module sdram2
(
	inout  reg [15:0] SDRAM_DQ,   // 16 bit bidirectional data bus
	output reg [12:0] SDRAM_A,    // 13 bit multiplexed address bus
	output reg        SDRAM_DQML, // byte mask
	output reg        SDRAM_DQMH, // byte mask
	output reg  [1:0] SDRAM_BA,   // two banks
	output reg        SDRAM_nCS,  // a single chip select
	output reg        SDRAM_nWE,  // write enable
	output reg        SDRAM_nRAS, // row address select
	output reg        SDRAM_nCAS, // columns address select
	output            SDRAM_CLK,
	output            SDRAM_CKE,

	// cpu/chipset interface
	input             init,			// init signal after FPGA config to initialize RAM
	input             clk,			// sdram is accessed at up to 128MHz

	input      [19:1] addr,
	input      [31:0] din,
	input       [3:0] wr,
	input             rd,
	output     [31:0] dout,
	input             rfs,
	output            busy,
	
	output            dbg_rfs_timeout,

	output [1:0] dbg_ctrl_bank,
	output [1:0] dbg_ctrl_cmd,
	output [3:0] dbg_ctrl_we,
	output       dbg_ctrl_rfs,
	
	output       dbg_data0_read,
	output       dbg_out0_read,
	output [1:0] dbg_out0_bank,
	
	output       dbg_data1_read,
	output       dbg_out1_read,
	output [1:0] dbg_out1_bank,
	
	output reg [15:0] dbg_sdram_d
);

	localparam RASCAS_DELAY   = 3'd3; // tRCD=20ns -> 2 cycles@85MHz
	localparam BURST_1        = 3'd1; // 0=1, 1=2, 2=4, 3=8, 7=full page
	localparam BURST_2        = 3'd1; // 0=1, 1=2, 2=4, 3=8, 7=full page
	localparam ACCESS_TYPE    = 1'd0; // 0=sequential, 1=interleaved
	localparam CAS_LATENCY    = 3'd3; // 2/3 allowed
	localparam OP_MODE        = 2'd0; // only 0 (standard operation) allowed
	localparam NO_WRITE_BURST = 1'd1; // 0=write burst enabled, 1=only single access write

	localparam bit [12:0] MODE[2] = '{{3'b000, NO_WRITE_BURST, OP_MODE, CAS_LATENCY, ACCESS_TYPE, BURST_2},
	                                  {3'b000, NO_WRITE_BURST, OP_MODE, CAS_LATENCY, ACCESS_TYPE, BURST_1}}; 
	
	localparam STATE_IDLE  = 4'd0;             // state to check the requests
	localparam STATE_START = STATE_IDLE+1'd1;  // state in which a new command is started
	localparam STATE_CONT  = STATE_START+RASCAS_DELAY;
	localparam STATE_READY = STATE_CONT+CAS_LATENCY+1'd1;
	localparam STATE_LAST  = STATE_READY;      // last state in cycle
	
	localparam MODE_NORMAL = 2'b00;
	localparam MODE_RESET  = 2'b01;
	localparam MODE_LDM    = 2'b10;
	localparam MODE_PRE    = 2'b11;

	// initialization 
	reg [3:0] init_state = '0;
	reg [1:0] mode;
	reg       init_chip = 0;
	reg       init_done = 0;
	always @(posedge clk) begin
		reg [4:0] reset = 5'h1f;
		reg init_old = 0;
		
		if(mode != MODE_NORMAL || init_state != STATE_IDLE || reset) begin
			init_state <= init_state + 1'd1;
			if (init_state == STATE_LAST) init_state <= STATE_IDLE;
		end

		init_old <= init;
		if (init_old & ~init) begin
			reset <= 5'h1f; 
			init_chip <= 0;
			init_done <= 0;
		end
		else if (init_state == STATE_LAST) begin
			if(reset != 0) begin
				reset <= reset - 5'd1;
				if (reset == 15 || reset == 14) begin mode <= MODE_PRE; init_chip <= (reset == 15); end
				else if(reset == 4 || reset == 3) begin mode <= MODE_LDM; init_chip <= (reset == 4); end
				else                mode <= MODE_RESET;
			end
			else begin
				mode <= MODE_NORMAL;
				init_chip <= 0;
				init_done <= 1;
			end
		end
	end
	
	localparam CTRL_IDLE = 2'd0;
	localparam CTRL_RAS = 2'd1;
	localparam CTRL_CAS = 2'd2;
	
	typedef struct packed
	{
		bit [ 1:0] CMD;	//command
		bit [ 1:0] BANK;	//bank
		bit [19:1] ADDR;	//read/write address
		bit [15:0] DATA;	//write data
		bit        RD;		//read	
		bit        WE;		//write enable
		bit [ 1:0] BE;		//write byte enable
		bit        RFS;	//refresh	
		bit        LAST;	//last read	
	} state_t;
	state_t state[7];
	reg [ 3: 0] st_num;
	
	reg         rd_busy,wr_busy;
	reg         is_read,is_write,is_refresh;
	reg [19: 1] address;
	reg [31: 0] wr_data;
	reg [ 3: 0] wr_be;
	
	always @(posedge clk) begin
		reg old_rd, old_wr, old_rfs;
		reg [ 1: 0] burst_cnt;
		reg [10: 0] rfs_wait_cnt;
		
		if (!init_done) begin
			st_num <= 4'd11;
			{is_read,is_write,is_refresh} <= '0;
			{rd_busy,wr_busy} <= '0;
			burst_cnt <= '0;
			dbg_rfs_timeout <= 0;
		end else begin
			if (is_read || is_write || is_refresh) st_num <= st_num + 4'd1;
			
			rfs_wait_cnt <= rfs_wait_cnt + 1'd1;
			if (rfs_wait_cnt == 11'h7FF) dbg_rfs_timeout <= 1;
			
			old_rd <= rd;
			old_wr <= |wr;
			old_rfs <= rfs;
			if (rd && !old_rd) begin
				burst_cnt <= burst_cnt + 2'd1;
				if (burst_cnt == 2'd0) begin
					address <= addr;
					rd_busy <= 1;
					is_read <= 1;
					st_num <= 4'd0;
				end
			end
			else if (wr && !old_wr) begin
				address <= addr;
				wr_data <= din;
				wr_be <= wr;
				wr_busy <= 1;
				is_write <= 1;
				st_num <= 4'd0;
			end
			else if (rfs && !old_rfs) begin
				is_refresh <= 1;
				st_num <= 4'd0;
				rfs_wait_cnt <= '0;
				dbg_rfs_timeout <= 0;
			end
			
			if (is_refresh && st_num == 4'd6) is_refresh <= 0;
			if (is_read && st_num == 4'd10) rd_busy <= 0;
			if (is_write && st_num == 4'd5) wr_busy <= 0;
			if (is_read && st_num == 4'd10) is_read <= 0;
			if (is_write && st_num == 4'd6) is_write <= 0;
		end
		
	end
	
	always @(posedge clk) begin
		state[0] <= '0;
		if (!init_done) begin
			state[0].CMD <= init_state == STATE_START ? CTRL_RAS : 
			                init_state == STATE_CONT  ? CTRL_CAS : 
								                             CTRL_IDLE;
			state[0].RFS <= 1;
		end else begin
			case (st_num[3:0])
				4'd0: begin state[0].CMD  <=                       CTRL_RAS;
								state[0].ADDR <= {address[19:2],1'b0};
								state[0].BANK <= '0;
								state[0].RFS  <= is_refresh; end

				4'd3: begin state[0].CMD  <= is_read || is_write ? CTRL_CAS : CTRL_IDLE;
								state[0].ADDR <= is_read             ? {address[19:4],address[3:2]+2'd0,1'b0} : {address[19:2],1'b0};
								state[0].DATA <= wr_data[31:16];
				            state[0].RD   <= is_read;
								state[0].WE   <= is_write;
								state[0].BE   <= wr_be[3:2];
								state[0].BANK <= '0; end
								
				4'd4: begin state[0].CMD  <= is_write            ? CTRL_CAS                         : CTRL_IDLE;
								state[0].ADDR <=                                                          {address[19:2],1'b1};
								state[0].DATA <= wr_data[15:0];
				            state[0].RD   <= 0;
								state[0].WE   <= is_write;
								state[0].BE   <= wr_be[1:0];
								state[0].BANK <= '0; end

				4'd5: begin state[0].CMD  <= is_read             ? CTRL_CAS                         : CTRL_IDLE;
								state[0].ADDR <=                       {address[19:4],address[3:2]+2'd1,1'b0};
				            state[0].RD   <= is_read;
								state[0].BANK <= '0; end

				4'd7: begin state[0].CMD  <= is_read             ? CTRL_CAS : CTRL_IDLE;
								state[0].ADDR <=                       {address[19:4],address[3:2]+2'd2,1'b0};
				            state[0].RD   <= is_read;
								state[0].BANK <= '0; end

				4'd9: begin state[0].CMD  <= is_read             ? CTRL_CAS : CTRL_IDLE;
								state[0].ADDR <=                       {address[19:4],address[3:2]+2'd3,1'b0};
				            state[0].RD   <= is_read;
								state[0].LAST <= 1;
								state[0].BANK <= '0; end
				default:;
			endcase
		end
		state[1] <= state[0];
		state[2] <= state[1];
		state[3] <= state[2];
		state[4] <= state[3];
		state[5] <= state[4];
		state[6] <= state[5];
	end
	
	wire [ 1:0] ctrl_cmd   = state[0].CMD;
	wire [19:1] ctrl_addr  = state[0].ADDR;
	wire [15:0] ctrl_data  = state[0].DATA;
//	wire        ctrl_rd    = state[0].RD;
	wire        ctrl_we    = state[0].WE;
	wire [ 1:0] ctrl_be    = state[0].BE;
	wire [ 1:0] ctrl_bank  = state[0].BANK;
	wire        ctrl_rfs   = state[0].RFS;
	wire        ctrl_last  = state[0].LAST;
	
	wire       data0_read = state[4].RD;
	wire       out0_read  = state[5].RD;
	wire [1:0] out0_addr  = state[5].ADDR[3:2];
	wire [1:0] out0_bank  = state[5].BANK;
	
	wire       data1_read = state[5].RD;
	wire       out1_read  = state[6].RD;
	wire [1:0] out1_addr  = state[6].ADDR[3:2];
	wire [1:0] out1_bank  = state[6].BANK;
	
	reg [15:0] rbuf;
	reg [31:0] dout_buf[4];
	always @(posedge clk) begin
		rbuf <= SDRAM_DQ;

		if (out0_read) dout_buf[out0_addr][31:16] <= rbuf;
		if (out1_read) dout_buf[out1_addr][15: 0] <= rbuf;
	end
		
	assign dout = dout_buf[addr[3:2]];
	assign busy = rd_busy | wr_busy;
	

	localparam CMD_NOP             = 3'b111;
	localparam CMD_ACTIVE          = 3'b011;
	localparam CMD_READ            = 3'b101;
	localparam CMD_WRITE           = 3'b100;
	localparam CMD_BURST_TERMINATE = 3'b110;
	localparam CMD_PRECHARGE       = 3'b010;
	localparam CMD_AUTO_REFRESH    = 3'b001;
	localparam CMD_LOAD_MODE       = 3'b000;
	
	// SDRAM state machines
	wire [19:1] a = ctrl_addr;
	wire [15:0] d = ctrl_data;
	wire        we = ctrl_we;
	wire  [1:0] dqm = ~ctrl_be;
	wire        ra10 = ctrl_last;
	wire        wa10 = ctrl_addr[1];
	always @(posedge clk) begin
		if (ctrl_cmd == CTRL_RAS || ctrl_cmd == CTRL_CAS) SDRAM_BA <= (mode == MODE_NORMAL) ? ctrl_bank : 2'b00;

		casex({init_done,ctrl_rfs,we,mode,ctrl_cmd})
			{3'bx0x, MODE_NORMAL, CTRL_RAS}: {SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE, SDRAM_nCS} <= {CMD_ACTIVE,1'b0};
			{3'bx1x, MODE_NORMAL, CTRL_RAS}: {SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE, SDRAM_nCS} <= {CMD_AUTO_REFRESH,1'b0};
			{3'b101, MODE_NORMAL, CTRL_CAS}: {SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE, SDRAM_nCS} <= {CMD_WRITE,1'b0};
			{3'b100, MODE_NORMAL, CTRL_CAS}: {SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE, SDRAM_nCS} <= {CMD_READ,1'b0};

			// init
			{3'bxxx,    MODE_LDM, CTRL_RAS}: {SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE, SDRAM_nCS} <= {CMD_LOAD_MODE, init_chip};
			{3'bxxx,    MODE_PRE, CTRL_RAS}: {SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE, SDRAM_nCS} <= {CMD_PRECHARGE, init_chip};

										   default: {SDRAM_nRAS, SDRAM_nCAS, SDRAM_nWE, SDRAM_nCS} <= {CMD_NOP,1'b1};
		endcase
		
		SDRAM_DQ <= 'Z;
		casex({init_done,ctrl_rfs,we,mode,ctrl_cmd})
			{3'b101, MODE_NORMAL, CTRL_CAS}: begin SDRAM_DQ <= d; dbg_sdram_d <= d; end
										   default: ;
		endcase

		if (mode == MODE_NORMAL) begin
			casex ({we,ctrl_cmd})
				{1'bx,CTRL_RAS}: SDRAM_A <= {2'b00,a[19:9]};
				{1'b0,CTRL_CAS}: SDRAM_A <= {2'b00,ra10,2'b00,a[8:1]};
				{1'b1,CTRL_CAS}: SDRAM_A <= {dqm  ,wa10 ,2'b00,a[8:1]};
			endcase;
		end
		else if (mode == MODE_LDM && ctrl_cmd == CTRL_RAS) SDRAM_A <= MODE[init_chip];
		else if (mode == MODE_PRE && ctrl_cmd == CTRL_RAS) SDRAM_A <= 13'b0010000000000;
		else SDRAM_A <= '0;
	end
	
	assign SDRAM_CKE = 1;
	assign {SDRAM_DQMH,SDRAM_DQML} = SDRAM_A[12:11];
	
	
	
	assign dbg_ctrl_bank = ctrl_bank;
	assign dbg_ctrl_cmd = ctrl_cmd;
	assign dbg_ctrl_we = ctrl_we;
	assign dbg_ctrl_rfs = ctrl_rfs;
	assign dbg_data0_read = data0_read;
	assign dbg_out0_read = out0_read;
	assign dbg_out0_bank = out0_bank;
	assign dbg_data1_read = data1_read;
	assign dbg_out1_read = out1_read;
	assign dbg_out1_bank = out1_bank;

	altddio_out
	#(
		.extend_oe_disable("OFF"),
		.intended_device_family("Cyclone V"),
		.invert_output("OFF"),
		.lpm_hint("UNUSED"),
		.lpm_type("altddio_out"),
		.oe_reg("UNREGISTERED"),
		.power_up_high("OFF"),
		.width(1)
	)
	sdramclk_ddr
	(
		.datain_h(1'b0),
		.datain_l(1'b1),
		.outclock(clk),
		.dataout(SDRAM_CLK),
		.aclr(1'b0),
		.aset(1'b0),
		.oe(1'b1),
		.outclocken(1'b1),
		.sclr(1'b0),
		.sset(1'b0)
	);

endmodule

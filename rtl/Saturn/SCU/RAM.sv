// synopsys translate_off
`define SIM
// synopsys translate_on
	
module DSP_DPRAM
#(
	parameter addr_width = 8,
	parameter data_width = 8,
	parameter mem_init_file = " ",
	parameter mem_sim_file = " "
)
(
	input                   CLK,
	
	input  [addr_width-1:0] ADDR_A,
	input  [data_width-1:0] DATA_A,
	input                   WREN_A,
	output [data_width-1:0] Q_A,
	
	input  [addr_width-1:0] ADDR_B,
	input  [data_width-1:0] DATA_B,
	input                   WREN_B,
	output [data_width-1:0] Q_B
);

`ifdef SIM
	
	reg [data_width-1:0] MEM [2**addr_width];

	initial begin
		$readmemh(mem_sim_file, MEM);
	end
	
	always @(posedge CLK) begin
		if (WREN_A) begin
			MEM[ADDR_A] <= DATA_A;
		end
		if (WREN_B) begin
			MEM[ADDR_B] <= DATA_B;
		end
	end
		
	assign Q_A = MEM[ADDR_A];
	assign Q_B = MEM[ADDR_B];
	
`else
	
	wire [data_width-1:0] sub_wire0, sub_wire1;

	altsyncram	altsyncram_component (
				.address_a (ADDR_A),
				.address_b (ADDR_B),
				.clock0 (CLK),
				.clock1 (CLK),
				.data_a (DATA_A),
				.data_b (DATA_B),
				.wren_a (WREN_A),
				.wren_b (WREN_B),
				.q_a (sub_wire0),
				.q_b (sub_wire1),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.eccstatus (),
				.rden_a (1'b1),
				.rden_b (1'b1));
	defparam
		altsyncram_component.address_reg_b = "CLOCK1",
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_input_b = "BYPASS",
//		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.clock_enable_output_b = "BYPASS",
//		altsyncram_component.indata_reg_b = "CLOCK1",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 2**addr_width,
		altsyncram_component.numwords_b = 2**addr_width,
		altsyncram_component.operation_mode = "DUAL_PORT",
//		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
//		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",		
		altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.read_during_write_mode_port_b = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.widthad_a = addr_width,
		altsyncram_component.widthad_b = addr_width,
		altsyncram_component.width_a = data_width,
		altsyncram_component.width_b = data_width,
		altsyncram_component.width_byteena_a = 1,
//		altsyncram_component.width_byteena_b = 1,
		altsyncram_component.init_file = mem_init_file; 


	assign Q_A = sub_wire0;
	assign Q_B = sub_wire1;
	
`endif

endmodule


module DSP_PRG_RAM
#(
	parameter addr_width = 8,
	parameter data_width = 8,
	parameter mem_init_file = " ",
	parameter mem_sim_file = " "
)
(
	input                   CLK,
	
	input  [addr_width-1:0] ADDR,
	input  [data_width-1:0] DATA,
	input                   WREN,
	output [data_width-1:0] Q
);

`ifdef SIM
	
	reg [data_width-1:0] MEM [2**addr_width];

	initial begin
		$readmemh(mem_sim_file, MEM);
	end
	
	always @(posedge CLK) begin
		if (WREN) begin
			MEM[ADDR] <= DATA;
		end
	end
		
	assign Q = MEM[ADDR];
	
//`elsif DEBUG
//
//	wire [data_width-1:0] sub_wire0;
//	
//	altdpram	altdpram_component (
//				.data (DATA),
//				.inclock (CLK),
//				.rdaddress (ADDR),
//				.wraddress (ADDR),
//				.wren (WREN),
//				.q (sub_wire0),
//				.aclr (1'b0),
//				.byteena (1'b1),
//				.inclocken (1'b1),
//				.rdaddressstall (1'b0),
//				.rden (1'b1),
////				.sclr (1'b0),
//				.wraddressstall (1'b0));
//	defparam
//		altdpram_component.indata_aclr = "OFF",
//		altdpram_component.indata_reg = "INCLOCK",
//		altdpram_component.intended_device_family = "Cyclone V",
//		altdpram_component.lpm_type = "altdpram",
//		altdpram_component.outdata_aclr = "OFF",
//		altdpram_component.outdata_reg = "UNREGISTERED",
//		altdpram_component.ram_block_type = "MLAB",
//		altdpram_component.rdaddress_aclr = "OFF",
//		altdpram_component.rdaddress_reg = "UNREGISTERED",
//		altdpram_component.rdcontrol_aclr = "OFF",
//		altdpram_component.rdcontrol_reg = "UNREGISTERED",
//		altdpram_component.read_during_write_mode_mixed_ports = "CONSTRAINED_DONT_CARE",
//		altdpram_component.width = data_width,
//		altdpram_component.widthad = addr_width,
//		altdpram_component.width_byteena = 1,
//		altdpram_component.wraddress_aclr = "OFF",
//		altdpram_component.wraddress_reg = "INCLOCK",
//		altdpram_component.wrcontrol_aclr = "OFF",
//		altdpram_component.wrcontrol_reg = "INCLOCK";
//	
//	assign Q = sub_wire0;

`else

	wire [data_width-1:0] sub_wire0;

	altsyncram	altsyncram_component (
				.address_a (ADDR),
				.clock0 (CLK),
				.data_a (DATA),
				.wren_a (WREN),
				.q_a (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.address_b (1'b1),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b (1'b1),
				.eccstatus (),
				.q_b (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));

	defparam
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 2**addr_width,
		altsyncram_component.operation_mode = "SINGLE_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.ram_block_type = "M10K",
		altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.widthad_a = addr_width,
		altsyncram_component.width_a = data_width,
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.init_file = mem_init_file;

	assign Q = sub_wire0;
	
`endif
	
endmodule


module DSP_DATA_RAM
#(
	parameter addr_width = 8,
	parameter data_width = 8,
	parameter mem_init_file = " ",
	parameter mem_sim_file = " "
)
(
	input                   CLK,
	
	input  [addr_width-1:0] ADDR,
	input  [data_width-1:0] DATA,
	input                   WREN,
	output [data_width-1:0] Q
);

`ifdef SIM
	
	reg [data_width-1:0] MEM [2**addr_width];

	initial begin
		$readmemh(mem_sim_file, MEM);
	end
	
	always @(posedge CLK) begin
		if (WREN) begin
			MEM[ADDR] <= DATA;
		end
	end
		
	assign Q = MEM[ADDR];
	
`else

	wire [data_width-1:0] sub_wire0;
	
	altdpram	altdpram_component (
				.data (DATA),
				.inclock (CLK),
				.rdaddress (ADDR),
				.wraddress (ADDR),
				.wren (WREN),
				.q (sub_wire0),
				.aclr (1'b0),
				.byteena (1'b1),
				.inclocken (1'b1),
				.rdaddressstall (1'b0),
				.rden (1'b1),
//				.sclr (1'b0),
				.wraddressstall (1'b0));
	defparam
		altdpram_component.indata_aclr = "OFF",
		altdpram_component.indata_reg = "INCLOCK",
		altdpram_component.intended_device_family = "Cyclone V",
		altdpram_component.lpm_type = "altdpram",
		altdpram_component.outdata_aclr = "OFF",
		altdpram_component.outdata_reg = "UNREGISTERED",
		altdpram_component.ram_block_type = "MLAB",
		altdpram_component.rdaddress_aclr = "OFF",
		altdpram_component.rdaddress_reg = "UNREGISTERED",
		altdpram_component.rdcontrol_aclr = "OFF",
		altdpram_component.rdcontrol_reg = "UNREGISTERED",
		altdpram_component.read_during_write_mode_mixed_ports = "CONSTRAINED_DONT_CARE",
		altdpram_component.width = data_width,
		altdpram_component.widthad = addr_width,
		altdpram_component.width_byteena = 1,
		altdpram_component.wraddress_aclr = "OFF",
		altdpram_component.wraddress_reg = "INCLOCK",
		altdpram_component.wrcontrol_aclr = "OFF",
		altdpram_component.wrcontrol_reg = "INCLOCK";
	
	assign Q = sub_wire0;
	
`endif
	
endmodule


module SCU_DMA_FIFO (
	CLK,
	DATA,
	WRREQ,
	RDREQ,
	Q,
	EMPTY,
	FULL);

	input	  CLK;
	input	[36:0]  DATA;
	input	  RDREQ;
	input	  WRREQ;
	output	  EMPTY;
	output	  FULL;
	output	[36:0] Q;

	wire  sub_wire0;
	wire  sub_wire1;
	wire [36:0] sub_wire2;
	wire  EMPTY = sub_wire0;
	wire  FULL = sub_wire1;
	wire [36:0] Q = sub_wire2[36:0];

	scfifo	scfifo_component (
				.clock (CLK),
				.data (DATA),
				.rdreq (RDREQ),
				.wrreq (WRREQ),
				.empty (sub_wire0),
				.full (sub_wire1),
				.q (sub_wire2),
				.aclr (),
				.almost_empty (),
				.almost_full (),
				.sclr (),
				.usedw ());
	defparam
		scfifo_component.add_ram_output_register = "OFF",
		scfifo_component.intended_device_family = "Cyclone V",
		scfifo_component.lpm_hint = "RAM_BLOCK_TYPE=MLAB",
		scfifo_component.lpm_numwords = 8,
		scfifo_component.lpm_showahead = "ON",
		scfifo_component.lpm_type = "scfifo",
		scfifo_component.lpm_width = 37,
		scfifo_component.lpm_widthu = 3,
		scfifo_component.overflow_checking = "OFF",
		scfifo_component.underflow_checking = "OFF",
		scfifo_component.use_eab = "ON";

endmodule

module SCU_DMA_FIFO2 (
	input	        CLK,
	input	 [36:0] DATA,
	input	        WRREQ,
	input	        RDREQ,
	output [36:0] Q,
	output	     EMPTY,
	output	     FULL
);

	wire [36: 0] sub_wire0;
	bit  [ 2: 0] RADDR;
	bit  [ 2: 0] WADDR;
	bit  [ 3: 0] AMOUNT;
	
	always @(posedge CLK) begin
		if (WRREQ && !AMOUNT[3]) begin
			WADDR <= WADDR + 3'd1;
		end
		if (RDREQ && AMOUNT) begin
			RADDR <= RADDR + 3'd1;
		end
		
		if (WRREQ && !RDREQ && !AMOUNT[3]) begin
			AMOUNT <= AMOUNT + 4'd1;
		end else if (!WRREQ && RDREQ && AMOUNT) begin
			AMOUNT <= AMOUNT - 4'd1;
		end
	end
	assign EMPTY = ~|AMOUNT;
	assign FULL = AMOUNT[3];
	
	altdpram	altdpram_component (
				.data (DATA),
				.inclock (CLK),
				.rdaddress (RADDR),
				.wraddress (WADDR),
				.wren (WRREQ),
				.q (sub_wire0),
				.aclr (1'b0),
				.byteena (1'b1),
				.inclocken (1'b1),
				.rdaddressstall (1'b0),
				.rden (1'b1),
//				.sclr (1'b0),
				.wraddressstall (1'b0));
	defparam
		altdpram_component.indata_aclr = "OFF",
		altdpram_component.indata_reg = "INCLOCK",
		altdpram_component.intended_device_family = "Cyclone V",
		altdpram_component.lpm_type = "altdpram",
		altdpram_component.outdata_aclr = "OFF",
		altdpram_component.outdata_reg = "UNREGISTERED",
		altdpram_component.ram_block_type = "MLAB",
		altdpram_component.rdaddress_aclr = "OFF",
		altdpram_component.rdaddress_reg = "UNREGISTERED",
		altdpram_component.rdcontrol_aclr = "OFF",
		altdpram_component.rdcontrol_reg = "UNREGISTERED",
		altdpram_component.read_during_write_mode_mixed_ports = "CONSTRAINED_DONT_CARE",
		altdpram_component.width = 37,
		altdpram_component.widthad = 3,
		altdpram_component.width_byteena = 1,
		altdpram_component.wraddress_aclr = "OFF",
		altdpram_component.wraddress_reg = "INCLOCK",
		altdpram_component.wrcontrol_aclr = "OFF",
		altdpram_component.wrcontrol_reg = "INCLOCK";
		
	assign Q = sub_wire0;

endmodule

module SCU_CBUS_CACHE
(
	input         CLK,
	
	input  [ 2:0] WADDR,
	input  [31:0] DATA,
	input         WREN,
	input  [ 2:0] RADDR,
	output [31:0] Q
);

`ifdef SIM
	
	reg [31:0] MEM [8];
	
	always @(posedge CLK) begin
		if (WREN) begin
			MEM[WADDR] <= DATA;
		end
	end
		
	assign Q = MEM[RADDR];
	
`else

	wire [31:0] sub_wire0;
	
	altdpram	altdpram_component (
				.data (DATA),
				.inclock (CLK),
				.rdaddress (RADDR),
				.wraddress (WADDR),
				.wren (WREN),
				.q (sub_wire0),
				.aclr (1'b0),
				.byteena (1'b1),
				.inclocken (1'b1),
				.rdaddressstall (1'b0),
				.rden (1'b1),
//				.sclr (1'b0),
				.wraddressstall (1'b0));
	defparam
		altdpram_component.indata_aclr = "OFF",
		altdpram_component.indata_reg = "INCLOCK",
		altdpram_component.intended_device_family = "Cyclone V",
		altdpram_component.lpm_type = "altdpram",
		altdpram_component.outdata_aclr = "OFF",
		altdpram_component.outdata_reg = "UNREGISTERED",
		altdpram_component.ram_block_type = "MLAB",
		altdpram_component.rdaddress_aclr = "OFF",
		altdpram_component.rdaddress_reg = "UNREGISTERED",
		altdpram_component.rdcontrol_aclr = "OFF",
		altdpram_component.rdcontrol_reg = "UNREGISTERED",
		altdpram_component.read_during_write_mode_mixed_ports = "CONSTRAINED_DONT_CARE",
		altdpram_component.width = 32,
		altdpram_component.widthad = 3,
		altdpram_component.width_byteena = 1,
		altdpram_component.wraddress_aclr = "OFF",
		altdpram_component.wraddress_reg = "INCLOCK",
		altdpram_component.wrcontrol_aclr = "OFF",
		altdpram_component.wrcontrol_reg = "INCLOCK";
	
	assign Q = sub_wire0;
	
`endif
	
endmodule

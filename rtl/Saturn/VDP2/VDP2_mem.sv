module VDP2_PAL_RAM (
	input         CLK,
	
	input  [ 9:0] ADDR_A,
	input  [15:0] DATA_A,
	input  [ 1:0] WREN_A,
	output [15:0] Q_A,
	
	input  [ 9:0] ADDR_B,
	input  [15:0] DATA_B,
	input  [ 1:0] WREN_B,
	output [15:0] Q_B
);

	wire [15:0] sub_wire0;
	wire [15:0] sub_wire1;

	altsyncram	altsyncram_component (
				.clock0 (CLK),
				.wren_a (|WREN_A),
				.address_b (ADDR_B),
				.data_b (DATA_B),
				.wren_b (|WREN_B),
				.address_a (ADDR_A),
				.data_a (DATA_A),
				.q_a (sub_wire0),
				.q_b (sub_wire1),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (WREN_A),
				.byteena_b (WREN_B),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.eccstatus (),
				.rden_a (1'b1),
				.rden_b (1'b1));
	defparam
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.byteena_reg_b = "CLOCK0",
		altsyncram_component.byte_size = 8,
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_input_b = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.clock_enable_output_b = "BYPASS",
		altsyncram_component.indata_reg_b = "CLOCK0",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 1024,
		altsyncram_component.numwords_b = 1024,
		altsyncram_component.operation_mode = "BIDIR_DUAL_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.read_during_write_mode_port_b = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.widthad_a = 10,
		altsyncram_component.widthad_b = 10,
		altsyncram_component.width_a = 16,
		altsyncram_component.width_b = 16,
		altsyncram_component.width_byteena_a = 2,
		altsyncram_component.width_byteena_b = 2,
		altsyncram_component.wrcontrol_wraddress_reg_b = "CLOCK0";
		
	assign Q_A = sub_wire0;
	assign Q_B = sub_wire1;

endmodule

module VDP2_WRITE_FIFO (
	input	        CLK,
	input         RST_N,
	
	input	 [35:0] DATA,
	input	        WRREQ,
	input	        RDREQ,
	output [35:0] Q,
	output	     EMPTY,
	output	     FULL,
	output	     LAST
);

	wire [35: 0] sub_wire0;
	bit  [ 2: 0] RADDR;
	bit  [ 2: 0] WADDR;
	bit  [ 3: 0] AMOUNT;
	
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			AMOUNT <= '0;
			RADDR <= '0;
			WADDR <= '0;
		end
		else begin
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
	end
	assign EMPTY = ~|AMOUNT;
	assign FULL = AMOUNT[3];
	assign LAST = (AMOUNT == 4'd1);
	
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
		altdpram_component.width = 36,
		altdpram_component.widthad = 3,
		altdpram_component.width_byteena = 1,
		altdpram_component.wraddress_aclr = "OFF",
		altdpram_component.wraddress_reg = "INCLOCK",
		altdpram_component.wrcontrol_aclr = "OFF",
		altdpram_component.wrcontrol_reg = "INCLOCK";
		
	assign Q = sub_wire0;

endmodule

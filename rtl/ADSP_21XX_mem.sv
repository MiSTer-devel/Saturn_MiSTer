// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on

module ADSP_21xx_MEM
#(
	parameter addr_width = 14,
	parameter data_width = 24
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

// synopsys translate_off
`define SIM
// synopsys translate_on

`ifdef SIM
	
	reg [data_width-1:0] MEM [2**addr_width];

	initial begin
		MEM <= '{2**addr_width{'0}};
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
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_input_b = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.clock_enable_output_b = "BYPASS",
		altsyncram_component.indata_reg_b = "CLOCK0",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 2**addr_width,
		altsyncram_component.numwords_b = 2**addr_width,
		altsyncram_component.operation_mode = "BIDIR_DUAL_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",	
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",	
		altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.read_during_write_mode_port_b = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.widthad_a = addr_width,
		altsyncram_component.widthad_b = addr_width,
		altsyncram_component.width_a = data_width,
		altsyncram_component.width_b = data_width,
		altsyncram_component.width_byteena_a = 1,
//		altsyncram_component.width_byteena_b = 1,
		altsyncram_component.wrcontrol_wraddress_reg_b = "CLOCK0"; 


	assign Q_A = sub_wire0;
	assign Q_B = sub_wire1;
	
`endif

endmodule

module ADSP_21xx_STACK
#(
	parameter addr_width = 4,
	parameter data_width = 16
)
(
	input	                  CLK,
	input                   RST,
	input                   EN,
	
	input	 [data_width-1:0] DATA,
	input	                  PUSH,
	input	                  POP,
	output [data_width-1:0] Q,
	
	output	               EMPTY,
	output	               FULL,
	
	output [data_width-1:0] Q2
);

	wire [data_width-1: 0] sub_wire0;
	bit  [addr_width-1: 0] ADDR;
	bit  [addr_width: 0] AMOUNT;
	
	always @(posedge CLK) begin
		if (RST) begin
			AMOUNT <= '0;
			ADDR <= '0;
		end
		else if (EN) begin
			if (PUSH && !AMOUNT[addr_width]) begin
				ADDR <= ADDR + 1'd1;
				AMOUNT <= AMOUNT + 1'd1;
			end
			if (POP && AMOUNT) begin
				ADDR <= ADDR - 1'd1;
				AMOUNT <= AMOUNT - 1'd1;
			end
		end
	end
	assign EMPTY = PUSH ? 1'b0 : ~|AMOUNT;
	assign FULL = AMOUNT[addr_width];

`ifdef SIM

	reg [data_width-1:0]  MEM[2**addr_width];
	initial begin
		MEM <= '{2**addr_width{'0}};
	end
	
	always @(posedge CLK) begin
		if (EN) begin
			if (PUSH) begin
				MEM[ADDR] <= DATA;
			end
		end
	end

	assign Q = PUSH ? DATA : MEM[ADDR - 1'd1];
	assign Q2 = MEM[ADDR - 1'd1];
											  	
`else 
	
	altdpram	altdpram_component (
				.data (DATA),
				.inclock (CLK),
				.rdaddress (ADDR - 1'd1),
				.wraddress (ADDR),
				.wren (PUSH && EN),
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
		
	assign Q = PUSH ? DATA : sub_wire0;
	assign Q2 = sub_wire0;

`endif

endmodule


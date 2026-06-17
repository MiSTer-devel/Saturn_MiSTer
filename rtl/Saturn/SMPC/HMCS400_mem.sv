module HMCS400_MR (
	input          CLK,
	input  [ 3: 0] ADDR,
	input  [ 3: 0] DATA,
	input          WREN,
	output [ 3: 0] Q
);

// synopsys translate_off
`define SIM
// synopsys translate_on
	
`ifdef SIM

	reg [3:0] MEM [2**4];
	initial begin
		MEM <= '{2**4{'0}};
	end
		
	always @(posedge CLK) begin
		if (WREN) MEM[ADDR] <= DATA;
	end
	assign Q = MEM[ADDR];
	
`else

	wire [3:0] sub_wire0;
		
	altdpram	altdpram_component (
				.data (DATA),
				.inclock (CLK),
				.outclock (CLK),
				.rdaddress (ADDR),
				.wraddress (ADDR),
				.wren (WREN),
				.q (sub_wire0),
				.aclr (1'b0),
				.byteena (1'b1),
				.inclocken (1'b1),
				.outclocken (1'b1),
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
		altdpram_component.width = 4,
		altdpram_component.widthad = 4,
		altdpram_component.width_byteena = 1,
		altdpram_component.wraddress_aclr = "OFF",
		altdpram_component.wraddress_reg = "INCLOCK",
		altdpram_component.wrcontrol_aclr = "OFF",
		altdpram_component.wrcontrol_reg = "INCLOCK";
		
	assign Q = sub_wire0;
	
`endif

endmodule 

module HMCS400_ROM
#(
	parameter rom_file = " "
)
(
	input          CLK,
	input  [10: 0] ADDR,
	output [ 9: 0] Q
);

// synopsys translate_off
`define SIM
// synopsys translate_on
	
`ifdef SIM

	reg [9:0] MEM [2**11];
	initial begin
		$readmemh(rom_file, MEM);
	end
	
	assign Q = MEM[ADDR];

`else

	wire [9:0] sub_wire0;
		
	altsyncram	altsyncram_component (
				.address_a (ADDR),
				.clock0 (CLK),
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
				.data_a ({10{1'b1}}),
				.data_b (1'b1),
				.eccstatus (),
				.q_b (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_a (1'b0),
				.wren_b (1'b0));
	defparam
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.init_file = rom_file,
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 2**11,
		altsyncram_component.operation_mode = "ROM",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.widthad_a = 11,
		altsyncram_component.width_a = 10,
		altsyncram_component.width_byteena_a = 1;

		
	assign Q = sub_wire0;
	
`endif

endmodule 

module HMCS400_STACK (
	input          CLK,
	input  [ 5: 2] ADDR,
	input  [15: 0] DATA,
	input  [ 3: 0] WREN,
	output [15: 0] Q
);

// synopsys translate_off
`define SIM
// synopsys translate_on
	
`ifdef SIM

	reg [15:0] MEM [2**4];
	initial begin
		MEM <= '{2**4{'0}};
	end
		
	always @(posedge CLK) begin
		if (WREN[3]) MEM[ADDR][15:12] <= DATA[15:12];
		if (WREN[2]) MEM[ADDR][11: 8] <= DATA[11: 8];
		if (WREN[1]) MEM[ADDR][ 7: 4] <= DATA[ 7: 4];
		if (WREN[0]) MEM[ADDR][ 3: 0] <= DATA[ 3: 0];
	end
	
	assign Q = MEM[ADDR];

`else

	wire [15:0] sub_wire0;
		
	altdpram	altdpram_component_0 (
				.data (DATA[15:12]),
				.inclock (CLK),
				.outclock (CLK),
				.rdaddress (ADDR),
				.wraddress (ADDR),
				.wren (WREN[3]),
				.q (sub_wire0[15:12]),
				.aclr (1'b0),
				.byteena (1'b1),
				.inclocken (1'b1),
				.outclocken (1'b1),
				.rdaddressstall (1'b0),
				.rden (1'b1),
//				.sclr (1'b0),
				.wraddressstall (1'b0));
	defparam
		altdpram_component_0.indata_aclr = "OFF",
		altdpram_component_0.indata_reg = "INCLOCK",
		altdpram_component_0.intended_device_family = "Cyclone V",
		altdpram_component_0.lpm_type = "altdpram",
		altdpram_component_0.outdata_aclr = "OFF",
		altdpram_component_0.outdata_reg = "UNREGISTERED",
		altdpram_component_0.ram_block_type = "MLAB",
		altdpram_component_0.rdaddress_aclr = "OFF",
		altdpram_component_0.rdaddress_reg = "UNREGISTERED",
		altdpram_component_0.rdcontrol_aclr = "OFF",
		altdpram_component_0.rdcontrol_reg = "UNREGISTERED",
		altdpram_component_0.read_during_write_mode_mixed_ports = "CONSTRAINED_DONT_CARE",
		altdpram_component_0.width = 4,
		altdpram_component_0.widthad = 4,
		altdpram_component_0.width_byteena = 1,
		altdpram_component_0.wraddress_aclr = "OFF",
		altdpram_component_0.wraddress_reg = "INCLOCK",
		altdpram_component_0.wrcontrol_aclr = "OFF",
		altdpram_component_0.wrcontrol_reg = "INCLOCK";
		
	altdpram	altdpram_component_1 (
				.data (DATA[11:8]),
				.inclock (CLK),
				.outclock (CLK),
				.rdaddress (ADDR),
				.wraddress (ADDR),
				.wren (WREN[2]),
				.q (sub_wire0[11:8]),
				.aclr (1'b0),
				.byteena (1'b1),
				.inclocken (1'b1),
				.outclocken (1'b1),
				.rdaddressstall (1'b0),
				.rden (1'b1),
//				.sclr (1'b0),
				.wraddressstall (1'b0));
	defparam
		altdpram_component_1.indata_aclr = "OFF",
		altdpram_component_1.indata_reg = "INCLOCK",
		altdpram_component_1.intended_device_family = "Cyclone V",
		altdpram_component_1.lpm_type = "altdpram",
		altdpram_component_1.outdata_aclr = "OFF",
		altdpram_component_1.outdata_reg = "UNREGISTERED",
		altdpram_component_1.ram_block_type = "MLAB",
		altdpram_component_1.rdaddress_aclr = "OFF",
		altdpram_component_1.rdaddress_reg = "UNREGISTERED",
		altdpram_component_1.rdcontrol_aclr = "OFF",
		altdpram_component_1.rdcontrol_reg = "UNREGISTERED",
		altdpram_component_1.read_during_write_mode_mixed_ports = "CONSTRAINED_DONT_CARE",
		altdpram_component_1.width = 4,
		altdpram_component_1.widthad = 4,
		altdpram_component_1.width_byteena = 1,
		altdpram_component_1.wraddress_aclr = "OFF",
		altdpram_component_1.wraddress_reg = "INCLOCK",
		altdpram_component_1.wrcontrol_aclr = "OFF",
		altdpram_component_1.wrcontrol_reg = "INCLOCK";
		
	altdpram	altdpram_component_2 (
				.data (DATA[7:4]),
				.inclock (CLK),
				.outclock (CLK),
				.rdaddress (ADDR),
				.wraddress (ADDR),
				.wren (WREN[1]),
				.q (sub_wire0[7:4]),
				.aclr (1'b0),
				.byteena (1'b1),
				.inclocken (1'b1),
				.outclocken (1'b1),
				.rdaddressstall (1'b0),
				.rden (1'b1),
//				.sclr (1'b0),
				.wraddressstall (1'b0));
	defparam
		altdpram_component_2.indata_aclr = "OFF",
		altdpram_component_2.indata_reg = "INCLOCK",
		altdpram_component_2.intended_device_family = "Cyclone V",
		altdpram_component_2.lpm_type = "altdpram",
		altdpram_component_2.outdata_aclr = "OFF",
		altdpram_component_2.outdata_reg = "UNREGISTERED",
		altdpram_component_2.ram_block_type = "MLAB",
		altdpram_component_2.rdaddress_aclr = "OFF",
		altdpram_component_2.rdaddress_reg = "UNREGISTERED",
		altdpram_component_2.rdcontrol_aclr = "OFF",
		altdpram_component_2.rdcontrol_reg = "UNREGISTERED",
		altdpram_component_2.read_during_write_mode_mixed_ports = "CONSTRAINED_DONT_CARE",
		altdpram_component_2.width = 4,
		altdpram_component_2.widthad = 4,
		altdpram_component_2.width_byteena = 1,
		altdpram_component_2.wraddress_aclr = "OFF",
		altdpram_component_2.wraddress_reg = "INCLOCK",
		altdpram_component_2.wrcontrol_aclr = "OFF",
		altdpram_component_2.wrcontrol_reg = "INCLOCK";
		
	altdpram	altdpram_component_3 (
				.data (DATA[3:0]),
				.inclock (CLK),
				.outclock (CLK),
				.rdaddress (ADDR),
				.wraddress (ADDR),
				.wren (WREN[0]),
				.q (sub_wire0[3:0]),
				.aclr (1'b0),
				.byteena (1'b1),
				.inclocken (1'b1),
				.outclocken (1'b1),
				.rdaddressstall (1'b0),
				.rden (1'b1),
//				.sclr (1'b0),
				.wraddressstall (1'b0));
	defparam
		altdpram_component_3.indata_aclr = "OFF",
		altdpram_component_3.indata_reg = "INCLOCK",
		altdpram_component_3.intended_device_family = "Cyclone V",
		altdpram_component_3.lpm_type = "altdpram",
		altdpram_component_3.outdata_aclr = "OFF",
		altdpram_component_3.outdata_reg = "UNREGISTERED",
		altdpram_component_3.ram_block_type = "MLAB",
		altdpram_component_3.rdaddress_aclr = "OFF",
		altdpram_component_3.rdaddress_reg = "UNREGISTERED",
		altdpram_component_3.rdcontrol_aclr = "OFF",
		altdpram_component_3.rdcontrol_reg = "UNREGISTERED",
		altdpram_component_3.read_during_write_mode_mixed_ports = "CONSTRAINED_DONT_CARE",
		altdpram_component_3.width = 4,
		altdpram_component_3.widthad = 4,
		altdpram_component_3.width_byteena = 1,
		altdpram_component_3.wraddress_aclr = "OFF",
		altdpram_component_3.wraddress_reg = "INCLOCK",
		altdpram_component_3.wrcontrol_aclr = "OFF",
		altdpram_component_3.wrcontrol_reg = "INCLOCK";
		
	assign Q = sub_wire0;
	
`endif

endmodule 

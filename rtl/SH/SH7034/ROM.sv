module SH7034_ROM 
#(
	parameter rom_file = ""
)
(
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	
	input      [27:0] IBUS_A,
	input      [31:0] IBUS_DI,
	output     [31:0] IBUS_DO,
	input       [3:0] IBUS_BA,
	input             IBUS_WE,
	input             IBUS_REQ,
	output            IBUS_BUSY,
	output            IBUS_ACT
);
	
	wire ROM_SEL = (IBUS_A[26:24] == 3'h0);
	bit [31:0] ROM_Q;
	CPU_ROM #(rom_file) cpu_rom
	(
		.clock(CLK),
		.address(IBUS_A[15:2]),
		.q(ROM_Q)
	);
	
	assign IBUS_DO = ROM_Q;
	assign IBUS_BUSY = 0;
	assign IBUS_ACT = ROM_SEL;
	
endmodule

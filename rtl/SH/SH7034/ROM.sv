module SH7034_ROM 
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
	output            IBUS_ACT,
	
	output     [15:0] ROM_A,
	input      [31:0] ROM_Q,
	output            ROM_CS
);
	
	wire ROM_SEL = (IBUS_A[26:24] == 3'h0);

	assign ROM_A = IBUS_A[15:0];
	assign ROM_CS = ROM_SEL;
	
	assign IBUS_DO = ROM_Q;
	assign IBUS_BUSY = 0;
	assign IBUS_ACT = ROM_SEL;
	
endmodule

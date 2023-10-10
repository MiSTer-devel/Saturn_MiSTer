module CD
#(
	parameter rom_file = "sh7034.mif"
)
(
	input             CLK,
	input             RST_N,
	input             CE,
	
	input             RES_N,
	
	input             CE_R,
	input             CE_F,
	input      [14:1] AA,
	input      [15:0] ADI,
	output     [15:0] ADO,
	input       [1:0] AFC,
	input             ACS2_N,
	input             ARD_N,
	input             AWRL_N,
	input             AWRU_N,
	input             ATIM0_N,
	input             ATIM2_N,
	output            AWAIT_N,
	output            ARQT_N,
	
	input             CDATA,
	output            HDATA,
	output            COMCLK,
	input             COMREQ_N,
	input             COMSYNC_N,
	output            DEMP,
	
	output     [18:1] RAM_A,
	output     [15:0] RAM_D,
	input      [15:0] RAM_Q,
	output            RAM_CS,
	output      [1:0] RAM_WE,
	output            RAM_RD,
	input             RAM_RDY,

	input      [15:0] CD_D,
	input             CD_CK
);

	bit [21:0] SA;
	bit [15:0] SDI;
	bit [15:0] SDO;
	bit        SWRL_N;
	bit        SWRH_N;
	bit        SRD_N;
	bit        SCS1_N;
	bit        SCS2_N;
	bit        SCS6_N;
	bit        SWAIT_N;
	bit        DACK0;
	bit        DACK1;
	bit        DREQ0_N;
	bit        DREQ1_N;
	bit        SIRQL_N;
	bit        SIRQH_N;
	
	bit [15:0] YGR019_DO;
	
	bit SHCLK;
	bit SHCE_R, SHCE_F;
	always @(posedge CLK) begin
		if (CE) SHCLK <= ~SHCLK;
	end
	assign SHCE_R =  SHCLK & CE;
	assign SHCE_F = ~SHCLK & CE;
	
	SH1 #(rom_file) sh1
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(SHCE_R),
		.CE_F(SHCE_F),
		
		.RES_N(RES_N),
		
		.A(SA),
		.DI(SDI),
		.DO(SDO),
		
		.CS1N_CASHN(SCS1_N),//in original CASH_N
		.CS2N(SCS2_N),
		.CS6N(SCS6_N),
		.WRLN(SWRL_N),
		.WRHN(SWRH_N),
		.RDN(SRD_N),
		.WAITN(SWAIT_N),
		
		.IRQ6N(SIRQL_N),
		.IRQ7N(SIRQH_N),
		
		.DACK0(DACK0),
		.DACK1(DACK1),
		.DREQ0N(DREQ0_N),
		.DREQ1N(DREQ1_N),
		
		.RXD0(CDATA),
		.TXD0(HDATA),
		.SCK0O(COMCLK),
		.PB2I(COMSYNC_N),
		.TIOCB3(COMREQ_N),
		.PB6O(DEMP),
		
		.TIOCA0(1'b0),//MPEG
		.TIOCA1(1'b0),//MPEG
		.TIOCA2(1'b1),//MPEGA_IRQ_N
		.TIOCB2(1'b1)//MPEGV_IRQ_N
	);
	
	assign SDI = !SCS1_N ? RAM_Q : YGR019_DO;
	
	YGR019 ygr 
	(
		.CLK(CLK),
		.RST_N(RST_N),
		
		.RES_N(RES_N),
		
		.CE_R(CE_R),
		.CE_F(CE_F),
		.AA(AA),
		.ADI(ADI),
		.ADO(ADO),
		.AFC(AFC),
		.ACS2_N(ACS2_N),
		.ARD_N(ARD_N),
		.AWRL_N(AWRL_N),
		.AWRU_N(AWRU_N),
		.ATIM0_N(ATIM0_N),
		.ATIM2_N(ATIM2_N),
		.AWAIT_N(AWAIT_N),
		.ARQT_N(ARQT_N),
		
		.SHCE_R(SHCE_R),
		.SHCE_F(SHCE_F),
		.SA(SA[21:1]),
		.SDI(SDO),
		.BDI(SDI),
		.SDO(YGR019_DO),
		.SWRL_N(SWRL_N),
		.SWRH_N(SWRH_N),
		.SRD_N(SRD_N),
		.SCS2_N(SCS2_N),
		.SCS6_N(SCS6_N),
		.SIRQL_N(SIRQL_N),
		.SIRQH_N(SIRQH_N),
		
		.DACK0(DACK0),
		.DACK1(DACK1),
		.DREQ0_N(DREQ0_N),
		.DREQ1_N(DREQ1_N),

		.CD_D(CD_D),
		.CD_CK(CD_CK)
	);
	
	assign SWAIT_N = RAM_RDY;
	
	assign RAM_A = SA[18:1];
	assign RAM_D = SDO;
	assign RAM_CS = ~SCS1_N;
	assign RAM_WE = ~{SWRH_N,SWRL_N};
	assign RAM_RD = ~SRD_N;
	

endmodule

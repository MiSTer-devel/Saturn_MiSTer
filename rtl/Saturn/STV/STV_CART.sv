module STV_CART (
	input             CLK,
	input             RST_N,
	
	input             STV_5838_MODE,
	input      [ 3:0] STV_5881_MODE,
	
	input             RES_N,
	
	input             CE_R,
	input             CE_F,
	input      [25:0] AA,
	input      [15:0] ADI,
	output     [15:0] ADO,
	input       [1:0] AFC,
	input             ACS0_N,
	input             ACS1_N,
	input             ACS2_N,
	input             ARD_N,
	input             AWRL_N,
	input             AWRU_N,
	input             ATIM0_N,
	input             ATIM2_N,
	output            AWAIT_N,
	output            ARQT_N,
	
	output     [25:1] MEM_A,
	input      [15:0] MEM_DI,
	output     [15:0] MEM_DO,
	output     [ 1:0] MEM_WE,
	output            MEM_RD,
	input             MEM_RDY
);

	wire [25:1] CART_ADDR = {ACS0_N,AA[24:1]};
	wire CART_SEL = ~ACS0_N || ~ACS1_N;
	
	wire STV_5838_SEL = (AA[22:1] >= 23'h7FFFF0>>1) && ~ACS0_N && STV_5838_MODE;
	wire STV_5881_SEL = (AA[23:1] >= 24'hFFFFF0>>1) && ~ACS1_N && |STV_5881_MODE;
	wire [31:0] STV_5881_KEY = STV_5881_MODE == 4'h1 ? 32'h052E2901 : //astrass
	                           STV_5881_MODE == 4'h2 ? 32'h05226D41 : //elandore
	                           STV_5881_MODE == 4'h3 ? 32'h0524AC01 : //ffreveng
	                           STV_5881_MODE == 4'h4 ? 32'h05272D01 : //rsgun
	                           STV_5881_MODE == 4'h5 ? 32'h052B6901 : //sss
	                           STV_5881_MODE == 4'h6 ? 32'h05200913 : //twcup98/twsoc98
										'0;

	bit        AWR_N_OLD;
	bit        ARD_N_OLD;
	always @(posedge CLK) begin
		AWR_N_OLD <= AWRL_N & AWRU_N;
		ARD_N_OLD <= ARD_N;
	end
	
	bit [15:0] ABUS_DO;
	bit        ABUS_WAIT;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			MEM_WE <= '0;
			MEM_RD <= 0;
			ABUS_WAIT <= 0;
		end else begin
			if (!RES_N) begin
				MEM_WE <= '0;
				MEM_RD <= 0;
				ABUS_WAIT <= 0;
			end else begin
				if ((!AWRL_N || !AWRU_N) && AWR_N_OLD) begin
					if (CART_SEL && !(STV_5838_SEL || STV_5881_SEL)) begin
						
					end
				end else if (!ARD_N && ARD_N_OLD) begin
					if (CART_SEL && !(STV_5838_SEL || STV_5881_SEL)) begin
						MEM_A <= CART_ADDR;
						MEM_RD <= 1;
						ABUS_WAIT <= 1;
					end
				end else if (SEGA_315_5838_MEM_RD) begin
					MEM_A <= {CART_ADDR[25:24],SEGA_315_5838_MEM_A};
					MEM_RD <= 1;
					ABUS_WAIT <= 1;
				end else if (SEGA_315_5881_MEM_RD) begin
					MEM_A <= SEGA_315_5881_MEM_A;
					MEM_RD <= 1;
					ABUS_WAIT <= 1;
				end
				
				if (ABUS_WAIT && MEM_RDY) begin
					ABUS_DO <= MEM_DI;
					MEM_WE <= '0;
					MEM_RD <= 0;
					ABUS_WAIT <= 0;
				end
			end
		end
	end
	assign MEM_DO = '0;
	
	//315-5838
	bit [15:0] SEGA_315_5838_DO;
	bit        SEGA_315_5838_WAIT;
	wire       SEGA_315_5838_RD = ~ARD_N & ARD_N_OLD & STV_5838_SEL;
	wire       SEGA_315_5838_WR = ~(AWRL_N & AWRU_N) & AWR_N_OLD & STV_5838_SEL;
	
	bit [23:1] SEGA_315_5838_MEM_A;
	bit        SEGA_315_5838_MEM_RD;
	SEGA_315_5838 SEGA_315_5838 (
		.CLK(CLK),
		.RST_N(RST_N),
		
		.RES_N(RES_N),
		
		.CE_R(CE_R),
		.CE_F(CE_F),
		.ADDR(AA[3:1]),
		.DI(ADI),
		.DO(SEGA_315_5838_DO),
		.RD(SEGA_315_5838_RD),
		.WR(SEGA_315_5838_WR),
		.WAIT(SEGA_315_5838_WAIT),
		
		.MEM_A(SEGA_315_5838_MEM_A),
		.MEM_DI(MEM_DI),
		.MEM_RD(SEGA_315_5838_MEM_RD),
		.MEM_RDY(MEM_RDY)
	);

	//315-5881
	bit [15:0] SEGA_315_5881_DO;
	bit        SEGA_315_5881_WAIT;
	wire       SEGA_315_5881_RD = ~ARD_N & ARD_N_OLD & STV_5881_SEL;
	wire       SEGA_315_5881_WR = ~(AWRL_N & AWRU_N) & AWR_N_OLD & STV_5881_SEL;
	bit        SEGA_315_5881_ACT;
	
	bit [25:1] SEGA_315_5881_MEM_A;
	bit        SEGA_315_5881_MEM_RD;
	SEGA_315_5881 SEGA_315_5881 (
		.CLK(CLK),
		.RST_N(RST_N),
		
		.RES_N(RES_N),
		
		.KEY(STV_5881_KEY),
		
		.CE_R(CE_R),
		.CE_F(CE_F),
		.ADDR(AA[3:1]),
		.DI(ADI),
		.DO(SEGA_315_5881_DO),
		.RD(SEGA_315_5881_RD),
		.WR(SEGA_315_5881_WR),
		.WAIT(SEGA_315_5881_WAIT),
		.ACT(SEGA_315_5881_ACT),
		
		.MEM_A(SEGA_315_5881_MEM_A),
		.MEM_DI(MEM_DI),
		.MEM_RD(SEGA_315_5881_MEM_RD),
		.MEM_RDY(MEM_RDY)
	);
	
	assign ADO = STV_5838_SEL ? SEGA_315_5838_DO : 
	             STV_5881_SEL ? SEGA_315_5881_DO : ABUS_DO;
	assign AWAIT_N = ~(ABUS_WAIT | SEGA_315_5838_WAIT | SEGA_315_5881_WAIT);
	assign ARQT_N = 1;
	
endmodule

module STV_CART (
	input              CLK,
	input              RST_N,
	
	input              STV_5838_MODE,
	input      [ 3: 0] STV_5881_MODE,
	input              STV_BATMAN_MODE,
	
	input              RES_N,
	
	input              CE_R,
	input              CE_F,
	input      [25: 0] AA,
	input      [15: 0] ADI,
	output     [15: 0] ADO,
	input      [ 1: 0] AFC,
	input              ACS0_N,
	input              ACS1_N,
	input              ACS2_N,
	input              ARD_N,
	input              AWRL_N,
	input              AWRU_N,
	input              ATIM0_N,
	input              ATIM2_N,
	output             AWAIT_N,
	output             ARQT_N,
	
	output     [25: 1] MEM_A,
	input      [15: 0] MEM_DI,
	output     [15: 0] MEM_DO,
	output     [ 1: 0] MEM_WE,
	output             MEM_RD,
	input              MEM_RDY,
	
	output     [24: 1] RAX_MEM_A,
	input      [15: 0] RAX_MEM_DI,
	output     [15: 0] RAX_MEM_DO,
	output             RAX_MEM_RD,
	output             RAX_MEM_WR,
	input              RAX_MEM_RDY,
	output     [15: 0] RAX_SOUND_L,
	output     [15: 0] RAX_SOUND_R
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
	wire STV_BATMAN_SEL = (AA[23:1] >= 24'h800000>>1 && AA[23:1] <= 24'h800001>>1) && ~ACS1_N && STV_BATMAN_MODE;
	
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
					if (CART_SEL && !(STV_5838_SEL || STV_5881_SEL || STV_BATMAN_SEL)) begin
						
					end
				end else if (!ARD_N && ARD_N_OLD) begin
					if (CART_SEL && !(STV_5838_SEL || STV_5881_SEL || STV_BATMAN_SEL)) begin
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
	
	//Acclaim RAX (Batman Forever)
	bit          RES_N_SYNCED;
	always @(posedge CLK or negedge RST_N) begin	
		if (!RST_N) begin
			RES_N_SYNCED <= 0;
		end else if (CE_R) begin
			RES_N_SYNCED <= RES_N;
		end
	end
	
	bit  [15: 0] RAX_DO;
	wire         RAX_RD = ~ARD_N & ARD_N_OLD & STV_BATMAN_SEL;
	wire         RAX_WR = ~(AWRL_N & AWRU_N) & AWR_N_OLD & STV_BATMAN_SEL;
	
	bit  [24: 0] RAX_ROM_A;
	bit          RAX_ROM_RD;
	
	bit  [15: 0] RAX_RAM_A;
	bit  [15: 0] RAX_RAM_DO;
	bit          RAX_RAM_RD;
	bit          RAX_RAM_WR;
	ACCLAIM_RAX RAX (
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_F(CE_F),
		.CE_R(CE_R),
		
		.RES_N(RES_N_SYNCED),
		
		.ADDR(AA[3:1]),
		.DI(ADI),
		.DO(RAX_DO),
		.RD(RAX_RD),
		.WR(RAX_WR ),
		
		.ROM_A(RAX_ROM_A),
		.ROM_DI(!RAX_ROM_A[0] ? {8'h00,RAX_MEM_DI_LATCH[15:8]} : {8'h00,RAX_MEM_DI_LATCH[7:0]}),
		.ROM_RD(RAX_ROM_RD),
		.ROM_RDY(RAX_MEM_RDY & RAX_MEM_RDY_LATCH),
		
		.RAM_A(RAX_RAM_A),
		.RAM_DI(RAX_MEM_DI_LATCH),
		.RAM_DO(RAX_RAM_DO),
		.RAM_RD(RAX_RAM_RD),
		.RAM_WR(RAX_RAM_WR),
		.RAM_RDY(RAX_MEM_RDY & RAX_MEM_RDY_LATCH),
		
		.SOUND_L(RAX_SOUND_L),
		.SOUND_R(RAX_SOUND_R)
	);
	
	bit  [15: 0] RAX_MEM_DI_LATCH;
	bit          RAX_MEM_RDY_LATCH;
	bit          RAX_ROM_SEL;
	bit  [24: 0] RAX_ROM_A_LATCH,ROM_A_OLD;
	bit          RAX_ROM_RD_PULSE;
	bit  [15: 0] RAX_RAM_A_LATCH,RAM_A_OLD;
	bit  [15: 0] RAX_RAM_DO_LATCH;
	bit          RAX_RAM_RD_PULSE,RAX_RAM_WR_PULSE;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			ROM_A_OLD <= '1;
			RAM_A_OLD <= '1;
		end else if (!RES_N_SYNCED) begin
			ROM_A_OLD <= '1;
			RAM_A_OLD <= '1;
		end else begin
			RAX_ROM_RD_PULSE <= 0;
			RAX_RAM_RD_PULSE <= 0;
			RAX_RAM_WR_PULSE <= 0;
			if (CE_F) begin
				RAX_ROM_A_LATCH <= RAX_ROM_A;
				RAX_ROM_RD_PULSE <= RAX_ROM_RD & RAX_ROM_A != ROM_A_OLD;
				RAX_ROM_SEL <= RAX_ROM_RD;
				
				RAX_RAM_A_LATCH <= RAX_RAM_A;
				RAX_RAM_DO_LATCH <= RAX_RAM_DO;
				RAX_RAM_RD_PULSE <= RAX_RAM_RD & RAX_RAM_A != RAM_A_OLD;
				RAX_RAM_WR_PULSE <= RAX_RAM_WR & RAX_RAM_A != RAM_A_OLD;
			end
			if (CE_R) begin
				if (RAX_ROM_RD) ROM_A_OLD <= RAX_ROM_A;
				else ROM_A_OLD <= '1;
				
				if (RAX_RAM_RD || RAX_RAM_WR) RAM_A_OLD <= RAX_RAM_A;
				else RAM_A_OLD <= '1;
			end
			RAX_MEM_RDY_LATCH <= RAX_MEM_RDY;
			RAX_MEM_DI_LATCH <= RAX_MEM_DI;
		end
	end
	
	assign RAX_MEM_A = RAX_ROM_SEL ? {1'b0,RAX_ROM_A_LATCH[23:1]} : {9'b100000000,RAX_RAM_A_LATCH[14:0]};
	assign RAX_MEM_DO = RAX_RAM_DO_LATCH;
	assign RAX_MEM_RD = RAX_ROM_SEL ? RAX_ROM_RD_PULSE : RAX_RAM_RD_PULSE;
	assign RAX_MEM_WR = RAX_ROM_SEL ? 1'b0             : RAX_RAM_WR_PULSE;
	
	
	assign ADO = STV_5838_SEL ? SEGA_315_5838_DO : 
	             STV_5881_SEL ? SEGA_315_5881_DO : ABUS_DO;
	assign AWAIT_N = ~(ABUS_WAIT | SEGA_315_5838_WAIT | SEGA_315_5881_WAIT);
	assign ARQT_N = 1;
	
endmodule

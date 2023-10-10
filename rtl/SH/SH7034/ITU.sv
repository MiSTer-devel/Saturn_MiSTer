module SH7034_ITU (
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	
	input             RES_N,
	
	input             TCLKA,
	input             TCLKB,
	input             TCLKC,
	input             TCLKD,
	input       [4:0] TIOCAI,
	input       [4:0] TIOCBI,
	output reg  [4:0] TIOCAO,
	output reg  [4:0] TIOCBO,
	output reg        TOCXA4,
	output reg        TOCXB4,
	
	input             CLK2_CE,
	input             CLK4_CE,
	input             CLK8_CE,
	
	input      [27:0] IBUS_A,
	input      [31:0] IBUS_DI,
	output     [31:0] IBUS_DO,
	input       [3:0] IBUS_BA,
	input             IBUS_WE,
	input             IBUS_REQ,
	output            IBUS_BUSY,
	output            IBUS_ACT,
	
	output      [4:0] IMIA_IRQ,
	output      [4:0] IMIB_IRQ,
	output      [4:0] OVI_IRQ
);
	import SH7034_PKG::*;

	TSTR_t      TSTR;
	TSNC_t      TSNC;
	TMDR_t      TMDR;
	TFCR_t      TFCR;
	TOCR_t      TOCR;
	TCR_t       TCR[5];
	TIOR_t      TIOR[5];
	TIER_t      TIER[5];
	TSR_t       TSR[5];
	TCNT_t      TCNT[5];
	GRx_t       GRA[5];
	GRx_t       GRB[5];
	BRx_t       BRA[2];
	BRx_t       BRB[2];
	TSR_t       TSR_READED;
	
	wire REG_SEL = (IBUS_A >= 28'h5FFFF00 && IBUS_A <= 28'h5FFFF3F);
	
	//Clock selector	
//	bit         TCNT_CE[5];
	bit         TCLKA_OLD;
	bit         TCLKB_OLD;
	bit         TCLKC_OLD;
	bit         TCLKD_OLD;
	always @(posedge CLK or negedge RST_N) begin
		
		if (!RST_N) begin
			// synopsys translate_off
			TCNT_CE <= '{5{0}};
			TCLKA_OLD <= 0;
			TCLKB_OLD <= 0;
			TCLKC_OLD <= 0;
			TCLKD_OLD <= 0;
			// synopsys translate_on
		end
		else if (CE_R) begin
			TCLKA_OLD <= TCLKA;
			TCLKB_OLD <= TCLKB;
			TCLKC_OLD <= TCLKC;
			TCLKD_OLD <= TCLKD;
//			for (int i=0; i<5; i++) begin
//				case (TCR[i].TPSC)
//					3'b000: TCNT_CE[i] <= 1;
//					3'b001: TCNT_CE[i] <= CLK2_CE;
//					3'b010: TCNT_CE[i] <= CLK4_CE;
//					3'b011: TCNT_CE[i] <= CLK8_CE;
//					3'b100: TCNT_CE[i] <= (TCLKA ^ TCLKA_OLD) & ((TCLKA ^ TCR[i].CKEG[0]) | TCR[i].CKEG[1]);
//					3'b101: TCNT_CE[i] <= (TCLKB ^ TCLKB_OLD) & ((TCLKB ^ TCR[i].CKEG[0]) | TCR[i].CKEG[1]);
//					3'b110: TCNT_CE[i] <= (TCLKC ^ TCLKC_OLD) & ((TCLKC ^ TCR[i].CKEG[0]) | TCR[i].CKEG[1]);
//					3'b111: TCNT_CE[i] <= (TCLKD ^ TCLKD_OLD) & ((TCLKD ^ TCR[i].CKEG[0]) | TCR[i].CKEG[1]);
//				endcase
//			end
		end
	end
	
	bit         TCNT_CE[5];
	always_comb begin
		for (int i=0; i<5; i++) begin
			case (TCR[i].TPSC)
				3'b000: TCNT_CE[i] <= 1;
				3'b001: TCNT_CE[i] <= CLK2_CE;
				3'b010: TCNT_CE[i] <= CLK4_CE;
				3'b011: TCNT_CE[i] <= CLK8_CE;
				3'b100: TCNT_CE[i] <= (TCLKA ^ TCLKA_OLD) & ((TCLKA ^ TCR[i].CKEG[0]) | TCR[i].CKEG[1]);
				3'b101: TCNT_CE[i] <= (TCLKB ^ TCLKB_OLD) & ((TCLKB ^ TCR[i].CKEG[0]) | TCR[i].CKEG[1]);
				3'b110: TCNT_CE[i] <= (TCLKC ^ TCLKC_OLD) & ((TCLKC ^ TCR[i].CKEG[0]) | TCR[i].CKEG[1]);
				3'b111: TCNT_CE[i] <= (TCLKD ^ TCLKD_OLD) & ((TCLKD ^ TCR[i].CKEG[0]) | TCR[i].CKEG[1]);
			endcase
		end
	end
	
	bit   [4:0] TIOCAI_OLD;
	bit   [4:0] TIOCBI_OLD;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			// synopsys translate_off
			TIOCAI_OLD <= '0;
			TIOCBI_OLD <= '0;
			// synopsys translate_on
		end
		else if (CE_R) begin
			TIOCAI_OLD <= TIOCAI;
			TIOCBI_OLD <= TIOCBI;
		end
	end
	
	bit   [4:0] TCNT_COMPA;
	bit   [4:0] TCNT_COMPB;
	bit   [4:0] TIOCAI_EDGE;
	bit   [4:0] TIOCBI_EDGE;
	bit   [4:0] TCNT_CLR;
	bit   [4:0] TCNT_INC;
//	bit   [4:0] TCNT_DEC;
	always_comb begin
		bit [4:0] TCNT_EN;
		
		TCNT_EN = {TSTR.STR4,TSTR.STR3,TSTR.STR2,TSTR.STR1,TSTR.STR0};
		
		for (int i=0; i<5; i++) begin
			TIOCAI_EDGE[i] <= (TIOCAI[i] ^ TIOCAI_OLD[i]) & ((TIOCAI[i] ^ TIOR[i].IOA[0]) | TIOR[i].IOA[1]);
			TIOCBI_EDGE[i] <= (TIOCBI[i] ^ TIOCBI_OLD[i]) & ((TIOCBI[i] ^ TIOR[i].IOB[0]) | TIOR[i].IOB[1]);
			
			TCNT_COMPA[i] <= (TCNT[i] == GRA[i]);
			TCNT_COMPB[i] <= (TCNT[i] == GRB[i]);
			
			TCNT_INC[i] <= 0;
			//TCNT_DEC[i] <= 0;
			TCNT_CLR[i] <= 0;
//			if (TCNT_CE[i]) begin
				TCNT_INC[i] <= TCNT_EN[i];
			
				case (TCR[i].CCLR)
					2'b00:;
					2'b01: if ((TCNT_COMPA[i] && !TIOR[i].IOA[2]) || (TIOCAI_EDGE[i] && TIOR[i].IOA[2])) TCNT_CLR[i] <= 1;
					2'b10: if ((TCNT_COMPB[i] && !TIOR[i].IOB[2]) || (TIOCBI_EDGE[i] && TIOR[i].IOB[2])) TCNT_CLR[i] <= 1;
					2'b11: ;
				endcase
//			end
		end
	end
	
	wire [4:0] TSR_WRITE = {REG_SEL && IBUS_A[5:2] == 6'h35>>2 && IBUS_BA[2] && IBUS_WE && IBUS_REQ,
	                        REG_SEL && IBUS_A[5:2] == 6'h25>>2 && IBUS_BA[2] && IBUS_WE && IBUS_REQ,
									REG_SEL && IBUS_A[5:2] == 6'h1B>>2 && IBUS_BA[0] && IBUS_WE && IBUS_REQ,
									REG_SEL && IBUS_A[5:2] == 6'h11>>2 && IBUS_BA[2] && IBUS_WE && IBUS_REQ,
									REG_SEL && IBUS_A[5:2] == 6'h07>>2 && IBUS_BA[0] && IBUS_WE && IBUS_REQ};
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			TSR <= '{5{TSR_INIT}};
			TIOCAO <= '0;
			TIOCBO <= '0;
		end
		else if (CE_R) begin
			for (int i=0; i<5; i++) begin
				if (TCNT_CE[i]) begin
					casex (TIOR[i].IOA)
						3'b000: begin                                          TSR[i].IMFA <= TSR[i].IMFA | TCNT_COMPA[i]; end
						3'b001: begin TIOCAO[i] <= ~TCNT_COMPA[i];             TSR[i].IMFA <= TSR[i].IMFA | TCNT_COMPA[i]; end
						3'b010: begin TIOCAO[i] <=  TCNT_COMPA[i];             TSR[i].IMFA <= TSR[i].IMFA | TCNT_COMPA[i]; end
						3'b011: begin TIOCAO[i] <=  TCNT_COMPA[i] ^ TIOCAO[i]; TSR[i].IMFA <= TSR[i].IMFA | TCNT_COMPA[i]; end
						3'b1??: begin                                          TSR[i].IMFA <= TSR[i].IMFA | TIOCAI_EDGE[i]; end
						default:;
					endcase
					casex (TIOR[i].IOB)
						3'b000: begin                                          TSR[i].IMFB <= TSR[i].IMFB | TCNT_COMPB[i]; end
						3'b001: begin TIOCBO[i] <= ~TCNT_COMPB[i];             TSR[i].IMFB <= TSR[i].IMFB | TCNT_COMPB[i]; end
						3'b010: begin TIOCBO[i] <=  TCNT_COMPB[i];             TSR[i].IMFB <= TSR[i].IMFB | TCNT_COMPB[i]; end
						3'b011: begin TIOCBO[i] <=  TCNT_COMPB[i] ^ TIOCBO[i]; TSR[i].IMFB <= TSR[i].IMFB | TCNT_COMPB[i]; end
						3'b1??: begin                                          TSR[i].IMFB <= TSR[i].IMFB | TIOCBI_EDGE[i]; end
						default:;
					endcase
					
					if (TCNT_INC[i] && TCNT[i] == 16'hFFFF) begin
						TSR[i].OVF <= 1;
					end
				end
				
				if (TSR_WRITE[i]) begin
					if (!IBUS_DI[0] /*&& TSR[i].IMFA*/ && TSR_READED.IMFA) TSR[i].IMFA <= 0;
					if (!IBUS_DI[1] /*&& TSR[i].IMFB*/ && TSR_READED.IMFB) TSR[i].IMFB <= 0;
					if (!IBUS_DI[2] /*&& TSR[i].OVF*/ && TSR_READED.OVF)  TSR[i].OVF <= 0;
				end
			end
		end
	end

	assign TOCXA4 = 0;
	assign TOCXB4 = 0;


	assign IMIA_IRQ[0] = TSR[0].IMFA & TIER[0].IMIEA;
	assign IMIB_IRQ[0] = TSR[0].IMFB & TIER[0].IMIEB;
	assign OVI_IRQ[0]  = TSR[0].OVF  & TIER[0].OVIE;
	assign IMIA_IRQ[1] = TSR[1].IMFA & TIER[1].IMIEA;
	assign IMIB_IRQ[1] = TSR[1].IMFB & TIER[1].IMIEB;
	assign OVI_IRQ[1]  = TSR[1].OVF  & TIER[1].OVIE;
	assign IMIA_IRQ[2] = TSR[2].IMFA & TIER[2].IMIEA;
	assign IMIB_IRQ[2] = TSR[2].IMFB & TIER[2].IMIEB;
	assign OVI_IRQ[2]  = TSR[2].OVF  & TIER[2].OVIE;
	assign IMIA_IRQ[3] = TSR[3].IMFA & TIER[3].IMIEA;
	assign IMIB_IRQ[3] = TSR[3].IMFB & TIER[3].IMIEB;
	assign OVI_IRQ[3]  = TSR[3].OVF  & TIER[3].OVIE;
	assign IMIA_IRQ[4] = TSR[4].IMFA & TIER[4].IMIEA;
	assign IMIB_IRQ[4] = TSR[4].IMFB & TIER[4].IMIEB;
	assign OVI_IRQ[4]  = TSR[4].OVF  & TIER[4].OVIE;
	
	//Registers
	always @(posedge CLK or negedge RST_N) begin
		bit [7:0] TEMP;
		
		if (!RST_N) begin
			TSTR <= TSTR_INIT;
			TSNC <= TSNC_INIT;
			TMDR <= TMDR_INIT;
			TFCR <= TFCR_INIT;
			TCR  <= '{5{TCR_INIT}};
			TIOR <= '{5{TIOR_INIT}};
			TIER <= '{5{TIER_INIT}};
			TCNT <= '{5{TCNT_INIT}};
			GRA <= '{5{GRx_INIT}};
			GRA <= '{5{GRx_INIT}};
			BRA <= '{2{BRx_INIT}};
			BRA <= '{2{BRx_INIT}};
			// synopsys translate_off
			
			// synopsys translate_on
		end
		else begin
			for (int i=0; i<5; i++) begin
				if (TCNT_INC[i] && TCNT_CE[i] && CE_R) begin
					TCNT[i] <= TCNT[i] + 16'd1;
				end
				
				if (TIOR[i].IOA[2] && TIOCAI_EDGE[i] && CE_R) GRA[i] <= TCNT[i];
				if (TIOR[i].IOB[2] && TIOCBI_EDGE[i] && CE_R) GRB[i] <= TCNT[i];
			end
			
			if (!RES_N) begin
				TSTR <= TSTR_INIT;
				TSNC <= TSNC_INIT;
				TMDR <= TMDR_INIT;
				TFCR <= TFCR_INIT;
				TCR  <= '{5{TCR_INIT}};
				TIOR <= '{5{TIOR_INIT}};
				TIER <= '{5{TIER_INIT}};
				TCNT <= '{5{TCNT_INIT}};
				GRA <= '{5{GRx_INIT}};
				GRA <= '{5{GRx_INIT}};
				BRA <= '{2{BRx_INIT}};
				BRA <= '{2{BRx_INIT}};
			end else if (REG_SEL && IBUS_WE && IBUS_REQ && CE_R) begin
				case ({IBUS_A[5:2],2'b00})
					6'h00: begin
						if (IBUS_BA[3]) TSTR <= IBUS_DI[31:24] & TSTR_WMASK;
						if (IBUS_BA[2]) TSNC <= IBUS_DI[23:16] & TSNC_WMASK;
						if (IBUS_BA[1]) TMDR <= IBUS_DI[15: 8] & TMDR_WMASK;
						if (IBUS_BA[0]) TFCR <= IBUS_DI[ 7: 0] & TFCR_WMASK;
					end 
					6'h04: begin
						if (IBUS_BA[3]) TCR[0]         <= IBUS_DI[31:24] & TCR_WMASK;
						if (IBUS_BA[2]) TIOR[0]        <= IBUS_DI[23:16] & TIOR_WMASK;
						if (IBUS_BA[1]) TIER[0]        <= IBUS_DI[15: 8] & TIER_WMASK;
					end 
					6'h08: begin
						if (IBUS_BA[3]) TCNT[0][15: 8] <= IBUS_DI[31:24] & TCNT_WMASK[15: 8];
						if (IBUS_BA[2]) TCNT[0][ 7: 0] <= IBUS_DI[23:16] & TCNT_WMASK[ 7: 0];
						if (IBUS_BA[1]) GRA[0][15: 8]  <= IBUS_DI[15: 8] & GRx_WMASK[15: 8];
						if (IBUS_BA[0]) GRA[0][ 7: 0]  <= IBUS_DI[ 7: 0] & GRx_WMASK[ 7: 0];
					end 
					6'h0C: begin
						if (IBUS_BA[3]) GRB[0][15: 8]  <= IBUS_DI[31:24] & GRx_WMASK[15: 8];
						if (IBUS_BA[2]) GRB[0][ 7: 0]  <= IBUS_DI[23:16] & GRx_WMASK[ 7: 0];
						if (IBUS_BA[1]) TCR[1]         <= IBUS_DI[15: 8] & TCR_WMASK;
						if (IBUS_BA[0]) TIOR[1]        <= IBUS_DI[ 7: 0] & TIOR_WMASK;
					end 
					6'h10: begin
						if (IBUS_BA[3]) TIER[1]        <= IBUS_DI[31:24] & TIER_WMASK;
						if (IBUS_BA[1]) TCNT[1][15: 8] <= IBUS_DI[15: 8] & TCNT_WMASK[15: 8];
						if (IBUS_BA[0]) TCNT[1][ 7: 0] <= IBUS_DI[ 7: 0] & TCNT_WMASK[ 7: 0];
					end 
					6'h14: begin
						if (IBUS_BA[3]) GRA[1][15: 8]  <= IBUS_DI[31:24] & GRx_WMASK[15: 8];
						if (IBUS_BA[2]) GRA[1][ 7: 0]  <= IBUS_DI[23:16] & GRx_WMASK[ 7: 0];
						if (IBUS_BA[1]) GRB[1][15: 8]  <= IBUS_DI[15: 8] & GRx_WMASK[15: 8];
						if (IBUS_BA[0]) GRB[1][ 7: 0]  <= IBUS_DI[ 7: 0] & GRx_WMASK[ 7: 0];
					end 
					6'h18: begin
						if (IBUS_BA[3]) TCR[2]         <= IBUS_DI[31:24] & TCR_WMASK;
						if (IBUS_BA[2]) TIOR[2]        <= IBUS_DI[23:16] & TIOR_WMASK;
						if (IBUS_BA[1]) TIER[2]        <= IBUS_DI[15: 8] & TIER_WMASK;
					end 
					6'h1C: begin
						if (IBUS_BA[3]) TCNT[2][15: 8] <= IBUS_DI[31:24] & TCNT_WMASK[15: 8];
						if (IBUS_BA[2]) TCNT[2][ 7: 0] <= IBUS_DI[23:16] & TCNT_WMASK[ 7: 0];
						if (IBUS_BA[1]) GRA[2][15: 8]  <= IBUS_DI[15: 8] & GRx_WMASK[15: 8];
						if (IBUS_BA[0]) GRA[2][ 7: 0]  <= IBUS_DI[ 7: 0] & GRx_WMASK[ 7: 0];
					end 
					6'h20: begin
						if (IBUS_BA[3]) GRB[2][15: 8]  <= IBUS_DI[31:24] & GRx_WMASK[15: 8];
						if (IBUS_BA[2]) GRB[2][ 7: 0]  <= IBUS_DI[23:16] & GRx_WMASK[ 7: 0];
						if (IBUS_BA[1]) TCR[3]         <= IBUS_DI[15: 8] & TCR_WMASK;
						if (IBUS_BA[0]) TIOR[3]        <= IBUS_DI[ 7: 0] & TIOR_WMASK;
					end 
					6'h24: begin
						if (IBUS_BA[3]) TIER[3]        <= IBUS_DI[31:24] & TIER_WMASK;
						if (IBUS_BA[1]) TCNT[3][15: 8] <= IBUS_DI[15: 8] & TCNT_WMASK[15: 8];
						if (IBUS_BA[0]) TCNT[3][ 7: 0] <= IBUS_DI[ 7: 0] & TCNT_WMASK[ 7: 0];
					end 
					6'h28: begin
						if (IBUS_BA[3]) GRA[3][15: 8]  <= IBUS_DI[31:24] & GRx_WMASK[15: 8];
						if (IBUS_BA[2]) GRA[3][ 7: 0]  <= IBUS_DI[23:16] & GRx_WMASK[ 7: 0];
						if (IBUS_BA[1]) GRB[3][15: 8]  <= IBUS_DI[15: 8] & GRx_WMASK[15: 8];
						if (IBUS_BA[0]) GRB[3][ 7: 0]  <= IBUS_DI[ 7: 0] & GRx_WMASK[ 7: 0];
					end 
					6'h2C: begin
						if (IBUS_BA[3]) BRA[0][15: 8]  <= IBUS_DI[31:24] & BRx_WMASK[15: 8];
						if (IBUS_BA[2]) BRA[0][ 7: 0]  <= IBUS_DI[23:16] & BRx_WMASK[ 7: 0];
						if (IBUS_BA[1]) BRB[0][15: 8]  <= IBUS_DI[15: 8] & BRx_WMASK[15: 8];
						if (IBUS_BA[0]) BRB[0][ 7: 0]  <= IBUS_DI[ 7: 0] & BRx_WMASK[ 7: 0];
					end 
					6'h30: begin
						if (IBUS_BA[1]) TCR[4]         <= IBUS_DI[15: 8] & TCR_WMASK;
						if (IBUS_BA[0]) TIOR[4]        <= IBUS_DI[ 7: 0] & TIOR_WMASK;
					end 
					6'h34: begin
						if (IBUS_BA[3]) TIER[4]        <= IBUS_DI[31:24] & TIER_WMASK;
						if (IBUS_BA[1]) TCNT[4][15: 8] <= IBUS_DI[15: 8] & TCNT_WMASK[15: 8];
						if (IBUS_BA[0]) TCNT[4][ 7: 0] <= IBUS_DI[ 7: 0] & TCNT_WMASK[ 7: 0];
					end 
					6'h38: begin
						if (IBUS_BA[3]) GRA[4][15: 8]  <= IBUS_DI[31:24] & GRx_WMASK[15: 8];
						if (IBUS_BA[2]) GRA[4][ 7: 0]  <= IBUS_DI[23:16] & GRx_WMASK[ 7: 0];
						if (IBUS_BA[1]) GRB[4][15: 8]  <= IBUS_DI[15: 8] & GRx_WMASK[15: 8];
						if (IBUS_BA[0]) GRB[4][ 7: 0]  <= IBUS_DI[ 7: 0] & GRx_WMASK[ 7: 0];
					end 
					6'h3C: begin
						if (IBUS_BA[3]) BRA[1][15: 8]  <= IBUS_DI[31:24] & BRx_WMASK[15: 8];
						if (IBUS_BA[2]) BRA[1][ 7: 0]  <= IBUS_DI[23:16] & BRx_WMASK[ 7: 0];
						if (IBUS_BA[1]) BRB[1][15: 8]  <= IBUS_DI[15: 8] & BRx_WMASK[15: 8];
						if (IBUS_BA[0]) BRB[1][ 7: 0]  <= IBUS_DI[ 7: 0] & BRx_WMASK[ 7: 0];
					end 
					default:;
				endcase
			end
			
			for (int i=0; i<5; i++) begin
				if (TCNT_CLR[i] && TCNT_CE[i] && CE_R) begin
					TCNT[i] <= '0;
				end
			end
		end
	end
	
	bit [31:0] REG_DO;
	always @(posedge CLK or negedge RST_N) begin		
		if (!RST_N) begin
			REG_DO <= '0;
		end
		else if (CE_F) begin
			if (REG_SEL && !IBUS_WE && IBUS_REQ) begin
				case ({IBUS_A[5:2],2'b00})
					6'h00: REG_DO <= {TSTR & TSTR_RMASK,TSNC & TSNC_RMASK,TMDR & TMDR_RMASK,TFCR & TFCR_RMASK};
					6'h04: begin REG_DO <= {TCR[0] & TCR_RMASK,TIOR[0] & TIOR_RMASK,TIER[0] & TIER_RMASK,TSR[0] & TSR_RMASK}; TSR_READED <= TSR[0]; end
					6'h08: REG_DO <= {TCNT[0] & TCNT_RMASK,GRA[0] & GRx_RMASK};
					6'h0C: REG_DO <= {GRB[0] & GRx_RMASK,TCR[1] & TCR_RMASK,TIOR[1] & TIOR_RMASK};
					6'h10: begin REG_DO <= {TIER[4] & TIER_RMASK,TSR[1] & TSR_RMASK,TCNT[1] & TCNT_RMASK}; TSR_READED <= TSR[1]; end
					6'h14: REG_DO <= {GRA[1] & GRx_RMASK,GRB[1] & GRx_RMASK};
					6'h18: begin REG_DO <= {TCR[2] & TCR_RMASK,TIOR[2] & TIOR_RMASK,TIER[2] & TIER_RMASK,TSR[2] & TSR_RMASK}; TSR_READED <= TSR[2]; end
					6'h1C: REG_DO <= {TCNT[2] & TCNT_RMASK,GRA[2] & GRx_RMASK};
					6'h20: REG_DO <= {GRB[2] & GRx_RMASK,TCR[3] & TCR_RMASK,TIOR[3] & TIOR_RMASK};
					6'h24: begin REG_DO <= {TIER[3] & TIER_RMASK,TSR[3] & TSR_RMASK,TCNT[3] & TCNT_RMASK}; TSR_READED <= TSR[3]; end
					6'h28: REG_DO <= {GRA[3] & GRx_RMASK,GRB[3] & GRx_RMASK};
					6'h2C: REG_DO <= {BRA[0] & BRx_RMASK,BRB[0] & BRx_RMASK};
					6'h30: REG_DO <= {16'h0000,TCR[4] & TCR_RMASK,TIOR[4] & TIOR_RMASK};
					6'h34: begin REG_DO <= {TIER[4] & TIER_RMASK,TSR[4] & TSR_RMASK,TCNT[4] & TCNT_RMASK}; TSR_READED <= TSR[4]; end
					6'h38: REG_DO <= {GRA[4] & GRx_RMASK,GRB[4] & GRx_RMASK};
					6'h3C: REG_DO <= {BRA[1] & BRx_RMASK,BRB[1] & BRx_RMASK};
					default:;
				endcase
			end
		end
	end
	
	assign IBUS_DO = REG_SEL ? REG_DO : 8'h00;
	assign IBUS_BUSY = 0;
	assign IBUS_ACT = REG_SEL;
	
endmodule 

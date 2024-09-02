module SH7604_FRT (
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	input             EN,
	
	input             RES_N,
	input             SBY,
	
	output reg        FTOA,
	output reg        FTOB,
	input             FTCI,
	input             FTI,
	
	input             CLK4_CE,
	input             CLK8_CE,
	input             CLK32_CE,
	input             CLK128_CE,
	
	input      [31:0] IBUS_A,
	input      [31:0] IBUS_DI,
	output     [31:0] IBUS_DO,
	input       [3:0] IBUS_BA,
	input             IBUS_WE,
	input             IBUS_REQ,
	output            IBUS_BUSY,
	output            IBUS_ACT,
	
	output            ICI_IRQ,
	output            OCIA_IRQ,
	output            OCIB_IRQ,
	output            OVI_IRQ
);

	import SH7604_PKG::*;
	
	FRC_t       FRC;
	OCR_t       OCRA;
	OCR_t       OCRB;
	FICR_t      ICR;
	TIER_t      TIER;
	FTCSR_t     FTCSR;
	TCR_t       TCR;
	TOCR_t      TOCR;
	
	//Clock selector
	bit         FTCI_OLD;
	always @(posedge CLK) begin
		FTCI_OLD <= FTCI;
	end
	
	bit         FRC_CE;
	always_comb begin
		case (TCR.CKS)
			2'b00: FRC_CE = CLK8_CE;
			2'b01: FRC_CE = CLK32_CE;
			2'b10: FRC_CE = CLK128_CE;
			2'b11: FRC_CE = FTCI & ~FTCI_OLD;
		endcase
	end
	
	wire REG_SEL = (IBUS_A >= 32'hFFFFFE10 && IBUS_A <= 32'hFFFFFE19);
	wire FTCSR_WRITE = REG_SEL && IBUS_A[3:0] == 4'h1 && IBUS_WE && IBUS_REQ;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			FTCSR.OCFA <= 0;
			FTCSR.OCFB <= 0;
			FTCSR.OVF <= 0;
		end
		else if (CE_R) begin
			if (!RES_N || SBY) begin
				FTCSR.OCFA <= 0;
				FTCSR.OCFB <= 0;
				FTCSR.OVF <= 0;
			end else if (EN) begin
				if (FRC_CE) begin
					if (FRC == OCRA) begin
						FTOA <= TOCR.OLVLA;
						FTCSR.OCFA <= 1;
					end
					if (FRC == OCRB) begin
						FTOB <= TOCR.OLVLB;
						FTCSR.OCFB <= 1;
					end
					
					if (FRC == 16'hFFFF) begin
						FTCSR.OVF <= 1;
					end
				end
				
				if (FTCSR_WRITE) begin
					if (!IBUS_DI[19] && FTCSR_READED[3] && FTCSR.OCFA) FTCSR.OCFA <= 0;
					if (!IBUS_DI[18] && FTCSR_READED[2] && FTCSR.OCFB) FTCSR.OCFB <= 0;
					if (!IBUS_DI[17] && FTCSR_READED[1] && FTCSR.OVF) FTCSR.OVF <= 0;
				end
			end
		end
	end
	
	wire ICR_READ = REG_SEL && IBUS_A[3:0] == 4'h9 && !IBUS_WE && IBUS_REQ;
	always @(posedge CLK or negedge RST_N) begin
		bit         CAPT;
		bit         FTI_OLD;
		bit         ICR_READ_OLD;
		
		if (!RST_N) begin
			ICR <= 16'h0000;
			FTCSR.ICF <= 0;
			CAPT <= 0;
			FTI_OLD <= 0;
			ICR_READ_OLD <= 0;
		end
		else if (CE_R) begin
			if (!RES_N || SBY) begin
				ICR <= 16'h0000;
				FTCSR.ICF <= 0;
				CAPT <= 0;
				FTI_OLD <= 0;
				ICR_READ_OLD <= 0;
			end else if (EN) begin
				FTI_OLD <= FTI;
				CAPT <= ~(FTI ^ TCR.IEDG) & (FTI_OLD ^ TCR.IEDG);
				
				ICR_READ_OLD <= ICR_READ;
				if (ICR_READ && !ICR_READ_OLD && CAPT) begin
					CAPT <= 1;
				end
				else if (CAPT) begin
					ICR <= FRC;
					FTCSR.ICF <= 1;
				end
				
				if (FTCSR_WRITE) begin
					if (!IBUS_DI[23] && FTCSR_READED[7] && FTCSR.ICF) FTCSR.ICF <= 0;
				end
			end
		end
	end
	
	assign ICI_IRQ = FTCSR.ICF & TIER.ICIE;
	assign OCIA_IRQ = FTCSR.OCFA & TIER.OCIAE;
	assign OCIB_IRQ = FTCSR.OCFB & TIER.OCIBE;
	assign OVI_IRQ = FTCSR.OVF & TIER.OVIE;
	
	//Registers
	always @(posedge CLK or negedge RST_N) begin
		bit [7:0] TEMP;
		
		if (!RST_N) begin
			TIER <= TIER_INIT;
			FRC  <= FRC_INIT;
			OCRA <= OCR_INIT;
			OCRB <= OCR_INIT;
			TCR  <= TCR_INIT;
			TOCR <= TOCR_INIT;
			FTCSR.CCLRA <= 0;
			FTCSR.UNUSED <= '0;
			// synopsys translate_off
			TEMP <= 8'h00;
			// synopsys translate_on
		end
		else if (CE_R) begin
			if (FRC_CE) begin
				FRC <= FRC + 16'd1;
			end
			
			if (!RES_N || SBY) begin
				TIER <= TIER_INIT;
				FRC  <= FRC_INIT;
				OCRA <= OCR_INIT;
				OCRB <= OCR_INIT;
				TCR  <= TCR_INIT;
				TOCR <= TOCR_INIT;
				FTCSR.CCLRA <= 0;
				FTCSR.UNUSED <= '0;
			end
			else if (REG_SEL && IBUS_WE && IBUS_REQ) begin
				case (IBUS_A[3:0])
					4'h0: TIER <= IBUS_DI[31:24] & TIER_WMASK;
					4'h1: FTCSR.CCLRA <= IBUS_DI[16];
					4'h2: TEMP <= IBUS_DI[15:8];
					4'h3: FRC <= {TEMP,IBUS_DI[7:0]} & FRC_WMASK;
					4'h4: TEMP <= IBUS_DI[31:24];
					4'h5: if (!TOCR.OCRS) OCRA <= {TEMP,IBUS_DI[23:16]} & OCR_WMASK; 
					      else OCRB <= {TEMP,IBUS_DI[23:16]} & OCR_WMASK;
					4'h6: TCR <= IBUS_DI[15:8] & TCR_WMASK;
					4'h7: TOCR <= (IBUS_DI[7:0] & TOCR_WMASK) | TOCR_INIT;
					default:;
				endcase
			end
			
			if (FRC == OCRA && FTCSR.CCLRA && FRC_CE) begin
				FRC <= 16'h0000;
			end
		end
	end
	
	bit [ 7: 0] REG_DO;
	bit [ 7: 0] FTCSR_READED;
	bit         BUSY;
	always @(posedge CLK or negedge RST_N) begin
		bit [7:0] TEMP;
		bit [31:0] OCR;
		
		if (!RST_N) begin
			REG_DO <= '0;
			BUSY <= 0;
		end
		else if (CE_F) begin
			if (REG_SEL && !IBUS_WE && IBUS_REQ) begin
				OCR = !TOCR.OCRS ? OCRA : OCRB;
				case (IBUS_A[3:0])
					4'h0:       REG_DO <= TIER & TIER_RMASK;
					4'h1: begin REG_DO <= FTCSR & FTCSR_RMASK; FTCSR_READED <= FTCSR; end
					4'h2: begin {REG_DO,TEMP} <= FRC; BUSY <= 1; end
					4'h3:       REG_DO <= TEMP; 
					4'h4: begin REG_DO <= OCR[15:8]; 
					            TEMP   <= OCR[7:0]; end
					4'h5:       REG_DO <= TEMP;
					4'h6:       REG_DO <= TCR & TCR_RMASK;
					4'h7:       REG_DO <= (TOCR & TOCR_RMASK) | TOCR_INIT;
					4'h8:       REG_DO <= TEMP;
					4'h9: begin REG_DO <= ICR[15:8]; 
					            TEMP   <= ICR[7:0]; end
					default:;
				endcase
			end
			
			if (CLK4_CE && BUSY) BUSY <= 0;
		end
	end
	
	assign IBUS_DO = REG_SEL ? {4{REG_DO}} : '0;
	assign IBUS_BUSY = BUSY;
	assign IBUS_ACT = REG_SEL;
	
endmodule

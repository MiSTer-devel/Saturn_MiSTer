module SH7604_WDT
#(parameter bit DISABLE=0)
(
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	input             EN,
	
	input             RES_N,
	input             SBY,
	
	output reg        WDTOVF_N,
	
	input             CLK2_CE,
	input             CLK64_CE,
	input             CLK128_CE,
	input             CLK256_CE,
	input             CLK512_CE,
	input             CLK1024_CE,
	input             CLK4096_CE,
	input             CLK8192_CE,
	
	input      [31:0] IBUS_A,
	input      [31:0] IBUS_DI,
	output     [31:0] IBUS_DO,
	input       [3:0] IBUS_BA,
	input             IBUS_WE,
	input             IBUS_REQ,
	output            IBUS_BUSY,
	output            IBUS_ACT,
	
	output            ITI_IRQ,
	output            PRES,
	output            MRES
);

	import SH7604_PKG::*;
	
	WTCNT_t     WTCNT;
	WTCSR_t     WTCSR;
	RSTCSR_t    RSTCSR;
	bit         WRES;
	
	//Clock selector
	bit         WT_CE;
	always_comb begin
		case (WTCSR.CKS)
			3'b000: WT_CE = CLK2_CE;
			3'b001: WT_CE = CLK64_CE;
			3'b010: WT_CE = CLK128_CE;
			3'b011: WT_CE = CLK256_CE;
			3'b100: WT_CE = CLK512_CE;
			3'b101: WT_CE = CLK1024_CE;
			3'b110: WT_CE = CLK4096_CE;
			3'b111: WT_CE = CLK8192_CE;
		endcase
	end
	
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			// synopsys translate_off
			WDTOVF_N <= 1;
			WRES <= 0;
			// synopsys translate_onn
		end
		else begin
			if (!RES_N) begin
				WDTOVF_N <= 1;
				WRES <= 0;
			end else if (EN && CE_R && !DISABLE) begin
				if (WT_CE) begin
					if (WTCNT == 8'hFF && WTCSR.WTIT) begin
						WDTOVF_N <= 0;
						WRES <= RSTCSR.RSTE & ~RSTCSR.RSTS;
					end
				end
				
				if (!WDTOVF_N && CLK128_CE) WDTOVF_N <= 1;
				if (WRES && CLK512_CE) WRES <= 0;
			end
		end
	end	
	
	assign PRES = WRES & ~RSTCSR.RSTS;
	assign MRES = WRES &  RSTCSR.RSTS;
	
	
	//Registers
	wire REG_SEL = (IBUS_A >= 32'hFFFFFE80 && IBUS_A <= 32'hFFFFFE83);
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			// synopsys translate_off
			WTCNT  <= WTCNT_INIT;
			WTCSR  <= WTCSR_INIT;
			RSTCSR <= RSTCSR_INIT;
			// synopsys translate_on
		end
		else begin
			if (!RES_N) begin
				WTCNT  <= WTCNT_INIT;
				WTCSR  <= WTCSR_INIT;
				RSTCSR <= RSTCSR_INIT;
			end else if (EN && CE_R && !DISABLE) begin
				if (WT_CE) begin
					if (WTCSR.TME) begin
						WTCNT <= WTCNT + 8'd1;
					end
					
					if (WTCNT == 8'hFF) begin
						if (!WTCSR.WTIT) begin
							WTCSR.OVF <= 1;
						end
						else begin
							RSTCSR.WOVF <= 1;
							WTCSR <= 8'h18;
						end
					end
				end
				
				if (!RES_N) begin
					WTCNT  <= WTCNT_INIT;
					WTCSR  <= WTCSR_INIT;
					RSTCSR <= RSTCSR_INIT;
				end else if (SBY) begin
					WTCNT <= WTCNT_INIT;//?
					WTCSR[7:3] <= WTCSR_INIT[7:3];
					RSTCSR <= RSTCSR_INIT;
				end else if (REG_SEL && IBUS_WE && IBUS_REQ) begin
					case (IBUS_A[1:0])
						2'h0: begin
							if (IBUS_DI[15:8] == 8'h5A) WTCNT <= IBUS_DI[7:0] & WTCNT_WMASK;
							else if (IBUS_DI[15:8] == 8'hA5) begin
								WTCSR[6:0] <= IBUS_DI[6:0] & WTCSR_WMASK[6:0];
								if (!IBUS_DI[7]) WTCSR[7] <= 0;
								if (!IBUS_DI[5]) begin WTCNT <= 8'h00; WTCSR[7] <= 0; end//?
							end
						end
						2'h2:  begin
							if (IBUS_DI[15:8] == 8'h5A) RSTCSR[6:0] <= IBUS_DI[6:0] & RSTCSR_WMASK[6:0];
							else if (IBUS_DI[15:8] == 8'hA5 && !IBUS_DI[7]) RSTCSR[7] <= 0;
						end
						default:;
					endcase
				end
			end
		end
	end
	
	assign ITI_IRQ = WTCSR.OVF;
	
	
	bit [31:0] REG_DO;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			REG_DO <= '0;
		end
		else begin
			if (!RES_N) begin
				REG_DO <= '0;
			end else if (CE_F && !DISABLE) begin
				if (REG_SEL && !IBUS_WE && IBUS_REQ) begin
					case (IBUS_A[1:0])
						2'h0: REG_DO <= {4{WTCSR & WTCSR_RMASK}};
						2'h1: REG_DO <= {4{WTCNT & WTCNT_RMASK}};
						2'h2: REG_DO <= '0;
						2'h3: REG_DO <= {4{RSTCSR & RSTCSR_RMASK}};
						default:;
					endcase
				end
			end
		end
	end
	
	assign IBUS_DO = REG_SEL ? REG_DO : 8'h00;
	assign IBUS_BUSY = 0;
	assign IBUS_ACT = REG_SEL;
	
endmodule

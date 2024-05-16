module SH7034_UBC 
#(parameter bit DISABLE=0)
(
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	
	input             RES_N,
	
	input      [27:0] IBUS_A,
	input      [31:0] IBUS_DI,
	output     [31:0] IBUS_DO,
	input       [3:0] IBUS_BA,
	input             IBUS_WE,
	input             IBUS_REQ,
	output            IBUS_BUSY,
	output            IBUS_ACT,
	
	output            IRQ
);

	import SH7034_PKG::*;
	
	BAR_t      BARH;
	BAR_t      BARL;
	BAMR_t     BAMRL;
	BAMR_t     BAMRH;
	BBR_t      BBR;
	
	wire REG_SEL = (IBUS_A >= 28'h5FFFF90 && IBUS_A <= 28'h5FFFF99);
	
	//Registers
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			// synopsys translate_off
			BARH <= BAR_INIT;
			BARL <= BAR_INIT;
			BAMRL <= BAMR_INIT;
			BAMRH <= BAMR_INIT;
			BBR <= BBR_INIT;
			// synopsys translate_on
		end
		else begin
			if (!RES_N) begin
				BARH <= BAR_INIT;
				BARL <= BAR_INIT;
				BAMRL <= BAMR_INIT;
				BAMRH <= BAMR_INIT;
				BBR <= BBR_INIT;
			end else if (CE_R && !DISABLE) begin
				if (REG_SEL && IBUS_WE && IBUS_REQ) begin
					case ({IBUS_A[3:2],2'b00})
						4'h0: begin
							if (IBUS_BA[3]) BARH <= IBUS_DI[31:24] & BAR_WMASK[15: 8];
							if (IBUS_BA[2]) BARH <= IBUS_DI[23:16] & BAR_WMASK[ 7: 0];
							if (IBUS_BA[1]) BARL <= IBUS_DI[15: 8] & BAR_WMASK[15: 8];
							if (IBUS_BA[0]) BARL <= IBUS_DI[ 7: 0] & BAR_WMASK[ 7: 0];
						end
						4'h4: begin
							if (IBUS_BA[3]) BAMRH <= IBUS_DI[31:24] & BAMR_WMASK[15: 8];
							if (IBUS_BA[2]) BAMRH <= IBUS_DI[23:16] & BAMR_WMASK[ 7: 0];
							if (IBUS_BA[1]) BAMRL <= IBUS_DI[15: 8] & BAMR_WMASK[15: 8];
							if (IBUS_BA[0]) BAMRL <= IBUS_DI[ 7: 0] & BAMR_WMASK[ 7: 0];
						end
						4'h8: begin
							if (IBUS_BA[3]) BBR <= IBUS_DI[31:24] & BBR_WMASK[15: 8];
							if (IBUS_BA[2]) BBR <= IBUS_DI[23:16] & BBR_WMASK[ 7: 0];
						end
						default:;
					endcase
				end
			end
		end
	end
	
	assign IRQ = 0;
	
	
	bit [31:0] REG_DO;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			// synopsys translate_off
			REG_DO <= '0;
			// synopsys translate_on
		end
		else begin
			if (!RES_N) begin
				REG_DO <= '0;
			end else if (CE_F && !DISABLE) begin
				if (REG_SEL && !IBUS_WE && IBUS_REQ) begin
					case ({IBUS_A[3:2],2'b00})
						4'h0: REG_DO <= {BARH,BARL} & {BAR_RMASK,BAR_RMASK};
						4'h4: REG_DO <= {BAMRH,BAMRL} & {BAMR_RMASK,BAMR_RMASK};
						4'h8: REG_DO <= {BBR,16'h0000} & {BBR_RMASK,16'h0000};
						default:REG_DO <= '0;
					endcase
				end
			end
		end
	end
	
	assign IBUS_DO = REG_SEL ? REG_DO : '0;
	assign IBUS_BUSY = 0;
	assign IBUS_ACT = REG_SEL;

endmodule

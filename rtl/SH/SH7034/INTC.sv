module SH7034_INTC (
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	
	input             RES_N,
	input             NMI_N,
	input       [7:0] IRQ_N,
	output            IRQOUT_N,
	
	input       [3:0] INT_MASK,
	input             INT_ACK,
	input             INT_ACP,
	output reg  [3:0] INT_LVL,
	output reg  [7:0] INT_VEC,
	output reg        INT_REQ,
	
	input             VECT_REQ,
	output            VECT_WAIT,
	
	input      [27:0] IBUS_A,
	input      [31:0] IBUS_DI,
	output     [31:0] IBUS_DO,
	input       [3:0] IBUS_BA,
	input             IBUS_WE,
	input             IBUS_REQ,
	output            IBUS_BUSY,
	output            IBUS_ACT,
	
	input             VBUS_WAIT,
	
	input             UBC_IRQ,
	input             DMAC0_IRQ,
	input             DMAC1_IRQ,
	input             DMAC2_IRQ,
	input             DMAC3_IRQ,
	input             WDT_IRQ,
	input             BSC_IRQ,
	input             SCI0_ERI_IRQ,
	input             SCI0_RXI_IRQ,
	input             SCI0_TXI_IRQ,
	input             SCI0_TEI_IRQ,
	input             SCI1_ERI_IRQ,
	input             SCI1_RXI_IRQ,
	input             SCI1_TXI_IRQ,
	input             SCI1_TEI_IRQ,
	input       [4:0] ITU_IMIA_IRQ,
	input       [4:0] ITU_IMIB_IRQ,
	input       [4:0] ITU_OVI_IRQ
);

	import SH7034_PKG::*;
	
	const integer NMI_INT       = 0;
	const integer UBC_INT       = 1;
	const integer IRQ0_INT      = 2;
	const integer IRQ1_INT      = 3; 
	const integer IRQ2_INT      = 4; 
	const integer IRQ3_INT      = 5; 
	const integer IRQ4_INT      = 6;
	const integer IRQ5_INT      = 7;
	const integer IRQ6_INT      = 8;
	const integer IRQ7_INT      = 9; 
	const integer DMAC0_INT     = 10;
	const integer DMAC1_INT     = 11;
	const integer DMAC2_INT     = 12;
	const integer DMAC3_INT     = 13;
	const integer WDT_INT       = 14;
	const integer BSC_INT       = 15;
	const integer SCI0_ERI_INT  = 16;
	const integer SCI0_RXI_INT  = 17;
	const integer SCI0_TXI_INT  = 18;
	const integer SCI0_TEI_INT  = 19;
	const integer SCI1_ERI_INT  = 20;
	const integer SCI1_RXI_INT  = 21; 
	const integer SCI1_TXI_INT  = 22;
	const integer SCI1_TEI_INT  = 23;
	const integer ITU0_IMIA_INT = 24;
	const integer ITU0_IMIB_INT = 25;
	const integer ITU0_OVI_INT  = 26;
	const integer ITU1_IMIA_INT = 27; 
	const integer ITU1_IMIB_INT = 28;
	const integer ITU1_OVI_INT  = 29;
	const integer ITU2_IMIA_INT = 30;
	const integer ITU2_IMIB_INT = 31;
	const integer ITU2_OVI_INT  = 32;
	const integer ITU3_IMIA_INT = 33;
	const integer ITU3_IMIB_INT = 34;
	const integer ITU3_OVI_INT  = 35;
	const integer ITU4_IMIA_INT = 36;
	const integer ITU4_IMIB_INT = 37;
	const integer ITU4_OVI_INT  = 38;

	IPRA_t     IPRA;
	IPRB_t     IPRB;
	IPRC_t     IPRC;
	IPRD_t     IPRD;
	IPRE_t     IPRE;
	ICR_t      ICR;
	
	bit [ 3:0] LVL;
	bit [ 7:0] VEC;
	bit        NMI_REQ;
	bit [ 7:0] IRQ_REQ;
	bit [38:0] INT_PEND;
	bit        VBREQ;
	
	always @(posedge CLK or negedge RST_N) begin
		bit NMI_N_OLD;
		
		if (!RST_N) begin
			NMI_REQ <= 0;
		end
		else if (CE_R) begin	
			NMI_N_OLD <= NMI_N;
			if (~(NMI_N ^ ICR.NMIE) && (NMI_N_OLD ^ ICR.NMIE) && !NMI_REQ) begin
				NMI_REQ <= 1;
			end
			else if (INT_ACK && INT_PEND[NMI_INT]) begin
				NMI_REQ <= 0;
			end
		end
	end
	
	always @(posedge CLK or negedge RST_N) begin
		bit [7:0] IRQ_OLD[2];
		
		if (!RST_N) begin
			IRQ_OLD <= '{2{'0}};
			IRQ_REQ <= '0;
		end
		else if (CE_R) begin	
			IRQ_OLD[0] <= ~IRQ_N;
			IRQ_OLD[1] <= IRQ_OLD[0];
			IRQ_REQ <= '0;
			for (int i=0; i<8; i++) begin
				if (IRQ_OLD[0][i] && IRQ_OLD[1][i] && !IRQ_N[i]) begin
					IRQ_REQ[i] <= 1;
				end
			end
		end
	end
	
	always @(posedge CLK or negedge RST_N) begin
		bit INT_CLR;
		if (!RST_N) begin
			INT_REQ <= 0;
			INT_PEND <= '0;
		end else if (CE_R) begin	
			if (!INT_REQ) begin
				if (NMI_REQ)                                        begin INT_REQ <= 1'b1; INT_PEND[NMI_INT] <= 1; end
				else if (UBC_IRQ         && 4'hF        > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[UBC_INT] <= 1; end
				else if (IRQ_REQ[0]      && IPRA.IRQ0   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[IRQ0_INT] <= 1; end
				else if (IRQ_REQ[1]      && IPRA.IRQ1   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[IRQ1_INT] <= 1; end
				else if (IRQ_REQ[2]      && IPRA.IRQ2   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[IRQ2_INT] <= 1; end
				else if (IRQ_REQ[3]      && IPRA.IRQ3   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[IRQ3_INT] <= 1; end
				else if (IRQ_REQ[4]      && IPRB.IRQ4   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[IRQ4_INT] <= 1; end
				else if (IRQ_REQ[5]      && IPRB.IRQ5   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[IRQ5_INT] <= 1; end
				else if (IRQ_REQ[6]      && IPRB.IRQ6   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[IRQ6_INT] <= 1; end
				else if (IRQ_REQ[7]      && IPRB.IRQ7   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[IRQ7_INT] <= 1; end
				else if (DMAC0_IRQ       && IPRC.DMAC01 > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[DMAC0_INT] <= 1; end
				else if (DMAC1_IRQ       && IPRC.DMAC01 > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[DMAC1_INT] <= 1; end
				else if (DMAC2_IRQ       && IPRC.DMAC23 > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[DMAC2_INT] <= 1; end
				else if (DMAC3_IRQ       && IPRC.DMAC23 > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[DMAC3_INT] <= 1; end
				else if (WDT_IRQ         && IPRE.WDT    > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[WDT_INT] <= 1; end
				else if (BSC_IRQ         && IPRE.WDT    > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[BSC_INT] <= 1; end
				else if (SCI0_ERI_IRQ    && IPRD.SCI0   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[SCI0_ERI_INT] <= 1; end
				else if (SCI0_RXI_IRQ    && IPRD.SCI0   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[SCI0_RXI_INT] <= 1; end
				else if (SCI0_TXI_IRQ    && IPRD.SCI0   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[SCI0_TXI_INT] <= 1; end
				else if (SCI0_TEI_IRQ    && IPRD.SCI0   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[SCI0_TEI_INT] <= 1; end
				else if (SCI1_ERI_IRQ    && IPRE.SCI1   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[SCI1_ERI_INT] <= 1; end
				else if (SCI1_RXI_IRQ    && IPRE.SCI1   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[SCI1_RXI_INT] <= 1; end
				else if (SCI1_TXI_IRQ    && IPRE.SCI1   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[SCI1_TXI_INT] <= 1; end
				else if (SCI1_TEI_IRQ    && IPRE.SCI1   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[SCI1_TEI_INT] <= 1; end
				else if (ITU_IMIA_IRQ[0] && IPRC.ITU0   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[ITU0_IMIA_INT] <= 1; end
				else if (ITU_IMIB_IRQ[0] && IPRC.ITU0   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[ITU0_IMIB_INT] <= 1; end
				else if (ITU_OVI_IRQ[0]  && IPRC.ITU0   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[ITU0_OVI_INT] <= 1; end
				else if (ITU_IMIA_IRQ[1] && IPRC.ITU1   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[ITU1_IMIA_INT] <= 1; end
				else if (ITU_IMIB_IRQ[1] && IPRC.ITU1   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[ITU1_IMIB_INT] <= 1; end
				else if (ITU_OVI_IRQ[1]  && IPRC.ITU1   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[ITU1_OVI_INT] <= 1; end
				else if (ITU_IMIA_IRQ[2] && IPRD.ITU2   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[ITU2_IMIA_INT] <= 1; end
				else if (ITU_IMIB_IRQ[2] && IPRD.ITU2   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[ITU2_IMIB_INT] <= 1; end
				else if (ITU_OVI_IRQ[2]  && IPRD.ITU2   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[ITU2_OVI_INT] <= 1; end
				else if (ITU_IMIA_IRQ[3] && IPRD.ITU3   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[ITU3_IMIA_INT] <= 1; end
				else if (ITU_IMIB_IRQ[3] && IPRD.ITU3   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[ITU3_IMIB_INT] <= 1; end
				else if (ITU_OVI_IRQ[3]  && IPRD.ITU3   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[ITU3_OVI_INT] <= 1; end
				else if (ITU_IMIA_IRQ[4] && IPRD.ITU4   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[ITU4_IMIA_INT] <= 1; end
				else if (ITU_IMIB_IRQ[4] && IPRD.ITU4   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[ITU4_IMIB_INT] <= 1; end
				else if (ITU_OVI_IRQ[4]  && IPRD.ITU4   > INT_MASK) begin INT_REQ <= 1'b1; INT_PEND[ITU4_OVI_INT] <= 1; end
				else                                                begin INT_REQ <= 1'b0; end
			end else if (INT_CLR) begin
				INT_REQ <= 0;
				INT_PEND <= '0;
			end
		end else if (CE_F) begin
			INT_CLR <= 0;
			if (INT_REQ && VBREQ && !VBUS_WAIT) begin
				INT_CLR <= 1;
			end
		end
	end
	
	always_comb begin
		if      (INT_PEND[NMI_INT])       begin INT_LVL <= 4'hF;        INT_VEC <= 8'd11;  end
		else if (INT_PEND[UBC_INT])       begin INT_LVL <= 4'hF;        INT_VEC <= 8'd12;  end
		else if (INT_PEND[IRQ0_INT])      begin INT_LVL <= IPRA.IRQ0;   INT_VEC <= 8'd64;  end
		else if (INT_PEND[IRQ1_INT])      begin INT_LVL <= IPRA.IRQ1;   INT_VEC <= 8'd65;  end
		else if (INT_PEND[IRQ2_INT])      begin INT_LVL <= IPRA.IRQ2;   INT_VEC <= 8'd66;  end
		else if (INT_PEND[IRQ3_INT])      begin INT_LVL <= IPRA.IRQ3;   INT_VEC <= 8'd67;  end
		else if (INT_PEND[IRQ4_INT])      begin INT_LVL <= IPRB.IRQ4;   INT_VEC <= 8'd68;  end
		else if (INT_PEND[IRQ5_INT])      begin INT_LVL <= IPRB.IRQ5;   INT_VEC <= 8'd69;  end
		else if (INT_PEND[IRQ6_INT])      begin INT_LVL <= IPRB.IRQ6;   INT_VEC <= 8'd70;  end
		else if (INT_PEND[IRQ7_INT])      begin INT_LVL <= IPRB.IRQ7;   INT_VEC <= 8'd71;  end
		else if (INT_PEND[DMAC0_INT])     begin INT_LVL <= IPRC.DMAC01; INT_VEC <= 8'd72;  end
		else if (INT_PEND[DMAC1_INT])     begin INT_LVL <= IPRC.DMAC01; INT_VEC <= 8'd74;  end
		else if (INT_PEND[DMAC2_INT])     begin INT_LVL <= IPRC.DMAC23; INT_VEC <= 8'd76;  end
		else if (INT_PEND[DMAC3_INT])     begin INT_LVL <= IPRC.DMAC23; INT_VEC <= 8'd78;  end
		else if (INT_PEND[WDT_INT])       begin INT_LVL <= IPRE.WDT;    INT_VEC <= 8'd112; end
		else if (INT_PEND[BSC_INT])       begin INT_LVL <= IPRE.WDT;    INT_VEC <= 8'd113; end
		else if (INT_PEND[SCI0_ERI_INT])  begin INT_LVL <= IPRD.SCI0;   INT_VEC <= 8'd100; end
		else if (INT_PEND[SCI0_RXI_INT])  begin INT_LVL <= IPRD.SCI0;   INT_VEC <= 8'd101; end
		else if (INT_PEND[SCI0_TXI_INT])  begin INT_LVL <= IPRD.SCI0;   INT_VEC <= 8'd102; end
		else if (INT_PEND[SCI0_TEI_INT])  begin INT_LVL <= IPRD.SCI0;   INT_VEC <= 8'd103; end
		else if (INT_PEND[SCI1_ERI_INT])  begin INT_LVL <= IPRE.SCI1;   INT_VEC <= 8'd104; end
		else if (INT_PEND[SCI1_RXI_INT])  begin INT_LVL <= IPRE.SCI1;   INT_VEC <= 8'd105; end
		else if (INT_PEND[SCI1_TXI_INT])  begin INT_LVL <= IPRE.SCI1;   INT_VEC <= 8'd106; end
		else if (INT_PEND[SCI1_TEI_INT])  begin INT_LVL <= IPRE.SCI1;   INT_VEC <= 8'd107; end
		else if (INT_PEND[ITU0_IMIA_INT]) begin INT_LVL <= IPRC.ITU0;   INT_VEC <= 8'd80;  end
		else if (INT_PEND[ITU0_IMIB_INT]) begin INT_LVL <= IPRC.ITU0;   INT_VEC <= 8'd81;  end
		else if (INT_PEND[ITU0_OVI_INT])  begin INT_LVL <= IPRC.ITU0;   INT_VEC <= 8'd82;  end
		else if (INT_PEND[ITU1_IMIA_INT]) begin INT_LVL <= IPRC.ITU1;   INT_VEC <= 8'd84;  end
		else if (INT_PEND[ITU1_IMIB_INT]) begin INT_LVL <= IPRC.ITU1;   INT_VEC <= 8'd85;  end
		else if (INT_PEND[ITU1_OVI_INT])  begin INT_LVL <= IPRC.ITU1;   INT_VEC <= 8'd86;  end
		else if (INT_PEND[ITU2_IMIA_INT]) begin INT_LVL <= IPRD.ITU2;   INT_VEC <= 8'd88;  end
		else if (INT_PEND[ITU2_IMIB_INT]) begin INT_LVL <= IPRD.ITU2;   INT_VEC <= 8'd89;  end
		else if (INT_PEND[ITU2_OVI_INT])  begin INT_LVL <= IPRD.ITU2;   INT_VEC <= 8'd90;  end
		else if (INT_PEND[ITU3_IMIA_INT]) begin INT_LVL <= IPRD.ITU3;   INT_VEC <= 8'd92;  end
		else if (INT_PEND[ITU3_IMIB_INT]) begin INT_LVL <= IPRD.ITU3;   INT_VEC <= 8'd93;  end
		else if (INT_PEND[ITU3_OVI_INT])  begin INT_LVL <= IPRD.ITU3;   INT_VEC <= 8'd94;  end
		else if (INT_PEND[ITU4_IMIA_INT]) begin INT_LVL <= IPRD.ITU4;   INT_VEC <= 8'd96;  end
		else if (INT_PEND[ITU4_IMIB_INT]) begin INT_LVL <= IPRD.ITU4;   INT_VEC <= 8'd97;  end
		else if (INT_PEND[ITU4_OVI_INT])  begin INT_LVL <= IPRD.ITU4;   INT_VEC <= 8'd98;  end
		else                              begin INT_LVL <= 4'hF;        INT_VEC <= 8'd0;   end
	end
	
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			VBREQ <= 0;
		end else if (CE_F) begin	
			if (VECT_REQ && !VBREQ) begin
				VBREQ <= 1;
			end else if (VBREQ && !VBUS_WAIT) begin
				VBREQ <= 0;
			end
		end
	end
	assign VECT_WAIT = VBREQ;
	
	assign IRQOUT_N = 1;
	
	//Registers
	wire REG_SEL = (IBUS_A >= 28'h5FFFF84 & IBUS_A <= 28'h5FFFF8F);
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			IPRA <= IPRA_INIT;
			IPRB <= IPRB_INIT;
			IPRC <= IPRC_INIT;
			IPRD <= IPRD_INIT;
			IPRE <= IPRE_INIT;
			ICR  <= ICR_INIT;
		end
		else if (CE_R) begin
			if (!RES_N) begin
				IPRA <= IPRA_INIT;
				IPRB <= IPRB_INIT;
				IPRC <= IPRC_INIT;
				IPRD <= IPRD_INIT;
				IPRE <= IPRE_INIT;
				ICR  <= ICR_INIT;
				ICR.NMIL <= NMI_N;
			end
			else if (REG_SEL && IBUS_WE && IBUS_REQ) begin
				case ({IBUS_A[3:2],2'b00})
					4'h4: begin
						if (IBUS_BA[3]) IPRA[15: 8] = IBUS_DI[31:24] & IPRA_WMASK[15:8];
						if (IBUS_BA[2]) IPRA[ 7: 0] = IBUS_DI[23:16] & IPRA_WMASK[ 7:0];
						if (IBUS_BA[1]) IPRB[15: 8] = IBUS_DI[15: 8] & IPRB_WMASK[15:8];
						if (IBUS_BA[0]) IPRB[ 7: 0] = IBUS_DI[ 7: 0] & IPRB_WMASK[ 7:0];
					end
					4'h8: begin
						if (IBUS_BA[3]) IPRC[15: 8] = IBUS_DI[31:24] & IPRC_WMASK[15:8];
						if (IBUS_BA[2]) IPRC[ 7: 0] = IBUS_DI[23:16] & IPRC_WMASK[ 7:0];
						if (IBUS_BA[1]) IPRD[15: 8] = IBUS_DI[15: 8] & IPRD_WMASK[15:8];
						if (IBUS_BA[0]) IPRD[ 7: 0] = IBUS_DI[ 7: 0] & IPRD_WMASK[ 7:0];
					end
					4'hC: begin
						if (IBUS_BA[3]) IPRE[15:8] = IBUS_DI[31:24] & IPRE_WMASK[15:8];
						if (IBUS_BA[2]) IPRE[ 7:0] = IBUS_DI[23:16] & IPRE_WMASK[ 7:0];
						if (IBUS_BA[1]) ICR[15:8]  = IBUS_DI[15: 8] & ICR_WMASK[15:8];
						if (IBUS_BA[0]) ICR[ 7:0]  = IBUS_DI[ 7: 0] & ICR_WMASK[ 7:0];
					end
					default:;
				endcase
			end
		end
	end
	
	bit [31:0] BUS_DO;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			BUS_DO <= '0;
		end
		else if (CE_F) begin
			if (REG_SEL && !IBUS_WE && IBUS_REQ) begin
				case ({IBUS_A[3:2],2'b00})
					4'h4: BUS_DO <= {IPRA & IPRA_RMASK,IPRB & IPRB_RMASK};
					4'h8: BUS_DO <= {IPRC & IPRC_RMASK,IPRD & IPRD_RMASK};
					4'hC: BUS_DO <= {IPRE & IPRE_RMASK,ICR & ICR_RMASK};
					default:BUS_DO <= '0;
				endcase
			end
		end
	end
	
	assign IBUS_DO = BUS_DO;
	assign IBUS_BUSY = 0;
	assign IBUS_ACT = REG_SEL;

endmodule

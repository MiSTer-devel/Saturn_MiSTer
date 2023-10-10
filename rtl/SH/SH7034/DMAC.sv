module SH7034_DMAC (
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	
	input             RES_N,
	input             NMI_N,
	
	input             DREQ0_N,
	output            DACK0,
	input             DREQ1_N,
	output            DACK1,
	
	input             RXI0_IRQ,
	input             TXI0_IRQ,
	input             RXI1_IRQ,
	input             TXI1_IRQ,
	input             IMIA0_IRQ,
	input             IMIA1_IRQ,
	input             IMIA2_IRQ,
	input             IMIA3_IRQ,
	input             ADI_IRQ,
	
	input      [27:0] IBUS_A,
	input      [31:0] IBUS_DI,
	output     [31:0] IBUS_DO,
	input       [3:0] IBUS_BA,
	input             IBUS_WE,
	input             IBUS_REQ,
	output reg        IBUS_BUSY,
	input             IBUS_LOCK,
	output            IBUS_ACT,
	
	output     [27:0] DBUS_A,
	input      [31:0] DBUS_DI,
	output     [31:0] DBUS_DO,
	output      [3:0] DBUS_BA,
	output            DBUS_WE,
	output            DBUS_REQ,
	input             DBUS_WAIT,
	output            DBUS_LOCK,
	
	input             BSC_ACK,
	
	output            DMAC0_IRQ,
	output            DMAC1_IRQ,
	output            DMAC2_IRQ,
	output            DMAC3_IRQ
	
);

	import SH7034_PKG::*;

	SARx_t      SAR[4];
	DARx_t      DAR[4];
	TCRx_t      TCR[4];
	CHCRx_t     CHCR[4];
	DMAOR_t     DMAOR;
		
	function bit [3:0] BAFromAddr(input bit [1:0] addr, input bit sz);
		bit [3:0] res;
	
		case (sz)
			1'b0: res = {~addr[1]&~addr[0],~addr[1]&addr[0],addr[1]&~addr[0],addr[1]&addr[0]};
			1'b1: res = {~addr[1]         ,~addr[1]        ,addr[1]                 ,addr[1]};
		endcase
		return res;
	endfunction
	
	function bit [31:0] GetAddrInc(input bit sz);
		bit [31:0] res;
	
		case (sz)
			1'b0: res = 32'd1;
			1'b1: res = 32'd2;
		endcase
		return res;
	endfunction
	
	bit         DACK0_EN;
	bit         DACK1_EN;
	
	wire REG_SEL = (IBUS_A >= 28'h5FFFF40 && IBUS_A <= 28'h5FFFF7F);

	wire CH_EN[4] = '{DMAOR.DME & CHCR[0].DE, 
	                  DMAOR.DME & CHCR[1].DE, 
	                  DMAOR.DME & CHCR[2].DE, 
	                  DMAOR.DME & CHCR[3].DE};
	wire CH_AVAIL[4] = '{~CHCR[0].TE & ~DMAOR.NMIF & ~DMAOR.AE, 
	                     ~CHCR[1].TE & ~DMAOR.NMIF & ~DMAOR.AE, 
	                     ~CHCR[2].TE & ~DMAOR.NMIF & ~DMAOR.AE, 
	                     ~CHCR[3].TE & ~DMAOR.NMIF & ~DMAOR.AE};

	bit         CH_REQ[4];
	bit         CH_REQ_CLR[4];
	always @(posedge CLK or negedge RST_N) begin
		bit         DREQ0_OLD;
		bit         DREQ1_OLD;
		bit         DREQ0_PAUSE;
		bit         DREQ1_PAUSE;
		bit         DREQ0_DET;
		bit         DREQ1_DET;
		bit         DACK0_OLD;
		bit         DACK1_OLD;
		
		if (!RST_N) begin
			DREQ0_OLD <= 0;
			DREQ1_OLD <= 0;
			DACK0_OLD <= 0;
			DACK1_OLD <= 0;
			CH_REQ <= '{0,0,0,0};
		end
		else if (CE_R) begin
			//CH0
			if (CH_REQ_CLR[0] && CHCR[0].DS) begin
				CH_REQ[0] <= 0;
			end else if (CH_EN[0] && CH_AVAIL[0] && !DBUS_WAIT) begin
				if (!CHCR[0].DS && CHCR[0].RS[3:2] == 2'b00) begin
					CH_REQ[0] <= ~DREQ0_N;
				end else begin
					if (!CH_REQ[0]) begin
						case(CHCR[0].RS)
							4'b0000,
							4'b0010,
							4'b0011: CH_REQ[0] <= DREQ0_DET;
							4'b0100: CH_REQ[0] <= RXI0_IRQ;
							4'b0101: CH_REQ[0] <= TXI0_IRQ;
							4'b0110: CH_REQ[0] <= RXI1_IRQ;
							4'b0111: CH_REQ[0] <= TXI1_IRQ;
							4'b1000: CH_REQ[0] <= IMIA0_IRQ;
							4'b1001: CH_REQ[0] <= IMIA1_IRQ;
							4'b1010: CH_REQ[0] <= IMIA2_IRQ;
							4'b1011: CH_REQ[0] <= IMIA3_IRQ;
							4'b1100: CH_REQ[0] <= 1;
							4'b1101: CH_REQ[0] <= ADI_IRQ;
							default: CH_REQ[0] <= 0;
						endcase
						DREQ0_DET <= 0;
//					end
//					else if (CH_REQ_CLR[0] /*|| !CHCR[0].TM*/) begin
//						CH_REQ[0] <= 0;
					end
				end
			end else if (!CH_EN[0] || !CH_AVAIL[0]) begin
				CH_REQ[0] <= 0;
				DREQ0_DET <= 0;
				DREQ0_PAUSE <= 0;
			end
			
			DREQ0_OLD <= DREQ0_N;
			if (!DREQ0_N && (DREQ0_OLD || !CHCR[0].DS) && !DREQ0_PAUSE) begin
				DREQ0_DET <= 1;
				DREQ0_PAUSE <= 1;
			end
			
			DACK0_OLD <= BSC_ACK & DACK0_EN;
			if (DACK0_EN && BSC_ACK && !DACK0_OLD) begin
				DREQ0_PAUSE <= 0;
			end
			
			//CH1
			if (CH_EN[1] && CH_AVAIL[1] && !DBUS_WAIT) begin
				if (!CHCR[1].DS && CHCR[1].RS[3:2] == 2'b00) begin
					CH_REQ[1] <= ~DREQ1_N;
				end else begin
					if (!CH_REQ[1]) begin
						case(CHCR[1].RS)
							4'b0000,
							4'b0010,
							4'b0011: CH_REQ[1] <= DREQ1_DET;
							4'b0100: CH_REQ[1] <= RXI0_IRQ;
							4'b0101: CH_REQ[1] <= TXI0_IRQ;
							4'b0110: CH_REQ[1] <= RXI1_IRQ;
							4'b0111: CH_REQ[1] <= TXI1_IRQ;
							4'b1000: CH_REQ[1] <= IMIA0_IRQ;
							4'b1001: CH_REQ[1] <= IMIA1_IRQ;
							4'b1010: CH_REQ[1] <= IMIA2_IRQ;
							4'b1011: CH_REQ[1] <= IMIA3_IRQ;
							4'b1100: CH_REQ[1] <= 1;
							4'b1101: CH_REQ[1] <= ADI_IRQ;
							default: CH_REQ[1] <= 0;
						endcase
						DREQ1_DET <= 0;
					end
					else if (CH_REQ_CLR[1] /*|| !CHCR[1].TM*/) begin
						CH_REQ[1] <= 0;
					end
				end
				
				DREQ1_OLD <= DREQ1_N;
				if (!DREQ1_N && (DREQ1_OLD || !CHCR[1].DS) && !DREQ1_PAUSE) begin
					DREQ1_DET <= 1;
					DREQ1_PAUSE <= 1;
				end
			end else if (!CH_EN[1] || !CH_AVAIL[1]) begin
				CH_REQ[1] <= 0;
				DREQ1_DET <= 0;
				DREQ1_PAUSE <= 0;
			end

			DACK1_OLD <= BSC_ACK & DACK1_EN;
			if (DACK1_EN && BSC_ACK && !DACK1_OLD) begin
				DREQ1_PAUSE <= 0;
			end
			
			//CH2
			if (!CH_REQ[2] && CH_EN[2] && CH_AVAIL[2]) begin
				case(CHCR[2].RS)
					4'b0000,
					4'b0010,
					4'b0011: CH_REQ[2] <= 0;
					4'b0100: CH_REQ[2] <= RXI0_IRQ;
					4'b0101: CH_REQ[2] <= TXI0_IRQ;
					4'b0110: CH_REQ[2] <= RXI1_IRQ;
					4'b0111: CH_REQ[2] <= TXI1_IRQ;
					4'b1000: CH_REQ[2] <= IMIA0_IRQ;
					4'b1001: CH_REQ[2] <= IMIA1_IRQ;
					4'b1010: CH_REQ[2] <= IMIA2_IRQ;
					4'b1011: CH_REQ[2] <= IMIA3_IRQ;
					4'b1100: CH_REQ[2] <= 1;
					4'b1101: CH_REQ[2] <= ADI_IRQ;
					default: CH_REQ[2] <= 0;
				endcase
			end
			else if (CH_REQ_CLR[2]) begin
				CH_REQ[2] <= 0;
			end
			
			//CH3
			if (!CH_REQ[3] && CH_EN[3] && CH_AVAIL[3]) begin
				case(CHCR[3].RS)
					4'b0000,
					4'b0010,
					4'b0011: CH_REQ[3] <= 0;
					4'b0100: CH_REQ[3] <= RXI0_IRQ;
					4'b0101: CH_REQ[3] <= TXI0_IRQ;
					4'b0110: CH_REQ[3] <= RXI1_IRQ;
					4'b0111: CH_REQ[3] <= TXI1_IRQ;
					4'b1000: CH_REQ[3] <= IMIA0_IRQ;
					4'b1001: CH_REQ[3] <= IMIA1_IRQ;
					4'b1010: CH_REQ[3] <= IMIA2_IRQ;
					4'b1011: CH_REQ[3] <= IMIA3_IRQ;
					4'b1100: CH_REQ[3] <= 1;
					4'b1101: CH_REQ[3] <= ADI_IRQ;
					default: CH_REQ[3] <= 0;
				endcase
			end
			else if (CH_REQ_CLR[3]) begin
				CH_REQ[3] <= 0;
			end
		end
	end
	
	
	bit         DMA_REQ;
//	bit         DMA_REQ_CLR;
	bit   [1:0] DMA_CH_NEXT;
	bit   [1:0] DMA_CH;
//	bit   [1:0] RB_PRIO;
	always @(posedge CLK or negedge RST_N) begin
		bit  [3:0] DMA_CH_REQ;
		bit  [3:0] DMA_CH_REQ_OLD;
		
		if (!RST_N) begin
			DMA_REQ <= 0;
			DMA_CH_REQ <= '0;
			DMA_CH_REQ_OLD <= '0;
//			RB_PRIO <= '0;
		end
		else if (CE_R) begin
			DMA_CH_REQ[0] = CH_REQ[0] && CH_EN[0] && CH_AVAIL[0];
			DMA_CH_REQ[1] = CH_REQ[1] && CH_EN[1] && CH_AVAIL[1];
			DMA_CH_REQ[2] = CH_REQ[2] && CH_EN[2] && CH_AVAIL[2];
			DMA_CH_REQ[3] = CH_REQ[3] && CH_EN[3] && CH_AVAIL[3];
			if (!DMA_REQ && DMA_CH_REQ != 4'b0000 && !DBUS_WAIT) begin
				if (DMA_CH_REQ[0] && !DMA_CH_REQ_OLD[0]) begin
					DMA_CH_REQ_OLD <= 4'b0001;
					DMA_REQ <= 1;
					DMA_CH_NEXT <= 2'd0;
				end else if (DMA_CH_REQ[1] && !DMA_CH_REQ_OLD[1]) begin
					DMA_CH_REQ_OLD <= 4'b0010;
					DMA_REQ <= 1;
					DMA_CH_NEXT <= 2'd1;
				end else if (DMA_CH_REQ[2] && !DMA_CH_REQ_OLD[2]) begin
					DMA_CH_REQ_OLD <= 4'b0100;
					DMA_REQ <= 1;
					DMA_CH_NEXT <= 2'd2;
				end else if (DMA_CH_REQ[3] && !DMA_CH_REQ_OLD[3]) begin
					DMA_CH_REQ_OLD <= 4'b1000;
					DMA_REQ <= 1;
					DMA_CH_NEXT <= 2'd3;
				end
			end
//			else if (DMA_REQ_CLR) begin
			else if (DMA_REQ && !DBUS_WAIT) begin
				DMA_REQ <= 0;
//				RB_PRIO <= ~RB_PRIO;
			end
			
			if (!DMA_CH_REQ[0] && DMA_CH_REQ_OLD[0]) DMA_CH_REQ_OLD[0] <= 0;
			if (!DMA_CH_REQ[1] && DMA_CH_REQ_OLD[1]) DMA_CH_REQ_OLD[1] <= 0;
			if (!DMA_CH_REQ[2] && DMA_CH_REQ_OLD[2]) DMA_CH_REQ_OLD[2] <= 0;
			if (!DMA_CH_REQ[3] && DMA_CH_REQ_OLD[3]) DMA_CH_REQ_OLD[3] <= 0;
		end
	end
	

	bit         DMA_WR;
	bit         DMA_RD;
	bit         DMA_LOCK;
	bit   [1:0] SA_BA;
	bit         DACK_EN;
	always @(posedge CLK or negedge RST_N) begin
		bit  [31:0] AR_INC;
		bit  [15:0] TCR_NEXT;
		bit         SAM, SAM_NEXT;
		bit         LAST_CYCLE;
		
		if (!RST_N) begin
			SAR <= '{4{SARx_INIT}};
			DAR <= '{4{DARx_INIT}};
			TCR <= '{4{TCRx_INIT}};
			CHCR <= '{4{CHCRx_INIT}};
			DMAOR <= DMAOR_INIT;
			// synopsys translate_off
			SAR[0] <= 32'h000000E0;
			DAR[0] <= 32'h000000F0;
			TCR[0] <= 4;
			// synopsys translate_on
			
			DMA_WR <= 0;
			DMA_RD <= 0;
			DMA_LOCK <= 0;
			CH_REQ_CLR <= '{0,0,0,0};
//			DMA_REQ_CLR <= 0;
		end
		else begin
			AR_INC = GetAddrInc(CHCR[DMA_CH].TS);
			TCR_NEXT = TCR[DMA_CH] - 16'd1;
			SAM = ~DMA_CH[1] & (CHCR[DMA_CH].RS[3:1] == 3'b001);//single address mode
			
			LAST_CYCLE = 0;
			if (CE_R) begin
				CH_REQ_CLR <= '{0,0,0,0};
//				DMA_REQ_CLR <= 0;
				
				if (DMA_RD && !DBUS_WAIT) begin
					if      (CHCR[DMA_CH].SM == 2'b01) SAR[DMA_CH] <= SAR[DMA_CH] + AR_INC;
					else if (CHCR[DMA_CH].SM == 2'b10) SAR[DMA_CH] <= SAR[DMA_CH] - AR_INC;
					
					if (!SAM) begin
						DMA_RD <= 0;
						DMA_WR <= 1;
						DMA_LOCK <= 0;
						DACK_EN <= (CHCR[DMA_CH].AM | CHCR[DMA_CH].RS[3:1] == 3'b001);

						CH_REQ_CLR[DMA_CH] <= 1;
					end
					else if (SAM && !CHCR[DMA_CH].RS[0]) begin
						if (!CHCR[DMA_CH].TM || !CH_REQ[DMA_CH]) DMA_RD <= 0;
						
						TCR[DMA_CH] <= TCR_NEXT;
						if (!TCR_NEXT) begin
							CHCR[DMA_CH].TE <= 1;
							DMA_RD <= 0;
						end
						else CH_REQ_CLR[DMA_CH] <= 1;
						
//						DMA_REQ_CLR <= 1;
					end
					SA_BA <= SAR[DMA_CH][1:0];
					
					LAST_CYCLE = SAM;
				end
				else if (DMA_WR && !DBUS_WAIT) begin
					if      (CHCR[DMA_CH].DM == 2'b01) DAR[DMA_CH] <= DAR[DMA_CH] + AR_INC;
					else if (CHCR[DMA_CH].DM == 2'b10) DAR[DMA_CH] <= DAR[DMA_CH] - AR_INC;
					
					if (!SAM) begin
						DMA_WR <= 0;
						DMA_RD <= 1;
						DACK_EN <= (~CHCR[DMA_CH].AM | CHCR[DMA_CH].RS[3:1] == 3'b001);
						
						if (!CHCR[DMA_CH].TM || !CH_REQ[DMA_CH]) DMA_RD <= 0;
					end 
					else if (SAM && CHCR[DMA_CH].RS[0]) begin
						if (!CHCR[DMA_CH].TM || !CH_REQ[DMA_CH]) DMA_WR <= 0;
						else CH_REQ_CLR[DMA_CH] <= 1;
					end
//					DMA_REQ_CLR <= 1;
					
					TCR[DMA_CH] <= TCR_NEXT;
					if (!TCR_NEXT) begin
						CHCR[DMA_CH].TE <= 1;
						DMA_RD <= 0;
						DMA_WR <= 0;
					end
					
					LAST_CYCLE = 1;
				end
				
				SAM_NEXT = ~DMA_CH_NEXT[1] & (CHCR[DMA_CH_NEXT].RS[3:1] == 3'b001);//single address mode
				if (DMA_REQ && (LAST_CYCLE || (!DMA_RD && !DMA_WR)) && !DBUS_WAIT && !IBUS_LOCK) begin
					DMA_RD <= 0;
					DMA_WR <= 0;
					if (!SAM_NEXT || (SAM_NEXT && !CHCR[DMA_CH_NEXT].RS[0])) begin
						DMA_RD <= 1;
						DACK_EN <= (~CHCR[DMA_CH_NEXT].AM | CHCR[DMA_CH_NEXT].RS[3:1] == 3'b001);
						CH_REQ_CLR[DMA_CH_NEXT] <= SAM_NEXT & ~CHCR[DMA_CH_NEXT].AM;
						DMA_LOCK <= ~SAM_NEXT;
					end
					else begin
						DMA_WR <= 1;
						DACK_EN <= (CHCR[DMA_CH_NEXT].AM | CHCR[DMA_CH_NEXT].RS[3:1] == 3'b001);
						CH_REQ_CLR[DMA_CH_NEXT] <= 1;
						DMA_LOCK <= 0;
					end
					DMA_CH <= DMA_CH_NEXT;
				end
			end
			
			if (CE_R) begin
				if (REG_SEL && !(DMA_RD | DMA_WR) && IBUS_WE && IBUS_REQ) begin
					case ({IBUS_A[5:2],2'b00})
						6'h00: begin
							if (IBUS_BA[3:2]) SAR[0][31:16] <= IBUS_DI[31:16] & SARx_WMASK[31:16];
							if (IBUS_BA[1:0]) SAR[0][15: 0] <= IBUS_DI[15: 0] & SARx_WMASK[15: 0];
						end
						6'h04: begin
							if (IBUS_BA[3:2]) DAR[0][31:16] <= IBUS_DI[31:16] & DARx_WMASK[31:16];
							if (IBUS_BA[1:0]) DAR[0][15: 0] <= IBUS_DI[15: 0] & DARx_WMASK[15: 0];
						end
						6'h08: begin
							if (IBUS_BA[3]) DMAOR[15:8] <= IBUS_DI[31:24] & DMAOR_WMASK[15:8];
							if (IBUS_BA[2]) DMAOR[ 7:3] <= IBUS_DI[23:19] & DMAOR_WMASK[7:3];
							if (IBUS_BA[2] && !IBUS_DI[18]) DMAOR[2] <= 0;
							if (IBUS_BA[2] && !IBUS_DI[17]) DMAOR[1] <= 0;
							if (IBUS_BA[2]) DMAOR[ 0:0] <= IBUS_DI[16:16] & DMAOR_WMASK[0];
							if (IBUS_BA[1:0]) TCR[0][15: 0] <= IBUS_DI[15: 0] & TCRx_WMASK[15: 0];
						end
						6'h0C: begin
							if (IBUS_BA[1]) CHCR[0][15: 8] <= IBUS_DI[15: 8] & CHCRx_WMASK[15: 8];
							if (IBUS_BA[0]) CHCR[0][ 7: 2] <= IBUS_DI[ 7: 2] & CHCRx_WMASK[ 7: 2];
							if (IBUS_BA[0] && !IBUS_DI[1] && CHCR_READ[1]) CHCR[0][1] <= 0;
							if (IBUS_BA[0]) CHCR[0][ 0: 0] <= IBUS_DI[ 0: 0] & CHCRx_WMASK[ 0: 0];
						end
						6'h10: begin
							if (IBUS_BA[3:2]) SAR[1][31:16] <= IBUS_DI[31:16] & SARx_WMASK[31:16];
							if (IBUS_BA[1:0]) SAR[1][15: 0] <= IBUS_DI[15: 0] & SARx_WMASK[15: 0];
						end
						6'h14: begin
							if (IBUS_BA[3:2]) DAR[1][31:16] <= IBUS_DI[31:16] & DARx_WMASK[31:16];
							if (IBUS_BA[1:0]) DAR[1][15: 0] <= IBUS_DI[15: 0] & DARx_WMASK[15: 0];
						end
						6'h18: begin
							if (IBUS_BA[1:0]) TCR[1][15: 0] <= IBUS_DI[15: 0] & TCRx_WMASK[15: 0];
						end
						6'h1C: begin
							if (IBUS_BA[1]) CHCR[1][15: 8] <= IBUS_DI[15: 8] & CHCRx_WMASK[15: 8];
							if (IBUS_BA[0]) CHCR[1][ 7: 2] <= IBUS_DI[ 7: 2] & CHCRx_WMASK[ 7: 2];
							if (IBUS_BA[0] && !IBUS_DI[1] && CHCR_READ[1]) CHCR[1][1] <= 0;
							if (IBUS_BA[0]) CHCR[1][ 0: 0] <= IBUS_DI[ 0: 0] & CHCRx_WMASK[ 0: 0];
						end
						6'h20: begin
							if (IBUS_BA[3:2]) SAR[2][31:16] <= IBUS_DI[31:16] & SARx_WMASK[31:16];
							if (IBUS_BA[1:0]) SAR[2][15: 0] <= IBUS_DI[15: 0] & SARx_WMASK[15: 0];
						end
						6'h24: begin
							if (IBUS_BA[3:2]) DAR[2][31:16] <= IBUS_DI[31:16] & DARx_WMASK[31:16];
							if (IBUS_BA[1:0]) DAR[2][15: 0] <= IBUS_DI[15: 0] & DARx_WMASK[15: 0];
						end
						6'h28: begin
							if (IBUS_BA[1:0]) TCR[2][15: 0] <= IBUS_DI[15: 0] & TCRx_WMASK[15: 0];
						end
						6'h2C: begin
							if (IBUS_BA[1]) CHCR[2][15: 8] <= IBUS_DI[15: 8] & CHCRx_WMASK[15: 8];
							if (IBUS_BA[0]) CHCR[2][ 7: 2] <= IBUS_DI[ 7: 2] & CHCRx_WMASK[ 7: 2];
							if (IBUS_BA[0] && !IBUS_DI[1] && CHCR_READ[1]) CHCR[2][1] <= 0;
							if (IBUS_BA[0]) CHCR[2][ 0: 0] <= IBUS_DI[ 0: 0] & CHCRx_WMASK[ 0: 0];
						end
						6'h30: begin
							if (IBUS_BA[3:2]) SAR[3][31:16] <= IBUS_DI[31:16] & SARx_WMASK[31:16];
							if (IBUS_BA[1:0]) SAR[3][15: 0] <= IBUS_DI[15: 0] & SARx_WMASK[15: 0];
						end
						6'h34: begin
							if (IBUS_BA[3:2]) DAR[3][31:16] <= IBUS_DI[31:16] & DARx_WMASK[31:16];
							if (IBUS_BA[1:0]) DAR[3][15: 0] <= IBUS_DI[15: 0] & DARx_WMASK[15: 0];
						end
						6'h38: begin
							if (IBUS_BA[1:0]) TCR[3][15: 0] <= IBUS_DI[15: 0] & TCRx_WMASK[15: 0];
						end
						6'h3C: begin
							if (IBUS_BA[1]) CHCR[3][15: 8] <= IBUS_DI[15: 8] & CHCRx_WMASK[15: 8];
							if (IBUS_BA[0]) CHCR[3][ 7: 2] <= IBUS_DI[ 7: 2] & CHCRx_WMASK[ 7: 2];
							if (IBUS_BA[0] && !IBUS_DI[1] && CHCR_READ[1]) CHCR[3][1] <= 0;
							if (IBUS_BA[0]) CHCR[3][ 0: 0] <= IBUS_DI[ 0: 0] & CHCRx_WMASK[ 0: 0];
						end
						default:;
					endcase
				end
				
				if (!NMI_N) DMAOR.NMIF <= 1;
			end
		end
	end
	
	assign DACK0_EN = (DMA_CH == 2'd0 & DMA_RD & (~CHCR[0].AM | CHCR[0].RS[3:1] == 3'b001)) | (DMA_CH == 2'd0 & DMA_WR & (CHCR[0].AM | CHCR[0].RS[3:1] == 3'b001));
	assign DACK1_EN = (DMA_CH == 2'd1 & DMA_RD & (~CHCR[1].AM | CHCR[1].RS[3:1] == 3'b001)) | (DMA_CH == 2'd1 & DMA_WR & (CHCR[1].AM | CHCR[1].RS[3:1] == 3'b001));
	
	bit [31:0] DBUS_DO_TEMP;
	always_comb begin
		case (CHCR[DMA_CH].TS)
			1'b0: 
				case (SA_BA)
					2'b00: DBUS_DO_TEMP = {4{DBUS_DI[31:24]}};
					2'b01: DBUS_DO_TEMP = {4{DBUS_DI[23:16]}};
					2'b10: DBUS_DO_TEMP = {4{DBUS_DI[15: 8]}};
					2'b11: DBUS_DO_TEMP = {4{DBUS_DI[ 7: 0]}};
				endcase
			1'b1: 
				case (SA_BA[1])
					1'b0: DBUS_DO_TEMP = {2{DBUS_DI[31:16]}};
					1'b1: DBUS_DO_TEMP = {2{DBUS_DI[15: 0]}};
				endcase
		endcase
	end
	
	assign DBUS_A = DMA_RD ? SAR[DMA_CH][27:0] : 
	                DMA_WR ? DAR[DMA_CH][27:0] : 
	                IBUS_A;
	assign DBUS_DO = DMA_RD || DMA_WR ? DBUS_DO_TEMP : IBUS_DI;
	assign DBUS_BA = DMA_RD ? BAFromAddr(SAR[DMA_CH][1:0],CHCR[DMA_CH].TS) : 
	                 DMA_WR ? BAFromAddr(DAR[DMA_CH][1:0],CHCR[DMA_CH].TS) : 
	                 IBUS_BA;
	assign DBUS_WE = DMA_RD ? 1'b0 : 
	                 DMA_WR ? 1'b1 : 
	                 IBUS_WE;
	assign DBUS_REQ = DMA_RD | DMA_WR | IBUS_REQ;
	assign DBUS_LOCK = ((DMA_RD | DMA_WR) & DMA_LOCK) | (~(DMA_RD | DMA_WR) &IBUS_LOCK);
	
//	assign DACK0 = (BSC_ACK & DACK0_EN) ^ CHCR[0].AL;
//	assign DACK1 = (BSC_ACK & DACK1_EN) ^ CHCR[1].AL;
	assign DACK0 = ~(DMA_CH == 2'd0 & (DMA_RD | DMA_WR) & BSC_ACK & DACK_EN);
	assign DACK1 = ~(DMA_CH == 2'd1 & (DMA_RD | DMA_WR) & BSC_ACK & DACK_EN);
	
	assign DMAC0_IRQ = CHCR[0].TE & CHCR[0].IE;
	assign DMAC1_IRQ = CHCR[1].TE & CHCR[1].IE;
	assign DMAC2_IRQ = CHCR[2].TE & CHCR[2].IE;
	assign DMAC3_IRQ = CHCR[3].TE & CHCR[3].IE;
	
	
	//Registers
	bit [31:0] REG_DO;
	CHCRx_t    CHCR_READ;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			REG_DO <= '0;
		end
		else if (CE_F) begin
			if (REG_SEL && !(DMA_RD | DMA_WR) && !IBUS_WE && IBUS_REQ) begin
				case ({IBUS_A[5:2],2'b00})
					6'h00: REG_DO <= SAR[0];
					6'h04: REG_DO <= DAR[0];
					6'h08: REG_DO <= {DMAOR,TCR[0]};
					6'h0C: begin REG_DO <= {16'h0000,CHCR[0] & CHCRx_RMASK}; CHCR_READ <= CHCR[0]; end
					6'h10: REG_DO <= SAR[1];
					6'h14: REG_DO <= DAR[1];
					6'h18: REG_DO <= {16'h0000,TCR[1]};
					6'h1C: begin REG_DO <= {16'h0000,CHCR[1] & CHCRx_RMASK}; CHCR_READ <= CHCR[1]; end
					6'h20: REG_DO <= SAR[2];
					6'h24: REG_DO <= DAR[2];
					6'h28: REG_DO <= {DMAOR,TCR[2]};
					6'h2C: begin REG_DO <= {16'h0000,CHCR[2] & CHCRx_RMASK}; CHCR_READ <= CHCR[2]; end
					6'h30: REG_DO <= SAR[3];
					6'h34: REG_DO <= DAR[3];
					6'h38: REG_DO <= {16'h0000,TCR[3]};
					6'h3C: begin REG_DO <= {16'h0000,CHCR[3] & CHCRx_RMASK}; CHCR_READ <= CHCR[3]; end
					default:REG_DO <= '0;
				endcase
			end
		end
	end
	
	assign IBUS_DO = REG_SEL ? REG_DO : DBUS_DI;
	assign IBUS_BUSY = DMA_RD || DMA_WR || DBUS_WAIT;
	assign IBUS_ACT = REG_SEL;
	

endmodule

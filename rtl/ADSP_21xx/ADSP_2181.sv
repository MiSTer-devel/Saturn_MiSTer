//		Not implemented:
//		-NORM,EXP,EXPADJ instructions
//		-IDMA

module ADSP_2181 
(
	input              CLK,
	input              RST_N,
	input              CE_F,
	input              CE_R,
	
	input              RES_N,
	
	input              IRQL0_N,
	input              IRQL1_N,
	input              IRQ2_N,
	input              IRQE_N,
	
	output     [13: 0] A,
	input      [23: 0] DI,
	output reg [23: 0] DO,
	output             WR_N,
	output             RD_N,
	input              WAIT,//not present in original
	
	output             PMS_N,
	output             DMS_N,
	output             BMS_N,
	output             CMS_N,
	output             IOMS_N,
	
	input              FI,
	output             FO,
	output     [ 2: 0] FL,
	
	input      [ 7: 0] PFI,
	output reg [ 7: 0] PFO,
	
	output             SCLK0_O,
	input              SCLK0_I,
	output reg         DT0,
	input              DR0,
	output reg         TFS0_O,
	
	output             SCLK1_O,
	input              SCLK1_I,
	output reg         DT1,
	input              DR1,
	output reg         TFS1_O,
	
	input              MMAP,
	input              BMODE
);
	
	bit  [15: 0] DM;
	bit  [15: 0] SCR;
	bit  [13: 0] BIAD;
	bit  [13: 0] BEAD;
	bit  [15: 0] BDMAC;
	bit  [13: 0] BWCOUNT;
	bit  [15: 0] PFCSC;
	bit  [15: 0] WSCR;
	bit  [15: 0] TCOUNT,TPERIOD;
	bit  [ 7: 0] TSCALE;
	bit  [15: 0] SPORT0SCLKDIV,SPORT1SCLKDIV;
	bit  [15: 0] SPORT0CTRL,SPORT1CTRL;
	bit  [15: 0] SPORT0ABUF,SPORT1ABUF;
	
	bit  [13: 0] PMIA,PMA,DMA;
	bit  [15: 0] DMDI,DMDO;
	bit  [23: 0] PMIDI,PMDI,PMDO;
	bit          PMWR,PMRD,DMWR,DMRD;
	bit          IORD,IOWR;
	bit          PMEM_WAIT,DMEM_WAIT,BDMA_WAIT;
	
	bit          BDMA_STATE;
	bit  [ 7: 0] BDMA_BUF[3];
	bit          BDMA_BOOT;
	wire         BDMA_EXEC = |BWCOUNT;
	wire         BDMAC_HALT = BDMAC[3] & BDMA_EXEC;
	
	bit          SPORT0AUTO_REQ,SPORT1AUTO_REQ;
	
	bit  [ 4: 0] ICNTL;
	bit  [ 3: 0] PMOVLAY,DMOVLAY;
	bit  [15: 0] TX0I,TX1I,RX0I,RX1I,RTXO;
	bit          TX0WE,TX1WE,RX0WE,RX1WE;
	bit          IRQTM,IRQSP0R,IRQSP0T,IRQBD,IRQE,IRQSP1R,IRQSP1T,IRQL0,IRQL1,IRQ2;
	bit          TM_EN;
	
	wire         CPU_STALL = ((BDMA_EXEC & BDMA_STATE) | SPORT0AUTO_REQ | SPORT1AUTO_REQ);
	wire         CPU_EN = ~(CPU_STALL | PMEM_WAIT | DMEM_WAIT | (BDMA_EXEC & ~BDMA_STATE & (IORD | IOWR)));
	ADSP_21XX_CORE CORE
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE(CE_R),
		
		.RES_N(RES_N & ~BDMAC_HALT & ~BDMA_BOOT),
		
		.RUN(CPU_EN),
		
		.IRQTM(IRQTM),
		.IRQSP0R(IRQSP0R),
		.IRQSP0T(IRQSP0T),
		.IRQBD(IRQBD),
		.IRQE(IRQE),
		.IRQSP1R(IRQSP1R),
		.IRQSP1T(IRQSP1T),
		.IRQL0(IRQL0),
		.IRQL1(IRQL1),
		.IRQ2(IRQ2),
		
		.PMIA(PMIA),
		.PMIDI(PMIDI),
		
		.PMA(PMA),
		.PMDI(PMDI),
		.PMDO(PMDO),
		.PMWR(PMWR),
		.PMRD(PMRD),
		
		.DMA(DMA),
		.DMDI(DMDI),
		.DMDO(DMDO),
		.DMWR(DMWR),
		.DMRD(DMRD),
		
		.IORD(IORD),
		.IOWR(IOWR),
		
		.ICNTL(ICNTL),
		
		.PMOVLAY(PMOVLAY),
		.DMOVLAY(DMOVLAY),
		
		.TX0I(TX0I),
		.TX1I(TX1I),
		.RX0I(RX0I),
		.RX1I(RX1I),
		.RTXO(RTXO),
		.TX0WE(TX0WE),
		.TX1WE(TX1WE),
		.RX0WE(RX0WE),
		.RX1WE(RX1WE),
		.ATX0I(SPORT0ABUF[11:9]),
		.ATX0M(SPORT0ABUF[8:7]),
		.ATX0REQ(SPORT0AUTO_REQ),
		.ATX1I(SPORT1ABUF[11:9]),
		.ATX1M(SPORT1ABUF[8:7]),
		.ATX1REQ(SPORT1AUTO_REQ),
		
		.TM_EN(TM_EN),
		
		.FI(FI),
		.FO(FO),
		.FL(FL)
	);
	
	wire         REG_SEL = (DMA >= 14'h3FE0);
	bit  [15: 0] REG_Q;
	
	//PMEM
	wire         INT_PMWR = ((~PMOVLAY[1] & ~PMOVLAY[0]) | ~(PMA[13] ^ MMAP)) & PMWR & ~CPU_STALL;
	bit  [23: 0] PMEM_Q_A,PMEM_Q_B;
	ADSP_21xx_MEM #(14,24) PMEM
	(
		.CLK(CLK),
		
		.ADDR_A(PMIA),
		.DATA_A('0),
		.WREN_A(1'b0),
		.Q_A(PMEM_Q_A),
		
		.ADDR_B(BDMA_STATE ? BIAD : PMA),
		.DATA_B(BDMA_STATE ? {BDMA_BUF[0],BDMA_BUF[1],BDMA_BUF[2]} : PMDO),
		.WREN_B(BDMA_STATE ? ~BDMAC[2] & ~|BDMAC[1:0] & CE_R : INT_PMWR & CE_R),
		.Q_B(PMEM_Q_B)
	);
	assign PMIDI = PMEM_Q_A;
	assign PMDI = PMEM_Q_B;//DI;
	
	//DMEM
	wire         INT_DMWR = ((~DMOVLAY[1] & ~DMOVLAY[0]) | DMA[13]) & DMWR & ~CPU_STALL;
	wire [15: 0] DMEM_BDMA_DATA = BDMAC[1:0] == 2'b10 ? {BDMA_BUF[0],8'h00      } :
	                              BDMAC[1:0] == 2'b11 ? {8'h00      ,BDMA_BUF[0]} :
										                         {BDMA_BUF[0],BDMA_BUF[1]} ;
	bit  [15: 0] DMEM_Q_A,DMEM_Q_B;
	ADSP_21xx_MEM #(14,16) DMEM
	(
		.CLK(CLK),
		
		.ADDR_A(DMA),
		.DATA_A(DMDO),
		.WREN_A(INT_DMWR & CE_R),
		.Q_A(DMEM_Q_A),
		
		.ADDR_B(BIAD),
		.DATA_B(DMEM_BDMA_DATA),
		.WREN_B(BDMA_STATE & ~BDMAC[2] & |BDMAC[1:0] & CE_R),
		.Q_B(DMEM_Q_B)
	);
	
	
	//Memory interface, PF
	wire [13: 0] EXT_PMA = {PMOVLAY[1]&~PMOVLAY[0],PMA[12:0]};
	wire         EXT_PMWR = (PMOVLAY[1] ^ PMOVLAY[0]) & (PMA[13] ^ MMAP) & PMWR & ~CPU_STALL;
	wire         EXT_PMRD = (PMOVLAY[1] ^ PMOVLAY[0]) & (PMA[13] ^ MMAP) & PMRD & ~CPU_STALL;
	
	wire [13: 0] EXT_DMA = {DMOVLAY[1]&~DMOVLAY[0],DMA[12:0]};
	wire         EXT_DMWR = (DMOVLAY[1] ^ DMOVLAY[0]) & ~DMA[13] & DMWR & ~CPU_STALL;
	wire         EXT_DMRD = (DMOVLAY[1] ^ DMOVLAY[0]) & ~DMA[13] & DMRD & ~CPU_STALL;

	bit  [ 2: 0] WS_CNT;
	always @(posedge CLK or negedge RST_N) begin	
		
		if (!RST_N) begin
			SCR <= 16'h0407;
			WSCR <= 16'h7FFF;
			PFCSC <= 16'h7B00;
			PFO <= '0;
			WS_CNT <= '0;
		end else if (!RES_N) begin
			SCR <= 16'h0407;
			WSCR <= 16'h7FFF;
			PFCSC <= 16'h7B00;
			PFO <= '0;
			WS_CNT <= '0;
		end else begin
			if (CE_R) begin
				if (REG_SEL && DMWR && !CPU_STALL) begin
					case (DMA[4:0])
						5'h05: PFO <= DMDO[7:0];	//3FE5
						5'h06: PFCSC <= DMDO;		//3FE6
						5'h1E: WSCR <= DMDO;			//3FFE
						5'h1F: SCR <= DMDO;			//3FFF
					endcase
				end
				
				if ((EXT_PMWR || EXT_PMRD) && !WAIT) begin
					WS_CNT <= WS_CNT + 3'd1;
					if (WS_CNT == SCR[2:0]) begin
						WS_CNT <= '0;
					end
				end
				if ((EXT_DMWR || EXT_DMRD) && !WAIT) begin
					WS_CNT <= WS_CNT + 3'd1;
					if (WS_CNT == WSCR[14:12]) begin
						WS_CNT <= '0;
					end
				end
				if (BDMA_EXEC && !BDMA_STATE && !BDMAC[2]) begin
					if (WS_CNT == PFCSC[14:12]) begin
						if (!WAIT) begin
							WS_CNT <= '0;
						end
					end else begin
						WS_CNT <= WS_CNT + 3'd1;
					end
				end
			end
		end
	end
	assign PMEM_WAIT = (EXT_PMWR || EXT_PMRD) && (WS_CNT != SCR[2:0]);
	assign DMEM_WAIT = (EXT_DMWR || EXT_DMRD) && (WS_CNT != WSCR[14:12]);
	assign BDMA_WAIT = (BDMA_EXEC && !BDMA_STATE && !BDMAC[2]) && (WS_CNT != PFCSC[14:12]);
	
	assign DMDI = REG_SEL  ? REG_Q : 
	              EXT_DMRD ? DI[23:8] : 
	              IORD     ? DI[23:8] :
					             DMEM_Q_A;
	
	//BDMA
	always @(posedge CLK or negedge RST_N) begin
		bit  [ 2: 0] BYTE_CNT,BYTE_LEN;
		
		if (!RST_N) begin
			BDMAC <= '0;
			BIAD <= '0;
			BEAD <= '0;
			BWCOUNT <= '0;
			BDMA_BOOT <= 0;
			BDMA_STATE <= 0;
			BYTE_CNT <= '0;
		end else if (!RES_N) begin
			BDMAC <= '0;
			BIAD <= '0;
			BEAD <= '0;
			BWCOUNT <= '0;
			BDMA_BOOT <= 0;
			BDMA_STATE <= 0;
			BYTE_CNT <= '0;
			if (!MMAP && !BMODE)begin
				BWCOUNT <= 14'h0020;
				BDMA_BOOT <= 1;
			end
		end else begin
			casex (BDMAC[1:0])
				2'b00: BYTE_LEN = 2'd2;
				2'b01: BYTE_LEN = 2'd1;
				2'b1x: BYTE_LEN = 2'd0;
			endcase
			
			if (CE_R) begin
				if (BWCOUNT) begin
					if (!BDMA_STATE) begin	//access Byte memory
						if (!BDMA_WAIT && !WAIT) begin
							{BDMAC[15:8],BEAD} <= {BDMAC[15:8],BEAD} + 22'd1;
							BDMA_BUF[BYTE_CNT] = DI[15:8];
							BYTE_CNT <= BYTE_CNT + 2'd1;
							if (BYTE_CNT == BYTE_LEN) begin
								BYTE_CNT <= '0;
								BDMA_STATE <= 1;
							end
						end
					end else begin			//access internal memory
						BIAD <= BIAD + 14'd1;
						BWCOUNT <= BWCOUNT - 14'd1;
						BDMA_STATE <= 0;
					end
				end else begin
					if (BDMA_BOOT) BDMA_BOOT <= 0;
				end
				
				if (REG_SEL && DMWR && !CPU_STALL) begin
					case (DMA[4:0])
						5'h01: BIAD <= DMDO[13:0];	//3FE1
						5'h02: BEAD <= DMDO[13:0];	//3FE2
						5'h03: BDMAC <= DMDO[15:0];	//3FE3
						5'h04: BWCOUNT <= DMDO[13:0];	//3FE4
					endcase
				end
			end
		end
	end
	
	//SPORT0
	bit  [15: 0] RX0,TX0;
	bit  [15: 0] TSR0,RSR0;
	bit          SPORT0_SCLK;
	bit          SPORT0_CE;
	bit          SPORT1_SCLK;
	bit          SPORT1_CE;
	always @(posedge CLK or negedge RST_N) begin		
		bit          SCLK0_I_OLD;	
		bit  [15: 0] DIV_CNT;
		bit  [ 3: 0] BIT_CNT;
		bit          TR_PEND;
		bit          TR_RUN;
		bit          AUTO_PEND;
		
		if (!RST_N) begin
			RX0 <= '0;
			TX0 <= '0;
			TSR0 <= '0;
			{IRQSP0R,IRQSP0T} <= '0;
			SPORT0SCLKDIV <= '0;
			SPORT0CTRL <= '0;
			DIV_CNT <= '0;
			BIT_CNT <= '0;
			TR_PEND <= '0;
			TR_RUN <= '0;
			SPORT0AUTO_REQ <= 0;
			TFS0_O <= 0;
			DT0 <= 0;
		end else if (!RES_N) begin
			RX0 <= '0;
			TX0 <= '0;
			TSR0 <= '0;
			{IRQSP0R,IRQSP0T} <= '0;
			SPORT0SCLKDIV <= '0;
			SPORT0CTRL <= '0;
			DIV_CNT <= '0;
			BIT_CNT <= '0;
			TR_PEND <= '0;
			TR_RUN <= '0;
			SPORT0AUTO_REQ <= 0;
			TFS0_O <= 0;
			DT0 <= 0;
		end else begin
			if (CE_R) begin
				SPORT0_CE <= 0;
				if (SPORT0CTRL[14]) begin
					DIV_CNT <= DIV_CNT + 16'd1;
					if (DIV_CNT == 16'd27/*SPORT0SCLKDIV*/) begin
						DIV_CNT <= '0;
						SPORT0_CE <= SCR[12];
					end
				end else begin
					SCLK0_I_OLD <= SCLK0_I;
					if (SCLK0_I ^ SCLK0_I_OLD) begin
						SPORT0_CE <= SCR[12];
					end
				end
				if (SPORT0_CE) SPORT0_SCLK <= ~SPORT0_SCLK;
				
				{IRQSP0R,IRQSP0T} <= '0;
				if (TR_RUN && !SPORT0_SCLK && SPORT0_CE) begin
					TFS0_O <= 0;
					
					BIT_CNT <= BIT_CNT + 4'd1;
					if (BIT_CNT == SPORT0CTRL[3:0]) begin
						TFS0_O <= 1;
						BIT_CNT <= '0;
						if (!TR_PEND) TR_RUN <= 0;
					end
					if (BIT_CNT == 4'd0) begin
						{DT0,TSR0} <= {TX0 << (4'd15-SPORT0CTRL[3:0]),1'b0};
						TR_PEND <= 0;
						if (!SPORT0ABUF[1]) IRQSP0T <= 1;
						if ( SPORT0ABUF[1]) begin
							AUTO_PEND <= 1;
						end
					end else begin
						{DT0,TSR0} <= {TSR0,1'b0};
					end
				end
				if(!PMEM_WAIT && !DMEM_WAIT) begin
					if (SPORT0AUTO_REQ) 
						SPORT0AUTO_REQ <= 0;
						
					if (AUTO_PEND) begin
						AUTO_PEND <= 0;
						SPORT0AUTO_REQ <= 1;
					end
				end
				
				if (RX0WE) RX0 <= RTXO;
				if (TX0WE) begin TX0 <= RTXO; TR_PEND <= 1; if (!TR_RUN) TR_RUN <= SCR[12]; end
				if (SPORT0AUTO_REQ) begin TX0 <= DMEM_Q_A; TR_PEND <= 1; end
				if (REG_SEL && DMWR && !CPU_STALL) begin
					case (DMA[4:0])
						5'h13: SPORT0ABUF <= DMDO;	//3FF3
						5'h15: SPORT0SCLKDIV <= DMDO;	//3FF5
						5'h16: SPORT0CTRL <= DMDO;	//3FF6
					endcase
				end
			end
		end
	end
	assign SCLK0_O = SPORT0_SCLK;
	
	//SPORT1
	bit  [15: 0] RX1,TX1;
	bit  [15: 0] TSR1,RSR1;
	always @(posedge CLK or negedge RST_N) begin	
		bit          SCLK1_I_OLD;	
		bit  [15: 0] DIV_CNT;
		bit  [ 3: 0] BIT_CNT;
		bit          TR_PEND;
		bit          TR_RUN;
		bit          AUTO_PEND;
		
		if (!RST_N) begin
			RX1 <= '0;
			TX1 <= '0;
			TSR1 <= '0;
			{IRQSP1R,IRQSP1T} <= '0;
			SPORT1SCLKDIV <= '0;
			SPORT1CTRL <= '0;
			DIV_CNT <= '0;
			BIT_CNT <= '0;
			TR_PEND <= '0;
			TR_RUN <= '0;
			SPORT1AUTO_REQ <= 0;
			TFS1_O <= 0;
			DT1 <= 0;
		end else if (!RES_N) begin
			RX1 <= '0;
			TX1 <= '0;
			TSR1 <= '0;
			{IRQSP1R,IRQSP1T} <= '0;
			SPORT1SCLKDIV <= '0;
			SPORT1CTRL <= '0;
			DIV_CNT <= '0;
			BIT_CNT <= '0;
			TR_PEND <= '0;
			TR_RUN <= '0;
			SPORT1AUTO_REQ <= 0;
			TFS1_O <= 0;
			DT1 <= 0;
		end else begin
			if (CE_R) begin
				SPORT1_CE <= 0;
				if (SPORT1CTRL[14]) begin
					DIV_CNT <= DIV_CNT + 16'd1;
					if (DIV_CNT == SPORT1SCLKDIV) begin
						DIV_CNT <= '0;
						SPORT1_CE <= SCR[11]&SCR[10];
					end
				end else begin
					SCLK1_I_OLD <= SCLK1_I;
					if (SCLK1_I ^ SCLK1_I_OLD) begin
						SPORT1_CE <= SCR[12]&SCR[10];
					end
				end
				if (SPORT1_CE) SPORT1_SCLK <= ~SPORT1_SCLK;
				
				{IRQSP1R,IRQSP1T} <= '0;
				if (TR_RUN && !SPORT1_SCLK && SPORT1_CE) begin
					TFS1_O <= 0;
					
					BIT_CNT <= BIT_CNT + 4'd1;
					if (BIT_CNT == SPORT1CTRL[3:0]) begin
						TFS1_O <= 1;
						BIT_CNT <= '0;
						if (!TR_PEND) TR_RUN <= 0;
					end
					if (BIT_CNT == 4'd0) begin
						{DT1,TSR1} <= {TX1 << (4'd15-SPORT1CTRL[3:0]),1'b0};
						TR_PEND <= 0;
						if (!SPORT1ABUF[1]) IRQSP1T <= 1;
						if ( SPORT1ABUF[1]) begin
							AUTO_PEND <= 1;
						end
					end else begin
						{DT1,TSR1} <= {TSR1,1'b0};
					end
				end
				if(!PMEM_WAIT && !DMEM_WAIT) begin
					if(!SPORT0AUTO_REQ && SPORT1AUTO_REQ) 
						SPORT1AUTO_REQ <= 0;
						
					if (AUTO_PEND) begin
						AUTO_PEND <= 0;
						SPORT1AUTO_REQ <= 1;
					end
				end
				
				if (RX1WE) RX1 <= RTXO;
				if (TX1WE) begin TX1 <= RTXO; TR_PEND <= 1; if (!TR_RUN) TR_RUN <= SCR[11]&SCR[10]; end
				if (!SPORT0AUTO_REQ && SPORT1AUTO_REQ) begin TX1 <= DMEM_Q_A; TR_PEND <= 1; end
				if (REG_SEL && DMWR && !CPU_STALL) begin
					case (DMA[4:0])
						5'h0F: SPORT1ABUF <= DMDO;	//3FEF
						5'h11: SPORT1SCLKDIV <= DMDO;	//3FF1
						5'h12: SPORT1CTRL <= DMDO;	//3FF2
					endcase
				end
			end
		end
	end
	assign SCLK1_O = SPORT1_SCLK;
	assign {RX0I,TX0I,RX1I,TX1I} = {RX0,TX0,RX1,TX1};
	
	//Timer
	always @(posedge CLK or negedge RST_N) begin		
		bit  [ 7: 0] DIV_CNT;
		bit          TICK;
		
		if (!RST_N) begin
			TCOUNT <= '0;
			TPERIOD <= '0;
			TSCALE <= '0;
			IRQTM <= 0;
			DIV_CNT <= '0;
		end else if (!RES_N) begin
			TCOUNT <= '0;
			TCOUNT <= '0;
			TSCALE <= '0;
			DIV_CNT <= '0;
		end else begin
			if (CE_R) begin
				IRQTM <= 0;
				
				if (TM_EN) begin
					DIV_CNT <= DIV_CNT+ 8'd1;
					TICK <= 0;
					if (DIV_CNT == TSCALE) begin
						DIV_CNT <= '0;
						TICK <= 1;
					end
				end
				
				if (TICK) begin
					TCOUNT <= TCOUNT - 16'd1;
					if (!TCOUNT) begin
						TCOUNT <= TPERIOD;
						IRQTM <= 1;
					end
				end
				
				if (REG_SEL && DMWR && !CPU_STALL) begin
					case (DMA[4:0])
						5'h1B: TSCALE <= DMDO[7:0];	//3FFB
						5'h1C: TCOUNT <= DMDO;	//3FFC
						5'h1D: TPERIOD <= DMDO;	//3FFD
					endcase
				end
			end
		end
	end
	
	//Interrupts
	always @(posedge CLK or negedge RST_N) begin		
		bit          IRQ2_N_OLD,IRQE_N_OLD,BDMA_EXEC_OLD;
		
		if (!RST_N) begin
			{IRQBD,IRQE,IRQL0,IRQL1,IRQ2} <= '0;
		end else if (!RES_N) begin
			{IRQBD,IRQE,IRQL0,IRQL1,IRQ2} <= '0;
		end else begin
			if (CE_R) begin
				IRQ2_N_OLD <= IRQ2_N;
				IRQE_N_OLD <= IRQE_N;
				BDMA_EXEC_OLD <= BDMA_EXEC;
				
				IRQL0 <= ~IRQL0_N;
				IRQL1 <= ~IRQL1_N;
				IRQ2 <= ~IRQ2_N & (IRQ2_N_OLD|~ICNTL[2]);
				IRQE <= ~IRQE_N & IRQE_N_OLD;
				IRQBD <= ~BDMA_EXEC & BDMA_EXEC_OLD;
			end
		end
	end
	
	
	always_comb begin
		case (DMA[4:0])
			5'h01: REG_Q = {2'b00,BIAD};
			5'h02: REG_Q = {2'b00,BEAD};
			5'h03: REG_Q = BDMAC;
			5'h04: REG_Q = {2'b00,BWCOUNT};
			5'h05: REG_Q = {8'h00,PFI};
			5'h06: REG_Q = PFCSC;
			5'h0F: REG_Q = SPORT1ABUF;
			5'h11: REG_Q = SPORT1SCLKDIV;
			5'h12: REG_Q = SPORT1CTRL;
			5'h13: REG_Q = SPORT0ABUF;
			5'h15: REG_Q = SPORT0SCLKDIV;
			5'h16: REG_Q = SPORT0CTRL;
			5'h1B: REG_Q = {8'h00,TSCALE};
			5'h1C: REG_Q = TCOUNT;
			5'h1D: REG_Q = TPERIOD;
			5'h1E: REG_Q = WSCR;
			5'h1F: REG_Q = SCR;
			default: REG_Q = '0;
		endcase
	end
	
	assign A = BDMA_EXEC                            ? BEAD : 
	           EXT_PMWR || EXT_PMRD                 ? EXT_PMA : 
				  EXT_DMWR || EXT_DMRD || IORD || IOWR ? EXT_DMA : '0;
	assign DO = BDMA_EXEC ? {BDMAC[15:8],16'h0000} : 
	            EXT_PMWR || EXT_PMRD ? PMDO :
					EXT_DMWR || EXT_DMRD || IORD || IOWR ? {DMDO,8'h00} : '0;
	assign WR_N = ~(BDMA_EXEC ? ~BDMA_STATE &  BDMAC[2] : EXT_PMWR | EXT_DMWR | IOWR);
	assign RD_N = ~(BDMA_EXEC ? ~BDMA_STATE & ~BDMAC[2] : EXT_PMRD | EXT_DMRD | IORD);
	
	assign PMS_N = ~(BDMA_EXEC ? 1'b0 : EXT_PMWR | EXT_PMRD);
	assign DMS_N = ~(BDMA_EXEC ? 1'b0 : EXT_DMWR | EXT_DMRD);
	assign BMS_N = ~(BDMA_EXEC ? ~BDMA_STATE : 1'b0);
	assign CMS_N = 1;
	assign IOMS_N = ~(IORD | IOWR);
	
endmodule

module ADSP_21XX_CORE
(
	input              CLK,
	input              RST_N,
	input              CE,
	
	input              RES_N,
	
	input              RUN,
	
	input              IRQTM,
	input              IRQSP0R,
	input              IRQSP0T,
	input              IRQBD,
	input              IRQE,
	input              IRQSP1R,
	input              IRQSP1T,
	input              IRQL0,
	input              IRQL1,
	input              IRQ2,
	
	output     [13: 0] PMIA,
	input      [23: 0] PMIDI,
	
	output     [13: 0] PMA,
	input      [23: 0] PMDI,
	output     [23: 0] PMDO,
	output             PMWR,
	output             PMRD,
	
	output     [13: 0] DMA,
	input      [15: 0] DMDI,
	output     [15: 0] DMDO,
	output             DMWR,
	output             DMRD,
	
	output             IOWR,
	output             IORD,
	
	output reg [ 4: 0] ICNTL,
	
	output reg [ 3: 0] PMOVLAY,
	output reg [ 3: 0] DMOVLAY,
	
	input      [15: 0] TX0I,
	input      [15: 0] TX1I,
	input      [15: 0] RX0I,
	input      [15: 0] RX1I,
	output     [15: 0] RTXO,
	output             TX0WE,
	output             TX1WE,
	output             RX0WE,
	output             RX1WE,
	input      [ 2: 0] ATX0I,
	input      [ 1: 0] ATX0M,
	input              ATX0REQ,
	input      [ 2: 0] ATX1I,
	input      [ 1: 0] ATX1M,
	input              ATX1REQ,
	
	output             TM_EN,
	
	input              FI,
	output reg         FO,
	output reg [ 2: 0] FL
);
	
	import ADSP_21XX_PKG::*;
	
	bit  [13: 0] PC;
	bit  [23: 0] IR;
	bit  [13: 0] CNTR;
	bit  [15: 0] LOOP;
	bit  [ 7: 0] ASTAT,SSTAT;
	bit  [ 6: 0] MSTAT;
	bit  [ 9: 0] IMASK;
	bit          SS,MV,AQ,AS,AC,AV,AN,AZ;
	bit  [13: 0] DAG_I[8],DAG_M[8],DAG_L[8];
	bit  [ 7: 0] PX;
	bit  [15: 0] AX0[2],AX1[2],AY0[2],AY1[2];
	bit  [15: 0] AR[2],AF[2];
	bit  [15: 0] MX0[2],MX1[2],MY0[2],MY1[2];
	bit  [15: 0] MF[2];
	bit  [15: 0] MR0[2],MR1[2];
	bit  [ 7: 0] MR2[2];
	bit  [15: 0] SB[2],SI[2];
	bit  [ 7: 0] SE[2];
	bit  [15: 0] SR0[2],SR1[2];
//	bit  [ 4: 0] ICNTL;
	bit          RES,IDLE;
	bit  [ 7: 0] IFC;
	bit          INT_EN;
	bit          INT_REQ;
	bit          COND,LOOP_COND;
	bit  [13: 0] DAG1_ADDR,DAG2_ADDR;
	
	bit  [15: 0] DMD;
	
	DecInstr_t   DECI;
	bit  [13: 0] PCSTACK_Q,PCSTACK_Q2;
	bit          PCSTACK_EMPTY,PCSTACK_FULL;
	bit  [24: 0] STATSTACK_Q;
	bit          STATSTACK_EMPTY,STATSTACK_FULL;
	bit  [17: 0] LOOPSTACK_Q;
	bit          LOOPSTACK_EMPTY,LOOPSTACK_FULL;
	bit  [13: 0] CNTRSTACK_Q;
	bit          CNTRSTACK_EMPTY,CNTRSTACK_FULL;
	
	assign {SS,MV,AQ,AS,AC,AV,AN,AZ} = ASTAT;
	assign SSTAT = {LOOPSTACK_FULL,LOOPSTACK_EMPTY,STATSTACK_FULL,STATSTACK_EMPTY,CNTRSTACK_FULL,CNTRSTACK_EMPTY,PCSTACK_FULL,PCSTACK_EMPTY};
	
	wire         EN = RUN && !IDLE;
	
	//Program sequencer
	wire         INT_HIT = |(IMASK & {IFC[7],IRQL1,IRQL0,IFC[6:0]});
	wire [13: 0] INT_VECT = IFC[7] && IMASK[9] ? 14'h0004 : //IRQ2
	                        IRQL1  && IMASK[8] ? 14'h0008 : //IRQL1
									IRQL0  && IMASK[7] ? 14'h000C : //IRQL0
									IFC[6] && IMASK[6] ? 14'h0010 : //SPORT0 transmit
									IFC[5] && IMASK[5] ? 14'h0014 : //SPORT0 receive
									IFC[4] && IMASK[4] ? 14'h0018 : //IRQE
									IFC[3] && IMASK[3] ? 14'h001C : //BDMA
									IFC[2] && IMASK[2] ? 14'h0020 : //SPORT1 transmit
									IFC[1] && IMASK[1] ? 14'h0024 : //SPORT1 receive
									IFC[0] && IMASK[0] ? 14'h0028 : //Timer
									                     14'h0000;
	
	wire [ 7: 0] INT_MASK = IFC[7] && IMASK[9] ? 8'h80 : //IRQ2
	                        IRQL1  && IMASK[8] ? 8'h00 : //IRQL1
									IRQL0  && IMASK[7] ? 8'h00 : //IRQL0
									IFC[6] && IMASK[6] ? 8'h40 : //SPORT0 transmit
									IFC[5] && IMASK[5] ? 8'h20 : //SPORT0 receive
									IFC[4] && IMASK[4] ? 8'h10 : //IRQE
									IFC[3] && IMASK[3] ? 8'h08 : //BDMA
									IFC[2] && IMASK[2] ? 8'h04 : //SPORT1 transmit
									IFC[1] && IMASK[1] ? 8'h02 : //SPORT1 receive
									IFC[0] && IMASK[0] ? 8'h01 : //Timer
									                     8'h00;
	bit  [13: 0] INT_ADDR;
	bit  [13: 0] NEXT_IADDR;
	wire [13: 0] PC_NEXT = PC + (!INT_REQ && !RES ? 14'd1 : 14'd0);
	always_comb begin
		if (INT_REQ)
			NEXT_IADDR = INT_ADDR;
		else if (COND)
			case (DECI.NADDR)
				NA_STACK: NEXT_IADDR = PCSTACK_Q;
				NA_INT: NEXT_IADDR = '0;
				NA_IMM: NEXT_IADDR = IR[17:4];
				NA_IMMF: NEXT_IADDR = {IR[3:2],IR[15:4]};
				default: NEXT_IADDR = PC_NEXT;
			endcase
		else
			NEXT_IADDR = PC_NEXT;
	end
	wire LOOP_LAST = (LOOPSTACK_Q[17:4] == PC) && !LOOPSTACK_EMPTY && !INT_REQ;
	
	bit  [13: 0] NEXT_PMIA;
	always_comb begin
		if (COND && DECI.IJMP)
			NEXT_PMIA = DAG_I[{1'b1,IR[7:6]}];
		else if (LOOP_LAST && LOOP_COND)
			NEXT_PMIA = PCSTACK_Q;
		else
			NEXT_PMIA = NEXT_IADDR;
	end
	assign PMIA = NEXT_PMIA;
	
	assign PMA = DAG2_ADDR;
	assign PMDO = DECI.IPMWI ? {DMD,PX} : '0;
	assign PMWR = DECI.IPMWI;
	assign PMRD = DECI.IPMRI;
	
	wire CNTR_CE = (CNTR == 14'h0001);
	
	always @(posedge CLK or negedge RST_N) begin
		bit          INT_HOLD;
		
		if (!RST_N) begin
			PC <= '0;
			IR <= '0;
			MSTAT <= '0;
			IMASK <= '0;
			ICNTL <= '0;
			CNTR <= '0;
			INT_EN <= 1;
			INT_REQ <= 0;
			INT_ADDR <= '0;
			INT_HOLD <= 0;
			RES <= 1;
			IDLE <= 0;
		end else if (!RES_N) begin
			PC <= '0;
			IR <= '0;
			MSTAT <= '0;
			IMASK <= '0;
			ICNTL <= '0;
			CNTR <= '0;
			INT_EN <= 1;
			INT_REQ <= 0;
			INT_ADDR <= '0;
			INT_HOLD <= 0;
			RES <= 1;
			IDLE <= 0;
		end else begin
			if (CE) begin
				if (IRQTM) IFC[0] <= 1;
				if (IRQSP1R) IFC[1] <= 1;
				if (IRQSP1T) IFC[2] <= 1;
				if (IRQBD) IFC[3] <= 1;
				if (IRQE) IFC[4] <= 1;
				if (IRQSP0R) IFC[5] <= 1;
				if (IRQSP0T) IFC[6] <= 1;
				if (IRQ2) IFC[7] <= 1;
				
				if (INT_HIT && IDLE) IDLE <= 0;
			end
			
			if (EN && CE) begin
				IR <= PMIDI;
				PC <= NEXT_PMIA;
				
				INT_REQ <= 0;
				if (INT_HIT && !INT_HOLD && INT_EN) begin
					INT_REQ <= 1;
					INT_ADDR <= INT_VECT;
					INT_HOLD <= 1;
				end
				if (INT_REQ) begin
					IMASK <= '0;
					IFC <= IFC & ~INT_MASK;
					INT_HOLD <= 0;
				end
				
				if ((LOOPSTACK_Q[3:0] == 4'hE && LOOP_LAST && LOOP_COND) || (DECI.CC == 4'hE && DECI.NADDR == NA_IMM && !CNTR_CE)) begin
					CNTR <= CNTR - 14'd1;
				end
				if ((LOOPSTACK_Q[3:0] == 4'hE && LOOP_LAST && !LOOP_COND) || (DECI.CC == 4'hE && DECI.NADDR == NA_IMM && CNTR_CE)) begin
					CNTR <= CNTRSTACK_Q;
				end
				
				RES <= 0;
				if (DECI.IDLE) IDLE <= 1;
			end
			
			if (COND && EN && CE) begin
				if (DECI.MODE) begin
					if (IR[15]) MSTAT[5] <= IR[14];
					if (IR[13]) MSTAT[4] <= IR[12];
					if (IR[11]) MSTAT[3] <= IR[10];
					if (IR[ 9]) MSTAT[2] <= IR[ 8];
					if (IR[ 7]) MSTAT[1] <= IR[ 6];
					if (IR[ 5]) MSTAT[0] <= IR[ 4];
					if (IR[ 3]) MSTAT[6] <= IR[ 2];
				end
				if (DECI.STPOP) begin
					{IMASK,MSTAT} <= STATSTACK_Q[24:8];
				end
				if (DECI.EINT) begin
					INT_EN <= IR[5];
				end
				
				if ((DECI.MOVI || DECI.DMRI) && DECI.DRGP == 2'b11) begin
					casex (DECI.DREG)
						4'b0001: MSTAT <= DMD[6:0];
						4'b0011: IMASK <= DMD[9:0];
						4'b0100: ICNTL <= DMD[4:0];
						4'b0101: CNTR <= DMD[13:0];//with push to CNTRSTACK
						4'b1100: IFC <= (IFC | DMD[15:8]) & ~DMD[7:0];
						4'b1101: CNTR <= DMD[13:0];
					endcase
				end
				if (DECI.LDRI && DECI.DRGP == 2'b11) begin
					casex (DECI.DREG)
						4'b0001: MSTAT <= IR[10:4];
						4'b0011: IMASK <= IR[13:4];
						4'b0100: ICNTL <= IR[8:4];
						4'b0101: CNTR <= IR[17:4];//with push to CNTRSTACK
						4'b1100: IFC <= (IFC | {2'b00,IR[17:12]}) & ~IR[11:4];
						4'b1101: CNTR <= IR[17:4];
					endcase
				end
			end
		end
	end
	
	ADSP_21xx_STACK #(4,14) PCSTACK (CLK, ~RES_N, 1'b1, (INT_REQ ? PC : DECI.MOVI ? DMD[13:0] : PC_NEXT), (((DECI.PCPUSH & COND) | INT_REQ) & EN & CE), (((DECI.PCPOP & COND) | (LOOP_LAST & !LOOP_COND)) & EN & CE), PCSTACK_Q, PCSTACK_EMPTY, PCSTACK_FULL, PCSTACK_Q2);
	ADSP_21xx_STACK #(2,25) STATSTACK (CLK, ~RES_N, 1'b1, {IMASK,MSTAT,ASTAT}, (((DECI.STPUSH & COND) | INT_REQ) & EN & CE), (DECI.STPOP & COND & EN & CE), STATSTACK_Q, STATSTACK_EMPTY, STATSTACK_FULL);
	ADSP_21xx_STACK #(2,18) LOOPSTACK (CLK, ~RES_N, 1'b1, IR[17:0], (DECI.DOI & EN & CE), (((DECI.LPPOP & COND) | (LOOP_LAST & !LOOP_COND)) & EN & CE), LOOPSTACK_Q, LOOPSTACK_EMPTY, LOOPSTACK_FULL);
	wire CNTRSTACK_PUSH = ((DECI.LDRI || DECI.MOVI || DECI.DMRI) && DECI.DRGP == 2'b11 && DECI.DREG == 4'b0101);
	wire CNTRSTACK_POP = (LOOPSTACK_Q[3:0] == 4'hE & LOOP_LAST & !LOOP_COND) || (DECI.CC == 4'hE && DECI.NADDR == NA_IMM && CNTR_CE);
	ADSP_21xx_STACK #(2,14) CNTRSTACK (CLK, ~RES_N, 1'b1, CNTR, (CNTRSTACK_PUSH & COND & EN & CE), (((DECI.CNPOP & COND) | CNTRSTACK_POP) & EN & CE), CNTRSTACK_Q, CNTRSTACK_EMPTY, CNTRSTACK_FULL);
	
	assign TM_EN = MSTAT[MSTAT_TIMER];
	wire RB = MSTAT[MSTAT_SEC_REG];
	
	//Decoder
	assign DECI = INT_REQ ? '0 : Decode(IR);
	
	always_comb begin
		bit          C;
		
		case (DECI.CC)
			4'h0: C = AZ;						//EQ
			4'h1: C = ~AZ;						//NE
			4'h2: C = ~((AN ^ AV) | AZ);	//GT
			4'h3: C = (AN ^ AV) | AZ;		//LE
			4'h4: C = (AN ^ AV);				//LT
			4'h5: C = ~(AN ^ AV);			//GE
			4'h6: C = AV;						//AV
			4'h7: C = ~AV;						//NOT AV
			4'h8: C = AC;						//AC
			4'h9: C = ~AC;						//NOT AC
			4'hA: C = AS;						//NEG
			4'hB: C = ~AS;						//POS
			4'hC: C = MV;						//MV
			4'hD: C = ~MV;						//NOT MV
			4'hE: C = ~CNTR_CE;				//NOT CE
			4'hF: C = 1;						//Always
		endcase
		
		if (DECI.NADDR == NA_IMMF)
			case (IR[1])
				1'b0: COND = FI;
				1'b1: COND = ~FI;
			endcase
		else if (LOOP_LAST)
			COND = 1;
		else
			COND = C;
			
		case (LOOPSTACK_Q[3:0])
			4'h0: LOOP_COND = AZ;					//EQ
			4'h1: LOOP_COND = ~AZ;					//NE
			4'h2: LOOP_COND = ~((AN ^ AV) | AZ);//GT
			4'h3: LOOP_COND = (AN ^ AV) | AZ;	//LE
			4'h4: LOOP_COND = (AN ^ AV);			//LT
			4'h5: LOOP_COND = ~(AN ^ AV);			//GE
			4'h6: LOOP_COND = AV;					//AV
			4'h7: LOOP_COND = ~AV;					//NOT AV
			4'h8: LOOP_COND = AC;					//AC
			4'h9: LOOP_COND = ~AC;					//NOT AC
			4'hA: LOOP_COND = AS;					//NEG
			4'hB: LOOP_COND = ~AS;					//POS
			4'hC: LOOP_COND = MV;					//MV
			4'hD: LOOP_COND = ~MV;					//NOT MV
			4'hE: LOOP_COND = ~CNTR_CE;				//CE
			4'hF: LOOP_COND = 1;						//Always
		endcase
	end
	
	//ALU&MAC
	bit  [15: 0] ALU_RES;
	bit          ALU_Q,ALU_S,ALU_C,ALU_N,ALU_V,ALU_Z;
	bit  [39: 0] MAC_RES;
	bit          MAC_V;

	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			// synopsys translate_off
			AX0 <= '{2{'0}};
			AX1 <= '{2{'0}};
			AY0 <= '{2{'0}};
			AY1 <= '{2{'0}};
			MX0 <= '{2{'0}};
			MX1 <= '{2{'0}};
			MY0 <= '{2{'0}};
			MY1 <= '{2{'0}};
			// synopsys translate_on
		end else if (!RES_N) begin
			AX0 <= '{2{'0}};
			AX1 <= '{2{'0}};
			AY0 <= '{2{'0}};
			AY1 <= '{2{'0}};
			MX0 <= '{2{'0}};
			MX1 <= '{2{'0}};
			MY0 <= '{2{'0}};
			MY1 <= '{2{'0}};
		end else begin
			if (COND && EN && CE) begin
				if (DECI.DIVS || DECI.DIVQ) begin
					AY0[RB] <= {AY0[RB][14:0],ALU_Q^DECI.DIVQ};
				end
				
				if ((DECI.MOVI || DECI.DMRI || DECI.IORI || (DECI.IDMRI && !DECI.IPMRI) || (DECI.IPMRI && !DECI.IDMRI)) && DECI.DRGP == 2'b00) begin
					case (DECI.DREG)
						4'b0000: AX0[RB] <= DMD;
						4'b0001: AX1[RB] <= DMD;
						4'b0010: MX0[RB] <= DMD;
						4'b0011: MX1[RB] <= DMD;
						4'b0100: AY0[RB] <= DMD;
						4'b0101: AY1[RB] <= DMD;
						4'b0110: MY0[RB] <= DMD;
						4'b0111: MY1[RB] <= DMD;
					endcase
				end
				if (DECI.LDRI && DECI.DRGP == 2'b00) begin
					case (DECI.DREG)
						4'b0000: AX0[RB] <= IR[19:4];
						4'b0001: AX1[RB] <= IR[19:4];
						4'b0010: MX0[RB] <= IR[19:4];
						4'b0011: MX1[RB] <= IR[19:4];
						4'b0100: AY0[RB] <= IR[19:4];
						4'b0101: AY1[RB] <= IR[19:4];
						4'b0110: MY0[RB] <= IR[19:4];
						4'b0111: MY1[RB] <= IR[19:4];
					endcase
				end
				
				//dual data read
				if (DECI.IDMRI && DECI.IPMRI && DECI.DRGP == 2'b00) begin 
					case (DECI.DREG[1:0])
						2'b00: AX0[RB] <= DMD;
						2'b01: AX1[RB] <= DMD;
						2'b10: MX0[RB] <= DMD;
						2'b11: MX1[RB] <= DMD;
					endcase
					case (DECI.DREG2)
						2'b00: AY0[RB] <= PMDI[23:8];
						2'b01: AY1[RB] <= PMDI[23:8];
						2'b10: MY0[RB] <= PMDI[23:8];
						2'b11: MY1[RB] <= PMDI[23:8];
					endcase
				end
			end
		end
	end
	
	always_comb begin
		bit  [ 3: 0] FC;
		bit  [15: 0] ALU_X,ALU_Y;
		bit  [15: 0] SUM_A,SUM_B;
		bit          SUM_C;
		bit  [16: 0] SUM_R;
		
		case (DECI.ALUX)
			3'b000: ALU_X = AX0[RB];
			3'b001: ALU_X = AX1[RB];
			3'b010: ALU_X = AR[RB];
			3'b011: ALU_X = MR0[RB];
			3'b100: ALU_X = MR1[RB];
			3'b101: ALU_X = MR2[RB];
			3'b110: ALU_X = SR0[RB];
			3'b111: ALU_X = SR1[RB];
		endcase
		casex (DECI.ALUY)
			3'b000: ALU_Y = AY0[RB];
			3'b001: ALU_Y = AY1[RB];
			3'b010: ALU_Y = AF[RB];
			3'b011: ALU_Y = '0;
			3'b1xx: ALU_Y = Constant(IR[12:11],IR[7:6],IR[5:4]);
		endcase
		
		FC = DECI.DIVS ? 4'h0 : DECI.DIVQ ? (AQ ? 4'h3 : 4'h9) : DECI.ALUFC[3:0];
		case (FC)
			4'h0: begin SUM_A = ALU_Y; SUM_B = '0;    SUM_C = '0; end
			4'h1: begin SUM_A = ALU_Y; SUM_B = 16'd1; SUM_C = '0; end
			4'h2: begin SUM_A = ALU_X; SUM_B = ALU_Y; SUM_C = AC; end
			4'h3: begin SUM_A = ALU_X; SUM_B = ALU_Y; SUM_C = '0; end
			4'h5: begin SUM_A = '0;    SUM_B = ALU_Y; SUM_C = '0; end
			4'h6: begin SUM_A = ALU_X; SUM_B = ALU_Y; SUM_C = AC; end
			4'h7: begin SUM_A = ALU_X; SUM_B = ALU_Y; SUM_C = '0; end
			4'h8: begin SUM_A = ALU_Y; SUM_B = '0;    SUM_C = '0; end
			4'h9: begin SUM_A = ALU_Y; SUM_B = ALU_X; SUM_C = '0; end
			4'hA: begin SUM_A = ALU_Y; SUM_B = ALU_X; SUM_C = AC; end
			4'hF: begin SUM_A = '0;    SUM_B = ALU_X; SUM_C = '0; end
			default: begin SUM_A = '0;    SUM_B = '0;    SUM_C = '0; end
		endcase
		
		case (FC)
			4'h0,
			4'h1,
			4'h2,
			4'h3: SUM_R = {1'b0,SUM_A} + {1'b0,SUM_B} + {16'h0000,SUM_C};
			4'h5,
			4'h7,
			4'h9,
			4'hF: SUM_R = {1'b0,SUM_A} - {1'b0,SUM_B} + {16'h0000,SUM_C};
			4'h6,
			4'h8,
			4'hA: SUM_R = {1'b0,SUM_A} - {1'b0,SUM_B} + {16'h0000,SUM_C} - 17'd1;
			default: SUM_R = '0;
		endcase
		
		if (DECI.DIVS || DECI.DIVQ) begin
			ALU_RES = {SUM_R[14:0],AY0[RB][15]};
			ALU_Q = ALU_X[15] ^ SUM_R[15];
			{ALU_S,ALU_C,ALU_V,ALU_N,ALU_Z} = {AS,AC,AV,AN,AZ};
		end else begin
			case (DECI.ALUFC[3:0])
				4'h0,
				4'h1,
				4'h2,
				4'h3: ALU_RES = SUM_R[15:0]; 
				4'h4: ALU_RES = ~ALU_Y; 
				4'h5,
				4'h6,
				4'h7,
				4'h8,
				4'h9,
				4'hA: ALU_RES = SUM_R[15:0]; 
				4'hB: ALU_RES = ~ALU_X; 
				4'hC: ALU_RES = ALU_X & ALU_Y; 
				4'hD: ALU_RES = ALU_X | ALU_Y; 
				4'hE: ALU_RES = ALU_X ^ ALU_Y;
				4'hF: ALU_RES = ALU_X[15] ? SUM_R[15:0] : ALU_X; 
			endcase
			case (DECI.ALUFC[3:0])
				4'h0,
				4'h1,
				4'h2,
				4'h3: begin ALU_C =  SUM_R[16]; ALU_V = SUM_A[15] ^ SUM_B[15] ^ SUM_R[15] ^ SUM_R[16]; ALU_N = ALU_RES[15];         ALU_S = AS; end
				4'h4,
				4'hB,
				4'hC,
				4'hD,
				4'hE: begin ALU_C = 0;          ALU_V = 0;                                             ALU_N = ALU_RES[15];         ALU_S = AS; end
				4'h5,
				4'h6,
				4'h7,
				4'h8,
				4'h9,
				4'hA: begin ALU_C = ~SUM_R[16]; ALU_V = SUM_A[15] ^ SUM_B[15] ^ SUM_R[15] ^ SUM_R[16]; ALU_N = ALU_RES[15];         ALU_S = AS; end
				4'hF: begin ALU_C = 0;          ALU_V = (ALU_X == 16'h8000);                           ALU_N = (ALU_X == 16'h8000); ALU_S = ALU_X[15]; end
			endcase
			ALU_Z = ~|ALU_RES;
			ALU_Q = AQ;
		end
	end
	
	bit  [31: 0] MUL_R;
	always @(posedge CLK) begin
		bit  [15: 0] MAC_X,MAC_Y;
		bit  [16: 0] MUL_A,MUL_B;
		
		case (DECI.ALUX)
			3'b000: MAC_X = MX0[RB];
			3'b001: MAC_X = MX1[RB];
			3'b010: MAC_X = AR[RB];
			3'b011: MAC_X = MR0[RB];
			3'b100: MAC_X = MR1[RB];
			3'b101: MAC_X = MR2[RB];
			3'b110: MAC_X = SR0[RB];
			3'b111: MAC_X = SR1[RB];
		endcase
		casex (DECI.ALUY)
			3'b000: MAC_Y = MY0[RB];
			3'b001: MAC_Y = MY1[RB];
			3'b010: MAC_Y = MF[RB];
			3'b011: MAC_Y = '0;
			3'b1xx: MAC_Y = MAC_X;
		endcase
		
		case (DECI.ALUFC[3:0])
			4'h0: begin MUL_A = {MAC_X[15],MAC_X}; MUL_B = {MAC_Y[15],MAC_Y}; end
			4'h1: begin MUL_A = {MAC_X[15],MAC_X}; MUL_B = {MAC_Y[15],MAC_Y}; end
			4'h2: begin MUL_A = {MAC_X[15],MAC_X}; MUL_B = {MAC_Y[15],MAC_Y}; end
			4'h3: begin MUL_A = {MAC_X[15],MAC_X}; MUL_B = {MAC_Y[15],MAC_Y}; end
			4'h4: begin MUL_A = {MAC_X[15],MAC_X}; MUL_B = {MAC_Y[15],MAC_Y}; end
			4'h5: begin MUL_A = {MAC_X[15],MAC_X}; MUL_B = {1'b0     ,MAC_Y}; end
			4'h6: begin MUL_A = {1'b0     ,MAC_X}; MUL_B = {MAC_Y[15],MAC_Y}; end
			4'h7: begin MUL_A = {1'b0     ,MAC_X}; MUL_B = {1'b0     ,MAC_Y}; end
			4'h8: begin MUL_A = {MAC_X[15],MAC_X}; MUL_B = {MAC_Y[15],MAC_Y}; end
			4'h9: begin MUL_A = {MAC_X[15],MAC_X}; MUL_B = {1'b0     ,MAC_Y}; end
			4'hA: begin MUL_A = {1'b0     ,MAC_X}; MUL_B = {MAC_Y[15],MAC_Y}; end
			4'hB: begin MUL_A = {1'b0     ,MAC_X}; MUL_B = {1'b0     ,MAC_Y}; end
			4'hC: begin MUL_A = {MAC_X[15],MAC_X}; MUL_B = {MAC_Y[15],MAC_Y}; end
			4'hD: begin MUL_A = {MAC_X[15],MAC_X}; MUL_B = {1'b0     ,MAC_Y}; end
			4'hE: begin MUL_A = {1'b0     ,MAC_X}; MUL_B = {MAC_Y[15],MAC_Y}; end
			4'hF: begin MUL_A = {1'b0     ,MAC_X}; MUL_B = {1'b0     ,MAC_Y}; end
		endcase
				
		MUL_R <= ($signed(MUL_A) * $signed(MUL_B)) << (~MSTAT[MSTAT_M_MODE]);
	end
		
	always_comb begin
		bit  [39: 0] MR;
		bit  [39: 0] MAC_SUM;
		
		MR = {MR2[RB],MR1[RB],MR0[RB]};
		case (DECI.ALUFC[3:0])
			4'h0: MAC_SUM = MR;
			4'h1: MAC_SUM =      {{8{MUL_R[31]}},MUL_R} + 40'h0000008000;
			4'h2: MAC_SUM = MR + {{8{MUL_R[31]}},MUL_R} + 40'h0000008000;
			4'h3: MAC_SUM = MR - {{8{MUL_R[31]}},MUL_R} + 40'h0000008000;
			4'h4,
			4'h5,
			4'h6,
			4'h7: MAC_SUM =      {{8{MUL_R[31]}},MUL_R};
			4'h8,
			4'h9,
			4'hA,
			4'hB: MAC_SUM = MR + {{8{MUL_R[31]}},MUL_R};
			4'hC,
			4'hD,
			4'hE,
			4'hF: MAC_SUM = MR - {{8{MUL_R[31]}},MUL_R};
		endcase
		case (DECI.ALUFC[3:0])
			4'h1,
			4'h2,
			4'h3: MAC_RES = MAC_SUM & ~(MAC_SUM[15:0] == 16'h8000 ? 40'h0000010000 : 40'h0000000000);
			default: MAC_RES = MAC_SUM;
		endcase
		MAC_V = MAC_RES[39:31] != 9'h000 && MAC_RES[31:23] != 9'h1FF;
	end
	
	always @(posedge CLK or negedge RST_N) begin
		bit  [15: 0] ALU_RES_SAT;
		bit  [39: 0] MAC_RES_SAT;
		
		if (!RST_N) begin
			// synopsys translate_off
			AR <= '{2{'0}};
			AF <= '{2{'0}};
			MR2 <= '{2{'0}};
			MR1 <= '{2{'0}};
			MR0 <= '{2{'0}};
			MF <= '{2{'0}};
			// synopsys translate_on
		end else if (!RES_N) begin
			AR <= '{2{'0}};
			AF <= '{2{'0}};
			MR2 <= '{2{'0}};
			MR1 <= '{2{'0}};
			MR0 <= '{2{'0}};
			MF <= '{2{'0}};
		end else begin
			if (COND && EN && CE) begin
				if ((DECI.AMI && DECI.ALUFC[4]) || DECI.DIVS || DECI.DIVQ) begin
					if (!(DECI.MOVI && DECI.SREG == 4'hA && DECI.DREG == 4'hA)) begin
						ALU_RES_SAT = {ALU_C,{15{~ALU_C}}};
						case (DECI.ALUZ)
							1'b0: AR[RB] <= MSTAT[MSTAT_AR_SAT] && ALU_V ? ALU_RES_SAT : ALU_RES;
							1'b1: AF[RB] <= ALU_RES;
						endcase
					end
					ASTAT[5:0] <= {ALU_Q,ALU_S,ALU_C,ALU_V,ALU_N,ALU_Z};
					if (MSTAT[MSTAT_AV_LATCH] && ASTAT[2]) ASTAT[2] <= 1;
				end
				
				if (DECI.AMI && !DECI.ALUFC[4]) begin
					{MR2[RB],MR1[RB],MR0[RB]} <= MAC_RES;
					ASTAT[6] <= MAC_V;
				end
				if (DECI.SATMR && MV) begin
					{MR2[RB],MR1[RB],MR0[RB]} <= {{9{MR2[RB][7]}},{31{~MR2[RB][7]}}};
				end
				if (DECI.MFU) MF[RB] <= MAC_RES[31:16];
				
				if (DECI.STPOP) ASTAT[6:0] <= STATSTACK_Q[6:0];
				
				if ((DECI.MOVI || DECI.DMRI || DECI.IORI || (DECI.IDMRI && !DECI.IPMRI) || (DECI.IPMRI && !DECI.IDMRI)) && DECI.DRGP == 2'b00) begin
					casex (DECI.DREG)
						4'b1010: AR[RB] <= DMD;
						4'b1011: MR0[RB] <= DMD;
						4'b1100: {MR2[RB],MR1[RB]} <= {{8{DMD[15]}},DMD}; 
						4'b1101: MR2[RB] <= DMD[7:0];
					endcase
				end
				if (DECI.LDRI && DECI.DRGP == 2'b00) begin
					casex (DECI.DREG)
						4'b1010: AR[RB] <= IR[19:4];
						4'b1011: MR0[RB] <= IR[19:4];
						4'b1100: {MR2[RB],MR1[RB]} <= {{8{IR[19]}},IR[19:4]};
						4'b1101: MR2[RB] <= IR[11:4];
					endcase
				end
			end
		end
	end
	
	//Shifter
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			// synopsys translate_off
			SI <= '{2{'0}};
			SB <= '{2{'0}};
			SE <= '{2{'0}};
			// synopsys translate_on
		end else if (!RES_N) begin
			SI <= '{2{'0}};
			SB <= '{2{'0}};
			SE <= '{2{'0}};
		end else begin
			if (COND && EN && CE) begin
				if ((DECI.MOVI || DECI.DMRI || DECI.IORI || (DECI.IDMRI && !DECI.IPMRI) || (DECI.IPMRI && !DECI.IDMRI)) && DECI.DRGP == 2'b00) begin
					casex (DECI.DREG)
						4'b1000: SI[RB] <= DMD;
						4'b1001: SE[RB] <= DMD[7:0];
					endcase
				end
				if ((DECI.MOVI || DECI.DMRI) && DECI.DRGP == 2'b11) begin
					casex (DECI.DREG)
						4'b0110: SB[RB] <= DMD[4:0];
					endcase
				end
				
				if (DECI.LDRI && DECI.DRGP == 2'b00) begin
					casex (DECI.DREG)
						4'b1000: SI[RB] <= IR[19:4];
						4'b1001: SE[RB] <= IR[11:4];
					endcase
				end
				if (DECI.LDRI && DECI.DRGP == 2'b11) begin
					casex (DECI.DREG)
						4'b0110: SB[RB] <= IR[9:4];
					endcase
				end
			end
		end
	end
	
	bit  [31: 0] SHIFTER_RES;
	bit          SHIFTER_SS;
	always_comb begin
		bit  [15: 0] SH_I;
		bit  [ 7: 0] SH_X;
		bit  [31: 0] SH_R;
		
		case (DECI.ALUX)
			3'b000: SH_I = SI[RB];
			3'b001: SH_I = SI[RB];
			3'b010: SH_I = AR[RB];
			3'b011: SH_I = MR0[RB];
			3'b100: SH_I = MR1[RB];
			3'b101: SH_I = MR2[RB];
			3'b110: SH_I = SR0[RB];
			3'b111: SH_I = SR1[RB];
		endcase
		case (IR[16])
			1'b0: SH_X = SE[RB];
			1'b1: SH_X = IR[7:0];
		endcase
		
		SH_R = Shifter(SH_I, SH_X, IR[13], IR[12]);
		
		SHIFTER_RES = SH_R | ({32{IR[11]}} & {SR1[RB],SR0[RB]});
		SHIFTER_SS = 0;
	end
	
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			// synopsys translate_off
			SR0 <= '{2{'0}};
			SR1 <= '{2{'0}};
			// synopsys translate_on
		end else if (!RES_N) begin
			SR0 <= '{2{'0}};
			SR1 <= '{2{'0}};
		end else begin
			if (COND && EN && CE) begin
				if (DECI.SHFTI) begin
					{SR1[RB],SR0[RB]} <= SHIFTER_RES;
					ASTAT[7] <= SHIFTER_SS;
				end
				if ((DECI.MOVI || DECI.DMRI || DECI.IORI || (DECI.IDMRI && !DECI.IPMRI) || (DECI.IPMRI && !DECI.IDMRI)) && DECI.DRGP == 2'b00) begin
					casex (DECI.DREG)
						4'b1110: SR0[RB] <= DMD;
						4'b1111: SR1[RB] <= DMD;
					endcase
				end
				if (DECI.LDRI && DECI.DRGP == 2'b00) begin
					casex (DECI.DREG)
						4'b1110: SR0[RB] <= IR[19:4];
						4'b1111: SR1[RB] <= IR[19:4];
					endcase
				end
				
				if (DECI.STPOP) ASTAT[7] <= STATSTACK_Q[7];
			end
		end
	end
					  
	//DAGs
	bit  [ 2: 0] DAG1_IREG,DAG1_MREG;
	bit  [ 2: 0] DAG2_IREG,DAG2_MREG;
	bit          DAG1_UPDATE,DAG2_UPDATE;
	always_comb begin
		if (ATX0REQ) begin
			DAG1_IREG = {1'b0,ATX0I[1:0]};
			DAG2_IREG = {1'b1,ATX0I[1:0]};
			DAG1_MREG = {1'b0,ATX0M[1:0]};
			DAG2_MREG = {1'b1,ATX0M[1:0]};
			DAG1_UPDATE = ~ATX0I[2];
			DAG2_UPDATE =  ATX0I[2];
		end else if (ATX1REQ) begin
			DAG1_IREG = {1'b0,ATX1I[1:0]};
			DAG2_IREG = {1'b1,ATX1I[1:0]};
			DAG1_MREG = {1'b0,ATX1M[1:0]};
			DAG2_MREG = {1'b1,ATX1M[1:0]};
			DAG1_UPDATE = ~ATX1I[2];
			DAG2_UPDATE =  ATX1I[2];
		end else begin
			DAG1_IREG = {1'b0,DECI.DAG1I};
			DAG2_IREG = {1'b1,DECI.DAG2I};
			DAG1_MREG = {1'b0,DECI.DAG1M};
			DAG2_MREG = {1'b1,DECI.DAG2M};
			DAG1_UPDATE = 0;
			DAG2_UPDATE = 0;
		end
	
	end
	
	always @(posedge CLK or negedge RST_N) begin
		bit  [13: 0] DAG1I_NEXT,DAG2I_NEXT;
		
		if (!RST_N) begin
			// synopsys translate_off
			DAG_I <= '{8{'0}};
			DAG_M <= '{8{'0}};
			DAG_L <= '{8{'0}};
			// synopsys translate_on
		end else if (!RES_N) begin
			DAG_I <= '{8{'0}};
			DAG_M <= '{8{'0}};
			DAG_L <= '{8{'0}};
		end else begin
			DAG1I_NEXT = Modulus(DAG_I[DAG1_IREG], DAG_M[DAG1_MREG], DAG_L[DAG1_IREG]);
			DAG2I_NEXT = Modulus(DAG_I[DAG2_IREG], DAG_M[DAG2_MREG], DAG_L[DAG2_IREG]);
			if (COND && EN && CE) begin
				if ((DECI.MOVI || DECI.DMRI) && (DECI.DRGP == 2'b01 || DECI.DRGP == 2'b10)) begin
					casex (DECI.DREG)
						4'b00xx: DAG_I[{DECI.DRGP[1],DECI.DREG[1:0]}] <= DMD[13:0];
						4'b01xx: DAG_M[{DECI.DRGP[1],DECI.DREG[1:0]}] <= DMD[13:0];
						4'b10xx: DAG_L[{DECI.DRGP[1],DECI.DREG[1:0]}] <= DMD[13:0];
					endcase
				end
				if (DECI.LDRI && (DECI.DRGP == 2'b01 || DECI.DRGP == 2'b10)) begin
					casex (DECI.DREG)
						4'b00xx: DAG_I[{DECI.DRGP[1],DECI.DREG[1:0]}] <= IR[17:4];
						4'b01xx: DAG_M[{DECI.DRGP[1],DECI.DREG[1:0]}] <= IR[17:4];
						4'b10xx: DAG_L[{DECI.DRGP[1],DECI.DREG[1:0]}] <= IR[17:4];
					endcase
				end
				
				if (DECI.DAG1U) DAG_I[DAG1_IREG] <= DAG1I_NEXT;
				if (DECI.DAG2U) DAG_I[DAG2_IREG] <= DAG2I_NEXT;
			end
			if ((ATX0REQ || ATX1REQ) && CE) begin
				if (DAG1_UPDATE) DAG_I[DAG1_IREG] <= DAG1I_NEXT;
				if (DAG2_UPDATE) DAG_I[DAG2_IREG] <= DAG2I_NEXT;
			end
		end
	end
	assign DAG1_ADDR = !MSTAT[MSTAT_BIT_REV] ? DAG_I[DAG1_IREG] : AddrReverse(DAG_I[DAG1_IREG]);
	assign DAG2_ADDR =                         DAG_I[DAG2_IREG];
	
	//PX
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			// synopsys translate_off
			PX <= '0;
			// synopsys translate_on
		end else if (!RES_N) begin
			PX <= '0;
		end else begin
			if (COND && EN && CE) begin
				if ((DECI.MOVI || DECI.DMRI) && DECI.DRGP == 2'b11) begin
					casex (DECI.DREG)
						4'b0111: PX <= DMD[7:0];
					endcase
				end
				if (DECI.LDRI && DECI.DRGP == 2'b11) begin
					casex (DECI.DREG)
						4'b0111: PX <= IR[11:4];
					endcase
				end
				
				if (DECI.IPMRI) begin
					PX <= PMDI[7:0];
				end
			end
		end
	end
	
	//Flag out
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			// synopsys translate_off
			FO <= 0;
			FL <= '1;
			// synopsys translate_on
		end else if (!RES_N) begin
			FO <= 0;
			FL <= '1;
		end else begin
			if (COND && EN && CE) begin
				if (DECI.MFO) begin
					case (IR[5:4])
						2'b00:;
						2'b01: FO <= ~FO;
						2'b10: FO <= 0;
						2'b11: FO <= 1;
					endcase
					case (IR[7:6])
						2'b00:;
						2'b01: FL[0] <= ~FL[0];
						2'b10: FL[0] <= 0;
						2'b11: FL[0] <= 1;
					endcase
					case (IR[9:8])
						2'b00:;
						2'b01: FL[1] <= ~FL[1];
						2'b10: FL[1] <= 0;
						2'b11: FL[1] <= 1;
					endcase
					case (IR[11:10])
						2'b00:;
						2'b01: FL[2] <= ~FL[2];
						2'b10: FL[2] <= 0;
						2'b11: FL[2] <= 1;
					endcase
				end
			end
		end
	end
	
	//Memory interface
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			PMOVLAY <= '0;
			DMOVLAY <= '0;
		end else if (!RES_N) begin
			PMOVLAY <= '0;
			DMOVLAY <= '0;
		end else begin
			if (COND && EN && CE) begin
				if ((DECI.MOVI || DECI.DMRI) && DECI.DRGP == 2'b01) begin
					casex (DECI.DREG)
						4'b1110: PMOVLAY <= DMD[3:0];
						4'b1111: DMOVLAY <= DMD[3:0];
					endcase
				end
				if (DECI.LDRI && DECI.DRGP == 2'b01) begin
					casex (DECI.DREG)
						4'b1110: PMOVLAY <= IR[7:4];
						4'b1111: DMOVLAY <= IR[7:4];
					endcase
				end
			end
		end
	end
	
	bit  [15: 0] REG_Q;
	always_comb begin
		bit  [15: 0] RGP_DATA[4];
		
		case (DECI.SREG)
			4'b0000: begin RGP_DATA[0] = AX0[RB]; RGP_DATA[1] = DAG_I[0];          RGP_DATA[2] = DAG_I[4]; RGP_DATA[3] = ASTAT; end
			4'b0001: begin RGP_DATA[0] = AX1[RB]; RGP_DATA[1] = DAG_I[1];          RGP_DATA[2] = DAG_I[5]; RGP_DATA[3] = MSTAT; end
			4'b0010: begin RGP_DATA[0] = MX0[RB]; RGP_DATA[1] = DAG_I[2];          RGP_DATA[2] = DAG_I[6]; RGP_DATA[3] = SSTAT; end
			4'b0011: begin RGP_DATA[0] = MX1[RB]; RGP_DATA[1] = DAG_I[3];          RGP_DATA[2] = DAG_I[7]; RGP_DATA[3] = IMASK; end
			4'b0100: begin RGP_DATA[0] = AY0[RB]; RGP_DATA[1] = DAG_M[0];          RGP_DATA[2] = DAG_M[4]; RGP_DATA[3] = ICNTL; end
			4'b0101: begin RGP_DATA[0] = AY1[RB]; RGP_DATA[1] = DAG_M[1];          RGP_DATA[2] = DAG_M[5]; RGP_DATA[3] = CNTR; end
			4'b0110: begin RGP_DATA[0] = MY0[RB]; RGP_DATA[1] = DAG_M[2];          RGP_DATA[2] = DAG_M[6]; RGP_DATA[3] = SB[RB]; end
			4'b0111: begin RGP_DATA[0] = MY1[RB]; RGP_DATA[1] = DAG_M[3];          RGP_DATA[2] = DAG_M[7]; RGP_DATA[3] = {8'h00,PX}; end
			4'b1000: begin RGP_DATA[0] = SI[RB];  RGP_DATA[1] = DAG_L[0];          RGP_DATA[2] = DAG_L[4]; RGP_DATA[3] = RX0I; end
			4'b1001: begin RGP_DATA[0] = SE[RB];  RGP_DATA[1] = DAG_L[1];          RGP_DATA[2] = DAG_L[5]; RGP_DATA[3] = TX0I; end
			4'b1010: begin RGP_DATA[0] = AR[RB];  RGP_DATA[1] = DAG_L[2];          RGP_DATA[2] = DAG_L[6]; RGP_DATA[3] = RX1I; end
			4'b1011: begin RGP_DATA[0] = MR0[RB]; RGP_DATA[1] = DAG_L[3];          RGP_DATA[2] = DAG_L[7]; RGP_DATA[3] = TX1I; end
			4'b1100: begin RGP_DATA[0] = MR1[RB]; RGP_DATA[1] = '0;                RGP_DATA[2] = '0;       RGP_DATA[3] = '0; end
			4'b1101: begin RGP_DATA[0] = MR2[RB]; RGP_DATA[1] = '0;                RGP_DATA[2] = '0;       RGP_DATA[3] = '0; end
			4'b1110: begin RGP_DATA[0] = SR0[RB]; RGP_DATA[1] = {12'h000,PMOVLAY}; RGP_DATA[2] = '0;       RGP_DATA[3] = '0; end
			4'b1111: begin RGP_DATA[0] = SR1[RB]; RGP_DATA[1] = {12'h000,DMOVLAY}; RGP_DATA[2] = '0;       RGP_DATA[3] = {2'b00,PCSTACK_Q2}; end
		endcase
		REG_Q = RGP_DATA[DECI.SRGP];
	end
	assign DMD = DECI.DMRI || DECI.IDMRI ? DMDI : 
	             DECI.IORI               ? DMDI :
		          DECI.IPMRI              ? PMDI[23:8] : 
				    DECI.IMMDMWI            ? IR[19:4] : 
				                              REG_Q;
	
	assign DMA = ATX0REQ                ? (!ATX0I[2] ? DAG1_ADDR : DAG2_ADDR) :
	             ATX1REQ                ? (!ATX1I[2] ? DAG1_ADDR : DAG2_ADDR) :
					 DECI.DMRI || DECI.DMWI ? IR[17:4] : 
	             DECI.IORI || DECI.IOWI ? {3'b000,IR[14:4]} :
					                          DECI.DAG1U ? DAG1_ADDR : DAG2_ADDR;
	assign DMDO = DECI.IMMDMWI ? IR[19:4] : 
			        REG_Q;
	assign DMWR = DECI.DMWI | DECI.IDMWI | DECI.IMMDMWI;
	assign DMRD = DECI.DMRI | DECI.IDMRI;
	
	
	assign RTXO = DECI.LDRI ? IR[19:4] : DMD;
	assign RX0WE = (DECI.DRGP == 2'b11 && DECI.DREG == 4'h8);
	assign TX0WE = (DECI.DRGP == 2'b11 && DECI.DREG == 4'h9);
	assign RX1WE = (DECI.DRGP == 2'b11 && DECI.DREG == 4'hA);
	assign TX1WE = (DECI.DRGP == 2'b11 && DECI.DREG == 4'hB);
	
	assign IOWR = DECI.IOWI;
	assign IORD = DECI.IORI;
	
	
endmodule

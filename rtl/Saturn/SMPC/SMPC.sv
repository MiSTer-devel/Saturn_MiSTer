// synopsys translate_off
`define SIM
// synopsys translate_on

module SMPC 
#(parameter rom_file = "smpc.mif")
(
	input              CLK,
	input              RST_N,
	input              EN,
	
	input              CE,
	input              CE32K,
	input              RESET_N,
	
	input      [ 6: 1] A,
	input      [ 7: 0] DBI,
	output reg [ 7: 0] DBO,
	input              CS_N,
	input              RW_N,
	
	output             D0,
	input              D1,
	input              D2,
	input              D3,
	output             D4,
	output             D5,
	output             D6,
	output             D7,
	output             D8,
	output             D9,
	output             D10,
	input              D13_INT0,
	
	input              R01_INT2,
	
	output     [ 6: 0] PIOA_O,
	input      [ 6: 0] PIOA_I,
	output     [ 6: 0] PIOA_D,
	
	output     [ 6: 0] PIOB_O,
	input      [ 6: 0] PIOB_I,
	output     [ 6: 0] PIOB_D,
	
	input      [ 3: 0] R5,
	
	output             R60_D,
	output             R60_O,
	input              R60_I,
	
	output             R61_D,
	output             R61_O,
	input              R61_I,
	
	input              R62_I,
	input              R63_I,
	
	input              R70_I,
	input              R71_I,
	output             R72_O,
	output             R73_O,
	
	output             EXL_N,
	
	input      [64: 0] EXT_RTC,
	
	input      [ 7: 0] DBG_EXT
	
`ifdef DEBUG
	                   ,
	output reg [ 7: 0] DBG_IREG[7],
	output reg [ 7: 0] DBG_COMREG,
	output reg         DBG_OPTIM_ALLOW,DBG_INTBACK_ABORT,
	output reg [15: 0] DBG_CMD_TIME,DBG_CMD_WAIT
`endif
);

	import SMPC_PKG::*;
	
	//Mapped registers
	INTC0_t      INTC0;
	INTC1_t      INTC1;
	INTC2_t      INTC2;
	INTC3_t      INTC3;
//	PMRA_t       PMRA;
	PMRB_t       PMRB;
	PMRC_t       PMRC;
	TMA_t        TMA;
	TMC1_t       TMC1;
	TWCx_t       TWCL,TWCU;
	TRCx_t       TRCL,TRCU;
	bit  [ 3: 0] RF0;
	bit  [ 3: 0] RF1;
	RF2_t        RF2;
	bit  [ 3: 0] RF3;
	ESR1_t       ESR1;
	DCDx_t       DCD0;
	DCDx_t       DCD1;
	DCDx_t       DCD2;
	DCDx_t       DCD3;
	DCRx_t       DCR0;
	DCRx_t       DCR1;
	DCRx_t       DCR2;
	DCRx_t       DCR3;
	DCRx_t       DCR4;
	DCRx_t       DCR5;
	DCRx_t       DCR6;
	DCRx_t       DCR7;
	
	bit  [ 7: 0] TCA,TCC;
	bit          TA_OVF,TC_OVF;
	bit          TC_UPD;
	
	//Port registers
	bit  [15: 0] D_O;
	bit  [15: 0] D_I;
	bit  [15: 0] D_D;
	bit  [ 3: 0] R0_O,R1_O,R2_O,R3_O,R4_O,R5_O,R6_O,R7_O;
	bit  [ 3: 0] R0_I,R1_I,R2_I,R3_I,R4_I,R5_I,R6_I,R7_I;
	
	//SMPC interface registers
	bit  [ 7: 0] SR;
	bit          SF;
	bit  [ 6: 0] PDR1_O,PDR2_O;
	bit  [ 6: 0] DDR1,DDR2;
	bit          IOSEL1,IOSEL2;
	bit          EXLE1,EXLE2;
	bit          COMREG_INT;
//	bit          VB_INT;
	
	//HMCS400 CPU
	bit          SBY,STOP;
	bit          INT_PEND;
	bit  [ 2: 0] INT_VEC;
	bit          INT_ACP,INT_RET;
	
	bit  [13: 0] ROM_A;
	bit  [ 9: 0] ROM_DI;
	
	bit  [ 9: 0] BUS_A;
	bit  [ 3: 0] BUS_DI;
	bit  [ 3: 0] BUS_DO;
	bit          BUS_WE,BUS_RE;
	bit          IO_WR,IO_RD;
	bit          IO_P;
	
	bit          SBY_REQ,STOP_REQ;
	
	bit  [ 3: 0] CYC;
	always @(posedge CLK or negedge RST_N) begin		
		if (!RST_N) begin
			CYC <= 4'h1;
		end
		else if (!RESET_N) begin
			CYC <= 4'h1;
		end
		else if (EN && CE) begin
			if (STOP) CYC <= 4'h0;
			else CYC <= {CYC[2:0],CYC[3]};
		end
	end
	wire EXEC = EN & ~SBY & ~STOP;
	
	
	always_comb begin		
		bit         INT0_PEND,INT1_PEND,INT2_PEND,INT3_PEND,TAI_PEND,TBI_PEND,TCI_PEND;
		
		INT0_PEND = INTC0.IF0 & ~INTC0.IM0;
		INT1_PEND = INTC1.IF1 & ~INTC1.IM1;
		INT2_PEND = RF2.IF2   & ~RF2.IM2;
		INT3_PEND = RF2.IF3   & ~RF2.IM3;
		TAI_PEND  = INTC1.IFTA & ~INTC1.IMTA;
		TBI_PEND  = INTC2.IFTB & ~INTC2.IMTB;
		TCI_PEND  = INTC2.IFTC & ~INTC2.IMTC;
		
		INT_PEND = (INT0_PEND | INT1_PEND | INT2_PEND | INT2_PEND | TAI_PEND | TBI_PEND | TCI_PEND);
		
		if      (INT0_PEND)             INT_VEC = 3'h1;
		else if (INT1_PEND)             INT_VEC = 3'h2;
		else if (TAI_PEND)              INT_VEC = 3'h3;
		else if (TBI_PEND || INT2_PEND) INT_VEC = 3'h4;
		else if (TCI_PEND || INT3_PEND) INT_VEC = 3'h5;
		else                            INT_VEC = '0;
	end
	
	HMCS400_CORE CORE
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE(CE),
		
		.RESET(~RESET_N),
		.CYC(CYC),
		.EXEC(EXEC),
		
		.INT_PEND(INTC0.IE & INT_PEND),
		.INT_VEC(INT_VEC),
		.INT_ACP(INT_ACP),
		.INT_RET(INT_RET),
		
		.ROM_A(ROM_A),
		.ROM_DI(ROM_DI),
		
		.BUS_A(BUS_A),
		.BUS_DI(BUS_DI),
		.BUS_DO(BUS_DO),
		.BUS_WE(BUS_WE),
		.BUS_RE(BUS_RE),
		
		.IO_WR(IO_WR),
		.IO_RD(IO_RD),
		.IO_P(IO_P),
		
		.STOP_REQ(STOP_REQ),
		.SBY_REQ(SBY_REQ)
	);
	
	bit  [ 9: 0] ROM_Q;
	HMCS400_ROM #(rom_file) ROM(CLK, ROM_A[10:0], ROM_Q);
	assign ROM_DI = ROM_A >= 14'h0681 && ROM_A <= 14'h068E ? {ROM_Q[9:4],RTC_INIT[ROM_A[3:0]]} : //replace init rtc data by extern data
	                ROM_A >= 14'h0FF0 && ROM_A <= 14'h0FFF ? {2'b01,IREG_Q} : ROM_Q;
	
	wire         MR_SEL = (BUS_A >= 10'h040 && BUS_A <= 10'h04F);
	wire         MR_WE = MR_SEL && BUS_WE & EXEC;
	bit  [ 3: 0] MR_Q;
	HMCS400_MR MR(CLK, BUS_A[3:0], BUS_DO, MR_WE & CYC[3] & CE, MR_Q);
	wire ERAM_SEL = (BUS_A >= 10'h260 && BUS_A <= 10'h26F);
	
	//8 nible for app variable + 4byte SMEM
	bit  [ 3: 0] ERAM_Q;
	SMPC_ERAM ERAM(CLK, BUS_A[3:0], BUS_DO, (ERAM_SEL & BUS_WE & EXEC & CYC[3] & CE), ERAM_Q);
	
	always @(posedge CLK or negedge RST_N) begin				
		if (!RST_N) begin
			{SBY,STOP} <= '0;
		end
		else if (!RESET_N) begin
			{SBY,STOP} <= '0;
		end
		else if (EN && CE) begin
			if (EXEC) begin
				if (CYC[3]) begin
					if (SBY_REQ && !SBY) SBY <= 1;
					if (STOP_REQ && !STOP) STOP <= 1;
				end
			end
			else begin
				if (CYC[3]) begin
					if (INT_PEND && SBY) SBY <= 0;
				end
			end
		end
	end
	
	
	//Mapped registers
	wire MREG_SEL = (BUS_A <= 10'h03F);
	always @(posedge CLK or negedge RST_N) begin			
		bit          INT0_N,INT1_N,INT2,INT3;
		bit          INT0_OLD,INT1_OLD,INT2_OLD,INT3_OLD;
		
		if (!RST_N) begin
			INTC0 <= INTC0_INIT;
			INTC1 <= INTC1_INIT;
			INTC2 <= INTC2_INIT;
			INTC3 <= INTC3_INIT;
//			PMRA <= PMRA_INIT;
			PMRB <= PMRB_INIT;
			PMRC <= PMRC_INIT;
			TMA <= TMA_INIT;
			TMC1 <= TMC1_INIT;
			TWCU <= TWCx_INIT;
			TWCL <= TWCx_INIT;
			TRCU <= TRCx_INIT;
			TRCL <= TRCx_INIT;
			RF0 <= '0;
			RF1 <= '0;
			RF2 <= RF2_INIT;
			RF3 <= '0;
			DCD0 <= '0;
			DCD1 <= '0;
			DCD2 <= '0;
			DCD3 <= '0;
			TC_UPD <= 0;
		end
		else if (!RESET_N) begin
			INTC0 <= INTC0_INIT;
			INTC1 <= INTC1_INIT;
			INTC2 <= INTC2_INIT;
			INTC3 <= INTC3_INIT;
//			PMRA <= PMRA_INIT;
			PMRB <= PMRB_INIT;
			PMRC <= PMRC_INIT;
			TMA <= TMA_INIT;
			TMC1 <= TMC1_INIT;
			TWCU <= TWCx_INIT;
			TWCL <= TWCx_INIT;
			TRCU <= TRCx_INIT;
			TRCL <= TRCx_INIT;
			RF0 <= '0;
			RF1 <= '0;
			RF2 <= RF2_INIT;
			RF3 <= '0;
			DCD0 <= '0;
			DCD1 <= '0;
			DCD2 <= '0;
			DCD3 <= '0;
		end
		else if (EN && CE) begin
			INT0_N = PMRC.INT0 ? D_I[13] : 1'b1;
			INT1_N = PMRB.INT1 ? R0_I[0] : 1'b1;
			INT2 = PMRB.INT2 ? R0_I[1] : 1'b0;
			INT3 = PMRB.INT3 ? R0_I[2] : 1'b0;
			
			if (CYC[0]) begin
				if (TA_OVF) INTC1.IFTA <= 1;
				if (TC_OVF) INTC2.IFTC <= 1;
			end
			
			if (CYC[1]) begin
				{INT0_OLD,INT1_OLD,INT2_OLD,INT3_OLD} <= {INT0_N,INT1_N,INT2,INT3};
				
				if (INT0_OLD && !INT0_N) INTC0.IF0 <= 1;
				if (INT1_OLD && !INT1_N) INTC1.IF1 <= 1;
				case (ESR1.INT2E)
					2'b00: ;
					2'b01: if (INT2_OLD && !INT2) RF2.IF2 <= 1;
					2'b10: if (!INT2_OLD && INT2) RF2.IF2 <= 1;
					2'b11: if ((INT2_OLD && !INT2) || (!INT2_OLD && INT2)) RF2.IF2 <= 1;
				endcase
				case (ESR1.INT3E)
					2'b00: ;
					2'b01: if (INT3_OLD && !INT3) RF2.IF3 <= 1;
					2'b10: if (!INT3_OLD && INT3) RF2.IF3 <= 1;
					2'b11: if ((INT3_OLD && !INT3) | (!INT3_OLD && INT3)) RF2.IF3 <= 1;
				endcase
			end
			
			if (CYC[2]) begin
				if (MREG_SEL && BUS_RE) begin
					case (BUS_A[5:0])
					 6'h0F: {TRCU,TRCL} <= TCC;
					endcase
				end
			end
			
			TC_UPD <= 0;
			if (CYC[3]) begin
				if (MREG_SEL && BUS_WE) begin
					case (BUS_A[5:0])
						6'h00: INTC0 <= BUS_DO;
						6'h01: INTC1 <= BUS_DO;
						6'h02: INTC2 <= BUS_DO;
						6'h03: INTC3 <= BUS_DO;
//						6'h04: PMRA <= BUS_DO;
						6'h08: TMA <= BUS_DO;
						6'h0D: TMC1 <= BUS_DO;
						6'h0E: TWCL <= BUS_DO;
						6'h0F: TWCU <= BUS_DO;
						6'h20: RF0 <= BUS_DO;
						6'h21: RF1 <= BUS_DO;
						6'h22: RF2 <= BUS_DO;
						6'h23: RF3 <= BUS_DO;
						6'h24: PMRB <= BUS_DO;
						6'h25: PMRC <= BUS_DO;
						6'h26: ESR1 <= BUS_DO;
						6'h2C: DCD0 <= BUS_DO;
						6'h2D: DCD1 <= BUS_DO;
						6'h2E: DCD2 <= BUS_DO;
						6'h2F: DCD3 <= BUS_DO;
						6'h30: DCR0 <= BUS_DO;
						6'h31: DCR1 <= BUS_DO;
						6'h32: DCR2 <= BUS_DO;
						6'h33: DCR3 <= BUS_DO;
						6'h34: DCR4 <= BUS_DO;
						6'h35: DCR5 <= BUS_DO;
						6'h36: DCR6 <= BUS_DO;
						6'h37: DCR7 <= BUS_DO;
					endcase
					TC_UPD <= (BUS_A[5:0] == 6'h0F);
				end
				if (INT_ACP) begin
					INTC0.IE <= 0;
				end
				if (INT_RET) begin
					INTC0.IE <= 1;
				end
			end
			
			
		end
	end
	
	bit  [ 3: 0] REG_DO;
	always_comb begin	
		case (BUS_A[5:0])
			6'h00: REG_DO <= INTC0;
			6'h01: REG_DO <= INTC1;
			6'h02: REG_DO <= INTC2;
			6'h03: REG_DO <= INTC3;
			6'h0E: REG_DO <= TRCL;
			6'h0F: REG_DO <= TRCU;
			6'h20: REG_DO <= RF0;
			6'h21: REG_DO <= RF1;
			6'h22: REG_DO <= RF2;
			6'h23: REG_DO <= RF3;
			6'h26: REG_DO <= ESR1;
			default: REG_DO <= '0;
		endcase
	end
	
	//Port
	assign D_D = {DCD3,DCD2,DCD1,DCD0};
	assign D_I = {2'b11,D13_INT0,9'b111111111,D3,D2,D1,1'b1};
	
	assign R0_I = {2'b11,R01_INT2,~COMREG_INT};//check R02/INT3
	assign R1_I = PIOA_I[3:0];
	assign R2_I = {PIOA_I[6:4],1'b0};
	assign R3_I = PIOB_I[3:0];
	assign R4_I = {PIOB_I[6:4],1'b0};
	assign R5_I = R5;
	assign R6_I = {R63_I,R62_I,R61_I,R60_I};
	assign R7_I = {2'b00,R71_I,R70_I};
	
	always @(posedge CLK or negedge RST_N) begin				
		if (!RST_N) begin
			D_O <= '0;
			{R0_O,R1_O,R2_O,R3_O,R4_O,R5_O,R6_O,R7_O} <= '0;
		end
		else if (!RESET_N) begin
			
		end
		else if (EN && CE) begin
			if (CYC[3]) begin
				if (IO_WR && !IO_P) begin
					D_O[BUS_A[3:0]] <= BUS_DO[0];
				end
				
				if (IO_WR && IO_P) begin
					case (BUS_A[3:0])
						4'h0: R0_O <= BUS_DO;
						4'h1: R1_O <= BUS_DO;
						4'h2: R2_O <= BUS_DO;
						4'h3: R3_O <= BUS_DO;
						4'h4: R4_O <= BUS_DO;
						4'h5: R5_O <= BUS_DO;
						4'h6: R6_O <= BUS_DO;
						4'h7: R7_O <= BUS_DO & 4'h7;//possibly a bug: bit 3 is set by command NETLINKON (0x0A), but intback status OREG11 bit7 ("System Status 2") reads as 0
					endcase
				end
			end
		end
	end
	
	bit  [ 3: 0] IO_DO;
	always_comb begin	
		bit [ 3: 0] N;
	
		N = BUS_A[3:0];
		if (!IO_P) 
			IO_DO <= {4{ (D_I[N]&~D_D[N]) | (D_O[N]&D_D[N]) }};
		else
			case (N)
				4'h0: IO_DO <= (R0_I&~DCR0)|(R0_O&DCR0);
				4'h1: IO_DO <= (R1_I&~DCR1)|(R1_O&DCR1);
				4'h2: IO_DO <= (R2_I&~DCR2)|(R2_O&DCR2);
				4'h3: IO_DO <= (R3_I&~DCR3)|(R3_O&DCR3);
				4'h4: IO_DO <= (R4_I&~DCR4)|(R4_O&DCR4);
				4'h5: IO_DO <= (R5_I&~DCR5)|(R5_O&DCR5);
				4'h6: IO_DO <= (R6_I&~DCR6)|(R6_O&DCR6);
				4'h7: IO_DO <= (R7_I&~DCR7)|(R7_O&DCR7);
				default: IO_DO <= '1;
			endcase
	end
	
	assign {D10,D9,D8,D7,D6,D5,D4,D0} = {D_O[10:4],D_O[0]} | ~{D_D[10:4],D_D[0]};
	assign {R61_D,R60_D} = DCR6[1:0];
	assign {R61_O,R60_O} = R6_O[1:0] | ~DCR6[1:0];
	assign {R73_O,R72_O} = R7_O[3:2] | ~DCR7[3:2];
	
	assign PIOA_O = IOSEL1 ? PDR1_O : {R2_O[3:1],R1_O};
	assign PIOA_D = IOSEL1 ? DDR1   : {DCR2[3:1],DCR1};
	assign PIOB_O = IOSEL2 ? PDR2_O : {R4_O[3:1],R3_O};
	assign PIOB_D = IOSEL2 ? DDR2   : {DCR4[3:1],DCR3};
	assign EXL_N = (~EXLE1 | PIOA_I[6]) & (~EXLE2 | PIOB_I[6]);
	
	//Timers
	bit  [10: 0] PSS;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			PSS <= '0;
		end
		else if (!RESET_N) begin
			PSS <= '0;
		end
		else if (EN && CE) begin
			if (CYC[3]) begin
				PSS <= PSS + 11'd1;
			end
		end
	end
	
	bit  [ 7: 0] PSW;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			PSW <= '0;
		end
		else if (!RESET_N) begin
			PSW <= '0;
		end
		else if (EN && CE32K) begin
			PSW <= PSW + 8'd1;
			if (TMA[3:1] == 3'b111) PSW <= '0;
		end
	end
	
	bit          TA_CLK,TC_CLK;
	always_comb begin	
		if (!TMA[3]) 
			case (TMA[2:0])
				3'h0: TA_CLK <= &PSS[10:0] & CYC[3];
				3'h1: TA_CLK <= &PSS[9:0] & CYC[3];
				3'h2: TA_CLK <= &PSS[8:0] & CYC[3];
				3'h3: TA_CLK <= &PSS[6:0] & CYC[3];
				3'h4: TA_CLK <= &PSS[4:0] & CYC[3];
				3'h5: TA_CLK <= &PSS[2:0] & CYC[3];
				3'h6: TA_CLK <= &PSS[1:0] & CYC[3];
				3'h7: TA_CLK <= &PSS[0:0] & CYC[3];
			endcase
		else
			case (TMA[2:0])
				3'h0: TA_CLK <= &PSW[7:0] & CE32K;
				3'h1: TA_CLK <= &PSW[6:0] & CE32K;
				3'h2: TA_CLK <= &PSW[5:0] & CE32K;
				3'h3: TA_CLK <= &PSW[3:0] & CE32K;
				3'h4: TA_CLK <= &PSW[1:0] & CE32K;
				3'h5: TA_CLK <= 0;
				3'h6: TA_CLK <= 0;
				3'h7: TA_CLK <= 0;
			endcase
			
		case (TMC1[2:0])
			3'h0: TC_CLK <= &PSS[10:0] & CYC[3];
			3'h1: TC_CLK <= &PSS[9:0] & CYC[3];
			3'h2: TC_CLK <= &PSS[8:0] & CYC[3];
			3'h3: TC_CLK <= &PSS[6:0] & CYC[3];
			3'h4: TC_CLK <= &PSS[4:0] & CYC[3];
			3'h5: TC_CLK <= &PSS[2:0] & CYC[3];
			3'h6: TC_CLK <= &PSS[1:0] & CYC[3];
			3'h7: TC_CLK <= &PSS[0:0] & CYC[3];
		endcase
	end
	
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			{TCA,TCC} <= '0;
			{TA_OVF,TC_OVF} <= '0; 
		end
		else if (!RESET_N) begin
			{TCA,TCC} <= '0;
			{TA_OVF,TC_OVF} <= '0; 
		end
		else if (EN && CE) begin
			if (CYC[0]) begin
				TA_OVF <= 0; 
			end
			
			if (TA_CLK) begin
				TCA <= TCA + 8'd1;
				if (TCA == 8'hFF) TA_OVF <= 1; 
			end
			if (TMA[3:1] == 3'b111) TCA <= '0;
			
			if (TC_CLK) begin
				TCC <= TCC + 8'd1;
				if (TCC == 8'hFF) begin
					if (TMC1[3]) TCC <= {TWCU,TWCL};
					TC_OVF <= 1; 
				end
			end
			if (TC_UPD) begin
				TCC <= {TWCU,TWCL};
			end
		end
	end
	
	//SMPC registers
	wire SREG_SEL = (BUS_A >= 10'h360 && BUS_A <= 10'h36F);
	wire OREG_SEL = (BUS_A >= 10'h320 && BUS_A <= 10'h35F);
	
	wire IREG_SEL = ({A,1'b1} <= 7'h0D || {A,1'b1} == 7'h1F);
	bit  [ 7: 0] IREG_Q;
	SMPC_IREG IREG
	(
		.CLK(CLK),
		.WADDR(A[3:1]),
		.DATA(DBI),
		.WREN(IREG_SEL & ~RW_N & RW_N_OLD & ~CS_N & EN),
		.RADDR(ROM_A[2:0]),
		.Q(IREG_Q)
	);
	
	wire [ 1: 0] OREG_WE = {~BUS_A[0],BUS_A[0]};
	bit  [ 7: 0] OREG_Q;
	SMPC_OREG OREG
	(
		.CLK(CLK),
		.WADDR(BUS_A[5:1]),
		.DATA({2{BUS_DO}}),
		.WREN(OREG_WE & {2{OREG_SEL & BUS_WE & EXEC & CYC[3] & CE}}),
		.RADDR(A[5:1]),
		.Q(OREG_Q)
	);
	
	bit         RW_N_OLD;
	always @(posedge CLK or negedge RST_N) begin
		bit         CS_N_OLD,COMREG_PEND;
		bit [ 7: 0] IO_BUF;
		
		if (!RST_N) begin
			SF <= 0;
			{PDR1_O,PDR2_O} <= '0;
			{DDR1,DDR2} <= '0;
			{IOSEL2,IOSEL1} <= '0;
			{EXLE2,EXLE1} <= '0;
			{COMREG_PEND,COMREG_INT} <= '0;
`ifdef DEBUG
			DBG_IREG <= '{7{'0}};
			DBG_COMREG <= '0;
`endif
		end
		else if (!RESET_N) begin
			 
		end
		else if (EN) begin
			//Inner access
			if (CE) begin
				if (CYC[3]) begin
					if (SREG_SEL && BUS_WE) begin
						casex (BUS_A[3:0])
							4'b0000: SR[7:4] <= BUS_DO;
							4'b0001: SR[3:0] <= BUS_DO;
							4'b0010: SF <= 0;
						endcase
					end
					
					if (COMREG_PEND && !COMREG_INT) begin
						COMREG_INT <= 1;
						COMREG_PEND <= 0;
					end
					else if (INTC1.IF1 && COMREG_INT) begin//??
						COMREG_INT <= 0;
					end
					
//					VB_INT <= R01_INT2;
					
`ifdef DEBUG
					if (BUS_A >= 10'h040 && BUS_A <= 10'h04F && BUS_WE) begin
						casex (BUS_A[3:0])
							4'h9: {DBG_INTBACK_ABORT,DBG_OPTIM_ALLOW} <= BUS_DO[3:2];
						endcase
					end
					DBG_CMD_TIME <= DBG_CMD_TIME + 1'd1;
					if ((INT_ACP && INT_VEC == 3'h2) || !EXEC) DBG_CMD_TIME <= '0;
					
					DBG_CMD_WAIT <= DBG_CMD_WAIT + 1'd1;
					if (!COMREG_INT) DBG_CMD_WAIT <= '0;
`endif
				end
			end
			
			//Extern access
			RW_N_OLD <= RW_N;
			CS_N_OLD <= CS_N;
			if (!RW_N && RW_N_OLD && !CS_N) begin
				case ({A,1'b1})
					7'h1F: COMREG_PEND <= 1;
					7'h63: SF <= 1;
					7'h75: if (IOSEL1) PDR1_O <= DBI[6:0];
					7'h77: if (IOSEL2) PDR2_O <= DBI[6:0];
					7'h79: DDR1 <= DBI[6:0];
					7'h7B: DDR2 <= DBI[6:0];
					7'h7D: {IOSEL2,IOSEL1} <= DBI[1:0];
					7'h7F: {EXLE2,EXLE1} <= DBI[1:0];
					default:;
				endcase
				IO_BUF <= DBI;
			end 
			
			if (!CS_N && CS_N_OLD && RW_N) begin
				if ({A,1'b1} >= 7'h21 && {A,1'b1} <= 7'h5F) begin
					DBO <= OREG_Q;
				end else begin
					case ({A,1'b1})
						7'h61: DBO <= SR;
						7'h63: DBO <= {IO_BUF[7:1],SF};
						7'h75: DBO <= {IO_BUF[7],PIOA_I};
						7'h77: DBO <= {IO_BUF[7],PIOB_I};
						default: DBO <= IO_BUF;
					endcase
				end
			end
			
`ifdef DEBUG
			if (!RW_N && RW_N_OLD && !CS_N) begin
				case ({A,1'b1})
					7'h01: DBG_IREG[0] <= DBI;
					7'h03: DBG_IREG[1] <= DBI;
					7'h05: DBG_IREG[2] <= DBI;
					7'h07: DBG_IREG[3] <= DBI;
					7'h09: DBG_IREG[4] <= DBI;
					7'h0B: DBG_IREG[5] <= DBI;
					7'h0D: DBG_IREG[6] <= DBI;
					7'h1F: DBG_COMREG <= DBI;
					default:;
				endcase
			end 
`endif
		end
	end
	
	assign BUS_DI = IO_RD    ? IO_DO : 
	                MREG_SEL ? REG_DO : 
						 ERAM_SEL ? (BUS_A[3:0] != 4'h5 ? ERAM_Q : (ERAM_Q | 4'h8)) : //STE always set
						 MR_SEL   ? MR_Q :
						            '0;
	
	bit  [ 3: 0] RTC_INIT[16];
	always @(posedge CLK) begin
		bit         EXT_RTC64_OLD = 0;
		
		if (!RESET_N) begin
			{RTC_INIT[2],RTC_INIT[1]} <= 8'h59;
			{RTC_INIT[4],RTC_INIT[3]} <= 8'h59;
			{RTC_INIT[6],RTC_INIT[5]} <= 8'h23;
			{RTC_INIT[8],RTC_INIT[7]} <= 8'h31;
			RTC_INIT[9] <= 4'hC;
			RTC_INIT[10] <= 4'h5;
			{RTC_INIT[14],RTC_INIT[13],RTC_INIT[12],RTC_INIT[11]} <= 16'h1993;
		end
		else if (EN) begin
			if (EXT_RTC[64] != EXT_RTC64_OLD) begin
				EXT_RTC64_OLD <= EXT_RTC[64];
				{RTC_INIT[2],RTC_INIT[1]} <= EXT_RTC[7:0];
				{RTC_INIT[4],RTC_INIT[3]} <= EXT_RTC[15:8];
				{RTC_INIT[6],RTC_INIT[5]} <= EXT_RTC[23:16];
				{RTC_INIT[8],RTC_INIT[7]} <= EXT_RTC[31:24];
				RTC_INIT[9] <= EXT_RTC[35:32] + (EXT_RTC[36] == 0 ? 4'd0 : 4'd10);
				RTC_INIT[10] <= 4'd1;
				{RTC_INIT[14],RTC_INIT[13],RTC_INIT[12],RTC_INIT[11]} <= {8'h20,EXT_RTC[47:40]};
			end
		end
	end
	
endmodule

module SMPC_ERAM 
(
	input          CLK,
	input  [ 3: 0] ADDR,
	input  [ 3: 0] DATA,
	input          WREN,
	output [ 3: 0] Q
);

// synopsys translate_off
`define SIM
// synopsys translate_on
	
`ifdef SIM

	reg [3:0] MEM [2**4];
	initial begin
		MEM <= '{2**4{'0}};
	end
		
	always @(posedge CLK) begin
		if (WREN) MEM[ADDR] <= DATA;
	end
	
	assign Q = MEM[ADDR];

`else

	wire [3:0] sub_wire0;
		
	altdpram	altdpram_component (
				.data (DATA),
				.inclock (CLK),
				.outclock (CLK),
				.rdaddress (ADDR),
				.wraddress (ADDR),
				.wren (WREN),
				.q (sub_wire0),
				.aclr (1'b0),
				.byteena (1'b1),
				.inclocken (1'b1),
				.outclocken (1'b1),
				.rdaddressstall (1'b0),
				.rden (1'b1),
//				.sclr (1'b0),
				.wraddressstall (1'b0));
	defparam
		altdpram_component.indata_aclr = "OFF",
		altdpram_component.indata_reg = "INCLOCK",
		altdpram_component.intended_device_family = "Cyclone V",
		altdpram_component.lpm_type = "altdpram",
		altdpram_component.outdata_aclr = "OFF",
		altdpram_component.outdata_reg = "UNREGISTERED",
		altdpram_component.ram_block_type = "MLAB",
		altdpram_component.rdaddress_aclr = "OFF",
		altdpram_component.rdaddress_reg = "UNREGISTERED",
		altdpram_component.rdcontrol_aclr = "OFF",
		altdpram_component.rdcontrol_reg = "UNREGISTERED",
		altdpram_component.read_during_write_mode_mixed_ports = "CONSTRAINED_DONT_CARE",
		altdpram_component.width = 4,
		altdpram_component.widthad = 4,
		altdpram_component.width_byteena = 1,
		altdpram_component.wraddress_aclr = "OFF",
		altdpram_component.wraddress_reg = "INCLOCK",
		altdpram_component.wrcontrol_aclr = "OFF",
		altdpram_component.wrcontrol_reg = "INCLOCK";
		
	assign Q = sub_wire0;
	
`endif

endmodule 

module SMPC_IREG 
(
	input          CLK,
	input  [ 3: 1] WADDR,
	input  [ 7: 0] DATA,
	input          WREN,
	input  [ 3: 1] RADDR,
	output [ 7: 0] Q
);

// synopsys translate_off
`define SIM
// synopsys translate_on
	
`ifdef SIM

	reg [7:0] MEM [2**3];
	initial begin
		MEM <= '{2**3{'0}};
	end
		
	always @(posedge CLK) begin
		if (WREN) MEM[WADDR] <= DATA;
	end
	
	assign Q = MEM[RADDR];

`else

	wire [7:0] sub_wire0;
		
	altdpram	altdpram_component (
				.data (DATA),
				.inclock (CLK),
				.outclock (CLK),
				.rdaddress (RADDR),
				.wraddress (WADDR),
				.wren (WREN),
				.q (sub_wire0),
				.aclr (1'b0),
				.byteena (1'b1),
				.inclocken (1'b1),
				.outclocken (1'b1),
				.rdaddressstall (1'b0),
				.rden (1'b1),
//				.sclr (1'b0),
				.wraddressstall (1'b0));
	defparam
		altdpram_component.indata_aclr = "OFF",
		altdpram_component.indata_reg = "INCLOCK",
		altdpram_component.intended_device_family = "Cyclone V",
		altdpram_component.lpm_type = "altdpram",
		altdpram_component.outdata_aclr = "OFF",
		altdpram_component.outdata_reg = "UNREGISTERED",
		altdpram_component.ram_block_type = "MLAB",
		altdpram_component.rdaddress_aclr = "OFF",
		altdpram_component.rdaddress_reg = "UNREGISTERED",
		altdpram_component.rdcontrol_aclr = "OFF",
		altdpram_component.rdcontrol_reg = "UNREGISTERED",
		altdpram_component.read_during_write_mode_mixed_ports = "CONSTRAINED_DONT_CARE",
		altdpram_component.width = 8,
		altdpram_component.widthad = 3,
		altdpram_component.width_byteena = 1,
		altdpram_component.wraddress_aclr = "OFF",
		altdpram_component.wraddress_reg = "INCLOCK",
		altdpram_component.wrcontrol_aclr = "OFF",
		altdpram_component.wrcontrol_reg = "INCLOCK";
		
	assign Q = sub_wire0;
	
`endif

endmodule 

module SMPC_OREG (
	input          CLK,
	input  [ 5: 1] WADDR,
	input  [ 7: 0] DATA,
	input  [ 1: 0] WREN,
	input  [ 5: 1] RADDR,
	output [ 7: 0] Q
);

// synopsys translate_off
`define SIM
// synopsys translate_on
	
`ifdef SIM

	reg [7:0] MEM [2**5];
	initial begin
		MEM <= '{2**5{'0}};
	end
		
	always @(posedge CLK) begin
		if (WREN[1]) MEM[WADDR][ 7: 4] <= DATA[ 7: 4];
		if (WREN[0]) MEM[WADDR][ 3: 0] <= DATA[ 3: 0];
	end
	
	assign Q = MEM[RADDR];

`else

	wire [7:0] sub_wire0;
		
	altdpram	altdpram_component_2 (
				.data (DATA[7:4]),
				.inclock (CLK),
				.outclock (CLK),
				.rdaddress (RADDR),
				.wraddress (WADDR),
				.wren (WREN[1]),
				.q (sub_wire0[7:4]),
				.aclr (1'b0),
				.byteena (1'b1),
				.inclocken (1'b1),
				.outclocken (1'b1),
				.rdaddressstall (1'b0),
				.rden (1'b1),
//				.sclr (1'b0),
				.wraddressstall (1'b0));
	defparam
		altdpram_component_2.indata_aclr = "OFF",
		altdpram_component_2.indata_reg = "INCLOCK",
		altdpram_component_2.intended_device_family = "Cyclone V",
		altdpram_component_2.lpm_type = "altdpram",
		altdpram_component_2.outdata_aclr = "OFF",
		altdpram_component_2.outdata_reg = "UNREGISTERED",
		altdpram_component_2.ram_block_type = "MLAB",
		altdpram_component_2.rdaddress_aclr = "OFF",
		altdpram_component_2.rdaddress_reg = "UNREGISTERED",
		altdpram_component_2.rdcontrol_aclr = "OFF",
		altdpram_component_2.rdcontrol_reg = "UNREGISTERED",
		altdpram_component_2.read_during_write_mode_mixed_ports = "CONSTRAINED_DONT_CARE",
		altdpram_component_2.width = 4,
		altdpram_component_2.widthad = 5,
		altdpram_component_2.width_byteena = 1,
		altdpram_component_2.wraddress_aclr = "OFF",
		altdpram_component_2.wraddress_reg = "INCLOCK",
		altdpram_component_2.wrcontrol_aclr = "OFF",
		altdpram_component_2.wrcontrol_reg = "INCLOCK";
		
	altdpram	altdpram_component_3 (
				.data (DATA[3:0]),
				.inclock (CLK),
				.outclock (CLK),
				.rdaddress (RADDR),
				.wraddress (WADDR),
				.wren (WREN[0]),
				.q (sub_wire0[3:0]),
				.aclr (1'b0),
				.byteena (1'b1),
				.inclocken (1'b1),
				.outclocken (1'b1),
				.rdaddressstall (1'b0),
				.rden (1'b1),
//				.sclr (1'b0),
				.wraddressstall (1'b0));
	defparam
		altdpram_component_3.indata_aclr = "OFF",
		altdpram_component_3.indata_reg = "INCLOCK",
		altdpram_component_3.intended_device_family = "Cyclone V",
		altdpram_component_3.lpm_type = "altdpram",
		altdpram_component_3.outdata_aclr = "OFF",
		altdpram_component_3.outdata_reg = "UNREGISTERED",
		altdpram_component_3.ram_block_type = "MLAB",
		altdpram_component_3.rdaddress_aclr = "OFF",
		altdpram_component_3.rdaddress_reg = "UNREGISTERED",
		altdpram_component_3.rdcontrol_aclr = "OFF",
		altdpram_component_3.rdcontrol_reg = "UNREGISTERED",
		altdpram_component_3.read_during_write_mode_mixed_ports = "CONSTRAINED_DONT_CARE",
		altdpram_component_3.width = 4,
		altdpram_component_3.widthad = 5,
		altdpram_component_3.width_byteena = 1,
		altdpram_component_3.wraddress_aclr = "OFF",
		altdpram_component_3.wraddress_reg = "INCLOCK",
		altdpram_component_3.wrcontrol_aclr = "OFF",
		altdpram_component_3.wrcontrol_reg = "INCLOCK";
		
	assign Q = sub_wire0;
	
`endif

endmodule 
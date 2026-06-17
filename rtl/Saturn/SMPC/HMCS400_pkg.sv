package HMCS400_PKG; 

	typedef enum bit[2:0] {
		AAS_A   = 3'b000, 
		AAS_B   = 3'b001, 
		AAS_Y   = 3'b010, 
		AAS_M   = 3'b011,
		AAS_I   = 3'b100,
		AAS_ZERO = 3'b101,
		AAS_SPX = 3'b110,
		AAS_SPY = 3'b111
	} ALUASrc_t; 

	typedef enum bit[2:0] {
		ABS_A   = 3'b000, 
		ABS_B   = 3'b001, 
		ABS_M   = 3'b010,
		ABS_I   = 3'b011,
		ABS_ONE   = 3'b100,
		ABS_ZERO  = 3'b101,
		ABS_BIT = 3'b110
	} ALUBSrc_t; 
	
	typedef enum bit[2:0] {
		ALU_NOP = 3'b000, 
		ALU_ADD = 3'b001,
		ALU_BIT = 3'b010,
		ALU_LOG = 3'b011,
		ALU_A   = 3'b100, 
		ALU_B   = 3'b101
	} ALUType_t;
	
	typedef enum bit[2:0] {
		CAU_NOP  = 3'b000, 
		CAU_ALU  = 3'b001, 
		CAU_ONE  = 3'b010,
		CAU_ZERO = 3'b011,
		CAU_RTN  = 3'b100
	} CAUpdate_t;
	
	typedef enum bit[2:0] {
		STU_NOP  = 3'b000, 
		STU_NZ   = 3'b001, 
		STU_NB   = 3'b010,
		STU_C    = 3'b011,
		STU_CA   = 3'b100,
		STU_SET  = 3'b101,
		STU_RTN  = 3'b110,
		STU_PD   = 3'b111
	} STUpdate_t;
	
	typedef enum bit[1:0] {
		MA_ADR  = 2'b00, 
		MA_MR   = 2'b01, 
		MA_STK1 = 2'b10,
		MA_STK2 = 2'b11
	} MemAddr_t;
	
	typedef enum bit[1:0] {
		MD_A   = 2'b00, 
		MD_B   = 2'b01,
		MD_I   = 2'b10, 
		MD_ALU = 2'b11
	} MemData_t;
	
	typedef enum bit[2:0] {
		PCU_INC = 3'b000, 
		PCU_BR  = 3'b001, 
		PCU_BRL = 3'b010,
		PCU_ZP  = 3'b011,
		PCU_TBR = 3'b100,
		PCU_NU  = 3'b101,
		PCU_RTN = 3'b110,
		PCU_INT = 3'b111
	} PCUpdate_t;
	
	typedef struct packed
	{
		ALUASrc_t   ALUAS; 	//ALU A source
		ALUBSrc_t   ALUBS; 	//ALU B source
		ALUType_t   ALUOP;	//ALU operation
		bit [ 2: 0] ALUCD;	//ALU code
		bit         AW;		//Register A write 
		bit         BW;		//Register B write 
		bit         XW;		//Register X write 
		bit         YW;		//Register Y write 
		bit         XE;		//Register X exchange 
		bit         YE;		//Register Y exchange 
		bit         WW;		//Register W write 
		CAUpdate_t  CAU;		//CA update 
		STUpdate_t  STU;		//STATUS update 
		MemAddr_t   MA;		//Memory address select 
		MemData_t   MD;		//Memory data select 
		bit         MR;		//Memory read 
		bit         MW;		//Memory write 
		PCUpdate_t  PCU;		//PC update
		bit         SPI;		//Stack pointer increment 
		bit         SPD;		//Stack pointer decrement 
		bit         PI;		//Pattern read instruction 
		bit         SBY;		//Stand-by instruction
		bit         STOP;		//Stop instruction
		bit         IWR;		//Instruction word read 
		bit         IOW;		//IO write 
		bit         IOR;		//IO read 
		bit         IOP;		//IO port select (0-D,1-Rn) 
		bit         LST;		//Last state		
		bit         ILI;		//Illegal instruction 
	} DecInstr_t;
	
	function DecInstr_t IDecode(input bit [9:0] IC, input bit [1:0] STATE, input bit INT, input bit ST, input bit DA_COND);
		DecInstr_t DECI;
		
		DECI = '0;;
		DECI.LST = 1;
		if (INT) begin
			case (STATE)
				2'b00: begin
					DECI.STU = STU_SET;
					DECI.PCU = PCU_NU;
					DECI.LST = 0;
				end
				2'b01: begin
					DECI.MA = MA_STK1;
					DECI.MW = 1;
					DECI.PCU = PCU_INT;
					DECI.SPD = 1;
					DECI.LST = 1;
				end
				default:;
			endcase
		end
		else
		casex ({IC,STATE})
			12'b00_0000_00xx_00: begin	//NOP/XSPX/XSPY/XSPXY
				{DECI.YW,DECI.XW} = IC[1:0];
				{DECI.YE,DECI.XE} = IC[1:0];
			end
			
			12'b00_0001_0000_00,			//RTN 
			12'b00_0001_0001_00: begin	//RTNI 
				DECI.PCU = PCU_NU;
				DECI.SPI = 1;
				DECI.LST = 0;
			end
			12'b00_0001_0000_01,			//RTN
			12'b00_0001_0001_01: begin	//RTNI 
				DECI.MA = MA_STK1;
				DECI.MR = 1;
				DECI.CAU = IC[0] ? CAU_RTN : CAU_NOP;
				DECI.STU = IC[0] ? STU_RTN : STU_NOP;
				DECI.PCU = PCU_RTN;
				DECI.LST = 0;
			end
			12'b00_0001_0000_10,			//RTN
			12'b00_0001_0001_10: begin	//RTNI 
				DECI.PCU = PCU_NU;
				DECI.LST = 1;
			end
			
			12'b00_0000_0100_00,			//ANEM
			12'b00_0001_0100_00,			//ALEM
			12'b00_0100_0100_00,			//BNEM
			12'b00_1100_0100_00,			//BLEM
			12'b01_0000_0100_01,			//ANEMD d
			12'b01_0001_0100_01: begin	//ALEMD d
				DECI.ALUAS = !IC[6] ? AAS_A : AAS_B;
				DECI.ALUBS = ABS_M;
				DECI.ALUOP = ALU_ADD;
				DECI.ALUCD = 3'b001;
				DECI.STU = IC[4] || IC[7] ? STU_NB : STU_NZ;
				DECI.MA = MA_ADR;
				DECI.MR = 1;
			end
			
			12'b00_0000_1000_00,			//AM (M+A->A)
			12'b00_0001_1000_00,			//AMC (M+A+CA->A)
			12'b00_1001_1000_00,			//SMC (M-A-~CA->A)
			12'b01_0000_1000_01,			//AMD d (M(d)+A->A)
			12'b01_0001_1000_01,			//AMCD d (M(d)+A+CA->A)
			12'b01_1001_1000_01: begin	//SMCD d (M-A-~CA->A)
				DECI.ALUAS = AAS_M;
				DECI.ALUBS = ABS_A;
				DECI.ALUOP = ALU_ADD;
				DECI.ALUCD = {1'b0,IC[4],IC[7]};
				DECI.AW = 1;
				DECI.CAU = !IC[4] ? CAU_NOP : CAU_ALU;
				DECI.STU = STU_C;
				DECI.MA = MA_ADR;
				DECI.MR = 1;
			end
			
			12'b00_0000_1100_00,			//ORM
			12'b00_0001_1100_00,			//EORM
			12'b00_1001_1100_00,			//ANM
			12'b01_0000_1100_01,			//ORMD d
			12'b01_0001_1100_01,			//EORMD d
			12'b01_1001_1100_01: begin	//ANMD d
				DECI.ALUAS = AAS_A;
				DECI.ALUBS = ABS_M;
				DECI.ALUOP = ALU_LOG;
				DECI.ALUCD = {1'b0,IC[7],IC[4]};
				DECI.AW = 1;
				DECI.STU = STU_NZ;
				DECI.MA = MA_ADR;
				DECI.MR = 1;
			end
			
			12'b00_0010_xxxx_00,			//INEM i
			12'b00_0011_xxxx_00,			//ILEM i
			12'b01_0010_xxxx_01,			//INEMD i,d
			12'b01_0011_xxxx_01: begin	//ILEMD i,d
				DECI.ALUAS = AAS_I;
				DECI.ALUBS = ABS_M;
				DECI.ALUOP = ALU_ADD;
				DECI.ALUCD = 3'b001;
				DECI.STU = !IC[4] ? STU_NZ : STU_NB;
				DECI.MA = MA_ADR;
				DECI.MR = 1;
			end
			
			12'b00_0100_00xx_00,			//LBM(XY) (M->B)
			12'b00_1001_00xx_00,			//LAM(XY) (M->A)
			12'b01_1001_0000_01: begin	//LAMD d (M->A)
				DECI.ALUAS = AAS_M;
				DECI.ALUOP = ALU_A;
				DECI.AW = ~IC[6];
				DECI.BW = IC[6];
				{DECI.YW,DECI.XW} = IC[1:0];
				{DECI.YE,DECI.XE} = IC[1:0];
				DECI.MA = MA_ADR;
				DECI.MR = 1;
			end
			
			12'b00_0100_1000_00,			//LAB (B->A)
			12'b00_0101_1000_00,			//LASPY (SPY->A)
			12'b00_0110_1000_00: begin	//LASPX (SPX->A)
				case (IC[5:4])
					default: DECI.ALUAS = AAS_B;
					2'b01: DECI.ALUAS = AAS_SPY;
					2'b10: DECI.ALUAS = AAS_SPX;
				endcase
				DECI.ALUOP = ALU_A;
				DECI.AW = 1;
			end
			
			12'b00_0100_1100_00,			//IB (B+1->B)
			12'b00_0101_1100_00,			//IY (Y+1->Y)
			12'b00_1100_1111_00,			//DB (B-1->B)
			12'b00_1101_1111_00: begin	//DY (Y-1->Y)
				case (IC[4])
					1'b0: DECI.ALUAS = AAS_B;
					1'b1: DECI.ALUAS = AAS_Y;
				endcase
				DECI.ALUBS = ABS_ONE;
				DECI.ALUOP = ALU_ADD;
				DECI.ALUCD = {2'b00,IC[7]};
				DECI.BW = ~IC[4];
				DECI.YW = IC[4];
				DECI.STU = !IC[7] ? STU_NZ : STU_C;
			end
			
			12'b00_0101_000x_00,			//LMAIY(X) (A->M,Y+1->Y,X<->SPX)
			12'b00_1101_000x_00: begin	//LMADY(X) (A->M,Y-1->Y,X<->SPX)
				DECI.ALUAS = AAS_Y;
				DECI.ALUBS = ABS_ONE;
				DECI.ALUOP = ALU_ADD;
				DECI.ALUCD = {2'b00,IC[7]};
				DECI.STU = !IC[7] ? STU_NZ : STU_C;
				DECI.XW = IC[0];
				DECI.XE = IC[0];
				DECI.YW = 1;
				DECI.MA = MA_ADR;
				DECI.MD = MD_A;
				DECI.MW = 1;
			end
			
			12'b00_0101_0100_00,			//AYY (Y+A->Y)
			12'b00_1101_0100_00: begin	//SYY (Y-A->Y)
				DECI.ALUAS = AAS_Y;
				DECI.ALUBS = ABS_A;
				DECI.ALUOP = ALU_ADD;
				DECI.ALUCD = {2'b00,IC[7]};
				DECI.YW = 1;
				DECI.STU = STU_C;
			end
			
			12'b00_0110_0000_00: begin	//NEGA (0-A->A)
				DECI.ALUAS = AAS_ZERO;
				DECI.ALUBS = ABS_A;
				DECI.ALUOP = ALU_ADD;
				DECI.ALUCD = 3'b001;
				DECI.AW = 1;
			end
			
			12'b00_0110_0100_00,			//RED (0->D[Y])
			12'b00_1110_0100_00,			//SED (1->D[Y])
			12'b10_0110_xxxx_00,			//REDD m (0->D[m])
			12'b10_1110_xxxx_00: begin	//SEDD m (1->D[m])
				DECI.ALUBS = IC[7] ? ABS_ONE : ABS_ZERO;
				DECI.ALUOP = ALU_B;
				DECI.MA = !IC[9] ? MA_ADR : MA_MR;
				DECI.MD = MD_ALU;
				DECI.IOW = 1;
				DECI.IOP = 0;
			end
			
			12'b00_1110_0000_00,			//TD (D[Y]->ST)
			12'b10_1010_xxxx_00: begin	//TDD m (D[m]->ST)
				DECI.ALUAS = AAS_M;
				DECI.ALUOP = ALU_A;
				DECI.MA = !IC[9] ? MA_ADR : MA_MR;
				DECI.STU = STU_PD;
				DECI.IOR = 1;
				DECI.IOP = 0;
			end
			
			12'b00_0110_1111_00: begin	//TC (CA->ST)
				DECI.STU = STU_CA;
			end
			
			12'b00_0111_xxxx_00: begin	//YNEI i
				DECI.ALUAS = AAS_Y;
				DECI.ALUBS = ABS_I;
				DECI.ALUOP = ALU_ADD;
				DECI.ALUCD = 3'b001;
				DECI.STU = STU_NZ;
			end
			
			12'b00_1000_00xx_00,			//XMA(XY) (M<->A)
			12'b00_1100_00xx_00,			//XMB(XY) (M<->B)
			12'b01_1000_0000_01: begin	//XMAD d (M(d)<->A)
				DECI.ALUAS = AAS_M;
				DECI.ALUOP = ALU_A;
				DECI.AW = ~IC[6];
				DECI.BW = IC[6];
				DECI.MA = MA_ADR;
				DECI.MD = IC[6] ? MD_B : MD_A;
				DECI.MW = 1;
				DECI.MR = 1;
			end
			
			12'b00_1000_01xx_00,			//SEM n (M|(1<<n)->M)
			12'b00_1000_10xx_00,			//REM n (M&~(1<<n)->M)
			12'b00_1000_11xx_00,			//TM n (M&(1<<n), NZ->ST)
			12'b01_1000_01xx_01,			//SEMD n,d (M|(1<<n)->M)
			12'b01_1000_10xx_01,			//REMD n,d (M&~(1<<n)->M)
			12'b01_1000_11xx_01: begin	//TMD n,d (M&(1<<n), NZ->ST)
				DECI.ALUAS = AAS_M;
				DECI.ALUBS = ABS_BIT;
				DECI.ALUOP = ALU_BIT;
				DECI.ALUCD = {1'b0,IC[3:2]};
				DECI.STU = IC[3:2] == 2'b11 ? STU_NZ : STU_NOP;
				DECI.MA = MA_ADR;
				DECI.MD = MD_ALU;
				DECI.MR = 1;
				DECI.MW = IC[3]^IC[2];
			end
			
			12'b00_1001_01xx_00,			//LMA(XY) (A->M,X<->SPX,Y<->SPY)
			12'b01_1001_0100_01: begin	//LMAD d (A->M)
				{DECI.YW,DECI.XW} = IC[1:0];
				{DECI.YE,DECI.XE} = IC[1:0];
				DECI.MA = MA_ADR;
				DECI.MD = MD_A;
				DECI.MW = 1;
			end
			
			12'b00_1010_0000_00,			//ROTR ({CA,A}>>1->{CA,A})
			12'b00_1010_0001_00: begin	//ROTL ({CA,A}<<1->{CA,A})
				DECI.ALUAS = AAS_A;
				DECI.ALUOP = ALU_LOG;
				DECI.ALUCD = {2'b10,IC[0]};
				DECI.AW = 1;
			end
			
			12'b00_1010_0110_00,			//DAA 
			12'b00_1010_1010_00: begin	//DAS 
				DECI.ALUAS = AAS_A;
				DECI.ALUBS = ABS_I;
				DECI.ALUOP = ALU_ADD;
				DECI.ALUCD = 3'b000;
				DECI.AW = DA_COND;
				DECI.CAU = !DA_COND ? CAU_NOP : !IC[3] ? CAU_ONE : CAU_ZERO;
			end
			
			12'b00_1010_1111_00: begin	//LAY (Y->A)
				DECI.ALUAS = AAS_Y;
				DECI.ALUOP = ALU_A;
				DECI.AW = 1;
			end
			
			12'b00_1011_xxxx_00: begin	//TBR p 
				DECI.PCU = PCU_TBR;
			end
			
			12'b00_1100_1000_00,			//LBA (A->B)
			12'b00_1101_1000_00,			//LYA (A->Y)
			12'b00_1110_1000_00: begin	//LXA (A->X)
				DECI.ALUAS = AAS_A;
				DECI.ALUOP = ALU_A;
				DECI.BW = IC[5:4] == 2'b00;
				DECI.YW = IC[5:4] == 2'b01;
				DECI.XW = IC[5:4] == 2'b10;
			end
			
			12'b00_1110_1100_00,			//REC (0->CA)
			12'b00_1110_1111_00: begin	//SEC (1->CA)
				DECI.CAU = !IC[0] ? CAU_ZERO : CAU_ONE;
			end
			
			12'b00_1111_00xx_00: begin	//LWI (I->W)
				DECI.ALUAS = AAS_I;
				DECI.ALUOP = ALU_A;
				DECI.WW = 1;
			end
			
			12'b01_0000_0100_00,			//ANEMD d
			12'b01_0000_1000_00,			//AMD d
			12'b01_0000_1100_00,			//ORMD d
			12'b01_0001_0100_00,			//ALEMD d
			12'b01_0001_1000_00,			//AMCD d
			12'b01_0001_1100_00,			//EORMD d
			12'b01_0010_xxxx_00,			//INEMD i,d
			12'b01_0011_xxxx_00,			//ILEMD i,d
			12'b01_1000_0000_00,			//XMAD d
			12'b01_1000_01xx_00,			//SEMD n,d
			12'b01_1000_10xx_00,			//REMD n,d
			12'b01_1000_11xx_00,			//TMD n,d
			12'b01_1001_0000_00,			//LAMD d
			12'b01_1001_0100_00,			//LMAD d
			12'b01_1001_1000_00,			//SMCD d
			12'b01_1001_1100_00,			//ANMD d
			12'b01_1010_xxxx_00: begin	//LMID i,d
				DECI.IWR = 1;
				DECI.LST = 0;
			end
			
			12'b01_0100_0000_00: begin	//COMB (~B->B)
				DECI.ALUBS = ABS_B;
				DECI.ALUOP = ALU_LOG;
				DECI.ALUCD = 3'b010;
				DECI.BW = 1;
			end
			
			12'b01_0100_0100_00: begin	//OR (A|B->A)
				DECI.ALUAS = AAS_A;
				DECI.ALUBS = ABS_B;
				DECI.ALUOP = ALU_LOG;
				DECI.ALUCD = 3'b000;
				DECI.AW = 1;
			end
			
			12'b01_0100_1100_00: begin	//SBY
				DECI.SBY = 1;
			end
			
			12'b01_0100_1101_00: begin	//STOP
				DECI.STOP = 1;
			end
			
			12'b01_0101_xxxx_00: begin	//JMPL u
				DECI.IWR = 1;
				DECI.LST = 0;
			end
			12'b01_0101_xxxx_01: begin	//JMPL u
				DECI.PCU = PCU_BRL;
			end
			
			12'b01_0110_xxxx_00,			//CALL u
			12'b01_0111_xxxx_00: begin	//BRL u
				DECI.IWR = 1;
				DECI.LST = 0;
			end
			12'b01_0110_xxxx_01,			//CALL u
			12'b01_0111_xxxx_01: begin	//BRL u
				DECI.STU = STU_SET;
				DECI.MA = MA_STK2;
				DECI.MW = ST & ~IC[4];
				DECI.PCU = ST ? PCU_BRL : PCU_INC;
				DECI.SPD = ST & ~IC[4];
			end
			
			12'b01_1010_xxxx_01: begin	//LMID i,d (I->M)
				DECI.MA = MA_ADR;
				DECI.MD = MD_I;
				DECI.MW = 1;
			end
			
			12'b01_1011_xxxx_00: begin	//P p
				DECI.PCU = PCU_NU;
				DECI.LST = 0;
			end
			12'b01_1011_xxxx_01: begin	//P p
				DECI.PI = 1;
				DECI.LST = 1;
			end
			
			12'b01_11xx_xxxx_00: begin	//CAL a
				DECI.STU = STU_SET;
				DECI.PCU = PCU_INC;
				DECI.LST = ~ST;
			end
			12'b01_11xx_xxxx_01: begin	//CAL a
				DECI.MA = MA_STK1;
				DECI.MW = 1;
				DECI.PCU = PCU_ZP;
				DECI.SPD = 1;
			end
			
			12'b10_0000_xxxx_00,			//LBI (I->B)
			12'b10_0001_xxxx_00,			//LYI (I->Y)
			12'b10_0010_xxxx_00,			//LXI (I->X)
			12'b10_0011_xxxx_00: begin	//LAI (I->A)
				DECI.ALUAS = AAS_I;
				DECI.ALUOP = ALU_A;
				DECI.BW = IC[5:4] == 2'b00;
				DECI.YW = IC[5:4] == 2'b01;
				DECI.XW = IC[5:4] == 2'b10;
				DECI.AW = IC[5:4] == 2'b11;
			end
			
			12'b10_0100_xxxx_00,			//LBR m (R[m]->B)
			12'b10_0101_xxxx_00: begin	//LAR m (R[m]->A)
				DECI.ALUAS = AAS_M;
				DECI.ALUOP = ALU_A;
				DECI.MA = MA_MR;
				DECI.AW = IC[4];
				DECI.BW = ~IC[4];
				DECI.IOR = 1;
				DECI.IOP = 1;
			end
			
			12'b10_0111_xxxx_00: begin	//LAMR m (MR[m]->A)
				DECI.ALUAS = AAS_M;
				DECI.ALUOP = ALU_A;
				DECI.AW = 1;
				DECI.MA = MA_MR;
				DECI.MR = 1;
			end
			
			12'b10_1000_xxxx_00: begin	//AI (A+I->A)
				DECI.ALUAS = AAS_A;
				DECI.ALUBS = ABS_I;
				DECI.ALUOP = ALU_ADD;
				DECI.ALUCD = 3'b000;
				DECI.AW = 1;
				DECI.STU = STU_C;
			end
			
			12'b10_1001_xxxx_00: begin	//LMIIY(X) (I->M,Y+1->Y)
				DECI.ALUAS = AAS_Y;
				DECI.ALUBS = ABS_ONE;
				DECI.ALUOP = ALU_ADD;
				DECI.ALUCD = 3'b000;
				DECI.STU = STU_NZ;
				DECI.YW = 1;
				DECI.MA = MA_ADR;
				DECI.MD = MD_I;
				DECI.MW = 1;
			end
			
			12'b10_1011_xxxx_00: begin	//ALEI (A-I)
				DECI.ALUAS = AAS_A;
				DECI.ALUBS = ABS_I;
				DECI.ALUOP = ALU_ADD;
				DECI.ALUCD = 3'b001;
				DECI.STU = STU_NB;
			end
			
			12'b10_1100_xxxx_00,			//LRB m (B->R[m])
			12'b10_1101_xxxx_00: begin	//LRA m (A->R[m])
				DECI.MA = MA_MR;
				case(IC[4])
					1'b0: DECI.MD = MD_B;
					1'b1: DECI.MD = MD_A;
				endcase
				DECI.IOW = 1;
				DECI.IOP = 1;
			end
			
			12'b10_1111_xxxx_00: begin	//XMRA m (MR[m]<->A)
				DECI.ALUAS = AAS_M;
				DECI.ALUOP = ALU_A;
				DECI.AW = 1;
				DECI.MA = MA_MR;
				DECI.MD = MD_A;
				DECI.MW = 1;
			end
			
			12'b11_xxxx_xxxx_00: begin	//BR d 
				DECI.STU = STU_SET;
				DECI.PCU = ST ? PCU_BR : PCU_INC;
			end
			
			default: DECI.ILI = 1;
		endcase
		
		return DECI;
	endfunction
	
endpackage

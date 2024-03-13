package SCSP_PKG;

	//Slot control registers, offset 100000+n*20
	typedef struct packed		//RW,00
	{
		bit [ 2: 0] UNUSED;
		bit         KX;
		bit         KB;
		bit [ 1: 0] SBCTL;
		bit [ 1: 0] SSCTL;
		bit [ 1: 0] LPCTL;
		bit         PCM8B;
		bit [ 3: 0] SAH;
	} SCR0_t;
	parameter bit [15:0] SCR0_MASK = 16'h1FFF;
	
	typedef bit [15:0] SA_t;	//RW,02
	parameter bit [15:0] SA_MASK = 16'hFFFF;
	
	typedef bit [15:0] LSA_t;	//RW,04
	parameter bit [15:0] LSA_MASK = 16'hFFFF;
	
	typedef bit [15:0] LEA_t;	//RW,06
	parameter bit [15:0] LEA_MASK = 16'hFFFF;
	
	typedef struct packed		//RW,08
	{
		bit [ 4: 0] D2R;
		bit [ 4: 0] D1R;
		bit         EGHOLD;
		bit [ 4: 0] AR;
	} SCR1_t;
	parameter bit [15:0] SCR1_MASK = 16'hFFFF;
	
	typedef struct packed		//RW,0A
	{
		bit         UNUSED;
		bit         LPSLNK;
		bit [ 3: 0] KRS;
		bit [ 4: 0] DL;
		bit [ 4: 0] RR;
	} SCR2_t;
	parameter bit [15:0] SCR2_MASK = 16'h7FFF;
	
	typedef struct packed		//RW,0C
	{
		bit [ 5: 0] UNUSED;
		bit         STWINH;
		bit         SDIR;
		bit [ 7: 0] TL;
	} SCR3_t;
	parameter bit [15:0] SCR3_MASK = 16'h03FF;
	
	typedef struct packed		//RW,0E
	{
		bit [ 3: 0] MDL;
		bit [ 5: 0] MDXSL;
		bit [ 5: 0] MDYSL;
	} SCR4_t;
	parameter bit [15:0] SCR4_MASK = 16'hFFFF;
	
	typedef struct packed		//RW,10
	{
		bit         UNUSED;
		bit [ 3: 0] OCT;
		bit [10: 0] FNS;
	} SCR5_t;
	parameter bit [15:0] SCR5_MASK = 16'h7FFF;
	
	typedef struct packed		//RW,12
	{
		bit         LFORE;
		bit [ 4: 0] LFOF;
		bit [ 1: 0] PLFOWS;
		bit [ 2: 0] PLFOS;
		bit [ 1: 0] ALFOWS;
		bit [ 2: 0] ALFOS;
	} SCR6_t;
	parameter bit [15:0] SCR6_MASK = 16'hFFFF;
	
	typedef struct packed		//RW,14
	{
		bit [ 8: 0] UNUSED;
		bit [ 3: 0] ISEL;
		bit [ 2: 0] IMXL;
	} SCR7_t;
	parameter bit [15:0] SCR7_MASK = 16'h007F;
	
	typedef struct packed		//RW,16
	{
		bit [ 2: 0] DISDL;
		bit [ 4: 0] DIPAN;
		bit [ 2: 0] EFSDL;
		bit [ 4: 0] EFPAN;
	} SCR8_t;
	parameter bit [15:0] SCR8_MASK = 16'hFFFF;
	
	//Control registers
	typedef struct packed		//RW,100400
	{
		bit [ 5: 0] UNUSED;
		bit         M4;
		bit         DB;
		bit [ 3: 0] UNUSED2;
		bit [ 3: 0] MVOL;
	} CR0_t;
	parameter bit [15:0] CR0_MASK = 16'h030F;
	
	typedef struct packed		//RW,100402
	{
		bit [ 6: 0] UNUSED;
		bit [ 1: 0] RBL;
		bit [ 6: 0] RBP;
	} CR1_t;
	parameter bit [15:0] CR1_MASK = 16'h01FF;
	
	typedef struct packed		//RW,100404
	{
		bit [ 2: 0] UNUSED;
		bit         OF;
		bit         OE;
		bit         IO;
		bit         IF;
		bit         IE;
		bit [ 7: 0] MIBUF;
	} CR2_t;
	parameter bit [15:0] CR2_MASK = 16'h1FFF;
	
	typedef struct packed		//RW,100406
	{
		bit [ 7: 0] UNUSED;
		bit [ 7: 0] MOBUF;
	} CR3_t;
	parameter bit [15:0] CR3_MASK = 16'h00FF;
	
	typedef struct packed		//RW,100408
	{
		bit [ 4: 0] MSLC;		//W
		bit [ 3: 0] CA;		//R
		bit [ 1: 0] UNUSED;
		bit [ 1: 0] SGC;		//R
		bit [ 2: 0] UNUSED2;
	} CR4_t;
	parameter bit [15:0] CR4_RMASK = 16'h07FF;
	parameter bit [15:0] CR4_WMASK = 16'hF800;
	
	typedef struct packed		//RW,100412
	{
		bit [14: 0] DMEAL;
		bit         UNUSED;
	} CR5_t;
	parameter bit [15:0] CR5_MASK = 16'hFFFE;
	
	typedef struct packed		//RW,100414
	{
		bit [ 3: 0] DMEAH;
		bit [10: 0] DRGA;
		bit         UNUSED;
	} CR6_t;
	parameter bit [15:0] CR6_MASK = 16'hFFFE;
	
	typedef struct packed		//RW,100416
	{
		bit         UNUSED;
		bit         DGATE;
		bit         DDIR;
		bit         DEXE;
		bit [10: 0] DTLG;
		bit         UNUSED2;
	} CR7_t;
	parameter bit [15:0] CR7_MASK = 16'h7FFE;
	
	typedef struct packed		//RW,100418
	{
		bit [ 4: 0] UNUSED;
		bit [ 2: 0] TACTL;
		bit [ 7: 0] TIMA;
	} CR8_t;
	parameter bit [15:0] CR8_MASK = 16'h07FF;
	
	typedef struct packed		//RW,10041A
	{
		bit [ 4: 0] UNUSED;
		bit [ 2: 0] TBCTL;
		bit [ 7: 0] TIMB;
	} CR9_t;
	parameter bit [15:0] CR9_MASK = 16'h07FF;
	
	typedef struct packed		//RW,10041C
	{
		bit [ 4: 0] UNUSED;
		bit [ 2: 0] TCCTL;
		bit [ 7: 0] TIMC;
	} CR10_t;
	parameter bit [15:0] CR10_MASK = 16'h07FF;
	
	typedef struct packed		//RW,10041E
	{
		bit [ 4: 0] UNUSED;
		bit [10: 0] SCIEB;
	} CR11_t;
	parameter bit [15:0] CR11_MASK = 16'h07FF;
	
	typedef struct packed		//RW,100420
	{
		bit [ 4: 0] UNUSED;
		bit [10: 0] SCIPD;
	} CR12_t;
	parameter bit [15:0] CR12_MASK = 16'h07FF;
	
	typedef struct packed		//RW,100422
	{
		bit [ 4: 0] UNUSED;
		bit [10: 0] SCIRE;
	} CR13_t;
	parameter bit [15:0] CR13_MASK = 16'h07FF;
	
	typedef struct packed		//RW,100424
	{
		bit [ 7: 0] UNUSED;
		bit [ 7: 0] SCILV0;
	} CR14_t;
	parameter bit [15:0] CR14_MASK = 16'h00FF;
	
	typedef struct packed		//RW,100426
	{
		bit [ 7: 0] UNUSED;
		bit [ 7: 0] SCILV1;
	} CR15_t;
	parameter bit [15:0] CR15_MASK = 16'h00FF;
	
	typedef struct packed		//RW,100428
	{
		bit [ 7: 0] UNUSED;
		bit [ 7: 0] SCILV2;
	} CR16_t;
	parameter bit [15:0] CR16_MASK = 16'h00FF;
	
	typedef struct packed		//RW,10042A
	{
		bit [ 4: 0] UNUSED;
		bit [10: 0] MCIEB;
	} CR17_t;
	parameter bit [15:0] CR17_MASK = 16'h07FF;
	
	typedef struct packed		//RW,10042C
	{
		bit [ 4: 0] UNUSED;
		bit [10: 0] MCIPD;
	} CR18_t;
	parameter bit [15:0] CR18_MASK = 16'h07FF;
	
	typedef struct packed		//RW,10042E
	{
		bit [ 4: 0] UNUSED;
		bit [10: 0] MCIRE;
	} CR19_t;
	parameter bit [15:0] CR19_MASK = 16'h07FF;
	
	typedef bit [15:0] SOUS_t;		//RW,100600-10067F
	parameter bit [15:0] SOUS_MASK = 16'hFFFF;
	
	typedef struct packed
	{
		SCR0_t      SCR0;
		SA_t        SA;
		LSA_t       LSA;
		LEA_t       LEA;
		SCR1_t      SCR1;
		SCR2_t      SCR2;
		SCR3_t      SCR3;
		SCR4_t      SCR4;
		SCR5_t      SCR5;
		SCR6_t      SCR6;
		SCR7_t      SCR7;
		SCR8_t      SCR8;
	} SCR_t;
	
//	typedef SOUS_t STACK_t[32];
	
	typedef bit [12:0]  COEF_t;		//RW,100700-10077F
	parameter bit [15:0] COEF_MASK = 16'hFFF8;
	
	typedef bit [16:1] MADRS_t;		//RW,100780-1007BF
	parameter bit [16:1] MADRS_MASK = 16'hFFFF;
	
	typedef struct packed				//RW,100800-100BFF
	{
		bit         UNUSED;
		bit [ 6: 0] TRA;
		bit         TWT;
		bit [ 6: 0] TWA;
		bit         XSEL;
		bit [ 1: 0] YSEL;
		bit         UNUSED2;
		bit [ 5: 0] IRA;
		bit         IWT;
		bit [ 4: 0] IWA;
		bit         TABLE;
		bit         MWT;
		bit         MRD;
		bit         EWT;
		bit [ 3: 0] EWA;
		bit         ADRL;
		bit         FRCL;
		bit [ 1: 0] SHFT;
		bit         YRL;
		bit         NEGB;
		bit         ZERO;
		bit         BSEL;
		bit         NOFL;
		bit [ 5: 0] COEF;
		bit [ 1: 0] UNUSED3;
		bit [ 4: 0] MASA;
		bit         ADREB;
		bit         NXADR;
	} MPRO_t;
	parameter bit [63:0] MPRO_MASK = 64'h7FFFEFFFFFFFFE7F;
	
	typedef bit [23:0] TEMP_t;		//RW,100C00-100DFF
	parameter bit [31:0] TEMP_MASK = 32'h00FFFFFF;
	
	typedef bit [23:0] MEMS_t;		//RW,100E00-100E7F
	parameter bit [31:0] MEMS_MASK = 32'h00FFFFFF;
	
	typedef bit [19:0] MIXS_t;		//RW,100E80-100EBF
	parameter bit [31:0] MIXS_MASK = 32'h000FFFFF;
	
	typedef bit [15:0] EFREG_t;	//RW,100EC0-100EDF
	parameter bit [15:0] EFREG_MASK = 16'hFFFF;
	
	typedef MIXS_t MIXSS_t[16];
	
	
	typedef bit [1:0] EGState_t;
	parameter EGState_t EST_ATTACK  = 2'b00;
	parameter EGState_t EST_DECAY1  = 2'b01;
	parameter EGState_t EST_DECAY2  = 2'b10;
	parameter EGState_t EST_RELEASE = 2'b11;
	
//	typedef struct packed
//	{
//		bit [14: 0] PHASE;
//	} OP1State_t;
	
	typedef struct packed
	{
		bit [ 4: 0] SLOT;	//
		bit         RST;	//
		bit         KON;	//
		bit         KOFF;	//
		bit  [ 7:0] PHASE_INT;//Phase integer
		bit  [17:0] PHASE_FRAC;//Phase fractional
		bit  [ 5:0] BASE_RATE;
		bit [ 7: 0] PLFO;	//Pitch LFO data
	} OP2_t;
	parameter OP2_t OP2_RESET = '{5'h00,1'b0,1'b0,1'b0,8'h00,18'h00000,6'h00,8'h00};
	
	typedef struct packed
	{
		bit [ 4: 0] SLOT;	//
		bit         RST;	//
		bit         KON;	//
		bit         KOFF;	//
		bit [ 5: 0] BASE_RATE;
		bit         LOOP;//Loop processing 
		bit         LOOP_END;//Loop processing end
		bit         PCM8B;//
		bit [ 1: 0] SBCTL;
		bit [ 1: 0] SSCTL;
		bit [ 1: 0] EST;//Envelope state
		bit [ 9: 0] EVOL;//Envelope volume
	} OP3_t;
	parameter OP3_t OP3_RESET = '{5'h00,1'b0,1'b0,1'b0,6'h00,1'b0,1'b0,1'b0,2'h0,2'h0,2'h0,10'h000};
	
	typedef struct packed
	{
		bit [ 4: 0] SLOT;	//
		bit         RST;	//
		bit         KON;	//
		bit         KOFF;	//
		bit [ 5: 0] BASE_RATE;
		bit         LOOP;//Loop processing 
		bit         LOOP_END;//Loop processing end
		bit [ 1: 0] EST;//Envelope state
		bit [ 9: 0] EVOL;//Envelope volume
		bit [15: 0] WD;//Wave form data
	} OP4_t;
	parameter OP4_t OP4_RESET = '{5'h00,1'b0,1'b0,1'b0,6'h00,1'b0,1'b0,2'h0,10'h000,16'h0000};
	
	typedef struct packed
	{
		bit [ 4: 0] SLOT;	//
		bit         RST;	//
		bit         KON;	//
		bit         KOFF;	//
		bit [15: 0] WD;	//Wave form data
		bit [ 1: 0] EST;	//Envelope state
		bit [ 9: 0] EVOL;	//Envelope volume
		bit [ 7: 0] ALFO; 
	} OP5_t;
	parameter OP5_t OP5_RESET = '{5'h00,1'b0,1'b0,1'b0,16'h0000,2'h0,10'h000,8'h00};
	
	typedef struct packed
	{
		bit [ 4: 0] SLOT;	//
		bit         RST;	//
		bit         KON;	//
		bit         KOFF;	//
		bit [15: 0] WD;	//Wave form data
		bit [15: 0] SD;	//Slot out data
		bit [ 9: 0] LEVEL;//Level
	} OP6_t;
	parameter OP6_t OP6_RESET = '{5'h00,1'b0,1'b0,1'b0,16'h0000,16'h0000,10'h000};
	
	typedef struct packed
	{
		bit [ 4: 0] SLOT;	//
		bit         RST;	//
		bit         KON;	//
		bit         KOFF;	//
		bit [15: 0] SD;	//Slot out data
		bit         STWINH;
	} OP7_t;
	parameter OP7_t OP7_RESET = '{5'h00,1'b0,1'b0,1'b0,16'h0000,1'b0};
	
	
	
	function bit [15:0] SoundSel(input bit [15:0] WAVE, input bit [15:0] NOISE, bit [1:0] SBCTL, bit [1:0] SSCTL);
		bit [15:0] SD;
		bit [15:0] temp;
		
		case (SSCTL)
			2'b00: temp = WAVE;
			2'b01: temp = NOISE;
			default: temp = 16'h0000;
		endcase
		SD = {temp[15] ^ SBCTL[1], temp[14:0] ^ {15{SBCTL[0]}}}; 
	
		return SD;
	endfunction

	function bit signed [15:0] MDCalc(bit signed [15:0] X, bit signed [15:0] Y, bit [3:0] MDL);
		bit signed [15:0] MD;
		bit signed [15:0] TEMP;
		
		TEMP = {X[15],X[15:1]} + {Y[15],Y[15:1]}; 
		MD = $signed($signed(TEMP)>>>(~MDL));
		
		return MDL ? MD : '0;
	endfunction
	
	function bit [25:0] PhaseCalc(SCR5_t SCR5);
		bit [25:0] P;
		bit [3:0] S;
		bit [10:0] F;
		
		S = SCR5.OCT^4'h8;
		F = 11'h400 + SCR5.FNS;
		P = {15'b000000000000000,F}<<S;
		
		return P;
	endfunction
	
	
	typedef struct packed
	{
		bit [12: 0] CNT;	//
		bit         LAST;	//
	} EnvTable_t;
	parameter EnvTable_t ENV_TBL [64][7] = '{
	'{{13'h1FFF,1'b0},{13'h0FFF,1'b0},{13'h0FFF,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//00
	'{{13'h1FFF,1'b0},{13'h0FFF,1'b0},{13'h0FFF,1'b0},{13'h0FFF,1'b0},{13'h0FFF,1'b0},{13'h0FFF,1'b0},{13'h0FFF,1'b1}},//01
	'{{13'h0FFF,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//02
	'{{13'h0FFF,1'b0},{13'h0FFF,1'b0},{13'h0FFF,1'b0},{13'h07FF,1'b0},{13'h07FF,1'b1},{13'h0000,1'b0},{13'h0000,1'b0}},//03
	
	'{{13'h0FFF,1'b0},{13'h07FF,1'b0},{13'h07FF,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//04
	'{{13'h0FFF,1'b0},{13'h07FF,1'b0},{13'h07FF,1'b0},{13'h07FF,1'b0},{13'h07FF,1'b0},{13'h07FF,1'b0},{13'h07FF,1'b1}},//05
	'{{13'h07FF,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//06
	'{{13'h07FF,1'b0},{13'h07FF,1'b0},{13'h07FF,1'b0},{13'h03FF,1'b0},{13'h03FF,1'b1},{13'h0000,1'b0},{13'h0000,1'b0}},//07
	
	'{{13'h07FF,1'b0},{13'h03FF,1'b0},{13'h03FF,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//08
	'{{13'h07FF,1'b0},{13'h03FF,1'b0},{13'h03FF,1'b0},{13'h03FF,1'b0},{13'h03FF,1'b0},{13'h03FF,1'b0},{13'h03FF,1'b1}},//09
	'{{13'h03FF,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//0A
	'{{13'h03FF,1'b0},{13'h03FF,1'b0},{13'h03FF,1'b0},{13'h01FF,1'b0},{13'h01FF,1'b1},{13'h0000,1'b0},{13'h0000,1'b0}},//0B
	
	'{{13'h03FF,1'b0},{13'h01FF,1'b0},{13'h01FF,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//0C
	'{{13'h03FF,1'b0},{13'h01FF,1'b0},{13'h01FF,1'b0},{13'h01FF,1'b0},{13'h01FF,1'b0},{13'h01FF,1'b0},{13'h01FF,1'b1}},//0D
	'{{13'h01FF,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//0E
	'{{13'h01FF,1'b0},{13'h01FF,1'b0},{13'h01FF,1'b0},{13'h00FF,1'b0},{13'h00FF,1'b1},{13'h0000,1'b0},{13'h0000,1'b0}},//0F
	
	'{{13'h01FF,1'b0},{13'h00FF,1'b0},{13'h00FF,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//10
	'{{13'h01FF,1'b0},{13'h00FF,1'b0},{13'h00FF,1'b0},{13'h00FF,1'b0},{13'h00FF,1'b0},{13'h00FF,1'b0},{13'h00FF,1'b1}},//11
	'{{13'h00FF,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//12
	'{{13'h00FF,1'b0},{13'h00FF,1'b0},{13'h00FF,1'b0},{13'h007F,1'b0},{13'h007F,1'b1},{13'h0000,1'b0},{13'h0000,1'b0}},//13
	
	'{{13'h00FF,1'b0},{13'h007F,1'b0},{13'h007F,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//14
	'{{13'h00FF,1'b0},{13'h007F,1'b0},{13'h007F,1'b0},{13'h007F,1'b0},{13'h007F,1'b0},{13'h007F,1'b0},{13'h007F,1'b1}},//15
	'{{13'h007F,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//16
	'{{13'h007F,1'b0},{13'h007F,1'b0},{13'h007F,1'b0},{13'h003F,1'b0},{13'h003F,1'b1},{13'h0000,1'b0},{13'h0000,1'b0}},//17
	
	'{{13'h007F,1'b0},{13'h003F,1'b0},{13'h003F,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//18
	'{{13'h007F,1'b0},{13'h003F,1'b0},{13'h003F,1'b0},{13'h003F,1'b0},{13'h003F,1'b0},{13'h003F,1'b0},{13'h003F,1'b1}},//19
	'{{13'h003F,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//1A
	'{{13'h003F,1'b0},{13'h003F,1'b0},{13'h003F,1'b0},{13'h001F,1'b0},{13'h001F,1'b1},{13'h0000,1'b0},{13'h0000,1'b0}},//1B
	
	'{{13'h003F,1'b0},{13'h001F,1'b0},{13'h001F,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//1C
	'{{13'h003F,1'b0},{13'h001F,1'b0},{13'h001F,1'b0},{13'h001F,1'b0},{13'h001F,1'b0},{13'h001F,1'b0},{13'h001F,1'b1}},//1D
	'{{13'h001F,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//1E
	'{{13'h001F,1'b0},{13'h001F,1'b0},{13'h001F,1'b0},{13'h000F,1'b0},{13'h000F,1'b1},{13'h0000,1'b0},{13'h0000,1'b0}},//1F
	
	'{{13'h001F,1'b0},{13'h000F,1'b0},{13'h000F,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//20
	'{{13'h001F,1'b0},{13'h000F,1'b0},{13'h000F,1'b0},{13'h000F,1'b0},{13'h000F,1'b0},{13'h000F,1'b0},{13'h000F,1'b1}},//21
	'{{13'h000F,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//22
	'{{13'h000F,1'b0},{13'h000F,1'b0},{13'h000F,1'b0},{13'h0007,1'b0},{13'h0007,1'b1},{13'h0000,1'b0},{13'h0000,1'b0}},//23
	
	'{{13'h000F,1'b0},{13'h0007,1'b0},{13'h0007,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//24
	'{{13'h000F,1'b0},{13'h0007,1'b0},{13'h0007,1'b0},{13'h0007,1'b0},{13'h0007,1'b0},{13'h0007,1'b0},{13'h0007,1'b1}},//25
	'{{13'h0007,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//26
	'{{13'h0007,1'b0},{13'h0007,1'b0},{13'h0007,1'b0},{13'h0003,1'b0},{13'h0003,1'b1},{13'h0000,1'b0},{13'h0000,1'b0}},//27
	
	'{{13'h0007,1'b0},{13'h0003,1'b0},{13'h0003,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//28
	'{{13'h0007,1'b0},{13'h0003,1'b0},{13'h0003,1'b0},{13'h0003,1'b0},{13'h0003,1'b0},{13'h0003,1'b0},{13'h0003,1'b1}},//29
	'{{13'h0003,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//2A
	'{{13'h0003,1'b0},{13'h0003,1'b0},{13'h0003,1'b0},{13'h0001,1'b0},{13'h0001,1'b1},{13'h0000,1'b0},{13'h0000,1'b0}},//2B
	
	'{{13'h0003,1'b0},{13'h0001,1'b0},{13'h0001,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//2C
	'{{13'h0003,1'b0},{13'h0001,1'b0},{13'h0001,1'b0},{13'h0001,1'b0},{13'h0001,1'b0},{13'h0001,1'b0},{13'h0001,1'b1}},//2D
	'{{13'h0001,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//2E
	'{{13'h0001,1'b0},{13'h0001,1'b0},{13'h0001,1'b0},{13'h0000,1'b0},{13'h0000,1'b1},{13'h0000,1'b0},{13'h0000,1'b0}},//2F
	
	'{{13'h0001,1'b0},{13'h0000,1'b0},{13'h0000,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//30
	'{{13'h0001,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b1}},//31
	'{{13'h0000,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//32
	'{{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b1},{13'h0000,1'b0},{13'h0000,1'b0}},//33
	
	'{{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//34
	'{{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b1}},//35
	'{{13'h0000,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//36
	'{{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b1},{13'h0000,1'b0},{13'h0000,1'b0}},//37
	
	'{{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//38
	'{{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b1}},//39
	'{{13'h0000,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//3A
	'{{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b1},{13'h0000,1'b0},{13'h0000,1'b0}},//3B
	
	'{{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//3C
	'{{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b1}},//3D
	'{{13'h0000,1'b1},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0}},//3E
	'{{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b0},{13'h0000,1'b1},{13'h0000,1'b0},{13'h0000,1'b0}} //3F
	};
	
	function bit [5:0] BaseRateCalc(SCR5_t SCR5);
		bit [5:0] TEMP;
		
		TEMP = {5'b00000,SCR5.FNS[9]} + {{2{SCR5.OCT[3]}},SCR5.OCT};
			
		return TEMP;
	endfunction
	
	parameter bit [ 3: 0] ARATE_TBL [16][4] = '{
	'{4'h4,4'h4,4'h4,4'h4},//30
	'{4'h3,4'h4,4'h4,4'h4},//31
	'{4'h3,4'h4,4'h3,4'h4},//32
	'{4'h3,4'h3,4'h3,4'h4},//33
	
	'{4'h3,4'h3,4'h3,4'h3},//34
	'{4'h2,4'h3,4'h3,4'h3},//35
	'{4'h2,4'h3,4'h2,4'h3},//36
	'{4'h2,4'h2,4'h2,4'h3},//37
	
	'{4'h2,4'h2,4'h2,4'h2},//38
	'{4'h1,4'h2,4'h2,4'h2},//39
	'{4'h1,4'h2,4'h1,4'h2},//3A
	'{4'h1,4'h1,4'h1,4'h2},//3B
	
	'{4'h1,4'h1,4'h1,4'h1},//3C
	'{4'h1,4'h1,4'h1,4'h1},//3D
	'{4'h1,4'h1,4'h1,4'h1},//3E
	'{4'h1,4'h1,4'h1,4'h1} //3F
	};
	
	parameter bit [ 3: 0] DRATE_TBL [16][4] = '{
	'{4'h1,4'h1,4'h1,4'h1},//30
	'{4'h2,4'h1,4'h1,4'h1},//31
	'{4'h2,4'h1,4'h2,4'h1},//32
	'{4'h2,4'h2,4'h2,4'h1},//33
	
	'{4'h2,4'h2,4'h2,4'h2},//34
	'{4'h4,4'h2,4'h2,4'h2},//35
	'{4'h2,4'h2,4'h4,4'h2},//36
	'{4'h4,4'h4,4'h4,4'h2},//37
	
	'{4'h4,4'h4,4'h4,4'h4},//38
	'{4'h8,4'h4,4'h4,4'h4},//39
	'{4'h8,4'h4,4'h8,4'h4},//3A
	'{4'h8,4'h8,4'h8,4'h4},//3B
	
	'{4'h8,4'h8,4'h8,4'h8},//3C
	'{4'h8,4'h8,4'h8,4'h8},//3D
	'{4'h8,4'h8,4'h8,4'h8},//3E
	'{4'h8,4'h8,4'h8,4'h8} //3F
	};
	
	function bit [9:0] AttackEnvCalc(bit [5:0] RATE, bit [9:0] EVOL);
		bit [3:0] R;
		
		if (RATE[5:4] != 2'h3)
			R = ARATE_TBL[0][0];
		else
			R = ARATE_TBL[RATE[3:0]][0];
		return (EVOL>>R) + 10'd1;
	endfunction
	
	function bit [9:0] DecayEnvCalc(bit [5:0] RATE);
		bit [3:0] R;
		
		if (RATE[5:4] != 2'h3)
			R = DRATE_TBL[0][0];
		else
			R = DRATE_TBL[RATE[3:0]][0];
		return {6'b000000,R};
	endfunction
	
	function bit [5:0] EffRateCalc(bit [5:0] BASE, bit [4:0] RATE, bit [3:0] KRS);
		bit [5:0] RES;
		bit [7:0] TEMP;
		
		if (KRS == 4'hF) 
			TEMP = {2'b00,RATE,1'b0};
		else
			TEMP = {{2{BASE[5]}},BASE} + {2'b00,RATE,1'b0} + {3'b000,KRS,1'b0};
		
		if (TEMP[7])
			RES = 6'h00;
		else if (TEMP[6])
			RES = 6'h3F;
		else
			RES = TEMP[5:0];
			
		return RES;
	endfunction
	
	function bit [9:0] LevelAddALFO(bit [9:0] LEVEL, bit [7:0] ALFO);
		bit [10:0] SUM;
		
		SUM = {1'b0,LEVEL} + {3'b000,ALFO};
		
		return !SUM[10] ? SUM[9:0] : 10'h3FF;
	endfunction
	
	function bit [9:0] LevelAddTL(bit [9:0] LEVEL, bit [7:0] TL);
		bit [10:0] SUM;
		
		SUM = {1'b0,LEVEL} + {1'b0,TL,2'b00};
		
		return !SUM[10] ? SUM[9:0] : 10'h3FF;
	endfunction
	
	function bit signed [15:0] VolCalc(bit signed [15:0] WAVE, bit [9:0] LEVEL);
		bit [22:0] MULT;
		bit [15:0] RES;
		
		MULT = $signed(WAVE) * ({2'b01,~LEVEL[5:0]});
		RES = $signed($signed(MULT[22:7])>>>LEVEL[9:6]);
		
		return RES;
	endfunction
	
	function bit signed [15:0] LevelCalc(bit signed [15:0] WAVE, bit [2:0] SDL);
		return SDL ? $signed($signed(WAVE)>>>(~SDL)) : 16'sh0000;
	endfunction
	
	function bit signed [15:0] PanLCalc(bit signed [15:0] WAVE, bit [4:0] PAN);
		bit [15:0] TEMP;
		
		TEMP = $signed($signed(WAVE)>>>PAN[3:1]);
		return !PAN[4] ? $signed(TEMP) - (PAN[0] ? $signed($signed(TEMP)>>>2) : '0) : WAVE;
	endfunction
	
	function bit signed [15:0] PanRCalc(bit signed [15:0] WAVE, bit [4:0] PAN);
		bit [15:0] TEMP;
		
		TEMP = $signed($signed(WAVE)>>>PAN[3:1]);
		return  PAN[4] ? $signed(TEMP) - (PAN[0] ? $signed($signed(TEMP)>>>2) : '0) : WAVE;
	endfunction
	
	function bit signed [15:0] MVolCalc(bit signed [17:0] WAVE, bit [3:0] MVOL, bit DAC18B);
		bit [17:0] TEMP1,TEMP2,TEMP3;
		
		TEMP1 = DAC18B ? $signed(WAVE)<<<2 : WAVE;
		TEMP2 = $signed($signed(TEMP1)>>>(~MVOL[3:1]));
		TEMP3 = MVOL ? $signed(TEMP2) - (!MVOL[0] ? $signed($signed(TEMP2)>>>2) : '0) : 18'sh0000;
		
		return TEMP3[17] && TEMP3[16:15] != 2'b11 ? 16'h8000 : !TEMP3[17] && TEMP3[16:15] != 2'b00 ? 16'h7FFF : TEMP3[15:0];
	endfunction
	
	function bit [7:0] LFOWave(bit [7:0] POS, bit [7:0] NOISE, bit [1:0] LFOWS);
		bit [7:0] WAVE;
		
		case (LFOWS)
			2'b00: WAVE = POS;
			2'b01: WAVE = {8{POS[7]}};
			2'b10: WAVE = {POS[6:0],1'b0} ^ {8{POS[7]}};
			2'b11: WAVE = NOISE;
		endcase
		return WAVE;
	endfunction
	
	function bit [25:0] DSPMult(bit [23:0] X, bit [12:0] Y);
		bit [37:0] M;
		
		M = $signed(X) * $signed(Y);
		return M[37:12];
	endfunction
	
	function bit [23:0] DSPShifter(bit [25:0] A, bit [1:0] SHFT);
		bit [25:0] TEMP;
		bit [23:0] RES;
		
		case (SHFT)
			2'b00,
			2'b11: TEMP = A[25:0];
			2'b01,
			2'b10: TEMP = {A[24:0],1'b0};
		endcase
		
		RES = !SHFT[1] && !TEMP[25] && TEMP[24:23] != 2'b00 ? 24'h7FFFFF : 
		      !SHFT[1] &&  TEMP[25] && TEMP[24:23] != 2'b11 ? 24'h800000 : 
				TEMP[23:0];
				
		return RES;
	endfunction
	
	function bit [15:0] DSPItoF(bit [23:0] I);
		bit         SIGN;
		bit [ 3: 0] EXP;
		bit [10: 0] MANT;
		bit [22: 0] T0,T1,T2,T3;
		bit [ 3: 0] E1,E2,E3;
		
		SIGN = I[23];
		
		T0 = I[22:0] ^ {23{SIGN}};
		{E1,T1} = T0[22:19] != 4'b0000 ? {4'h0,T0[22:0]} : T0[18:15] != 4'b0000 ? {4'h4,T0[18:0],4'h0} : {4'h8,T0[14:0],4'h0,4'h0};
		{E2,T2} = T1[22:21] != 2'b00 ? {4'h0,T1[22:0]} : {4'h2,T1[20:0],2'h0};
		{E3,T3} = T2[22:22] != 1'b0 ? {4'h0,T2[22:0]} : T2[21:21] != 1'b0 ? {4'h1,T2[21:0],1'h0} : {4'h2,T2[21:0],1'h0};
		
		EXP = E1 + E2 + E3;
		MANT = T3[21:11] ^ {11{SIGN}};
		
		return {SIGN,EXP,MANT};
	endfunction
	
	function bit [23:0] DSPFtoI(bit [15:0] F);
		bit         SIGN;
		bit [ 3: 0] EXP;
		bit [10: 0] MANT;
		bit [23: 0] RES;
	
		{SIGN,EXP,MANT} = F;
		
		if (EXP >= 4'd12)
			RES = {{12{SIGN}},SIGN,MANT};
		else
			RES = $signed($signed({SIGN,~SIGN,MANT,11'h000}) >>> EXP);
	
		return RES;
	endfunction
	
endpackage

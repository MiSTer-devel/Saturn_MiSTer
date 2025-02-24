package VDP1_PKG;

	//Registers
	typedef struct packed	//WO,100000
	{
		bit [11: 0] UNUSED;
		bit         VBE;
		bit [ 2: 0] TVM;
	} TVMR_t;
	parameter bit [15:0] TVMR_MASK = 16'h000F;

	typedef struct packed	//WO,100002
	{
		bit [10: 0] UNUSED;
		bit         EOS;
		bit         DIE;
		bit         DIL;
		bit         FCM;
		bit         FCT;
	} FBCR_t;
	parameter bit [15:0] FBCR_MASK = 16'h001F;

	typedef struct packed	//WO,100004
	{
		bit [13: 0] UNUSED;
		bit [ 1: 0] PTM;
	} PTMR_t;
	parameter bit [15:0] PTMR_MASK = 16'h0003;
	
	typedef bit [15:0] EWDR_t;	//WO,100006
	parameter bit [15:0] EWDR_MASK = 16'hFFFF;
	
	typedef struct packed	//WO,100008
	{
		bit         UNUSED;
		bit [ 8: 3] X1;
		bit [ 8: 0] Y1;
	} EWLR_t;
	parameter bit [15:0] EWLR_MASK = 16'h7FFF;

	typedef struct packed	//WO,10000A
	{
		bit [ 9: 3] X3;
		bit [ 8: 0] Y3;
	} EWRR_t;
	parameter bit [15:0] EWRR_MASK = 16'hFFFF;
	
	typedef bit [15:0] ENDR_t;	//WO,10000C
	parameter bit [15:0] ENDR_MASK = 16'h0000;
	
	typedef struct packed	//RO,100010
	{
		bit [13: 0] UNUSED;
		bit         CEF;
		bit         BEF;
	} EDSR_t;
	parameter bit [15:0] EDSR_MASK = 16'h0003;
	
	typedef bit [15:0] LOPR_t;	//RO,100012
	parameter bit [15:0] LOPR_MASK = 16'hFFFC;
	
	typedef bit [15:0] COPR_t;	//RO,100014
	parameter bit [15:0] COPR_MASK = 16'hFFFC;
	
	typedef struct packed	//RO,100016
	{
		bit [ 3: 0] VER;
		bit [ 2: 0] UNUSED;
		bit         PTM1;
		bit         EOS;
		bit         DIE;
		bit         DIL;
		bit         FCM;
		bit         VBE;
		bit [ 2: 0] TVM;
	} MODR_t;
	parameter bit [15:0] MODR_MASK = 16'hF1FF;
	
	//Command tables
	typedef struct packed	//00
	{
		bit         END;
		bit [ 2: 0] JP;
		bit [ 3: 0] ZP;
		bit [ 1: 0] UNUSED;
		bit [ 1: 0] DIR;
		bit [ 3: 0] COMM;
	} CMDCTRL_t;
	parameter bit [15:0] CMDCTRL_MASK = 16'hFF3F;
	
	typedef bit [15:0] CMDLINK_t;	//02
	parameter bit [15:0] CMDLINK_MASK = 16'hFFFC;
	
	typedef struct packed	//04
	{
		bit         MON;
		bit [ 1: 0] UNUSED;
		bit         HSS;
		bit         PCLP;
		bit         CLIP;
		bit         CMOD;
		bit         MESH;
		bit         ECD;
		bit         SPD;
		bit [ 2: 0] CM;
		bit [ 2: 0] CCB;
	} CMDPMOD_t;
	parameter bit [15:0] CMDPMOD_MASK = 16'h9FFF;
	
	typedef bit [15:0] CMDCOLR_t;	//06
	parameter bit [15:0] CMDCOLR_MASK = 16'hFFFF;
	
	typedef bit [15:0] CMDSRCA_t;	//08
	parameter bit [15:0] CMDSRCA_MASK = 16'hFFFF;
	
	typedef struct packed	//0A
	{
		bit [ 1: 0] UNUSED;
		bit [ 8: 3] SX;
		bit [ 7: 0] SY;
	} CMDSIZE_t;
	parameter bit [15:0] CMDSIZE_MASK = 16'h3FFF;
	
	typedef struct packed	//0C-1A
	{
		bit [ 4: 0] EXT;
		bit [10: 0] COORD;
	} CMDCRD_t;
	parameter bit [15:0] CMDCRD_MASK = 16'hFFFF;
	
	typedef bit [15:0] CMDGRDA_t;	//1C
	parameter bit [15:0] CMDGRDA_MASK = 16'hFFFF;
	
	typedef struct packed
	{
		CMDCTRL_t   CMDCTRL;	//00
		CMDLINK_t   CMDLINK;	//02
		CMDPMOD_t   CMDPMOD;	//04
		CMDCOLR_t   CMDCOLR;	//06
		CMDSRCA_t   CMDSRCA;	//08
		CMDSIZE_t   CMDSIZE;	//0A
		CMDCRD_t    CMDXA;	//0C
		CMDCRD_t    CMDYA;	//0E
		CMDCRD_t    CMDXB;	//10
		CMDCRD_t    CMDYB;	//12
		CMDCRD_t    CMDXC;	//14
		CMDCRD_t    CMDYC;	//16
		CMDCRD_t    CMDXD;	//18
		CMDCRD_t    CMDYD;	//1A
		CMDGRDA_t   CMDGRDA;	//1C
		bit [15: 0] UNUSED;	//1E
	} CMDTBL_t;
	
	//Command value
	parameter CMD_NSPR 	= 4'h0; 	//Normal sprite draw
	parameter CMD_SSPR 	= 4'h1; 	//Scaled sprite draw
	parameter CMD_DSPR 	= 4'h2;	//Distorted sprite draw
	parameter CMD_POLY 	= 4'h4;	//Polygon draw
	parameter CMD_PLIN 	= 4'h5;	//Polyline draw
	parameter CMD_LINE 	= 4'h6;	//Line draw
	parameter CMD_UCLIP 	= 4'h8;	//Set user clipping coordinate
	parameter CMD_SCLIP 	= 4'h9;	//Set system clipping coordinate
	parameter CMD_LCORD 	= 4'hA;	//Set local coordinate
	
	
	typedef struct packed
	{
		bit [10: 0] X1;
		bit [10: 0] Y1;
		bit [10: 0] X2;
		bit [10: 0] Y2;
	} Clip_t;
	parameter Clip_t CLIP_NULL = {11'h000,11'h000,11'h000,11'h000};
	
	typedef struct packed
	{
		bit [10: 0] X;
		bit [10: 0] Y;
	} Coord_t;
	parameter Coord_t COORD_NULL = {11'h000,11'h000};
	
	
	typedef struct packed
	{
		bit [12: 0] X;
		bit [12: 0] Y;
	} Vertex_t;
	parameter Vertex_t VERT_NULL = {12'h000,12'h000};
	
	//Rotation screen
	typedef struct packed
	{
		bit [ 2: 0] UNUSED;
		bit [12: 0] INT;
		bit [ 9: 0] FRAC;
		bit [ 5: 0] UNUSED2;
	} ScrnStart_t;
	parameter ScrnStart_t SCNST_NULL = {3'h0,13'h0000,10'h000,6'h00};
	
	typedef struct packed
	{
		bit [12: 0] UNUSED;
		bit [ 2: 0] INT;
		bit [ 9: 0] FRAC;
		bit [ 5: 0] UNUSED2;
	} ScrnInc_t;
	parameter ScrnInc_t SCNINC_NULL = {13'h0000,3'h0,10'h000,6'h00};
	
	typedef struct packed
	{
		bit [10: 0] INT;
		bit [ 8: 0] FRAC;
	} RotCoord_t;
	parameter bit [31:0] RC_NULL = {16'h0000,16'h0000};
	parameter bit [31:0] RC_ONE = {16'h0001,16'h0000};
	
	function RotCoord_t ScrnStartToRC(ScrnStart_t P);
		return { {P.INT[12],P.INT[9:0]}, P.FRAC[9:1]};
	endfunction
	
	function RotCoord_t ScrnIncToRC(ScrnInc_t P);
		return { {{8{P.INT[2]}},P.INT}, P.FRAC[9:1] };
	endfunction
	
	function bit [18:1] SprAddr(input bit [16:3] OFFSY, input CMDSRCA_t CMDSRCA, input bit [2:0] CM);
		bit [18:1] ADDR;

		case (CM)
			3'b000,
			3'b001:  ADDR = {CMDSRCA,2'b00} + {3'b000,OFFSY,1'b0};
			3'b010,
			3'b011,
			3'b100:  ADDR = {CMDSRCA,2'b00} + {2'b00,OFFSY,2'b00};
			default: ADDR = {CMDSRCA[15:1],1'b0,2'b00} + {1'b0,OFFSY,3'b000};
		endcase
		return ADDR;
	endfunction
	
	function bit [15:0] GetSprData(input bit [15:0] DATA, input bit [2:0] CM, input bit [1:0] OFFSX);
		bit [15:0] D;
		
		case (CM)
			3'b000,
			3'b001:
				case (OFFSX)
					2'b00: D = {12'h000,DATA[15:12]};
					2'b01: D = {12'h000,DATA[11: 8]};
					2'b10: D = {12'h000,DATA[ 7: 4]};
					2'b11: D = {12'h000,DATA[ 3: 0]};
				endcase
			3'b010,
			3'b011,
			3'b100:
				case (OFFSX[0])
					1'b0: D = {8'h00,DATA[15: 8]};
					1'b1: D = {8'h00,DATA[ 7: 0]};
				endcase
			default: D = DATA;
		endcase

		return D;
	endfunction
	
	typedef struct packed
	{
		bit [15: 0] C;
		bit         TP;
		bit         EC;
	} Pattern_t;
	parameter Pattern_t PATTERN_NULL = {16'h0000,1'b0,1'b0};
	
	function Pattern_t GetPattern(input bit [15:0] DATA, input bit [2:0] CM);
		bit [15:0] C;
		bit        TP;
		bit        EC;
		
		case (CM)
			3'b000,
			3'b001: begin C = {12'h000,DATA[3:0]}; TP = ~|DATA[3:0]; EC = &DATA[3:0]; end
			3'b010,
			3'b011,
			3'b100: begin C = {8'h00,DATA[7:0]}; TP = ~|DATA[7:0]; EC = &DATA[7:0]; end
			default: begin C = DATA; TP = ~DATA[15]; EC = (DATA == 16'h7FFF); end
		endcase

		return {C,TP,EC};
	endfunction
	
	typedef struct packed
	{
		bit [ 4: 0] B;
		bit [ 4: 0] G;
		bit [ 4: 0] R;
	} RGB_t;
	
	typedef struct packed
	{
		bit         DIR;
		bit [ 4: 0] INT;
		bit [11: 0] FRAC;
	} ColorFP_t;
	
	typedef struct packed
	{
		ColorFP_t  B;
		ColorFP_t  G;
		ColorFP_t  R;
	} RGBFP_t;
	
	function RGBFP_t RGBItoF(input RGB_t CI);
		RGBFP_t CF;
		
		CF.R = {1'b0,CI.R,12'b000000000000};
		CF.G = {1'b0,CI.G,12'b000000000000};
		CF.B = {1'b0,CI.B,12'b000000000000};
		return CF;
	endfunction
	
	function RGB_t RGBFtoI(input RGBFP_t CF);
		RGB_t CI;
		
		CI.R = CF.R.INT;
		CI.G = CF.G.INT;
		CI.B = CF.B.INT;
		return CI;
	endfunction
	
	function RGB_t ColorHalf(input RGB_t CA);
		RGB_t CH;
		
		CH.R = {1'b0,CA.R[4:1]};
		CH.G = {1'b0,CA.G[4:1]};
		CH.B = {1'b0,CA.B[4:1]};
		return CH;
	endfunction
	
	function RGB_t ColorAdd(input RGB_t CA, input RGB_t CB);
		RGB_t CR;
		
		CR.R = CA.R + CB.R;
		CR.G = CA.G + CB.G;
		CR.B = CA.B + CB.B;
		return CR;
	endfunction
	
	function RGB_t GouraudAdd(input RGB_t CO, input RGB_t CG);
		bit [6:0] SUMR,SUMG,SUMB;
		RGB_t CR;
		
		SUMR = {2'b00,CO.R} + {2'b00,CG.R} - 7'h10;
		SUMG = {2'b00,CO.G} + {2'b00,CG.G} - 7'h10;
		SUMB = {2'b00,CO.B} + {2'b00,CG.B} - 7'h10;
		
		CR.R = SUMR[6:5] == 2'b11 ? 5'h00 : SUMR[6:5] == 2'b01 ? 5'h1F : SUMR[4:0];
		CR.G = SUMG[6:5] == 2'b11 ? 5'h00 : SUMG[6:5] == 2'b01 ? 5'h1F : SUMG[4:0];
		CR.B = SUMB[6:5] == 2'b11 ? 5'h00 : SUMB[6:5] == 2'b01 ? 5'h1F : SUMB[4:0];
		
		return CR;
	endfunction
	
	function bit [15:0] ColorCalc(input bit [15:0] ORIG, input bit [15:0] BACK, input bit [14:0] CG, input bit [2:0] CCB);
		RGB_t      GOUR;
		RGB_t      ORIG_HALF,ORIG_ONE;
		RGB_t      GOUR_HALF,GOUR_ONE;
		RGB_t      BACK_HALF,BACK_ONE;
		RGB_t      A,B,S;
		bit        MSB;
		
		GOUR = GouraudAdd(ORIG[14:0],CG);
		
		ORIG_HALF = ColorHalf(ORIG[14:0]);
		ORIG_ONE = ORIG[14:0];
		GOUR_HALF = ColorHalf(GOUR);
		GOUR_ONE = GOUR;
		BACK_HALF = ColorHalf(BACK[14:0]);
		BACK_ONE = BACK[14:0];
		
		case (CCB)
			3'b000: begin A = ORIG_ONE;                        B = '0;                              MSB =            ORIG[15]; end
			3'b001: begin A = '0;                              B = BACK[15] ? BACK_HALF : BACK_ONE; MSB = BACK[15];            end
			3'b010: begin A = ORIG_HALF;                       B = '0;                              MSB =            ORIG[15]; end
			3'b011: begin A = BACK[15] ? ORIG_HALF : ORIG_ONE; B = BACK[15] ? BACK_HALF : '0;       MSB = BACK[15] | ORIG[15]; end
			3'b100: begin A = GOUR_ONE;                        B = '0;                              MSB =            ORIG[15]; end
			3'b101: begin A = '0;                              B = BACK_ONE;                        MSB = BACK[15];            end
			3'b110: begin A = GOUR_HALF;                       B = '0;                              MSB =            ORIG[15]; end
			3'b111: begin A = BACK[15] ? GOUR_HALF : GOUR_ONE; B = BACK[15] ? BACK_HALF : '0;       MSB = BACK[15] | ORIG[15]; end
		endcase
		S = ColorAdd(A,B);
		
		return {MSB,S};
	endfunction

	function bit [11:0] Abs13(input bit [12:0] C);
		bit [12:0] abs; 
		
		abs = $signed(C) >= 0 ? $signed(C) : -$signed(C);
		return abs[11:0];
	endfunction
	
endpackage

// altera message_off 10027

import VDP2_PKG::*;
	
module VDP2 (
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	
	input             RES_N,

	input      [15:0] DI,
	output     [15:0] DO,
	input             CS_N,
	input             AD_N,
	input             DTEN_N,
	input             REQ_N,
	output            RDY_N,
	
	output            VINT_N,
	output            HINT_N,
	
	output            DCE_R,
	output            DCE_F,
	output            HTIM_N,
	output            VTIM_N,
	input      [15:0] FBD,
	
	input             PAL,
	
	output     [17:1] RA0_A,
	output     [16:1] RA1_A,
	output     [63:0] RA_D,
	output      [7:0] RA_WE,
	output            RA_RD,
	input      [31:0] RA0_Q,
	input      [31:0] RA1_Q,
	
	output     [17:1] RB0_A,
	output     [16:1] RB1_A,
	output     [63:0] RB_D,
	output      [7:0] RB_WE,
	output            RB_RD,
	input      [31:0] RB0_Q,
	input      [31:0] RB1_Q,
	
	output      [7:0] R,
	output      [7:0] G,
	output      [7:0] B,
	output reg        DCLK,
	output reg        HS_N,
	output reg        VS_N,
	output reg        HBL_N,
	output reg        VBL_N,
	
	output            FIELD,
	output            INTERLACE,
	output reg  [1:0] HRES,
	output reg  [1:0] VRES,
	
	input       [7:0] SCRN_EN,
	
	input       [7:0] DBG_EXT
`ifdef DEBUG
                     ,
	output VRAMAccessState_t VA_PIPE0,
	output NVRAMAccess_t NBG_A0VA_DBG,
//	output [18: 1] NxVS_ADDR0,
	output CellDotsColor_t NBG_CDC0_DBG,
	output CellDotsColor_t NBG_CDC1_DBG,
	output CellDotsColor_t NBG_CDC2_DBG,
	output CellDotsColor_t NBG_CDC3_DBG,
	output CellDotsParam_t NBG_CDP0_DBG,
	output           [7:0] RBG0_CDC0_DBG,
	output           [7:0] RBG0_CDC1_DBG,
	output           [7:0] RBG0_CDC2_DBG,
	output           [7:0] RBG0_CDC3_DBG,
	output DotParam_t      RBG0_CDP_DBG,
	output           [7:0] RBG1_CDC0_DBG,
	output           [7:0] RBG1_CDC1_DBG,
	output           [7:0] RBG1_CDC2_DBG,
	output           [7:0] RBG1_CDC3_DBG,
	output DotParam_t      RBG1_CDP_DBG,
//	output RxCHD_t CH_PIPE0,
//	output RxCHD_t CH_PIPE1,
//	output RxCHD_t CH_PIPE2,
//	output [4:0] N0DOTN_DBG,
	output DotData_t R0DOT_DBG,
	output DotData_t N0DOT_DBG,
	output DotData_t N1DOT_DBG,
	output DotData_t N2DOT_DBG,
	output DotData_t N3DOT_DBG,
//	output ScreenDot_t DOT_FST_DBG,
//	output ScreenDot_t DOT_SEC_DBG,
//	output ScreenDot_t DOT_THD_DBG,
	output [2:0] FST_PRI0_DBG, SEC_PRI0_DBG, THD_PRI0_DBG,
	output [2:0] FST_PRI1_DBG, SEC_PRI1_DBG, THD_PRI1_DBG,
	output [2:0] FST_PRI2_DBG, SEC_PRI2_DBG, THD_PRI2_DBG,
	output [2:0] FST_PRI3_DBG, SEC_PRI3_DBG, THD_PRI3_DBG,
	output [2:0] FST_PRI4_DBG, SEC_PRI4_DBG, THD_PRI4_DBG,
	output [2:0] FST_PRI5_DBG, SEC_PRI5_DBG, THD_PRI5_DBG,
//	output [18:0] N0SCX,
//	output [18:0] N0SCY,
	output [18:0] NxOFFX0_DBG,
	output [18:0] NxOFFX1_DBG,
	output [18:0] NxOFFX2_DBG,
	output [18:0] NxOFFY0_DBG,
	output [18:0] NxOFFY1_DBG,
//	output RotTbl_t ROTA_TBL,
	output [15:0] VRAM_WRITE_PEND_CNT,
	output RotCoord_t   RPK_DBG,
	output [34:0] KAx0_DBG,
	output [3:0] RA_D_ERR,
	output [3:0] RB_D_ERR,
	output [15:0] REG_DBG
`endif
);
	
	//H 427/455
	//V 263/313
	parameter HRES_320  = 9'd427;
	parameter HRES_352  = 9'd455;//
	parameter HS_START_320  = 9'd350;
	parameter HS_START_352  = 9'd380;
	parameter HBL_START_320 = 9'd312;
	parameter HBL_START_352 = 9'd344;
//	parameter HBL_END_320 = 9'd415 - 9'd1;//9'd410;
//	parameter HBL_END_352 = 9'd443 - 9'd1;//9'd442;
	parameter VRES_NTSC = 9'd263;
	parameter VRES_PAL  = 9'd313;
	parameter VS_START_224  = 9'd239;
	parameter VS_START_240  = 9'd245;//?
	parameter VS_START_256  = 9'd276;//?
	parameter VS_END_224    = VS_START_224 + 9'd3;
	parameter VS_END_240    = VS_START_240 + 9'd3;
	parameter VS_END_256    = VS_START_256 + 9'd3;
	parameter VBL_START_224 = 9'd224;
	parameter VBL_START_240 = 9'd240;
	parameter VBL_START_256 = 9'd256;
	
	VDP2Regs_t REGS;
	
	
	bit [18:1] VRAM_WA;
	bit [18:1] VRAM_RA;
	bit [63:0] VRAM_D;
	bit  [7:0] VRAM_WE;
	bit        VRAM_WRITE_PEND;
	bit        VRAM_READ_PEND;
	
	bit  [17: 1] VRAMA0_A, VRAMB0_A;
	bit  [16: 1] VRAMA1_A, VRAMB1_A;
	bit  [63: 0] VRAMA_D, VRAMB_D;
	bit  [ 7: 0] VRAMA_WE, VRAMB_WE;
	bit          VRAMA0_RD, VRAMA1_RD, VRAMB0_RD, VRAMB1_RD;
	bit  [15: 0] VRAMA0_Q, VRAMA1_Q, VRAMB0_Q, VRAMB1_Q;
	bit          VRAM_READ_PIPE[2];
	wire VRAMA0_READ = (VRAM_RA[18:17] == 2'b00);
	wire VRAMA1_READ = (VRAM_RA[18:17] == 2'b01);
	wire VRAMB0_READ = (VRAM_RA[18:17] == 2'b10);
	wire VRAMB1_READ = (VRAM_RA[18:17] == 2'b11);
	
	
	bit          DOT_CE_R,DOT_CE_F;
	bit  [ 8: 0] H_CNT, V_CNT;
	bit  [ 8: 0] SCRNX, SCRNY;
	bit          SCRNX0;
//	bit  [ 8: 0] WINX;
//	bit  [ 1: 0] HRES;
//	bit  [ 1: 0] VRES;
	bit          DISP;
	VRAMAccessPipeline_t VA_PIPE;
	NBGPipeline_t   BG_PIPE;
	ScrollData_t NxOFFX[4];
	ScrollData_t NxOFFY[4];
	ScrollData_t VS[2];
	CT_t         CTD[2];			//Coeficient table data A/B
	RotCoord_t   RxX[2],RxY[2];
	RotCoord_t   KAst[2];
	RotAddr_t    RxKA[2];
	bit          RxCTTP[2];
	bit          R0RPMSB;
	
	bit  [15: 0] PAL0_Q, PAL1_Q;
	bit  [15: 0] PAL0_DO, PAL1_DO;
	
	
	bit  [ 1: 0] DOTCLK_DIV;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			DOTCLK_DIV <= '0;
		end
		else if (CE_R) begin
			DOTCLK_DIV <= DOTCLK_DIV + 2'd1;
		end
	end
	assign DOT_CE_R = (DOTCLK_DIV == 3) & CE_R;
	assign DOT_CE_F = (DOTCLK_DIV == 1) & CE_R;
	
	assign DCLK = DOT_CE_R | (DOT_CE_F & HRES[1]);
	assign DCE_R = DOT_CE_R;
	assign DCE_F = DOT_CE_F;
	
	bit  [ 8: 0] HBL_END_320,HBL_END_352;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			HBL_END_320 <= 9'd4;
			HBL_END_352 <= 9'd4;
		end else begin
			HBL_END_320 <= !HRES[1] ? 9'd5 : 9'd4;
			HBL_END_352 <= !HRES[1] ? 9'd5 : 9'd4;
			if (DBG_EXT[2]) begin
				HBL_END_320 <= 9'd5;
				HBL_END_352 <= 9'd5;
			end
//			
//			if (H352_END_INC) begin
//				HBL_END_352 <= HBL_END_352 + 9'd1;
//				if (HBL_END_352 == 9'd455 - 9'd1) HBL_END_352 <= 9'd0;
//			end
//			if (H352_END_DEC) begin
//				HBL_END_352 <= HBL_END_352 - 9'd1;
//				if (HBL_END_352 == 9'd0) HBL_END_352 <= 9'd455 - 9'd1;
//			end
		end
	end
	
	wire LAST_DOT = (H_CNT == HRES_320 - 1 && !HRES[0]) || (H_CNT == HRES_352 - 1 && HRES[0]);
//	wire PRELAST_DOT = (H_CNT == HRES_320 - 2 && !HRES[0]) || (H_CNT == HRES_352 - 2 && HRES[0]);
//	wire [8:0] HBL_START = !HRES[0] ? HBL_START_320 : HBL_START_352;
	wire [8:0] HS_START = (!HRES[0] ? HS_START_320 : HS_START_352) - (!PAL ? 0 : 4);
	wire [8:0] HS_END =  HS_START + 9'd32; 
	wire [8:0] HBL_END = !HRES[0] ? HBL_END_320 - 9'd2 : HBL_END_352 - 9'd2;
	wire [8:0] HDISP_END = !HRES[0] ? 9'd320 - 9'd1 : 9'd352 - 9'd1;
	wire [8:0] VBL_START = VBL_START_224 + {VRES,4'h0};
	wire [8:0] VS_START  = !VRES[1] ? (!VRES[0] ? VS_START_224 : VS_START_240) : VS_START_256 ; // + {VRES,4'h0};
	wire [8:0] VS_END    = !VRES[1] ? (!VRES[0] ? VS_END_224 : VS_END_240) : VS_END_256; //VS_END_224 + {VRES,4'h0};
	wire [8:0] VBORD_START  = !VRES[1] ? (!VRES[0] ? 9'd263-9'd12 : 9'd263-9'd4) : 9'd313-9'd0;
	wire [8:0] VBORD_END  = !VRES[1] ? (!VRES[0] ? 9'd224+9'd12 : 9'd240+9'd4) : 9'd256+9'd0;
	wire [8:0] NEXT_TO_LAST_LINE  = !PAL ? (VRES_NTSC - 9'd2) : (VRES_PAL - 9'd2);
	wire [8:0] LAST_LINE  = !PAL ? (VRES_NTSC - 9'd1) : (VRES_PAL - 9'd1);
	wire IS_LAST_LINE = (V_CNT == LAST_LINE);
	
	bit  [ 8: 0] HDISP_CNT;
	bit          VBLANK,VBLANK2;
	bit          HBLANK;
	bit          ODD;
	bit          VSYNC;
	bit          HSYNC;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			H_CNT <= '0;
			V_CNT <= '0;
			HSYNC <= 0;
			VSYNC <= 0;
			HBLANK <= 0;
			VBLANK <= 0;
			ODD <= 0;
			HDISP_CNT <= '0;
		end
		else if (!RES_N) begin
			H_CNT <= '0;
			V_CNT <= !PAL ? VS_START : 9'd280;
			HSYNC <= 0;
			VSYNC <= 1;
			HBLANK <= 0;
			VBLANK <= 1;
			ODD <= 0;
			VBLANK2 <= 1;
			HDISP_CNT <= '0;
		end
		else if (DOT_CE_R) begin
			H_CNT <= H_CNT + 9'd1;
			if (LAST_DOT) begin
				H_CNT <= '0;
				V_CNT <= V_CNT + 9'd1;
				if (V_CNT == LAST_LINE) begin
					V_CNT <= '0;
				end
			end
			
			if (H_CNT == HS_START - 1) begin
				HSYNC <= 1;
			end else if (H_CNT == HS_END - 1) begin
				HSYNC <= 0;
			end
			
			HDISP_CNT <= HDISP_CNT + 9'd1;
			if (H_CNT == HBL_END - 1) begin
				HBLANK <= 0;
				HDISP_CNT <= '0;
			end else if (HDISP_CNT == HDISP_END) begin
				HBLANK <= 1;
			end
			
			if (H_CNT == 9'd352) begin
				if (V_CNT == VS_START - 1) begin
					VSYNC <= 1;
				end else if (V_CNT == VS_END - 1) begin
					VSYNC <= 0;
				end
			end
			
			if (H_CNT == 9'h176 - 1 && V_CNT == VBL_START - 1) begin
				VBLANK <= 1;
			end else if (H_CNT == 9'h180 && V_CNT == LAST_LINE) begin
				VBLANK <= 0;
			end
			
			if (LAST_DOT && V_CNT == VBL_START - 1) begin
				VBLANK2 <= 1;
			end else if (LAST_DOT && V_CNT == NEXT_TO_LAST_LINE) begin
				VBLANK2 <= 0;
			end
			
			if (LAST_DOT && V_CNT == VBORD_START - 1) begin
				
			end else if (LAST_DOT && V_CNT == VBORD_END - 1) begin
				ODD <= ~ODD;
			end
			
			if (LAST_DOT && V_CNT >= VBL_START && V_CNT <= NEXT_TO_LAST_LINE) begin
				HRES <= REGS.TVMD.HRESO[1:0];
				VRES <= !PAL && REGS.TVMD.VRESO[1] ? 2'b01 : REGS.TVMD.VRESO[1:0];
				DISP <= REGS.TVMD.DISP;
			end
		end
	end
//	assign HRES = REGS.TVMD.HRESO[1:0];
//	assign VRES = REGS.TVMD.VRESO[1:0];
	
	wire [8:0] HINT_START = !HRES[0] ? 9'h138 : 9'h158;
	wire [8:0] VINT_HPOS = !HRES[0] ? 9'h15B : 9'h177;
	bit VINT;
	bit HINT;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			HINT <= 0;
			VINT <= 0;
		end
		else if (!RES_N) begin
			HINT <= 0;
			VINT <= 1;
		end
		else if (DOT_CE_R) begin
			if (H_CNT == HINT_START - 1) begin
				HINT <= 1;
			end else if (LAST_DOT) begin
				HINT <= 0;
			end
			
			if (H_CNT == VINT_HPOS - 1) begin
				if (V_CNT == VBL_START - 1) begin
					VINT <= 1;
				end else if (V_CNT == NEXT_TO_LAST_LINE) begin
					VINT <= 0;
				end
			end
		end
	end
	assign VINT_N = ~VINT;
	assign HINT_N = ~HINT;
	
	bit  [ 8: 0] HTIM_END_320,HTIM_END_352;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			HTIM_END_320 <= 9'h001;
			HTIM_END_352 <= 9'h001;
		end else begin
			HTIM_END_320 <= 9'h001;
			HTIM_END_352 <= 9'h001;
			if (DBG_EXT[3]) begin
				HTIM_END_320 <= 9'h002;
				HTIM_END_352 <= 9'h002;
			end
//			
//			if (H352_END_INC) begin
//				HTIM_END_352 <= HTIM_END_352 + 9'd1;
//				if (HTIM_END_352 == 9'd455 - 9'd1) HTIM_END_352 <= 9'd0;
//			end
//			if (H352_END_DEC) begin
//				HTIM_END_352 <= HTIM_END_352 - 9'd1;
//				if (HTIM_END_352 == 9'd0) HTIM_END_352 <= 9'd455 - 9'd1;
//			end
		end
	end
//	wire [8:0] HTIM_END = !REGS.TVMD.HRESO[0] ? HRES_320 - 9'd1 : HRES_352 - 9'd1;
	bit VTIM;
	bit HTIM;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			HTIM <= 0;
			VTIM <= 0;
		end
		else if (!RES_N) begin
			HTIM <= 0;
			VTIM <= 1;
		end
		else if (DOT_CE_R) begin
			if (H_CNT == 9'h18B) begin///////////////////
				HTIM <= 1;
			end else if (H_CNT == HTIM_END_352) begin///////////////////
				HTIM <= 0;
			end
			
			if (H_CNT == 9'h18B - 1) begin
				if (V_CNT == VBL_START - 1) begin
					VTIM <= 1;
				end else if (V_CNT == LAST_LINE) begin
					VTIM <= 0;
				end
			end
		end
//		else if (DOT_CE_F) begin
//			if (H_CNT == 9'h18B) begin
//				HTIM <= 1;
//			end else if (H_CNT == 9'h1A2) begin
//				HTIM <= 0;
//			end
//		end
	end
	assign VTIM_N = ~VTIM;
	assign HTIM_N = ~HTIM;
	
	wire [ 8: 0] NBG_CELLX_START = !HRES[0] ? 9'h18D : 9'h1A9;
	wire [ 8: 0] NBG_FETCH_START = !HRES[0] ? 9'h195 + {HRES[1],3'b000} : 9'h1B1 + {HRES[1],3'b000};
	wire [ 8: 0] NBG_FETCH_END = !HRES[0] ? 9'h131 + {HRES[1],3'b000} : 9'h151 + {HRES[1],3'b000};
	wire [ 8: 0] RBG_FETCH_START = !HRES[0] ? 9'h195 + 9'h010 : 9'h1B1 + 9'h010;
	wire [ 8: 0] RBG_FETCH_END = !HRES[0] ? 9'h131 + 9'h010 : 9'h151 + 9'h010;
	wire [ 8: 0] RPA_FETCH_START = !HRES[0] ? 9'h169 : 9'h185;
	wire [ 8: 0] RPB_FETCH_START = !HRES[0] ? 9'h151 : 9'h16D;
	wire [ 8: 0] RCTA_FETCH_START = !HRES[0] ? 9'h18B : 9'h1A7;
	wire [ 8: 0] RCTB_FETCH_START = !HRES[0] ? 9'h18C : 9'h1A8;
	wire [ 8: 0] LS_FETCH_START = !HRES[0] ? 9'h181 : 9'h19D;
	wire [ 8: 0] LW_FETCH_START = !HRES[0] ? 9'h187 : 9'h1A3;
	wire [ 8: 0] LN_FETCH_START = !HRES[0] ? 9'h189 : 9'h1A5;
	wire [ 8: 0] BS_FETCH_START = !HRES[0] ? 9'h18A : 9'h1A6;
	wire [ 8: 0] NBG_SCREEN_START = !HRES[0] ? 9'h19D : 9'h1B9;
	
	bit  [ 2: 0] CELLX;
	bit          NBG_FETCH;		//Normal screen pattern data fetch time
	bit          NCH_FETCH;		//Normal screen char data fetch time
	bit          NVCS_FETCH;	//Vertical cell scroll data fetch time
	bit          RBG_PRECALC;
	bit          RBG_CALC;
	bit          RBG_FETCH;		//Rotation screen pattern data fetch time
	bit          RCH_FETCH;		//Rotation screen char data fetch time
	bit          LS_FETCH;		//Line scroll table fetch time
	bit          LW_FETCH;		//Line window table fetch time
	bit          RPA_FETCH;		//Rotation parameter A fetch time
	bit          RPB_FETCH;		//Rotation parameter B fetch time
	bit          RCTA_FETCH;	//Rotation coeficient table line A fetch time
	bit          RCTB_FETCH;	//Rotation coeficient table line B fetch time
	bit          CT_FETCH;		//Coefficient table fetch time
	bit          LN_FETCH;		//Line screen table fetch time
	bit          BACK_FETCH;	//Back screen table fetch time
	bit          DOT_FETCH;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			CELLX <= '0;
			NBG_FETCH <= 0;
			NCH_FETCH <= 0;
			NVCS_FETCH <= 0;
			RBG_FETCH <= 0;
			RBG_PRECALC <= 0;
			RBG_CALC <= 0;
			RCTA_FETCH <= 0;
			RCTB_FETCH <= 0;
			LS_FETCH <= 0;
			LW_FETCH <= 0;
			RPA_FETCH <= 0;
			RPB_FETCH <= 0;
			BACK_FETCH <= 0;
			DOT_FETCH <= 0;
		end
		else if (!RES_N) begin
			CELLX <= '0;
			NBG_FETCH <= 0;
			NCH_FETCH <= 0;
			NVCS_FETCH <= 0;
			RBG_FETCH <= 0;
			RBG_PRECALC <= 0;
			RBG_CALC <= 0;
			RCTA_FETCH <= 0;
			RCTB_FETCH <= 0;
			LS_FETCH <= 0;
			LW_FETCH <= 0;
			RPA_FETCH <= 0;
			RPB_FETCH <= 0;
			BACK_FETCH <= 0;
			DOT_FETCH <= 0;
		end
		else if (DOT_CE_R) begin
			CELLX <= CELLX + 1'd1;
			if (H_CNT == NBG_CELLX_START - 1 && (V_CNT < VBL_START || V_CNT == LAST_LINE)) begin
				CELLX <= '0;
			end
			
			if (H_CNT == NBG_FETCH_START - 1 && (V_CNT < VBL_START || V_CNT == LAST_LINE) && DISP) begin
				NBG_FETCH <= 1;
			end else if (H_CNT == NBG_FETCH_END) begin
				NBG_FETCH <= 0;
			end
			if (H_CNT == NBG_FETCH_START + 4 - 1 && (V_CNT < VBL_START || V_CNT == LAST_LINE) && DISP) begin
				NCH_FETCH <= 1;
			end else if (H_CNT == NBG_FETCH_END + 4) begin
				NCH_FETCH <= 0;
			end
			if (H_CNT == NBG_FETCH_START - 1 - 8 && (V_CNT < VBL_START || V_CNT == LAST_LINE) && DISP) begin
				NVCS_FETCH <= 1;
			end else if (H_CNT == NBG_FETCH_END - 8) begin
				NVCS_FETCH <= 0;
			end
			
			if (H_CNT == RBG_FETCH_START - 1 - 4 && (V_CNT < VBL_START || V_CNT == LAST_LINE) && DISP) begin
				CT_FETCH <= 1;
			end else if (H_CNT == RBG_FETCH_END - 4) begin
				CT_FETCH <= 0;
			end
			if (H_CNT == RBG_FETCH_START - 1 - 2 && (V_CNT < VBL_START || V_CNT == LAST_LINE)) begin
				RBG_PRECALC <= 1;
			end else if (H_CNT == RBG_FETCH_END - 2) begin
				RBG_PRECALC <= 0;
			end
			if (H_CNT == RBG_FETCH_START - 1 - 1 && (V_CNT < VBL_START || V_CNT == LAST_LINE)) begin
				RBG_CALC <= 1;
			end else if (H_CNT == RBG_FETCH_END - 1) begin
				RBG_CALC <= 0;
			end
			if (H_CNT == RBG_FETCH_START - 1 && (V_CNT < VBL_START || V_CNT == LAST_LINE) && DISP) begin
				RBG_FETCH <= 1;
			end else if (H_CNT == RBG_FETCH_END) begin
				RBG_FETCH <= 0;
			end
			if (H_CNT == RBG_FETCH_START + 4 - 1 && (V_CNT < VBL_START || V_CNT == LAST_LINE) && DISP) begin
				RCH_FETCH <= 1;
			end else if (H_CNT == RBG_FETCH_END + 4) begin
				RCH_FETCH <= 0;
			end
			
			if (H_CNT == RPA_FETCH_START - 1 && (V_CNT < VBL_START || V_CNT == LAST_LINE) && DISP) begin
				RPA_FETCH <= 1;
			end else if (H_CNT == RPA_FETCH_START + 24 - 1) begin
				RPA_FETCH <= 0;
			end
			if (H_CNT == RPB_FETCH_START - 1 && (V_CNT < VBL_START || V_CNT == LAST_LINE) && DISP) begin
				RPB_FETCH <= 1;
			end else if (H_CNT == RPB_FETCH_START + 24 - 1) begin
				RPB_FETCH <= 0;
			end
			
			if (H_CNT == RCTA_FETCH_START - 1 && (V_CNT < VBL_START || V_CNT == LAST_LINE) && DISP) begin
				RCTA_FETCH <= 1;
			end else if (H_CNT == RCTA_FETCH_START) begin
				RCTA_FETCH <= 0;
			end
			if (H_CNT == RCTB_FETCH_START - 1 && (V_CNT < VBL_START || V_CNT == LAST_LINE) && DISP) begin
				RCTB_FETCH <= 1;
			end else if (H_CNT == RCTB_FETCH_START) begin
				RCTB_FETCH <= 0;
			end
			
			if (H_CNT == LS_FETCH_START - 1 && (V_CNT < VBL_START || V_CNT == LAST_LINE) && DISP) begin
				LS_FETCH <= 1;
			end else if (H_CNT == LS_FETCH_START + 6 - 1) begin
				LS_FETCH <= 0;
			end
			
			if (H_CNT == LW_FETCH_START - 1 && (V_CNT < VBL_START || V_CNT == LAST_LINE) && DISP) begin
				LW_FETCH <= 1;
			end else if (H_CNT == LW_FETCH_START + 2 - 1) begin
				LW_FETCH <= 0;
			end
			
			if (H_CNT == LN_FETCH_START - 1 && (V_CNT < VBL_START || V_CNT == LAST_LINE) && DISP) begin
				LN_FETCH <= 1;
			end else begin
				LN_FETCH <= 0;
			end
			
			if (H_CNT == BS_FETCH_START - 1 && (V_CNT < VBL_START || V_CNT == LAST_LINE) && DISP) begin
				BACK_FETCH <= 1;
			end else begin
				BACK_FETCH <= 0;
			end
			
			if (H_CNT == 9'd2 - 1 && V_CNT < VBL_START) begin
				DOT_FETCH <= 1;
			end else if (H_CNT == 9'd2 + 9'd352 - 1) begin
				DOT_FETCH <= 0;
			end
		end
	end
			
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			SCRNX0 <= 0;
		end
		else if (DOT_CE_F) begin
			SCRNX0 <= 1;
		end
		else if (DOT_CE_R) begin
			SCRNX0 <= 0;
			SCRNX <= SCRNX + 1'd1;
			if (H_CNT == NBG_SCREEN_START - 1 && (V_CNT < VBL_START || V_CNT == LAST_LINE)) begin
				SCRNX <= '0;
			end
			
			if (H_CNT == LS_FETCH_START - 1 && (V_CNT < VBL_START || V_CNT == LAST_LINE)) begin
				SCRNY <= SCRNY + 1'd1;
				if (V_CNT == LAST_LINE) begin
					SCRNY <= '0;
				end
			end
		end
	end
	wire [8:0] WSCRNY = !INTERLACE ? SCRNY : {SCRNY[7:0],ODD};
	
	always_comb begin
		bit [3:0] VCPA0; 
		bit [3:0] VCPA1; 
		bit [3:0] VCPB0; 
		bit [3:0] VCPB1;
		bit [1:0] RDBSA0; 
		bit [1:0] RDBSA1; 
		bit [1:0] RDBSB0; 
		bit [1:0] RDBSB1;
		
		case (CELLX[2:0] & {~HRES[1],2'b11})
			T0: begin VCPA0 = REGS.CYCA0L[15:12]; VCPA1 = REGS.RAMCTL.VRAMD ? REGS.CYCA1L[15:12] : REGS.CYCA0L[15:12]; 
			          VCPB0 = REGS.CYCB0L[15:12]; VCPB1 = REGS.RAMCTL.VRBMD ? REGS.CYCB1L[15:12] : REGS.CYCB0L[15:12]; end
			T1: begin VCPA0 = REGS.CYCA0L[11: 8]; VCPA1 = REGS.RAMCTL.VRAMD ? REGS.CYCA1L[11: 8] : REGS.CYCA0L[11: 8]; 
			          VCPB0 = REGS.CYCB0L[11: 8]; VCPB1 = REGS.RAMCTL.VRBMD ? REGS.CYCB1L[11: 8] : REGS.CYCB0L[11: 8]; end
			T2: begin VCPA0 = REGS.CYCA0L[ 7: 4]; VCPA1 = REGS.RAMCTL.VRAMD ? REGS.CYCA1L[ 7: 4] : REGS.CYCA0L[ 7: 4]; 
			          VCPB0 = REGS.CYCB0L[ 7: 4]; VCPB1 = REGS.RAMCTL.VRBMD ? REGS.CYCB1L[ 7: 4] : REGS.CYCB0L[ 7: 4]; end
			T3: begin VCPA0 = REGS.CYCA0L[ 3: 0]; VCPA1 = REGS.RAMCTL.VRAMD ? REGS.CYCA1L[ 3: 0] : REGS.CYCA0L[ 3: 0]; 
			          VCPB0 = REGS.CYCB0L[ 3: 0]; VCPB1 = REGS.RAMCTL.VRBMD ? REGS.CYCB1L[ 3: 0] : REGS.CYCB0L[ 3: 0]; end
			T4: begin VCPA0 = REGS.CYCA0U[15:12]; VCPA1 = REGS.RAMCTL.VRAMD ? REGS.CYCA1U[15:12] : REGS.CYCA0U[15:12]; 
			          VCPB0 = REGS.CYCB0U[15:12]; VCPB1 = REGS.RAMCTL.VRBMD ? REGS.CYCB1U[15:12] : REGS.CYCB0U[15:12]; end
			T5: begin VCPA0 = REGS.CYCA0U[11: 8]; VCPA1 = REGS.RAMCTL.VRAMD ? REGS.CYCA1U[11: 8] : REGS.CYCA0U[11: 8]; 
			          VCPB0 = REGS.CYCB0U[11: 8]; VCPB1 = REGS.RAMCTL.VRBMD ? REGS.CYCB1U[11: 8] : REGS.CYCB0U[11: 8]; end
			T6: begin VCPA0 = REGS.CYCA0U[ 7: 4]; VCPA1 = REGS.RAMCTL.VRAMD ? REGS.CYCA1U[ 7: 4] : REGS.CYCA0U[ 7: 4]; 
			          VCPB0 = REGS.CYCB0U[ 7: 4]; VCPB1 = REGS.RAMCTL.VRBMD ? REGS.CYCB1U[ 7: 4] : REGS.CYCB0U[ 7: 4]; end
			T7: begin VCPA0 = REGS.CYCA0U[ 3: 0]; VCPA1 = REGS.RAMCTL.VRAMD ? REGS.CYCA1U[ 3: 0] : REGS.CYCA0U[ 3: 0]; 
			          VCPB0 = REGS.CYCB0U[ 3: 0]; VCPB1 = REGS.RAMCTL.VRBMD ? REGS.CYCB1U[ 3: 0] : REGS.CYCB0U[ 3: 0]; end
		endcase
		
		RDBSA0 = REGS.RAMCTL.RDBSA0;
		RDBSA1 = REGS.RAMCTL.VRAMD ? REGS.RAMCTL.RDBSA1 : REGS.RAMCTL.RDBSA0;
		RDBSB0 = REGS.RAMCTL.RDBSB0;
		RDBSB1 = REGS.RAMCTL.VRBMD ? REGS.RAMCTL.RDBSB1 : REGS.RAMCTL.RDBSB0;
			
		VA_PIPE[0].NxA0PN[0] = VCPA0 == VCP_N0PN & (REGS.RAMCTL.RDBSA0 == 2'b00 | !REGS.BGON.R0ON)                   & NBG_FETCH & REGS.BGON.N0ON;
		VA_PIPE[0].NxA1PN[0] = VCPA1 == VCP_N0PN & (REGS.RAMCTL.RDBSA1 == 2'b00 | !REGS.BGON.R0ON)                   & NBG_FETCH & REGS.BGON.N0ON;
		VA_PIPE[0].NxB0PN[0] = VCPB0 == VCP_N0PN & (REGS.RAMCTL.RDBSB0 == 2'b00 | !REGS.BGON.R0ON) & !REGS.BGON.R1ON & NBG_FETCH & REGS.BGON.N0ON;
		VA_PIPE[0].NxB1PN[0] = VCPB1 == VCP_N0PN & (REGS.RAMCTL.RDBSB1 == 2'b00 | !REGS.BGON.R0ON) & !REGS.BGON.R1ON & NBG_FETCH & REGS.BGON.N0ON;
		VA_PIPE[0].NxA0PN[1] = VCPA0 == VCP_N1PN & (REGS.RAMCTL.RDBSA0 == 2'b00 | !REGS.BGON.R0ON)                   & NBG_FETCH & REGS.BGON.N1ON;
		VA_PIPE[0].NxA1PN[1] = VCPA1 == VCP_N1PN & (REGS.RAMCTL.RDBSA1 == 2'b00 | !REGS.BGON.R0ON)                   & NBG_FETCH & REGS.BGON.N1ON;
		VA_PIPE[0].NxB0PN[1] = VCPB0 == VCP_N1PN & (REGS.RAMCTL.RDBSB0 == 2'b00 | !REGS.BGON.R0ON) & !REGS.BGON.R1ON & NBG_FETCH & REGS.BGON.N1ON;
		VA_PIPE[0].NxB1PN[1] = VCPB1 == VCP_N1PN & (REGS.RAMCTL.RDBSB1 == 2'b00 | !REGS.BGON.R0ON) & !REGS.BGON.R1ON & NBG_FETCH & REGS.BGON.N1ON;
		VA_PIPE[0].NxA0PN[2] = VCPA0 == VCP_N2PN & (REGS.RAMCTL.RDBSA0 == 2'b00 | !REGS.BGON.R0ON)                   & NBG_FETCH & REGS.BGON.N2ON;
		VA_PIPE[0].NxA1PN[2] = VCPA1 == VCP_N2PN & (REGS.RAMCTL.RDBSA1 == 2'b00 | !REGS.BGON.R0ON)                   & NBG_FETCH & REGS.BGON.N2ON;
		VA_PIPE[0].NxB0PN[2] = VCPB0 == VCP_N2PN & (REGS.RAMCTL.RDBSB0 == 2'b00 | !REGS.BGON.R0ON) & !REGS.BGON.R1ON & NBG_FETCH & REGS.BGON.N2ON;
		VA_PIPE[0].NxB1PN[2] = VCPB1 == VCP_N2PN & (REGS.RAMCTL.RDBSB1 == 2'b00 | !REGS.BGON.R0ON) & !REGS.BGON.R1ON & NBG_FETCH & REGS.BGON.N2ON;
		VA_PIPE[0].NxA0PN[3] = VCPA0 == VCP_N3PN & (REGS.RAMCTL.RDBSA0 == 2'b00 | !REGS.BGON.R0ON)                   & NBG_FETCH & REGS.BGON.N3ON;
		VA_PIPE[0].NxA1PN[3] = VCPA1 == VCP_N3PN & (REGS.RAMCTL.RDBSA1 == 2'b00 | !REGS.BGON.R0ON)                   & NBG_FETCH & REGS.BGON.N3ON;
		VA_PIPE[0].NxB0PN[3] = VCPB0 == VCP_N3PN & (REGS.RAMCTL.RDBSB0 == 2'b00 | !REGS.BGON.R0ON) & !REGS.BGON.R1ON & NBG_FETCH & REGS.BGON.N3ON;
		VA_PIPE[0].NxB1PN[3] = VCPB1 == VCP_N3PN & (REGS.RAMCTL.RDBSB1 == 2'b00 | !REGS.BGON.R0ON) & !REGS.BGON.R1ON & NBG_FETCH & REGS.BGON.N3ON;
		
		VA_PIPE[0].NxA0CH[0] = VCPA0 == VCP_N0CH & (REGS.RAMCTL.RDBSA0 == 2'b00 | !REGS.BGON.R0ON)                   & NCH_FETCH & REGS.BGON.N0ON;
		VA_PIPE[0].NxA1CH[0] = VCPA1 == VCP_N0CH & (REGS.RAMCTL.RDBSA1 == 2'b00 | !REGS.BGON.R0ON)                   & NCH_FETCH & REGS.BGON.N0ON;
		VA_PIPE[0].NxB0CH[0] = VCPB0 == VCP_N0CH & (REGS.RAMCTL.RDBSB0 == 2'b00 | !REGS.BGON.R0ON) & !REGS.BGON.R1ON & NCH_FETCH & REGS.BGON.N0ON;
		VA_PIPE[0].NxB1CH[0] = VCPB1 == VCP_N0CH & (REGS.RAMCTL.RDBSB1 == 2'b00 | !REGS.BGON.R0ON) & !REGS.BGON.R1ON & NCH_FETCH & REGS.BGON.N0ON;
		VA_PIPE[0].NxA0CH[1] = VCPA0 == VCP_N1CH & (REGS.RAMCTL.RDBSA0 == 2'b00 | !REGS.BGON.R0ON)                   & NCH_FETCH & REGS.BGON.N1ON;
		VA_PIPE[0].NxA1CH[1] = VCPA1 == VCP_N1CH & (REGS.RAMCTL.RDBSA1 == 2'b00 | !REGS.BGON.R0ON)                   & NCH_FETCH & REGS.BGON.N1ON;
		VA_PIPE[0].NxB0CH[1] = VCPB0 == VCP_N1CH & (REGS.RAMCTL.RDBSB0 == 2'b00 | !REGS.BGON.R0ON) & !REGS.BGON.R1ON & NCH_FETCH & REGS.BGON.N1ON;
		VA_PIPE[0].NxB1CH[1] = VCPB1 == VCP_N1CH & (REGS.RAMCTL.RDBSB1 == 2'b00 | !REGS.BGON.R0ON) & !REGS.BGON.R1ON & NCH_FETCH & REGS.BGON.N1ON;
		VA_PIPE[0].NxA0CH[2] = VCPA0 == VCP_N2CH & (REGS.RAMCTL.RDBSA0 == 2'b00 | !REGS.BGON.R0ON)                   & NCH_FETCH & REGS.BGON.N2ON;
		VA_PIPE[0].NxA1CH[2] = VCPA1 == VCP_N2CH & (REGS.RAMCTL.RDBSA1 == 2'b00 | !REGS.BGON.R0ON)                   & NCH_FETCH & REGS.BGON.N2ON;
		VA_PIPE[0].NxB0CH[2] = VCPB0 == VCP_N2CH & (REGS.RAMCTL.RDBSB0 == 2'b00 | !REGS.BGON.R0ON) & !REGS.BGON.R1ON & NCH_FETCH & REGS.BGON.N2ON;
		VA_PIPE[0].NxB1CH[2] = VCPB1 == VCP_N2CH & (REGS.RAMCTL.RDBSB1 == 2'b00 | !REGS.BGON.R0ON) & !REGS.BGON.R1ON & NCH_FETCH & REGS.BGON.N2ON;
		VA_PIPE[0].NxA0CH[3] = VCPA0 == VCP_N3CH & (REGS.RAMCTL.RDBSA0 == 2'b00 | !REGS.BGON.R0ON)                   & NCH_FETCH & REGS.BGON.N3ON;
		VA_PIPE[0].NxA1CH[3] = VCPA1 == VCP_N3CH & (REGS.RAMCTL.RDBSA1 == 2'b00 | !REGS.BGON.R0ON)                   & NCH_FETCH & REGS.BGON.N3ON;
		VA_PIPE[0].NxB0CH[3] = VCPB0 == VCP_N3CH & (REGS.RAMCTL.RDBSB0 == 2'b00 | !REGS.BGON.R0ON) & !REGS.BGON.R1ON & NCH_FETCH & REGS.BGON.N3ON;
		VA_PIPE[0].NxB1CH[3] = VCPB1 == VCP_N3CH & (REGS.RAMCTL.RDBSB1 == 2'b00 | !REGS.BGON.R0ON) & !REGS.BGON.R1ON & NCH_FETCH & REGS.BGON.N3ON;
		
		VA_PIPE[0].NxA0VS[0] = VCPA0 == VCP_N0VS & (REGS.RAMCTL.RDBSA0 == 2'b00 | !REGS.BGON.R0ON)                   & NVCS_FETCH & REGS.BGON.N0ON;
		VA_PIPE[0].NxA1VS[0] = VCPA1 == VCP_N0VS & (REGS.RAMCTL.RDBSA1 == 2'b00 | !REGS.BGON.R0ON)                   & NVCS_FETCH & REGS.BGON.N0ON;
		VA_PIPE[0].NxB0VS[0] = VCPB0 == VCP_N0VS & (REGS.RAMCTL.RDBSB0 == 2'b00 | !REGS.BGON.R0ON) & !REGS.BGON.R1ON & NVCS_FETCH & REGS.BGON.N0ON;
		VA_PIPE[0].NxB1VS[0] = VCPB1 == VCP_N0VS & (REGS.RAMCTL.RDBSB1 == 2'b00 | !REGS.BGON.R0ON) & !REGS.BGON.R1ON & NVCS_FETCH & REGS.BGON.N0ON;
		VA_PIPE[0].NxA0VS[1] = VCPA0 == VCP_N1VS & (REGS.RAMCTL.RDBSA0 == 2'b00 | !REGS.BGON.R0ON)                   & NVCS_FETCH & REGS.BGON.N1ON;
		VA_PIPE[0].NxA1VS[1] = VCPA1 == VCP_N1VS & (REGS.RAMCTL.RDBSA1 == 2'b00 | !REGS.BGON.R0ON)                   & NVCS_FETCH & REGS.BGON.N1ON;
		VA_PIPE[0].NxB0VS[1] = VCPB0 == VCP_N1VS & (REGS.RAMCTL.RDBSB0 == 2'b00 | !REGS.BGON.R0ON) & !REGS.BGON.R1ON & NVCS_FETCH & REGS.BGON.N1ON;
		VA_PIPE[0].NxB1VS[1] = VCPB1 == VCP_N1VS & (REGS.RAMCTL.RDBSB1 == 2'b00 | !REGS.BGON.R0ON) & !REGS.BGON.R1ON & NVCS_FETCH & REGS.BGON.N1ON;
		
		VA_PIPE[0].NxA0CPU = ((VCPA0 == VCP_CPU | (VCPA0 == VCP_NA & VCPA1 == VCP_NA)) & ~LS_FETCH & ~RPA_FETCH & ~BACK_FETCH & ~LN_FETCH) | VBLANK2 | ~DISP;
		VA_PIPE[0].NxA1CPU = ((VCPA1 == VCP_CPU | (VCPA0 == VCP_NA & VCPA1 == VCP_NA)) & ~LS_FETCH & ~RPA_FETCH & ~BACK_FETCH & ~LN_FETCH) | VBLANK2 | ~DISP;
		VA_PIPE[0].NxB0CPU = ((VCPB0 == VCP_CPU | (VCPB0 == VCP_NA & VCPB1 == VCP_NA)) & ~LS_FETCH & ~RPA_FETCH & ~BACK_FETCH & ~LN_FETCH) | VBLANK2 | ~DISP;
		VA_PIPE[0].NxB1CPU = ((VCPB1 == VCP_CPU | (VCPB0 == VCP_NA & VCPB1 == VCP_NA)) & ~LS_FETCH & ~RPA_FETCH & ~BACK_FETCH & ~LN_FETCH) | VBLANK2 | ~DISP;
		
		VA_PIPE[0].RxA0PN[0] = RDBSA0 == 2'b10 & REGS.BGON.R0ON & RBG_FETCH;
		VA_PIPE[0].RxA1PN[0] = RDBSA1 == 2'b10 & REGS.BGON.R0ON & RBG_FETCH;
		VA_PIPE[0].RxB0PN[0] = RDBSB0 == 2'b10 & REGS.BGON.R0ON & RBG_FETCH;
		VA_PIPE[0].RxB1PN[0] = RDBSB1 == 2'b10 & REGS.BGON.R0ON & RBG_FETCH;
		VA_PIPE[0].RxA0PN[1] = 0;
		VA_PIPE[0].RxA1PN[1] = 0;
		VA_PIPE[0].RxB0PN[1] = 0;
		VA_PIPE[0].RxB1PN[1] =                   REGS.BGON.R1ON & RBG_FETCH;
		
		VA_PIPE[0].RxA0CH[0] = RDBSA0 == 2'b11 & REGS.BGON.R0ON & RCH_FETCH;
		VA_PIPE[0].RxA1CH[0] = RDBSA1 == 2'b11 & REGS.BGON.R0ON & RCH_FETCH;
		VA_PIPE[0].RxB0CH[0] = RDBSB0 == 2'b11 & REGS.BGON.R0ON & RCH_FETCH;
		VA_PIPE[0].RxB1CH[0] = RDBSB1 == 2'b11 & REGS.BGON.R0ON & RCH_FETCH;
		VA_PIPE[0].RxA0CH[1] = 0;
		VA_PIPE[0].RxA1CH[1] = 0;
		VA_PIPE[0].RxB0CH[1] =                   REGS.BGON.R1ON & RCH_FETCH;
		VA_PIPE[0].RxB1CH[1] = 0;
		
		VA_PIPE[0].RxA0CT[0] = RDBSA0 == 2'b01 & REGS.BGON.R0ON & CT_FETCH;
		VA_PIPE[0].RxA1CT[0] = RDBSA1 == 2'b01 & REGS.BGON.R0ON & CT_FETCH;
		VA_PIPE[0].RxB0CT[0] = RDBSB0 == 2'b01 & REGS.BGON.R0ON & CT_FETCH;
		VA_PIPE[0].RxB1CT[0] = RDBSB1 == 2'b01 & REGS.BGON.R0ON & CT_FETCH;
		VA_PIPE[0].RxA0CT[1] = 0;
		VA_PIPE[0].RxA1CT[1] = 0;
		VA_PIPE[0].RxB0CT[1] = 0;
		VA_PIPE[0].RxB1CT[1] = 0;
		
		VA_PIPE[0].RxCRCT[0] = REGS.RAMCTL.CRKTE & REGS.BGON.R0ON & CT_FETCH;
		VA_PIPE[0].RxCRCT[1] = 0;
		
		VA_PIPE[0].RxCTTP[0] = RxCTTP[0];
		VA_PIPE[0].RxCTTP[1] = RxCTTP[1];
		
		VA_PIPE[0].LS = LS_FETCH;
		VA_PIPE[0].LS_POS = LS_POS;
		VA_PIPE[0].LW = LW_FETCH;
		VA_PIPE[0].LW_POS = LW_POS;
		VA_PIPE[0].RPA = RPA_FETCH;
		VA_PIPE[0].RPB = RPB_FETCH;
		VA_PIPE[0].RCTA = RCTA_FETCH;
		VA_PIPE[0].RCTB = RCTB_FETCH;
		VA_PIPE[0].R0RP = REGS.RPMD.RPMD == 2'b10 ? R0RPMSB : R0RP_PIPE[3];
		VA_PIPE[0].RP_POS = RP_POS;
		VA_PIPE[0].BS = BACK_FETCH;
		VA_PIPE[0].LN = LN_FETCH;
//		VA_PIPE[0].RBG = RBG_PREFETCH;
		
		VA_PIPE[0].NxX[0] = NxOFFX[0].INT;
		VA_PIPE[0].NxX[1] = NxOFFX[1].INT;
		VA_PIPE[0].NxX[2] = NxOFFX[2].INT;
		VA_PIPE[0].NxX[3] = NxOFFX[3].INT;
		VA_PIPE[0].NxY[0] = NxOFFY[0].INT;
		VA_PIPE[0].NxY[1] = NxOFFY[1].INT;
		VA_PIPE[0].NxY[2] = NxOFFY[2].INT;
		VA_PIPE[0].NxY[3] = NxOFFY[3].INT;
		VA_PIPE[0].RxX[0] = RxX[0].INT;
		VA_PIPE[0].RxX[1] = RxX[1].INT;
		VA_PIPE[0].RxY[0] = RxY[0].INT;
		VA_PIPE[0].RxY[1] = RxY[1].INT;
	end
	
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			// synopsys translate_off
			VA_PIPE <= '{4{'0}};
			// synopsys translate_on
		end
		else if (DOT_CE_R) begin
			VA_PIPE[1] <= VA_PIPE[0];
			VA_PIPE[2] <= VA_PIPE[1];
			VA_PIPE[3] <= VA_PIPE[2];
			VA_PIPE[4] <= VA_PIPE[3];
		end
	end

	
	VDP2NSxRegs_t NSxREG;
	VDP2RSxRegs_t RSxREG;
	VDP2RPxRegs_t RPxREG;
	
	assign NSxREG = NSxRegs(REGS);
	assign RSxREG = RSxRegs(REGS);
	assign RPxREG = RPxRegs(REGS);
	
	NVRAMAccess_t NBG_A0VA;
	NVRAMAccess_t NBG_A1VA;
	NVRAMAccess_t NBG_B0VA;
	NVRAMAccess_t NBG_B1VA;
	RVRAMAccess_t RBG_A0VA;
	RVRAMAccess_t RBG_A1VA;
	RVRAMAccess_t RBG_B0VA;
	RVRAMAccess_t RBG_B1VA;
	bit       NxLSC;
	always_comb begin
		NBG_A0VA.PN = |VA_PIPE[0].NxA0PN;
		NBG_A0VA.CH = |VA_PIPE[0].NxA0CH;
		NBG_A0VA.VS = |VA_PIPE[0].NxA0VS;
		NBG_A0VA.CPUA = VA_PIPE[0].NxA0CPU /*| (VCPA0 == VCP_NA & ~REGS.RAMCTL.VRAMD)*/;
		NBG_A0VA.CPUD = VA_PIPE[1].NxA0CPU /*| (VCPA0 == VCP_NA & ~REGS.RAMCTL.VRAMD)*/;
		NBG_A0VA.Nx = 2'd0;
		if (VA_PIPE[0].NxA0PN[0] || VA_PIPE[0].NxA0CH[0] || VA_PIPE[0].NxA0VS[0]) NBG_A0VA.Nx = 2'd0;
		if (VA_PIPE[0].NxA0PN[1] || VA_PIPE[0].NxA0CH[1] || VA_PIPE[0].NxA0VS[1]) NBG_A0VA.Nx = 2'd1;
		if (VA_PIPE[0].NxA0PN[2] || VA_PIPE[0].NxA0CH[2])                         NBG_A0VA.Nx = 2'd2;
		if (VA_PIPE[0].NxA0PN[3] || VA_PIPE[0].NxA0CH[3])                         NBG_A0VA.Nx = 2'd3;
		
		NBG_A1VA.PN = |VA_PIPE[0].NxA1PN;
		NBG_A1VA.CH = |VA_PIPE[0].NxA1CH;
		NBG_A1VA.VS = |VA_PIPE[0].NxA1VS;
		NBG_A1VA.CPUA = VA_PIPE[0].NxA0CPU /*| (VCPA0 == VCP_NA & ~REGS.RAMCTL.VRAMD)*/;//???
		NBG_A1VA.CPUD = VA_PIPE[1].NxA0CPU /*| (VCPA0 == VCP_NA & ~REGS.RAMCTL.VRAMD)*/;//???
		NBG_A1VA.Nx = 2'd0;
		if (VA_PIPE[0].NxA1PN[0] || VA_PIPE[0].NxA1CH[0] || VA_PIPE[0].NxA1VS[0]) NBG_A1VA.Nx = 2'd0;
		if (VA_PIPE[0].NxA1PN[1] || VA_PIPE[0].NxA1CH[1] || VA_PIPE[0].NxA1VS[1]) NBG_A1VA.Nx = 2'd1;
		if (VA_PIPE[0].NxA1PN[2] || VA_PIPE[0].NxA1CH[2])                         NBG_A1VA.Nx = 2'd2;
		if (VA_PIPE[0].NxA1PN[3] || VA_PIPE[0].NxA1CH[3])                         NBG_A1VA.Nx = 2'd3;
		
		NBG_B0VA.PN = |VA_PIPE[0].NxB0PN;
		NBG_B0VA.CH = |VA_PIPE[0].NxB0CH;
		NBG_B0VA.VS = |VA_PIPE[0].NxB0VS;
		NBG_B0VA.CPUA = VA_PIPE[0].NxB0CPU /*| (VCPB0 == VCP_NA & ~REGS.RAMCTL.VRBMD)*/;
		NBG_B0VA.CPUD = VA_PIPE[1].NxB0CPU /*| (VCPB0 == VCP_NA & ~REGS.RAMCTL.VRBMD)*/;
		NBG_B0VA.Nx = 2'd0;
		if (VA_PIPE[0].NxB0PN[0] || VA_PIPE[0].NxB0CH[0] || VA_PIPE[0].NxB0VS[0]) NBG_B0VA.Nx = 2'd0;
		if (VA_PIPE[0].NxB0PN[1] || VA_PIPE[0].NxB0CH[1] || VA_PIPE[0].NxB0VS[1]) NBG_B0VA.Nx = 2'd1;
		if (VA_PIPE[0].NxB0PN[2] || VA_PIPE[0].NxB0CH[2])                         NBG_B0VA.Nx = 2'd2;
		if (VA_PIPE[0].NxB0PN[3] || VA_PIPE[0].NxB0CH[3])                         NBG_B0VA.Nx = 2'd3;
		
		
		NBG_B1VA.PN = |VA_PIPE[0].NxB1PN;
		NBG_B1VA.CH = |VA_PIPE[0].NxB1CH;
		NBG_B1VA.VS = |VA_PIPE[0].NxB1VS;
		NBG_B1VA.CPUA = VA_PIPE[0].NxB0CPU /*| (VCPB0 == VCP_NA & ~REGS.RAMCTL.VRBMD)*/;//???
		NBG_B1VA.CPUD = VA_PIPE[1].NxB0CPU /*| (VCPB0 == VCP_NA & ~REGS.RAMCTL.VRBMD)*/;//???
		NBG_B1VA.Nx = 2'd0;
		if (VA_PIPE[0].NxB1PN[0] || VA_PIPE[0].NxB1CH[0] || VA_PIPE[0].NxB1VS[0]) NBG_B1VA.Nx = 2'd0;
		if (VA_PIPE[0].NxB1PN[1] || VA_PIPE[0].NxB1CH[1] || VA_PIPE[0].NxB1VS[1]) NBG_B1VA.Nx = 2'd1;
		if (VA_PIPE[0].NxB1PN[2] || VA_PIPE[0].NxB1CH[2])                         NBG_B1VA.Nx = 2'd2;
		if (VA_PIPE[0].NxB1PN[3] || VA_PIPE[0].NxB1CH[3])                         NBG_B1VA.Nx = 2'd3;
				
		RBG_A0VA.PN = |VA_PIPE[0].RxA0PN;
		RBG_A0VA.CH = |VA_PIPE[0].RxA0CH;
		RBG_A0VA.CT = |VA_PIPE[0].RxA0CT;
		RBG_A0VA.Rx = VA_PIPE[0].RxA0PN[1] | VA_PIPE[0].RxA0CH[1] | VA_PIPE[0].RxA0CT[1];
		
		RBG_A1VA.PN = |VA_PIPE[0].RxA1PN;
		RBG_A1VA.CH = |VA_PIPE[0].RxA1CH;
		RBG_A1VA.CT = |VA_PIPE[0].RxA1CT;
		RBG_A1VA.Rx = VA_PIPE[0].RxA1PN[1] | VA_PIPE[0].RxA1CH[1] | VA_PIPE[0].RxA1CT[1];
		
		RBG_B0VA.PN = |VA_PIPE[0].RxB0PN;
		RBG_B0VA.CH = |VA_PIPE[0].RxB0CH;
		RBG_B0VA.CT = |VA_PIPE[0].RxB0CT;
		RBG_B0VA.Rx = VA_PIPE[0].RxB0PN[1] | VA_PIPE[0].RxB0CH[1] | VA_PIPE[0].RxB0CT[1];
		
		RBG_B1VA.PN = |VA_PIPE[0].RxB1PN;
		RBG_B1VA.CH = |VA_PIPE[0].RxB1CH;
		RBG_B1VA.CT = |VA_PIPE[0].RxB1CT;
		RBG_B1VA.Rx = VA_PIPE[0].RxB1PN[1] | VA_PIPE[0].RxB1CH[1] | VA_PIPE[0].RxB1CT[1];
	end
	
	always_comb begin
		NxOFFX[0] = NX[0] + NSX[0];
		NxOFFX[1] = NX[1] + NSX[1];
		NxOFFX[2] = NX[2] + NSX[2];
		NxOFFX[3] = NX[3] + NSX[3];
		NxOFFY[0] = NY[0] + NSY[0] + NVCSY[0];
		NxOFFY[1] = NY[1] + NSY[1] + NVCSY[1];
		NxOFFY[2] = NY[2] + NSY[2];
		NxOFFY[3] = NY[3] + NSY[3];
	end
`ifdef DEBUG
	assign NxOFFX0_DBG = NxOFFX[0];
	assign NxOFFX1_DBG = NxOFFX[1];
	assign NxOFFX2_DBG = NxOFFX[2];
	assign NxOFFY0_DBG = NxOFFY[0];
	assign NxOFFY1_DBG = NxOFFY[1];
`endif
	
	
	PN_t            NBG0_PN_PIPE[2];
	PN_t            NBG1_PN_PIPE[2];
	PN_t            NBG2_PN_PIPE[2];
	PN_t            NBG3_PN_PIPE[2];
	
	bit  [19: 1] NxPN_ADDR[4];
	bit  [19: 1] RxPN_ADDR[2];
	bit  [19: 1] NxCH_ADDR[4];
	bit  [19: 1] RxCH_ADDR[2];
	bit          RxSCRN_OVER[2];
	bit  [19: 1] NxVS_ADDR;
	bit  [19: 1] NxLS_ADDR[2];
	bit  [19: 1] RxRP_ADDR;
	bit  [19: 1] RxCT_ADDR[2];
	bit  [19: 1] RxCTA_ADDR;
	bit  [19: 1] RxCTB_ADDR;
	bit  [19: 1] LW_ADDR[2];
	bit  [19: 1] BS_ADDR;
	bit  [19: 1] LN_ADDR;
	always_comb begin
		bit PN_RP,CH_RP,CT_RP;
		
		PN_RP = VA_PIPE[0].R0RP;
		CH_RP = VA_PIPE[4].R0RP;
		CT_RP = R0_RP;
		
		NxPN_ADDR[0] = NxPNAddr(NBG_PN_CNT[0], VA_PIPE[0].NxX[0], VA_PIPE[0].NxY[0], NSxREG[0].MP, NSxREG[0].MPn, NSxREG[0].PLSZ, NSxREG[0].CHSZ, NSxREG[0].PNC.NxPNB, NSxREG[0].ZMHF & ~HRES[1], NSxREG[0].ZMQT & ~HRES[1]);
		NxPN_ADDR[1] = NxPNAddr(NBG_PN_CNT[1], VA_PIPE[0].NxX[1], VA_PIPE[0].NxY[1], NSxREG[1].MP, NSxREG[1].MPn, NSxREG[1].PLSZ, NSxREG[1].CHSZ, NSxREG[1].PNC.NxPNB, NSxREG[1].ZMHF & ~HRES[1], NSxREG[1].ZMQT & ~HRES[1]);
		NxPN_ADDR[2] = NxPNAddr(2'b00        , VA_PIPE[0].NxX[2], VA_PIPE[0].NxY[2], NSxREG[2].MP, NSxREG[2].MPn, NSxREG[2].PLSZ, NSxREG[2].CHSZ, NSxREG[2].PNC.NxPNB, 1'b0                     , 1'b0);
		NxPN_ADDR[3] = NxPNAddr(2'b00        , VA_PIPE[0].NxX[3], VA_PIPE[0].NxY[3], NSxREG[3].MP, NSxREG[3].MPn, NSxREG[3].PLSZ, NSxREG[3].CHSZ, NSxREG[3].PNC.NxPNB, 1'b0                     , 1'b0);
		RxPN_ADDR[0] = RxPNAddr(VA_PIPE[0].RxX[PN_RP][11:0], VA_PIPE[0].RxY[PN_RP][11:0],    RPxREG[PN_RP].MP, RPxREG[PN_RP].MPn, RPxREG[PN_RP].PLSZ, RSxREG[0].CHSZ, RSxREG[0].PNC.NxPNB);
		RxPN_ADDR[1] = RxPNAddr(VA_PIPE[0].RxX[    1][11:0], VA_PIPE[0].RxY[    1][11:0],    RPxREG[1    ].MP, RPxREG[1    ].MPn, RPxREG[1    ].PLSZ, RSxREG[1].CHSZ, RSxREG[1].PNC.NxPNB);
		
		NxCH_ADDR[0] = !NSxREG[0].BMEN ? NxCHAddr('{PN_PIPE[2][0],PN_PIPE[2][4]}, NBG_CH_CNT[0], VA_PIPE[4].NxX[0], VA_PIPE[4].NxY[0], NSxREG[0].CHCN, NSxREG[0].CHSZ, NSxREG[0].ZMHF & ~HRES[1], NSxREG[0].ZMQT & ~HRES[1]) :
													NxBMAddr(NSxREG[0].MP,                   NBG_CH_CNT[0], VA_PIPE[4].NxX[0], VA_PIPE[4].NxY[0], NSxREG[0].CHCN, NSxREG[0].BMSZ, NSxREG[0].ZMHF & ~HRES[1], NSxREG[0].ZMQT & ~HRES[1]);
		NxCH_ADDR[1] = !NSxREG[1].BMEN ? NxCHAddr('{PN_PIPE[2][1],PN_PIPE[2][5]}, NBG_CH_CNT[1], VA_PIPE[4].NxX[1], VA_PIPE[4].NxY[1], NSxREG[1].CHCN, NSxREG[1].CHSZ, NSxREG[1].ZMHF & ~HRES[1], NSxREG[1].ZMQT & ~HRES[1]) :
													NxBMAddr(NSxREG[1].MP,                   NBG_CH_CNT[1], VA_PIPE[4].NxX[1], VA_PIPE[4].NxY[1], NSxREG[1].CHCN, NSxREG[1].BMSZ, NSxREG[1].ZMHF & ~HRES[1], NSxREG[1].ZMQT & ~HRES[1]);
//		NxCH_ADDR[2] =                   NxCHAddr('{PN_PIPE[2][2],PN_PIPE[2][2]}, NBG_CH_CNT[2], VA_PIPE[4].NxX[2], VA_PIPE[4].NxY[2], NSxREG[2].CHCN, NSxREG[2].CHSZ, 1'b0                     , 1'b0);
//		NxCH_ADDR[3] =                   NxCHAddr('{PN_PIPE[2][3],PN_PIPE[2][3]}, NBG_CH_CNT[3], VA_PIPE[4].NxX[3], VA_PIPE[4].NxY[3], NSxREG[3].CHCN, NSxREG[3].CHSZ, 1'b0                     , 1'b0);
		NxCH_ADDR[2] =                   NxCHAddr2(NBG2_PN_PIPE, NBG_CH_CNT[2], VA_PIPE[4].NxX[2], VA_PIPE[4].NxY[2], NSxREG[2].CHCN, NSxREG[2].CHSZ, 1'b0                     , 1'b0);
		NxCH_ADDR[3] =                   NxCHAddr2(NBG3_PN_PIPE, NBG_CH_CNT[3], VA_PIPE[4].NxX[3], VA_PIPE[4].NxY[3], NSxREG[3].CHCN, NSxREG[3].CHSZ, 1'b0                     , 1'b0);
		
		RxCH_ADDR[0] = !RSxREG[0].BMEN ? RxCHAddr(RBG_PN_PIPE[2][0], VA_PIPE[4].RxX[CH_RP][11:0], VA_PIPE[4].RxY[CH_RP][11:0], RSxREG[0].CHCN, RSxREG[0].CHSZ) :
													RxBMAddr(RPxREG[CH_RP].MP,  VA_PIPE[4].RxX[CH_RP][11:0], VA_PIPE[4].RxY[CH_RP][11:0], RSxREG[0].CHCN, RSxREG[0].BMSZ);
		RxCH_ADDR[1] =                   RxCHAddr(RBG_PN_PIPE[2][1], VA_PIPE[4].RxX[    1][11:0], VA_PIPE[4].RxY[    1][11:0], RSxREG[1].CHCN, RSxREG[1].CHSZ);
		
		RxSCRN_OVER[0] = RxScreenOver(RPxREG[PN_RP].OVR, VA_PIPE[0].RxX[PN_RP][15:0], VA_PIPE[0].RxY[PN_RP][15:0], RPxREG[PN_RP].PLSZ, RSxREG[0].BMSZ, RSxREG[0].BMEN);
		RxSCRN_OVER[1] = RxScreenOver(RPxREG[    1].OVR, VA_PIPE[0].RxX[    1][15:0], VA_PIPE[0].RxY[    1][15:0], RPxREG[    1].PLSZ, RSxREG[1].BMSZ, RSxREG[1].BMEN);
		
		NxVS_ADDR    = {REGS.VCSTAU.VCSTA,REGS.VCSTAL.VCSTA,1'b0} + {11'h000,VS_OFFS,1'b0};
		
		NxLS_ADDR[0] = NxLSAddr(NSxREG[0].LSTA, LS_TBL_OFFS[0], LS_VAL_OFFS[0]);
		NxLS_ADDR[1] = NxLSAddr(NSxREG[1].LSTA, LS_TBL_OFFS[1], LS_VAL_OFFS[1]);
		
		RxRP_ADDR    = RxRPAddr({REGS.RPTAU.RPTA,REGS.RPTAL.RPTA},{~RP_POS[7],RP_POS[6:2]});
		RxCT_ADDR[0] = RxCTAddr(KAst[CT_RP].INT, RxKA[CT_RP].INT, RPxREG[CT_RP].KTAOS, RPxREG[CT_RP].KDBS);
		RxCT_ADDR[1] = RxCTAddr(KAst[    1].INT, RxKA[    1].INT, RPxREG[    1].KTAOS, RPxREG[    1].KDBS);
		RxCTA_ADDR   = RxCTAddr(KAst[    0].INT, RxKA[    0].INT, RPxREG[    0].KTAOS, RPxREG[    0].KDBS);
		RxCTB_ADDR   = RxCTAddr(KAst[    1].INT, RxKA[    1].INT, RPxREG[    1].KTAOS, RPxREG[    1].KDBS);
		
		LW_ADDR[0]   = LWAddr({REGS.LWTA0U.WxLWTA,REGS.LWTA0L.WxLWTA}, LW_OFFS);
		LW_ADDR[1]   = LWAddr({REGS.LWTA1U.WxLWTA,REGS.LWTA1L.WxLWTA}, LW_OFFS);
		BS_ADDR      = BSAddr({REGS.BKTAU.BKTA,REGS.BKTAL.BKTA}, BS_OFFS, REGS.BKTAU.BKCLMD);
		LN_ADDR      = LNAddr({REGS.LCTAU.LCTA,REGS.LCTAL.LCTA}, LN_OFFS, REGS.LCTAU.LCCLMD);
	end
//	assign NxVS_ADDR0 = NxVS_ADDR[18:1];
		
	
	NxPNCNT_t    NBG_PN_CNT;
	bit          NBG_PN_EN[4];
	NxCHCNT_t    NBG_CH_CNT;
	bit          NBG_CH_EN[4];
	bit  [ 2: 0] LS_POS;
	bit  [ 3: 2] LS_VAL_OFFS[2];
	bit  [12: 2] LS_TBL_OFFS[2];
	bit          LW_POS;
	bit  [ 9: 2] LW_OFFS;
	bit  [ 6: 0] VS_OFFS;
	bit  [ 8: 0] BS_OFFS;
	bit  [ 8: 0] LN_OFFS;
	bit  [ 7: 2] RP_POS;
	bit  [ 1: 0] VRAM_BANK;
	bit          VRAM_WRITE_PEND_CLR;
	bit          VRAM_RRDY;
	bit          VRAM_WRDY;
	bit          VRAM_WLOCK;
	always @(posedge CLK or negedge RST_N) begin
		bit FIFO_EMPTY_OLD;
		bit CS_N_OLD;
//		bit VRAM_WRITE_END;
		
		if (!RST_N) begin
			VRAMA0_A <= '0;
			VRAMA1_A <= '0;
			VRAMB0_A <= '0;
			VRAMB1_A <= '0;
			VRAMA_WE <= '0;
			VRAMB_WE <= '0;
			VRAMA0_RD <= 0;
			VRAMA1_RD <= 0;
			VRAMB0_RD <= 0;
			VRAMB1_RD <= 0;
			NBG_PN_CNT <= '{2{'0}};
			NBG_CH_CNT <= '{4{'0}};
			NBG_CH_EN <= '{4{0}};
			RP_POS <= '0;
			LS_POS <= '0;
			
			VRAM_WRITE_PEND <= 0;
			VRAM_READ_PEND <= 0;
			VRAM_RRDY <= 1;
			VRAM_WRDY <= 1;
			VRAM_WLOCK <= 0;
//			VRAM_WRITE_END <= 0;
		end else begin
			VRAM_WRITE_PEND_CLR = 0;
			if (DOT_CE_F) begin
				VRAMA_WE <= '0;
				VRAMB_WE <= '0;
				VRAMA0_RD <= 0;
				VRAMA1_RD <= 0;
				VRAMB0_RD <= 0;
				VRAMB1_RD <= 0;
				VRAM_READ_PIPE[0] <= 0;
				if (LS_FETCH) begin
					VRAMA0_A <= {1'b0,NxLS_ADDR[LS_POS[2]][16:1]};
					VRAMA1_A <= {     NxLS_ADDR[LS_POS[2]][16:1]};
					VRAMB0_A <= {1'b0,NxLS_ADDR[LS_POS[2]][16:1]};
					VRAMB1_A <= {     NxLS_ADDR[LS_POS[2]][16:1]};
					VRAMA0_RD <= ~NxLS_ADDR[LS_POS[2]][18];
					VRAMA1_RD <= ~NxLS_ADDR[LS_POS[2]][18];
					VRAMB0_RD <=  NxLS_ADDR[LS_POS[2]][18];
					VRAMB1_RD <=  NxLS_ADDR[LS_POS[2]][18];
				end else if (LW_FETCH) begin
					VRAMA0_A <= {1'b0,LW_ADDR[LW_POS][16:1]};
					VRAMA1_A <= {     LW_ADDR[LW_POS][16:1]};
					VRAMB0_A <= {1'b0,LW_ADDR[LW_POS][16:1]};
					VRAMB1_A <= {     LW_ADDR[LW_POS][16:1]};
					VRAMA0_RD <= ~LW_ADDR[LW_POS][18];
					VRAMA1_RD <= ~LW_ADDR[LW_POS][18];
					VRAMB0_RD <=  LW_ADDR[LW_POS][18];
					VRAMB1_RD <=  LW_ADDR[LW_POS][18];
				end else if (RPA_FETCH || RPB_FETCH) begin
					VRAMA0_A <= {1'b0,RxRP_ADDR[16:1]};
					VRAMA1_A <= {     RxRP_ADDR[16:1]};
					VRAMB0_A <= {1'b0,RxRP_ADDR[16:1]};
					VRAMB1_A <= {     RxRP_ADDR[16:1]};
					VRAMA0_RD <= ~RxRP_ADDR[18];
					VRAMA1_RD <= ~RxRP_ADDR[18];
					VRAMB0_RD <=  RxRP_ADDR[18];
					VRAMB1_RD <=  RxRP_ADDR[18];
				end else if (RCTA_FETCH) begin
					VRAMA0_A <= {1'b0,RxCTA_ADDR[16:1]};
					VRAMA1_A <= {     RxCTA_ADDR[16:1]};
					VRAMB0_A <= {1'b0,RxCTA_ADDR[16:1]};
					VRAMB1_A <= {     RxCTA_ADDR[16:1]};
					VRAMA0_RD <= ~RxCTA_ADDR[18];
					VRAMA1_RD <= ~RxCTA_ADDR[18];
					VRAMB0_RD <=  RxCTA_ADDR[18];
					VRAMB1_RD <=  RxCTA_ADDR[18];
				end else if (RCTB_FETCH) begin
					VRAMA0_A <= {1'b0,RxCTB_ADDR[16:1]};
					VRAMA1_A <= {     RxCTB_ADDR[16:1]};
					VRAMB0_A <= {1'b0,RxCTB_ADDR[16:1]};
					VRAMB1_A <= {     RxCTB_ADDR[16:1]};
					VRAMA0_RD <= ~RxCTB_ADDR[18];
					VRAMA1_RD <= ~RxCTB_ADDR[18];
					VRAMB0_RD <=  RxCTB_ADDR[18];
					VRAMB1_RD <=  RxCTB_ADDR[18];
				end else if (BACK_FETCH) begin
					VRAMA0_A <= {1'b0,BS_ADDR[16:1]};
					VRAMA1_A <= {     BS_ADDR[16:1]};
					VRAMB0_A <= {1'b0,BS_ADDR[16:1]};
					VRAMB1_A <= {     BS_ADDR[16:1]};
					VRAMA0_RD <= ~BS_ADDR[18];
					VRAMA1_RD <= ~BS_ADDR[18];
					VRAMB0_RD <=  BS_ADDR[18];
					VRAMB1_RD <=  BS_ADDR[18];
				end else if (LN_FETCH) begin
					VRAMA0_A <= {1'b0,LN_ADDR[16:1]};
					VRAMA1_A <= {     LN_ADDR[16:1]};
					VRAMB0_A <= {1'b0,LN_ADDR[16:1]};
					VRAMB1_A <= {     LN_ADDR[16:1]};
					VRAMA0_RD <= ~LN_ADDR[18];
					VRAMA1_RD <= ~LN_ADDR[18];
					VRAMB0_RD <=  LN_ADDR[18];
					VRAMB1_RD <=  LN_ADDR[18];
				end else if (!DISP || VBLANK2 || (!REGS.BGON.N0ON && !REGS.BGON.N1ON && !REGS.BGON.N2ON && !REGS.BGON.N3ON && !REGS.BGON.R0ON && !REGS.BGON.R1ON) ||
				             !(NBG_FETCH || NCH_FETCH || NVCS_FETCH || RBG_FETCH || RCH_FETCH || CT_FETCH)) begin
					if (VRAM_WRITE_PEND) begin
						VRAMA0_A <= {VRAM_WA[17:2],1'b0};
						VRAMA1_A <= {VRAM_WA[16:2],1'b0};
						VRAMB0_A <= {VRAM_WA[17:2],1'b0};
						VRAMB1_A <= {VRAM_WA[16:2],1'b0};
						VRAMA_D <= VRAM_D;
						VRAMB_D <= VRAM_D;
						VRAMA_WE <= VRAM_WE & {8{~VRAM_WA[18]}};
						VRAMB_WE <= VRAM_WE & {8{ VRAM_WA[18]}};
						VRAM_WRITE_PEND_CLR = 1;
					end else if (VRAM_READ_PEND) begin 
						VRAMA0_A <= {1'b0,VRAM_RA[16:1]};
						VRAMA1_A <= {     VRAM_RA[16:1]};
						VRAMB0_A <= {1'b0,VRAM_RA[16:1]};
						VRAMB1_A <= {     VRAM_RA[16:1]};
						VRAMA0_RD <= VRAMA0_READ;
						VRAMA1_RD <= VRAMA1_READ;
						VRAMB0_RD <= VRAMB0_READ;
						VRAMB1_RD <= VRAMB1_READ;
						VRAM_READ_PEND <= 0;
						VRAM_READ_PIPE[0] <= 1;
					end
				end else begin
					if (NBG_A0VA.PN && NxPN_ADDR[NBG_A0VA.Nx][18:17] == 2'b00) begin
						VRAMA0_A <= {1'b0,NxPN_ADDR[NBG_A0VA.Nx][16:1]};
						VRAMA0_RD <= 1;
					end //else 
					if (NBG_A0VA.CH && NxCH_ADDR[NBG_A0VA.Nx][18:17] == 2'b00) begin
						VRAMA0_A <= {1'b0,NxCH_ADDR[NBG_A0VA.Nx][16:1]};
						VRAMA0_RD <= 1;
					end //else	
					if (NBG_A0VA.VS && NxVS_ADDR[18:17] == 2'b00) begin
						VRAMA0_A <= {1'b0,NxVS_ADDR[16:1]};
						VRAMA0_RD <= 1;
					end //else 
					if (RBG_A0VA.PN && RxPN_ADDR[RBG_A0VA.Rx][18:17] == 2'b00) begin
						VRAMA0_A <= {1'b0,RxPN_ADDR[RBG_A0VA.Rx][16:1]};
						VRAMA0_RD <= 1;
					end //else 
					if (RBG_A0VA.CH && RxCH_ADDR[RBG_A0VA.Rx][18:17] == 2'b00) begin
						VRAMA0_A <= {1'b0,RxCH_ADDR[RBG_A0VA.Rx][16:1]};
						VRAMA0_RD <= 1;
					end //else 
					if (RBG_A0VA.CT && RxCT_ADDR[RBG_A0VA.Rx][18:17] == 2'b00) begin
						VRAMA0_A <= {1'b0,RxCT_ADDR[RBG_A0VA.Rx][16:1]};
						VRAMA0_RD <= 1;
					end
					
					if (NBG_A1VA.PN && NxPN_ADDR[NBG_A1VA.Nx][18:17] == 2'b01) begin
						VRAMA1_A <= {NxPN_ADDR[NBG_A1VA.Nx][16:1]};
						VRAMA1_RD <= 1;
					end //else	
					if (NBG_A1VA.CH && NxCH_ADDR[NBG_A1VA.Nx][18:17] == 2'b01 ) begin
						VRAMA1_A <= {NxCH_ADDR[NBG_A1VA.Nx][16:1]};
						VRAMA1_RD <= 1;
					end //else	
					if (NBG_A1VA.VS && NxVS_ADDR[18:17] == 2'b01) begin
						VRAMA1_A <= {NxVS_ADDR[16:1]};
						VRAMA1_RD <= 1;
					end //else 
					if (RBG_A1VA.PN && RxPN_ADDR[RBG_A1VA.Rx][18:17] == 2'b01) begin
						VRAMA1_A <= {RxPN_ADDR[RBG_A1VA.Rx][16:1]};
						VRAMA1_RD <= 1;
					end //else	
					if (RBG_A1VA.CH && RxCH_ADDR[RBG_A1VA.Rx][18:17] == 2'b01) begin
						VRAMA1_A <= {RxCH_ADDR[RBG_A1VA.Rx][16:1]};
						VRAMA1_RD <= 1;
					end //else 
					if (RBG_A1VA.CT && RxCT_ADDR[RBG_A1VA.Rx][18:17] == 2'b01) begin
						VRAMA1_A <= {RxCT_ADDR[RBG_A1VA.Rx][16:1]};
						VRAMA1_RD <= 1;
					end
					
					if (!NBG_A0VA.PN && !RBG_A0VA.PN && !NBG_A0VA.CH && !RBG_A0VA.CH && !RBG_A0VA.CT && !NBG_A0VA.VS &&
						 !NBG_A1VA.PN && !RBG_A1VA.PN && !NBG_A1VA.CH && !RBG_A1VA.CH && !RBG_A1VA.CT && !NBG_A1VA.VS) begin
						if (/*NBG_A0VA.CPUA &&*/ ((VRAM_READ_PEND && (VRAMA0_READ || VRAMA1_READ)) || (VRAM_WRITE_PEND && !VRAM_WA[18]))) begin
							if (VRAM_WRITE_PEND) begin
								VRAMA0_A <= {VRAM_WA[17:2],1'b0};
								VRAMA_D <= VRAM_D;
								VRAMA_WE <= VRAM_WE;
								VRAM_WRITE_PEND_CLR = 1;
							end else if (VRAM_READ_PEND) begin
								VRAMA0_A <= {1'b0,VRAM_RA[16:1]};
								VRAMA1_A <= {     VRAM_RA[16:1]};
								VRAMA0_RD <= VRAMA0_READ;
								VRAMA1_RD <= VRAMA1_READ;
								VRAM_READ_PIPE[0] <= 1;
								VRAM_READ_PEND <= 0;
							end
						end
					end
					
					if (NBG_B0VA.PN && NxPN_ADDR[NBG_B0VA.Nx][18:17] == 2'b10) begin
						VRAMB0_A <= {1'b0,NxPN_ADDR[NBG_B0VA.Nx][16:1]};
						VRAMB0_RD <= 1;
					end //else	
					if (NBG_B0VA.CH && NxCH_ADDR[NBG_B0VA.Nx][18:17] == 2'b10) begin
						VRAMB0_A <= {1'b0,NxCH_ADDR[NBG_B0VA.Nx][16:1]};
						VRAMB0_RD <= 1;
					end //else	
					if (NBG_B0VA.VS && NxVS_ADDR[18:17] == 2'b10) begin
						VRAMB0_A <= {1'b0,NxVS_ADDR[16:1]};
						VRAMB0_RD <= 1;
					end //else 
					if (RBG_B0VA.PN && RxPN_ADDR[RBG_B0VA.Rx][18:17] == 2'b10) begin
						VRAMB0_A <= {1'b0,RxPN_ADDR[RBG_B0VA.Rx][16:1]};
						VRAMB0_RD <= 1;
					end //else	
					if (RBG_B0VA.CH && RxCH_ADDR[RBG_B0VA.Rx][18:17] == 2'b10) begin
						VRAMB0_A <= {1'b0,RxCH_ADDR[RBG_B0VA.Rx][16:1]};
						VRAMB0_RD <= 1;
					end //else 
					if (RBG_B0VA.CT && RxCT_ADDR[RBG_B0VA.Rx][18:17] == 2'b10) begin
						VRAMB0_A <= {1'b0,RxCT_ADDR[RBG_B0VA.Rx][16:1]};
						VRAMB0_RD <= 1;
					end
					
					if (NBG_B1VA.PN && NxPN_ADDR[NBG_B1VA.Nx][18:17] == 2'b11) begin
						VRAMB1_A <= {NxPN_ADDR[NBG_B1VA.Nx][16:1]};
						VRAMB1_RD <= 1;
					end //else	
					if (NBG_B1VA.CH && NxCH_ADDR[NBG_B1VA.Nx][18:17] == 2'b11) begin
						VRAMB1_A <= {NxCH_ADDR[NBG_B1VA.Nx][16:1]};
						VRAMB1_RD <= 1;
					end //else	
					if (NBG_B1VA.VS && NxVS_ADDR[18:17] == 2'b11) begin
						VRAMB1_A <= {NxVS_ADDR[16:1]};
						VRAMB1_RD <= 1;
					end //else 
					if (RBG_B1VA.PN && RxPN_ADDR[RBG_B1VA.Rx][18:17] == 2'b11) begin
						VRAMB1_A <= {RxPN_ADDR[RBG_B1VA.Rx][16:1]};
						VRAMB1_RD <= 1;
					end //else	
					if (RBG_B1VA.CH && RxCH_ADDR[RBG_B1VA.Rx][18:17] == 2'b11) begin
						VRAMB1_A <= {RxCH_ADDR[RBG_B1VA.Rx][16:1]};
						VRAMB1_RD <= 1;
					end //else 
					if (RBG_B1VA.CT && RxCT_ADDR[RBG_B1VA.Rx][18:17] == 2'b11) begin
						VRAMB1_A <= {RxCT_ADDR[RBG_B1VA.Rx][16:1]};
						VRAMB1_RD <= 1;
					end
					
					if (!NBG_B0VA.PN && !RBG_B0VA.PN && !NBG_B0VA.CH && !RBG_B0VA.CH && !RBG_B0VA.CT && !NBG_B0VA.VS &&
						 !NBG_B1VA.PN && !RBG_B1VA.PN && !NBG_B1VA.CH && !RBG_B1VA.CH && !RBG_B1VA.CT && !NBG_B1VA.VS) begin
						if (/*NBG_B0VA.CPUA &&*/ ((VRAM_READ_PEND && (VRAMB0_READ || VRAMB1_READ)) || (VRAM_WRITE_PEND && VRAM_WA[18]))) begin
							if (VRAM_WRITE_PEND) begin
								VRAMB0_A <= {VRAM_WA[17:2],1'b0};
								VRAMA_D <= VRAM_D;//////////////////////
								VRAMB_D <= VRAM_D;
								VRAMB_WE <= VRAM_WE;
								VRAM_WRITE_PEND_CLR = 1;
							end else if (VRAM_READ_PEND) begin
								VRAMB0_A <= {1'b0,VRAM_RA[16:1]};
								VRAMB1_A <= {     VRAM_RA[16:1]};
								VRAMB0_RD <= VRAMB0_READ;
								VRAMB1_RD <= VRAMB1_READ;
								VRAM_READ_PIPE[0] <= 1;
								VRAM_READ_PEND <= 0;
							end
						end
					end
				end
				VRAM_READ_PIPE[1] <= VRAM_READ_PIPE[0];
			end
			else if (DOT_CE_R) begin
				if (LS_FETCH) begin
					VRAM_BANK <= NxLS_ADDR[LS_POS[2]][18:17];
					
					if ((WSCRNY[2:0] & NxLSSMask(NSxREG[{1'b0,LS_POS[2]}].LSS)) == 3'b000) begin
						case (LS_POS[1:0])
							2'd0: if (NSxREG[{1'b0,LS_POS[2]}].LSCX) LS_VAL_OFFS[LS_POS[2]] <= LS_VAL_OFFS[LS_POS[2]] + 2'd1;
							2'd1: if (NSxREG[{1'b0,LS_POS[2]}].LSCY) LS_VAL_OFFS[LS_POS[2]] <= LS_VAL_OFFS[LS_POS[2]] + 2'd1;
							2'd2:                                    LS_VAL_OFFS[LS_POS[2]] <= 2'd0;
						endcase
						if (LS_POS[1:0] == 2'd2) begin
							LS_TBL_OFFS[LS_POS[2]] <= LS_TBL_OFFS[LS_POS[2]] + NxLSTblSize(NSxREG[{1'b0,LS_POS[2]}].LSCX,NSxREG[{1'b0,LS_POS[2]}].LSCY,NSxREG[{1'b0,LS_POS[2]}].LZMX,~|NSxREG[{1'b0,LS_POS[2]}].LSS&INTERLACE);
						end
					end
					LS_POS <= LS_POS + 3'd1;
					if (LS_POS[1:0] == 2'd2) LS_POS <= LS_POS + 3'd2;
					VS_OFFS <= '0;
				end else if (LW_FETCH) begin
					VRAM_BANK <= LW_ADDR[LW_POS][18:17];
					LW_POS <= ~LW_POS;
					if (LW_POS) LW_OFFS <= LW_OFFS + 8'd1;
				end else if (RPA_FETCH || RPB_FETCH) begin
					RP_POS[6:2] <= RP_POS[6:2] + 5'd1;
					if (RP_POS[6:2] == 5'd23) RP_POS <= {~RP_POS[7],5'd0};
					VRAM_BANK <= RxRP_ADDR[18:17];
				end else if (RCTA_FETCH) begin
					VRAM_BANK <= RxCTA_ADDR[18:17];
				end else if (RCTB_FETCH) begin
					VRAM_BANK <= RxCTB_ADDR[18:17];
				end else if (BACK_FETCH) begin
					BS_OFFS <= BS_OFFS + 9'd1;
					VRAM_BANK <= BS_ADDR[18:17];
				end else if (LN_FETCH) begin
					LN_OFFS <= LN_OFFS + 9'd1;
					VRAM_BANK <= LN_ADDR[18:17];
				end else if (!DISP || VBLANK2 || (!REGS.BGON.N0ON && !REGS.BGON.N1ON && !REGS.BGON.N2ON && !REGS.BGON.N3ON && !REGS.BGON.R0ON && !REGS.BGON.R1ON)) begin
					
				end else if (NBG_FETCH || NCH_FETCH || RBG_FETCH || RCH_FETCH || NVCS_FETCH) begin
					NBG_PN_EN <= '{4{0}};
					NBG_CH_EN <= '{4{0}};
					if (NBG_A0VA.PN) begin
						if (NxPN_ADDR[NBG_A0VA.Nx][18:17] == 2'b00) begin
							NBG_PN_EN[NBG_A0VA.Nx] <= 1;
						end
						if (!NBG_A0VA.Nx[1]) NBG_PN_CNT[NBG_A0VA.Nx] <= NBG_PN_CNT[NBG_A0VA.Nx] + 2'd1;
					end //else 
					if (NBG_A0VA.CH) begin
						if (NxCH_ADDR[NBG_A0VA.Nx][18:17] == 2'b00) begin
							NBG_CH_EN[NBG_A0VA.Nx] <= 1;
						end
						NBG_CH_CNT[NBG_A0VA.Nx] <= NBG_CH_CNT[NBG_A0VA.Nx] + 3'd1;
					end //else 
					if (NBG_A0VA.VS && NxVS_ADDR[18:17] == 2'b00) begin
						VS_OFFS <= VS_OFFS + 1'd1;
					end
					
					if (NBG_A1VA.PN) begin
						if (NxPN_ADDR[NBG_A1VA.Nx][18:17] == 2'b01) begin
							NBG_PN_EN[NBG_A1VA.Nx] <= 1;
						end
						if (!NBG_A1VA.Nx[1]) NBG_PN_CNT[NBG_A1VA.Nx] <= NBG_PN_CNT[NBG_A1VA.Nx] + 2'd1;
					end //else 
					if (NBG_A1VA.CH) begin
						if (NxCH_ADDR[NBG_A1VA.Nx][18:17] == 2'b01) begin
							NBG_CH_EN[NBG_A1VA.Nx] <= 1;
						end
						NBG_CH_CNT[NBG_A1VA.Nx] <= NBG_CH_CNT[NBG_A1VA.Nx] + 3'd1;
					end //else 
					if (NBG_A1VA.VS && NxVS_ADDR[18:17] == 2'b01) begin
						VS_OFFS <= VS_OFFS + 1'd1;
					end
					
					if (NBG_B0VA.PN) begin
						if (NxPN_ADDR[NBG_B0VA.Nx][18:17] == 2'b10) begin
							NBG_PN_EN[NBG_B0VA.Nx] <= 1;
						end
						if (!NBG_B0VA.Nx[1]) NBG_PN_CNT[NBG_B0VA.Nx] <= NBG_PN_CNT[NBG_B0VA.Nx] + 2'd1;
					end //else 
					if (NBG_B0VA.CH) begin
						if (NxCH_ADDR[NBG_B0VA.Nx][18:17] == 2'b10) begin
							NBG_CH_EN[NBG_B0VA.Nx] <= 1;
						end
						NBG_CH_CNT[NBG_B0VA.Nx] <= NBG_CH_CNT[NBG_B0VA.Nx] + 3'd1;
					end //else 
					if (NBG_B0VA.VS && NxVS_ADDR[18:17] == 2'b10) begin
						VS_OFFS <= VS_OFFS + 1'd1;
					end
					
					if (NBG_B1VA.PN) begin
						if (NxPN_ADDR[NBG_B1VA.Nx][18:17] == 2'b11) begin
							NBG_PN_EN[NBG_B1VA.Nx] <= 1;
						end
						if (!NBG_B1VA.Nx[1]) NBG_PN_CNT[NBG_B1VA.Nx] <= NBG_PN_CNT[NBG_B1VA.Nx] + 2'd1;
					end //else 
					if (NBG_B1VA.CH) begin
						if (NxCH_ADDR[NBG_B1VA.Nx][18:17] == 2'b11) begin
							NBG_CH_EN[NBG_B1VA.Nx] <= 1;
						end
						NBG_CH_CNT[NBG_B1VA.Nx] <= NBG_CH_CNT[NBG_B1VA.Nx] + 3'd1;
					end //else 
					if (NBG_B1VA.VS && NxVS_ADDR[18:17] == 2'b11) begin
						VS_OFFS <= VS_OFFS + 1'd1;
					end
				end
				
//				if (((SCRNX[2:0] ^ 3'h4) | {HRES[1],2'b00}) == 3'd7) begin
//					NBG_PN_CNT <= '{2{'0}};
//					NBG_CH_CNT <= '{4{'0}};
//				end
				if (H_CNT == NBG_FETCH_START - 1) begin
					NBG_PN_CNT <= '{2{'0}};
					NBG_CH_CNT <= '{4{'0}};
				end	
				
				if (H_CNT == LS_FETCH_START - 2 && V_CNT == LAST_LINE) begin
					LS_POS <= '0;
					LS_VAL_OFFS <= '{2{'0}};
//					LS_TBL_OFFS <= '{2{'0}};
					LS_TBL_OFFS[0] <= !NSxREG[0].LSS && INTERLACE && ODD ? NxLSTblSize(NSxREG[0].LSCX,NSxREG[0].LSCY,NSxREG[0].LZMX,0) : '0;
					LS_TBL_OFFS[1] <= !NSxREG[1].LSS && INTERLACE && ODD ? NxLSTblSize(NSxREG[1].LSCX,NSxREG[1].LSCY,NSxREG[1].LZMX,0) : '0;
				end
				
				if (LAST_DOT && V_CNT == VRES_NTSC - 2) begin
					LW_POS <= 0;
					LW_OFFS <= '0;
					BS_OFFS <= '0;
					LN_OFFS <= '0;
					RP_POS <= '0;
				end
				
				if (VRAM_READ_PIPE[1]) begin
					VRAMA0_Q <= RA0_Q[31:16];
					VRAMA1_Q <= RA1_Q[31:16];
					VRAMB0_Q <= RB0_Q[31:16];
					VRAMB1_Q <= RB1_Q[31:16];
					VRAM_READ_PIPE[1] <= 0;
					if (!VRAM_RRDY) VRAM_RRDY <= 1;
				end
			end
			
			if (VRAM_REQ && WE_N) begin
				VRAM_RA <= A[18:1];
				VRAM_READ_PEND <= 1;
				VRAM_RRDY <= 0;
			end
			
			if (VRAM_WRITE_PEND_CLR) begin
				VRAM_WRITE_PEND <= 0;
				VRAM_WE <= '0;
				VRAM_WRDY <= 1;
			end
			
			//Write single
			if (VRAM_REQ && !WE_N && !DTEN_N && !BURST) begin
				case (A[2:1])
					2'b00: begin
						VRAM_WA <= A[18:1];
						VRAM_D[63:48] <= DI;
						VRAM_WE[7:6] <= ~{2{WE_N}} & ~DQM;
						VRAM_WRITE_PEND <= 1;
					end
					2'b01: begin
						VRAM_WA <= A[18:1];
						VRAM_D[47:32] <= DI;
						VRAM_WE[5:4] <= ~{2{WE_N}} & ~DQM;
						VRAM_WRITE_PEND <= 1;
					end
					2'b10: begin
						VRAM_WA <= A[18:1];
						VRAM_D[31:16] <= DI;
						VRAM_WE[3:2] <= ~{2{WE_N}} & ~DQM;
						VRAM_WRITE_PEND <= 1;
					end
					2'b11: begin
						VRAM_WA <= A[18:1];
						VRAM_D[15:0] <= DI;
						VRAM_WE[1:0] <= ~{2{WE_N}} & ~DQM;
						VRAM_WRITE_PEND <= 1;
					end
				endcase
				VRAM_WRDY <= 0;
			end
			
			//Write burst
			if (!FIFO_EMPTY && !VRAM_WRITE_PEND) begin
				case (FIFO_A[2:1])
					2'b00: begin
						VRAM_WA <= FIFO_A[18:1];
						VRAM_D[63:48] <= FIFO_D;
						VRAM_WE[7:6] <= 2'b11;//FIFO_DQM;
						VRAM_WRITE_PEND <= FIFO_LAST;
					end
					2'b01: begin
						VRAM_WA <= FIFO_A[18:1];
						VRAM_D[47:32] <= FIFO_D;
						VRAM_WE[5:4] <= 2'b11;//FIFO_DQM;
						VRAM_WRITE_PEND <= FIFO_LAST;
					end
					2'b10: begin
						VRAM_WA <= FIFO_A[18:1];
						VRAM_D[31:16] <= FIFO_D;
						VRAM_WE[3:2] <= 2'b11;//FIFO_DQM;
						VRAM_WRITE_PEND <= FIFO_LAST;
					end
					2'b11: begin
						VRAM_WA <= FIFO_A[18:1];
						VRAM_D[15:0] <= FIFO_D;
						VRAM_WE[1:0] <= 2'b11;//FIFO_DQM;
						VRAM_WRITE_PEND <= 1;
					end
				endcase
			end
			
			CS_N_OLD <= CS_N;
			if (CS_N && !CS_N_OLD) begin
				VRAM_WLOCK <= ~FIFO_EMPTY;
			end
			FIFO_EMPTY_OLD <= FIFO_EMPTY;
			if (FIFO_EMPTY && !FIFO_EMPTY_OLD) begin
				VRAM_WLOCK <= 0;
			end
			
			//debug
`ifdef DEBUG
			if (VRAM_WRITE_PEND) VRAM_WRITE_PEND_CNT <= VRAM_WRITE_PEND_CNT + 1'd1;
			else VRAM_WRITE_PEND_CNT <= '0;
`endif
		end
	end
	
	bit         FIFO_WRREQ;
	bit         FIFO_RDREQ;
	bit [33: 0] FIFO_Q;
	bit         FIFO_EMPTY;
	bit         FIFO_FULL;
	bit         FIFO_LAST;
	VDP2_WRITE_FIFO fifo(CLK, RST_N, {A[18:1],DI}, FIFO_WRREQ, FIFO_RDREQ, FIFO_Q, FIFO_EMPTY, FIFO_FULL, FIFO_LAST);
	assign FIFO_WRREQ = VRAM_REQ & ~WE_N & ~DTEN_N & BURST;
	assign FIFO_RDREQ = ~FIFO_EMPTY & ~VRAM_WRITE_PEND;
	wire [18: 1] FIFO_A = FIFO_Q[33:16];
	wire [15: 0] FIFO_D = FIFO_Q[15:0];
	
	assign RA0_A = VRAMA0_A;
	assign RA1_A = VRAMA1_A;
	assign RA_D = VRAMA_D;
	assign RA_WE = VRAMA_WE;
	assign RA_RD = VRAMA0_RD | VRAMA1_RD;
	
	assign RB0_A = VRAMB0_A;
	assign RB1_A = VRAMB1_A;
	assign RB_D = VRAMB_D;
	assign RB_WE = VRAMB_WE;
	assign RB_RD = VRAMB0_RD | VRAMB1_RD;

	wire [15:0] VRAM_DO = VRAMA0_READ ? VRAMA0_Q :
	                      VRAMA1_READ ? VRAMA1_Q :
							    VRAMB0_READ ? VRAMB0_Q :
								 VRAMB1_Q;
								 
	
	//Scroll data  
	ScrollData_t NX[4];
	ScrollData_t NSX[4];
	ScrollData_t NY[4];
	ScrollData_t NSY[4];
	ScrollData_t NVCSY[2];
	CoordInc_t   LZMX[2];
	always @(posedge CLK or negedge RST_N) begin
		ScrollData_t CX[4];
		bit  [31:0] LS_WD;
		bit         RD0,RD1;
		
		RD0 = ((WSCRNY[2:0] & NxLSSMask(NSxREG[0].LSS)) == 3'b000);
		RD1 = ((WSCRNY[2:0] & NxLSSMask(NSxREG[1].LSS)) == 3'b000);
		
		if (!RST_N) begin
			// synopsys translate_off
			NX <= '{4{'0}};
			NSX <= '{4{'0}};
			NY <= '{4{'0}};
			NSY <= '{4{'0}};
			LZMX <= '{2{'0}};
			// synopsys translate_on
		end
		else begin
			if (DOT_CE_R || (DOT_CE_F & HRES[1])) begin
				if (NBG_FETCH) begin
					CX[0] <= CX[0] + LZMX[0];
					CX[1] <= CX[1] + LZMX[1];
					CX[2] <= CX[2] + 19'h00100;
					CX[3] <= CX[3] + 19'h00100;
				end
			end
			
			if (DOT_CE_R) begin
				if (NBG_FETCH && (CELLX[2:0] | {HRES[1],2'b00}) == 3'd7) begin
					NX[0] <= NX[0] + CX[0] + LZMX[0];
					CX[0] <= '0;
					NX[1] <= NX[1] + CX[1] + LZMX[1];
					CX[1] <= '0;
					NX[2] <= NX[2] + CX[2] + 19'h00100;
					CX[2] <= '0;
					NX[3] <= NX[3] + CX[3] + 19'h00100;
					CX[3] <= '0;
				end
				if (H_CNT == NBG_FETCH_START - 1 || CELLX[2:0] == 3'h7) begin
					NVCSY[0] <= VS[0] & {19{NSxREG[0].VCSC}};
					NVCSY[1] <= VS[1] & {19{NSxREG[1].VCSC}};
				end
				
				if (VA_PIPE[1].LS) begin
					case (VRAM_BANK)
						2'b00: LS_WD = RA0_Q;
						2'b01: LS_WD = RA1_Q;
						2'b10: LS_WD = RB0_Q;
						2'b11: LS_WD = RB1_Q;
					endcase
					
					case (VA_PIPE[1].LS_POS)
						3'b000: begin
							NX[0] <= '0;
							if (!NSxREG[0].LSCX)       begin NSX[0] <= NSxREG[0].SCX;               end
							else if (RD0)              begin NSX[0] <= NSxREG[0].SCX + LS_WD[26:8]; end
							
							NX[2] <= '0;
					      NSX[2] <= NSxREG[2].SCX;
						end
						3'b001: begin
							if (NSxREG[0].LSCY && RD0) begin NSY[0] <= NSxREG[0].SCY + LS_WD[26:8]; 
							                                 NY[0]  <= /*(!INTERLACE || !ODD ?*/ '0 /*: NSxREG[0].ZMY)*/; end
							else if (IS_LAST_LINE)     begin NSY[0] <= NSxREG[0].SCY;
							                                 NY[0]  <= (!INTERLACE || !ODD ? '0 : NSxREG[0].ZMY); end
							else                       begin NY[0]  <= NY[0] + (!INTERLACE ? NSxREG[0].ZMY : NSxREG[0].ZMY<<1); end
							
							if (IS_LAST_LINE)          begin NSY[2] <= NSxREG[2].SCY;
							                                 NY[2]  <= (!INTERLACE || !ODD ? '0 : 19'h00100); end
					      else                       begin NY[2]  <= NY[2] + (!INTERLACE ? 19'h00100 : 19'h00200); end
						end
						3'b010: begin
							if (!NSxREG[0].LZMX)       begin LZMX[0] <= NSxREG[0].ZMX;                           end
							else if (RD0)              begin LZMX[0] <= LS_WD[18:8];                             end
						end
						
						3'b100: begin
							NX[1] <= '0;
							if (!NSxREG[1].LSCX)       begin NSX[1] <= NSxREG[1].SCX;               end
							else if (RD1)              begin NSX[1] <= NSxREG[1].SCX + LS_WD[26:8]; end
							
							NX[3] <= '0;
					      NSX[3] <= NSxREG[3].SCX;
						end
						3'b101: begin
							if (NSxREG[1].LSCY && RD1) begin NSY[1] <= NSxREG[1].SCY + LS_WD[26:8];
							                                 NY[1]  <= /*(!INTERLACE || !ODD ?*/ '0 /*: NSxREG[1].ZMY)*/; end
							else if (IS_LAST_LINE)     begin NSY[1] <= NSxREG[1].SCY;
							                                 NY[1]  <= (!INTERLACE || !ODD ? '0 : NSxREG[1].ZMY); end     
							else                       begin NY[1]  <= NY[1] + (!INTERLACE ? NSxREG[1].ZMY : NSxREG[1].ZMY<<1); end
							
							if (IS_LAST_LINE)          begin NSY[3] <= NSxREG[3].SCY;
							                                 NY[3]  <= (!INTERLACE || !ODD ? '0 : 19'h00100); end
					      else                       begin NY[3]  <= NY[3] + (!INTERLACE ? 19'h00100 : 19'h00200); end
						end
						3'b110: begin
							if (!NSxREG[1].LZMX)       begin LZMX[1] <= NSxREG[1].ZMX;                           end
							else if (RD1)              begin LZMX[1] <= LS_WD[18:8];                             end
						end
					endcase

				end
			end
		end
	end
	
	//Rotation parameters
	ScrnStart_t  RP_Xst;		//00
	ScrnStart_t  RP_Yst;		//04
	ScrnStart_t  RP_Zst;		//08
	ScrnInc_t    RP_DXst;	//0C
	ScrnInc_t    RP_DYst;	//10
	ScrnInc_t    RP_DX;		//14
	ScrnInc_t    RP_DY;		//18
	MatrParam_t  RP_A;		//1C
	MatrParam_t  RP_B;		//20
	MatrParam_t  RP_C;		//24
	MatrParam_t  RP_D;		//28
	MatrParam_t  RP_E;		//2C
	MatrParam_t  RP_F;		//30
	ScrnCoord_t  RP_PX;		//34
	ScrnCoord_t  RP_PY;		//36
	ScrnCoord_t  RP_PZ;		//38
	ScrnCoord_t  RP_CX;		//3C
	ScrnCoord_t  RP_CY;		//3E
	ScrnCoord_t  RP_CZ;		//40
	Shift_t      RP_MX;		//44
	Shift_t      RP_MY;		//48
	Scalling_t   RP_KX[2];	//4C
	Scalling_t   RP_KY[2];	//50
	TblAddr_t    RP_KAst;	//54
	AddrInc_t    RP_DKAst;	//58
	AddrInc_t    RP_DKAx[2];//5C
	RotCoord_t   Xsp[2],Ysp[2];
	RotCoord_t   Xp[2],Yp[2];
	RotCoord_t   dX[2],dY[2];
	RotCoord_t   Xst[2],Yst[2];
	RotAddr_t    KAx[2],KAy[2];
	always @(posedge CLK or negedge RST_N) begin
		bit  [31: 0] RP_WD;
		RotCoord_t   SUBXA,SUBXB;
		RotCoord_t   SUBYA,SUBYB;
		RotCoord_t   MULXA;
		RotCoord_t   MULYA;
		RotCoord_t   SUMX,ACCX;
		RotCoord_t   SUMY,ACCY;
		RotCoord_t   ADD1;
		RotCoord_t   MULT1,MULT2;
		RotCoord_t   RES;
		RotCoord_t   RES_LATCH[4];
		bit          N;
		
		if (!RST_N) begin
			// synopsys translate_off
			// synopsys translate_on
			Xsp <= '{2{RC_NULL}};
			Ysp <= '{2{RC_NULL}};
			Xp <= '{2{RC_NULL}};
			Yp <= '{2{RC_NULL}};
			dX <= '{2{RC_NULL}};
			dY <= '{2{RC_NULL}};
			Xst <= '{2{RC_NULL}};
			Yst <= '{2{RC_NULL}};
		end
		else begin
			if (DOT_CE_R) begin
				N = ~VA_PIPE[1].RP_POS[7];
				case (VRAM_BANK)
					2'b00: RP_WD = RA0_Q;
					2'b01: RP_WD = RA1_Q;
					2'b10: RP_WD = RB0_Q;
					2'b11: RP_WD = RB1_Q;
				endcase
				if (VA_PIPE[1].RPA || VA_PIPE[1].RPB) begin
					case (VA_PIPE[1].RP_POS[6:2])
						5'd00: RP_Xst <= RP_WD;
						5'd01: RP_Yst <= RP_WD;
						5'd02: RP_Zst <= RP_WD;
						5'd03: RP_DXst <= RP_WD;
						5'd04: RP_DYst <= RP_WD;
						5'd05: RP_DX <= RP_WD;
						5'd06: RP_DY <= RP_WD;
						5'd07: RP_A <= RP_WD;
						5'd08: RP_B <= RP_WD;
						5'd09: RP_C <= RP_WD;
						5'd10: RP_D <= RP_WD;
						5'd11: RP_E <= RP_WD;
						5'd12: RP_F <= RP_WD;
						5'd13: {RP_PX,RP_PY} <= RP_WD;
						5'd14: RP_PZ <= RP_WD[31:16];
						5'd15: {RP_CX,RP_CY} <= RP_WD;
						5'd16: RP_CZ <= RP_WD[31:16];
						5'd17: RP_MX <= RP_WD;
						5'd18: RP_MY <= RP_WD;
						5'd19: RP_KX[N] <= RP_WD;
						5'd20: RP_KY[N] <= RP_WD;
						5'd21: RP_KAst <= RP_WD;
						5'd22: RP_DKAst <= RP_WD;
						5'd23: RP_DKAx[N] <= RP_WD;
					endcase
				end
				
				if (VA_PIPE[1].RCTA) begin
					CTD[0] <= CTData(RPxREG[0].KMD, RPxREG[0].KDBS, RP_WD);
				end
				if (VA_PIPE[1].RCTB) begin
					CTD[1] <= CTData(RPxREG[1].KMD, RPxREG[1].KDBS, RP_WD);
				end
				
				if (VA_PIPE[2].RxA0CT[0] || VA_PIPE[2].RxA1CT[0] || VA_PIPE[2].RxB0CT[0] || VA_PIPE[2].RxB1CT[0] || VA_PIPE[2].RxCRCT[0]) begin
					CTD[0] <= RBG_CT_PIPE[0][0];
					if (R0RP_PIPE[2]) CTD[1] <= RBG_CT_PIPE[0][0];
				end
				
				SUMX = $signed(ACCX) + $signed(MultRC(MULXA, ($signed(SUBXA) - $signed(SUBXB))));
				SUMY = $signed(ACCY) + $signed(MultRC(MULYA, ($signed(SUBYA) - $signed(SUBYB))));
				
				ACCX <= SUMX;
				ACCY <= SUMY;
				if (VA_PIPE[1].RPA || VA_PIPE[1].RPB) begin
					case (VA_PIPE[1].RP_POS[6:2])
						5'd04: begin 
							Xst[N] <= $signed(Xst[N]) + $signed(ScrnIncToRC(RP_DXst));
							if (IS_LAST_LINE) begin
								Xst[N] <= ScrnStartToRC(RP_Xst);
							end
						end
						5'd05: begin 
							Yst[N] <= $signed(Yst[N]) + $signed(ScrnIncToRC(RP_DYst));
							if (IS_LAST_LINE) begin
								Yst[N] <= ScrnStartToRC(RP_Yst);
							end
						end
						
						5'd12: begin 																				//sumx = 0 + (A * (О”X - 0)), sumy = 0 + (D * (О”X - 0))
							SUBXA <= ScrnIncToRC(RP_DX); SUBXB <= RC_NULL; 								//sub = О”X - 0
							SUBYA <= ScrnIncToRC(RP_DX); SUBYB <= RC_NULL; 								//sub = О”X - 0
							MULXA <= MatrParamToRC(RP_A);														//multx = A * sub
							MULYA <= MatrParamToRC(RP_D);														//multy = D * sub
							ACCX <= RC_NULL; 																		//accx = 0
							ACCY <= RC_NULL; 																		//accy = 0
						end
						5'd13: begin 																				//sumx = accx + (B * (О”Y - 0)), sumy = 0 + (E * (О”Y - 0))
							SUBXA <= ScrnIncToRC(RP_DY); SUBXB <= RC_NULL; 								//sub = О”Y - 0
							SUBYA <= ScrnIncToRC(RP_DY); SUBYB <= RC_NULL; 								//sub = О”Y - 0
							MULXA <= MatrParamToRC(RP_B);														//multx = B * sub
							MULYA <= MatrParamToRC(RP_E); 													//multy = E * sub
						end
						5'd14: begin 
							dX[N] <= SUMX;																			//dX = accx + multx
							dY[N] <= SUMY;																			//dY = accy + multy
							SUBXA <= Xst[N]; SUBXB <= ScrnCoordToRC(RP_PX);								//sub = Xst - Px
							SUBYA <= Xst[N]; SUBYB <= ScrnCoordToRC(RP_PX);								//sub = Xst - Px
							MULXA <= MatrParamToRC(RP_A);														//multx = A * sub
							MULYA <= MatrParamToRC(RP_D); 													//multy = D * sub
							ACCX <= RC_NULL; 																		//accx = 0
							ACCY <= RC_NULL; 																		//accy = 0
						end
						5'd15: begin 
							SUBXA <= Yst[N]; SUBXB <= ScrnCoordToRC(RP_PY);								//sub = Yst - Py
							SUBYA <= Yst[N]; SUBYB <= ScrnCoordToRC(RP_PY);								//sub = Yst - Py
							MULXA <= MatrParamToRC(RP_B);														//multx = B * sub
							MULYA <= MatrParamToRC(RP_E); 													//multy = E * sub
						end
						5'd16: begin 
							SUBXA <= ScrnStartToRC(RP_Zst); SUBXB <= ScrnCoordToRC(RP_PZ);			//sub = Zst - Pz
							SUBYA <= ScrnStartToRC(RP_Zst); SUBYB <= ScrnCoordToRC(RP_PZ);			//sub = Zst - Pz
							MULXA <= MatrParamToRC(RP_C);														//multx = C * sub
							MULYA <= MatrParamToRC(RP_F); 													//multy = F * sub
						end
						5'd17: begin 
							Xsp[N] <= SUMX;																		//Xsp = accx + multx
							Ysp[N] <= SUMY;																		//Ysp = accy + multy
							SUBXA <= ScrnCoordToRC(RP_PX); SUBXB <= ScrnCoordToRC(RP_CX);			//sub = Px - Cx
							SUBYA <= ScrnCoordToRC(RP_PX); SUBYB <= ScrnCoordToRC(RP_CX);			//sub = Px - Cx
							MULXA <= MatrParamToRC(RP_A); 													//multx = A * sub
							MULYA <= MatrParamToRC(RP_D);														//multy = D * sub
							ACCX <= ScrnCoordToRC(RP_CX); 													//accx = Cx
							ACCY <= ScrnCoordToRC(RP_CY); 													//accy = Cy
						end
						5'd18: begin 
							SUBXA <= ScrnCoordToRC(RP_PY); SUBXB <= ScrnCoordToRC(RP_CY);			//sub = Py - Cy
							SUBYA <= ScrnCoordToRC(RP_PY); SUBYB <= ScrnCoordToRC(RP_CY);			//sub = Py - Cy
							MULXA <= MatrParamToRC(RP_B);														//multx = B * sub
							MULYA <= MatrParamToRC(RP_E);												 		//multy = E * sub
						end
						5'd19: begin 
							SUBXA <= ScrnCoordToRC(RP_PZ); SUBXB <= ScrnCoordToRC(RP_CZ);			//sub = Py - Cy
							SUBYA <= ScrnCoordToRC(RP_PZ); SUBYB <= ScrnCoordToRC(RP_CZ);			//sub = Py - Cy
							MULXA <= MatrParamToRC(RP_C);														//multx = C * sub
							MULYA <= MatrParamToRC(RP_F);														//multy = F * sub
						end
						5'd20: begin 
							SUBXA <= RC_ONE; SUBXB <= RC_NULL;												//sub = 1 - 0
							SUBYA <= RC_ONE; SUBYB <= RC_NULL;												//sub = 1 - 0
							MULXA <= ShiftToRC(RP_MX);															//multx = Mx * 1
							MULYA <= ShiftToRC(RP_MY);															//multy = My * 1
						end
						5'd21: begin 
							Xp[N] <= SUMX;																			//Xp = accx + multx
							Yp[N] <= SUMY;																			//Yp = accy + multy
							SUBXA <= RC_NULL; SUBXB <= RC_NULL;												//
							SUBYA <= RC_NULL; SUBYB <= RC_NULL;												//
							MULXA <= RC_NULL; 																	//
							MULYA <= RC_NULL; 					 												//
							ACCX <= RC_NULL; 																		//accx = 0
							ACCY <= RC_NULL; 																		//accy = 0
						end
						5'd22: begin 
						end
						5'd23: begin
							KAst[N] <= TblAddrToRC(RP_KAst);
							KAy[N] <= $signed(KAy[N]) + $signed(AddrIncToRA(RP_DKAst));
							if (IS_LAST_LINE) begin
								KAy[N] <= '0;
							end
							KAx[N] <= '0;
						end
					endcase
				end
				
				if (VA_PIPE[0].RxA0CT[0] || VA_PIPE[0].RxA1CT[0] || VA_PIPE[0].RxB0CT[0] || VA_PIPE[0].RxB1CT[0] || VA_PIPE[0].RxCRCT[0]) begin
					KAx[0] <= $signed(KAx[0]) + $signed(AddrIncToRA(RP_DKAx[0]));
					KAx[1] <= $signed(KAx[1]) + $signed(AddrIncToRA(RP_DKAx[1]));
				end
				
				if (RBG_PRECALC) begin
					Xsp[0] <= $signed(Xsp[0]) + $signed(dX[0]);
					Ysp[0] <= $signed(Ysp[0]) + $signed(dY[0]);
					Xsp[1] <= $signed(Xsp[1]) + $signed(dX[1]);
					Ysp[1] <= $signed(Ysp[1]) + $signed(dY[1]);
				end
			end
				
			case (DOTCLK_DIV)
				2'd0: begin
					ADD1 = Xp[0];
					if (RPxREG[0].KTE && !RPxREG[0].KMD[0])
						MULT1 = {CTD[0].INT,CTD[0].FRAC};
					else
						MULT1 = ScallingToRC(RP_KX[0]);
					MULT2 = Xsp[0];
				end
				2'd1: begin
					ADD1 = Yp[0];
					if (RPxREG[0].KTE && !RPxREG[0].KMD[1])
						MULT1 = {CTD[0].INT,CTD[0].FRAC};
					else
						MULT1 = ScallingToRC(RP_KY[0]);
					MULT2 = Ysp[0];
				end
				2'd2: begin
					ADD1 = Xp[1];
					if (RPxREG[1].KTE && !RPxREG[1].KMD[0])
						MULT1 = {CTD[1].INT,CTD[1].FRAC};
					else
						MULT1 = ScallingToRC(RP_KX[1]);
					MULT2 = Xsp[1];
				end
				2'd3: begin
					ADD1 = Yp[1];
					if (RPxREG[1].KTE && !RPxREG[1].KMD[1])
						MULT1 = {CTD[1].INT,CTD[1].FRAC};
					else
						MULT1 = ScallingToRC(RP_KY[1]);
					MULT2 = Ysp[1];
				end
			endcase
			RES = $signed(ADD1) + $signed(MultRC(MULT1,MULT2));
			
			if (CE_R) begin
				RES_LATCH[DOTCLK_DIV] <= RES;
			end
			
			if (DOT_CE_R) begin
				if (RBG_CALC) begin
					RxX[0] <= RES_LATCH[0];
					RxY[0] <= RES_LATCH[1];
					RxX[1] <= RES_LATCH[2];
					RxY[1] <= RES;
				end
				RxCTTP[0] <= REGS.RPMD.RPMD == 2'b10 && CTD[0].TP ? CTD[1].TP & RPxREG[1].KTE : CTD[R0RP_PIPE[3]].TP & RPxREG[R0RP_PIPE[3]].KTE;
				RxCTTP[1] <=                                                                    CTD[           1].TP & RPxREG[           1].KTE;
				R0RPMSB <= CTD[0].TP;
			end
`ifdef DEBUG
			RPK_DBG = MULT1;
`endif
		end
	end
	assign RxKA[0] = $signed(KAy[0]) + $signed(KAx[0]);
	assign RxKA[1] = $signed(KAy[1]) + $signed(KAx[1]);
				
	//Rotattion parameter window
	wire RPW0_HIT = W0_HIT_PIPE[3*2];
	wire RPW1_HIT = W1_HIT_PIPE[3*2];
	wire RPW_EN = WinTest(RPW0_HIT ^ REGS.WCTLD.RPW0A, RPW1_HIT ^ REGS.WCTLD.RPW1A, 0, REGS.WCTLD.RPW0E, REGS.WCTLD.RPW1E, 0, REGS.WCTLD.RPLOG);
	
	//Rotattion parameter select
	wire R0_RP = !REGS.RPMD.RPMD[1] ? REGS.RPMD.RPMD[0] : 
	             !REGS.RPMD.RPMD[0] ? 1'b0 : RPW_EN;
					 
	bit          R0RP_PIPE[4];
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			R0RP_PIPE <= '{4{0}};
		end
		else begin
			if (DOT_CE_R) begin
				R0RP_PIPE[0] <= R0_RP;
				for (int i=0; i<3; i++) begin
					R0RP_PIPE[i+1] <= R0RP_PIPE[i];
				end
			end
		end
	end
	
	//Windows
	wire [ 9: 0] WPSX[2] = '{REGS.WPSX0.WxSX,REGS.WPSX1.WxSX};
	wire [ 9: 0] WPEX[2] = '{REGS.WPEX0.WxEX,REGS.WPEX1.WxEX};
	wire         LWE[2] = '{REGS.LWTA0U.WxLWE,REGS.LWTA1U.WxLWE};
	bit  [ 9: 0] WxSX[2];
	bit  [ 9: 0] WxEX[2];
	always @(posedge CLK or negedge RST_N) begin
		bit         N;
		bit  [31:0] LW_WD;
		
		if (!RST_N) begin
			// synopsys translate_off
			WxSX <= '{2{'0}};
			WxEX <= '{2{'0}};
			// synopsys translate_on
		end
		else begin
			if (DOT_CE_R) begin
				if (VA_PIPE[1].LW) begin
					N = VA_PIPE[1].LW_POS;
					case (VRAM_BANK)
						2'b00: LW_WD = RA0_Q;
						2'b01: LW_WD = RA1_Q;
						2'b10: LW_WD = RB0_Q;
						2'b11: LW_WD = RB1_Q;
					endcase
					
					if (LWE[N]) begin
						WxSX[N] <= LW_WD[25:16];
						WxEX[N] <= LW_WD[9:0];
					end else begin
						WxSX[N] <= WPSX[N];
						WxEX[N] <= WPEX[N];
					end 
				end
			end
		end
	end
	wire [ 8: 0] WxSY[2] = '{REGS.WPSY0.WxSY,REGS.WPSY1.WxSY};
	wire [ 8: 0] WxEY[2] = '{REGS.WPEY0.WxEY,REGS.WPEY1.WxEY};
	
	wire W0_HIT = {SCRNX,SCRNX0&HRES[1]} >= {WxSX[0][9:1],WxSX[0][0]&HRES[1]}    && {SCRNX,SCRNX0&HRES[1]} <= {WxEX[0][9:1],WxEX[0][0]&HRES[1]} &&
	              WSCRNY                 >= {WxSY[0][8:1],WxSY[0][0]&~INTERLACE} && WSCRNY                 <= {WxEY[0][8:1],WxEY[0][0]&~INTERLACE} &&
					  WxEX[0] != 10'h3FF;
	wire W1_HIT = {SCRNX,SCRNX0|HRES[1]} >= {WxSX[1][9:1],WxSX[1][0]|HRES[1]}    && {SCRNX,SCRNX0|HRES[1]} <= {WxEX[1][9:1],WxEX[1][0]|HRES[1]} &&
	              WSCRNY                 >= {WxSY[1][8:1],WxSY[1][0]&~INTERLACE} && WSCRNY                 <= {WxEY[1][8:1],WxEY[1][0]&~INTERLACE} &&
					  WxEX[1] != 10'h3FF;
					  
	bit          W0_HIT_PIPE[17*2];
	bit          W1_HIT_PIPE[17*2];
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			// synopsys translate_off
			W0_HIT_PIPE <= '{17*2{0}};
			W1_HIT_PIPE <= '{17*2{0}};
			// synopsys translate_on
		end
		else begin
			if (DOT_CE_R || DOT_CE_F) begin
				W0_HIT_PIPE[0] <= W0_HIT;
				W1_HIT_PIPE[0] <= W1_HIT;
				for (int i=0; i<(17*2)-1; i++) begin
					W0_HIT_PIPE[i+1] <= W0_HIT_PIPE[i];
					W1_HIT_PIPE[i+1] <= W1_HIT_PIPE[i];
				end
			end
		end
	end
	
	//Back & line screen  
	bit  [23: 0] BACK_DC;
	bit  [10: 0] LINE_PAL;
	always @(posedge CLK or negedge RST_N) begin
		bit  [15:0] WD;
		
		if (!RST_N) begin
			BACK_DC <= '0;
			LINE_PAL <= '0;
		end
		else begin
			if (DOT_CE_R) begin
				case (VRAM_BANK)
					2'b00: WD = RA0_Q[31:16];
					2'b01: WD = RA1_Q[31:16];
					2'b10: WD = RB0_Q[31:16];
					2'b11: WD = RB1_Q[31:16];
				endcase
				
				if (VA_PIPE[1].BS) begin
					BACK_DC <= Color555To888(WD[14:0]);
				end
				
				if (VA_PIPE[1].LN) begin
					LINE_PAL <= WD[10:0];
				end
			end
		end
	end
					
	//BG data
	
//	NBGPipeline_t   BG_PIPE;
	PNPipe_t        PN_PIPE;
	CHPipe_t        CH_PIPE;
	CellDotsColor_t NBG_CDC[4];
	CellDotsParam_t NBG_CDP[6];
	RBGPipeline_t   RBG_PIPE;
	RPNPipe_t       RBG_PN_PIPE;
	RCTPipe_t       RBG_CT_PIPE;
	bit             RBG_TP_PIPE[5][2];
	bit  [ 7: 0]    RBG_DC[2][4];
	DotParam_t      RBG_DP[2];
	always @(posedge CLK or negedge RST_N) begin
		bit [31: 0] PN_WD[4];
		bit [31: 0] VS_WD[2];
		bit [31: 0] LS_WD[2];
		bit [ 1: 0] PN_CNT[4];
		bit [ 3: 0] NCNT[4];
		bit         NHF[6];
		bit         NPR[6];
		bit         NCC[6];
		bit [ 6: 0] NPALN[6];
		bit [31: 0] NCH[4];
		bit         NTPON[4];
		bit [ 2: 0] NCHCN[4];
//		bit         NWON[4];
		bit         NEN[4];
		bit [ 2: 0] RCNT[2];
		bit         RHF[2];
		bit         RPR[4];
		bit         RCC[4];
		bit [ 6: 0] RPALN[2];
		bit [31: 0] RCH[2];
		bit         RTPON[2];
//		bit         RWON[2];
		bit [ 2: 0] RCELLX[2];
		bit [31: 0] RPN_WD[2];
		bit [31: 0] RCH_WD[2];
		bit [31: 0] RCT_WD[2];
		bit [31: 0] RBG_CH[2];
		bit         PN_RP;
		bit         CH_RP;
		bit         CT_RP;
		
		
		if (!RST_N) begin
			// synopsys translate_off
			NBG_CDL[0] <= '{8{'0}};
			NBG_CDL[1] <= '{8{'0}};
			NBG_CDL[2] <= '{8{'0}};
			NBG_CDL[3] <= '{8{'0}};
			RBG_CDL[0] <= '{8{'0}};
			RBG_CDL[1] <= '{8{'0}};
			// synopsys translate_on
			VS[0] <= '0; 
			VS[1] <= '0;
		end
		else if (DOT_CE_R) begin
			//NBG0,NBG1,NBG2,NBG3
			for (int i=0; i<4; i++) begin
				BG_PIPE[0].NxPN[i] = VA_PIPE[0].NxA0PN[i] | VA_PIPE[0].NxA1PN[i] | VA_PIPE[0].NxB0PN[i] | VA_PIPE[0].NxB1PN[i];
				BG_PIPE[0].NxPNS[i] = VA_PIPE[0].NxA0PN[i] && NxPN_ADDR[NBG_A0VA.Nx][18:17] == 2'b00 ? 2'd0 : 
									       VA_PIPE[0].NxA1PN[i] && NxPN_ADDR[NBG_A1VA.Nx][18:17] == 2'b01 ? 2'd1 : 
									       VA_PIPE[0].NxB0PN[i] && NxPN_ADDR[NBG_B0VA.Nx][18:17] == 2'b10 ? 2'd2 : 
									       2'd3;
				BG_PIPE[0].NxCH[i] = VA_PIPE[0].NxA0CH[i] | VA_PIPE[0].NxA1CH[i] | VA_PIPE[0].NxB0CH[i] | VA_PIPE[0].NxB1CH[i];
				BG_PIPE[0].NxCHS[i] = VA_PIPE[0].NxA0CH[i] && NxCH_ADDR[NBG_A0VA.Nx][18:17] == 2'b00 ? 2'd0 : 
									       VA_PIPE[0].NxA1CH[i] && NxCH_ADDR[NBG_A1VA.Nx][18:17] == 2'b01 ? 2'd1 : 
									       VA_PIPE[0].NxB0CH[i] && NxCH_ADDR[NBG_B0VA.Nx][18:17] == 2'b10 ? 2'd2 : 
									       2'd3;
				if (i < 2) begin
					BG_PIPE[0].NxVS[i] = VA_PIPE[0].NxA0VS[i] | VA_PIPE[0].NxA1VS[i] | VA_PIPE[0].NxB0VS[i] | VA_PIPE[0].NxB1VS[i];
					BG_PIPE[0].NxVSS[i] = VA_PIPE[0].NxA0VS[i] && NxVS_ADDR[18:17] == 2'b00 ? 2'd0 : 
										       VA_PIPE[0].NxA1VS[i] && NxVS_ADDR[18:17] == 2'b01 ? 2'd1 : 
										       VA_PIPE[0].NxB0VS[i] && NxVS_ADDR[18:17] == 2'b10 ? 2'd2 : 
										       2'd3;		 
					BG_PIPE[0].NxPN_CNT[i] = NBG_PN_CNT[i];
				end
//				BG_PIPE[0].NxPN_EN[i] = NBG_PN_EN[i];
				BG_PIPE[0].NxCH_CNT[i] = NBG_CH_CNT[i];
				BG_PIPE[0].NxCH_EN[i] = NBG_CH_EN[i];

				if (BG_PIPE[1].NxPN[i] && NBG_PN_EN[i]) begin
					case (BG_PIPE[1].NxPNS[i])
						2'd0: PN_WD[i] = RA0_Q;
						2'd1: PN_WD[i] = RA1_Q;
						2'd2: PN_WD[i] = RB0_Q;
						2'd3: PN_WD[i] = RB1_Q;
					endcase
					if (i < 2)
						PN_CNT[i] = BG_PIPE[1].NxPN_CNT[i];
					else
						PN_CNT[i] = 0;
					
					if (NSxREG[i].PNC.NxPNB)
						PN_PIPE[0][{NSxREG[i].ZMHF&PN_CNT[i][0],2'b00}|i] <= PNData(NSxREG[i].PNC, NSxREG[i].CHSZ, NSxREG[i].CHCN, PN_WD[i][31:16]);
					else
						PN_PIPE[0][{NSxREG[i].ZMHF&PN_CNT[i][0],2'b00}|i] <= PN_WD[i];
				end
				
				if (i < 2) begin
					if (BG_PIPE[1].NxVS[i]) begin
						case (BG_PIPE[1].NxVSS[i])
							2'd0: VS_WD[i] = RA0_Q;
							2'd1: VS_WD[i] = RA1_Q;
							2'd2: VS_WD[i] = RB0_Q;
							2'd3: VS_WD[i] = RB1_Q;
						endcase
						VS[i].INT  <= VS_WD[i][26:16];
						VS[i].FRAC <= VS_WD[i][15: 8];
					end
				end
				
				if (BG_PIPE[1].NxCH[i]) begin
					case (BG_PIPE[1].NxCHS[i])
						2'd0: CH_PIPE[0][i] <= RA0_Q;
						2'd1: CH_PIPE[0][i] <= RA1_Q;
						2'd2: CH_PIPE[0][i] <= RB0_Q;
						2'd3: CH_PIPE[0][i] <= RB1_Q;
					endcase
				end
			end
			
			if (H_CNT == NBG_FETCH_START - 1) begin
				NBG_CDC[0] <= '{8{'0}}; NBG_CDP[0] <= '{8{DP_NULL}};
				NBG_CDC[1] <= '{8{'0}}; NBG_CDP[1] <= '{8{DP_NULL}};
				NBG_CDC[2] <= '{8{'0}}; NBG_CDP[2] <= '{8{DP_NULL}};
				NBG_CDC[3] <= '{8{'0}}; NBG_CDP[3] <= '{8{DP_NULL}};
			end
				
			NEN[3] = 0;
			if (BG_PIPE[3].NxCH[0] && NSxREG[0].CHCN[2]) begin
				NCNT[3] = BG_PIPE[3].NxCH_CNT[0];
				NPALN[3] = !NSxREG[0].BMEN ? PN_PIPE[5][0].PALN : {NSxREG[0].BMP,4'b0000};
				NHF[3] = PN_PIPE[5][0].HF & ~NSxREG[0].BMEN;
				NPR[3] = !NSxREG[0].BMEN ? PN_PIPE[5][0].PR : NSxREG[0].BMPR;
				NCC[3] = !NSxREG[0].BMEN ? PN_PIPE[5][0].CC : NSxREG[0].BMCC;
				NCH[3] = CH_PIPE[1][0];
				NTPON[3] = NSxREG[0].TPON;
				NCHCN[3] = NSxREG[0].CHCN;
				NEN[3] = BG_PIPE[2].NxCH_EN[0];
			end else if (BG_PIPE[3].NxCH[1] && NSxREG[1].CHCN[1]) begin
				NCNT[3] = BG_PIPE[3].NxCH_CNT[1];
				NPALN[3] = !NSxREG[1].BMEN ? PN_PIPE[5][1].PALN : {NSxREG[1].BMP,4'b0000};
				NHF[3] = PN_PIPE[5][1].HF & ~NSxREG[1].BMEN;
				NPR[3] = !NSxREG[1].BMEN ? PN_PIPE[5][1].PR : NSxREG[1].BMPR;
				NCC[3] = !NSxREG[1].BMEN ? PN_PIPE[5][1].CC : NSxREG[1].BMCC;
				NCH[3] = CH_PIPE[1][1];
				NTPON[3] = NSxREG[1].TPON;
				NCHCN[3] = {1'b0,NSxREG[1].CHCN[1:0]};
				NEN[3] = BG_PIPE[2].NxCH_EN[1];
			end else if (BG_PIPE[3].NxCH[1] && ((NSxREG[1].CHCN == 3'b000 && REGS.ZMCTL.N1ZMQT) || 
			                                    (NSxREG[1].CHCN == 3'b001 && REGS.ZMCTL.N1ZMHF))) begin
				NCNT[3] = BG_PIPE[3].NxCH_CNT[1];
				NPALN[3] = !NSxREG[1].BMEN ? PN_PIPE[5][5].PALN : {NSxREG[1].BMP,4'b0000};
				NHF[3] = PN_PIPE[5][5].HF & ~NSxREG[1].BMEN;
				NPR[3] = !NSxREG[1].BMEN ? PN_PIPE[5][5].PR : NSxREG[1].BMPR;
				NCC[3] = !NSxREG[1].BMEN ? PN_PIPE[5][5].CC : NSxREG[1].BMCC;
				NCH[3] = CH_PIPE[1][1];
				NTPON[3] = NSxREG[1].TPON;
				NCHCN[3] = {2'b00,NSxREG[1].CHCN[0]};
				NEN[3] = BG_PIPE[3].NxCH[1] & BG_PIPE[3].NxCH_CNT[1][1] & BG_PIPE[2].NxCH_EN[1];
			end else begin
				NCNT[3] = BG_PIPE[3].NxCH_CNT[3];
				NPALN[3] = !NSxREG[3].BMEN ? PN_PIPE[5][3].PALN : {NSxREG[3].BMP,4'b0000};
				NHF[3] = PN_PIPE[5][3].HF & ~NSxREG[3].BMEN;
				NPR[3] = !NSxREG[3].BMEN ? PN_PIPE[5][3].PR : NSxREG[3].BMPR;
				NCC[3] = !NSxREG[3].BMEN ? PN_PIPE[5][3].CC : NSxREG[3].BMCC;
				NCH[3] = CH_PIPE[1][3];
				NTPON[3] = NSxREG[3].TPON;
				NCHCN[3] = {2'b00,NSxREG[3].CHCN[0]};
				NEN[3] = BG_PIPE[3].NxCH[3] & BG_PIPE[2].NxCH_EN[3];
			end
			if (NEN[3]) begin
				case (NCHCN[3])//                                              DC                                                                PR      CC       TPON     PALN
					3'b000: begin				//4bits/dot, 16 colors
						NBG_CDC[3][3'b000               ^ {3{NHF[3]}}] <= {4'h0,NCH[3][31:28]}; NBG_CDP[3][3'b000               ^ {3{NHF[3]}}] <= {NPR[3], NCC[3], NTPON[3], NPALN[3]};
						NBG_CDC[3][3'b001               ^ {3{NHF[3]}}] <= {4'h0,NCH[3][27:24]}; NBG_CDP[3][3'b001               ^ {3{NHF[3]}}] <= {NPR[3], NCC[3], NTPON[3], NPALN[3]};
						NBG_CDC[3][3'b010               ^ {3{NHF[3]}}] <= {4'h0,NCH[3][23:20]}; NBG_CDP[3][3'b010               ^ {3{NHF[3]}}] <= {NPR[3], NCC[3], NTPON[3], NPALN[3]};
						NBG_CDC[3][3'b011               ^ {3{NHF[3]}}] <= {4'h0,NCH[3][19:16]}; NBG_CDP[3][3'b011               ^ {3{NHF[3]}}] <= {NPR[3], NCC[3], NTPON[3], NPALN[3]};
						NBG_CDC[3][3'b100               ^ {3{NHF[3]}}] <= {4'h0,NCH[3][15:12]}; NBG_CDP[3][3'b100               ^ {3{NHF[3]}}] <= {NPR[3], NCC[3], NTPON[3], NPALN[3]};
						NBG_CDC[3][3'b101               ^ {3{NHF[3]}}] <= {4'h0,NCH[3][11: 8]}; NBG_CDP[3][3'b101               ^ {3{NHF[3]}}] <= {NPR[3], NCC[3], NTPON[3], NPALN[3]};
						NBG_CDC[3][3'b110               ^ {3{NHF[3]}}] <= {4'h0,NCH[3][ 7: 4]}; NBG_CDP[3][3'b110               ^ {3{NHF[3]}}] <= {NPR[3], NCC[3], NTPON[3], NPALN[3]};
						NBG_CDC[3][3'b111               ^ {3{NHF[3]}}] <= {4'h0,NCH[3][ 3: 0]}; NBG_CDP[3][3'b111               ^ {3{NHF[3]}}] <= {NPR[3], NCC[3], NTPON[3], NPALN[3]};
					end
					3'b001: begin				//8bits/dot, 256 colors
						NBG_CDC[3][{NCNT[3][0:0],2'b00 ^ {2{NHF[3]}}}] <= {     NCH[3][31:24]}; NBG_CDP[3][{NCNT[3][0:0],2'b00} ^ {3{NHF[3]}}] <= {NPR[3], NCC[3], NTPON[3], NPALN[3]};
						NBG_CDC[3][{NCNT[3][0:0],2'b01 ^ {2{NHF[3]}}}] <= {     NCH[3][23:16]}; NBG_CDP[3][{NCNT[3][0:0],2'b01} ^ {3{NHF[3]}}] <= {NPR[3], NCC[3], NTPON[3], NPALN[3]};
						NBG_CDC[3][{NCNT[3][0:0],2'b10 ^ {2{NHF[3]}}}] <= {     NCH[3][15: 8]}; NBG_CDP[3][{NCNT[3][0:0],2'b10} ^ {3{NHF[3]}}] <= {NPR[3], NCC[3], NTPON[3], NPALN[3]};
						NBG_CDC[3][{NCNT[3][0:0],2'b11 ^ {2{NHF[3]}}}] <= {     NCH[3][ 7: 0]}; NBG_CDP[3][{NCNT[3][0:0],2'b11} ^ {3{NHF[3]}}] <= {NPR[3], NCC[3], NTPON[3], NPALN[3]};
					end
					3'b010,3'b011: begin				//16bits/dot, 2048 colors
						NBG_CDC[3][{NCNT[3][1:0], 1'b0 ^ {1{NHF[1]}}}] <= {     NCH[3][31:24]}; 
						NBG_CDC[3][{NCNT[3][1:0], 1'b1 ^ {1{NHF[1]}}}] <= {     NCH[3][15: 8]}; 
					end
					3'b100: begin				//32bits/dot, 16M colors
						NBG_CDC[3][{NCNT[3][2:0]                    }] <= {     NCH[3][31:24]}; 
					end
					default:;
				endcase
			end
				
			NEN[2] = 0;
			if (BG_PIPE[3].NxCH[0] && NSxREG[0].CHCN[2:1]) begin
				NCNT[2] = BG_PIPE[3].NxCH_CNT[0];
				NPALN[2] = !NSxREG[0].BMEN ? PN_PIPE[5][0].PALN : {NSxREG[0].BMP,4'b0000};
				NHF[2] = PN_PIPE[5][0].HF & ~NSxREG[0].BMEN;
				NPR[2] = !NSxREG[0].BMEN ? PN_PIPE[5][0].PR : NSxREG[0].BMPR;
				NCC[2] = !NSxREG[0].BMEN ? PN_PIPE[5][0].CC : NSxREG[0].BMCC;
				NCH[2] = CH_PIPE[1][0];
				NTPON[2] = NSxREG[0].TPON;
				NCHCN[2] = NSxREG[0].CHCN;
				NEN[2] = BG_PIPE[3].NxCH[0] & BG_PIPE[2].NxCH_EN[0];
			end else if (BG_PIPE[3].NxCH[0] && ((NSxREG[0].CHCN == 3'b000 && REGS.ZMCTL.N0ZMQT) || 
			                                    (NSxREG[0].CHCN == 3'b001 && REGS.ZMCTL.N0ZMHF))) begin
				NCNT[2] = BG_PIPE[3].NxCH_CNT[0];
				NPALN[2] = !NSxREG[0].BMEN ? PN_PIPE[5][4].PALN : {NSxREG[0].BMP,4'b0000};
				NHF[2] = PN_PIPE[5][4].HF & ~NSxREG[0].BMEN;
				NPR[2] = !NSxREG[0].BMEN ? PN_PIPE[5][4].PR : NSxREG[0].BMPR;
				NCC[2] = !NSxREG[0].BMEN ? PN_PIPE[5][4].CC : NSxREG[0].BMCC;
				NCH[2] = CH_PIPE[1][0];
				NTPON[2] = NSxREG[0].TPON;
				NCHCN[2] = NSxREG[0].CHCN;
				NEN[2] = BG_PIPE[3].NxCH[0] & BG_PIPE[3].NxCH_CNT[0][1] & BG_PIPE[2].NxCH_EN[0];
			end else begin
				NCNT[2] = BG_PIPE[3].NxCH_CNT[2];
				NPALN[2] = !NSxREG[2].BMEN ? PN_PIPE[5][2].PALN : {NSxREG[2].BMP,4'b0000};
				NHF[2] = PN_PIPE[5][2].HF & ~NSxREG[2].BMEN;
				NPR[2] = !NSxREG[2].BMEN ? PN_PIPE[5][2].PR : NSxREG[2].BMPR;
				NCC[2] = !NSxREG[2].BMEN ? PN_PIPE[5][2].CC : NSxREG[2].BMCC;
				NCH[2] = CH_PIPE[1][2];
				NTPON[2] = NSxREG[2].TPON;
				NCHCN[2] = {2'b00,NSxREG[2].CHCN[0]};
				NEN[2] = BG_PIPE[3].NxCH[2] & BG_PIPE[2].NxCH_EN[2];
			end
			if (NEN[2]) begin
				case (NCHCN[2])//                                               DC                                                                PR      CC      TPON     PALN
					3'b000: begin				//4bits/dot, 16 colors
						NBG_CDC[2][3'b000               ^ {3{NHF[2]}}] <= {4'h0,NCH[2][31:28]}; NBG_CDP[2][3'b000               ^ {3{NHF[2]}}] <= {NPR[2], NCC[2], NTPON[2], NPALN[2]};
						NBG_CDC[2][3'b001               ^ {3{NHF[2]}}] <= {4'h0,NCH[2][27:24]}; NBG_CDP[2][3'b001               ^ {3{NHF[2]}}] <= {NPR[2], NCC[2], NTPON[2], NPALN[2]};
						NBG_CDC[2][3'b010               ^ {3{NHF[2]}}] <= {4'h0,NCH[2][23:20]}; NBG_CDP[2][3'b010               ^ {3{NHF[2]}}] <= {NPR[2], NCC[2], NTPON[2], NPALN[2]};
						NBG_CDC[2][3'b011               ^ {3{NHF[2]}}] <= {4'h0,NCH[2][19:16]}; NBG_CDP[2][3'b011               ^ {3{NHF[2]}}] <= {NPR[2], NCC[2], NTPON[2], NPALN[2]};
						NBG_CDC[2][3'b100               ^ {3{NHF[2]}}] <= {4'h0,NCH[2][15:12]}; NBG_CDP[2][3'b100               ^ {3{NHF[2]}}] <= {NPR[2], NCC[2], NTPON[2], NPALN[2]};
						NBG_CDC[2][3'b101               ^ {3{NHF[2]}}] <= {4'h0,NCH[2][11: 8]}; NBG_CDP[2][3'b101               ^ {3{NHF[2]}}] <= {NPR[2], NCC[2], NTPON[2], NPALN[2]};
						NBG_CDC[2][3'b110               ^ {3{NHF[2]}}] <= {4'h0,NCH[2][ 7: 4]}; NBG_CDP[2][3'b110               ^ {3{NHF[2]}}] <= {NPR[2], NCC[2], NTPON[2], NPALN[2]};
						NBG_CDC[2][3'b111               ^ {3{NHF[2]}}] <= {4'h0,NCH[2][ 3: 0]}; NBG_CDP[2][3'b111               ^ {3{NHF[2]}}] <= {NPR[2], NCC[2], NTPON[2], NPALN[2]};
					end
					3'b001: begin				//8bits/dot, 256 colors
						NBG_CDC[2][{NCNT[2][0:0],2'b00 ^ {2{NHF[2]}}}] <= {     NCH[2][31:24]}; NBG_CDP[2][{NCNT[2][0:0],2'b00 ^ {2{NHF[2]}}}] <= {NPR[2], NCC[2], NTPON[2], NPALN[2]};
						NBG_CDC[2][{NCNT[2][0:0],2'b01 ^ {2{NHF[2]}}}] <= {     NCH[2][23:16]}; NBG_CDP[2][{NCNT[2][0:0],2'b01 ^ {2{NHF[2]}}}] <= {NPR[2], NCC[2], NTPON[2], NPALN[2]};
						NBG_CDC[2][{NCNT[2][0:0],2'b10 ^ {2{NHF[2]}}}] <= {     NCH[2][15: 8]}; NBG_CDP[2][{NCNT[2][0:0],2'b10 ^ {2{NHF[2]}}}] <= {NPR[2], NCC[2], NTPON[2], NPALN[2]};
						NBG_CDC[2][{NCNT[2][0:0],2'b11 ^ {2{NHF[2]}}}] <= {     NCH[2][ 7: 0]}; NBG_CDP[2][{NCNT[2][0:0],2'b11 ^ {2{NHF[2]}}}] <= {NPR[2], NCC[2], NTPON[2], NPALN[2]};
					end
					3'b010,3'b011: begin				//16bits/dot, 2048 colors (NBG0)
						NBG_CDC[2][{NCNT[2][1:0], 1'b0 ^ {1{NHF[2]}}}] <= {     NCH[2][31:24]}; 
						NBG_CDC[2][{NCNT[2][1:0], 1'b1 ^ {1{NHF[2]}}}] <= {     NCH[2][15: 8]}; 
					end
					3'b100: begin				//32bits/dot, 16M colors (NBG0)
						NBG_CDC[2][{NCNT[2][2:0]                    }] <= {     NCH[2][15: 8]}; 
					end
					default:;
				endcase
			end
			
			NEN[1] = 0;
			if (BG_PIPE[3].NxCH[0] && NSxREG[0].CHCN[2]) begin
				NCNT[1] = BG_PIPE[3].NxCH_CNT[0];
				NPALN[1] = !NSxREG[0].BMEN ? PN_PIPE[5][0].PALN : {NSxREG[0].BMP,4'b0000}; NPALN[5] = !NSxREG[0].BMEN ? PN_PIPE[5][5].PALN : {NSxREG[0].BMP,4'b0000};
				NHF[1] = !NSxREG[0].BMEN ? PN_PIPE[5][0].HF : 1'b0;                        NHF[5] = !NSxREG[0].BMEN ? PN_PIPE[5][5].HF : 1'b0;
				NPR[1] = !NSxREG[0].BMEN ? PN_PIPE[5][0].PR : NSxREG[0].BMPR;              NPR[5] = !NSxREG[0].BMEN ? PN_PIPE[5][5].PR : NSxREG[0].BMPR;
				NCC[1] = !NSxREG[0].BMEN ? PN_PIPE[5][0].CC : NSxREG[0].BMCC;              NCC[5] = !NSxREG[0].BMEN ? PN_PIPE[5][5].CC : NSxREG[0].BMCC;
				NCH[1] = CH_PIPE[1][0];
				NTPON[1] = NSxREG[0].TPON;
				NCHCN[1] = NSxREG[0].CHCN;
				NEN[1] = BG_PIPE[2].NxCH_EN[0];
			end else if (BG_PIPE[3].NxCH[1] && NSxREG[1].CHCN == 3'b000 && (REGS.ZMCTL.N1ZMHF || REGS.ZMCTL.N1ZMQT)) begin
				NCNT[1] = BG_PIPE[3].NxCH_CNT[1];
				NPALN[1] = !NSxREG[1].BMEN ? PN_PIPE[5][1].PALN : {NSxREG[1].BMP,4'b0000}; NPALN[5] = !NSxREG[1].BMEN ? PN_PIPE[5][5].PALN : {NSxREG[1].BMP,4'b0000};
				NHF[1] = !NSxREG[1].BMEN ? PN_PIPE[5][1].HF : 1'b0;                        NHF[5] = !NSxREG[1].BMEN ? PN_PIPE[5][5].HF : 1'b0;
				NPR[1] = !NSxREG[1].BMEN ? PN_PIPE[5][1].PR : NSxREG[1].BMPR;              NPR[5] = !NSxREG[1].BMEN ? PN_PIPE[5][5].PR : NSxREG[1].BMPR;
				NCC[1] = !NSxREG[1].BMEN ? PN_PIPE[5][1].CC : NSxREG[1].BMCC;              NCC[5] = !NSxREG[1].BMEN ? PN_PIPE[5][5].CC : NSxREG[1].BMCC;
				NCH[1] = CH_PIPE[1][1];
				NTPON[1] = NSxREG[1].TPON;
				NCHCN[1] = NSxREG[1].CHCN;
				NEN[1] = BG_PIPE[3].NxCH[1] & (!BG_PIPE[3].NxCH_CNT[1][1] | REGS.ZMCTL.N1ZMHF) & BG_PIPE[2].NxCH_EN[1];
			end else if (BG_PIPE[3].NxCH[1] && NSxREG[1].CHCN == 3'b001 && REGS.ZMCTL.N1ZMHF) begin
				NCNT[1] = BG_PIPE[3].NxCH_CNT[1];
				NPALN[1] = !NSxREG[1].BMEN ? PN_PIPE[5][1].PALN : {NSxREG[1].BMP,4'b0000}; NPALN[5] = !NSxREG[1].BMEN ? PN_PIPE[5][5].PALN : {NSxREG[1].BMP,4'b0000};
				NHF[1] = !NSxREG[1].BMEN ? PN_PIPE[5][1].HF : 1'b0;                        NHF[5] = !NSxREG[1].BMEN ? PN_PIPE[5][5].HF : 1'b0;
				NPR[1] = !NSxREG[1].BMEN ? PN_PIPE[5][1].PR : NSxREG[1].BMPR;              NPR[5] = !NSxREG[1].BMEN ? PN_PIPE[5][5].PR : NSxREG[1].BMPR;
				NCC[1] = !NSxREG[1].BMEN ? PN_PIPE[5][1].CC : NSxREG[1].BMCC;              NCC[5] = !NSxREG[1].BMEN ? PN_PIPE[5][5].CC : NSxREG[1].BMCC;
				NCH[1] = CH_PIPE[1][1];
				NTPON[1] = NSxREG[1].TPON;
				NCHCN[1] = NSxREG[1].CHCN;
				NEN[1] = BG_PIPE[3].NxCH[1] & !BG_PIPE[3].NxCH_CNT[1][1] & BG_PIPE[2].NxCH_EN[1];
			end else begin
				NCNT[1] = BG_PIPE[3].NxCH_CNT[1];
				NPALN[1] = !NSxREG[1].BMEN ? PN_PIPE[5][1].PALN : {NSxREG[1].BMP,4'b0000}; NPALN[5] = !NSxREG[1].BMEN ? PN_PIPE[5][5].PALN : {NSxREG[1].BMP,4'b0000};
				NHF[1] = !NSxREG[1].BMEN ? PN_PIPE[5][1].HF : 1'b0;                        NHF[5] = !NSxREG[1].BMEN ? PN_PIPE[5][5].HF : 1'b0;
				NPR[1] = !NSxREG[1].BMEN ? PN_PIPE[5][1].PR : NSxREG[1].BMPR;              NPR[5] = !NSxREG[1].BMEN ? PN_PIPE[5][5].PR : NSxREG[1].BMPR;
				NCC[1] = !NSxREG[1].BMEN ? PN_PIPE[5][1].CC : NSxREG[1].BMCC;              NCC[5] = !NSxREG[1].BMEN ? PN_PIPE[5][5].CC : NSxREG[1].BMCC;
				NCH[1] = CH_PIPE[1][1];
				NTPON[1] = NSxREG[1].TPON;
				NCHCN[1] = {1'b0,NSxREG[1].CHCN[1:0]};
				NEN[1] = BG_PIPE[3].NxCH[1] & BG_PIPE[2].NxCH_EN[1];
			end
			if (NEN[1]) begin
				case (NCHCN[1])//                                               DC                                                                PR      CC      TPON      PALN
					3'b000: begin				//4bits/dot, 16 colors
						if (NCNT[1][0] && REGS.ZMCTL.N1ZMHF) begin
						NBG_CDC[1][3'b000               ^ {3{NHF[5]}}][ 7: 4] <= NCH[1][31:28]; NBG_CDP[5][3'b000               ^ {3{NHF[5]}}] <= {NPR[5], NCC[5], NTPON[1], NPALN[5]};
						NBG_CDC[1][3'b001               ^ {3{NHF[5]}}][ 7: 4] <= NCH[1][27:24]; NBG_CDP[5][3'b001               ^ {3{NHF[5]}}] <= {NPR[5], NCC[5], NTPON[1], NPALN[5]};
						NBG_CDC[1][3'b010               ^ {3{NHF[5]}}][ 7: 4] <= NCH[1][23:20]; NBG_CDP[5][3'b010               ^ {3{NHF[5]}}] <= {NPR[5], NCC[5], NTPON[1], NPALN[5]};
						NBG_CDC[1][3'b011               ^ {3{NHF[5]}}][ 7: 4] <= NCH[1][19:16]; NBG_CDP[5][3'b011               ^ {3{NHF[5]}}] <= {NPR[5], NCC[5], NTPON[1], NPALN[5]};
						NBG_CDC[1][3'b100               ^ {3{NHF[5]}}][ 7: 4] <= NCH[1][15:12]; NBG_CDP[5][3'b100               ^ {3{NHF[5]}}] <= {NPR[5], NCC[5], NTPON[1], NPALN[5]};
						NBG_CDC[1][3'b101               ^ {3{NHF[5]}}][ 7: 4] <= NCH[1][11: 8]; NBG_CDP[5][3'b101               ^ {3{NHF[5]}}] <= {NPR[5], NCC[5], NTPON[1], NPALN[5]};
						NBG_CDC[1][3'b110               ^ {3{NHF[5]}}][ 7: 4] <= NCH[1][ 7: 4]; NBG_CDP[5][3'b110               ^ {3{NHF[5]}}] <= {NPR[5], NCC[5], NTPON[1], NPALN[5]};
						NBG_CDC[1][3'b111               ^ {3{NHF[5]}}][ 7: 4] <= NCH[1][ 3: 0]; NBG_CDP[5][3'b111               ^ {3{NHF[5]}}] <= {NPR[5], NCC[5], NTPON[1], NPALN[5]};
						end else begin
						NBG_CDC[1][3'b000               ^ {3{NHF[1]}}][ 3: 0] <= NCH[1][31:28]; NBG_CDP[1][3'b000               ^ {3{NHF[1]}}] <= {NPR[1], NCC[1], NTPON[1], NPALN[1]};
						NBG_CDC[1][3'b001               ^ {3{NHF[1]}}][ 3: 0] <= NCH[1][27:24]; NBG_CDP[1][3'b001               ^ {3{NHF[1]}}] <= {NPR[1], NCC[1], NTPON[1], NPALN[1]};
						NBG_CDC[1][3'b010               ^ {3{NHF[1]}}][ 3: 0] <= NCH[1][23:20]; NBG_CDP[1][3'b010               ^ {3{NHF[1]}}] <= {NPR[1], NCC[1], NTPON[1], NPALN[1]};
						NBG_CDC[1][3'b011               ^ {3{NHF[1]}}][ 3: 0] <= NCH[1][19:16]; NBG_CDP[1][3'b011               ^ {3{NHF[1]}}] <= {NPR[1], NCC[1], NTPON[1], NPALN[1]};
						NBG_CDC[1][3'b100               ^ {3{NHF[1]}}][ 3: 0] <= NCH[1][15:12]; NBG_CDP[1][3'b100               ^ {3{NHF[1]}}] <= {NPR[1], NCC[1], NTPON[1], NPALN[1]};
						NBG_CDC[1][3'b101               ^ {3{NHF[1]}}][ 3: 0] <= NCH[1][11: 8]; NBG_CDP[1][3'b101               ^ {3{NHF[1]}}] <= {NPR[1], NCC[1], NTPON[1], NPALN[1]};
						NBG_CDC[1][3'b110               ^ {3{NHF[1]}}][ 3: 0] <= NCH[1][ 7: 4]; NBG_CDP[1][3'b110               ^ {3{NHF[1]}}] <= {NPR[1], NCC[1], NTPON[1], NPALN[1]};
						NBG_CDC[1][3'b111               ^ {3{NHF[1]}}][ 3: 0] <= NCH[1][ 3: 0]; NBG_CDP[1][3'b111               ^ {3{NHF[1]}}] <= {NPR[1], NCC[1], NTPON[1], NPALN[1]};
						end
					end
					3'b001: begin				//8bits/dot, 256 colors
						NBG_CDC[1][{NCNT[1][0:0],2'b00 ^ {2{NHF[1]}}}] <= {     NCH[1][31:24]}; NBG_CDP[1][{NCNT[1][0:0],2'b00 ^ {2{NHF[1]}}}] <= {NPR[1], NCC[1], NTPON[1], NPALN[1]};
						NBG_CDC[1][{NCNT[1][0:0],2'b01 ^ {2{NHF[1]}}}] <= {     NCH[1][23:16]}; NBG_CDP[1][{NCNT[1][0:0],2'b01 ^ {2{NHF[1]}}}] <= {NPR[1], NCC[1], NTPON[1], NPALN[1]};
						NBG_CDC[1][{NCNT[1][0:0],2'b10 ^ {2{NHF[1]}}}] <= {     NCH[1][15: 8]}; NBG_CDP[1][{NCNT[1][0:0],2'b10 ^ {2{NHF[1]}}}] <= {NPR[1], NCC[1], NTPON[1], NPALN[1]};
						NBG_CDC[1][{NCNT[1][0:0],2'b11 ^ {2{NHF[1]}}}] <= {     NCH[1][ 7: 0]}; NBG_CDP[1][{NCNT[1][0:0],2'b11 ^ {2{NHF[1]}}}] <= {NPR[1], NCC[1], NTPON[1], NPALN[1]};
					end
					3'b010,3'b011: begin				//16bits/dot, 2048 colors
						NBG_CDC[1][{NCNT[1][1:0], 1'b0 ^ {1{NHF[1]}}}] <= {     NCH[1][23:16]}; NBG_CDP[1][{NCNT[1][1:0], 1'b0 ^ {1{NHF[1]}}}] <= {NPR[1], NCC[1], NTPON[1], 7'h00};
						NBG_CDC[1][{NCNT[1][1:0], 1'b1 ^ {1{NHF[1]}}}] <= {     NCH[1][ 7: 0]}; NBG_CDP[1][{NCNT[1][1:0], 1'b1 ^ {1{NHF[1]}}}] <= {NPR[1], NCC[1], NTPON[1], 7'h00};
					end
					3'b100: begin				//32bits/dot, 16M colors
						NBG_CDC[1][{NCNT[1][2:0]                    }] <= {     NCH[1][23:16]}; 
					end
					default:;
				endcase
			end
			
			NEN[0] = 0;
			if (BG_PIPE[3].NxCH[0] && NSxREG[0].CHCN == 3'b000 && (REGS.ZMCTL.N0ZMHF || REGS.ZMCTL.N0ZMQT)) begin
				NCNT[0] = BG_PIPE[3].NxCH_CNT[0];
				NPALN[0] = !NSxREG[0].BMEN ? PN_PIPE[5][0].PALN : {NSxREG[0].BMP,4'b0000}; NPALN[4] = !NSxREG[0].BMEN ? PN_PIPE[5][4].PALN : {NSxREG[0].BMP,4'b0000};
				NHF[0] = !NSxREG[0].BMEN ? PN_PIPE[5][0].HF : 1'b0;                        NHF[4] = !NSxREG[0].BMEN ? PN_PIPE[5][4].HF : 1'b0;
				NPR[0] = !NSxREG[0].BMEN ? PN_PIPE[5][0].PR : NSxREG[0].BMPR;              NPR[4] = !NSxREG[0].BMEN ? PN_PIPE[5][4].PR : NSxREG[0].BMPR;
				NCC[0] = !NSxREG[0].BMEN ? PN_PIPE[5][0].CC : NSxREG[0].BMCC;              NCC[4] = !NSxREG[0].BMEN ? PN_PIPE[5][4].CC : NSxREG[0].BMCC;
				NCH[0] = CH_PIPE[1][0];
				NTPON[0] = NSxREG[0].TPON;
				NCHCN[0] = NSxREG[0].CHCN;
				NEN[0] = BG_PIPE[3].NxCH[0] & (!BG_PIPE[3].NxCH_CNT[0][1] | REGS.ZMCTL.N0ZMHF) & BG_PIPE[2].NxCH_EN[0];
			end else if (BG_PIPE[3].NxCH[0] && NSxREG[0].CHCN == 3'b001 && REGS.ZMCTL.N0ZMHF) begin
				NCNT[0] = BG_PIPE[3].NxCH_CNT[0];
				NPALN[0] = !NSxREG[0].BMEN ? PN_PIPE[5][0].PALN : {NSxREG[0].BMP,4'b0000}; NPALN[4] = !NSxREG[0].BMEN ? PN_PIPE[5][4].PALN : {NSxREG[0].BMP,4'b0000};
				NHF[0] = !NSxREG[0].BMEN ? PN_PIPE[5][0].HF : 1'b0;                        NHF[4] = !NSxREG[0].BMEN ? PN_PIPE[5][4].HF : 1'b0;
				NPR[0] = !NSxREG[0].BMEN ? PN_PIPE[5][0].PR : NSxREG[0].BMPR;              NPR[4] = !NSxREG[0].BMEN ? PN_PIPE[5][4].PR : NSxREG[0].BMPR;
				NCC[0] = !NSxREG[0].BMEN ? PN_PIPE[5][0].CC : NSxREG[0].BMCC;              NCC[4] = !NSxREG[0].BMEN ? PN_PIPE[5][4].CC : NSxREG[0].BMCC;
				NCH[0] = CH_PIPE[1][0];
				NTPON[0] = NSxREG[0].TPON;
				NCHCN[0] = NSxREG[0].CHCN;
				NEN[0] = BG_PIPE[3].NxCH[0] & !BG_PIPE[3].NxCH_CNT[0][1] & BG_PIPE[2].NxCH_EN[0];
			end else begin
				NCNT[0] = BG_PIPE[3].NxCH_CNT[0];
				NPALN[0] = !NSxREG[0].BMEN ? PN_PIPE[5][0].PALN : {NSxREG[0].BMP,4'b0000}; NPALN[4] = !NSxREG[0].BMEN ? PN_PIPE[5][4].PALN : {NSxREG[0].BMP,4'b0000};
				NHF[0] = !NSxREG[0].BMEN ? PN_PIPE[5][0].HF : 1'b0;                        NHF[4] = !NSxREG[0].BMEN ? PN_PIPE[5][4].HF : 1'b0;
				NPR[0] = !NSxREG[0].BMEN ? PN_PIPE[5][0].PR : NSxREG[0].BMPR;              NPR[4] = !NSxREG[0].BMEN ? PN_PIPE[5][4].PR : NSxREG[0].BMPR;
				NCC[0] = !NSxREG[0].BMEN ? PN_PIPE[5][0].CC : NSxREG[0].BMCC;              NCC[4] = !NSxREG[0].BMEN ? PN_PIPE[5][4].CC : NSxREG[0].BMCC;
				NCH[0] = CH_PIPE[1][0];
				NTPON[0] = NSxREG[0].TPON;
				NCHCN[0] = NSxREG[0].CHCN;
				NEN[0] = BG_PIPE[3].NxCH[0] & BG_PIPE[2].NxCH_EN[0];
			end
			if (NEN[0]) begin
				case (NCHCN[0])//                                               DC                                                                PR      CC      TPON      PALN
					3'b000: begin				//4bits/dot, 16 colors
						if (NCNT[0][0] && REGS.ZMCTL.N0ZMHF) begin
						NBG_CDC[0][3'b000               ^ {3{NHF[4]}}][ 7: 4] <= NCH[0][31:28]; NBG_CDP[4][3'b000               ^ {3{NHF[4]}}] <= {NPR[4], NCC[4], NTPON[0], NPALN[4]};
						NBG_CDC[0][3'b001               ^ {3{NHF[4]}}][ 7: 4] <= NCH[0][27:24]; NBG_CDP[4][3'b001               ^ {3{NHF[4]}}] <= {NPR[4], NCC[4], NTPON[0], NPALN[4]};
						NBG_CDC[0][3'b010               ^ {3{NHF[4]}}][ 7: 4] <= NCH[0][23:20]; NBG_CDP[4][3'b010               ^ {3{NHF[4]}}] <= {NPR[4], NCC[4], NTPON[0], NPALN[4]};
						NBG_CDC[0][3'b011               ^ {3{NHF[4]}}][ 7: 4] <= NCH[0][19:16]; NBG_CDP[4][3'b011               ^ {3{NHF[4]}}] <= {NPR[4], NCC[4], NTPON[0], NPALN[4]};
						NBG_CDC[0][3'b100               ^ {3{NHF[4]}}][ 7: 4] <= NCH[0][15:12]; NBG_CDP[4][3'b100               ^ {3{NHF[4]}}] <= {NPR[4], NCC[4], NTPON[0], NPALN[4]};
						NBG_CDC[0][3'b101               ^ {3{NHF[4]}}][ 7: 4] <= NCH[0][11: 8]; NBG_CDP[4][3'b101               ^ {3{NHF[4]}}] <= {NPR[4], NCC[4], NTPON[0], NPALN[4]};
						NBG_CDC[0][3'b110               ^ {3{NHF[4]}}][ 7: 4] <= NCH[0][ 7: 4]; NBG_CDP[4][3'b110               ^ {3{NHF[4]}}] <= {NPR[4], NCC[4], NTPON[0], NPALN[4]};
						NBG_CDC[0][3'b111               ^ {3{NHF[4]}}][ 7: 4] <= NCH[0][ 3: 0]; NBG_CDP[4][3'b111               ^ {3{NHF[4]}}] <= {NPR[4], NCC[4], NTPON[0], NPALN[4]};
						end else begin
						NBG_CDC[0][3'b000               ^ {3{NHF[0]}}][ 3: 0] <= NCH[0][31:28]; NBG_CDP[0][3'b000               ^ {3{NHF[0]}}] <= {NPR[0], NCC[0], NTPON[0], NPALN[0]};
						NBG_CDC[0][3'b001               ^ {3{NHF[0]}}][ 3: 0] <= NCH[0][27:24]; NBG_CDP[0][3'b001               ^ {3{NHF[0]}}] <= {NPR[0], NCC[0], NTPON[0], NPALN[0]};
						NBG_CDC[0][3'b010               ^ {3{NHF[0]}}][ 3: 0] <= NCH[0][23:20]; NBG_CDP[0][3'b010               ^ {3{NHF[0]}}] <= {NPR[0], NCC[0], NTPON[0], NPALN[0]};
						NBG_CDC[0][3'b011               ^ {3{NHF[0]}}][ 3: 0] <= NCH[0][19:16]; NBG_CDP[0][3'b011               ^ {3{NHF[0]}}] <= {NPR[0], NCC[0], NTPON[0], NPALN[0]};
						NBG_CDC[0][3'b100               ^ {3{NHF[0]}}][ 3: 0] <= NCH[0][15:12]; NBG_CDP[0][3'b100               ^ {3{NHF[0]}}] <= {NPR[0], NCC[0], NTPON[0], NPALN[0]};
						NBG_CDC[0][3'b101               ^ {3{NHF[0]}}][ 3: 0] <= NCH[0][11: 8]; NBG_CDP[0][3'b101               ^ {3{NHF[0]}}] <= {NPR[0], NCC[0], NTPON[0], NPALN[0]};
						NBG_CDC[0][3'b110               ^ {3{NHF[0]}}][ 3: 0] <= NCH[0][ 7: 4]; NBG_CDP[0][3'b110               ^ {3{NHF[0]}}] <= {NPR[0], NCC[0], NTPON[0], NPALN[0]};
						NBG_CDC[0][3'b111               ^ {3{NHF[0]}}][ 3: 0] <= NCH[0][ 3: 0]; NBG_CDP[0][3'b111               ^ {3{NHF[0]}}] <= {NPR[0], NCC[0], NTPON[0], NPALN[0]};
						end
					end
					3'b001: begin				//8bits/dot, 256 colors
						NBG_CDC[0][{NCNT[0][0:0],2'b00 ^ {2{NHF[0]}}}] <= {     NCH[0][31:24]}; NBG_CDP[0][{NCNT[0][0:0],2'b00 ^ {2{NHF[0]}}}] <= {NPR[0], NCC[0], NTPON[0], NPALN[0]};
						NBG_CDC[0][{NCNT[0][0:0],2'b01 ^ {2{NHF[0]}}}] <= {     NCH[0][23:16]}; NBG_CDP[0][{NCNT[0][0:0],2'b01 ^ {2{NHF[0]}}}] <= {NPR[0], NCC[0], NTPON[0], NPALN[0]};
						NBG_CDC[0][{NCNT[0][0:0],2'b10 ^ {2{NHF[0]}}}] <= {     NCH[0][15: 8]}; NBG_CDP[0][{NCNT[0][0:0],2'b10 ^ {2{NHF[0]}}}] <= {NPR[0], NCC[0], NTPON[0], NPALN[0]};
						NBG_CDC[0][{NCNT[0][0:0],2'b11 ^ {2{NHF[0]}}}] <= {     NCH[0][ 7: 0]}; NBG_CDP[0][{NCNT[0][0:0],2'b11 ^ {2{NHF[0]}}}] <= {NPR[0], NCC[0], NTPON[0], NPALN[0]};
					end
					3'b010,3'b011: begin				//16bits/dot, 2048 colors
						NBG_CDC[0][{NCNT[0][1:0], 1'b0 ^ {1{NHF[0]}}}] <= {     NCH[0][23:16]}; NBG_CDP[0][{NCNT[0][1:0], 1'b0 ^ {1{NHF[0]}}}] <= {NPR[0], NCC[0], NTPON[0], 7'h00};
						NBG_CDC[0][{NCNT[0][1:0], 1'b1 ^ {1{NHF[0]}}}] <= {     NCH[0][ 7: 0]}; NBG_CDP[0][{NCNT[0][1:0], 1'b1 ^ {1{NHF[0]}}}] <= {NPR[0], NCC[0], NTPON[0], 7'h00};
					end
					3'b100: begin				//32bits/dot, 16M colors
						NBG_CDC[0][{NCNT[0][2:0]                    }] <= {     NCH[0][ 7: 0]}; NBG_CDP[0][{NCNT[0][2:0]                    }] <= {NPR[0], NCC[0], NTPON[0], 7'h00};
					end
					default:;
				endcase
			end
			
			BG_PIPE[1] <= BG_PIPE[0];
			BG_PIPE[2] <= BG_PIPE[1];
			BG_PIPE[3] <= BG_PIPE[2];
			
			PN_PIPE[1] <= PN_PIPE[0];
			PN_PIPE[2] <= PN_PIPE[1];
			PN_PIPE[3] <= PN_PIPE[2];
			PN_PIPE[4] <= PN_PIPE[3];
			PN_PIPE[5] <= PN_PIPE[4];
			CH_PIPE[1] <= CH_PIPE[0];
			
			NBG0_PN_PIPE[0] <= PN_PIPE[1][0];
			NBG0_PN_PIPE[1] <= NBG0_PN_PIPE[0];
			
			if (BG_PIPE[3].NxPN[0] && NSxREG[0].CHCN[2]) begin
				NBG1_PN_PIPE[0] <= NBG2_PN_PIPE[1];
			end else begin
				NBG1_PN_PIPE[0] <= PN_PIPE[1][1];
			end
			NBG1_PN_PIPE[1] <= NBG1_PN_PIPE[0];
			
			if (BG_PIPE[3].NxPN[0] && NSxREG[0].CHCN[2:1]) begin
				NBG2_PN_PIPE[0] <= NBG0_PN_PIPE[1];
			end else begin
				NBG2_PN_PIPE[0] <= PN_PIPE[1][2];
			end
			NBG2_PN_PIPE[1] <= NBG2_PN_PIPE[0];
			
			if (BG_PIPE[3].NxPN[0] && NSxREG[0].CHCN[2]) begin
				NBG3_PN_PIPE[0] <= NBG1_PN_PIPE[1];
			end else if (BG_PIPE[3].NxPN[1] && NSxREG[1].CHCN[1]) begin
				NBG3_PN_PIPE[0] <= NBG1_PN_PIPE[1];
			end else begin
				NBG3_PN_PIPE[0] <= PN_PIPE[1][3];
			end
			NBG3_PN_PIPE[1] <= NBG3_PN_PIPE[0];
			
			
			//RBG0,RBG1
			for (int i=0; i<2; i++) begin
				CT_RP = (i == 0 ? R0RP_PIPE[1] : 1'b1);
				PN_RP = (i == 0 ? VA_PIPE[1].R0RP : 1'b1);
				CH_RP = (i == 0 ? VA_PIPE[4].R0RP : 1'b1);
				
				RBG_PIPE[0].RxCT[i] = VA_PIPE[0].RxA0CT[i] | VA_PIPE[0].RxA1CT[i] | VA_PIPE[0].RxB0CT[i] | VA_PIPE[0].RxB1CT[i];
				RBG_PIPE[0].RxCTS[i] = VA_PIPE[0].RxA0CT[i] && RxCT_ADDR[RBG_A0VA.Rx][18:17] == 2'b00 ? 2'd0 : 
									        VA_PIPE[0].RxA1CT[i] && RxCT_ADDR[RBG_A1VA.Rx][18:17] == 2'b01 ? 2'd1 : 
									        VA_PIPE[0].RxB0CT[i] && RxCT_ADDR[RBG_B0VA.Rx][18:17] == 2'b10 ? 2'd2 : 
									        2'd3;
				RBG_PIPE[0].RxCRCT[i] = VA_PIPE[0].RxCRCT[i];
				RBG_PIPE[0].RxPN[i] = VA_PIPE[0].RxA0PN[i] | VA_PIPE[0].RxA1PN[i] | VA_PIPE[0].RxB0PN[i] | VA_PIPE[0].RxB1PN[i];
				RBG_PIPE[0].RxPNS[i] = VA_PIPE[0].RxA0PN[i] && RxPN_ADDR[RBG_A0VA.Rx][18:17] == 2'b00 ? 2'd0 : 
									        VA_PIPE[0].RxA1PN[i] && RxPN_ADDR[RBG_A1VA.Rx][18:17] == 2'b01 ? 2'd1 : 
									        VA_PIPE[0].RxB0PN[i] && RxPN_ADDR[RBG_B0VA.Rx][18:17] == 2'b10 ? 2'd2 : 
									        2'd3;
				RBG_PIPE[0].RxOVR[i] = RxSCRN_OVER[i];
				RBG_PIPE[0].RxCTTP[i] = VA_PIPE[0].RxCTTP[i];
				RBG_PIPE[0].RxCH[i] = VA_PIPE[0].RxA0CH[i] | VA_PIPE[0].RxA1CH[i] | VA_PIPE[0].RxB0CH[i] | VA_PIPE[0].RxB1CH[i];
				RBG_PIPE[0].RxCHS[i] = VA_PIPE[0].RxA0CH[i] && RxCH_ADDR[RBG_A0VA.Rx][18:17] == 2'b00 ? 2'd0 : 
									        VA_PIPE[0].RxA1CH[i] && RxCH_ADDR[RBG_A1VA.Rx][18:17] == 2'b01 ? 2'd1 : 
									        VA_PIPE[0].RxB0CH[i] && RxCH_ADDR[RBG_B0VA.Rx][18:17] == 2'b10 ? 2'd2 : 
									        2'd3;
				RBG_PIPE[0].RxCELLX[i] = VA_PIPE[4].RxX[CH_RP][2:0];

				if (RBG_PIPE[1].RxCT[i]) begin
					case (RBG_PIPE[1].RxCTS[i])
						2'd0: RCT_WD[i] = RA0_Q;
						2'd1: RCT_WD[i] = RA1_Q;
						2'd2: RCT_WD[i] = RB0_Q;
						2'd3: RCT_WD[i] = RB1_Q;
					endcase
					RBG_CT_PIPE[0][i] <= CTData(RPxREG[CT_RP].KMD, RPxREG[CT_RP].KDBS, RCT_WD[i]);
				end else if (RBG_PIPE[1].RxCRCT[i]) begin
					RCT_WD[i] = CT_CRAM_Q;
					RBG_CT_PIPE[0][i] <= CTData(RPxREG[CT_RP].KMD, RPxREG[CT_RP].KDBS, RCT_WD[i]);
				end
				
				if (RBG_PIPE[1].RxPN[i]) begin
					case (RBG_PIPE[1].RxPNS[i])
						2'd0: RPN_WD[i] = RA0_Q;
						2'd1: RPN_WD[i] = RA1_Q;
						2'd2: RPN_WD[i] = RB0_Q;
						2'd3: RPN_WD[i] = RB1_Q;
					endcase
					if (RPxREG[PN_RP].OVR == 2'b01 && RBG_PIPE[1].RxOVR[i])
						RBG_PN_PIPE[0][i] <= PNData(RSxREG[i].PNC, RSxREG[i].CHSZ, RSxREG[i].CHCN, RPxREG[PN_RP].OVPNR);
					else if (RSxREG[i].PNC.NxPNB)
						RBG_PN_PIPE[0][i] <= PNData(RSxREG[i].PNC, RSxREG[i].CHSZ, RSxREG[i].CHCN, RPN_WD[i][31:16]);
					else
						RBG_PN_PIPE[0][i] <= RPN_WD[i];
				end
				
				RBG_TP_PIPE[0][i] <= (RPxREG[PN_RP].OVR[1] && RBG_PIPE[1].RxOVR[i]) || RBG_PIPE[1].RxCTTP[i];
					
				if (RBG_PIPE[1].RxCH[i]) begin
					case (RBG_PIPE[1].RxCHS[i])
						2'd0: RCH_WD[i] = RA0_Q;
						2'd1: RCH_WD[i] = RA1_Q;
						2'd2: RCH_WD[i] = RB0_Q;
						2'd3: RCH_WD[i] = RB1_Q;
					endcase
					RBG_CH[i] <= RCH_WD[i];
				end
				
				if (RBG_PIPE[2].RxCH[i]) begin
					RCELLX[i] = RBG_PIPE[2].RxCELLX[i];
					RPALN[i] = !RSxREG[i].BMEN ? RBG_PN_PIPE[4][i].PALN : {RSxREG[i].BMP,4'b0000};
					RHF[i] = RBG_PN_PIPE[4][i].HF & ~RSxREG[i].BMEN;
					RPR[i] = !RSxREG[i].BMEN ? RBG_PN_PIPE[4][i].PR : RSxREG[i].BMPR;
					RCC[i] = !RSxREG[i].BMEN ? RBG_PN_PIPE[4][i].CC : RSxREG[i].BMCC;
					RCH[i] = RBG_CH[i] & {32{~RBG_TP_PIPE[4][i]}};
					RTPON[i] = RSxREG[i].TPON & ~RBG_TP_PIPE[4][i];
//					RWON[i] = 0;//RxW_EN[i];
					case (RSxREG[i].CHCN)//                  DC                             PR      CC      TPON      PALN
						3'b000: begin				//4bits/dot, 16 colors
							case (RCELLX[i] ^ {3{RHF[i]}})
							3'b000:begin RBG_DC[i][0] <= {4'h0,RCH[i][31:28]}; RBG_DP[i] <= {RPR[i], RCC[i], RTPON[i], RPALN[i]}; end
							3'b001:begin RBG_DC[i][0] <= {4'h0,RCH[i][27:24]}; RBG_DP[i] <= {RPR[i], RCC[i], RTPON[i], RPALN[i]}; end
							3'b010:begin RBG_DC[i][0] <= {4'h0,RCH[i][23:20]}; RBG_DP[i] <= {RPR[i], RCC[i], RTPON[i], RPALN[i]}; end
							3'b011:begin RBG_DC[i][0] <= {4'h0,RCH[i][19:16]}; RBG_DP[i] <= {RPR[i], RCC[i], RTPON[i], RPALN[i]}; end
							3'b100:begin RBG_DC[i][0] <= {4'h0,RCH[i][15:12]}; RBG_DP[i] <= {RPR[i], RCC[i], RTPON[i], RPALN[i]}; end
							3'b101:begin RBG_DC[i][0] <= {4'h0,RCH[i][11: 8]}; RBG_DP[i] <= {RPR[i], RCC[i], RTPON[i], RPALN[i]}; end
							3'b110:begin RBG_DC[i][0] <= {4'h0,RCH[i][ 7: 4]}; RBG_DP[i] <= {RPR[i], RCC[i], RTPON[i], RPALN[i]}; end
							3'b111:begin RBG_DC[i][0] <= {4'h0,RCH[i][ 3: 0]}; RBG_DP[i] <= {RPR[i], RCC[i], RTPON[i], RPALN[i]}; end
							endcase
						end
						3'b001: begin				//8bits/dot, 256 colors
							case (RCELLX[i][1:0] ^ {2{RHF[i]}})
							2'b00: begin RBG_DC[i][0] <= {     RCH[i][31:24]}; RBG_DP[i] <= {RPR[i], RCC[i], RTPON[i], RPALN[i]}; end
							2'b01: begin RBG_DC[i][0] <= {     RCH[i][23:16]}; RBG_DP[i] <= {RPR[i], RCC[i], RTPON[i], RPALN[i]}; end
							2'b10: begin RBG_DC[i][0] <= {     RCH[i][15: 8]}; RBG_DP[i] <= {RPR[i], RCC[i], RTPON[i], RPALN[i]}; end
							2'b11: begin RBG_DC[i][0] <= {     RCH[i][ 7: 0]}; RBG_DP[i] <= {RPR[i], RCC[i], RTPON[i], RPALN[i]}; end
							endcase
						end
						3'b010,3'b011: begin		//16bits/dot, 2048/32768 colors
							case (RCELLX[i][0:0] ^ {1{RHF[i]}})
							1'b0: begin  RBG_DC[i][2] <= {     RCH[i][31:24]};
							             RBG_DC[i][0] <= {     RCH[i][23:16]}; RBG_DP[i] <= {RPR[i], RCC[i], RTPON[i], 7'h00}; end
							1'b1: begin  RBG_DC[i][2] <= {     RCH[i][15: 8]};
							             RBG_DC[i][0] <= {     RCH[i][ 7: 0]}; RBG_DP[i] <= {RPR[i], RCC[i], RTPON[i], 7'h00}; end
							endcase
						end
						3'b100: begin				//32bits/dot, 16M colors
									       RBG_DC[i][3] <= {     RCH[i][31:24]}; 
									       RBG_DC[i][1] <= {     RCH[i][23:16]}; 
									       RBG_DC[i][2] <= {     RCH[i][15: 8]}; 
									       RBG_DC[i][0] <= {     RCH[i][ 7: 0]}; RBG_DP[i] <= {RPR[i], RCC[i], RTPON[i], 7'h00};
						end
						default:;
					endcase
				end
			end
			
			RBG_PIPE[1] <= RBG_PIPE[0];
			RBG_PIPE[2] <= RBG_PIPE[1];
			RBG_PIPE[3] <= RBG_PIPE[2];
			
			RBG_PN_PIPE[1] <= RBG_PN_PIPE[0];
			RBG_PN_PIPE[2] <= RBG_PN_PIPE[1];
			RBG_PN_PIPE[3] <= RBG_PN_PIPE[2];
			RBG_PN_PIPE[4] <= RBG_PN_PIPE[3];
			RBG_CT_PIPE[1] <= RBG_CT_PIPE[0];
			RBG_CT_PIPE[2] <= RBG_CT_PIPE[1];
			RBG_CT_PIPE[3] <= RBG_CT_PIPE[2];
			RBG_TP_PIPE[1] <= RBG_TP_PIPE[0];
			RBG_TP_PIPE[2] <= RBG_TP_PIPE[1];
			RBG_TP_PIPE[3] <= RBG_TP_PIPE[2];
			RBG_TP_PIPE[4] <= RBG_TP_PIPE[3];
		end
	end

	//Dots data
	bit [31:0] N0DC[16], N1DC[16], N2DC[16], N3DC[16], N4DC[16], N5DC[16];
	bit [31:0] RxDC[2];
	DotParam_t N0DP[16], N1DP[16], N2DP[16], N3DP[16], N4DP[16], N5DP[16];
	DotParam_t RxDP[2];
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			// synopsys translate_off
			
			// synopsys translate_on
		end
		else if (DOT_CE_R /*|| (DOT_CE_F & HRES[1])*/) begin
			if ((CELLX[2:0] | {HRES[1],2'b00}) == 3'd7) begin
				for (int i=0; i<8; i++) begin
					N0DC[i] <= N0DC[i+8]; N0DC[i+8] <= {NBG_CDC[3][i],NBG_CDC[1][i],NBG_CDC[2][i],NBG_CDC[0][i]     };
					N0DP[i] <= N0DP[i+8]; N0DP[i+8] <= NBG_CDP[0][i];
					N4DC[i] <= N4DC[i+8]; N4DC[i+8] <= {24'h000000,                          4'h0,NBG_CDC[0][i][7:4]};
					N4DP[i] <= N4DP[i+8]; N4DP[i+8] <= NBG_CDP[4][i];
					
					N1DC[i] <= N1DC[i+8]; N1DC[i+8] <= {16'h0000,                   NBG_CDC[3][i],NBG_CDC[1][i]     };
					N1DP[i] <= N1DP[i+8]; N1DP[i+8] <= NBG_CDP[1][i];
					N5DC[i] <= N5DC[i+8]; N5DC[i+8] <= {24'h000000,                          4'h0,NBG_CDC[1][i][7:4]};
					N5DP[i] <= N5DP[i+8]; N5DP[i+8] <= NBG_CDP[5][i];
					
					N2DC[i] <= N2DC[i+8]; N2DC[i+8] <= {24'h000000,                               NBG_CDC[2][i]};
					N2DP[i] <= N2DP[i+8]; N2DP[i+8] <= NBG_CDP[2][i];
					
					N3DC[i] <= N3DC[i+8]; N3DC[i+8] <= {24'h000000,                               NBG_CDC[3][i]};
					N3DP[i] <= N3DP[i+8]; N3DP[i+8] <= NBG_CDP[3][i];
				end
			end
			
			RxDC[0] <= {RBG_DC[0][3],RBG_DC[0][1],RBG_DC[0][2],RBG_DC[0][0]};
			RxDP[0] <= RBG_DP[0];
			
			RxDC[1] <= {RBG_DC[1][3],RBG_DC[1][1],RBG_DC[1][2],RBG_DC[1][0]};
			RxDP[1] <= RBG_DP[1];
		end
	end
	
	ScrollData_t NCX[4];
	always @(posedge CLK or negedge RST_N) begin
		ScrollData_t X[4];
		
		if (!RST_N) begin
			// synopsys translate_off
			NCX <= '{4{SCRLD_NULL}};
			// synopsys translate_on
		end
		else begin
			X[0] = NCX[0] + LZMX[0];
			X[1] = NCX[1] + LZMX[1];
			X[2] = NCX[2] + 19'h00100;
			X[3] = NCX[3] + 19'h00100;
			if (DOT_CE_R || (DOT_CE_F & HRES[1])) begin
				if (DOT_FETCH) begin
					NCX[0] <= X[0];
					NCX[1] <= X[1];
					NCX[2] <= X[2];
					NCX[3] <= X[3];
				end
			end
			if (DOT_CE_R) begin
				if (DOT_FETCH) begin
					if ((SCRNX[2:0] | {HRES[1],2'b00}) == 3'd7) begin
						NCX[0] <= X[0] & {11'h007,8'hFF};
						NCX[1] <= X[1] & {11'h007,8'hFF};
						NCX[2] <= X[2] & {11'h007,8'hFF};
						NCX[3] <= X[3] & {11'h007,8'hFF};
					end
				end
				if (VA_PIPE[2].LS) begin
					NCX[0] <= NSX[0] & {11'h007,8'hFF};
					NCX[1] <= NSX[1] & {11'h007,8'hFF};
					NCX[2] <= NSX[2] & {11'h007,8'hFF};
					NCX[3] <= NSX[3] & {11'h007,8'hFF};
				end
			end
		end
	end
	
	DotData_t R0DOT, N0DOT, N1DOT, N2DOT, N3DOT;
	bit [31:0] N0DOTDC, N1DOTDC, N2DOTDC, N3DOTDC;
	bit [31:0] R0DOTDC;
	DotParam_t N0DOTDP, N1DOTDP, N2DOTDP, N3DOTDP;
	DotParam_t R0DOTDP;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			// synopsys translate_off
			R0DOT <= DD_NULL;
			N0DOT <= DD_NULL;
			N1DOT <= DD_NULL;
			N2DOT <= DD_NULL;
			N3DOT <= DD_NULL;
			// synopsys translate_on
		end
		else if (DOT_CE_R || (DOT_CE_F & HRES[1])) begin
			R0DOTDC <= RxDC[0];
			R0DOTDP <= RxDP[0];
			
			if (RSxREG[1].ON) begin
				N0DOTDC <= RxDC[1];
				N0DOTDP <= RxDP[1];
			end else if (NSxREG[0].CHCN == 3'b000 && REGS.ZMCTL.N0ZMHF) begin
				N0DOTDC <= !NCX[0].INT[3] ? N0DC[{NCX[0].INT[4],NCX[0].INT[2:0]}] : N4DC[{NCX[0].INT[4],NCX[0].INT[2:0]}];
				N0DOTDP <= !NCX[0].INT[3] ? N0DP[{NCX[0].INT[4],NCX[0].INT[2:0]}] : N4DP[{NCX[0].INT[4],NCX[0].INT[2:0]}];
			end else if (NSxREG[0].CHCN == 3'b001 && REGS.ZMCTL.N0ZMHF) begin
				N0DOTDC <= !NCX[0].INT[3] ? N0DC[{NCX[0].INT[4],NCX[0].INT[2:0]}] : N2DC[{NCX[0].INT[4],NCX[0].INT[2:0]}];
				N0DOTDP <= !NCX[0].INT[3] ? N0DP[{NCX[0].INT[4],NCX[0].INT[2:0]}] : N2DP[{NCX[0].INT[4],NCX[0].INT[2:0]}];
			end else begin
				N0DOTDC <= N0DC[NCX[0].INT[3:0]];
				N0DOTDP <= N0DP[NCX[0].INT[3:0]];
			end
			
			if (NSxREG[1].CHCN == 3'b000 && REGS.ZMCTL.N1ZMHF) begin
				N1DOTDC <= !NCX[1].INT[3] ? N1DC[{NCX[1].INT[4],NCX[1].INT[2:0]}] : N5DC[{NCX[1].INT[4],NCX[1].INT[2:0]}];
				N1DOTDP <= !NCX[1].INT[3] ? N1DP[{NCX[1].INT[4],NCX[1].INT[2:0]}] : N5DP[{NCX[1].INT[4],NCX[1].INT[2:0]}];
			end else if (NSxREG[1].CHCN == 3'b001 && REGS.ZMCTL.N1ZMHF) begin
				N1DOTDC <= !NCX[1].INT[3] ? N1DC[{NCX[1].INT[4],NCX[1].INT[2:0]}] : N3DC[{NCX[1].INT[4],NCX[1].INT[2:0]}];
				N1DOTDP <= !NCX[1].INT[3] ? N1DP[{NCX[1].INT[4],NCX[1].INT[2:0]}] : N3DP[{NCX[1].INT[4],NCX[1].INT[2:0]}];
			end else begin
				N1DOTDC <= N1DC[NCX[1].INT[3:0]];
				N1DOTDP <= N1DP[NCX[1].INT[3:0]];
			end
				
			N2DOTDC <= N2DC[NCX[2].INT[3:0]];
			N2DOTDP <= N2DP[NCX[2].INT[3:0]];
			
			N3DOTDC <= N3DC[NCX[3].INT[3:0]];
			N3DOTDP <= N3DP[NCX[3].INT[3:0]];
		end
	end
	
	assign R0DOT = MakeDotData(R0DOTDC,R0DOTDP,RSxREG[0].CHCN);
	assign N0DOT = MakeDotData(N0DOTDC,N0DOTDP,NSxREG[0].CHCN);
	assign N1DOT = MakeDotData(N1DOTDC,N1DOTDP,NSxREG[1].CHCN);
	assign N2DOT = MakeDotData(N2DOTDC,N2DOTDP,(NSxREG[0].CHCN[0] && REGS.ZMCTL.N0ZMHF) || REGS.ZMCTL.N0ZMQT ? NSxREG[0].CHCN : NSxREG[2].CHCN);
	assign N3DOT = MakeDotData(N3DOTDC,N3DOTDP,(NSxREG[1].CHCN[0] && REGS.ZMCTL.N1ZMHF) || REGS.ZMCTL.N1ZMQT ? NSxREG[1].CHCN : NSxREG[3].CHCN);
								 
	//Sprite data
	SpriteDotData_t SDOT;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			// synopsys translate_off
			SDOT <= SDD_NULL;
			// synopsys translate_on
		end
		else if (DOT_CE_R || (DOT_CE_F & HRES[1])) begin
			SDOT <= SpriteData(REGS.SPCTL,FBD);
		end
	end
	
	//Priority
	wire TW0_HIT = DBG_EXT[0] ? W0_HIT_PIPE[16*2+1] : W0_HIT_PIPE[16*2];
	wire TW1_HIT = W1_HIT_PIPE[16*2];
	wire SW_EN     =   WinTest(TW0_HIT ^ REGS.WCTLC.SPW0A,TW1_HIT ^ REGS.WCTLC.SPW1A,SDOT.WN ^ REGS.WCTLC.SPSWA,REGS.WCTLC.SPW0E,REGS.WCTLC.SPW1E,REGS.WCTLC.SPSWE & REGS.SPCTL.SPWINEN,REGS.WCTLC.SPLOG);
	wire RxW_EN[2] = '{WinTest(TW0_HIT ^ REGS.WCTLC.R0W0A,TW1_HIT ^ REGS.WCTLC.R0W1A,SDOT.WN ^ REGS.WCTLC.SPSWA,REGS.WCTLC.R0W0E,REGS.WCTLC.R0W1E,REGS.WCTLC.R0SWE & REGS.SPCTL.SPWINEN,REGS.WCTLC.R0LOG),
	                   0};
	wire NxW_EN[4] = '{WinTest(TW0_HIT ^ REGS.WCTLA.N0W0A,TW1_HIT ^ REGS.WCTLA.N0W1A,SDOT.WN ^ REGS.WCTLC.SPSWA,REGS.WCTLA.N0W0E,REGS.WCTLA.N0W1E,REGS.WCTLA.N0SWE & REGS.SPCTL.SPWINEN,REGS.WCTLA.N0LOG),
	                   WinTest(TW0_HIT ^ REGS.WCTLA.N1W0A,TW1_HIT ^ REGS.WCTLA.N1W1A,SDOT.WN ^ REGS.WCTLC.SPSWA,REGS.WCTLA.N1W0E,REGS.WCTLA.N1W1E,REGS.WCTLA.N1SWE & REGS.SPCTL.SPWINEN,REGS.WCTLA.N1LOG),
	                   WinTest(TW0_HIT ^ REGS.WCTLB.N2W0A,TW1_HIT ^ REGS.WCTLB.N2W1A,SDOT.WN ^ REGS.WCTLC.SPSWA,REGS.WCTLB.N2W0E,REGS.WCTLB.N2W1E,REGS.WCTLB.N2SWE & REGS.SPCTL.SPWINEN,REGS.WCTLB.N2LOG),
	                   WinTest(TW0_HIT ^ REGS.WCTLB.N3W0A,TW1_HIT ^ REGS.WCTLB.N3W1A,SDOT.WN ^ REGS.WCTLC.SPSWA,REGS.WCTLB.N3W0E,REGS.WCTLB.N3W1E,REGS.WCTLB.N3SWE & REGS.SPCTL.SPWINEN,REGS.WCTLB.N3LOG)};
							 
	ScreenDot_t DOT_FST, DOT_SEC, DOT_THD, DOT_FTH;
	always @(posedge CLK or negedge RST_N) begin
		bit         SON, R0ON, N0ON, N1ON, N2ON, N3ON;
		bit   [2:0] SCAOS, R0CAOS, N0CAOS, N1CAOS, N2CAOS, N3CAOS;
		bit         R0SFC, N0SFC, N1SFC, N2SFC, N3SFC;
		bit   [2:0] SPRIN, R0PRIN, N0PRIN, N1PRIN, N2PRIN, N3PRIN;
		bit         SCCEN, R0CCEN, N0CCEN, N1CCEN, N2CCEN, N3CCEN, LCCCEN;
		bit         SCCM3, R0CCM3, N0CCM3, N1CCM3, N2CCM3, N3CCM3;
		bit   [4:0] SCCRT, R0CCRT, N0CCRT, N1CCRT, N2CCRT, N3CCRT, BKCCRT, LCCCRT;
		bit         SCOEN, R0COEN, N0COEN, N1COEN, N2COEN, N3COEN, BKCOEN;
		bit         SCOSL, R0COSL, N0COSL, N1COSL, N2COSL, N3COSL, BKCOSL;
		bit         BKSDEN, R0SDEN, N0SDEN, N1SDEN, N2SDEN, N3SDEN;
		bit         SLCEN, R0LCEN, N0LCEN, N1LCEN, N2LCEN, N3LCEN;
		ScreenDot_t FST, SEC, THD, FTH;
		bit   [2:0] FST_PRI, SEC_PRI, THD_PRI, FTH_PRI;
		
		if (!RST_N) begin
			// synopsys translate_off
			DOT_FST <= SD_NULL;
			DOT_SEC <= SD_NULL;
			DOT_THD <= SD_NULL;
			DOT_FTH <= SD_NULL;
			// synopsys translate_on
		end
		else if (DOT_CE_R || (DOT_CE_F & HRES[1])) begin
			SON  =                                                                           ~SDOT.TP  & (~SDOT.SD | ~SCRN_EN[7])        & SCRN_EN[5] & ~(SW_EN     & SCRN_EN[6]);
			R0ON = (               RSxREG[0].ON) &                                           ~R0DOT.TP &                                   SCRN_EN[4] & ~(RxW_EN[0] & SCRN_EN[6]);
			N0ON = (NSxREG[0].ON | RSxREG[1].ON) &                                           ~N0DOT.TP &                                   SCRN_EN[0] & ~(NxW_EN[0] & SCRN_EN[6]);
			N1ON = (NSxREG[1].ON               ) & ~NSxREG[0].CHCN[2] &                      ~N1DOT.TP &                                   SCRN_EN[1] & ~(NxW_EN[1] & SCRN_EN[6]);
			N2ON = (NSxREG[2].ON               ) & ~NSxREG[0].CHCN[2] & ~NSxREG[0].CHCN[1] & ~N2DOT.TP &                                   SCRN_EN[2] & ~(NxW_EN[2] & SCRN_EN[6]);
			N3ON = (NSxREG[3].ON               ) & ~NSxREG[0].CHCN[2] & ~NSxREG[1].CHCN[1] & ~N3DOT.TP &                                   SCRN_EN[3] & ~(NxW_EN[3] & SCRN_EN[6]);
			
			SCAOS = REGS.CRAOFB.SPCAOS;
			R0CAOS = REGS.CRAOFB.R0CAOS;
			N0CAOS = NSxREG[0].CAOS;
			N1CAOS = NSxREG[1].CAOS;
			N2CAOS = NSxREG[2].CAOS;
			N3CAOS = NSxREG[3].CAOS;
			
			R0SFC = SFCMatch(REGS.SFSEL.R0SFCS,REGS.SFCODE,R0DOT.DC[3:0]);
			N0SFC = SFCMatch(REGS.SFSEL.N0SFCS,REGS.SFCODE,N0DOT.DC[3:0]);
			N1SFC = SFCMatch(REGS.SFSEL.N1SFCS,REGS.SFCODE,N1DOT.DC[3:0]);
			N2SFC = SFCMatch(REGS.SFSEL.N2SFCS,REGS.SFCODE,N2DOT.DC[3:0]);
			N3SFC = SFCMatch(REGS.SFSEL.N3SFCS,REGS.SFCODE,N3DOT.DC[3:0]);
			
			case (SDOT.PR)
				3'h0: SPRIN = REGS.PRISA.S0PRIN;
				3'h1: SPRIN = REGS.PRISA.S1PRIN;
				3'h2: SPRIN = REGS.PRISB.S2PRIN;
				3'h3: SPRIN = REGS.PRISB.S3PRIN;
				3'h4: SPRIN = REGS.PRISC.S4PRIN;
				3'h5: SPRIN = REGS.PRISC.S5PRIN;
				3'h6: SPRIN = REGS.PRISD.S6PRIN;
				3'h7: SPRIN = REGS.PRISD.S7PRIN;
			endcase
			R0PRIN = RSxREG[0].SPRM == 2'b01 ? {RSxREG[0].PRIN[2:1],R0DOT.PR} : RSxREG[0].SPRM == 2'b10 ? {RSxREG[0].PRIN[2:1],R0DOT.PR & R0SFC} : RSxREG[0].PRIN;
			N0PRIN = NSxREG[0].SPRM == 2'b01 ? {NSxREG[0].PRIN[2:1],N0DOT.PR} : NSxREG[0].SPRM == 2'b10 ? {NSxREG[0].PRIN[2:1],N0DOT.PR & N0SFC} : NSxREG[0].PRIN; 
			N1PRIN = NSxREG[1].SPRM == 2'b01 ? {NSxREG[1].PRIN[2:1],N1DOT.PR} : NSxREG[1].SPRM == 2'b10 ? {NSxREG[1].PRIN[2:1],N1DOT.PR & N1SFC} : NSxREG[1].PRIN;
			N2PRIN = NSxREG[2].SPRM == 2'b01 ? {NSxREG[2].PRIN[2:1],N2DOT.PR} : NSxREG[2].SPRM == 2'b10 ? {NSxREG[2].PRIN[2:1],N2DOT.PR & N2SFC} : NSxREG[2].PRIN;
			N3PRIN = NSxREG[3].SPRM == 2'b01 ? {NSxREG[3].PRIN[2:1],N3DOT.PR} : NSxREG[3].SPRM == 2'b10 ? {NSxREG[3].PRIN[2:1],N3DOT.PR & N3SFC} : NSxREG[3].PRIN;
			
			SCCEN = REGS.CCCTL.SPCCEN & ((REGS.SPCTL.SPCCCS == 2'b00 & SPRIN <= REGS.SPCTL.SPCCN & SDOT.P) | 
			                             (REGS.SPCTL.SPCCCS == 2'b01 & SPRIN == REGS.SPCTL.SPCCN & SDOT.P) |
												  (REGS.SPCTL.SPCCCS == 2'b10 & SPRIN >= REGS.SPCTL.SPCCN & SDOT.P) |
												  (REGS.SPCTL.SPCCCS == 2'b11));
			R0CCEN = RSxREG[0].SCCM == 2'b01 ? R0DOT.CC & RSxREG[0].CCEN : RSxREG[0].SCCM == 2'b10 ? R0SFC & R0DOT.CC & RSxREG[0].CCEN : RSxREG[0].CCEN;
			N0CCEN = NSxREG[0].SCCM == 2'b01 ? N0DOT.CC & NSxREG[0].CCEN : NSxREG[0].SCCM == 2'b10 ? N0SFC & N0DOT.CC & NSxREG[0].CCEN : NSxREG[0].CCEN;
			N1CCEN = NSxREG[1].SCCM == 2'b01 ? N1DOT.CC & NSxREG[1].CCEN : NSxREG[1].SCCM == 2'b10 ? N1SFC & N1DOT.CC & NSxREG[1].CCEN : NSxREG[1].CCEN;
			N2CCEN = NSxREG[2].SCCM == 2'b01 ? N2DOT.CC & NSxREG[2].CCEN : NSxREG[2].SCCM == 2'b10 ? N2SFC & N2DOT.CC & NSxREG[2].CCEN : NSxREG[2].CCEN;
			N3CCEN = NSxREG[3].SCCM == 2'b01 ? N3DOT.CC & NSxREG[3].CCEN : NSxREG[3].SCCM == 2'b10 ? N3SFC & N3DOT.CC & NSxREG[3].CCEN : NSxREG[3].CCEN;
			LCCCEN = REGS.CCCTL.LCCCEN;
			
			SCCM3 = REGS.SPCTL.SPCCCS == 2'b11;
			R0CCM3 = RSxREG[0].SCCM == 2'b11;
			N0CCM3 = NSxREG[0].SCCM == 2'b11;
			N1CCM3 = NSxREG[1].SCCM == 2'b11;
			N2CCM3 = NSxREG[2].SCCM == 2'b11;
			N3CCM3 = NSxREG[3].SCCM == 2'b11;
			
			case (SDOT.CC)
				3'h0: SCCRT = REGS.CCRSA.S0CCRT;
				3'h1: SCCRT = REGS.CCRSA.S1CCRT;
				3'h2: SCCRT = REGS.CCRSB.S2CCRT;
				3'h3: SCCRT = REGS.CCRSB.S3CCRT;
				3'h4: SCCRT = REGS.CCRSC.S4CCRT;
				3'h5: SCCRT = REGS.CCRSC.S5CCRT;
				3'h6: SCCRT = REGS.CCRSD.S6CCRT;
				3'h7: SCCRT = REGS.CCRSD.S7CCRT;
			endcase
			R0CCRT = RSxREG[0].CCRT;
			N0CCRT = NSxREG[0].CCRT;
			N1CCRT = NSxREG[1].CCRT;
			N2CCRT = NSxREG[2].CCRT;
			N3CCRT = NSxREG[3].CCRT;
			BKCCRT = REGS.CCRLB.BKCCRT;
			LCCCRT = REGS.CCRLB.LCCCRT;
			
			SCOEN = REGS.CLOFEN.SPCOEN; SCOSL = REGS.CLOFSL.SPCOSL;
			R0COEN = RSxREG[0].COEN;    R0COSL = RSxREG[0].COSL;
			N0COEN = NSxREG[0].COEN;    N0COSL = NSxREG[0].COSL;
			N1COEN = NSxREG[1].COEN;    N1COSL = NSxREG[1].COSL;
			N2COEN = NSxREG[2].COEN;    N2COSL = NSxREG[2].COSL;
			N3COEN = NSxREG[3].COEN;    N3COSL = NSxREG[3].COSL;
			BKCOEN = REGS.CLOFEN.BKCOEN;BKCOSL = REGS.CLOFSL.BKCOSL;
			
			BKSDEN = REGS.SDCTL.BKSDEN & SDOT.SD & SCRN_EN[7];
			R0SDEN = REGS.SDCTL.R0SDEN & SDOT.SD & SCRN_EN[7];
			N0SDEN = REGS.SDCTL.N0SDEN & SDOT.SD & SCRN_EN[7];
			N1SDEN = REGS.SDCTL.N1SDEN & SDOT.SD & SCRN_EN[7];
			N2SDEN = REGS.SDCTL.N2SDEN & SDOT.SD & SCRN_EN[7];
			N3SDEN = REGS.SDCTL.N3SDEN & SDOT.SD & SCRN_EN[7];
			
			SLCEN = REGS.LNCLEN.SPLCEN;
			R0LCEN = REGS.LNCLEN.R0LCEN;
			N0LCEN = REGS.LNCLEN.N0LCEN;
			N1LCEN = REGS.LNCLEN.N1LCEN;
			N2LCEN = REGS.LNCLEN.N2LCEN;
			N3LCEN = REGS.LNCLEN.N3LCEN;
			
			FST = {3'b000,1'b0,1'b0,BKCCRT,BKCOEN,BKCOSL,BKSDEN,1'b0,1'b0,BACK_DC}; FST_PRI = 3'd0;
			SEC = {3'b000,1'b0,1'b0,BKCCRT,BKCOEN,BKCOSL,BKSDEN,1'b0,1'b0,BACK_DC}; SEC_PRI = 3'd0;
			THD = {3'b000,1'b0,1'b0,BKCCRT,BKCOEN,BKCOSL,BKSDEN,1'b0,1'b0,BACK_DC}; THD_PRI = 3'd0;
			if (DISP) begin
				if          (SON  && SPRIN                     ) begin
					THD = SEC; THD_PRI = SEC_PRI;
					SEC = FST; SEC_PRI = FST_PRI;
					FST = {SCAOS,SCCEN,SCCM3,SCCRT,SCOEN,SCOSL,1'b0,SLCEN,SDOT.P,SDOT.DC}; FST_PRI = SPRIN;
				end
`ifdef DEBUG
				FST_PRI5_DBG <= FST_PRI;
				SEC_PRI5_DBG <= SEC_PRI;
				THD_PRI5_DBG <= THD_PRI;
`endif
			
				if          (R0ON && R0PRIN && R0PRIN > FST_PRI) begin
					THD = SEC; THD_PRI = SEC_PRI;
					SEC = FST; SEC_PRI = FST_PRI;
					FST = {R0CAOS,R0CCEN,R0CCM3,R0CCRT,R0COEN,R0COSL,R0SDEN,R0LCEN,R0DOT.P,R0DOT.DC}; FST_PRI = R0PRIN;
				end else if (R0ON && R0PRIN && R0PRIN > SEC_PRI) begin
					THD = SEC; THD_PRI = SEC_PRI;
					SEC = {R0CAOS,R0CCEN,R0CCM3,R0CCRT,R0COEN,R0COSL,R0SDEN,R0LCEN,R0DOT.P,R0DOT.DC}; SEC_PRI = R0PRIN;
				end
`ifdef DEBUG
				FST_PRI4_DBG <= FST_PRI;
				SEC_PRI4_DBG <= SEC_PRI;
				THD_PRI4_DBG <= THD_PRI;
`endif
				
				if          (N0ON && N0PRIN && N0PRIN > FST_PRI) begin
					THD = SEC; THD_PRI = SEC_PRI;
					SEC = FST; SEC_PRI = FST_PRI;
					FST = {N0CAOS,N0CCEN,N0CCM3,N0CCRT,N0COEN,N0COSL,N0SDEN,N0LCEN,N0DOT.P,N0DOT.DC}; FST_PRI = N0PRIN;
				end else if (N0ON && N0PRIN && N0PRIN > SEC_PRI) begin
					THD = SEC; THD_PRI = SEC_PRI;
					SEC = {N0CAOS,N0CCEN,N0CCM3,N0CCRT,N0COEN,N0COSL,N0SDEN,N0LCEN,N0DOT.P,N0DOT.DC}; SEC_PRI = N0PRIN;
				end else if (N0ON && N0PRIN && N0PRIN > THD_PRI) begin
					THD = {N0CAOS,N0CCEN,N0CCM3,N0CCRT,N0COEN,N0COSL,N0SDEN,N0LCEN,N0DOT.P,N0DOT.DC}; THD_PRI = N0PRIN;
				end
`ifdef DEBUG
				FST_PRI0_DBG <= FST_PRI;
				SEC_PRI0_DBG <= SEC_PRI;
				THD_PRI0_DBG <= THD_PRI;
`endif
				
				if          (N1ON && N1PRIN && N1PRIN > FST_PRI) begin
					THD = SEC; THD_PRI = SEC_PRI;
					SEC = FST; SEC_PRI = FST_PRI;
					FST = {N1CAOS,N1CCEN,N1CCM3,N1CCRT,N1COEN,N1COSL,N1SDEN,N1LCEN,N1DOT.P,N1DOT.DC}; FST_PRI = N1PRIN;
				end else if (N1ON && N1PRIN && N1PRIN > SEC_PRI) begin
					THD = SEC; THD_PRI = SEC_PRI;
					SEC = {N1CAOS,N1CCEN,N1CCM3,N1CCRT,N1COEN,N1COSL,N1SDEN,N1LCEN,N1DOT.P,N1DOT.DC}; SEC_PRI = N1PRIN;
				end else if (N1ON && N1PRIN && N1PRIN > THD_PRI) begin
					THD = {N1CAOS,N1CCEN,N1CCM3,N1CCRT,N1COEN,N1COSL,N1SDEN,N1LCEN,N1DOT.P,N1DOT.DC}; THD_PRI = N1PRIN;
				end
`ifdef DEBUG
				FST_PRI1_DBG <= FST_PRI;
				SEC_PRI1_DBG <= SEC_PRI;
				THD_PRI1_DBG <= THD_PRI;
`endif
				
				if          (N2ON && N2PRIN && N2PRIN > FST_PRI) begin
					THD = SEC; THD_PRI = SEC_PRI;
					SEC = FST; SEC_PRI = FST_PRI;
					FST = {N2CAOS,N2CCEN,N2CCM3,N2CCRT,N2COEN,N2COSL,N2SDEN,N2LCEN,N2DOT.P,N2DOT.DC}; FST_PRI = N2PRIN;
				end else if (N2ON && N2PRIN && N2PRIN > SEC_PRI) begin
					THD = SEC; THD_PRI = SEC_PRI;
					SEC = {N2CAOS,N2CCEN,N2CCM3,N2CCRT,N2COEN,N2COSL,N2SDEN,N2LCEN,N2DOT.P,N2DOT.DC}; SEC_PRI = N2PRIN;
				end else if (N2ON && N2PRIN && N2PRIN > THD_PRI) begin
					THD = {N2CAOS,N2CCEN,N2CCM3,N2CCRT,N2COEN,N2COSL,N2SDEN,N2LCEN,N2DOT.P,N2DOT.DC}; THD_PRI = N2PRIN;
				end
`ifdef DEBUG
				FST_PRI2_DBG <= FST_PRI;
				SEC_PRI2_DBG <= SEC_PRI;
				THD_PRI2_DBG <= THD_PRI;
`endif
				
				if          (N3ON && N3PRIN && N3PRIN > FST_PRI) begin
					THD = SEC; THD_PRI = SEC_PRI;
					SEC = FST; SEC_PRI = FST_PRI;
					FST = {N3CAOS,N3CCEN,N3CCM3,N3CCRT,N3COEN,N3COSL,N3SDEN,N3LCEN,N3DOT.P,N3DOT.DC}; FST_PRI = N3PRIN;
				end else if (N3ON && N3PRIN && N3PRIN > SEC_PRI) begin
					THD = SEC; THD_PRI = SEC_PRI;
					SEC = {N3CAOS,N3CCEN,N3CCM3,N3CCRT,N3COEN,N3COSL,N3SDEN,N3LCEN,N3DOT.P,N3DOT.DC}; SEC_PRI = N3PRIN;
				end else if (N3ON && N3PRIN && N3PRIN > THD_PRI) begin
					THD = {N3CAOS,N3CCEN,N3CCM3,N3CCRT,N3COEN,N3COSL,N3SDEN,N3LCEN,N3DOT.P,N3DOT.DC}; THD_PRI = N3PRIN;
				end
`ifdef DEBUG
				FST_PRI3_DBG <= FST_PRI;
				SEC_PRI3_DBG <= SEC_PRI;
				THD_PRI3_DBG <= THD_PRI;
`endif
			end
			
			DOT_FST <= FST;
			if (!FST.LCEN) begin
				DOT_SEC <= SEC;
				DOT_THD <= THD;
				DOT_FTH <= '0;
			end else begin
				DOT_SEC <= {3'b000,LCCCEN,1'b0,LCCCRT,1'b0,1'b0,1'b0,1'b0,1'b1,{13'b0000000000000,LINE_PAL}};
				DOT_THD <= SEC;
				DOT_FTH <= THD;
			end
		end
	end
	
	//Dots color
	bit [10:0] PAL_N;
	always_comb begin
		bit [10: 0] PAL;
		bit [ 2: 0] CAOS;
		
		case (DOTCLK_DIV & {~HRES[1],1'b1})
			2'b00: {CAOS,PAL} = {DOT_FST.CAOS,DOT_FST.DC[10:0]};
			2'b01: {CAOS,PAL} = {DOT_SEC.CAOS,DOT_SEC.DC[10:0]};
			2'b10: {CAOS,PAL} = {DOT_THD.CAOS,DOT_THD.DC[10:0]};
			2'b11: {CAOS,PAL} = {DOT_FTH.CAOS,DOT_FTH.DC[10:0]};
		endcase
		PAL_N = {CAOS,8'b00000000} + PAL;
	end
	
	DotColor_t DC_FST_LATCH, DC_SEC_LATCH, DC_THD_LATCH;
	bit        CC_FST;
	DotColor_t CFST, CSEC, CTHD, CFTH;
	bit  [4:0] CCRT;
	bit        CCENFST, CCENSEC, CCENTHD;
	bit        PTHD;
	bit        LCEN;
	bit        COEN;
	bit        COSL;
	bit        SDEN;
	bit        HBLANK2;
	always @(posedge CLK or negedge RST_N) begin
		bit [23:0] DC;
		bit        CC;
		
		if (!RST_N) begin
			// synopsys translate_off
			DC_FST_LATCH <= DC_NULL;
			DC_SEC_LATCH <= DC_NULL;
			DC_THD_LATCH <= DC_NULL;
			CC_FST <= 0;
			CFST <= DC_NULL;
			CSEC <= DC_NULL;
			CTHD <= DC_NULL;
			CFTH <= DC_NULL;
			CCRT <= '0;
			CCENFST <= 0;
			CCENSEC <= 0;
			CCENTHD <= 0;
			PTHD <= 0;
			LCEN <= 0;
			SDEN <= 0;
			COEN <= 0;
			COSL <= 0;
			// synopsys translate_on
		end
		else begin
			if (CE_R) begin
				case (REGS.RAMCTL.CRMD)
					2'b00: begin DC = Color555To888(PAL0_Q);                       CC =              PAL0_Q[15]; end
					2'b01: begin DC = Color555To888(!PAL_N[10] ? PAL0_Q : PAL1_Q); CC = !PAL_N[10] ? PAL0_Q[15] : PAL1_Q[15]; end
					default: begin DC = {PAL0_Q[7:0],PAL1_Q};                      CC =              PAL0_Q[15]; end
				endcase
				case (DOTCLK_DIV & {~HRES[1],1'b1})
					2'd0: {CC_FST,DC_FST_LATCH} <= {CC,DC};
					2'd1: DC_SEC_LATCH <= DC;
					2'd2: DC_THD_LATCH <= DC;
					2'd3: ;
				endcase
			end
			
			if (DOT_CE_R || (DOT_CE_F & HRES[1])) begin
				CFST <= !DOT_FST.P ? DOT_FST.DC : DC_FST_LATCH;
				CSEC <= !DOT_SEC.P ? DOT_SEC.DC : DC_SEC_LATCH;
				CTHD <= !DOT_THD.P ? DOT_THD.DC : DC_THD_LATCH;
				CFTH <= !DOT_FTH.P ? DOT_FTH.DC : DC;
				CCRT <= !REGS.CCCTL.CCRTMD ? DOT_FST.CCRT : DOT_SEC.CCRT;
				CCENFST <= !DOT_FST.CCM3 ? DOT_FST.CCEN : DOT_FST.CCEN & (CC_FST | ~DOT_FST.P);
				CCENSEC <= DOT_SEC.CCEN;
				CCENTHD <= DOT_THD.CCEN;
				PTHD <= DOT_THD.P; 
				LCEN <= DOT_FST.LCEN; 
				COEN <= DOT_FST.COEN; 
				COSL <= DOT_FST.COSL;
				SDEN <= DOT_FST.SDEN;
			end
			
			if (DOT_CE_R) begin
				HBLANK2 <= HBLANK;
			end
			if ((HBLANK && DOT_CE_R) || (HBLANK2 && DOT_CE_F)) begin
				CFST <= DC_NULL;
				CSEC <= DC_NULL;
				CTHD <= DC_NULL;
				CFTH <= DC_NULL;
				CCENFST <= 0;
				CCENSEC <= 0;
				CCENTHD <= 0;
				PTHD <= 0;
				LCEN <= 0;
				SDEN <= 0;
				COEN <= 0;
				COSL <= 0;
			end
		end
	end
	
	DotColor_t DCOL;
	bit        HBLANK3;
	always @(posedge CLK or negedge RST_N) begin
		DotColor_t CSEC2;
		DotColor_t C;
		
		if (!RST_N) begin
			// synopsys translate_off
			DCOL <= DC_NULL;
			// synopsys translate_on
		end else begin
			if (DOT_CE_R || DOT_CE_F) begin
				CSEC2 = ExtColorCalc(CSEC, CCENSEC, CTHD, PTHD, CCENTHD, CFTH, LCEN, REGS.RAMCTL.CRMD);
				C = ColorCalc(CFST, CSEC2, CCRT, CCENFST, REGS.CCCTL.CCMD);
				DCOL.B <= Shadow(ColorOffset(C.B, REGS.COAB.COBL, REGS.COBB.COBL, COEN, COSL), SDEN); 
				DCOL.G <= Shadow(ColorOffset(C.G, REGS.COAG.COGR, REGS.COBG.COGR, COEN, COSL), SDEN); 
				DCOL.R <= Shadow(ColorOffset(C.R, REGS.COAR.CORD, REGS.COBR.CORD, COEN, COSL), SDEN); 
			end
			
			if (DOT_CE_R) begin
				HBLANK3 <= HBLANK2;
			end
			
			if (!DISP) begin
				DCOL <= REGS.TVMD.BDCLMD ? BACK_DC : DC_NULL;
			end else if ((HBLANK2 && DOT_CE_R) || (HBLANK3 && DOT_CE_F)) begin
				DCOL <= DC_NULL;
			end
		end
	end

	assign R = DCOL.R;
	assign G = DCOL.G;
	assign B = DCOL.B;
	assign VBL_N = ~VBLANK;
	assign HBL_N = ~HBLANK3;
	assign VS_N = ~VSYNC;
	assign HS_N = ~HSYNC;
	assign FIELD = ODD && &REGS.TVMD.LSMD;
	assign INTERLACE = &REGS.TVMD.LSMD;
	
	
	//Color RAM
	wire         PAL_SEL = (A[20:19] == 2'b10) && !CS_N && !AD_N;	//100000-17FFFF
	wire         PAL_WE = PAL_SEL && !WE_N && !DTEN_N && !REQ_N;
	wire [10: 1] IO_PAL_A   = REGS.RAMCTL.CRMD == 2'b10 ? A[11:2] : A[10:1];
	wire         IO_PAL0_WE = (REGS.RAMCTL.CRMD == 2'b01 ? ~A[11] : REGS.RAMCTL.CRMD == 2'b10 ? ~A[1] : 1'b1) & PAL_WE;
	wire         IO_PAL1_WE = (REGS.RAMCTL.CRMD == 2'b01 ?  A[11] : REGS.RAMCTL.CRMD == 2'b10 ?  A[1] : 1'b1) & PAL_WE;
	wire [10: 1] PAL_A = PAL_N[9:0];
	
	bit          IO_PAL_RD;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			// synopsys translate_off
			IO_PAL_RD <= 0;
			// synopsys translate_on
		end else begin
			if (PAL_SEL && WE_N && DTEN_N && !REQ_N) begin
				IO_PAL_RD <= REGS.RAMCTL.CRMD == 2'b10 ? A[1] : A[11];
			end
		end
	end
	
	VDP2_PAL_RAM pal1
	(
		.CLK(CLK),
		
		.ADDR_A(PAL_A),
		.DATA_A(16'h0000),
		.WREN_A(2'b00),
		.Q_A(PAL0_Q),
		
		.ADDR_B(IO_PAL_A),
		.DATA_B(DI),
		.WREN_B({2{IO_PAL0_WE}} & ~DQM),
		.Q_B(PAL0_DO)
	);
	
	VDP2_PAL_RAM pal2
	(
		.CLK(CLK),
		
		.ADDR_A(!REGS.RAMCTL.CRKTE ? PAL_A : (CT_CRAM_A + DOTCLK_DIV[0])),
		.DATA_A(16'h0000),
		.WREN_A(2'b00),
		.Q_A(PAL1_Q),
		
		.ADDR_B(IO_PAL_A),
		.DATA_B(DI),
		.WREN_B({2{IO_PAL1_WE}} & ~DQM),
		.Q_B(PAL1_DO)
	);
	wire [15:0] PAL_DO = !IO_PAL_RD ? PAL0_DO : PAL1_DO;
	
	bit  [10:1] CT_CRAM_A;
	bit  [31:0] CT_CRAM_Q;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			// synopsys translate_off
			CT_CRAM_A <= '0;
			CT_CRAM_Q <= '0;
			// synopsys translate_on
		end else begin
			if (RBG_PIPE[0].RxCRCT[0] && DOT_CE_R) begin
				CT_CRAM_A <= RxCT_ADDR[0][10:1];
			end
			if (RBG_PIPE[0].RxCRCT[1] && DOT_CE_R) begin
				CT_CRAM_A <= RxCT_ADDR[1][10:1];
			end
			
			if (CE_R) begin
				case (DOTCLK_DIV)
					2'd0: CT_CRAM_Q[31:16] <= PAL1_Q;
					2'd1: CT_CRAM_Q[15: 0] <= PAL1_Q;
					2'd2: ;
					2'd3: ;
				endcase
			end
		end
	end
	
	//Registers
	wire VRAM_SEL = ~A[20] & ~CS_N & ~AD_N ;	//000000-0FFFFF
	wire VRAM_REQ = VRAM_SEL & ~REQ_N;
	wire REG_SEL = (A[20:18] == 3'b110) & ~CS_N & ~AD_N;
	
	bit [20:1] A;
	bit        WE_N;
	bit  [1:0] DQM;
	bit        BURST;
	bit [15:0] REG_DO;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			REGS.TVMD <= '0;
			REGS.EXTEN <= '0;
			REGS.TVSTAT <= '0;
			REGS.VRSIZE <= '0;
//			REGS.HCNT <= '0;
//			REGS.VCNT <= '0;
			REGS.RSRV0 <= '0;
			REGS.RAMCTL <= '0;
			REGS.CYCA0L <= '0;
			REGS.CYCA0U <= '0;
			REGS.CYCA1L <= '0;
			REGS.CYCA1U <= '0;
			REGS.CYCB0L <= '0;
			REGS.CYCB0U <= '0;
			REGS.CYCB1L <= '0;
			REGS.CYCB1U <= '0;
			REGS.BGON <= '0;
			REGS.MZCTL <= '0;
			REGS.SFSEL <= '0;
			REGS.SFCODE <= '0;
			REGS.CHCTLA <= '0;
			REGS.CHCTLB <= '0;
			REGS.BMPNA <= '0;
			REGS.BMPNB <= '0;
			REGS.PNCN0 <= '0;
			REGS.PNCN1 <= '0;
			REGS.PNCN2 <= '0;
			REGS.PNCN3 <= '0;
			REGS.PNCR <= '0;
			REGS.PLSZ <= '0;
			REGS.MPOFN <= '0;
			REGS.MPOFR <= '0;
			REGS.MPABN0 <= '0;
			REGS.MPCDN0 <= '0;
			REGS.MPABN1 <= '0;
			REGS.MPCDN1 <= '0;
			REGS.MPABN2 <= '0;
			REGS.MPCDN2 <= '0;
			REGS.MPABN3 <= '0;
			REGS.MPCDN3 <= '0;
			REGS.MPABRA <= '0;
			REGS.MPCDRA <= '0;
			REGS.MPEFRA <= '0;
			REGS.MPGHRA <= '0;
			REGS.MPIJRA <= '0;
			REGS.MPKLRA <= '0;
			REGS.MPMNRA <= '0;
			REGS.MPOPRA <= '0;
			REGS.MPABRB <= '0;
			REGS.MPCDRB <= '0;
			REGS.MPEFRB <= '0;
			REGS.MPGHRB <= '0;
			REGS.MPIJRB <= '0;
			REGS.MPKLRB <= '0;
			REGS.MPMNRB <= '0;
			REGS.MPOPRB <= '0;
			REGS.SCXIN0 <= '0;
			REGS.SCXDN0 <= '0;
			REGS.SCYIN0 <= '0;
			REGS.SCYDN0 <= '0;
			REGS.ZMXIN0 <= '0;
			REGS.ZMXDN0 <= '0;
			REGS.ZMYIN0 <= '0;
			REGS.ZMYDN0 <= '0;
			REGS.SCXIN1 <= '0;
			REGS.SCXDN1 <= '0;
			REGS.SCYIN1 <= '0;
			REGS.SCYDN1 <= '0;
			REGS.ZMXIN1 <= '0;
			REGS.ZMXDN1 <= '0;
			REGS.ZMYIN1 <= '0;
			REGS.ZMYDN1 <= '0;
			REGS.SCXN2 <= '0;
			REGS.SCYN2 <= '0;
			REGS.SCXN3 <= '0;
			REGS.SCYN3 <= '0;
			REGS.ZMCTL <= '0;
			REGS.SCRCTL <= '0;
			REGS.VCSTAU <= '0;
			REGS.VCSTAL <= '0;
			REGS.LSTA0U <= '0;
			REGS.LSTA0L <= '0;
			REGS.LSTA1U <= '0;
			REGS.LSTA1L <= '0;
			REGS.LCTAU <= '0;
			REGS.LCTAL <= '0;
			REGS.BKTAU <= '0;
			REGS.BKTAL <= '0;
			REGS.RPMD <= '0;
			REGS.RPRCTL <= '0;
			REGS.KTCTL <= '0;
			REGS.KTAOF <= '0;
			REGS.OVPNRA <= '0;
			REGS.OVPNRB <= '0;
			REGS.RPTAU <= '0;
			REGS.RPTAL <= '0;
			REGS.WPSX0 <= '0;
			REGS.WPSY0 <= '0;
			REGS.WPEX0 <= '0;
			REGS.WPEY0 <= '0;
			REGS.WPSX1 <= '0;
			REGS.WPSY1 <= '0;
			REGS.WPEX1 <= '0;
			REGS.WPEY1 <= '0;
			REGS.WCTLA <= '0;
			REGS.WCTLB <= '0;
			REGS.WCTLC <= '0;
			REGS.WCTLD <= '0;
			REGS.LWTA0U <= '0;
			REGS.LWTA0L <= '0;
			REGS.LWTA1U <= '0;
			REGS.LWTA1L <= '0;
			REGS.SPCTL <= '0;
			REGS.SDCTL <= '0;
			REGS.CRAOFA <= '0;
			REGS.CRAOFB <= '0;
			REGS.LNCLEN <= '0;
			REGS.SFPRMD <= '0;
			REGS.CCCTL <= '0;
			REGS.SFCCMD <= '0;
			REGS.PRISA <= '0;
			REGS.PRISB <= '0;
			REGS.PRISC <= '0;
			REGS.PRISD <= '0;
			REGS.PRINA <= '0;
			REGS.PRINB <= '0;
			REGS.PRIR <= '0;
			REGS.RSRV1 <= '0;
			REGS.CCRSA <= '0;
			REGS.CCRSB <= '0;
			REGS.CCRSC <= '0;
			REGS.CCRSD <= '0;
			REGS.CCRNA <= '0;
			REGS.CCRNB <= '0;
			REGS.CCRR <= '0;
			REGS.CCRLB <= '0;
			REGS.CLOFEN <= '0;
			REGS.CLOFSL <= '0;
			REGS.COAR <= '0;
			REGS.COAG <= '0;
			REGS.COAB <= '0;
			REGS.COBR <= '0;
			REGS.COBG <= '0;
			REGS.COBB <= '0;

			REG_DO <= '0;
		end else if (!RES_N) begin
				
		end else begin
			if (REG_SEL && !REQ_N) begin
				if (!WE_N && !DTEN_N) begin
					case ({A[8:1],1'b0})
						9'h000: REGS.TVMD <= DI & TVMD_MASK;
						9'h002: REGS.EXTEN <= DI & EXTEN_MASK;
						9'h006: REGS.VRSIZE <= DI & VRSIZE_MASK;
						9'h00C: REGS.RSRV0 <= DI & RSRV_MASK;
						9'h00E: REGS.RAMCTL <= DI & RAMCTL_MASK;
						9'h010: REGS.CYCA0L <= DI & CYCx0L_MASK;
						9'h012: REGS.CYCA0U <= DI & CYCx0U_MASK;
						9'h014: REGS.CYCA1L <= DI & CYCx1L_MASK;
						9'h016: REGS.CYCA1U <= DI & CYCx1U_MASK;
						9'h018: REGS.CYCB0L <= DI & CYCx0L_MASK;
						9'h01A: REGS.CYCB0U <= DI & CYCx0U_MASK;
						9'h01C: REGS.CYCB1L <= DI & CYCx1L_MASK;
						9'h01E: REGS.CYCB1U <= DI & CYCx1U_MASK;
						9'h020: REGS.BGON <= DI & BGON_MASK;
						9'h022: REGS.MZCTL <= DI & MZCTL_MASK;
						9'h024: REGS.SFSEL <= DI & SFSEL_MASK;
						9'h026: REGS.SFCODE <= DI & SFCODE_MASK;
						9'h028: REGS.CHCTLA <= DI & CHCTLA_MASK;
						9'h02A: REGS.CHCTLB <= DI & CHCTLB_MASK;
						9'h02C: REGS.BMPNA <= DI & BMPNA_MASK;
						9'h02E: REGS.BMPNB <= DI & BMPNB_MASK;
						9'h030: REGS.PNCN0 <= DI & PNCNx_MASK;
						9'h032: REGS.PNCN1 <= DI & PNCNx_MASK;
						9'h034: REGS.PNCN2 <= DI & PNCNx_MASK;
						9'h036: REGS.PNCN3 <= DI & PNCNx_MASK;
						9'h038: REGS.PNCR <= DI & PNCR_MASK;
						9'h03A: REGS.PLSZ <= DI & PLSZ_MASK;
						9'h03C: REGS.MPOFN <= DI & MPOFN_MASK;
						9'h03E: REGS.MPOFR <= DI & MPOFR_MASK;
						9'h040: REGS.MPABN0 <= DI & MPABNx_MASK;
						9'h042: REGS.MPCDN0 <= DI & MPCDNx_MASK;
						9'h044: REGS.MPABN1 <= DI & MPABNx_MASK;
						9'h046: REGS.MPCDN1 <= DI & MPCDNx_MASK;
						9'h048: REGS.MPABN2 <= DI & MPABNx_MASK;
						9'h04A: REGS.MPCDN2 <= DI & MPCDNx_MASK;
						9'h04C: REGS.MPABN3 <= DI & MPABNx_MASK;
						9'h04E: REGS.MPCDN3 <= DI & MPCDNx_MASK;
						9'h050: REGS.MPABRA <= DI & MPABRx_MASK;
						9'h052: REGS.MPCDRA <= DI & MPCDRx_MASK;
						9'h054: REGS.MPEFRA <= DI & MPEFRx_MASK;
						9'h056: REGS.MPGHRA <= DI & MPGHRx_MASK;
						9'h058: REGS.MPIJRA <= DI & MPIJRx_MASK;
						9'h05A: REGS.MPKLRA <= DI & MPKLRx_MASK;
						9'h05C: REGS.MPMNRA <= DI & MPMNRx_MASK;
						9'h05E: REGS.MPOPRA <= DI & MPOPRx_MASK;
						9'h060: REGS.MPABRB <= DI & MPABRx_MASK;
						9'h062: REGS.MPCDRB <= DI & MPCDRx_MASK;
						9'h064: REGS.MPEFRB <= DI & MPEFRx_MASK;
						9'h066: REGS.MPGHRB <= DI & MPGHRx_MASK;
						9'h068: REGS.MPIJRB <= DI & MPIJRx_MASK;
						9'h06A: REGS.MPKLRB <= DI & MPKLRx_MASK;
						9'h06C: REGS.MPMNRB <= DI & MPMNRx_MASK;
						9'h06E: REGS.MPOPRB <= DI & MPOPRx_MASK;
						9'h070: REGS.SCXIN0 <= DI & SCXINx_MASK;
						9'h072: REGS.SCXDN0 <= DI & SCXDNx_MASK;
						9'h074: REGS.SCYIN0 <= DI & SCYINx_MASK;
						9'h076: REGS.SCYDN0 <= DI & SCYDNx_MASK;
						9'h078: REGS.ZMXIN0 <= DI & ZMXINx_MASK;
						9'h07A: REGS.ZMXDN0 <= DI & ZMXDNx_MASK;
						9'h07C: REGS.ZMYIN0 <= DI & ZMYINx_MASK;
						9'h07E: REGS.ZMYDN0 <= DI & ZMYDNx_MASK;
						9'h080: REGS.SCXIN1 <= DI & SCXINx_MASK;
						9'h082: REGS.SCXDN1 <= DI & SCXDNx_MASK;
						9'h084: REGS.SCYIN1 <= DI & SCYINx_MASK;
						9'h086: REGS.SCYDN1 <= DI & SCYDNx_MASK;
						9'h088: REGS.ZMXIN1 <= DI & ZMXINx_MASK;
						9'h08A: REGS.ZMXDN1 <= DI & ZMXDNx_MASK;
						9'h08C: REGS.ZMYIN1 <= DI & ZMYINx_MASK;
						9'h08E: REGS.ZMYDN1 <= DI & ZMYDNx_MASK;
						9'h090: REGS.SCXN2 <= DI & SCXNx_MASK;
						9'h092: REGS.SCYN2 <= DI & SCYNx_MASK;
						9'h094: REGS.SCXN3 <= DI & SCXNx_MASK;
						9'h096: REGS.SCYN3 <= DI & SCYNx_MASK;
						9'h098: REGS.ZMCTL <= DI & ZMCTL_MASK;
						9'h09A: REGS.SCRCTL <= DI & SCRCTL_MASK;
						9'h09C: REGS.VCSTAU <= DI & VCSTAU_MASK;
						9'h09E: REGS.VCSTAL <= DI & VCSTAL_MASK;
						9'h0A0: REGS.LSTA0U <= DI & LSTAxU_MASK;
						9'h0A2: REGS.LSTA0L <= DI & LSTAxL_MASK;
						9'h0A4: REGS.LSTA1U <= DI & LSTAxU_MASK;
						9'h0A6: REGS.LSTA1L <= DI & LSTAxL_MASK;
						9'h0A8: REGS.LCTAU <= DI & LCTAU_MASK;
						9'h0AA: REGS.LCTAL <= DI & LCTAL_MASK;
						9'h0AC: REGS.BKTAU <= DI & BKTAU_MASK;
						9'h0AE: REGS.BKTAL <= DI & BKTAL_MASK;
						9'h0B0: REGS.RPMD <= DI & RPMD_MASK;
						9'h0B2: REGS.RPRCTL <= DI & RPRCTL_MASK;
						9'h0B4: REGS.KTCTL <= DI & KTCTL_MASK;
						9'h0B6: REGS.KTAOF <= DI & KTAOF_MASK;
						9'h0B8: REGS.OVPNRA <= DI & OVPNRx_MASK;
						9'h0BA: REGS.OVPNRB <= DI & OVPNRx_MASK;
						9'h0BC: REGS.RPTAU <= DI & RPTAU_MASK;
						9'h0BE: REGS.RPTAL <= DI & RPTAL_MASK;
						9'h0C0: REGS.WPSX0 <= DI & WPSXx_MASK;
						9'h0C2: REGS.WPSY0 <= DI & WPSYx_MASK;
						9'h0C4: REGS.WPEX0 <= DI & WPEXx_MASK;
						9'h0C6: REGS.WPEY0 <= DI & WPEYx_MASK;
						9'h0C8: REGS.WPSX1 <= DI & WPSXx_MASK;
						9'h0CA: REGS.WPSY1 <= DI & WPSYx_MASK;
						9'h0CC: REGS.WPEX1 <= DI & WPEXx_MASK;
						9'h0CE: REGS.WPEY1 <= DI & WPEYx_MASK;
						9'h0D0: REGS.WCTLA <= DI & WCTLA_MASK;
						9'h0D2: REGS.WCTLB <= DI & WCTLB_MASK;
						9'h0D4: REGS.WCTLC <= DI & WCTLC_MASK;
						9'h0D6: REGS.WCTLD <= DI & WCTLD_MASK;
						9'h0D8: REGS.LWTA0U <= DI & LWTAxU_MASK;
						9'h0DA: REGS.LWTA0L <= DI & LWTAxL_MASK;
						9'h0DC: REGS.LWTA1U <= DI & LWTAxU_MASK;
						9'h0DE: REGS.LWTA1L <= DI & LWTAxL_MASK;
						9'h0E0: REGS.SPCTL <= DI & SPCTL_MASK;
						9'h0E2: REGS.SDCTL <= DI & SDCTL_MASK;
						9'h0E4: REGS.CRAOFA <= DI & CRAOFA_MASK;
						9'h0E6: REGS.CRAOFB <= DI & CRAOFB_MASK;
						9'h0E8: REGS.LNCLEN <= DI & LNCLEN_MASK;
						9'h0EA: REGS.SFPRMD <= DI & SFPRMD_MASK;
						9'h0EC: REGS.CCCTL <= DI & CCCTL_MASK;
						9'h0EE: REGS.SFCCMD <= DI & SFCCMD_MASK;
						9'h0F0: REGS.PRISA <= DI & PRISA_MASK;
						9'h0F2: REGS.PRISB <= DI & PRISB_MASK;
						9'h0F4: REGS.PRISC <= DI & PRISC_MASK;
						9'h0F6: REGS.PRISD <= DI & PRISD_MASK;
						9'h0F8: REGS.PRINA <= DI & PRINA_MASK;
						9'h0FA: REGS.PRINB <= DI & PRINB_MASK;
						9'h0FC: REGS.PRIR <= DI & PRIR_MASK;
						9'h0FE: REGS.RSRV1 <= DI & RSRV_MASK;
						9'h100: REGS.CCRSA <= DI & CCRSA_MASK;
						9'h102: REGS.CCRSB <= DI & CCRSB_MASK;
						9'h104: REGS.CCRSC <= DI & CCRSC_MASK;
						9'h106: REGS.CCRSD <= DI & CCRSD_MASK;
						9'h108: REGS.CCRNA <= DI & CCRNA_MASK;
						9'h10A: REGS.CCRNB <= DI & CCRNA_MASK;
						9'h10C: REGS.CCRR <= DI & CCRR_MASK;
						9'h10E: REGS.CCRLB <= DI & CCRLB_MASK;
						9'h110: REGS.CLOFEN <= DI & CLOFEN_MASK;
						9'h112: REGS.CLOFSL <= DI & CLOFSL_MASK;
						9'h114: REGS.COAR <= DI & COxR_MASK;
						9'h116: REGS.COAG <= DI & COxG_MASK;
						9'h118: REGS.COAB <= DI & COxB_MASK;
						9'h11A: REGS.COBR <= DI & COxR_MASK;
						9'h11C: REGS.COBG <= DI & COxG_MASK;
						9'h11E: REGS.COBB <= DI & COxB_MASK;
						default:;
					endcase
				end else begin
					case ({A[8:1],1'b0})
						9'h000: REG_DO <= REGS.TVMD & TVMD_MASK;
						9'h002: REG_DO <= REGS.EXTEN & EXTEN_MASK;
						9'h004: REG_DO <= {REGS.TVSTAT[15:8], 4'h0, VBLANK|~DISP, HBLANK, ~ODD|~REGS.TVMD.LSMD[1], PAL} & TVSTAT_MASK;
						9'h006: REG_DO <= REGS.VRSIZE & VRSIZE_MASK;
						9'h008: REG_DO <= REGS.HCNT & HCNT_MASK;
						9'h00A: REG_DO <= REGS.VCNT & VCNT_MASK;
						9'h00E: REG_DO <= REGS.RAMCTL & RAMCTL_MASK;
						default: REG_DO <= '0;
					endcase
					if ({A[8:1],1'b0} == 9'h002 && !REGS.EXTEN.EXLTEN) begin	//EXTEN
						REGS.HCNT.HCT = {H_CNT,DOTCLK_DIV[1]};
						REGS.VCNT.VCT = REGS.TVMD.LSMD == 2'b11 ? {V_CNT,ODD} : {1'b0,V_CNT};
						REGS.TVSTAT.EXLTFG <= 1;
					end
					if ({A[8:1],1'b0} == 9'h004) begin								//TVSTAT
						REGS.TVSTAT.EXLTFG <= 0;
						REGS.TVSTAT.EXSYFG <= 0;
					end
				end
			end
		end
	end
	
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			A <= '1;
			WE_N <= 1;
			DQM <= '1;
			BURST <= 0;
		end
		else begin
			if (!CS_N && DTEN_N && AD_N && CE_R) begin
				if (!DI[15]) begin
					A[20:9] <= DI[11:0];
					WE_N <= DI[14];
					BURST <= DI[13];
				end else begin
					A[8:1] <= DI[7:0];
					DQM <= DI[13:12];
				end
			end
			if (/*BURST &&*/ (VRAM_SEL || REG_SEL || PAL_SEL) && !REQ_N) begin
				A <= A + 20'd1;
			end
		end
	end
	
	
	assign RDY_N = ~VRAM_RRDY | ~VRAM_WRDY | VRAM_WLOCK | (FIFO_FULL & BURST);
	
	assign DO = REG_SEL ? REG_DO : 
	            PAL_SEL ? PAL_DO : 
					VRAM_DO;
	
	//debug
`ifdef DEBUG
	assign VA_PIPE0 = VA_PIPE[0];
	assign NBG_A0VA_DBG = NBG_A0VA;
//	assign N0SCX = SCX[0];
//	assign N0SCY = SCY[0];
//	assign CH_PIPE0 = RBG_CH_PIPE[0];
//	assign CH_PIPE1 = RBG_CH_PIPE[1];
//	assign CH_PIPE2 = RBG_CH_PIPE[2];
	assign NBG_CDC0_DBG = NBG_CDC[0];
	assign NBG_CDC1_DBG = NBG_CDC[1];
	assign NBG_CDC2_DBG = NBG_CDC[2];
	assign NBG_CDC3_DBG = NBG_CDC[3];
	assign NBG_CDP0_DBG = NBG_CDP[0];
	assign RBG0_CDC0_DBG = RBG_DC[0][0];
	assign RBG0_CDC1_DBG = RBG_DC[0][1];
	assign RBG0_CDC2_DBG = RBG_DC[0][2];
	assign RBG0_CDC3_DBG = RBG_DC[0][3];
	assign RBG0_CDP_DBG = RBG_DP[0];
	assign RBG1_CDC0_DBG = RBG_DC[1][0];
	assign RBG1_CDC1_DBG = RBG_DC[1][1];
	assign RBG1_CDC2_DBG = RBG_DC[1][2];
	assign RBG1_CDC3_DBG = RBG_DC[1][3];
	assign RBG1_CDP_DBG = RBG_DP[1];
//	assign N0DOTN_DBG = N0DOTN;
	assign R0DOT_DBG = R0DOT;
	assign N0DOT_DBG = N0DOT;
	assign N1DOT_DBG = N1DOT;
	assign N2DOT_DBG = N2DOT;
	assign N3DOT_DBG = N3DOT;
//	assign DOT_FST_DBG = DOT_FST;
//	assign DOT_SEC_DBG = DOT_SEC;
//	assign DOT_THD_DBG = DOT_THD;
	assign KAx0_DBG = KAx[0];
	assign RA_D_ERR = {RA_D[63:48] != 16'd0,RA_D[47:32] != 16'd0,RA_D[31:16] != 16'd0,RA_D[15:0] != 16'd0};
	assign RB_D_ERR = {RB_D[47:32] != 16'd0,RB_D[47:32] != 16'd0,RB_D[31:16] != 16'd0,RB_D[15:0] != 16'd0};
	assign REG_DBG = REGS.RPRCTL^REGS.PLSZ^REGS.CCCTL^REGS.LNCLEN/*^REGS.TVMD^REGS.EXTEN^REGS.RAMCTL^REGS.BGON^REGS.MZCTL^REGS.SFSEL^REGS.SFCODE^REGS.ZMCTL^REGS.SCRCTL^
							REGS.KTCTL^REGS.KTAOF^REGS.WCTLA^REGS.WCTLB^REGS.WCTLC^REGS.WCTLD^REGS.SPCTL^REGS.SDCTL^REGS.CRAOFA^REGS.CRAOFB^
							REGS.SFPRMD^REGS.SFCCMD^REGS.CCRSA^REGS.CCRSB^REGS.CCRSC^REGS.CCRSD^REGS.CCRNA^REGS.CCRNB^REGS.CCRR^REGS.CCRLB^REGS.CLOFEN^REGS.CLOFSL*/;
`endif

endmodule

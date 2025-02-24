module VDP1 (
	input              CLK,
	input              RST_N,
	input              CE_R,
	input              CE_F,
	input              EN,
	
	input              RES_N,

	input      [15: 0] DI,
	output     [15: 0] DO,
	input              CS_N,
	input              AD_N,
	input              DTEN_N,
	input              REQ_N,
	output             RDY_N,
	
	output             IRQ_N,
	
	input              DCE_R,
	input              DCE_F,
	input              HTIM_N,
	input              VTIM_N,
	input      [15: 0] VOUTI,
	output     [15: 0] VOUTO,
	
	output reg [18: 1] VRAM_A,
	output reg [15: 0] VRAM_D,
	input      [15: 0] VRAM_Q,
	output reg [ 1: 0] VRAM_WE,
	output reg         VRAM_RD,
	output reg [ 8: 0] VRAM_BLEN,
	input              VRAM_RDY,
	
	output     [17: 1] FB0_A,
	output     [15: 0] FB0_D,
	input      [15: 0] FB0_Q,
	output     [ 1: 0] FB0_WE,
	output             FB0_RD,
	
	output     [17: 1] FB1_A,
	output     [15: 0] FB1_D,
	input      [15: 0] FB1_Q,
	output     [ 1: 0] FB1_WE,
	output             FB1_RD,
	input              FB_RDY,
	output             FB_MODE3,
	
	input              FAST,
	
	input      [ 7: 0] DBG_EXT
	
`ifdef DEBUG
	                   ,
	output             DBG_START,
	output             DBG_CMD_END,
	output     [18: 1] DBG_SPR_ADDR,
	output             DBG_LINE_DRAW_STEP,
	output             DBG_TEXT_READ_STEP,
	output             DBG_COL_DRAW_STEP,
	output     [ 8: 0] DBG_TEXT_X,
	output     [ 7: 0] DBG_TEXT_Y,
	output     [15: 0] ORIG_C_DBG,
	output     [10: 0] DRAW_X_DBG,
	output     [10: 0] DRAW_Y_DBG,
	output       RGB_t DBG_ORIG_RGB,
	output             TP_DBG,
	output             SCLIP_DBG,
	output             UCLIP_DBG,
	output             DBG_LINE_OVER,
	output             DBG_DRAW_OVER,
	output     [ 7: 0] FRAMES_DBG,
	output     [ 7: 0] START_DRAW_CNT,
	output     [18: 1] DBG_CMD_ADDR16,
	output     [18: 1] DBG_CMD_ADDR_LAST,
	output   CMDSRCA_t DBG_CMD_CMDSRCA_LAST,
	output     [ 7: 0] DBG_CMD_CNT,
	output     [ 7: 0] DBG_CMD_WAIT_CNT,
	output             DBG_CMD_ADDR_ERR,
	output       RGB_t DBG_GHCOLOR_C,
	output       RGB_t DBG_GHCOLOR_D,
	output reg         DBG_SKIP,
	output             DBG_PENALTY_OVER
`endif
);
	import VDP1_PKG::*;
	
	TVMR_t       TVMR;
	FBCR_t       FBCR;
	PTMR_t       PTMR;
	EWDR_t       EWDR;
	EWLR_t       EWLR;
	EWRR_t       EWRR;
	EDSR_t       EDSR;
	LOPR_t       LOPR;
	COPR_t       COPR;
	MODR_t       MODR;
	bit          DIE,DIL;

	bit          FRAME_START;
	bit          FRAME_ERASE;
	bit          VBLANK_ERASE;
	bit          FRAME_ERASE_EN;
	bit          VBLANK_ERASE_EN;
	bit          OUT_EN;
	bit          DRAW_TERMINATE;
	bit          DRAW_END;
	
	bit  [15: 0] CLT_Q;
	
	//Frame buffers
	bit          FB_SEL;
	bit  [17: 1] FB_A;
	bit  [15: 0] FB_D;
	bit  [ 1: 0] FB_WE;
	bit          FB_RD;
	bit  [15: 0] FB_DRAW_Q;
	bit          FB_DRAW_WAIT;
	bit  [17: 1] FB_DISP_A;
	bit          FB_DISP_WE;
	bit  [15: 0] FB_DISP_Q;
	bit  [17: 1] FB_ERASE_A;
//	bit          FRAME;
	wire         FB_ERASE_WE = (FRAME_ERASE_EN & DCE_R) | (VBLANK_ERASE_EN & CE_R);
	wire [17: 1] FB_OUT_A = VBLANK_ERASE_EN ? FB_ERASE_A : FB_DISP_A;
	
	assign FB0_A  = FB_SEL ? FB_A             : FB_OUT_A;
	assign FB1_A  = FB_SEL ? FB_OUT_A         : FB_A;
	assign FB0_D  = FB_SEL ? FB_D             : EWDR;
	assign FB1_D  = FB_SEL ? EWDR             : FB_D;
	assign FB0_WE = FB_SEL ? FB_WE /*& CE_R*/ : {2{FB_ERASE_WE}};
	assign FB1_WE = FB_SEL ? {2{FB_ERASE_WE}} : FB_WE /*& CE_R*/;
	assign FB0_RD = FB_SEL ? FB_RD            : 1'b0;
	assign FB1_RD = FB_SEL ? 1'b0             : FB_RD;
	
	assign FB_DRAW_Q = FB_SEL ? FB0_Q : FB1_Q;
	assign FB_DISP_Q = FB_SEL ? FB1_Q : FB0_Q;
	
	assign FB_MODE3 = (TVMR.TVM[1:0] == 2'b11);
	
	typedef enum bit [5:0] {
		CMDS_IDLE,  
		CMDS_READ, 
		CMDS_GRD_LOAD,
		CMDS_EXEC,
		CMDS_CLT_LOAD,
		CMDS_DELAY,
		CMDS_GRD_CALC_COL,
		CMDS_GRD_CALC_LEFT,
		CMDS_GRD_CALC_RIGHT,
		CMDS_GRD_CALC_ROW,
		CMDS_GRD_CALC_LINE,
		CMDS_ROW_DRAW,
		CMDS_NSPR_START,
		CMDS_SSPR_START,
		CMDS_DSPR_START,
		CMDS_POLYGON_START,
		CMDS_POLYLINE_START,
		CMDS_LINE_START,
		CMDS_EDGE_INIT,
		CMDS_LINE_INIT,
		CMDS_PRE_DRAW,
		CMDS_NSPR_CALCX,
		CMDS_NSPR_DRAW,
		CMDS_SSPR_CALCX,
		CMDS_SSPR_CALCTX,
		CMDS_SSPR_DRAW,
		CMDS_POLYGON_CALCE,
		CMDS_POLYGON_CALCH,
		CMDS_POLYGON_CALCTY,
		CMDS_LINE_CALC,
		CMDS_LINE_CALCTX,
		CMDS_LINE_DRAW,
		CMDS_AA_DRAW,
		CMDS_LINE_END,
		CMDS_LINE_NEXT,
		CMDS_END
	} CMDState_t;
	CMDState_t CMD_ST;
	bit  [18: 1] CMD_ADDR;
	bit          CMD_READ;
	bit          CMD_READ_DONE;
	bit  [18: 1] SPR_ADDR;
	bit          SPR_READ;
	bit  [15: 0] SPR_DATA;
	bit          SPR_DATA_READY;
	bit  [18: 1] CLT_ADDR;
	bit          CLT_READ;
	bit          CLT_READ_DONE;
	bit  [18: 1] GRD_ADDR;
	bit          GRD_READ;
	bit          GRD_READ_DONE;
	bit  [15: 0] GRD_TBL[4];
	
	CMDTBL_t     CMD;
	Clip_t       SYS_CLIP;
	Clip_t       USR_CLIP;
	Coord_t      LOC_COORD;
	Vertex_t     VERTA,VERTB,VERTC,VERTD;
	Pattern_t    PAT;
	bit  [ 8: 0] TEXT_X;
	bit  [ 7: 0] TEXT_Y;
	bit  [16: 3] SPR_OFFSY;
	bit  [11: 0] POLY_LSX;
	bit  [11: 0] POLY_LSY;
	bit  [11: 0] POLY_RSX;
	bit  [11: 0] POLY_RSY;
	bit          POLY_LDIRX;
	bit          POLY_LDIRY;
	bit          POLY_RDIRX;
	bit          POLY_RDIRY;
	bit  [ 1: 0] POLY_S;
	
	Coord_t      LINE_VERTA;
	Coord_t      LINE_VERTB;
	Vertex_t     LEFT_VERT;
	Vertex_t     RIGHT_VERT;
	Vertex_t     BOTTOM_VERT;
	bit          LINE_DIRX;
	bit          LINE_DIRY;
	bit          LINE_CLIP;
	bit          LINE_S;
	bit  [11: 0] ROW_WIDTH;
	bit  [11: 0] COL_HEIGHT,LEFT_HEIGHT,RIGHT_HEIGHT;
	bit          COL_DIRY;
	bit          SPR_COL_ENLARGE;
	bit          EC_FIND;
	bit  [10: 0] AA_X;
	bit  [10: 0] AA_Y;
	bit          AA;
	bit  [10: 0] AA_X_INC;
	bit  [10: 0] AA_Y_INC;
	bit  [ 1: 0] DIR;
	bit          HSS_EN;
	bit          DRAW_WAIT;
	bit          DRAW_ENABLE;
	
	bit          LINE_DRAW_STEP;
	bit          LINE_AA_STEP;
	bit          COL_DRAW_STEP;
	bit          TEXT_X_READ_STEP;
	bit          TEXTY_READ_STEP, TEXT_Y_READ_STEP;
	bit          LEFT_COL_X_STEP, LEFT_COL_Y_STEP;
	bit          RIGHT_COL_X_STEP,RIGHT_COL_Y_STEP;
	bit  [ 3: 0] GRD_CALC_STATE;
	
	wire [ 8: 0] ORIG_WIDTH = {CMD.CMDSIZE.SX,3'b000} | ~|CMD.CMDSIZE.SX;
	wire [ 7: 0] ORIG_HEIGHT = {CMD.CMDSIZE.SY} | ~|CMD.CMDSIZE.SY;
	wire         TEXT_DIRX = (CMD.CMDCTRL.DIR[0] ^ DIR[0]);
	wire         TEXT_DIRY = (CMD.CMDCTRL.DIR[1] ^ DIR[1]);
	wire         IS_PAT_EC = (CMD.CMDCTRL.COMM <= 4'h3 && !CMD.CMDPMOD.ECD && PAT.EC && !HSS_EN);
	
	bit  [12: 0] COL_D;
	bit  [12: 0] NEXT_LEFT_COL_ERROR_X, NEXT_LEFT_COL_ERROR_Y, LEFT_COL_ERROR_X, LEFT_COL_ERROR_Y, LEFT_COL_ERROR_X_INC, LEFT_COL_ERROR_Y_INC, LEFT_COL_ERROR_ADJ;
	bit  [12: 0] NEXT_RIGHT_COL_ERROR_X, NEXT_RIGHT_COL_ERROR_Y, RIGHT_COL_ERROR_X, RIGHT_COL_ERROR_Y, RIGHT_COL_ERROR_X_INC, RIGHT_COL_ERROR_Y_INC, RIGHT_COL_ERROR_ADJ;
	bit  [12: 0] NEXT_LEFT_D_ERROR, LEFT_D_ERROR, LEFT_D_ERROR_INC, LEFT_D_ERROR_ADJ;
	bit  [12: 0] NEXT_RIGHT_D_ERROR, RIGHT_D_ERROR, RIGHT_D_ERROR_INC, RIGHT_D_ERROR_ADJ;
	bit          LEFT_D_ERROR_CMP, RIGHT_D_ERROR_CMP, LEFT_COL_ERROR_X_CMP, LEFT_COL_ERROR_Y_CMP, RIGHT_COL_ERROR_X_CMP, RIGHT_COL_ERROR_Y_CMP;
					 
	bit  [12: 0] NEXT_LINE_ERROR, LINE_ERROR, LINE_ERROR_INC, LINE_ERROR_ADJ;
	bit  [12: 0] NEXT_TEXT_ERROR, TEXT_ERROR, TEXT_ERROR_INC, TEXT_ERROR_ADJ;
	bit  [12: 0] NEXT_TEXT_Y_ERROR, TEXT_Y_ERROR, TEXT_Y_ERROR_INC, TEXT_Y_ERROR_ADJ;
	always_comb begin
		bit COL_STEP;
		bit  [12: 0] TEXT_ERROR_ADJUSTED,LINE_ERROR_ICREMENTED;
		bit  [12: 0] TEXT_Y_ERROR_ADJUSTED;
		bit  [12: 0] LEFT_D_ERROR_ICREMENTED,LEFT_COL_ERROR_X_ICREMENTED,LEFT_COL_ERROR_Y_ICREMENTED;
		bit  [12: 0] RIGHT_D_ERROR_ICREMENTED,RIGHT_COL_ERROR_X_ICREMENTED,RIGHT_COL_ERROR_Y_ICREMENTED;
		
		LINE_DRAW_STEP = 0;
		LINE_AA_STEP = 0;
		COL_DRAW_STEP = 0;
		TEXT_X_READ_STEP = 0;
		TEXT_Y_READ_STEP = 0;
		{LEFT_COL_X_STEP,LEFT_COL_Y_STEP} = '0;
		{RIGHT_COL_X_STEP,RIGHT_COL_Y_STEP} = '0;
		
		
		NEXT_TEXT_ERROR = '0;
		NEXT_LINE_ERROR = '0;
		NEXT_TEXT_Y_ERROR = '0;
		NEXT_LEFT_D_ERROR = '0;
		NEXT_LEFT_COL_ERROR_X = '0;
		NEXT_LEFT_COL_ERROR_Y = '0;
		NEXT_RIGHT_D_ERROR = '0;
		NEXT_RIGHT_COL_ERROR_X = '0;
		NEXT_RIGHT_COL_ERROR_Y = '0;
		case (CMD_ST) 
			CMDS_NSPR_DRAW: begin		
				LINE_DRAW_STEP = 1;		
				TEXT_X_READ_STEP = 1;
			end
			
			CMDS_PRE_DRAW,
			CMDS_SSPR_DRAW,
			CMDS_LINE_DRAW: begin
				if (CMD.CMDCTRL.COMM >= 4'h4) begin
					LINE_DRAW_STEP = 1;
					TEXT_X_READ_STEP = 0;
				end else begin
					if (!TEXT_ERROR[12]) begin
						TEXT_ERROR_ADJUSTED = $signed(TEXT_ERROR) - $signed(TEXT_ERROR_ADJ);
						if (TEXT_ERROR_ADJUSTED[12]) begin
							LINE_DRAW_STEP = 1;
							NEXT_TEXT_ERROR = $signed(TEXT_ERROR_ADJUSTED) + $signed(TEXT_ERROR_INC);
						end else begin
							NEXT_TEXT_ERROR = $signed(TEXT_ERROR_ADJUSTED);
						end
					end else begin
						TEXT_ERROR_ADJUSTED = $signed(TEXT_ERROR);
						LINE_DRAW_STEP = 1;
						NEXT_TEXT_ERROR = $signed(TEXT_ERROR_ADJUSTED) + $signed(TEXT_ERROR_INC);
					end
					
					if (!NEXT_TEXT_ERROR[12]) begin
						TEXT_X_READ_STEP = 1;
					end
				end
					
				if (LINE_DRAW_STEP && CMD_ST == CMDS_LINE_DRAW) begin
					LINE_ERROR_ICREMENTED = LINE_ERROR + LINE_ERROR_INC;
					if ($signed(LINE_ERROR_ICREMENTED) >= 13'sd1) begin
						NEXT_LINE_ERROR = LINE_ERROR_ICREMENTED + LINE_ERROR_ADJ;
						LINE_AA_STEP = 1;
					end else begin
						NEXT_LINE_ERROR = LINE_ERROR_ICREMENTED;
					end
				end
			end
			
			CMDS_AA_DRAW,
			CMDS_LINE_END: begin
				LINE_DRAW_STEP = AA;
			end
			
			CMDS_ROW_DRAW: begin
				if (CMD.CMDCTRL.COMM >= 4'h4) begin
					COL_DRAW_STEP = 1;
				end else begin
					if (!TEXT_Y_ERROR[12]) begin
						TEXT_Y_ERROR_ADJUSTED = $signed(TEXT_Y_ERROR) - $signed(TEXT_Y_ERROR_ADJ);
						if (!TEXT_Y_ERROR_ADJUSTED[12]) begin
							NEXT_TEXT_Y_ERROR = $signed(TEXT_Y_ERROR_ADJUSTED);
						end else begin
							COL_DRAW_STEP = 1;
							NEXT_TEXT_Y_ERROR = $signed(TEXT_Y_ERROR_ADJUSTED) + $signed(TEXT_Y_ERROR_INC);
						end
						TEXT_Y_READ_STEP = 1;
					end else begin
						TEXT_Y_ERROR_ADJUSTED = $signed(TEXT_Y_ERROR);
						COL_DRAW_STEP = 1;
						NEXT_TEXT_Y_ERROR = $signed(TEXT_Y_ERROR_ADJUSTED) + $signed(TEXT_Y_ERROR_INC);
					end
				end
			end
			
			CMDS_LINE_NEXT: begin
				LEFT_D_ERROR_ICREMENTED = LEFT_D_ERROR + LEFT_D_ERROR_INC;
				if ($signed(LEFT_D_ERROR_ICREMENTED) >= $signed({13{LEFT_D_ERROR_CMP}})) begin
					NEXT_LEFT_D_ERROR = LEFT_D_ERROR_ICREMENTED + LEFT_D_ERROR_ADJ;
					
					LEFT_COL_ERROR_X_ICREMENTED = LEFT_COL_ERROR_X + LEFT_COL_ERROR_X_INC;
					if ($signed(LEFT_COL_ERROR_X_ICREMENTED) >= $signed({13{LEFT_COL_ERROR_X_CMP}})) begin
						NEXT_LEFT_COL_ERROR_X = LEFT_COL_ERROR_X_ICREMENTED + LEFT_COL_ERROR_ADJ;
						LEFT_COL_X_STEP = 1;
					end else begin
						NEXT_LEFT_COL_ERROR_X = LEFT_COL_ERROR_X_ICREMENTED;
					end
					
					LEFT_COL_ERROR_Y_ICREMENTED = LEFT_COL_ERROR_Y + LEFT_COL_ERROR_Y_INC;
					if ($signed(LEFT_COL_ERROR_Y_ICREMENTED) >= $signed({13{LEFT_COL_ERROR_Y_CMP}})) begin
						NEXT_LEFT_COL_ERROR_Y = LEFT_COL_ERROR_Y_ICREMENTED + LEFT_COL_ERROR_ADJ;
						LEFT_COL_Y_STEP = 1;
					end else begin
						NEXT_LEFT_COL_ERROR_Y = LEFT_COL_ERROR_Y_ICREMENTED;
					end
				end else begin
					NEXT_LEFT_D_ERROR = LEFT_D_ERROR_ICREMENTED;
					NEXT_LEFT_COL_ERROR_X = LEFT_COL_ERROR_X;
					NEXT_LEFT_COL_ERROR_Y = LEFT_COL_ERROR_Y;
				end
				
				RIGHT_D_ERROR_ICREMENTED = RIGHT_D_ERROR + RIGHT_D_ERROR_INC;
				if ($signed(RIGHT_D_ERROR_ICREMENTED) >= $signed({13{RIGHT_D_ERROR_CMP}})) begin
					NEXT_RIGHT_D_ERROR = RIGHT_D_ERROR_ICREMENTED + RIGHT_D_ERROR_ADJ;
					
					RIGHT_COL_ERROR_X_ICREMENTED = RIGHT_COL_ERROR_X + RIGHT_COL_ERROR_X_INC;
					if ($signed(RIGHT_COL_ERROR_X_ICREMENTED) >= $signed({13{RIGHT_COL_ERROR_X_CMP}})) begin
						NEXT_RIGHT_COL_ERROR_X = RIGHT_COL_ERROR_X_ICREMENTED + RIGHT_COL_ERROR_ADJ;
						RIGHT_COL_X_STEP = 1;
					end else begin
						NEXT_RIGHT_COL_ERROR_X = RIGHT_COL_ERROR_X_ICREMENTED;
					end
					
					RIGHT_COL_ERROR_Y_ICREMENTED = RIGHT_COL_ERROR_Y + RIGHT_COL_ERROR_Y_INC;
					if ($signed(RIGHT_COL_ERROR_Y_ICREMENTED) >= $signed({13{RIGHT_COL_ERROR_Y_CMP}})) begin
						NEXT_RIGHT_COL_ERROR_Y = RIGHT_COL_ERROR_Y_ICREMENTED + RIGHT_COL_ERROR_ADJ;
						RIGHT_COL_Y_STEP = 1;
					end else begin
						NEXT_RIGHT_COL_ERROR_Y = RIGHT_COL_ERROR_Y_ICREMENTED;
					end
				end else begin
					NEXT_RIGHT_D_ERROR = RIGHT_D_ERROR_ICREMENTED;
					NEXT_RIGHT_COL_ERROR_X = RIGHT_COL_ERROR_X;
					NEXT_RIGHT_COL_ERROR_Y = RIGHT_COL_ERROR_Y;
				end
			end

			default:;
		endcase
	end
	
	
	bit  [ 4: 0] DIV_A;//5.0
	bit  [11: 0] DIV_B;//12
	bit  [20: 0] DIV_Q;//9.12
	VDP1_DIV DIV(.numer({4'b0000,DIV_A,12'b000000000000}), .denom(DIV_B), .quotient(DIV_Q));
	
	RGB_t        GHCOLOR_A,GHCOLOR_B,GHCOLOR_C,GHCOLOR_D;
	assign {GHCOLOR_A,GHCOLOR_B,GHCOLOR_C,GHCOLOR_D} = {GRD_TBL[0][14:0],GRD_TBL[1][14:0],GRD_TBL[2][14:0],GRD_TBL[3][14:0]};
	RGBFP_t      LEFT_GHCOLOR,RIGHT_GHCOLOR,LINE_GHCOLOR;
	RGBFP_t      LEFT_GHCOLOR_STEP,RIGHT_GHCOLOR_STEP,LINE_GHCOLOR_STEP;
	
`ifdef DEBUG
	assign DBG_GHCOLOR_C = GRD_TBL[2][14:0];
	assign DBG_GHCOLOR_D = GRD_TBL[3][14:0];
	assign DBG_LINE_DRAW_STEP = LINE_DRAW_STEP;
	assign DBG_TEXT_READ_STEP = TEXT_X_READ_STEP;
	assign DBG_COL_DRAW_STEP = COL_DRAW_STEP;
	assign DBG_TEXT_X = TEXT_X;
	assign DBG_TEXT_Y = TEXT_Y;
`endif
	
	bit  [ 9: 0] CMD_CURR,CMD_SKIP;
	bit  [ 8: 0] CMD_PIX_XPOS,CMD_PIX_YPOS;
	bit          CMD_SKIP_EN,CMD_PIX_EN,DBG_DRAW_EN;
	bit  [ 8: 0] CMD_DELAY;
	bit  [ 9: 0] PENALTY_CNT;
	always @(posedge CLK or negedge RST_N) begin
//	   bit         FRAME_START_PEND;
		bit [18: 1] NEXT_ADDR;
		bit [18: 1] CMD_RET_ADDR;
		bit         CMD_SUB_RUN;
		bit [12: 0] NEW_LINE_SX;
		bit [12: 0] NEW_LINE_SY;
		bit [11: 0] NEW_LINE_ASX;
		bit [11: 0] NEW_LINE_ASY;
		bit [12: 0] NEW_POLY_LSX;
		bit [12: 0] NEW_POLY_LSY;
		bit [12: 0] NEW_POLY_RSX;
		bit [12: 0] NEW_POLY_RSY;
		bit         LINE_VERTA_X_OVR,LINE_VERTA_Y_OVR;
		bit         AA_DRAW;
		bit         LINE_SWAP;
		bit [16: 3] SPR_OFFSY_NEXT;
		bit         CLIP_H;
		RGB_t       GRD_CALC_1,GRD_CALC_2;
		bit [11: 0] GRD_CALC_S;
		RGBFP_t     GRD_CALC_STEP;
		bit         GRD_CALC_DIR;
		bit [12: 0] CMD_SSPR_LEFT,CMD_SSPR_RIGHT,CMD_SSPR_TOP,CMD_SSPR_BOTTOM;
		bit [12: 0] SSPR_WIDTH_ABS,SSPR_HEIGHT_ABS;
		bit         SSPR_DIRX,SSPR_DIRY;
		bit [12: 0] SYS_CLIP_X1,SYS_CLIP_X2,SYS_CLIP_Y1,SYS_CLIP_Y2;
		bit [ 3: 0] CMD_COORD_LEFT_OVER,CMD_COORD_RIGHT_OVER,CMD_COORD_TOP_OVER,CMD_COORD_BOTTOM_OVER;
		bit         CMD_NSPR_LEFT_OVER,CMD_NSPR_TOP_OVER;
		bit         CMD_SSPR_WIDTH_OVER,CMD_SSPR_HEIGHT_OVER;
		bit         CMD_SSPR_LEFT_OVER,CMD_SSPR_RIGHT_OVER,CMD_SSPR_TOP_OVER,CMD_SSPR_BOTTOM_OVER;
		bit         LINE_LEFT_OVER,LINE_RIGHT_OVER,LINE_TOP_OVER,LINE_BOTTOM_OVER;
		bit [ 3: 0] CLIP_DELAY;
		bit [ 7: 0] DBG_EXT_OLD;
		
		if (!RST_N) begin
			CMD_ST <= CMDS_IDLE;
			CMD_ADDR <= '0;
			CMD_READ <= 0;
			SPR_READ <= 0;
			CLT_READ <= 0;
			GRD_READ <= 0;
			SYS_CLIP <= CLIP_NULL;
			USR_CLIP <= CLIP_NULL;
			LOC_COORD <= COORD_NULL;
			CMD_SUB_RUN <= 0;
			
			LOPR <= '0;
			COPR <= '0;
			
			CMD_SKIP <= '1;
			
			{CMD_SKIP_EN,CMD_PIX_EN,DBG_DRAW_EN} <= '0;
		end else if (FRAME_START) begin
			CMD_ADDR <= '0;
			CMD_READ <= 1;
			SPR_READ <= 0;
			CLT_READ <= 0;
			GRD_READ <= 0;
			CMD_SUB_RUN <= 0;
			CMD_ST <= CMDS_READ;
		end else if (DRAW_TERMINATE) begin
			CMD_READ <= 0;
			SPR_READ <= 0;
			CLT_READ <= 0;
			GRD_READ <= 0;
			CMD_ST <= CMDS_IDLE;
		end else if (EN) begin
			SPR_OFFSY_NEXT = TEXT_DIRY ? SPR_OFFSY - ORIG_WIDTH[8:3] : SPR_OFFSY + ORIG_WIDTH[8:3];
		
			SYS_CLIP_X1 <= 13'd0 - $signed({{2{LOC_COORD.X[10]}},LOC_COORD.X});
			SYS_CLIP_Y1 <= 13'd0 - $signed({{2{LOC_COORD.Y[10]}},LOC_COORD.Y});
			SYS_CLIP_X2 <= $signed({{2{SYS_CLIP.X2[10]}},SYS_CLIP.X2}) - $signed({{2{LOC_COORD.X[10]}},LOC_COORD.X});
			SYS_CLIP_Y2 <= $signed({{2{SYS_CLIP.Y2[10]}},SYS_CLIP.Y2}) - $signed({{2{LOC_COORD.Y[10]}},LOC_COORD.Y});
			
			if (CMD.CMDPMOD.CLIP && !CMD.CMDPMOD.CMOD) begin
				SYS_CLIP_X1 <= $signed({{2{USR_CLIP.X1[10]}},USR_CLIP.X1}) - $signed({{2{LOC_COORD.X[10]}},LOC_COORD.X});
				SYS_CLIP_Y1 <= $signed({{2{USR_CLIP.Y1[10]}},USR_CLIP.Y1}) - $signed({{2{LOC_COORD.Y[10]}},LOC_COORD.Y});
				SYS_CLIP_X2 <= $signed({{2{USR_CLIP.X2[10]}},USR_CLIP.X2}) - $signed({{2{LOC_COORD.X[10]}},LOC_COORD.X});
				SYS_CLIP_Y2 <= $signed({{2{USR_CLIP.Y2[10]}},USR_CLIP.Y2}) - $signed({{2{LOC_COORD.Y[10]}},LOC_COORD.Y});
			end
			
			
			CMD_COORD_LEFT_OVER   <= {$signed(CMD.CMDXD[13:0]) < $signed({SYS_CLIP_X1[12],SYS_CLIP_X1}),
			                          $signed(CMD.CMDXC[13:0]) < $signed({SYS_CLIP_X1[12],SYS_CLIP_X1}), 
			                          $signed(CMD.CMDXB[13:0]) < $signed({SYS_CLIP_X1[12],SYS_CLIP_X1}), 
			                          $signed(CMD.CMDXA[13:0]) < $signed({SYS_CLIP_X1[12],SYS_CLIP_X1})};
			CMD_COORD_RIGHT_OVER  <= {$signed(CMD.CMDXD[13:0]) > $signed({SYS_CLIP_X2[12],SYS_CLIP_X2}),
			                          $signed(CMD.CMDXC[13:0]) > $signed({SYS_CLIP_X2[12],SYS_CLIP_X2}), 
			                          $signed(CMD.CMDXB[13:0]) > $signed({SYS_CLIP_X2[12],SYS_CLIP_X2}), 
			                          $signed(CMD.CMDXA[13:0]) > $signed({SYS_CLIP_X2[12],SYS_CLIP_X2})};
			CMD_COORD_TOP_OVER    <= {$signed(CMD.CMDYD[13:0]) < $signed({SYS_CLIP_Y1[12],SYS_CLIP_Y1}),
								           $signed(CMD.CMDYC[13:0]) < $signed({SYS_CLIP_Y1[12],SYS_CLIP_Y1}),
								           $signed(CMD.CMDYB[13:0]) < $signed({SYS_CLIP_Y1[12],SYS_CLIP_Y1}),
								           $signed(CMD.CMDYA[13:0]) < $signed({SYS_CLIP_Y1[12],SYS_CLIP_Y1})};
			CMD_COORD_BOTTOM_OVER <= {$signed(CMD.CMDYD[13:0]) > $signed({SYS_CLIP_Y2[12],SYS_CLIP_Y2}),
								           $signed(CMD.CMDYC[13:0]) > $signed({SYS_CLIP_Y2[12],SYS_CLIP_Y2}),
								           $signed(CMD.CMDYB[13:0]) > $signed({SYS_CLIP_Y2[12],SYS_CLIP_Y2}),
								           $signed(CMD.CMDYA[13:0]) > $signed({SYS_CLIP_Y2[12],SYS_CLIP_Y2})};
											  			
			if (CMD.CMDCTRL.COMM == 4'h0) begin
				CMD_SSPR_LEFT = CMD.CMDXA[12:0]; 
				CMD_SSPR_RIGHT = CMD.CMDXA[12:0] + {4'h00,CMD.CMDSIZE.SX,3'b000};
				CMD_SSPR_TOP = CMD.CMDYA[12:0];
				CMD_SSPR_BOTTOM = CMD.CMDYA[12:0] + {5'h00,CMD.CMDSIZE.SY};
			end else begin
				case (CMD.CMDCTRL.ZP[1:0])
					2'b00: begin 
						CMD_SSPR_LEFT = CMD.CMDXA[12:0]; 
						CMD_SSPR_RIGHT = CMD.CMDXC[12:0];
					end
					2'b01: begin 
						CMD_SSPR_LEFT = CMD.CMDXA[12:0]; 
						CMD_SSPR_RIGHT = CMD.CMDXA[12:0] + CMD.CMDXB[12:0];
					end
					2'b10: begin 
						CMD_SSPR_LEFT = CMD.CMDXA[12:0] - {CMD.CMDXB[12],CMD.CMDXB[12:1]};
						CMD_SSPR_RIGHT = CMD.CMDXA[12:0] + {CMD.CMDXB[12],CMD.CMDXB[12:1]} + {12'h000,CMD.CMDXB[0]};
					end
					2'b11: begin 
						CMD_SSPR_LEFT = CMD.CMDXA[12:0] - CMD.CMDXB[12:0];
						CMD_SSPR_RIGHT = CMD.CMDXA[12:0];
					end
				endcase
				case (CMD.CMDCTRL.ZP[3:2])
					2'b00: begin 
						CMD_SSPR_TOP = CMD.CMDYA[12:0];
						CMD_SSPR_BOTTOM = CMD.CMDYC[12:0];
					end
					2'b01: begin 
						CMD_SSPR_TOP = CMD.CMDYA[12:0];
						CMD_SSPR_BOTTOM = CMD.CMDYA[12:0] + CMD.CMDYB[12:0];
					end
					2'b10: begin 
						CMD_SSPR_TOP = CMD.CMDYA[12:0] - {CMD.CMDYB[12],CMD.CMDYB[12:1]};
						CMD_SSPR_BOTTOM = CMD.CMDYA[12:0] + {CMD.CMDYB[12],CMD.CMDYB[12:1]} + {12'h000,CMD.CMDYB[0]};
					end
					2'b11: begin 
						CMD_SSPR_TOP = CMD.CMDYA[12:0] - CMD.CMDYB[12:0];
						CMD_SSPR_BOTTOM = CMD.CMDYA[12:0];
					end
				endcase
			end
			CMD_SSPR_LEFT_OVER <= $signed(CMD_SSPR_LEFT) < $signed(SYS_CLIP_X1) && $signed(CMD_SSPR_RIGHT) < $signed(SYS_CLIP_X1);
			CMD_SSPR_RIGHT_OVER <= $signed(CMD_SSPR_LEFT) > $signed(SYS_CLIP_X2) && $signed(CMD_SSPR_RIGHT) > $signed(SYS_CLIP_X2);
			CMD_SSPR_TOP_OVER <= $signed(CMD_SSPR_TOP) < $signed(SYS_CLIP_Y1) && $signed(CMD_SSPR_BOTTOM) < $signed(SYS_CLIP_Y1);
			CMD_SSPR_BOTTOM_OVER <= $signed(CMD_SSPR_TOP) > $signed(SYS_CLIP_Y2) && $signed(CMD_SSPR_BOTTOM) > $signed(SYS_CLIP_Y2);
												
			CMD_SSPR_WIDTH_OVER <= (!CMD.CMDXB[11:0] && CMD.CMDCTRL.ZP);
			CMD_SSPR_HEIGHT_OVER <= (!CMD.CMDYB[11:0] && CMD.CMDCTRL.ZP);
																							  
			LINE_LEFT_OVER <= ($signed(LEFT_VERT.X) < $signed(SYS_CLIP_X1) && $signed(RIGHT_VERT.X) < $signed(SYS_CLIP_X1));
			LINE_RIGHT_OVER <= ($signed(LEFT_VERT.X) > $signed(SYS_CLIP_X2) && $signed(RIGHT_VERT.X) > $signed(SYS_CLIP_X2));
			LINE_TOP_OVER <= ($signed(LEFT_VERT.Y) < $signed(SYS_CLIP_Y1) && $signed(RIGHT_VERT.Y) < $signed(SYS_CLIP_Y1));
			LINE_BOTTOM_OVER <= ($signed(LEFT_VERT.Y) > $signed(SYS_CLIP_Y2) && $signed(RIGHT_VERT.Y) > $signed(SYS_CLIP_Y2));
			
`ifdef DEBUG
			DBG_EXT_OLD <= DBG_EXT;
			if (DBG_EXT[0] && !DBG_EXT_OLD[0]) CMD_SKIP <= CMD_SKIP - 8'd1;
			if (DBG_EXT[1] && !DBG_EXT_OLD[1]) CMD_SKIP <= CMD_SKIP + 8'd1;
			if (DBG_EXT[2] && !DBG_EXT_OLD[2]) CMD_SKIP <= CMD_SKIP - 8'd10;
			if (DBG_EXT[3] && !DBG_EXT_OLD[3]) CMD_SKIP <= CMD_SKIP + 8'd10;
			if (DBG_EXT[4] && !DBG_EXT_OLD[4]) CMD_SKIP_EN <= ~CMD_SKIP_EN;
			
			if (DBG_EXT[0] && !DBG_EXT_OLD[0]) CMD_PIX_XPOS <= CMD_PIX_XPOS - 8'd1;
			if (DBG_EXT[1] && !DBG_EXT_OLD[1]) CMD_PIX_XPOS <= CMD_PIX_XPOS + 8'd1;
			if (DBG_EXT[2] && !DBG_EXT_OLD[2]) CMD_PIX_YPOS <= CMD_PIX_YPOS - 8'd1;
			if (DBG_EXT[3] && !DBG_EXT_OLD[3]) CMD_PIX_YPOS <= CMD_PIX_YPOS + 8'd1;
			if (DBG_EXT[5] && !DBG_EXT_OLD[5]) CMD_PIX_EN <= ~CMD_PIX_EN;
			
			if (DBG_EXT[6] && !DBG_EXT_OLD[6]) DBG_DRAW_EN <= ~DBG_DRAW_EN;
			
			if (DBG_EXT[7] && !DBG_EXT_OLD[7]) {CMD_SKIP,CMD_SKIP_EN,CMD_PIX_EN,DBG_DRAW_EN} <= '0;
`else
			CMD_SKIP <= '0;
			CMD_SKIP_EN <= 0;
			CMD_PIX_EN <= 0;
			DBG_DRAW_EN <= 0;
`endif
			
			if (CMD_ST == CMDS_GRD_CALC_LEFT || CMD_ST == CMDS_GRD_CALC_RIGHT || CMD_ST == CMDS_GRD_CALC_LINE) begin
				GRD_CALC_STATE <= GRD_CALC_STATE + 4'd1;
				case (GRD_CALC_STATE)
					4'd0: {GRD_CALC_DIR,DIV_A[4:0]} <= GRD_CALC_2.R >= GRD_CALC_1.R ? {1'b0,GRD_CALC_2.R - GRD_CALC_1.R} : {1'b1,GRD_CALC_1.R - GRD_CALC_2.R};
					4'd2: {GRD_CALC_DIR,DIV_A[4:0]} <= GRD_CALC_2.G >= GRD_CALC_1.G ? {1'b0,GRD_CALC_2.G - GRD_CALC_1.G} : {1'b1,GRD_CALC_1.G - GRD_CALC_2.G};
					4'd5: {GRD_CALC_DIR,DIV_A[4:0]} <= GRD_CALC_2.B >= GRD_CALC_1.B ? {1'b0,GRD_CALC_2.B - GRD_CALC_1.B} : {1'b1,GRD_CALC_1.B - GRD_CALC_2.B};
				endcase
				DIV_B <= GRD_CALC_S;
				case (GRD_CALC_STATE)
					4'd2: GRD_CALC_STEP.R <= {GRD_CALC_DIR,DIV_Q[16:0]};
					4'd5: GRD_CALC_STEP.G <= {GRD_CALC_DIR,DIV_Q[16:0]};
					4'd8: GRD_CALC_STEP.B <= {GRD_CALC_DIR,DIV_Q[16:0]};
				endcase
			end
									
			if (CE_R) DRAW_END <= 0;
			if (FBD_ST == FBDS_WRITE) DRAW_ENABLE <= 0;
			case (CMD_ST) 
				CMDS_IDLE: begin
					CMD_CURR <= '0;
				end
					
				CMDS_READ: begin
`ifdef DEBUG
					DBG_CMD_WAIT_CNT <= DBG_CMD_WAIT_CNT + 1'd1;
`endif
					CMD_READ <= 0;
					
					if (CMD_READ_DONE) begin
						CMD_CURR <= CMD_CURR + 1'd1;
`ifdef DEBUG
						DBG_SKIP <= (CMD_CURR == CMD_SKIP);
`endif
						if (!CMD.CMDCTRL.JP[2] && !CMD.CMDCTRL.END 
`ifdef DEBUG
						    && (CMD_CURR != CMD_SKIP || !CMD_SKIP_EN)
`endif
						                                             ) begin
							case (CMD.CMDCTRL.COMM) 
								4'h0: begin	//normal sprite
									if (CMD_SSPR_LEFT_OVER || CMD_SSPR_TOP_OVER || CMD_COORD_RIGHT_OVER[0] || CMD_COORD_BOTTOM_OVER[0]) begin
										CMD_ST <= CMDS_END;
									end else if (CMD.CMDPMOD.CCB[2]) begin
										GRD_READ <= 1;
										CMD_DELAY <= 8'd10;
										CMD_ST <= CMDS_GRD_LOAD;
									end else begin
										CMD_DELAY <= 8'd23;
										CMD_ST <= CMDS_EXEC;
									end
								end
							
								4'h1: begin	//scaled sprite
									if (CMD_SSPR_LEFT_OVER || CMD_SSPR_RIGHT_OVER || CMD_SSPR_TOP_OVER || CMD_SSPR_BOTTOM_OVER || CMD_SSPR_WIDTH_OVER || CMD_SSPR_HEIGHT_OVER) begin
										CMD_ST <= CMDS_END;
									end else if (CMD.CMDPMOD.CCB[2]) begin
										GRD_READ <= 1;
										CMD_DELAY <= 8'd10;
										CMD_ST <= CMDS_GRD_LOAD;
									end else begin
										CMD_DELAY <= 8'd23;
										CMD_ST <= CMDS_EXEC;
									end
								end
								
								4'h2,
								4'h3: begin	//distored sprite
									if (&CMD_COORD_LEFT_OVER || &CMD_COORD_RIGHT_OVER || &CMD_COORD_TOP_OVER || &CMD_COORD_BOTTOM_OVER) begin
										CMD_ST <= CMDS_END;
									end else if (CMD.CMDPMOD.CCB[2]) begin
										GRD_READ <= 1;
										CMD_DELAY <= 8'd10;
										CMD_ST <= CMDS_GRD_LOAD;
									end else begin
										CMD_DELAY <= 8'd23;
										CMD_ST <= CMDS_EXEC;
									end
								end
								
								4'h4,			//polygon
								4'h5,
								4'h7: begin	//polyline
									if (&CMD_COORD_LEFT_OVER || &CMD_COORD_RIGHT_OVER || &CMD_COORD_TOP_OVER || &CMD_COORD_BOTTOM_OVER) begin
										CMD_ST <= CMDS_END;
									end else if (CMD.CMDPMOD.CCB[2]) begin
										GRD_READ <= 1;
										CMD_DELAY <= 8'd0;
										CMD_ST <= CMDS_GRD_LOAD;
									end else begin
										CMD_DELAY <= 8'd0;
										CMD_ST <= CMDS_EXEC;
									end
								end
								
								4'h6: begin	//line
									if (&CMD_COORD_LEFT_OVER[1:0] || &CMD_COORD_RIGHT_OVER[1:0] || &CMD_COORD_TOP_OVER[1:0] || &CMD_COORD_BOTTOM_OVER[1:0]) begin
										CMD_ST <= CMDS_END;
									end else if (CMD.CMDPMOD.CCB[2]) begin
										GRD_READ <= 1;
										CMD_DELAY <= 8'd0;
										CMD_ST <= CMDS_GRD_LOAD;
									end else begin
										CMD_DELAY <= 8'd0;
										CMD_ST <= CMDS_EXEC;
									end
								end
							
								4'h8,
								4'hB,
								4'h9,
								4'hA,
								4'hB: begin	
									CMD_DELAY <= 8'd0;
									CMD_ST <= CMDS_EXEC;
								end
							
								default: begin	
									CMD_ST <= CMDS_END;
								end
							endcase
						end
						else begin
							CMD_ST <= CMDS_END;
						end
						
						LOPR <= COPR;
						COPR <= CMD_ADDR[18:3];
`ifdef DEBUG
						DBG_CMD_WAIT_CNT <= '0;
						DBG_CMD_ADDR_ERR <= (CMD_ADDR > 18'h09000);
`endif
					end
				end
				
				CMDS_GRD_LOAD: begin
					GRD_READ <= 0;
					if (GRD_READ_DONE) begin 
						CMD_ST <= CMDS_EXEC;
					end
				end
				
				CMDS_EXEC: begin
						case (CMD.CMDCTRL.COMM)
							4'h0,			//normal sprite
							4'h1,			//scaled sprite
							4'h2,
							4'h3: begin	//distored sprite
								if (CMD.CMDPMOD.CM == 3'b001) begin
									CLT_READ <= 1;
									CMD_ST <= CMDS_CLT_LOAD;
								end else begin
									if (PENALTY_CNT > CMDS_DELAY) CMD_DELAY <= '0;
									CMD_ST <= CMDS_DELAY;
								end
							end
							
							4'h4: begin	//polygon
								CMD_ST <= CMDS_DELAY;
							end
							
							4'h5,
							4'h7: begin	//polyline
								CMD_ST <= CMDS_DELAY;
							end
							
							4'h6: begin	//line
								CMD_ST <= CMDS_DELAY;
							end
							
							4'h8,
							4'hB: begin	
								USR_CLIP.X1 <= {1'b0,CMD.CMDXA[9:0]}; 
								USR_CLIP.Y1 <= {1'b0,CMD.CMDYA[9:0]}; 
								USR_CLIP.X2 <= {1'b0,CMD.CMDXC[9:0]};
								USR_CLIP.Y2 <= {1'b0,CMD.CMDYC[9:0]};
								CMD_ST <= CMDS_END;
							end
							
							4'h9: begin	
								SYS_CLIP.X2 <= {1'b0,CMD.CMDXC[9:0]};
								SYS_CLIP.Y2 <= {1'b0,CMD.CMDYC[9:0]};
								//TODO: check on original hw
								USR_CLIP.X2 <= {1'b0,CMD.CMDXC[9:0]};
								USR_CLIP.Y2 <= {1'b0,CMD.CMDYC[9:0]};
								//
								CMD_ST <= CMDS_END;
							end
							
							4'hA: begin	
								LOC_COORD.X <= CMD.CMDXA[10:0]; 
								LOC_COORD.Y <= CMD.CMDYA[10:0];
								CMD_ST <= CMDS_END;
							end
								
							default: begin	
								CMD_ST <= CMDS_END;
							end
						endcase
`ifdef DEBUG
						if (DBG_CMD_CNT == 16) begin
							DBG_CMD_ADDR16 <= CMD_ADDR;
						end
`endif
				end
				
				CMDS_CLT_LOAD: begin
					CLT_READ <= 0;
					if (CLT_READ_DONE) begin
						CMD_ST <= CMDS_DELAY;
					end
				end
				
				CMDS_DELAY: if (CE_R) begin
					CMD_DELAY <= CMD_DELAY - 1'd1;
					if (!CMD_DELAY) begin
						case (CMD.CMDCTRL.COMM) 
							4'h0: CMD_ST <= CMDS_NSPR_START;
							4'h1: CMD_ST <= CMDS_SSPR_START;
							4'h2,
							4'h3: CMD_ST <= CMDS_DSPR_START;
							4'h4: CMD_ST <= CMDS_POLYGON_START;							
							4'h5,
							4'h7: CMD_ST <= CMDS_POLYLINE_START;							
							4'h6: CMD_ST <= CMDS_LINE_START;
						endcase
					end
				end
				
				CMDS_NSPR_START: begin
					VERTA.X <= CMD.CMDXA[12:0];
					VERTB.X <= CMD.CMDXA[12:0] + ORIG_WIDTH - 13'd1;
					VERTC.X <= CMD.CMDXA[12:0] + ORIG_WIDTH - 13'd1;;
					VERTD.X <= CMD.CMDXA[12:0];
					VERTA.Y <= CMD.CMDYA[12:0];
					VERTB.Y <= CMD.CMDYA[12:0];
					VERTC.Y <= CMD.CMDYA[12:0] + ORIG_HEIGHT - 13'd1;
					VERTD.Y <= CMD.CMDYA[12:0] + ORIG_HEIGHT - 13'd1;
					
					CMD_ST <= CMDS_EDGE_INIT;
				end
				
				CMDS_SSPR_START: begin
					case (CMD.CMDCTRL.ZP[1:0])
						2'b00: begin 
							VERTA.X <= CMD.CMDXA[12:0];
							VERTB.X <= CMD.CMDXC[12:0];
							VERTC.X <= CMD.CMDXC[12:0];
							VERTD.X <= CMD.CMDXA[12:0];
						end
						2'b01: begin 
							VERTA.X <= CMD.CMDXA[12:0];
							VERTB.X <= CMD.CMDXA[12:0] + CMD.CMDXB[12:0];
							VERTC.X <= CMD.CMDXA[12:0] + CMD.CMDXB[12:0];
							VERTD.X <= CMD.CMDXA[12:0];
						end
						2'b10: begin 
							VERTA.X <= CMD.CMDXA[12:0] - {CMD.CMDXB[12],CMD.CMDXB[12:1]};
							VERTB.X <= CMD.CMDXA[12:0] + {CMD.CMDXB[12],CMD.CMDXB[12:1]} + {12'b0_0000_0000_000,CMD.CMDXB[12]^CMD.CMDXB[0]};
							VERTC.X <= CMD.CMDXA[12:0] + {CMD.CMDXB[12],CMD.CMDXB[12:1]} + {12'b0_0000_0000_000,CMD.CMDXB[12]^CMD.CMDXB[0]};
							VERTD.X <= CMD.CMDXA[12:0] - {CMD.CMDXB[12],CMD.CMDXB[12:1]};
						end
						2'b11: begin 
							VERTA.X <= CMD.CMDXA[12:0] - CMD.CMDXB[12:0];
							VERTB.X <= CMD.CMDXA[12:0];
							VERTC.X <= CMD.CMDXA[12:0];
							VERTD.X <= CMD.CMDXA[12:0] - CMD.CMDXB[12:0];
						end
					endcase
					case (CMD.CMDCTRL.ZP[3:2])
						2'b00: begin 
							VERTA.Y <= CMD.CMDYA[12:0];
							VERTB.Y <= CMD.CMDYA[12:0];
							VERTC.Y <= CMD.CMDYC[12:0];
							VERTD.Y <= CMD.CMDYC[12:0];
						end
						2'b01: begin 
							VERTA.Y <= CMD.CMDYA[12:0];
							VERTB.Y <= CMD.CMDYA[12:0];
							VERTC.Y <= CMD.CMDYA[12:0] + CMD.CMDYB[12:0];
							VERTD.Y <= CMD.CMDYA[12:0] + CMD.CMDYB[12:0];
						end
						2'b10: begin 
							VERTA.Y <= CMD.CMDYA[12:0] - {CMD.CMDYB[12],CMD.CMDYB[12:1]};
							VERTB.Y <= CMD.CMDYA[12:0] - {CMD.CMDYB[12],CMD.CMDYB[12:1]};
							VERTC.Y <= CMD.CMDYA[12:0] + {CMD.CMDYB[12],CMD.CMDYB[12:1]} + {12'b0_0000_0000_000,CMD.CMDYB[12]^CMD.CMDYB[0]};
							VERTD.Y <= CMD.CMDYA[12:0] + {CMD.CMDYB[12],CMD.CMDYB[12:1]} + {12'b0_0000_0000_000,CMD.CMDYB[12]^CMD.CMDYB[0]};
						end
						2'b11: begin 
							VERTA.Y <= CMD.CMDYA[12:0] - CMD.CMDYB[12:0];
							VERTB.Y <= CMD.CMDYA[12:0] - CMD.CMDYB[12:0];
							VERTC.Y <= CMD.CMDYA[12:0];
							VERTD.Y <= CMD.CMDYA[12:0];
						end
					endcase
					
					CMD_ST <= CMDS_EDGE_INIT;
				end
				
				CMDS_DSPR_START,
				CMDS_POLYGON_START: begin
					VERTA <= {CMD.CMDXA[12:0],CMD.CMDYA[12:0]};
					VERTB <= {CMD.CMDXB[12:0],CMD.CMDYB[12:0]};
					VERTC <= {CMD.CMDXC[12:0],CMD.CMDYC[12:0]};
					VERTD <= {CMD.CMDXD[12:0],CMD.CMDYD[12:0]};
							
					CMD_ST <= CMDS_EDGE_INIT;
				end
				
				CMDS_POLYLINE_START,
				CMDS_LINE_START: begin
					VERTA <= {CMD.CMDXA[12:0],CMD.CMDYA[12:0]};
					VERTB <= {CMD.CMDXB[12:0],CMD.CMDYB[12:0]};
					VERTC <= {CMD.CMDXC[12:0],CMD.CMDYC[12:0]};
					VERTD <= {CMD.CMDXD[12:0],CMD.CMDYD[12:0]};
					
					CMD_ST <= CMDS_LINE_INIT;
				end
				
				CMDS_EDGE_INIT: begin
					LEFT_VERT <= VERTA;
					RIGHT_VERT <= VERTB;
					NEW_POLY_LSX = VERTD.X - VERTA.X;
					NEW_POLY_LSY = VERTD.Y - VERTA.Y;
					NEW_POLY_RSX = VERTC.X - VERTB.X;
					NEW_POLY_RSY = VERTC.Y - VERTB.Y;
					
					POLY_LSX <= Abs13(NEW_POLY_LSX);
					POLY_LSY <= Abs13(NEW_POLY_LSY);
					POLY_RSX <= Abs13(NEW_POLY_RSX);
					POLY_RSY <= Abs13(NEW_POLY_RSY);
					POLY_LDIRX <= NEW_POLY_LSX[12];
					POLY_LDIRY <= NEW_POLY_LSY[12];
					POLY_RDIRX <= NEW_POLY_RSX[12];
					POLY_RDIRY <= NEW_POLY_RSY[12];
					
					DIR <= '0;
					
					CLIP_H <= 0;
					if (($signed(VERTA.X) < $signed(SYS_CLIP_X1) && $signed(VERTD.X) < $signed(SYS_CLIP_X1)) ||
					    ($signed(VERTB.X) < $signed(SYS_CLIP_X1) && $signed(VERTC.X) < $signed(SYS_CLIP_X1)) ||
						 ($signed(VERTA.X) > $signed(SYS_CLIP_X2) && $signed(VERTD.X) > $signed(SYS_CLIP_X2)) ||
						 ($signed(VERTB.X) > $signed(SYS_CLIP_X2) && $signed(VERTC.X) > $signed(SYS_CLIP_X2))) begin
						CLIP_H <= ~CMD.CMDPMOD.PCLP;
					end
							
					CMD_ST <= CMDS_POLYGON_CALCE;
				end
				
				CMDS_LINE_INIT: begin
					LEFT_VERT <= VERTA;
					RIGHT_VERT <= VERTB;
					POLY_S <= 2'b00;
					TEXT_X <= '0;
					LEFT_GHCOLOR <= RGBItoF(GHCOLOR_A);
					RIGHT_GHCOLOR <= RGBItoF(GHCOLOR_B);
					CMD_ST <= CMDS_LINE_CALC;
				end
				
				CMDS_POLYGON_CALCE: begin
					if (POLY_LSX >= POLY_LSY) begin
						LEFT_HEIGHT <= POLY_LSX;
					end else begin
						LEFT_HEIGHT <= POLY_LSY;
					end
					if (POLY_RSX >= POLY_RSY) begin
						RIGHT_HEIGHT <= POLY_RSX;
					end else begin
						RIGHT_HEIGHT <= POLY_RSY;
					end
					
					CMD_ST <= CMDS_POLYGON_CALCH;
				end
				
				CMDS_POLYGON_CALCH: begin
					if (LEFT_HEIGHT >= RIGHT_HEIGHT) begin
						COL_HEIGHT <= LEFT_HEIGHT;
					end else begin
						COL_HEIGHT <= RIGHT_HEIGHT;
					end
					
					CMD_ST <= CMDS_POLYGON_CALCTY;
				end
				
				CMDS_POLYGON_CALCTY: begin
					if ((COL_HEIGHT + 13'd1) <= {5'b00000,ORIG_HEIGHT - 8'd1}) begin
						TEXT_Y_ERROR_INC <= ({5'b00000,ORIG_HEIGHT} << 1);
						TEXT_Y_ERROR_ADJ <= (COL_HEIGHT + 13'd1) << 1;
						TEXT_Y_ERROR <= {5'b00000,ORIG_HEIGHT} - (((COL_HEIGHT + 13'd1) << 1) + (!TEXT_DIRY || ORIG_HEIGHT == 8'd1 ? 13'd0 : 13'd1 ));
					end else begin
						TEXT_Y_ERROR_INC <= ({5'b00000,ORIG_HEIGHT - 8'd1} << 1);
						TEXT_Y_ERROR_ADJ <= (((COL_HEIGHT + 13'd1) - 13'd1) << 1);
						TEXT_Y_ERROR <= (COL_HEIGHT + 13'd1) - (((COL_HEIGHT + 13'd1) << 1) - (!TEXT_DIRY || ORIG_HEIGHT == 8'd1 ? 13'd0 : 13'd1 ));
					end
					
					LEFT_COL_ERROR_X_INC <= POLY_LSX << 1;
					LEFT_COL_ERROR_Y_INC <= POLY_LSY << 1;
					LEFT_COL_ERROR_ADJ <= -(LEFT_HEIGHT << 1);
					LEFT_COL_ERROR_X <= ~LEFT_HEIGHT;
					LEFT_COL_ERROR_Y <= ~LEFT_HEIGHT;
					LEFT_COL_ERROR_X_CMP <= POLY_LDIRY;
					LEFT_COL_ERROR_Y_CMP <= POLY_LDIRX;
					
					LEFT_D_ERROR_INC <= LEFT_HEIGHT << 1;
					LEFT_D_ERROR_ADJ <= -(COL_HEIGHT << 1);
					LEFT_D_ERROR <= ~COL_HEIGHT;
					LEFT_D_ERROR_CMP <= POLY_LSY > POLY_LSX ? POLY_LDIRY : POLY_LDIRX;
					
					RIGHT_COL_ERROR_X_INC <= POLY_RSX << 1;
					RIGHT_COL_ERROR_Y_INC <= POLY_RSY << 1;
					RIGHT_COL_ERROR_ADJ <= -(RIGHT_HEIGHT << 1);
					RIGHT_COL_ERROR_X <= ~RIGHT_HEIGHT;
					RIGHT_COL_ERROR_Y <= ~RIGHT_HEIGHT;
					RIGHT_COL_ERROR_X_CMP <= POLY_RDIRY;
					RIGHT_COL_ERROR_Y_CMP <= POLY_RDIRX;
					
					RIGHT_D_ERROR_INC <= RIGHT_HEIGHT << 1;
					RIGHT_D_ERROR_ADJ <= -(COL_HEIGHT << 1);
					RIGHT_D_ERROR <= ~COL_HEIGHT;
					RIGHT_D_ERROR_CMP <= POLY_RSY > POLY_RSX ? POLY_RDIRY : POLY_RDIRX;
					
					COL_D <= COL_HEIGHT;
					
					SPR_OFFSY <= TEXT_DIRY ? (ORIG_HEIGHT - 8'd1) * ORIG_WIDTH[8:3] : '0;
					TEXT_Y <= '0;
					TEXT_X <= '0;
					
					CMD_ST <= CMDS_GRD_CALC_COL;
				end
				
				CMDS_GRD_CALC_COL: begin
					LEFT_GHCOLOR <= RGBItoF(GHCOLOR_A);
					RIGHT_GHCOLOR <= RGBItoF(GHCOLOR_B);
					
					GRD_CALC_1 <= GHCOLOR_A;
					GRD_CALC_2 <= GHCOLOR_D;
					GRD_CALC_S <= COL_HEIGHT + 12'd1;
					GRD_CALC_STATE <= '0;
					CMD_ST <= CMDS_GRD_CALC_LEFT;
				end
				
				CMDS_GRD_CALC_LEFT: begin
					if (GRD_CALC_STATE == 4'd15) begin
						GRD_CALC_STATE <= '0;
						LEFT_GHCOLOR_STEP <= GRD_CALC_STEP;
						
						GRD_CALC_1 <= GHCOLOR_B;
						GRD_CALC_2 <= GHCOLOR_C;
						GRD_CALC_S <= COL_HEIGHT + 12'd1;
						CMD_ST <= CMDS_GRD_CALC_RIGHT;
					end
				end
				
				CMDS_GRD_CALC_RIGHT: begin
					if (GRD_CALC_STATE == 4'd15) begin
						GRD_CALC_STATE <= '0;
						RIGHT_GHCOLOR_STEP <= GRD_CALC_STEP;
						CMD_ST <= CMDS_ROW_DRAW;
					end
				end
				
				CMDS_ROW_DRAW: begin
					if (TEXT_Y_READ_STEP) begin
						TEXT_Y <= TEXT_Y + 8'd1;
						SPR_OFFSY <= SPR_OFFSY_NEXT;
					end
					
					if (COL_DRAW_STEP) begin
						case (CMD.CMDCTRL.COMM) 
							4'h0: CMD_ST <= CMDS_NSPR_CALCX;
							4'h1: CMD_ST <= CMDS_SSPR_CALCX;
							default: CMD_ST <= CMDS_LINE_CALC;
						endcase
					end else begin
						CMD_ST <= CMDS_ROW_DRAW;
					end
					TEXT_Y_ERROR <= NEXT_TEXT_Y_ERROR;
				end
				
				CMDS_NSPR_CALCX: begin
					NEW_LINE_SX = RIGHT_VERT.X - LEFT_VERT.X;
//					NEW_LINE_SY = RIGHT_VERT.Y - LEFT_VERT.Y;
					NEW_LINE_ASX = Abs13(NEW_LINE_SX);
//					NEW_LINE_ASY = Abs13(NEW_LINE_SY);
					/*if (LEFT_VERT.Y == RIGHT_VERT.Y && $signed(LEFT_VERT.X) < $signed(SYS_CLIP_X1) && !CMD.CMDPMOD.PCLP) begin
						LINE_VERTA.X <= RIGHT_VERT.X[10:0];
						LINE_VERTA.Y <= RIGHT_VERT.Y[10:0];
						LINE_VERTB.X <= SYS_CLIP_X1[10:0];
						LINE_VERTB.Y <= LEFT_VERT.Y[10:0];
						LINE_DIRX <= 0;
						LINE_DIRY <= 0;
						LINE_CLIP <= 1;
						DIR[0] <= 1;
					end else if (LEFT_VERT.Y == RIGHT_VERT.Y && $signed(LEFT_VERT.X) > $signed(SYS_CLIP_X2) && !CMD.CMDPMOD.PCLP) begin
						LINE_VERTA.X <= RIGHT_VERT.X[10:0];
						LINE_VERTA.Y <= RIGHT_VERT.Y[10:0];
						LINE_VERTB.X <= SYS_CLIP_X2[10:0];
						LINE_VERTB.Y <= LEFT_VERT.Y[10:0];
						LINE_DIRX <= 0;
						LINE_DIRY <= 0;
						LINE_CLIP <= 1;
						DIR[0] <= 1;
					end else*/ begin
						LINE_VERTA.X <= LEFT_VERT.X[10:0];
						LINE_VERTA.Y <= LEFT_VERT.Y[10:0];
						LINE_VERTB.X <= RIGHT_VERT.X[10:0];
						LINE_VERTB.Y <= RIGHT_VERT.Y[10:0];
						LINE_DIRX <= 0;
						LINE_DIRY <= 0;
						LINE_CLIP <= 0;
						DIR[0] <= 0;
					end
					EC_FIND <= 0;
					HSS_EN <= 0;
					
					ROW_WIDTH <= NEW_LINE_ASX + 12'd1;
					
					CMD_ST <= CMDS_SSPR_CALCTX;
				end
				
				CMDS_SSPR_CALCX: begin
					NEW_LINE_SX = RIGHT_VERT.X - LEFT_VERT.X;
//					NEW_LINE_SY = RIGHT_VERT.Y - LEFT_VERT.Y;
					NEW_LINE_ASX = Abs13(NEW_LINE_SX);
//					NEW_LINE_ASY = Abs13(NEW_LINE_SY);
					if ($signed(LEFT_VERT.X) < $signed(SYS_CLIP_X1) && $signed(RIGHT_VERT.X) <= $signed(SYS_CLIP_X2) && CLIP_H && !DBG_EXT_OLD[5]) begin
						LINE_VERTA.X <= RIGHT_VERT.X[10:0];
						LINE_VERTA.Y <= RIGHT_VERT.Y[10:0];
						LINE_VERTB.X <= LEFT_VERT.X[10:0];
						LINE_VERTB.Y <= LEFT_VERT.Y[10:0];
						LINE_DIRX <= ~NEW_LINE_SX[12];
						LINE_CLIP <= 1;
						DIR[0] <= 1;
					end else if ($signed(LEFT_VERT.X) <= $signed(SYS_CLIP_X2) && $signed(RIGHT_VERT.X) < $signed(SYS_CLIP_X1) && CLIP_H && !DBG_EXT_OLD[5]) begin
						LINE_VERTA.X <= LEFT_VERT.X[10:0];
						LINE_VERTA.Y <= LEFT_VERT.Y[10:0];
						LINE_VERTB.X <= RIGHT_VERT.X[10:0];
						LINE_VERTB.Y <= RIGHT_VERT.Y[10:0];
						LINE_DIRX <= NEW_LINE_SX[12];
						LINE_CLIP <= 1;
						DIR[0] <= 0;
					end else if ($signed(LEFT_VERT.X) > $signed(SYS_CLIP_X2) && $signed(RIGHT_VERT.X) >= $signed(SYS_CLIP_X1) && CLIP_H && !DBG_EXT_OLD[5]) begin
						LINE_VERTA.X <= RIGHT_VERT.X[10:0];
						LINE_VERTA.Y <= RIGHT_VERT.Y[10:0];
						LINE_VERTB.X <= LEFT_VERT.X[10:0];
						LINE_VERTB.Y <= LEFT_VERT.Y[10:0];
						LINE_DIRX <= ~NEW_LINE_SX[12];
						LINE_CLIP <= 1;
						DIR[0] <= 1;
					end else if ($signed(LEFT_VERT.X) >= $signed(SYS_CLIP_X1) && $signed(RIGHT_VERT.X) > $signed(SYS_CLIP_X2) && CLIP_H && !DBG_EXT_OLD[5]) begin
						LINE_VERTA.X <= LEFT_VERT.X[10:0];
						LINE_VERTA.Y <= LEFT_VERT.Y[10:0];
						LINE_VERTB.X <= RIGHT_VERT.X[10:0];
						LINE_VERTB.Y <= RIGHT_VERT.Y[10:0];
						LINE_DIRX <= NEW_LINE_SX[12];
						LINE_CLIP <= 1;
						DIR[0] <= 0;
					end else begin
						LINE_VERTA.X <= LEFT_VERT.X[10:0];
						LINE_VERTA.Y <= LEFT_VERT.Y[10:0];
						LINE_VERTB.X <= RIGHT_VERT.X[10:0];
						LINE_VERTB.Y <= RIGHT_VERT.Y[10:0];
						LINE_DIRX <= NEW_LINE_SX[12];
						LINE_CLIP <= 0;
						DIR[0] <= 0;
					end
					LINE_DIRY <= 0;
					EC_FIND <= 0;
					
					ROW_WIDTH <= NEW_LINE_ASX + 12'd1;
					
					CMD_ST <= CMDS_SSPR_CALCTX;
				end
				
				CMDS_SSPR_CALCTX: begin
					if (ROW_WIDTH < {4'b0000,ORIG_WIDTH} && CMD.CMDPMOD.HSS) begin
						if (ROW_WIDTH < {5'b00000,ORIG_WIDTH[8:1]}) begin
							TEXT_ERROR_INC <= {4'b0000,ORIG_WIDTH};
							TEXT_ERROR_ADJ <= (ROW_WIDTH << 1);
							TEXT_ERROR <= {5'b00000,ORIG_WIDTH[8:1]} - (ROW_WIDTH << 1) - (!TEXT_DIRX || ORIG_WIDTH == 8'd1 ? 13'd0 : 13'd1);
						end else begin
							TEXT_ERROR_INC <= ({5'b00000,ORIG_WIDTH[8:1] - 8'd1} << 1);
							TEXT_ERROR_ADJ <= ((ROW_WIDTH - 12'd1) << 1);
							TEXT_ERROR <= (-ROW_WIDTH) + (!TEXT_DIRX || ORIG_WIDTH == 8'd1 ? 13'd0 : 13'd1);
						end
						HSS_EN <= 1;
					end else begin
						if (ROW_WIDTH < {4'b0000,ORIG_WIDTH}) begin
							TEXT_ERROR_INC <= ({4'b0000,ORIG_WIDTH} << 1);
							TEXT_ERROR_ADJ <= (ROW_WIDTH << 1);
							TEXT_ERROR <= {4'b0000,ORIG_WIDTH} - (ROW_WIDTH << 1) - (!TEXT_DIRX || ORIG_WIDTH == 8'd1 ? 13'd0 : 13'd1);
						end else begin
							TEXT_ERROR_INC <= ({4'b0000,ORIG_WIDTH - 9'd1} << 1);
							TEXT_ERROR_ADJ <= ((ROW_WIDTH - 12'd1) << 1);
							TEXT_ERROR <= (-ROW_WIDTH) + (!TEXT_DIRX || ORIG_WIDTH == 8'd1 ? 13'd0 : 13'd1);
						end
						HSS_EN <= 0;
					end

					if ((LINE_LEFT_OVER || LINE_RIGHT_OVER || LINE_TOP_OVER || LINE_BOTTOM_OVER) && !CMD.CMDPMOD.PCLP) begin
						CMD_ST <= CMDS_LINE_NEXT;
					end else begin
						SPR_READ <= 1;
						CMD_ST <= CMDS_GRD_CALC_ROW;
					end
				end
				
				CMDS_LINE_CALC: begin
					NEW_LINE_SX = RIGHT_VERT.X - LEFT_VERT.X;
					NEW_LINE_SY = RIGHT_VERT.Y - LEFT_VERT.Y;
					NEW_LINE_ASX = Abs13(NEW_LINE_SX);
					NEW_LINE_ASY = Abs13(NEW_LINE_SY);
					LINE_SWAP = 0;
					if ($signed(LEFT_VERT.X) < $signed(SYS_CLIP_X1) && $signed(RIGHT_VERT.X) <= $signed(SYS_CLIP_X2) && CLIP_H && !DBG_EXT_OLD[5]) begin
						LINE_VERTA.X <= RIGHT_VERT.X[10:0];
						LINE_VERTA.Y <= RIGHT_VERT.Y[10:0];
						LINE_VERTB.X <= LEFT_VERT.X[10:0];
						LINE_VERTB.Y <= LEFT_VERT.Y[10:0];
						LINE_DIRX <= ~NEW_LINE_SX[12];
						LINE_DIRY <= ~NEW_LINE_SY[12];
						LINE_CLIP <= 1;
						DIR[0] <= 1;
						LINE_SWAP = 1;
					end else if ($signed(LEFT_VERT.X) <= $signed(SYS_CLIP_X2) && $signed(RIGHT_VERT.X) < $signed(SYS_CLIP_X1) && CLIP_H && !DBG_EXT_OLD[5]) begin
						LINE_VERTA.X <= LEFT_VERT.X[10:0];
						LINE_VERTA.Y <= LEFT_VERT.Y[10:0];
						LINE_VERTB.X <= RIGHT_VERT.X[10:0];
						LINE_VERTB.Y <= RIGHT_VERT.Y[10:0];
						LINE_DIRX <= NEW_LINE_SX[12];
						LINE_DIRY <= NEW_LINE_SY[12];
						LINE_CLIP <= 1;
						DIR[0] <= 0;
					end else if ($signed(LEFT_VERT.X) > $signed(SYS_CLIP_X2) && $signed(RIGHT_VERT.X) >= $signed(SYS_CLIP_X1) && CLIP_H && !DBG_EXT_OLD[5]) begin
						LINE_VERTA.X <= RIGHT_VERT.X[10:0];
						LINE_VERTA.Y <= RIGHT_VERT.Y[10:0];
						LINE_VERTB.X <= LEFT_VERT.X[10:0];
						LINE_VERTB.Y <= LEFT_VERT.Y[10:0];
						LINE_DIRX <= ~NEW_LINE_SX[12];
						LINE_DIRY <= ~NEW_LINE_SY[12];
						LINE_CLIP <= 1;
						DIR[0] <= 1;
						LINE_SWAP = 1;
					end else if ($signed(LEFT_VERT.X) >= $signed(SYS_CLIP_X1) && $signed(RIGHT_VERT.X) > $signed(SYS_CLIP_X2) && CLIP_H && !DBG_EXT_OLD[5]) begin
						LINE_VERTA.X <= LEFT_VERT.X[10:0];
						LINE_VERTA.Y <= LEFT_VERT.Y[10:0];
						LINE_VERTB.X <= RIGHT_VERT.X[10:0];
						LINE_VERTB.Y <= RIGHT_VERT.Y[10:0];
						LINE_DIRX <= NEW_LINE_SX[12];
						LINE_DIRY <= NEW_LINE_SY[12];
						LINE_CLIP <= 1;
						DIR[0] <= 0;
					end else begin
						LINE_VERTA.X <= LEFT_VERT.X[10:0];
						LINE_VERTA.Y <= LEFT_VERT.Y[10:0];
						LINE_VERTB.X <= RIGHT_VERT.X[10:0];
						LINE_VERTB.Y <= RIGHT_VERT.Y[10:0];
						LINE_DIRX <= NEW_LINE_SX[12];
						LINE_DIRY <= NEW_LINE_SY[12];
						LINE_CLIP <= 0;
						DIR[0] <= 0;
					end
					
					if (NEW_LINE_ASY > NEW_LINE_ASX) begin
						LINE_ERROR_INC <= (NEW_LINE_ASX << 1);
						LINE_ERROR_ADJ <= -(NEW_LINE_ASY << 1);
						LINE_ERROR <= (NEW_LINE_ASY - (NEW_LINE_ASY << 1)) - (NEW_LINE_ASX << 1);
						LINE_S <= 1;
						AA_X_INC <= (NEW_LINE_SY[12]^LINE_SWAP) ? {11{(NEW_LINE_SX[12]^LINE_SWAP)}} : {{10{1'b0}},~(NEW_LINE_SX[12]^LINE_SWAP)};
						AA_Y_INC <= (NEW_LINE_SY[12]^LINE_SWAP) ? {{10{1'b0}},(NEW_LINE_SX[12]^LINE_SWAP)} : {11{~(NEW_LINE_SX[12]^LINE_SWAP)}};
					end else begin
						LINE_ERROR_INC <= (NEW_LINE_ASY << 1);
						LINE_ERROR_ADJ <= -(NEW_LINE_ASX << 1);
						LINE_ERROR <= (NEW_LINE_ASX - (NEW_LINE_ASX << 1)) - (NEW_LINE_ASY << 1);
						LINE_S <= 0;
						AA_X_INC <= (NEW_LINE_SX[12]^LINE_SWAP) ? {{10{1'b0}},~(NEW_LINE_SY[12]^LINE_SWAP)} : {11{(NEW_LINE_SY[12]^LINE_SWAP)}};
						AA_Y_INC <= (NEW_LINE_SX[12]^LINE_SWAP) ? {{10{1'b0}},~(NEW_LINE_SY[12]^LINE_SWAP)} : {11{(NEW_LINE_SY[12]^LINE_SWAP)}};
					end
					
					ROW_WIDTH <= NEW_LINE_ASX >= NEW_LINE_ASY ? NEW_LINE_ASX + 12'd1 : NEW_LINE_ASY + 12'd1;
					
					CMD_ST <= CMDS_LINE_CALCTX;
				end
				
				CMDS_LINE_CALCTX: begin
					if (ROW_WIDTH <= {4'b0000,ORIG_WIDTH - 9'd1} && CMD.CMDPMOD.HSS && !CMD.CMDCTRL.COMM[2]) begin
						if (ROW_WIDTH < {5'b00000,ORIG_WIDTH[8:1]}) begin
							TEXT_ERROR_INC <= {4'b0000,ORIG_WIDTH};
							TEXT_ERROR_ADJ <= (ROW_WIDTH << 1);
							TEXT_ERROR <= {5'b00000,ORIG_WIDTH[8:1]} - (ROW_WIDTH << 1) - (!TEXT_DIRX || ORIG_WIDTH == 8'd1 ? 13'd0 : 13'd1);
						end else begin
							TEXT_ERROR_INC <= ({5'b00000,ORIG_WIDTH[8:1] - 8'd1} << 1);
							TEXT_ERROR_ADJ <= ((ROW_WIDTH - 13'd1) << 1);
							TEXT_ERROR <= ROW_WIDTH - (ROW_WIDTH << 1) + (!TEXT_DIRX || ORIG_WIDTH == 8'd1 ? 13'd0 : 13'd1);
						end
						HSS_EN <= 1;
					end else begin
						if (ROW_WIDTH < {4'b0000,ORIG_WIDTH}) begin
							TEXT_ERROR_INC <= ({4'b0000,ORIG_WIDTH} << 1);
							TEXT_ERROR_ADJ <= (ROW_WIDTH << 1);
							TEXT_ERROR <= {4'b0000,ORIG_WIDTH} - (ROW_WIDTH << 1) - (!TEXT_DIRX || ORIG_WIDTH == 8'd1 ? 13'd0 : 13'd1);
						end else begin
							TEXT_ERROR_INC <= ({4'b0000,ORIG_WIDTH - 9'd1} << 1);
							TEXT_ERROR_ADJ <= ((ROW_WIDTH - 13'd1) << 1);
							TEXT_ERROR <= ROW_WIDTH - (ROW_WIDTH << 1) + (!TEXT_DIRX || ORIG_WIDTH == 8'd1 ? 13'd0 : 13'd1);
						end
						HSS_EN <= 0;
					end
					
					EC_FIND <= 0;
					AA <= 0;
				
					if ((LINE_LEFT_OVER || LINE_RIGHT_OVER || LINE_TOP_OVER || LINE_BOTTOM_OVER) && !CMD.CMDPMOD.PCLP) begin
						CMD_ST <= CMDS_LINE_NEXT;
					end else begin
						SPR_READ <= ~CMD.CMDCTRL.COMM[2];
						CMD_ST <= CMDS_GRD_CALC_ROW;
					end
				end
				
				CMDS_GRD_CALC_ROW: begin
					LINE_GHCOLOR <= DIR[0] ? RIGHT_GHCOLOR : LEFT_GHCOLOR;
					GRD_CALC_1 <= RGBFtoI(LEFT_GHCOLOR);
					GRD_CALC_2 <= RGBFtoI(RIGHT_GHCOLOR);
					GRD_CALC_S <= ROW_WIDTH /*- 12'd1*/;
					CMD_ST <= CMDS_GRD_CALC_LINE;
				end
				
				CMDS_GRD_CALC_LINE: begin
					if (GRD_CALC_STATE == 4'd9) begin
						GRD_CALC_STATE <= '0;
						LINE_GHCOLOR_STEP <= GRD_CALC_STEP;
						
						TEXT_X <= '0;
						if (!TEXT_ERROR[12])
							CMD_ST <= CMDS_PRE_DRAW;
						else
						case (CMD.CMDCTRL.COMM) 
							4'h0: CMD_ST <= CMDS_NSPR_DRAW;
							4'h1: CMD_ST <= CMDS_SSPR_DRAW;
							default: CMD_ST <= CMDS_LINE_DRAW;
						endcase
							
					end
				end
				
				CMDS_PRE_DRAW: begin
					if (TEXT_X_READ_STEP) begin
						TEXT_X <= TEXT_X + (HSS_EN ? 2'd2 : 2'd1);
						if (IS_PAT_EC) EC_FIND <= 1;
					end
					TEXT_ERROR <= NEXT_TEXT_ERROR;
					
					case (CMD.CMDCTRL.COMM) 
						4'h0: CMD_ST <= CMDS_NSPR_DRAW;
						4'h1: CMD_ST <= CMDS_SSPR_DRAW;
						default: CMD_ST <= CMDS_LINE_DRAW;
					endcase
				end
				
				CMDS_NSPR_DRAW,
				CMDS_SSPR_DRAW: if (!DRAW_WAIT && SPR_DATA_READY) begin
					DRAW_ENABLE <= LINE_DRAW_STEP;
					
					if (TEXT_X_READ_STEP) begin
						TEXT_X <= TEXT_X + (HSS_EN ? 2'd2 : 2'd1);
						if (IS_PAT_EC) EC_FIND <= 1;
					end
					TEXT_ERROR <= NEXT_TEXT_ERROR;
					
					if (LINE_DRAW_STEP) begin
						LINE_VERTA.X <= LINE_VERTA.X + {{10{LINE_DIRX}},1'b1};
						
						{LINE_GHCOLOR.R.INT,LINE_GHCOLOR.R.FRAC} <= {LINE_GHCOLOR.R.INT,LINE_GHCOLOR.R.FRAC} + ({LINE_GHCOLOR_STEP.R.INT,LINE_GHCOLOR_STEP.R.FRAC}^{17{DIR[0]^LINE_GHCOLOR_STEP.R.DIR}}) + (DIR[0]^LINE_GHCOLOR_STEP.R.DIR);
						{LINE_GHCOLOR.G.INT,LINE_GHCOLOR.G.FRAC} <= {LINE_GHCOLOR.G.INT,LINE_GHCOLOR.G.FRAC} + ({LINE_GHCOLOR_STEP.G.INT,LINE_GHCOLOR_STEP.G.FRAC}^{17{DIR[0]^LINE_GHCOLOR_STEP.G.DIR}}) + (DIR[0]^LINE_GHCOLOR_STEP.G.DIR);
						{LINE_GHCOLOR.B.INT,LINE_GHCOLOR.B.FRAC} <= {LINE_GHCOLOR.B.INT,LINE_GHCOLOR.B.FRAC} + ({LINE_GHCOLOR_STEP.B.INT,LINE_GHCOLOR_STEP.B.FRAC}^{17{DIR[0]^LINE_GHCOLOR_STEP.B.DIR}}) + (DIR[0]^LINE_GHCOLOR_STEP.B.DIR);
					end
					  
					if ((LINE_VERTA.X == LINE_VERTB.X && LINE_DRAW_STEP) || (IS_PAT_EC && EC_FIND && TEXT_X_READ_STEP)) begin
						SPR_READ <= 0;
						CMD_ST <= CMDS_LINE_NEXT;
					end
				end
				
				CMDS_LINE_DRAW: if (!DRAW_WAIT && (SPR_DATA_READY || CMD.CMDCTRL.COMM >= 4'h4)) begin
					DRAW_ENABLE <= LINE_DRAW_STEP;
					
					if (TEXT_X_READ_STEP) begin
						TEXT_X <= TEXT_X + (HSS_EN ? 2'd2 : 2'd1);
						if (IS_PAT_EC) EC_FIND <= 1;
					end
					TEXT_ERROR <= NEXT_TEXT_ERROR;
					
					{LINE_VERTA_X_OVR,LINE_VERTA_Y_OVR} = '0;
					AA_DRAW = 0;
					AA_X <= LINE_VERTA.X + AA_X_INC;
					AA_Y <= LINE_VERTA.Y + AA_Y_INC;
					if (LINE_DRAW_STEP) begin
						if (LINE_AA_STEP) begin
							if (!LINE_S) begin
								LINE_VERTA.Y <= LINE_VERTA.Y + {{10{LINE_DIRY}},1'b1};
							end else begin
								LINE_VERTA.X <= LINE_VERTA.X + {{10{LINE_DIRX}},1'b1};
							end
							AA <= 1;
							AA_DRAW = 1;
						end else begin
							if (!LINE_S) begin
								LINE_VERTA.X <= LINE_VERTA.X + {{10{LINE_DIRX}},1'b1};
								LINE_VERTA_X_OVR = (LINE_VERTA.X == LINE_VERTB.X) || ($signed(LINE_VERTA.X) < $signed(SYS_CLIP_X1) && LINE_DIRX && !CMD.CMDPMOD.PCLP) || ($signed(LINE_VERTA.X) > $signed(SYS_CLIP_X2) && !LINE_DIRX && !CMD.CMDPMOD.PCLP);
								LINE_VERTA_Y_OVR = ($signed(LINE_VERTA.Y) < $signed(SYS_CLIP_Y1) && LINE_DIRY && !CMD.CMDPMOD.PCLP) || ($signed(LINE_VERTA.Y) > $signed(SYS_CLIP_Y2) && !LINE_DIRY && !CMD.CMDPMOD.PCLP);
							end else begin
								LINE_VERTA.Y <= LINE_VERTA.Y + {{10{LINE_DIRY}},1'b1};
								LINE_VERTA_X_OVR = ($signed(LINE_VERTA.X) < $signed(SYS_CLIP_X1) && LINE_DIRX && !CMD.CMDPMOD.PCLP) || ($signed(LINE_VERTA.X) > $signed(SYS_CLIP_X2) && !LINE_DIRX && !CMD.CMDPMOD.PCLP);
								LINE_VERTA_Y_OVR = (LINE_VERTA.Y == LINE_VERTB.Y) || ($signed(LINE_VERTA.Y) < $signed(SYS_CLIP_Y1) && LINE_DIRY && !CMD.CMDPMOD.PCLP) || ($signed(LINE_VERTA.Y) > $signed(SYS_CLIP_Y2) && !LINE_DIRY && !CMD.CMDPMOD.PCLP);
							end
						end
						LINE_ERROR <= NEXT_LINE_ERROR;
					
						{LINE_GHCOLOR.R.INT,LINE_GHCOLOR.R.FRAC} <= {LINE_GHCOLOR.R.INT,LINE_GHCOLOR.R.FRAC} + ({LINE_GHCOLOR_STEP.R.INT,LINE_GHCOLOR_STEP.R.FRAC}^{17{DIR[0]^LINE_GHCOLOR_STEP.R.DIR}}) + (DIR[0]^LINE_GHCOLOR_STEP.R.DIR);
						{LINE_GHCOLOR.G.INT,LINE_GHCOLOR.G.FRAC} <= {LINE_GHCOLOR.G.INT,LINE_GHCOLOR.G.FRAC} + ({LINE_GHCOLOR_STEP.G.INT,LINE_GHCOLOR_STEP.G.FRAC}^{17{DIR[0]^LINE_GHCOLOR_STEP.G.DIR}}) + (DIR[0]^LINE_GHCOLOR_STEP.G.DIR);
						{LINE_GHCOLOR.B.INT,LINE_GHCOLOR.B.FRAC} <= {LINE_GHCOLOR.B.INT,LINE_GHCOLOR.B.FRAC} + ({LINE_GHCOLOR_STEP.B.INT,LINE_GHCOLOR_STEP.B.FRAC}^{17{DIR[0]^LINE_GHCOLOR_STEP.B.DIR}}) + (DIR[0]^LINE_GHCOLOR_STEP.B.DIR);
					end

					if (IS_PAT_EC && EC_FIND && TEXT_X_READ_STEP) begin
						CMD_ST <= AA_DRAW ? CMDS_LINE_END : CMDS_LINE_NEXT;
					end else if ((LINE_VERTA_X_OVR || LINE_VERTA_Y_OVR) && LINE_DRAW_STEP) begin
						CMD_ST <= AA_DRAW ? CMDS_LINE_END : CMDS_LINE_NEXT;
					end else if (AA_DRAW) begin
						CMD_ST <= CMDS_AA_DRAW;
					end
				end
				
				CMDS_AA_DRAW: if (!DRAW_WAIT && (SPR_DATA_READY || CMD.CMDCTRL.COMM >= 4'h4)) begin
					DRAW_ENABLE <= 1;
					AA <= 0;
					
					{LINE_VERTA_X_OVR,LINE_VERTA_Y_OVR} = '0;
					if (!LINE_S) begin
						LINE_VERTA.X <= LINE_VERTA.X + {{10{LINE_DIRX}},1'b1};
						LINE_VERTA_X_OVR = (LINE_VERTA.X == LINE_VERTB.X);
					end else begin
						LINE_VERTA.Y <= LINE_VERTA.Y + {{10{LINE_DIRY}},1'b1};
						LINE_VERTA_Y_OVR = (LINE_VERTA.Y == LINE_VERTB.Y);
					end
					if ((LINE_VERTA_X_OVR || LINE_VERTA_Y_OVR) && LINE_DRAW_STEP) 
						CMD_ST <= CMDS_LINE_NEXT;
					else
						CMD_ST <= CMDS_LINE_DRAW;
				end
				
				CMDS_LINE_END: if (!DRAW_WAIT && (SPR_DATA_READY || CMD.CMDCTRL.COMM >= 4'h4)) begin
					DRAW_ENABLE <= AA;
					AA <= 0;
					CMD_ST <= CMDS_LINE_NEXT;
				end
				
				CMDS_LINE_NEXT: begin
					SPR_READ <= 0;
					TEXT_X <= '0;
					
					if (CMD.CMDCTRL.COMM == 4'h0 || CMD.CMDCTRL.COMM == 4'h1 || CMD.CMDCTRL.COMM == 4'h2 || CMD.CMDCTRL.COMM == 4'h3 || CMD.CMDCTRL.COMM == 4'h4) begin 
						if (LEFT_COL_X_STEP) begin
							LEFT_VERT.X <= LEFT_VERT.X + {{12{POLY_LDIRX}},1'b1};
						end
						if (LEFT_COL_Y_STEP) begin
							LEFT_VERT.Y <= LEFT_VERT.Y + {{12{POLY_LDIRY}},1'b1};
						end
						if (RIGHT_COL_X_STEP) begin
							RIGHT_VERT.X <= RIGHT_VERT.X + {{12{POLY_RDIRX}},1'b1};
						end
						if (RIGHT_COL_Y_STEP) begin
							RIGHT_VERT.Y <= RIGHT_VERT.Y + {{12{POLY_RDIRY}},1'b1};
						end
						
						LEFT_D_ERROR <= NEXT_LEFT_D_ERROR;
						LEFT_COL_ERROR_X <= NEXT_LEFT_COL_ERROR_X;
						LEFT_COL_ERROR_Y <= NEXT_LEFT_COL_ERROR_Y;
						RIGHT_D_ERROR <= NEXT_RIGHT_D_ERROR;
						RIGHT_COL_ERROR_X <= NEXT_RIGHT_COL_ERROR_X;
						RIGHT_COL_ERROR_Y <= NEXT_RIGHT_COL_ERROR_Y;
						
						{LEFT_GHCOLOR.R.INT, LEFT_GHCOLOR.R.FRAC } <= {LEFT_GHCOLOR.R.INT, LEFT_GHCOLOR.R.FRAC } + ({LEFT_GHCOLOR_STEP.R.INT, LEFT_GHCOLOR_STEP.R.FRAC }^{17{LEFT_GHCOLOR_STEP.R.DIR }}) + LEFT_GHCOLOR_STEP.R.DIR;
						{LEFT_GHCOLOR.G.INT, LEFT_GHCOLOR.G.FRAC } <= {LEFT_GHCOLOR.G.INT, LEFT_GHCOLOR.G.FRAC } + ({LEFT_GHCOLOR_STEP.G.INT, LEFT_GHCOLOR_STEP.G.FRAC }^{17{LEFT_GHCOLOR_STEP.G.DIR }}) + LEFT_GHCOLOR_STEP.G.DIR;
						{LEFT_GHCOLOR.B.INT, LEFT_GHCOLOR.B.FRAC } <= {LEFT_GHCOLOR.B.INT, LEFT_GHCOLOR.B.FRAC } + ({LEFT_GHCOLOR_STEP.B.INT, LEFT_GHCOLOR_STEP.B.FRAC }^{17{LEFT_GHCOLOR_STEP.B.DIR }}) + LEFT_GHCOLOR_STEP.B.DIR;
						{RIGHT_GHCOLOR.R.INT,RIGHT_GHCOLOR.R.FRAC} <= {RIGHT_GHCOLOR.R.INT,RIGHT_GHCOLOR.R.FRAC} + ({RIGHT_GHCOLOR_STEP.R.INT,RIGHT_GHCOLOR_STEP.R.FRAC}^{17{RIGHT_GHCOLOR_STEP.R.DIR}}) + RIGHT_GHCOLOR_STEP.R.DIR;
						{RIGHT_GHCOLOR.G.INT,RIGHT_GHCOLOR.G.FRAC} <= {RIGHT_GHCOLOR.G.INT,RIGHT_GHCOLOR.G.FRAC} + ({RIGHT_GHCOLOR_STEP.G.INT,RIGHT_GHCOLOR_STEP.G.FRAC}^{17{RIGHT_GHCOLOR_STEP.G.DIR}}) + RIGHT_GHCOLOR_STEP.G.DIR;
						{RIGHT_GHCOLOR.B.INT,RIGHT_GHCOLOR.B.FRAC} <= {RIGHT_GHCOLOR.B.INT,RIGHT_GHCOLOR.B.FRAC} + ({RIGHT_GHCOLOR_STEP.B.INT,RIGHT_GHCOLOR_STEP.B.FRAC}^{17{RIGHT_GHCOLOR_STEP.B.DIR}}) + RIGHT_GHCOLOR_STEP.B.DIR;
						
						CMD_ST <= CMDS_ROW_DRAW;
						COL_D <= COL_D - 12'd1;
						if (COL_D == 12'd0) begin
							CMD_ST <= CMDS_END;
						end
					end else if (CMD.CMDCTRL.COMM == 4'h5 || CMD.CMDCTRL.COMM == 4'h7) begin
						case (POLY_S)
							2'd0: begin
								LEFT_VERT <= VERTB;
								RIGHT_VERT <= VERTC;
								LEFT_GHCOLOR <= RGBItoF(GHCOLOR_B);
								RIGHT_GHCOLOR <= RGBItoF(GHCOLOR_C);
								CMD_ST <= CMDS_ROW_DRAW;
							end
							2'd1: begin
								LEFT_VERT <= VERTC;
								RIGHT_VERT <= VERTD;
								LEFT_GHCOLOR <= RGBItoF(GHCOLOR_C);
								RIGHT_GHCOLOR <= RGBItoF(GHCOLOR_D);
								CMD_ST <= CMDS_ROW_DRAW;
							end
							2'd2: begin
								LEFT_VERT <= VERTD;
								RIGHT_VERT <= VERTA;
								LEFT_GHCOLOR <= RGBItoF(GHCOLOR_D);
								RIGHT_GHCOLOR <= RGBItoF(GHCOLOR_A);
								CMD_ST <= CMDS_ROW_DRAW;
							end
							2'd3: begin
								CMD_ST <= CMDS_END;
							end
						endcase
						POLY_S <= POLY_S + 2'd01;
					end else if (CMD.CMDCTRL.COMM == 4'h6) begin
						CMD_ST <= CMDS_END;
					end else begin
						CMD_ST <= CMDS_END;
					end
				end
				
				CMDS_END: begin
					NEXT_ADDR = CMD_ADDR + 18'h10;
					case (CMD.CMDCTRL.JP[1:0])
						2'b00: begin CMD_ADDR <= NEXT_ADDR; end
						2'b01: begin CMD_ADDR <= {CMD.CMDLINK[15:2],2'b00,2'b00}; end
						2'b10: begin CMD_ADDR <= {CMD.CMDLINK[15:2],2'b00,2'b00}; CMD_RET_ADDR <= NEXT_ADDR; CMD_SUB_RUN <= 1; end
						2'b11: begin CMD_ADDR <= CMD_SUB_RUN ? CMD_RET_ADDR : NEXT_ADDR; CMD_SUB_RUN <= 0; end
					endcase
					
					if (CMD.CMDCTRL.END || CMD.CMDCTRL.COMM >= 4'hC) begin
						DRAW_END <= 1;
						CMD_ST <= CMDS_IDLE;
`ifdef DEBUG
						DBG_CMD_CNT <= '0;
`endif
					end else begin
						CMD_READ <= 1;
						CMD_ST <= CMDS_READ;
`ifdef DEBUG
						DBG_CMD_CNT <= DBG_CMD_CNT + 1'd1;
						DBG_CMD_ADDR_LAST <= CMD_ADDR;
						DBG_CMD_CMDSRCA_LAST <= CMD.CMDSRCA;
`endif
					end
				end
			endcase
		end
	end
`ifdef DEBUG
	assign DBG_START = (CMD_ST == CMDS_IDLE && (FRAME_START /*|| FRAME_START_PEND*/));
	assign DBG_CMD_END = (CMD_ST == CMDS_END);
	assign DBG_LINE_OVER = COL_HEIGHT > 12'h200 || ROW_WIDTH > 12'h200;
`endif
		
	assign PAT = GetPattern(SPR_DATA, CMD.CMDPMOD.CM);
	
	typedef enum bit [2:0] {
		FBDS_IDLE,
		FBDS_RAS,
		FBDS_READ,
		FBDS_READWAIT,
		FBDS_READBACK,
		FBDS_WRITE,
		FBDS_SKIP
	} FBDrawState_t;
	FBDrawState_t FBD_ST;
	
	bit          CPU_VRAM_BUSY;
	
	bit  [10: 0] DRAW_X;
	bit  [10: 0] DRAW_Y;
	Pattern_t    DRAW_PAT;
	RGB_t        DRAW_GHCOLOR;
	bit  [15: 0] DRAW_BACK_C;
	bit          FB_DRAW_PEND;
	bit          FB_READ_PEND;
	bit          PAT_NEXT;
	always @(posedge CLK or negedge RST_N) begin
		bit  [ 1: 0] RAS_DELAY;
		bit          FBD_RAS;
		
		if (!RST_N) begin
			FBD_ST <= FBDS_IDLE;
			FB_DRAW_PEND <= 0;
			FB_READ_PEND <= 0;
			PAT_NEXT <= 0;
			RAS_DELAY <= '0;
			FBD_RAS <= 0;
		end
		else begin
			PAT_NEXT <= 0;
			case (FBD_ST)
				FBDS_IDLE: begin
					if (CPU_VRAM_BUSY) begin
						FBD_ST <= FBDS_SKIP;
					end else if (SPR_DATA_READY || CMD.CMDCTRL.COMM >= 4'h4) begin
						if ((CMD_ST == CMDS_NSPR_DRAW || CMD_ST == CMDS_SSPR_DRAW || CMD_ST == CMDS_LINE_DRAW || CMD_ST == CMDS_AA_DRAW || CMD_ST == CMDS_LINE_END)) begin
							if ((CMD_ST == CMDS_AA_DRAW || CMD_ST == CMDS_LINE_END)) begin
								DRAW_X <= LOC_COORD.X + AA_X;
								DRAW_Y <= LOC_COORD.Y + AA_Y;
							end else begin
								if (LINE_AA_STEP && LINE_S) begin
									DRAW_X <= LOC_COORD.X + LINE_VERTA.X + {{10{LINE_DIRX}},1'b1};
								end else begin
									DRAW_X <= LOC_COORD.X + LINE_VERTA.X;
								end
								if (LINE_AA_STEP && !LINE_S) begin
									DRAW_Y <= LOC_COORD.Y + LINE_VERTA.Y + {{10{LINE_DIRY}},1'b1};
								end else begin
									DRAW_Y <= LOC_COORD.Y + LINE_VERTA.Y;
								end
								if (!(TEXT_X_READ_STEP && EC_FIND && IS_PAT_EC)) begin
									DRAW_PAT <= PAT;
									DRAW_GHCOLOR <= RGBFtoI(LINE_GHCOLOR);
								end
								FBD_RAS <= LINE_DRAW_STEP && (CMD.CMDCTRL.COMM <= 4'h1) && &LINE_VERTA.X[3:0];
							end
							
							
							if (LINE_DRAW_STEP && !IS_PAT_EC) begin
								if (CMD.CMDPMOD.CCB[0] || CMD.CMDPMOD.MON) begin
									FB_READ_PEND <= 1;
									FBD_ST <= FBDS_READ;
								end else begin
									FB_DRAW_PEND <= 1;
									FBD_ST <= FBDS_WRITE;
								end
							end else begin
								FBD_ST <= FBDS_SKIP;
							end
						end
						if (CMD_ST == CMDS_ROW_DRAW) begin
							FBD_RAS <= 1;
						end
						PAT_NEXT <= TEXT_X_READ_STEP;
					end
					
				end
				
				FBDS_READ: begin
					if (!FB_DRAW_WAIT) begin
						FB_READ_PEND <= 0;
						FBD_ST <= FBDS_READWAIT;
					end
				end
			
				FBDS_READWAIT: begin
					FBD_ST <= FBDS_READBACK;
				end
			
				FBDS_READBACK: begin
					DRAW_BACK_C <= FB_DRAW_Q;
					FB_DRAW_PEND <= 1;
					FBD_ST <= FBDS_WRITE;
				end
				
				FBDS_WRITE: begin
					if (!FB_DRAW_WAIT) begin
						FB_DRAW_PEND <= 0;
						if (FBD_RAS)
							if (PENALTY_CNT < 10'd3) begin
								FBD_ST <= FBDS_RAS;
							end else begin
								PENALTY_CNT <= PENALTY_CNT - 10'd3;
								FBD_ST <= FBDS_IDLE;
							end
						else
							FBD_ST <= FBDS_IDLE;
					end
				end
				
				FBDS_RAS: if (CE_R) begin
					RAS_DELAY <= RAS_DELAY + 2'd1;
					if (RAS_DELAY == 2'd2) begin
						RAS_DELAY <= 2'd0;
						FBD_RAS <= 0;
						FBD_ST <= FBDS_IDLE;
					end
				end
				
				FBDS_SKIP: begin
					FBD_ST <= FBDS_IDLE;
				end
			endcase
			
			if (((CMD_ST == CMDS_LINE_DRAW && CMD.CMDCTRL.COMM <= 4'h3) || CMD_ST == CMDS_NSPR_DRAW || CMD_ST == CMDS_SSPR_DRAW) && PAT_PREREAD_WAIT && !CPU_VRAM_BUSY && CE_R) PENALTY_CNT <= PENALTY_CNT + 10'd1;
			if (CMD_ST == CMDS_EXEC && CMD_DELAY && PENALTY_CNT >= CMD_DELAY) PENALTY_CNT <= PENALTY_CNT - CMD_DELAY;
		end
	end
	assign DRAW_WAIT = (FBD_ST != FBDS_IDLE) || CPU_VRAM_BUSY;
	
`ifdef DEBUG
	assign DBG_PENALTY_OVER = (PENALTY_CNT >= 10'd256);
`endif

	assign SPR_ADDR = CMD.CMDCTRL.COMM >= 4'h4 ? '1 : SprAddr(SPR_OFFSY, CMD.CMDSRCA, CMD.CMDPMOD.CM);
	assign CLT_ADDR = {CMD.CMDCOLR[15:2],2'b00,2'b00};
	assign GRD_ADDR = {CMD.CMDGRDA,2'b00};
	
	bit  [15: 0] FB_DRAW_D;
	bit          FB_DRAW_WE;
	bit          SCLIP;
	bit          UCLIP;
		bit [15: 0] ORIG_C;
		bit         TP;
	always_comb begin
		bit [15: 0] CALC_C;
		bit         EC;
		bit         MESH;
		bit         IDRAW;
		
		if (!CMD.CMDCTRL.COMM[2]) begin
			case (CMD.CMDPMOD.CM)
				3'b000: ORIG_C = {CMD.CMDCOLR[15:4],DRAW_PAT.C[3:0]};
				3'b001: ORIG_C = CLT_Q;
				3'b010: ORIG_C = {CMD.CMDCOLR[15:6],DRAW_PAT.C[5:0]};
				3'b011: ORIG_C = {CMD.CMDCOLR[15:7],DRAW_PAT.C[6:0]};
				3'b100: ORIG_C = {CMD.CMDCOLR[15:8],DRAW_PAT.C[7:0]};
				default: ORIG_C = DRAW_PAT.C;
			endcase
			TP = DRAW_PAT.TP;
			EC = DRAW_PAT.EC;
		end else begin
			ORIG_C = CMD.CMDCOLR;
			TP = 0;
			EC = 0;
		end
		CALC_C = CMD.CMDPMOD.MON ? {1'b1,DRAW_BACK_C[14:0]} : !TVMR.TVM[0] ? ColorCalc(ORIG_C, DRAW_BACK_C, DRAW_GHCOLOR, CMD.CMDPMOD.CCB) : ORIG_C;
			
		SCLIP = !DRAW_X[10]                                    && DRAW_X[9:0] <= SYS_CLIP.X2[9:0] && !DRAW_Y[10]                                    && DRAW_Y[9:0] <= SYS_CLIP.Y2[9:0];
		UCLIP = !DRAW_X[10] && DRAW_X[9:0] >= USR_CLIP.X1[9:0] && DRAW_X[9:0] <= USR_CLIP.X2[9:0] && !DRAW_Y[10] && DRAW_Y[9:0] >= USR_CLIP.Y1[9:0] && DRAW_Y[9:0] <= USR_CLIP.Y2[9:0];
		MESH = ~(DRAW_X[0] ^ DRAW_Y[0]);
		IDRAW = ~(DIL ^ DRAW_Y[0]);
		FB_DRAW_D = CALC_C;
		FB_DRAW_WE = (~TP | CMD.CMDPMOD.SPD) & (~EC | CMD.CMDPMOD.ECD) & SCLIP & ((UCLIP^CMD.CMDPMOD.CMOD) | ~CMD.CMDPMOD.CLIP) & (MESH | ~CMD.CMDPMOD.MESH) & (IDRAW | ~DIE);
	end
`ifdef DEBUG
	assign ORIG_C_DBG = ORIG_C;
	assign DBG_ORIG_RGB = ORIG_C[14:0];
	assign DRAW_X_DBG = DRAW_X;
	assign DRAW_Y_DBG = DRAW_Y;
	assign TP_DBG = TP;
	assign SCLIP_DBG = SCLIP;
	assign UCLIP_DBG = UCLIP;
	
	assign DBG_DRAW_OVER = DRAW_X[10:8] == 3'b011 || DRAW_X[10:8] == 3'b101 || DRAW_Y[10:8] == 2'b011 || DRAW_Y[10:8] == 3'b101;
	assign DBG_SPR_ADDR = SPR_ADDR;
`endif

	//FB out
	ScrnStart_t  RP_Xst;
	ScrnStart_t  RP_Yst;
	ScrnInc_t    RP_DXst;
	ScrnInc_t    RP_DYst;
	ScrnInc_t    RP_DX;
	ScrnInc_t    RP_DY;
	RotCoord_t   RXst,RYst;
	RotCoord_t   OUT_RX,OUT_RY;
	bit  [ 8: 0] OUT_X;
	bit  [ 8: 0] OUT_Y;
	bit          FRAME_ERASE_HIT;
	bit  [ 8: 0] ERASE_X;
	bit  [ 8: 0] ERASE_Y;
	bit          ERASE_HIT;
	bit  [15: 0] HTIM_PIPE;
	always @(posedge CLK or negedge RST_N) begin
		bit          HTIM_N_OLD;
		bit          VTIM_N_OLD;
		bit  [ 2: 0] RP_POS;
		bit          RP_FIRST;
		
		if (!RST_N) begin
			OUT_X <= '0;
			OUT_Y <= '0;
		end
		else begin
			HTIM_N_OLD <= HTIM_N;
			VTIM_N_OLD <= VTIM_N;
			
			if (DCE_R) begin
				HTIM_PIPE <= {HTIM_PIPE[14:0],HTIM_N};
			end
			
			if (DCE_R) begin
				if (RP_POS != 3'd7) RP_POS <= RP_POS + 3'd1;
			end
			if (!HTIM_N && HTIM_N_OLD) begin
				RP_POS <= '0;
			end
			if (VTIM_N && !VTIM_N_OLD) begin
				RP_FIRST <= 1;
			end
			if (HTIM_N && !HTIM_N_OLD) begin
				RP_FIRST <= 0;
			end
			
			if (DCE_F) begin
				case (RP_POS)
					3'd0: RP_Xst[31:16] <= VOUTI;	//0x18C/0x1A8
					3'd1: RP_Yst[31:16] <= VOUTI;	//0x18D/0x1A9
					3'd2: RP_DXst[31:16] <= VOUTI;//0x18E/0x1AA
					3'd3: RP_DYst[31:16] <= VOUTI;//0x18F/0x1AB
					3'd4: RP_DX[31:16] <= VOUTI;	//0x190/0x1AC
					3'd5: RP_DY[31:16] <= VOUTI;	//0x191/0x1AD
				endcase
			end
			if (DCE_R) begin
				case (RP_POS)
					3'd0: RP_Xst[15:0] <= VOUTI;
					3'd1: RP_Yst[15:0] <= VOUTI;
					3'd2: RP_DXst[15:0] <= VOUTI;
					3'd3: RP_DYst[15:0] <= VOUTI;
					3'd4: RP_DX[15:0] <= VOUTI;
					3'd5: RP_DY[15:0] <= VOUTI;
					3'd6: begin
						RXst <= $signed(RXst) + $signed(ScrnIncToRC(RP_DXst));
						RYst <= $signed(RYst) + $signed(ScrnIncToRC(RP_DYst));
						if (RP_FIRST) begin
							RXst <= ScrnStartToRC(RP_Xst);
							RYst <= ScrnStartToRC(RP_Yst);
						end
					end
				endcase
			end
			
			if (DCE_R) begin
				OUT_RX <= $signed(OUT_RX) + $signed(ScrnIncToRC(RP_DX));
				OUT_RY <= $signed(OUT_RY) + $signed(ScrnIncToRC(RP_DY));
				if (HTIM_PIPE[8:7] == 2'b01) begin
					OUT_RX <= $signed(RXst);
					OUT_RY <= $signed(RYst);
				end
			end
			
			if (VTIM_N && DCE_R) begin
				if (HTIM_PIPE[8:7] == 2'b01) begin
					OUT_X <= '0;
					OUT_Y <= OUT_Y + 9'd1;
				end
				else if (OUT_X < 9'd352 + 8) begin
					OUT_X <= OUT_X + 9'd1;
				end
			end
			
			if ((HTIM_N || |HTIM_PIPE) && VBLANK_ERASE && CE_R) begin
				OUT_X <= OUT_X + 9'd1;
				if ({1'b0,OUT_X} + 10'd1 == (!EWRR.X3[9] ? {EWRR.X3,3'b000} : 10'h200)) begin
					OUT_X <= {EWLR.X1,3'b000};
					OUT_Y <= OUT_Y + 9'd1;
				end
			end
			if (!VTIM_N && VTIM_N_OLD) begin
				OUT_X <= {EWLR.X1,3'b000};
				OUT_Y <= EWLR.Y1;
			end
			if (VTIM_N && !VTIM_N_OLD) begin
				OUT_Y <= '1;
			end
			if (CE_F) begin
				ERASE_HIT <= (OUT_X >= {EWLR.X1,3'b000}) && ({1'b0,OUT_X} < {EWRR.X3,3'b000}) && (OUT_Y >= EWLR.Y1) && (OUT_Y <= EWRR.Y3);
			end
		end
	end
	
	assign FRAME_ERASE_EN = ERASE_HIT && FRAME_ERASE && VTIM_N;
	assign VBLANK_ERASE_EN = ERASE_HIT && VBLANK_ERASE && (HTIM_N || |HTIM_PIPE);
	
	assign FB_ERASE_A = {OUT_Y[7:0],OUT_X[8:0]};
	assign FB_DISP_A = TVMR.TVM[1:0] == 2'b10 ? {OUT_RY.INT[7:0],OUT_RX.INT[8:0]} : 
	                   TVMR.TVM[1:0] == 2'b11 ? {OUT_RY.INT[8:0],OUT_RX.INT[8:1]} : 
							                          {     OUT_Y[7:0],     OUT_X[8:0]};
	bit DCLK;
	always @(posedge CLK) begin
		if      (DCE_R) DCLK <= 1;
		else if (DCE_F) DCLK <= 0;
		
		VOUTO <= TVMR.TVM[1:0] == 2'b01 ? (DCLK ? {8'hFF,FB_DISP_Q[15:8]} : {8'hFF,FB_DISP_Q[7:0]}) :
	            TVMR.TVM[1:0] == 2'b10 ? (OUT_RX.INT[10:9] || OUT_RY.INT[10:8] ? 16'h0000 : FB_DISP_Q) :
					TVMR.TVM[1:0] == 2'b11 ? (OUT_RX.INT[10:9] || OUT_RY.INT[10:9] ? 16'h0000 : !OUT_X[0] ? {8'h00,FB_DISP_Q[15:8]} : {8'h00,FB_DISP_Q[7:0]}) :
					FB_DISP_Q;
	end
	
	//VRAM
	typedef enum bit [3:0] {
		VS_IDLE,  
		VS_RAS0,VS_RAS1,VS_RAS2,
		VS_CPU_WRITE,
		VS_CPU_READ,
		VS_CMD_READ,
		VS_PAT_READ,
		VS_CLT_READ,
		VS_GRD_READ
	} VRAMState_t;
	VRAMState_t VRAM_ST;
	
	typedef enum bit [2:0] {
		FS_IDLE,  
		FS_CPU_WRITE,
		FS_CPU_WAIT,
		FS_CPU_READ,
		FS_DRAW
	} FBState_t;
	FBState_t FB_ST;
		
	wire CPU_VRAM_REQ = (A[20:19] == 2'b00) & ~AD_N & ~CS_N & ~REQ_N;	//000000-07FFFF
	wire CPU_FB_REQ = (A[20:19] == 2'b01) & ~AD_N & ~CS_N & ~REQ_N;	//080000-0FFFFF
	
	bit  [20: 1] A;
	bit          WE_N;
	bit  [ 1: 0] DQM;
	bit          BURST;
	bit          READY;
	bit          VRAM_SEL;
	
	bit          CPU_VRAM_RRDY;
	bit          CPU_FB_RRDY;
	bit          CPU_VRAM_WRDY;
	bit          CPU_FB_WRDY;
	bit          CPU_FB_RPEND;
	bit          CPU_FB_WPEND;
	
	wire [15: 0] PAT_FIFO_D = GetSprData(VRAM_Q, CMD.CMDPMOD.CM, PAT_CNT[1:0] ^ {2{CMD.CMDCTRL.DIR[0]}} ^ {2{DIR[0]}});
	wire         PAT_FIFO_WRREQ = VRAM_ST == VS_PAT_READ && !PAT_PREREAD && VRAM_RDY;
	wire         PAT_FIFO_RDREQ = PAT_NEXT && SPR_DATA_READY;
	bit  [15: 0] PAT_FIFO_Q;
	bit          PAT_FIFO_EMPTY;
	bit          PAT_FIFO_FULL;
	wire         PAT_FIFO_RST = !SPR_READ;
	VDP1_PAT_FIFO PAT_FIFO(CLK, PAT_FIFO_RST, PAT_FIFO_D, PAT_FIFO_WRREQ, PAT_FIFO_RDREQ, PAT_FIFO_Q, PAT_FIFO_EMPTY, PAT_FIFO_FULL);
	
	assign SPR_DATA = PAT_FIFO_Q;
	assign SPR_DATA_READY = !PAT_FIFO_EMPTY || PAT_CNT >= ORIG_WIDTH;
	
	bit  [15: 0] MEM_DO;
	bit  [ 8: 0] PAT_CNT;
	bit          PAT_PREREAD;
	bit  [ 3: 0] VRAM_READ_POS;
	bit          CPU_VRAM_RPEND;
	bit          CPU_VRAM_WPEND;
	bit          CPU_VRAM_ACCESS;
	always @(posedge CLK or negedge RST_N) begin
		bit         CS_N_OLD;
		bit         READY2,READY3;
//		bit         VRAM_PAGE_BREAK;
		bit [18: 1] CPU_RA;
		bit [18: 1] CPU_WA,CPU_FB_WA;
		bit [15: 0] CPU_D,CPU_FB_D;
		bit [ 1: 0] CPU_WE,CPU_FB_WE;
		bit [18: 1] SAVE_WA,SAVE_FB_WA;
		bit [15: 0] SAVE_D,SAVE_FB_D;
		bit [ 1: 0] SAVE_WE,SAVE_FB_WE;
		bit         CMD_READ_PEND;
		bit         CLT_READ_PEND;
		bit         GRD_READ_PEND;
		bit [ 8: 0] FB_Y;
		bit         VRAM_FIFO_FULL,FB_FIFO_FULL,VRAM_FIFO_EMPTY,FB_FIFO_EMPTY;
		bit [ 4: 0] CPU_ACCESS_WAIT,DRAW_ACCESS_WAIT;
		bit [ 1: 0] CPU_VRAM_WDELAY;
		
		if (!RST_N) begin
			VRAM_ST <= VS_IDLE;
			VRAM_A <= '0;
			VRAM_D <= '0;
			VRAM_WE <= '0;
			VRAM_RD <= 0;
			FB_ST <= FS_IDLE;
			FB_A <= '0;
			FB_D <= '0;
			FB_WE <= '0;
			FB_RD <= 0;
			{CMD_READ_PEND,CLT_READ_PEND,GRD_READ_PEND} <= 0;
			
			A <= '0;
			WE_N <= 1;
			DQM <= '1;
			BURST <= 0;
			READY <= 1;
			{CPU_VRAM_RPEND,CPU_VRAM_WPEND} <= '0;
			{CPU_VRAM_RRDY,CPU_VRAM_WRDY} <= '1;
			{CPU_FB_RPEND,CPU_FB_WPEND} <= '0;
			{CPU_FB_RRDY,CPU_FB_WRDY} <= '1;
			{VRAM_FIFO_FULL,FB_FIFO_FULL,VRAM_FIFO_EMPTY,FB_FIFO_EMPTY} <= '0;
			
			CPU_ACCESS_WAIT <= '0;
			DRAW_ACCESS_WAIT <= '0;
		end 
		else begin
			CS_N_OLD <= CS_N;
			if (CE_F) begin				
				READY2 <= 1;
				if (VRAM_FIFO_EMPTY && FB_FIFO_EMPTY) begin
					READY3 <= READY2; 
					READY <= READY2 & READY3;	
				end	
			end		
			if (!CS_N && CS_N_OLD) begin
				READY <= 0;
				READY2 <= 0;
				READY3 <= 0;
			end
			
			if (CE_R) begin
				if (!CS_N && DTEN_N && AD_N) begin
					if (!DI[15]) begin
						A[20:9] <= DI[11:0];
						WE_N <= DI[14];
						BURST <= DI[13];
						VRAM_SEL <= (DI[11:10] == 2'b00);
					end else begin
						A[8:1] <= DI[7:0];
						DQM <= DI[13:12];
					end
				end
			end
			if (CS_N && !CS_N_OLD) begin
				BURST <= 0;
				VRAM_SEL <= 0;
			end
			
			if (CMD_READ && !CMD_READ_PEND) begin CMD_READ_PEND <= 1; VRAM_READ_POS <= '0; end
			if (CLT_READ && !CLT_READ_PEND) begin CLT_READ_PEND <= 1; VRAM_READ_POS <= '0; end
			if (GRD_READ && !GRD_READ_PEND) begin GRD_READ_PEND <= 1; VRAM_READ_POS <= '0; end

			if (!SPR_READ) begin PAT_CNT <= {8'b00000000,HSS_EN&(FBCR.EOS^TEXT_DIRX)}; PAT_PREREAD <= 1; end
			
			if ((CPU_VRAM_REQ || CPU_FB_REQ) && WE_N && DTEN_N) begin 
				CPU_RA <= A[18:1];
				if (CPU_VRAM_REQ) begin
					CPU_VRAM_RPEND <= 1;
					CPU_VRAM_RRDY <= 0;
				end 
				if (CPU_FB_REQ) begin
					CPU_FB_RPEND <= 1;
					CPU_FB_RRDY <= 0;
				end
				A <= A + 20'd1;
			end
			
			if (CPU_VRAM_WDELAY && CE_F) CPU_VRAM_WDELAY <= CPU_VRAM_WDELAY - 2'd1;
			if (CPU_VRAM_REQ && !WE_N && !DTEN_N) begin
				if (!CPU_VRAM_WPEND) begin
					CPU_WA <= A[18:1];
					CPU_D <= DI;
					CPU_WE <= ~{2{WE_N}} & ~DQM;
					CPU_VRAM_WPEND <= 1;
					VRAM_FIFO_EMPTY <= 0;
				end else begin
					SAVE_WA <= A[18:1];
					SAVE_D <= DI;
					SAVE_WE <= ~{2{WE_N}} & ~DQM;
					CPU_VRAM_WRDY <= 0;
					VRAM_FIFO_FULL <= 1;
				end
				if (!BURST) CPU_VRAM_WDELAY <= 2'd3;
				A <= A + 20'd1;
			end
			if (!CPU_VRAM_WRDY && !CPU_VRAM_WPEND) begin
				CPU_WA <= SAVE_WA;
				CPU_D <= SAVE_D;
				CPU_WE <= SAVE_WE;
				CPU_VRAM_WPEND <= 1;
				CPU_VRAM_WRDY <= 1;
				VRAM_FIFO_EMPTY <= 0;
				VRAM_FIFO_FULL <= 0;
			end
			if (CPU_VRAM_WRDY && !CPU_VRAM_WPEND && !VRAM_FIFO_EMPTY) begin
				VRAM_FIFO_EMPTY <= 1;
			end
			
			if (CPU_FB_REQ && !WE_N && !DTEN_N) begin
				if (CPU_FB_REQ && !CPU_FB_WPEND) begin
					CPU_FB_WA <= A[18:1];
					CPU_FB_D <= DI;
					CPU_FB_WE <= ~{2{WE_N}} & ~DQM;
					CPU_FB_WPEND <= 1;
					FB_FIFO_EMPTY <= 0;
				end else begin
					SAVE_FB_WA <= A[18:1];
					SAVE_FB_D <= DI;
					SAVE_FB_WE <= ~{2{WE_N}} & ~DQM;
					CPU_FB_WRDY <= 0;
					FB_FIFO_FULL <= 1;
				end
				A <= A + 20'd1;
			end
			if (!CPU_FB_WRDY && !CPU_FB_WPEND) begin
				CPU_FB_WA <= SAVE_FB_WA;
				CPU_FB_D <= SAVE_FB_D;
				CPU_FB_WE <= SAVE_FB_WE;
				CPU_FB_WPEND <= 1;
				CPU_FB_WRDY <= 1;
				FB_FIFO_EMPTY <= 0;
				FB_FIFO_FULL <= 0;
			end
			if (CPU_FB_WRDY && !CPU_FB_WPEND && !FB_FIFO_EMPTY) begin
				FB_FIFO_EMPTY <= 1;
			end
			
			if (CPU_ACCESS_WAIT && CE_R) CPU_ACCESS_WAIT <= CPU_ACCESS_WAIT - 5'd1;
			if (DRAW_ACCESS_WAIT && CE_R) DRAW_ACCESS_WAIT <= DRAW_ACCESS_WAIT - 5'd1;
			case (VRAM_ST)
				VS_IDLE: if (VRAM_RDY) begin
					CPU_VRAM_ACCESS <= 0;
					if (CPU_VRAM_WPEND && !CPU_VRAM_WDELAY) begin
						CPU_VRAM_ACCESS <= 1;
						if (!CPU_ACCESS_WAIT) begin
							VRAM_A <= CPU_WA;
							if (VRAM_A[18:9] != CPU_WA[18:9]) begin
								VRAM_ST <= VS_RAS0;
							end else begin
								VRAM_D <= CPU_D;
								VRAM_WE <= CPU_WE;
								VRAM_RD <= 0;
								VRAM_BLEN <= '0;
								CPU_VRAM_WPEND <= 0;
								VRAM_ST <= VS_CPU_WRITE;
							end
						end
					end else if (CPU_VRAM_RPEND) begin
						CPU_VRAM_ACCESS <= 1;
						if (!CPU_ACCESS_WAIT) begin
							VRAM_A <= CPU_RA;
							VRAM_WE <= '0;
							VRAM_RD <= 1;
							VRAM_BLEN <= '0;
							CPU_VRAM_RPEND <= 0;
							VRAM_ST <= VS_CPU_READ;
						end
					end else if (DRAW_ACCESS_WAIT && !BURST) begin
						CPU_VRAM_ACCESS <= 1;
//					end else if (VRAM_PAGE_BREAK) begin
//						VRAM_ST <= VS_RAS;
					end else if (CMD_READ_PEND && !FRAME_START && !BURST && !VRAM_SEL) begin
						if (VRAM_READ_POS == 4'd15) CMD_READ_PEND <= 0;
						VRAM_A <= CMD_ADDR + VRAM_READ_POS;
						VRAM_WE <= '0;
						VRAM_RD <= 1;
						VRAM_BLEN <= '0;
						VRAM_ST <= VS_CMD_READ;
					end else if (SPR_READ && !PAT_FIFO_FULL && PAT_CNT < ORIG_WIDTH && !FRAME_START && !BURST && !VRAM_SEL) begin
						if (PAT_PREREAD) begin
							VRAM_A <= SPR_ADDR;
							case (CMD.CMDPMOD.CM)
								3'b000,
								3'b001: VRAM_BLEN <= {2'b00,ORIG_WIDTH[8:2]};
								3'b010,
								3'b011,
								3'b100: VRAM_BLEN <= {1'b0,ORIG_WIDTH[8:1]};
								default: VRAM_BLEN <= ORIG_WIDTH[8:0];
							endcase
						end else begin
							case (CMD.CMDPMOD.CM)
								3'b000,
								3'b001: VRAM_A <= !TEXT_DIRX ? SPR_ADDR + {2'b00,PAT_CNT[8:2]} : SPR_ADDR + ({2'b00,ORIG_WIDTH[8:2]} - {2'b00,PAT_CNT[8:2]} - 9'd1);
								3'b010,
								3'b011,
								3'b100: VRAM_A <= !TEXT_DIRX ? SPR_ADDR + {1'b0,PAT_CNT[8:1]} : SPR_ADDR + ({1'b0,ORIG_WIDTH[8:1]} - {1'b0,PAT_CNT[8:1]} - 9'd1);
								default: VRAM_A <= !TEXT_DIRX ? SPR_ADDR + PAT_CNT[8:0] : SPR_ADDR + (ORIG_WIDTH[8:0] - PAT_CNT[8:0] - 9'd1);
							endcase
							VRAM_BLEN <= '0;
						end
						VRAM_WE <= '0;
						VRAM_RD <= 1;
						VRAM_ST <= VS_PAT_READ;
					end else if (CLT_READ_PEND && !FRAME_START && !BURST && !VRAM_SEL) begin
						if (VRAM_READ_POS == 4'd15) CLT_READ_PEND <= 0;
						VRAM_A <= CLT_ADDR + VRAM_READ_POS;
						VRAM_WE <= '0;
						VRAM_RD <= 1;
						VRAM_BLEN <= '0;
						VRAM_ST <= VS_CLT_READ;
					end else if (GRD_READ_PEND && !FRAME_START && !BURST && !VRAM_SEL) begin
						if (VRAM_READ_POS == 4'd3) GRD_READ_PEND <= 0;
						VRAM_A <= GRD_ADDR + VRAM_READ_POS;
						VRAM_WE <= '0;
						VRAM_RD <= 1;
						VRAM_BLEN <= '0;
						VRAM_ST <= VS_GRD_READ;
					end
				end
				
				VS_RAS0: if (CE_F) begin
					VRAM_ST <= VS_RAS1;
				end
				
				VS_RAS1: if (CE_F) begin
					VRAM_ST <= VS_RAS2;
				end
				
				VS_RAS2: if (CE_F) begin
					VRAM_ST <= VS_IDLE;
				end
				
				VS_CPU_WRITE: begin
					VRAM_WE <= '0;
//					VRAM_PAGE_BREAK <= 1;
					DRAW_ACCESS_WAIT <= FAST ? 5'd5 : 5'd13;
					if (!VRAM_FIFO_FULL && !BURST) CPU_ACCESS_WAIT <= 5'd10;
					VRAM_ST <= VS_IDLE;
				end
				
				VS_CPU_READ: begin
					if (VRAM_RDY && CE_R) begin
						MEM_DO <= VRAM_Q;
						VRAM_RD <= 0;
//						VRAM_PAGE_BREAK <= 1;
						DRAW_ACCESS_WAIT <= FAST ? 5'd5 : 5'd13;
						CPU_VRAM_RRDY <= 1;
						VRAM_ST <= VS_IDLE;
					end
				end
					
				VS_CMD_READ: begin
					VRAM_RD <= 0;
					if (FRAME_START) begin
						VRAM_WE <= '0;
						VRAM_RD <= 0;
						VRAM_ST <= VS_IDLE;
					end else if (VRAM_RDY) begin
						VRAM_READ_POS <= VRAM_READ_POS + 4'd1;
						CPU_ACCESS_WAIT <= 5'd10;
						VRAM_ST <= VS_IDLE;
					end
				end
				
				VS_CLT_READ: begin
					VRAM_RD <= 0;
					if (FRAME_START) begin
						VRAM_RD <= 0;
						VRAM_ST <= VS_IDLE;
					end else if (VRAM_RDY) begin
						VRAM_READ_POS <= VRAM_READ_POS + 4'd1;
						CPU_ACCESS_WAIT <= 5'd10;
						VRAM_ST <= VS_IDLE;
					end
				end
				
				VS_PAT_READ: begin
					VRAM_RD <= 0;
					if (FRAME_START || !SPR_READ) begin
						VRAM_WE <= '0;
						VRAM_RD <= 0;
						VRAM_ST <= VS_IDLE;
					end else if (VRAM_RDY) begin
						if (!PAT_PREREAD) begin
							PAT_CNT <= PAT_CNT + (HSS_EN ? 9'd2 : 9'd1);
							CPU_ACCESS_WAIT <= 5'd10;
						end
						PAT_PREREAD <= 0;
						VRAM_ST <= VS_IDLE;
					end
				end
				
				VS_GRD_READ: begin
					VRAM_RD <= 0;
					if (FRAME_START) begin
						VRAM_RD <= 0;
						VRAM_ST <= VS_IDLE;
					end else if (VRAM_RDY) begin
						VRAM_READ_POS <= VRAM_READ_POS + 4'd1;
						CPU_ACCESS_WAIT <= 5'd10;
						VRAM_ST <= VS_IDLE;
					end
				end
			endcase
			
			if (FRAME_START) begin
				CMD_READ_PEND <= 0;
				CLT_READ_PEND <= 0;
				GRD_READ_PEND <= 0;
			end
			
			case (FB_ST)
				FS_IDLE: begin
					if (CPU_FB_WPEND && !FB_WE) begin
						if (FB_RDY) begin
							FB_A <= CPU_FB_WA[17:1];
							FB_D <= CPU_FB_D;
							FB_WE <= CPU_FB_WE;
							CPU_FB_WPEND <= 0;
							FB_ST <= FS_CPU_WRITE;
						end
					end else if (CPU_FB_RPEND && !FB_RD) begin
						if (FB_RDY) begin
							FB_A <= CPU_RA[17:1];
							FB_RD <= 1;
							CPU_FB_RPEND <= 0;
							FB_ST <= FS_CPU_WAIT;
						end
					end
					else if (((FB_READ_PEND && !FB_RD) || (FB_DRAW_PEND && !FB_WE)) && FB_DRAW_WE) begin
						FB_Y = !DIE ? DRAW_Y[8:0] : DRAW_Y[9:1];
						casex (TVMR.TVM[1:0]) 
							2'bx0: begin
								FB_A <= {FB_Y[7:0],DRAW_X[8:0]};
								FB_D <= FB_DRAW_D;
								FB_WE <= {2{FB_DRAW_PEND}};
								FB_RD <= FB_READ_PEND;
							end
							2'b01: begin
								FB_A <= {FB_Y[7:0],DRAW_X[9:1]};
								FB_D <= {FB_DRAW_D[7:0],FB_DRAW_D[7:0]};
								FB_WE <= {~DRAW_X[0],DRAW_X[0]} & {2{FB_DRAW_PEND}};
								FB_RD <= FB_READ_PEND;
							end
							2'b11: begin
								FB_A <= {FB_Y[8:0],DRAW_X[8:1]};
								FB_D <= {FB_DRAW_D[7:0],FB_DRAW_D[7:0]};
								FB_WE <= {~DRAW_X[0],DRAW_X[0]} & {2{FB_DRAW_PEND}};
								FB_RD <= FB_READ_PEND;
							end
						endcase
						FB_ST <= FS_DRAW;
					end
				end
				
				FS_CPU_WRITE: begin
					FB_WE <= '0;
					FB_ST <= FS_IDLE;
				end
				
				FS_CPU_WAIT: begin
					FB_ST <= FS_CPU_READ;
				end
				
				FS_CPU_READ: begin
					if (FB_RDY && CE_R) begin
						MEM_DO <= FB_DRAW_Q;
						FB_RD <= 0;
						CPU_FB_RRDY <= 1;
						FB_ST <= FS_IDLE;
					end
				end
				
				FS_DRAW: begin
					FB_WE <= '0;
					FB_RD <= 0;
					FB_ST <= FS_IDLE;
				end
			endcase
		end
	end
	assign CPU_VRAM_BUSY = VRAM_SEL || CPU_VRAM_RPEND || CPU_VRAM_WPEND || CPU_VRAM_ACCESS;
	assign FB_DRAW_WAIT = (FB_ST != FS_IDLE) || CPU_FB_WPEND || CPU_FB_RPEND;
	wire PAT_PREREAD_WAIT = (VRAM_ST == VS_PAT_READ) && PAT_PREREAD && !VRAM_RDY;
	
	bit [ 3: 0] CMD_POS;
	bit [15: 0] CMD_DAT;
	bit         CMD_WE,CLT_WE,GRD_WE;
	always @(posedge CLK or negedge RST_N) begin
		bit         CMD_WE,GRD_WE;
		
		if (!RST_N) begin
			CMD_WE <= 0;
			CLT_WE <= 0;
			GRD_WE <= 0;
		end else begin
			CMD_DAT <= VRAM_Q;
			CMD_POS <= VRAM_READ_POS;
			CMD_WE <= (VRAM_ST == VS_CMD_READ && VRAM_RDY);
			if (CMD_WE) begin
				case (CMD_POS)
					4'h0: CMD.CMDCTRL <= CMD_DAT;
					4'h1: CMD.CMDLINK <= CMD_DAT;
					4'h2: CMD.CMDPMOD <= CMD_DAT;
					4'h3: CMD.CMDCOLR <= CMD_DAT;
					4'h4: CMD.CMDSRCA <= CMD_DAT;
					4'h5: CMD.CMDSIZE <= CMD_DAT;
					4'h6: CMD.CMDXA <= CMD_DAT;
					4'h7: CMD.CMDYA <= CMD_DAT;
					4'h8: CMD.CMDXB <= CMD_DAT;
					4'h9: CMD.CMDYB <= CMD_DAT;
					4'hA: CMD.CMDXC <= CMD_DAT;
					4'hB: CMD.CMDYC <= CMD_DAT;
					4'hC: CMD.CMDXD <= CMD_DAT;
					4'hD: CMD.CMDYD <= CMD_DAT;
					4'hE: CMD.CMDGRDA <= CMD_DAT;
				endcase
			end
			
			CLT_WE <= (VRAM_ST == VS_CLT_READ) && VRAM_RDY;
			
			GRD_WE <= (VRAM_ST == VS_GRD_READ) && VRAM_RDY;
			if (GRD_WE) begin
				GRD_TBL[CMD_POS[1:0]] <= CMD_DAT;
			end
		end
	end
	assign CMD_READ_DONE = (VRAM_ST == VS_CMD_READ) && VRAM_RDY && (VRAM_READ_POS == 4'd15);
	
	wire [ 3: 0] CLT_RA = DRAW_PAT.C[3:0];
	VDP1_COL_TBL CLT(.CLK(CLK), .WRADDR(CMD_POS), .DATA(CMD_DAT), .WREN(CLT_WE), .RDADDR(CLT_RA), .Q(CLT_Q));
	assign CLT_READ_DONE = (VRAM_ST == VS_CLT_READ) && VRAM_RDY && (VRAM_READ_POS == 4'd15);
	
	assign GRD_READ_DONE = (VRAM_ST == VS_GRD_READ) && VRAM_RDY && (VRAM_READ_POS == 4'd3);

	//Registers
	wire REG_REQ = (A[20:19] == 2'b10) & ~AD_N & ~CS_N & ~REQ_N;
	
	assign MODR = {4'h0,3'b000,PTMR.PTM[1],FBCR.EOS,FBCR.DIE,FBCR.DIL,FBCR.FCM,TVMR.VBE,TVMR.TVM};
	
	bit        VBOUT;
	always @(posedge CLK or negedge RST_N) begin
		bit        HTIM_N_OLD;
		bit        VTIM_N_OLD;
		bit        FRAME_CHANGE;
		bit        MANUAL_ERASECHANGE_PEND;
		bit        START_DRAW_PEND;
		bit        VBERASE_PEND;
		
		if (!RST_N) begin
			TVMR <= '0;
			FBCR <= '0;
			PTMR <= '0;
			EWDR <= 16'h0000;
			EWLR <= 16'h0000;
			EWRR <= 16'h0000;
			EDSR <= '0;
			IRQ_N <= 1;
			
			MANUAL_ERASECHANGE_PEND <= 0;
			FRAME_ERASE <= 0;
			VBLANK_ERASE <= 0;
			DRAW_TERMINATE <= 0;
			VBERASE_PEND <= 0;
		end else if (!RES_N) begin
			PTMR <= '0;
		end else begin
			START_DRAW_PEND <= 0;
			DRAW_TERMINATE <= 0;
			if (REG_REQ && !WE_N && !DTEN_N) begin
				case ({A[5:1],1'b0})
					5'h00: TVMR <= DI & TVMR_MASK;
					5'h02: FBCR <= DI & FBCR_MASK;
					5'h04: PTMR <= DI & PTMR_MASK;
					5'h06: EWDR <= DI & EWDR_MASK;
					5'h08: EWLR <= DI & EWLR_MASK;
					5'h0A: EWRR <= DI & EWRR_MASK;
					default:;
				endcase
				if (A[5:1] == 5'h02>>1 && DI[1]) MANUAL_ERASECHANGE_PEND <= 1;
				if (A[5:1] == 5'h04>>1 && DI[1:0] == 2'b01) begin 
					START_DRAW_PEND <= 1; 
`ifdef DEBUG
					START_DRAW_CNT <= START_DRAW_CNT + 8'd1; 
`endif
				end
				if (A[5:1] == 5'h0C>>1 && DI[1]) DRAW_TERMINATE <= 1;
			end
			
			if (DRAW_END) begin
				EDSR.CEF <= 1;
			end
			IRQ_N <= ~EDSR.CEF;

			FRAME_START <= 0;
			if (START_DRAW_PEND) begin
				FRAME_START <= 1;
				EDSR.CEF <= 0;
				DIE <= FBCR.DIE;
				DIL <= FBCR.DIL;
			end
			if (FRAME_CHANGE) begin
				FRAME_ERASE <= 0;
`ifdef DEBUG
				FRAMES_DBG <= FRAMES_DBG + 8'd1;
`endif
				if (!FBCR.FCM || DBG_DRAW_EN) begin
					FB_SEL <= ~FB_SEL;
					FRAME_ERASE <= ~TVMR.TVM[1];
					VBERASE_PEND <= TVMR.TVM[1];
					EDSR.CEF <= 0;
					EDSR.BEF <= EDSR.CEF;
					DIE <= FBCR.DIE;
					DIL <= FBCR.DIL;
					if (PTMR.PTM[1] || DBG_DRAW_EN) begin
						FRAME_START <= 1;
					end
					MANUAL_ERASECHANGE_PEND <= 0;
`ifdef DEBUG
					FRAMES_DBG <= 8'd0;
`endif
				end else if ((MANUAL_ERASECHANGE_PEND || DBG_DRAW_EN) && FBCR.FCT) begin
					FB_SEL <= ~FB_SEL;
					EDSR.CEF <= 0;
					EDSR.BEF <= EDSR.CEF;
					DIE <= FBCR.DIE;
					DIL <= FBCR.DIL;
					if (PTMR.PTM[1] || DBG_DRAW_EN) begin
						FRAME_START <= 1;
					end
					MANUAL_ERASECHANGE_PEND <= 0;
`ifdef DEBUG
					FRAMES_DBG <= 8'd0;
`endif
				end else if (MANUAL_ERASECHANGE_PEND && !FBCR.FCT) begin
					FRAME_ERASE <= ~TVMR.TVM[1];
					VBERASE_PEND <= TVMR.TVM[1];
					MANUAL_ERASECHANGE_PEND <= 0;
				end;
			end
			
			FRAME_CHANGE <= 0;
			if (DCE_R) begin
				HTIM_N_OLD <= HTIM_N;
				VTIM_N_OLD <= VTIM_N;
				
				if (VTIM_N && !VTIM_N_OLD) begin
					VBOUT <= 1;
				end
				if (VTIM_N && HTIM_PIPE[11:10] == 2'b10 && VBOUT) begin
					VBOUT <= 0;
					FRAME_CHANGE <= 1;
				end
				
				if (!VTIM_N && VTIM_N_OLD) begin
					if (TVMR.VBE) begin
						VBLANK_ERASE <= 1;
					end
					if (VBERASE_PEND) begin
						VBLANK_ERASE <= 1;
					end
					VBERASE_PEND <= 0;
				end
				if (VTIM_N && !VTIM_N_OLD) begin
					VBLANK_ERASE <= 0;
				end
			end
		end
	end
	
	bit  [15: 0] REG_DO;
	always_comb begin
		case ({A[5:1],1'b0})
			5'h10: REG_DO <= EDSR & EDSR_MASK;
			5'h12: REG_DO <= LOPR & LOPR_MASK;
			5'h14: REG_DO <= COPR & COPR_MASK;
			5'h16: REG_DO <= MODR & MODR_MASK;
			default: REG_DO <= '0;
		endcase
	end
	assign DO = A[20] ? REG_DO : MEM_DO;
	assign RDY_N = ~CPU_VRAM_RRDY | ~CPU_VRAM_WRDY | ~CPU_FB_RRDY | ~CPU_FB_WRDY | ~READY;
	
endmodule


module VDP1_PAT_FIFO #(parameter l = 1) (
	input	         CLK,
	input          RST,
	
	input	 [15: 0] DATA,
	input	         WRREQ,
	input	         RDREQ,
	output [15: 0] Q,
	output	      EMPTY,
	output	      FULL
);

	wire [15: 0] sub_wire0;
	bit  [l-1: 0] RADDR;
	bit  [l-1: 0] WADDR;
	bit  [l: 0] AMOUNT;
	
	always @(posedge CLK) begin
		if (RST) begin
			AMOUNT <= '0;
			RADDR <= '0;
			WADDR <= '0;
		end
		else begin
			if (WRREQ && !AMOUNT[l]) begin
				WADDR <= WADDR + 1'd1;
			end
			if (RDREQ && AMOUNT) begin
				RADDR <= RADDR + 1'd1;
			end
			
			if (WRREQ && !RDREQ && !AMOUNT[l]) begin
				AMOUNT <= AMOUNT + 1'd1;
			end else if (!WRREQ && RDREQ && AMOUNT) begin
				AMOUNT <= AMOUNT - 1'd1;
			end
		end
	end
	assign EMPTY = ~|AMOUNT;
	assign FULL = AMOUNT[l];
	
	altdpram	altdpram_component (
				.data (DATA),
				.inclock (CLK),
				.rdaddress (RADDR),
				.wraddress (WADDR),
				.wren (WRREQ),
				.q (sub_wire0),
				.aclr (1'b0),
				.byteena (1'b1),
				.inclocken (1'b1),
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
		altdpram_component.width = 16,
		altdpram_component.widthad = l,
		altdpram_component.width_byteena = 1,
		altdpram_component.wraddress_aclr = "OFF",
		altdpram_component.wraddress_reg = "INCLOCK",
		altdpram_component.wrcontrol_aclr = "OFF",
		altdpram_component.wrcontrol_reg = "INCLOCK";
		
	assign Q = sub_wire0;

endmodule

module VDP1_COL_TBL (
	input         CLK,
	input	  [3:0] WRADDR,
	input	 [15:0] DATA,
	input	        WREN,
	input	  [3:0] RDADDR,
	output [15:0] Q
);

	wire [15:0] sub_wire0;

	altdpram	altdpram0 (
				.data (DATA),
				.inclock (CLK),
				.rdaddress (RDADDR[3:0]),
				.wraddress (WRADDR[3:0]),
				.wren (WREN),
				.q (sub_wire0),
				.aclr (1'b0),
				.byteena (1'b1),
				.inclocken (1'b1),
				.rdaddressstall (1'b0),
				.rden (1'b1),
				//.sclr (1'b0),
				.wraddressstall (1'b0));
	defparam
		altdpram0.indata_aclr = "OFF",
		altdpram0.indata_reg = "INCLOCK",
		altdpram0.intended_device_family = "Cyclone V",
		altdpram0.lpm_type = "altdpram",
		altdpram0.outdata_aclr = "OFF",
		altdpram0.outdata_reg = "UNREGISTERED",
		altdpram0.ram_block_type = "MLAB",
		altdpram0.rdaddress_aclr = "OFF",
		altdpram0.rdaddress_reg = "UNREGISTERED",
		altdpram0.rdcontrol_aclr = "OFF",
		altdpram0.rdcontrol_reg = "UNREGISTERED",
		altdpram0.read_during_write_mode_mixed_ports = "CONSTRAINED_DONT_CARE",
		altdpram0.width = 16,
		altdpram0.widthad = 4,
		altdpram0.width_byteena = 1,
		altdpram0.wraddress_aclr = "OFF",
		altdpram0.wraddress_reg = "INCLOCK",
		altdpram0.wrcontrol_aclr = "OFF",
		altdpram0.wrcontrol_reg = "INCLOCK";

	assign Q =  sub_wire0;

endmodule

module VDP1_DIV (
	denom,
	numer,
	quotient,
	remain);

	input	[11:0]  denom;
	input	[20:0]  numer;
	output	[20:0]  quotient;
	output	[11:0]  remain;

	wire [20:0] sub_wire0;
	wire [11:0] sub_wire1;
	wire [20:0] quotient = sub_wire0;
	wire [11:0] remain = sub_wire1;

	lpm_divide	LPM_DIVIDE_component (
				.denom (denom),
				.numer (numer),
				.quotient (sub_wire0),
				.remain (sub_wire1),
				.aclr (1'b0),
				.clken (1'b1),
				.clock (1'b0));
	defparam
		LPM_DIVIDE_component.lpm_drepresentation = "UNSIGNED",
		LPM_DIVIDE_component.lpm_hint = "LPM_REMAINDERPOSITIVE=TRUE",
		LPM_DIVIDE_component.lpm_nrepresentation = "UNSIGNED",
		LPM_DIVIDE_component.lpm_type = "LPM_DIVIDE",
		LPM_DIVIDE_component.lpm_widthd = 12,
		LPM_DIVIDE_component.lpm_widthn = 21;

endmodule


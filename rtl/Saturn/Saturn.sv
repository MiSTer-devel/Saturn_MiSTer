module Saturn
#(parameter bit RAMH_SLOW=0)
(
	input             CLK,
	input             RST_N,
	input             EN,
	
	input             SYS_CE_F,
	input             SYS_CE_R,
	
	input             SRES_N,
	
	input             PAL,
	
	output     [24:0] MEM_A,
	input      [31:0] MEM_DI,
	output     [31:0] MEM_DO,
	output            ROM_CS_N,
	output            SRAM_CS_N,
	output            RAML_CS_N,
	output            RAMH_CS_N,
	output            RAMH_RFS,
`ifdef STV_BUILD
	output            STVIO_CS_N,
`endif
	output      [3:0] MEM_DQM_N,
	output            MEM_RD_N,
	input             MEM_WAIT_N,
	
	output     [18:1] VDP1_VRAM_A,
	output     [15:0] VDP1_VRAM_D,
	input      [15:0] VDP1_VRAM_Q,
	output      [1:0] VDP1_VRAM_WE,
	output            VDP1_VRAM_RD,
	output      [8:0] VDP1_VRAM_BLEN,
	input             VDP1_VRAM_RDY,
	
	output     [17:1] VDP1_FB0_A,
	output     [15:0] VDP1_FB0_D,
	input      [15:0] VDP1_FB0_Q,
	output      [1:0] VDP1_FB0_WE,
	output            VDP1_FB0_RD,
	
	output     [17:1] VDP1_FB1_A,
	output     [15:0] VDP1_FB1_D,
	input      [15:0] VDP1_FB1_Q,
	output      [1:0] VDP1_FB1_WE,
	output            VDP1_FB1_RD,
	
	input             VDP1_FB_RDY,
	output            VDP1_FB_MODE3,
	
	output     [18:1] VDP2_RA0_A,
	output     [16:1] VDP2_RA1_A,
	output     [63:0] VDP2_RA_D,
	output      [7:0] VDP2_RA_WE,
	output            VDP2_RA_RD,
	input      [31:0] VDP2_RA0_Q,
	input      [31:0] VDP2_RA1_Q,
	
	output     [18:1] VDP2_RB0_A,
	output     [16:1] VDP2_RB1_A,
	output     [63:0] VDP2_RB_D,
	output      [7:0] VDP2_RB_WE,
	output            VDP2_RB_RD,
	input      [31:0] VDP2_RB0_Q,
	input      [31:0] VDP2_RB1_Q,

	input             SCSP_CE,
	output     [18:1] SCSP_RAM_A,
	output     [15:0] SCSP_RAM_D,
	output      [1:0] SCSP_RAM_WE,
	output            SCSP_RAM_RD,
	output            SCSP_RAM_CS,
	input      [15:0] SCSP_RAM_Q,
	output            SCSP_RAM_RFS,
	input             SCSP_RAM_RDY,
	
	input             SMPC_CE,
	input             TIME_SET,
	input      [64:0] RTC,
	input       [3:0] SMPC_AREA,
	output            SMPC_DOTSEL,
	
	input     [ 6: 0] SMPC_PDR1I,
	output    [ 6: 0] SMPC_PDR1O,
	output    [ 6: 0] SMPC_DDR1,
	input     [ 6: 0] SMPC_PDR2I,
	output    [ 6: 0] SMPC_PDR2O,
	output    [ 6: 0] SMPC_DDR2,

`ifndef STV_BUILD
	input             CD_CE,
	input             CD_CDATA,
	output            CD_HDATA,
	output            CD_COMCLK,
	input             CD_COMREQ_N,
	input             CD_COMSYNC_N,
	output            CD_DEMP,
	input      [15:0] CD_D,
	input             CD_CK,
	input             CD_AUDIO,
	output     [18:1] CD_RAM_A,
	output     [15:0] CD_RAM_D,
	output      [1:0] CD_RAM_WE,
	output            CD_RAM_RD,
	output            CD_RAM_CS,
	input      [15:0] CD_RAM_Q,
	input             CD_RAM_RDY,
`endif
	
	input       [2:0] CART_MODE,
	output     [25:1] CART_MEM_A,
	output     [15:0] CART_MEM_D,
	output     [ 1:0] CART_MEM_WE,
	output            CART_MEM_RD,
	input      [15:0] CART_MEM_Q,
	input             CART_MEM_RDY,
	
`ifdef STV_BUILD
	input      [ 7: 0] STV_SW,
`endif
	
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
	output      [1:0] HRES,
	output      [1:0] VRES,
	output            DCE_R,
	output            DCE_F,
	
	output     [15:0] SOUND_L,
	output     [15:0] SOUND_R,
	
	input             FAST,
	
	input       [7:0] SCRN_EN,
	input       [2:0] SND_EN,
	input      [31:0] SLOT_EN,
	input             DBG_PAUSE,
	input             DBG_BREAK,
	input             DBG_RUN,
	input       [7:0] DBG_EXT
);

	bit BREAK;
	bit START;
`ifdef DEBUG
	bit VDP1_CMD_END,VDP1_START;
`endif
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			BREAK <= 0;
			START <= 0;
		end
		else begin
`ifdef DEBUG
			if (VDP1_START) begin
				BREAK <= DBG_BREAK;
				START <= 1;
			end else if (VDP1_CMD_END && START) begin
				BREAK <= DBG_BREAK;
			end else 
`endif
			if (DBG_RUN) begin
				BREAK <= 0;
			end 
		end
	end
	wire PAUSE = DBG_PAUSE | BREAK;
	
	
	//MSH
	bit  [26:0] MSHA;
	bit  [31:0] MSHDO;
	bit  [31:0] MSHDI;
	bit         MSHBS_N;
	bit         MSHCS0_N;
	bit         MSHCS1_N;
	bit         MSHCS2_N;
	bit         MSHCS3_N;
	bit         MSHRD_WR_N;
	bit   [3:0] MSHDQM_N;
	bit         MSHRD_N;
	bit         MSHWAIT_N;
	bit         MSHIVECF_N;
	bit   [3:0] MSHIRL_N;
	bit         MSHRES_N;
	bit         MSHNMI_N;
	bit         MSHBGR_N;
	bit         MSHBRLS_N;
	bit         MSRFS;
	
	//SSH
	bit  [26:0] SSHA;
	bit  [31:0] SSHDO;
	bit  [31:0] SSHDI;
	bit         SSHBS_N;
	bit         SSHCS0_N;
	bit         SSHCS1_N;
	bit         SSHCS2_N;
	bit         SSHCS3_N;
	bit         SSHRD_WR_N;
	bit   [3:0] SSHDQM_N;
	bit         SSHRD_N;
	bit         SSHWAIT_N;
	bit   [3:0] SSHIRL_N;
	bit         SSHRES_N;
	bit         SSHNMI_N;
	bit         SSHBREQ_N;
	bit         SSHBACK_N;
	
	//SCU
	bit  [24:0] CA;
	bit  [31:0] CDO;
	bit  [31:0] CDI;
	bit         CBS_N;
	bit         CCS0_N;
	bit         CCS1_N;
	bit         CCS2_N;
	bit         CCS3_N;
	bit         CRD_WR_N;
	bit   [3:0] CDQM_N;
	bit         CRD_N;
	bit         CWAIT_N;
	bit         CWATIN_N;
	bit         CIVECF_N;
	bit   [3:0] CIRL_N;
	bit         CBREQ_N;
	bit         CBACK_N;
	
	bit  [24:0] ECA;
	bit  [31:0] ECDI;
	bit  [31:0] ECDO;
	bit   [3:0] ECDQM_N;
	bit         ECRD_WR_N;
	bit         ECCS3_N;
	bit         ECRD_N;
	bit         ECRFS;
	bit         ECWAIT_N;

	bit  [25:0] AA;
	bit  [15:0] ADI;
	bit  [15:0] ADO;
	bit   [1:0] AFC;
	bit         AAS_N;
	bit         ACS0_N;
	bit         ACS1_N;
	bit         ACS2_N;
	bit         AWAIT_N;
	bit         AIRQ_N;
	bit         ARD_N;
	bit         AWRL_N;
	bit         AWRU_N;
	bit         ATIM0_N;
	bit         ATIM1_N;
	bit         ATIM2_N;
	
	bit  [15:0] BDI;
	bit  [15:0] BDO;
	bit         BADDT_N;
	bit         BDTEN_N;
	bit         BREQ_N;
	bit         BCS1_N;
	bit         BRDY1_N;
	bit         IRQ1_N;
	bit         BCS2_N;
	bit         BRDY2_N;
	bit         IRQV_N;
	bit         IRQH_N;
	bit         BCSS_N;
	bit         BRDYS_N;
	bit         IRQS_N;
	
	bit         MIRQ_N;
	
	bit  [31:0] SCU_DO;
	
	//DCC
	bit         DRAMCE_N;
	bit         ROMCE_N;
	bit         SMPCCE_N;
	bit         SRAMCE_N;
	bit         MWR_N;
	bit   [1:0] BIRL;
	bit         MFTI;
	bit         SFTI;
	
	//SMPC
	bit   [7:0] SMPC_DO;
	bit         SYSRES_N;
	bit         SNDRES_N;
	bit         CDRES_N;
	bit         EXL_N;
	
	//VDP1
	bit  [15:0] VDP1_DO;
	
	//VDP2
	bit  [15:0] VDP2_DO;
	bit  [15:0] FBDI;
	bit  [15:0] FBDO;
	bit         HTIM_N;
	bit         VTIM_N;
	
	//SCSP
	bit  [15:0] SCSP_DO;
	
	//CD
	bit  [15:0] CD_DO;
	bit         ARQT_N;
	bit  [15:0] CD_SL;
	bit  [15:0] CD_SR;
	
	SH7604 #(.UBC_DISABLE(1), .SCI_DISABLE(1), .BUS_AREA_TIMIMG({RAMH_SLOW,3'b111}), .BUS_SIZE_BYTE_DISABLE(1)) MSH
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(SYS_CE_R),
		.CE_F(SYS_CE_F),
		.EN(EN),
		
		.RES_N(MSHRES_N),
		.NMI_N(MSHNMI_N),
		
		.IRL_N(MSHIRL_N),
		
		.A(MSHA),
		.DI(MSHDI),
		.DO(MSHDO),
		.BS_N(MSHBS_N),
		.CS0_N(MSHCS0_N),
		.CS1_N(MSHCS1_N),
		.CS2_N(MSHCS2_N),
		.CS3_N(MSHCS3_N),
		.RD_WR_N(MSHRD_WR_N),
		.WE_N(MSHDQM_N),
		.RD_N(MSHRD_N),
		.IVECF_N(MSHIVECF_N),
		.RFS(MSRFS),
		
		.EA(SSHA),
		.EDI(SSHDI),
		.EDO(SSHDO),
		.EBS_N(SSHBS_N),
		.ECS0_N(SSHCS0_N),
		.ECS1_N(SSHCS1_N),
		.ECS2_N(SSHCS2_N),
		.ECS3_N(SSHCS3_N),
		.ERD_WR_N(SSHRD_WR_N),
		.EWE_N(SSHDQM_N),
		.ERD_N(SSHRD_N),
		.ECE_N(1'b1),
		.EOE_N(1'b1),
		.EIVECF_N(1'b1),
		
		.WAIT_N(MSHWAIT_N),
		.IVECF_N(),
		.BRLS_N(MSHBRLS_N),
		.BGR_N(MSHBGR_N),
		
		.DREQ0(1'b1),
		.DREQ1(1'b1),
		
		.FTCI(1'b1),
		.FTI(MFTI),
		
		.RXD(1'b1),
		.TXD(),
		.SCKO(),
		.SCKI(1'b1),
		
		.MD(6'b001000),
		
		.FAST(FAST)
`ifdef DEBUG
		,
		.DBG_REGN('0),
		.DBG_REGQ(),
		.DBG_RUN(1),
		.DBG_BREAK()
`endif
	);
	
	SH7604 #(.UBC_DISABLE(1), .SCI_DISABLE(1), .BUS_AREA_TIMIMG({RAMH_SLOW,3'b111}), .BUS_SIZE_BYTE_DISABLE(1)) SSH
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(SYS_CE_R),
		.CE_F(SYS_CE_F),
		.EN(EN),
		
		.RES_N(SSHRES_N),
		.NMI_N(SSHNMI_N),
		
		.IRL_N(SSHIRL_N),
		
		.A(SSHA),
		.DI(SSHDI),
		.DO(SSHDO),
		.BS_N(SSHBS_N),
		.CS0_N(SSHCS0_N),
		.CS1_N(SSHCS1_N),
		.CS2_N(SSHCS2_N),
		.CS3_N(SSHCS3_N),
		.RD_WR_N(SSHRD_WR_N),
		.WE_N(SSHDQM_N),
		.RD_N(SSHRD_N),
		.IVECF_N(),
		
		.EA({2'b00,ECA}),
		.EDI(ECDI),
		.EDO(ECDO),
		.EBS_N(1'b1),
		.ECS0_N(1'b1),
		.ECS1_N(1'b1),
		.ECS2_N(1'b1),
		.ECS3_N(ECCS3_N),
		.ERD_WR_N(ECRD_WR_N),
		.EWE_N(ECDQM_N),
		.ERD_N(ECRD_N),
		.ECE_N(1'b1),
		.EOE_N(1'b1),
		.EIVECF_N(1'b1),
		
		.WAIT_N(SSHWAIT_N),
		.BRLS_N(SSHBACK_N),
		.BGR_N(SSHBREQ_N),
		
		.DREQ0(1'b1),
		.DREQ1(1'b1),
		
		.FTCI(1'b1),
		.FTI(SFTI),
		
		.RXD(1'b1),
		.TXD(),
		.SCKO(),
		.SCKI(1'b1),
		
		.MD(6'b101000),
		
		.FAST(FAST)
`ifdef DEBUG
		,
		.DBG_REGN('0),
		.DBG_REGQ(),
		.DBG_RUN(1),
		.DBG_BREAK()
`endif
	);
	
	assign MSHIRL_N  = CIRL_N;
	assign SSHIRL_N  = {1'b1,BIRL,1'b1};

	assign MSHDI     = CDO;
	assign MSHWAIT_N = CWAIT_N & (MEM_WAIT_N | (MSHCS3_N & DRAMCE_N & ROMCE_N & SRAMCE_N));
	assign SSHWAIT_N = CWAIT_N & (MEM_WAIT_N | (MSHCS3_N & DRAMCE_N & ROMCE_N & SRAMCE_N));
	
	assign CA       = MSHA[24:0];
	assign CDO      = !MSHCS3_N || !DRAMCE_N || !ROMCE_N || !SRAMCE_N ? MEM_DI :
`ifdef STV_BUILD
                     !STVIO_CS_N                                     ? MEM_DI :
`endif
                     !SMPCCE_N                                       ? {4{SMPC_DO}} :
							SCU_DO;
	assign CDI      = MSHDO;
	assign CBS_N    = MSHBS_N;
	assign CCS0_N   = MSHCS0_N;
	assign CCS1_N   = MSHCS1_N;
	assign CCS2_N   = MSHCS2_N;
	assign CCS3_N   = MSHCS3_N;
	assign CRD_WR_N = MSHRD_WR_N;
	assign CDQM_N   = MSHDQM_N;
	assign CRD_N    = MSHRD_N;
	assign CIVECF_N = MSHIVECF_N;
	assign ECWAIT_N = MEM_WAIT_N;
	
	
	
	assign ADI      = !ACS0_N || !ACS1_N ? CART_DO  : 
`ifndef STV_BUILD
	                  !ACS2_N            ? CD_DO    : 
`endif
							16'hFFFF;
`ifndef STV_BUILD
	assign AWAIT_N  = YGR019_AWAIT_N & CART_AWAIT_N;
`else
	assign AWAIT_N  = CART_AWAIT_N;
`endif
	assign AIRQ_N   = ARQT_N;
	
	assign BDI      = !BCS1_N ? VDP1_DO :
	                  !BCS2_N ? VDP2_DO :
							!BCSS_N ? SCSP_DO : 16'h0000;

	bit DBG_ABUS_END;
	SCU #(RAMH_SLOW) SCU
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(SYS_CE_R),
		.CE_F(SYS_CE_F),
		
		.RES_N(SYSRES_N),
		
		.CA(CA),
		.CDI(CDI),
		.CDO(SCU_DO),
		.CCS1_N(CCS1_N),
		.CCS2_N(CCS2_N),
		.CCS3_N(CCS3_N),
		.CRD_WR_N(CRD_WR_N),
		.CDQM_N(CDQM_N),
		.CRD_N(CRD_N),
		.CWAIT_N(CWATIN_N),
		.CIVECF_N(CIVECF_N),
		.CIRL_N(CIRL_N),
		.CBREQ_N(CBREQ_N),
		.CBACK_N(CBACK_N),
		
		.ECA(ECA),
		.ECDI(ECDI),
		.ECDO(ECDO),
		.ECDQM_N(ECDQM_N),
		.ECRD_WR_N(ECRD_WR_N),
		.ECCS3_N(ECCS3_N),
		.ECRD_N(ECRD_N),
		.ECRFS(ECRFS),
		.ECWAIT_N(ECWAIT_N),
		
		.AA(AA),
		.ADI(ADI),
		.ADO(ADO),
		.AFC(AFC),
		.AAS_N(AAS_N),
		.ACS0_N(ACS0_N),
		.ACS1_N(ACS1_N),
		.ACS2_N(ACS2_N),
		.AWAIT_N(AWAIT_N),
		.AIRQ_N(AIRQ_N),
		.ARD_N(ARD_N),
		.AWRL_N(AWRL_N),
		.AWRU_N(AWRU_N),
		.ATIM0_N(ATIM0_N),
		.ATIM1_N(ATIM1_N),
		.ATIM2_N(ATIM2_N),
		
		.BDI(BDI),
		.BDO(BDO),
		.BADDT_N(BADDT_N),
		.BDTEN_N(BDTEN_N),
		.BREQ_N(BREQ_N),
		.BCS1_N(BCS1_N),
		.BRDY1_N(BRDY1_N),
		.IRQ1_N(IRQ1_N),
		.BCS2_N(BCS2_N),
		.BRDY2_N(BRDY2_N),
		.IRQV_N(IRQV_N),
		.IRQH_N(IRQH_N),
		.IRQL_N(EXL_N),
		.BCSS_N(BCSS_N),
		.BRDYS_N(BRDYS_N),
		.IRQS_N(IRQS_N),
	
		.MIREQ_N(MIRQ_N),
		
		.FAST(FAST)
	);
	
	
	DCC DCC
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(SYS_CE_R),
		.CE_F(SYS_CE_F),
		
		.RES_N(SYSRES_N),
		
		.A(CA[24:1]),
		.BS_N(CBS_N),
		.CS0_N(CCS0_N),
		.CS1_N(CCS1_N),
		.CS2_N(CCS2_N),
		.RD_WR_N(CRD_WR_N),
		.WE_N(CDQM_N[1:0]),
		.RD_N(CRD_N),
		.WAIT_N(CWAIT_N),
		
		.BRLS_N(MSHBRLS_N),
		.BGR_N(MSHBGR_N),
		.BREQ_N(SSHBREQ_N),
		.BACK_N(SSHBACK_N),
		.EXBREQ_N(CBREQ_N),
		.EXBACK_N(CBACK_N),
		
		.WTIN_N(CWATIN_N),
		.IVECF_N(1'b1),
		
		.HINT_N(IRQH_N),
		.VINT_N(IRQV_N),
		.IREQ_N(BIRL),
		
		.MFTI(MFTI),
		.SFTI(SFTI),
		
		.DCE_N(DRAMCE_N),
		.DOE_N(),
		.DWE_N(),
		.DWAIT_N(MEM_WAIT_N),
		
		.ROMCE_N(ROMCE_N),
		.SRAMCE_N(SRAMCE_N),
		.SMPCCE_N(SMPCCE_N),
		.MOE_N(),
		.MWR_N(MWR_N),
		
		.FAST(FAST)
	);
	
	assign MEM_A     = CA[24:0];
	assign MEM_DO    = CDI;
	assign MEM_DQM_N = CDQM_N;
	assign MEM_RD_N  = CRD_N;
	assign ROM_CS_N  = ROMCE_N;
	assign SRAM_CS_N = SRAMCE_N;
	assign RAML_CS_N = DRAMCE_N;
	assign RAMH_CS_N = MSHCS3_N;
	assign RAMH_RFS = MSRFS | ECRFS;
`ifdef STV_BUILD
	assign STVIO_CS_N = ~(CA >= 25'h0400000 && CA <= 25'h040007F && ~CCS0_N);
`endif
	
	bit MRES_N;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			MRES_N <= 0;
		end else begin
			if (SMPC_CE) MRES_N <= 1;
		end
	end
	
	SMPC SMPC
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE(SMPC_CE),
		
		.MRES_N(MRES_N),
		.TIME_SET(TIME_SET),
		
		.RTC(RTC),
		
		.AC(SMPC_AREA),	
		
		.A(CA[6:1]),
		.DI(CDI[7:0]),
		.DO(SMPC_DO),
		.CS_N(SMPCCE_N),
		.RW_N(MWR_N),
		
		.SRES_N(SRES_N),
		
		.IRQV_N(IRQV_N),
		.EXL_N(EXL_N),
		
		.MSHRES_N(MSHRES_N),
		.MSHNMI_N(MSHNMI_N),
		.SSHRES_N(SSHRES_N),
		.SSHNMI_N(SSHNMI_N),
		.SYSRES_N(SYSRES_N),
		.SNDRES_N(SNDRES_N),
		.CDRES_N(CDRES_N),
		
		.MIRQ_N(MIRQ_N),
		.DOTSEL(SMPC_DOTSEL),
		
		.PDR1I(SMPC_PDR1I),
		.PDR1O(SMPC_PDR1O),
		.DDR1(SMPC_DDR1),
		.PDR2I(SMPC_PDR2I),
		.PDR2O(SMPC_PDR2O),
		.DDR2(SMPC_DDR2)
	);
	
	VDP1 VDP1
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(SYS_CE_R),
		.CE_F(SYS_CE_F),
		.EN(EN),
		
		.RES_N(SYSRES_N),
		
		.DI(BDO),
		.DO(VDP1_DO),
		.CS_N(BCS1_N),
		.AD_N(BADDT_N),
		.DTEN_N(BDTEN_N),
		.REQ_N(BREQ_N),
		.RDY_N(BRDY1_N),
		
		.IRQ_N(IRQ1_N), 
		
		.DCE_R(DCE_R),
		.DCE_F(DCE_F),
		.VTIM_N(VTIM_N),
		.HTIM_N(HTIM_N),
		.VOUTI(FBDO),
		.VOUTO(FBDI),
		
		.VRAM_A(VDP1_VRAM_A),
		.VRAM_D(VDP1_VRAM_D),
		.VRAM_WE(VDP1_VRAM_WE),
		.VRAM_RD(VDP1_VRAM_RD),
		.VRAM_BLEN(VDP1_VRAM_BLEN),
		.VRAM_Q(VDP1_VRAM_Q),
		.VRAM_RDY(VDP1_VRAM_RDY),
		
		.FB0_A(VDP1_FB0_A),
		.FB0_D(VDP1_FB0_D),
		.FB0_WE(VDP1_FB0_WE),
		.FB0_RD(VDP1_FB0_RD),
		.FB0_Q(VDP1_FB0_Q),
		
		.FB1_A(VDP1_FB1_A),
		.FB1_D(VDP1_FB1_D),
		.FB1_WE(VDP1_FB1_WE),
		.FB1_RD(VDP1_FB1_RD),
		.FB1_Q(VDP1_FB1_Q),
		.FB_RDY(VDP1_FB_RDY),
		.FB_MODE3(VDP1_FB_MODE3),
		
		.FAST(FAST),
		
		.DBG_EXT(DBG_EXT)
		
`ifdef DEBUG
		,
		.DBG_START(VDP1_START),
		.DBG_CMD_END(VDP1_CMD_END)
`endif
	);
	
	VDP2 VDP2
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(SYS_CE_R),
		.CE_F(SYS_CE_F),
		
		.RES_N(SYSRES_N),
		
		.DI(BDO),
		.DO(VDP2_DO),
		.CS_N(BCS2_N),
		.AD_N(BADDT_N),
		.DTEN_N(BDTEN_N),
		.REQ_N(BREQ_N),
		.RDY_N(BRDY2_N),
		
		.VINT_N(IRQV_N),
		.HINT_N(IRQH_N),
		
		.DCE_R(DCE_R),
		.DCE_F(DCE_F),
		.HTIM_N(HTIM_N),
		.VTIM_N(VTIM_N),
		.FBDI(FBDI),
		.FBDO(FBDO),
		
		.PAL(PAL),
		
		.EXLAT_N(EXL_N),
		
		.RA0_A(VDP2_RA0_A),
		.RA1_A(VDP2_RA1_A),
		.RA_D(VDP2_RA_D),
		.RA_WE(VDP2_RA_WE),
		.RA_RD(VDP2_RA_RD),
		.RA0_Q(VDP2_RA0_Q),
		.RA1_Q(VDP2_RA1_Q),
		
		.RB0_A(VDP2_RB0_A),
		.RB1_A(VDP2_RB1_A),
		.RB_D(VDP2_RB_D),
		.RB_WE(VDP2_RB_WE),
		.RB_RD(VDP2_RB_RD),
		.RB0_Q(VDP2_RB0_Q),
		.RB1_Q(VDP2_RB1_Q),
		
		.R(R),
		.G(G),
		.B(B),
		.DCLK(DCLK),
		.VS_N(VS_N),
		.HS_N(HS_N),
		.HBL_N(HBL_N),
		.VBL_N(VBL_N),
	
		.FIELD(FIELD),
		.INTERLACE(INTERLACE),
		.HRES(HRES),
		.VRES(VRES),
		
		.SCRN_EN(SCRN_EN),
		
		.DBG_EXT(DBG_EXT)
	);
	
	
	bit STV_SCSP_RES_N,STV_SCPU_RES_N;
	always @(posedge CLK) begin	
		if (SYS_CE_R) begin
			STV_SCSP_RES_N <= ~(SMPC_PDR2O[3] | ~SMPC_DDR2[3]);
			STV_SCPU_RES_N <= ~(SMPC_PDR2O[4] | ~SMPC_DDR2[4]);
		end
	end
	
	bit         SCCE_R;
	bit         SCCE_F;
	bit  [23:1] SCA;
	bit  [15:0] SCDI;
	bit  [15:0] SCDO;
	bit         SCRW_N;
	bit         SCAS_N;
	bit         SCLDS_N;
	bit         SCUDS_N;
	bit         SCDTACK_N;
	bit   [2:0] SCFC;
	bit         SCAVEC_N;
	bit   [2:0] SCIPL_N;
	
	wire SCSP_RES_N = CART_MODE == 3'h5 ? STV_SCSP_RES_N : SYSRES_N;
	SCSP SCSP
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE(SCSP_CE),
		
		.RES_N(SCSP_RES_N),
		
		.CE_R(SYS_CE_R),
		.CE_F(SYS_CE_F),
		.DI(BDO),
		.DO(SCSP_DO),
		.CS_N(BCSS_N),
		.AD_N(BADDT_N),
		.DTEN_N(BDTEN_N),
		.REQ_N(BREQ_N),
		.RDY_N(BRDYS_N),
		.INT_N(IRQS_N),
		
		.SCCE_R(SCCE_R),
		.SCCE_F(SCCE_F),
		.SCA(SCA),
		.SCDI(SCDI),
		.SCDO(SCDO),
		.SCRW_N(SCRW_N),
		.SCAS_N(SCAS_N),
		.SCLDS_N(SCLDS_N),
		.SCUDS_N(SCUDS_N),
		.SCDTACK_N(SCDTACK_N),
		.SCFC(SCFC),
		.SCAVEC_N(SCAVEC_N),
		.SCIPL_N(SCIPL_N),
		
		.RAM_A(SCSP_RAM_A),
		.RAM_D(SCSP_RAM_D),
		.RAM_WE(SCSP_RAM_WE),
		.RAM_RD(SCSP_RAM_RD),
		.RAM_CS(SCSP_RAM_CS),
		.RAM_Q(SCSP_RAM_Q),
		.RAM_RFS(SCSP_RAM_RFS),
		.RAM_RDY(SCSP_RAM_RDY),
		
		.ESL(CD_SL),
		.ESR(CD_SR),
		
		.SOUND_L(SOUND_L),
		.SOUND_R(SOUND_R),
		
`ifdef STV_BUILD
		.STV_SW(STV_SW),
`endif
		
		.SND_EN(SND_EN)
		
`ifdef DEBUG
		,
		.SLOT_EN(SLOT_EN)
`endif
	);
	
	wire SCPU_RES_N = CART_MODE == 3'h5 ? STV_SCPU_RES_N : SNDRES_N;
	bit M68K_RESO_N;
	fx68k M68K
	(
		.clk(CLK),
		.extReset(~SCPU_RES_N | ~M68K_RESO_N),
		.pwrUp(~RST_N),
		.enPhi1(SCCE_R),
		.enPhi2(SCCE_F),

		.eab(SCA),
		.iEdb(SCDO),
		.oEdb(SCDI),
		.eRWn(SCRW_N),
		.ASn(SCAS_N),
		.LDSn(SCLDS_N),
		.UDSn(SCUDS_N),
		.DTACKn(SCDTACK_N),

		.IPL0n(SCIPL_N[0]),
		.IPL1n(SCIPL_N[1]),
		.IPL2n(SCIPL_N[2]),

		.VPAn(SCAVEC_N),
		
		.FC0(SCFC[0]),
		.FC1(SCFC[1]),
		.FC2(SCFC[2]),

		.BGn(),
		.BRn(1),
		.BGACKn(1),

		.BERRn(1),
		.HALTn(1),
		
		.oRESETn(M68K_RESO_N)
	);

	
	
	//CD
`ifndef STV_BUILD
	bit [21:0] SA;
	bit [15:0] SDI;
	bit [15:0] SDO;
	bit        SWRL_N;
	bit        SWRH_N;
	bit        SRD_N;
	bit        SCS1_N;
	bit        SCS2_N;
	bit        SCS6_N;
	bit        SWAIT_N;
	bit        DACK0;
	bit        DACK1;
	bit        DREQ0_N;
	bit        DREQ1_N;
	bit        SIRQL_N;
	bit        SIRQH_N;
	
	bit [15:0] YGR019_SDO;
	
	bit SHCLK;
	bit SHCE_R, SHCE_F;
	always @(posedge CLK) begin
		if (CD_CE) SHCLK <= ~SHCLK;
	end
	assign SHCE_R =  SHCLK & CD_CE;
	assign SHCE_F = ~SHCLK & CD_CE;
	
	SH1 #("rtl/cdb105m.mif") sh1
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(SHCE_R),
		.CE_F(SHCE_F),
		.EN(EN),
		
		.RES_N(CDRES_N),
		
		.A(SA),
		.DI(SDI),
		.DO(SDO),
		
		.CS1N_CASHN(SCS1_N),//in original CASH_N
		.CS2N(SCS2_N),
		.CS6N(SCS6_N),
		.WRLN(SWRL_N),
		.WRHN(SWRH_N),
		.RDN(SRD_N),
		.WAITN(SWAIT_N),
		
		.IRQ6N(SIRQL_N),
		.IRQ7N(SIRQH_N),
		
		.DACK0(DACK0),
		.DACK1(DACK1),
		.DREQ0N(DREQ0_N),
		.DREQ1N(DREQ1_N),
		
		.RXD0(CD_CDATA),
		.TXD0(CD_HDATA),
		.SCK0O(CD_COMCLK),
		.PB2I(CD_COMSYNC_N),
		.TIOCB3(CD_COMREQ_N),
		.PB6O(CD_DEMP),
		
		.TIOCA0(1'b0),//MPEG
		.TIOCA1(1'b0),//MPEG
		.TIOCA2(1'b1),//MPEGA_IRQ_N
		.TIOCB2(1'b1)//MPEGV_IRQ_N
	);
	
	assign SDI = !SCS1_N ? CD_RAM_Q : YGR019_SDO;
	
	bit YGR019_AWAIT_N;
	bit [15:0] DBG_SEC_SUM;
	bit DBG_SEC_END;
	YGR019 ygr 
	(
		.CLK(CLK),
		.RST_N(RST_N),
		
		.RES_N(CDRES_N),
		
		.CE_R(SYS_CE_R),
		.CE_F(SYS_CE_F),
		.AA(AA[14:1]),
		.ADI(ADO),
		.ADO(CD_DO),
		.AFC(AFC),
		.ACS2_N(ACS2_N),
		.ARD_N(ARD_N),
		.AWRL_N(AWRL_N),
		.AWRU_N(AWRU_N),
		.ATIM0_N(ATIM0_N),
		.ATIM2_N(ATIM2_N),
		.AWAIT_N(YGR019_AWAIT_N),
		.ARQT_N(ARQT_N),
		
		.SHCE_R(SHCE_R),
		.SHCE_F(SHCE_F),
		.SA(SA[21:1]),
		.SDI(SDO),
		.SDO(YGR019_SDO),
		.BDI(CD_RAM_Q),
		.SWRL_N(SWRL_N),
		.SWRH_N(SWRH_N),
		.SRD_N(SRD_N),
		.SCS2_N(SCS2_N),
		.SCS6_N(SCS6_N),
		.SIRQL_N(SIRQL_N),
		.SIRQH_N(SIRQH_N),
		
		.DACK0(DACK0),
		.DACK1(DACK1),
		.DREQ0_N(DREQ0_N),
		.DREQ1_N(DREQ1_N),
		
		.CD_D(CD_D),
		.CD_CK(CD_CK),
		.CD_AUDIO(CD_AUDIO),
		
		.CD_SL(CD_SL),
		.CD_SR(CD_SR),
		
		.FAST(FAST)
	);
	
	assign SWAIT_N = CD_RAM_RDY;
	
	assign CD_RAM_A = SA[18:1];
	assign CD_RAM_D = !DACK0 || !DACK1 ? YGR019_SDO : SDO;
	assign CD_RAM_CS = ~SCS1_N;
	assign CD_RAM_WE = ~{SWRH_N,SWRL_N};
	assign CD_RAM_RD = ~SRD_N;
`else
	assign {CD_SL,CD_SR} = '0;
`endif
	
	
	bit  [15: 0] CART_DO;
	bit          CART_AWAIT_N;
	CART cart 
	(
		.CLK(CLK),
		.RST_N(RST_N),
		
		.MODE(CART_MODE),
		
		.RES_N(SYSRES_N),
		
		.CE_R(SYS_CE_R),
		.CE_F(SYS_CE_F),
		.AA(AA),
		.ADI(ADO),
		.ADO(CART_DO),
		.AFC(AFC),
		.ACS0_N(ACS0_N),
		.ACS1_N(ACS1_N),
		.ACS2_N(ACS2_N),
		.ARD_N(ARD_N),
		.AWRL_N(AWRL_N),
		.AWRU_N(AWRU_N),
		.ATIM0_N(ATIM0_N),
		.ATIM2_N(ATIM2_N),
		.AWAIT_N(CART_AWAIT_N),
		.ARQT_N(),
		
		.MEM_A(CART_MEM_A),
		.MEM_DO(CART_MEM_D),
		.MEM_DI(CART_MEM_Q),
		.MEM_WE(CART_MEM_WE),
		.MEM_RD(CART_MEM_RD),
		.MEM_RDY(CART_MEM_RDY)
	);
	
endmodule

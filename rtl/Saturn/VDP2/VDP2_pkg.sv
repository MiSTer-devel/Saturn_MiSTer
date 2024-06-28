package VDP2_PKG;

	typedef struct packed	//RW,180000
	{
		bit         DISP;
		bit [ 5: 0] UNUSED;
		bit         BDCLMD;
		bit [ 1: 0] LSMD;
		bit [ 1: 0] VRESO;
		bit         UNUSED2;
		bit [ 2: 0] HRESO;
	} TVMD_t;
	parameter bit [15:0] TVMD_MASK = 16'h81F7;
	
	typedef struct packed	//RW,180002
	{
		bit [ 5: 0] UNUSED;
		bit         EXLTEN;
		bit         EXSYEN;
		bit [ 5: 0] UNUSED2;
		bit         DASEL;
		bit         EXBGEN;
	} EXTEN_t;
	parameter bit [15:0] EXTEN_MASK = 16'h0303;

	typedef struct packed	//RO,180004
	{
		bit [ 5: 0] UNUSED;
		bit         EXLTFG;
		bit         EXSYFG;
		bit [ 3: 0] UNUSED2;
		bit         VBLANK;
		bit         HBLANK;
		bit         ODD;
		bit         PAL;
	} TVSTAT_t;
	parameter bit [15:0] TVSTAT_MASK = 16'h030F;
	
	typedef struct packed	//RW,180006
	{
		bit         VRAMSZ;	//RW
		bit [10: 0] UNUSED;
		bit [ 3: 0] VER;		//RO
	} VRSIZE_t;
	parameter bit [15:0] VRSIZE_MASK = 16'h8000;
	
	typedef struct packed	//RO,180008
	{
		bit [ 5: 0] UNUSED;
		bit [ 9: 0] HCT;
	} HCNT_t;
	parameter bit [15:0] HCNT_MASK = 16'h03FF;
	
	typedef struct packed	//RO,18000A
	{
		bit [ 5: 0] UNUSED;
		bit [ 9: 0] VCT;
	} VCNT_t;
	parameter bit [15:0] VCNT_MASK = 16'h03FF;
	
	typedef struct packed	//RW,18000E
	{
		bit         CRKTE;
		bit         UNUSED;
		bit [ 1: 0] CRMD;
		bit [ 1: 0] UNUSED2;
		bit         VRBMD;
		bit         VRAMD;
		bit [ 1: 0] RDBSB1;
		bit [ 1: 0] RDBSB0;
		bit [ 1: 0] RDBSA1;
		bit [ 1: 0] RDBSA0;
	} RAMCTL_t;
	parameter bit [15:0] RAMCTL_MASK = 16'hB3FF;
	
	typedef struct packed	//RW,180010,180018
	{
		bit [ 3: 0] VCP0x0;
		bit [ 3: 0] VCP1x0;
		bit [ 3: 0] VCP2x0;
		bit [ 3: 0] VCP3x0;
	} CYCx0L_t;
	parameter bit [15:0] CYCx0L_MASK = 16'hFFFF;
	
	typedef struct packed	//RW,180012,18001A
	{
		bit [ 3: 0] VCP4x0;
		bit [ 3: 0] VCP5x0;
		bit [ 3: 0] VCP6x0;
		bit [ 3: 0] VCP7x0;
	} CYCx0U_t;
	parameter bit [15:0] CYCx0U_MASK = 16'hFFFF;
	
	typedef struct packed	//RW,180014,18001C
	{
		bit [ 3: 0] VCP0x1;
		bit [ 3: 0] VCP1x1;
		bit [ 3: 0] VCP2x1;
		bit [ 3: 0] VCP3x1;
	} CYCx1L_t;
	parameter bit [15:0] CYCx1L_MASK = 16'hFFFF;
	
	typedef struct packed	//RW,180016,18001E
	{
		bit [ 3: 0] VCP4x1;
		bit [ 3: 0] VCP5x1;
		bit [ 3: 0] VCP6x1;
		bit [ 3: 0] VCP7x1;
	} CYCx1U_t;
	parameter bit [15:0] CYCx1U_MASK = 16'hFFFF;
	
	typedef struct packed	//RW,180020
	{
		bit [ 2: 0] UNUSED;
		bit         R0TPON;
		bit         N3TPON;
		bit         N2TPON;
		bit         N1TPON;
		bit         N0TPON;
		bit [ 1: 0] UNUSED2;
		bit         R1ON;
		bit         R0ON;
		bit         N3ON;
		bit         N2ON;
		bit         N1ON;
		bit         N0ON;
	} BGON_t;
	parameter bit [15:0] BGON_MASK = 16'h1F3F;
	
	typedef struct packed	//RW,180022
	{
		bit [ 3: 0] MZSZV;
		bit [ 3: 0] MZSZH;
		bit [ 2: 0] UNUSED;
		bit         R0MZE;
		bit         N3MZE;
		bit         N2MZE;
		bit         N1MZE;
		bit         N0MZE;
	} MZCTL_t;
	parameter bit [15:0] MZCTL_MASK = 16'hFF1F;
	
	typedef struct packed	//RW,180024
	{
		bit [10: 0] UNUSED;
		bit         R0SFCS;
		bit         N3SFCS;
		bit         N2SFCS;
		bit         N1SFCS;
		bit         N0SFCS;
	} SFSEL_t;
	parameter bit [15:0] SFSEL_MASK = 16'h001F;
	
	typedef struct packed	//RW,180026
	{
		bit [ 7: 0] SFCDB;
		bit [ 7: 0] SFCDA;
	} SFCODE_t;
	parameter bit [15:0] SFCODE_MASK = 16'hFFFF;
	
	typedef struct packed	//RW,180028
	{
		bit [ 1: 0] UNUSED;
		bit [ 1: 0] N1CHCN;
		bit [ 1: 0] N1BMSZ;
		bit         N1BMEN;
		bit         N1CHSZ;
		bit         UNUSED2;
		bit [ 2: 0] N0CHCN;
		bit [ 1: 0] N0BMSZ;
		bit         N0BMEN;
		bit         N0CHSZ;
	} CHCTLA_t;
	parameter bit [15:0] CHCTLA_MASK = 16'h3F7F;
	
	typedef struct packed	//RW,18002A
	{
		bit         UNUSED;
		bit [ 2: 0] R0CHCN;
		bit         UNUSED2;
		bit         R0BMSZ;
		bit         R0BMEN;
		bit         R0CHSZ;
		bit [ 1: 0] UNUSED3;
		bit         N3CHCN;
		bit         N3CHSZ;
		bit [ 1: 0] UNUSED4;
		bit         N2CHCN;
		bit         N2CHSZ;
	} CHCTLB_t;
	parameter bit [15:0] CHCTLB_MASK = 16'h7733;
	
	typedef struct packed	//RW,18002C
	{
		bit [ 1: 0] UNUSED;
		bit         N1BMPR;
		bit         N1BMCC;
		bit         UNUSED2;
		bit [ 6: 4] N1BMP;
		bit [ 1: 0] UNUSED3;
		bit         N0BMPR;
		bit         N0BMCC;
		bit         UNUSED4;
		bit [ 6: 4] N0BMP;
	} BMPNA_t;
	parameter bit [15:0] BMPNA_MASK = 16'h3737;
	
	typedef struct packed	//RW,18002E
	{
		bit [ 9: 0] UNUSED;
		bit         R0BMPR;
		bit         R0BMCC;
		bit         UNUSED2;
		bit [ 6: 4] R0BMP;
	} BMPNB_t;
	parameter bit [15:0] BMPNB_MASK = 16'h0037;
	
	typedef struct packed	//RW,180030,180032,180034,180036
	{
		bit         NxPNB;
		bit         NxCNSM;
		bit [ 3: 0] UNUSED;
		bit         NxSPR;
		bit         NxSCC;
		bit [ 6: 4] NxSPLT;
		bit [ 4: 0] NxSCN;
	} PNCNx_t;
	parameter bit [15:0] PNCNx_MASK = 16'hC3FF;
	
	typedef struct packed	//RW,180038
	{
		bit         R0PNB;
		bit         R0CNSM;
		bit [ 3: 0] UNUSED;
		bit         R0SPR;
		bit         R0SCC;
		bit [ 6: 4] R0SPLT;
		bit [ 4: 0] R0SCN;
	} PNCR_t;
	parameter bit [15:0] PNCR_MASK = 16'hC3FF;
	
	typedef struct packed	//RW,18003A
	{
		bit [ 1: 0] RBOVR;
		bit [ 1: 0] RBPLSZ;
		bit [ 1: 0] RAOVR;
		bit [ 1: 0] RAPLSZ;
		bit [ 1: 0] N3PLSZ;
		bit [ 1: 0] N2PLSZ;
		bit [ 1: 0] N1PLSZ;
		bit [ 1: 0] N0PLSZ;
	} PLSZ_t;
	parameter bit [15:0] PLSZ_MASK = 16'hFFFF;
	
	typedef struct packed	//RW,18003C
	{
		bit         UNUSED;
		bit [ 8: 6] N3MP;
		bit         UNUSED2;
		bit [ 8: 6] N2MP;
		bit         UNUSED3;
		bit [ 8: 6] N1MP;
		bit         UNUSED4;
		bit [ 8: 6] N0MP;
	} MPOFN_t;
	parameter bit [15:0] MPOFN_MASK = 16'h7777;
	
	typedef struct packed	//RW,18003E
	{
		bit [ 8: 0] UNUSED;
		bit [ 8: 6] RBMP;
		bit         UNUSED2;
		bit [ 8: 6] RAMP;
	} MPOFR_t;
	parameter bit [15:0] MPOFR_MASK = 16'h0077;
	
	typedef struct packed	//RW,180040,180044,180048,18004C
	{
		bit [ 1: 0] UNUSED;
		bit [ 5: 0] NxMPB;
		bit [ 1: 0] UNUSED2;
		bit [ 5: 0] NxMPA;
	} MPABNx_t;
	parameter bit [15:0] MPABNx_MASK = 16'h3F3F;
	
	typedef struct packed	//RW,180042,180046,18004A,18004E
	{
		bit [ 1: 0] UNUSED;
		bit [ 5: 0] NxMPD;
		bit [ 1: 0] UNUSED2;
		bit [ 5: 0] NxMPC;
	} MPCDNx_t;
	parameter bit [15:0] MPCDNx_MASK = 16'h3F3F;
	
	typedef struct packed	//RW,180050,180060
	{
		bit [ 1: 0] UNUSED;
		bit [ 5: 0] RxMPB;
		bit [ 1: 0] UNUSED2;
		bit [ 5: 0] RxMPA;
	} MPABRx_t;
	parameter bit [15:0] MPABRx_MASK = 16'h3F3F;
	
	typedef struct packed	//RW,180052,180062
	{
		bit [ 1: 0] UNUSED;
		bit [ 5: 0] RxMPD;
		bit [ 1: 0] UNUSED2;
		bit [ 5: 0] RxMPC;
	} MPCDRx_t;
	parameter bit [15:0] MPCDRx_MASK = 16'h3F3F;
	
	typedef struct packed	//RW,180054,180064
	{
		bit [ 1: 0] UNUSED;
		bit [ 5: 0] RxMPF;
		bit [ 1: 0] UNUSED2;
		bit [ 5: 0] RxMPE;
	} MPEFRx_t;
	parameter bit [15:0] MPEFRx_MASK = 16'h3F3F;
	
	typedef struct packed	//RW,180056,180066
	{
		bit [ 1: 0] UNUSED;
		bit [ 5: 0] RxMPH;
		bit [ 1: 0] UNUSED2;
		bit [ 5: 0] RxMPG;
	} MPGHRx_t;
	parameter bit [15:0] MPGHRx_MASK = 16'h3F3F;
	
	typedef struct packed	//RW,180058,180068
	{
		bit [ 1: 0] UNUSED;
		bit [ 5: 0] RxMPJ;
		bit [ 1: 0] UNUSED2;
		bit [ 5: 0] RxMPI;
	} MPIJRx_t;
	parameter bit [15:0] MPIJRx_MASK = 16'h3F3F;
	
	typedef struct packed	//RW,18005A,18006A
	{
		bit [ 1: 0] UNUSED;
		bit [ 5: 0] RxMPL;
		bit [ 1: 0] UNUSED2;
		bit [ 5: 0] RxMPK;
	} MPKLRx_t;
	parameter bit [15:0] MPKLRx_MASK = 16'h3F3F;
	
	typedef struct packed	//RW,18005C,18006C
	{
		bit  [1:0] UNUSED;
		bit  [5:0] RxMPN;
		bit  [1:0] UNUSED2;
		bit  [5:0] RxMPM;
	} MPMNRx_t;
	parameter bit [15:0] MPMNRx_MASK = 16'h3F3F;
	
	typedef struct packed	//RW,18005E,18006E
	{
		bit [ 1: 0] UNUSED;
		bit [ 5: 0] RxMPP;
		bit [ 1: 0] UNUSED2;
		bit [ 5: 0] RxMPO;
	} MPOPRx_t;
	parameter bit [15:0] MPOPRx_MASK = 16'h3F3F;
	
	typedef struct packed	//RW,180070,180080
	{
		bit [ 4: 0] UNUSED;
		bit [10: 0] NxSCXI;
	} SCXINx_t;
	parameter bit [15:0] SCXINx_MASK = 16'h07FF;
	
	typedef struct packed	//RW,180072,180082
	{
		bit [ 7: 0] NxSCXD;
		bit [ 7: 0] UNUSED;
	} SCXDNx_t;
	parameter bit [15:0] SCXDNx_MASK = 16'hFF00;
	
	typedef struct packed	//RW,180074,180084
	{
		bit [ 4: 0] UNUSED;
		bit [10: 0] NxSCYI;
	} SCYINx_t;
	parameter bit [15:0] SCYINx_MASK = 16'h07FF;
	
	typedef struct packed	//RW,180076,180086
	{
		bit [ 7: 0] NxSCYD;
		bit [ 7: 0] UNUSED;
	} SCYDNx_t;
	parameter bit [15:0] SCYDNx_MASK = 16'hFF00;
	
	typedef struct packed	//RW,180078,180088
	{
		bit [12: 0] UNUSED;
		bit [ 2: 0] NxZMXI;
	} ZMXINx_t;
	parameter bit [15:0] ZMXINx_MASK = 16'h0007;
	
	typedef struct packed	//RW,18007A,18008A
	{
		bit [ 7: 0] NxZMXD;
		bit [ 7: 0] UNUSED;
	} ZMXDNx_t;
	parameter bit [15:0] ZMXDNx_MASK = 16'hFF00;
	
	typedef struct packed	//RW,18007C,18008C
	{
		bit [12: 0] UNUSED;
		bit [ 2: 0] NxZMYI;
	} ZMYINx_t;
	parameter bit [15:0] ZMYINx_MASK = 16'h0007;
	
	typedef struct packed	//RW,18007E,18008E
	{
		bit [ 7: 0] NxZMYD;
		bit [ 7: 0] UNUSED;
	} ZMYDNx_t;
	parameter bit [15:0] ZMYDNx_MASK = 16'hFF00;
	
	typedef struct packed	//RW,180090,180094
	{
		bit [ 4: 0] UNUSED;
		bit [10: 0] NxSCX;
	} SCXNx_t;
	parameter bit [15:0] SCXNx_MASK = 16'h07FF;
	
	typedef struct packed	//RW,180092,180096
	{
		bit [ 4: 0] UNUSED;
		bit [10: 0] NxSCY;
	} SCYNx_t;
	parameter bit [15:0] SCYNx_MASK = 16'h07FF;
	
	typedef struct packed	//RW,180098
	{
		bit [ 5: 0] UNUSED;
		bit         N1ZMQT;
		bit         N1ZMHF;
		bit [ 5: 0] UNUSED2;
		bit         N0ZMQT;
		bit         N0ZMHF;
	} ZMCTL_t;
	parameter bit [15:0] ZMCTL_MASK = 16'h0303;
	
	typedef struct packed	//RW,18009A
	{
		bit [ 1: 0] UNUSED;
		bit [ 1: 0] N1LSS;
		bit         N1LZMX;
		bit         N1LSCY;
		bit         N1LSCX;
		bit         N1VCSC;
		bit [ 1: 0] UNUSED2;
		bit [ 1: 0] N0LSS;
		bit         N0LZMX;
		bit         N0LSCY;
		bit         N0LSCX;
		bit         N0VCSC;
	} SCRCTL_t;
	parameter bit [15:0] SCRCTL_MASK = 16'h3F3F;
	
	typedef struct packed	//RW,18009C
	{
		bit [12: 0] UNUSED;
		bit [18:16] VCSTA;
	} VCSTAU_t;
	parameter bit [15:0] VCSTAU_MASK = 16'h0007;
	
	typedef struct packed	//RW,18009E
	{
		bit [15: 1] VCSTA;
		bit         UNUSED;
	} VCSTAL_t;
	parameter bit [15:0] VCSTAL_MASK = 16'hFFFE;
	
	typedef struct packed	//RW,1800A0,1800A4
	{
		bit [12: 0] UNUSED;
		bit [18:16] LSTA;
	} LSTAxU_t;
	parameter bit [15:0] LSTAxU_MASK = 16'h0007;
	
	typedef struct packed	//RW,1800A2,1800A6
	{
		bit [15: 1] LSTA;
		bit         UNUSED;
	} LSTAxL_t;
	parameter bit [15:0] LSTAxL_MASK = 16'hFFFE;
	
	typedef struct packed	//RW,1800A8
	{
		bit         LCCLMD;
		bit [11: 0] UNUSED;
		bit [18:16] LCTA;
	} LCTAU_t;
	parameter bit [15:0] LCTAU_MASK = 16'h8007;
	
	typedef struct packed	//RW,1800AA
	{
		bit [15: 0] LCTA;
	} LCTAL_t;
	parameter bit [15:0] LCTAL_MASK = 16'hFFFF;
	
	typedef struct packed	//RW,1800AC
	{
		bit         BKCLMD;
		bit [11: 0] UNUSED;
		bit [18:16] BKTA;
	} BKTAU_t;
	parameter bit [15:0] BKTAU_MASK = 16'h8007;
	
	typedef struct packed	//RW,1800AE
	{
		bit [15: 0] BKTA;
	} BKTAL_t;
	parameter bit [15:0] BKTAL_MASK = 16'hFFFF;
	
	typedef struct packed	//RW,1800B0
	{
		bit [13: 0] UNUSED;
		bit [ 1: 0] RPMD;
	} RPMD_t;
	parameter bit [15:0] RPMD_MASK = 16'h0003;
	
	typedef struct packed	//RW,1800B2
	{
		bit [ 4: 0] UNUSED;
		bit         RBKASTRE;
		bit         RBYSTRE;
		bit         RBXSTRE;
		bit [ 4: 0] UNUSED2;
		bit         RAKASTRE;
		bit         RAYSTRE;
		bit         RAXSTRE;
	} RPRCTL_t;
	parameter bit [15:0] RPRCTL_MASK = 16'h0707;
	
	typedef struct packed	//RW,1800B4
	{
		bit [ 2: 0] UNUSED;
		bit         RBKLCE;
		bit [ 1: 0] RBKMD;
		bit         RBKDBS;
		bit         RBKTE;
		bit [ 2: 0] UNUSED2;
		bit         RAKLCE;
		bit [ 1: 0] RAKMD;
		bit         RAKDBS;
		bit         RAKTE;
	} KTCTL_t;
	parameter bit [15:0] KTCTL_MASK = 16'h1F1F;
	
	typedef struct packed	//RW,1800B6
	{
		bit [ 4: 0] UNUSED;
		bit [ 2: 0] RBKTAOS;
		bit [ 4: 0] UNUSED2;
		bit [ 2: 0] RAKTAOS;
	} KTAOF_t;
	parameter bit [15:0] KTAOF_MASK = 16'h0707;
	
	typedef struct packed	//RW,1800B8,1800BA
	{
		bit [15: 0] RxOPN;
	} OVPNRx_t;
	parameter bit [15:0] OVPNRx_MASK = 16'hFFFF;
	
	typedef struct packed	//RW,1800BC
	{
		bit [12: 0] UNUSED;
		bit [18:16] RPTA;
	} RPTAU_t;
	parameter bit [15:0] RPTAU_MASK = 16'h0007;
	
	typedef struct packed	//RW,1800BE
	{
		bit [15: 1] RPTA;
		bit         UNUSED;
	} RPTAL_t;
	parameter bit [15:0] RPTAL_MASK = 16'hFFFE;
	
	typedef struct packed	//RW,1800C0,1800C8
	{
		bit [ 5: 0] UNUSED;
		bit [ 9: 0] WxSX;
	} WPSXx_t;
	parameter bit [15:0] WPSXx_MASK = 16'h03FF;
	
	typedef struct packed	//RW,1800C2,1800CA
	{
		bit [ 6: 0] UNUSED;
		bit [ 8: 0] WxSY;
	} WPSYx_t;
	parameter bit [15:0] WPSYx_MASK = 16'h01FF;
	
	typedef struct packed	//RW,1800C4,1800CC
	{
		bit [ 5: 0] UNUSED;
		bit [ 9: 0] WxEX;
	} WPEXx_t;
	parameter bit [15:0] WPEXx_MASK = 16'h03FF;
	
	typedef struct packed	//RW,1800C6,1800CE
	{
		bit [ 6: 0] UNUSED;
		bit [ 8: 0] WxEY;
	} WPEYx_t;
	parameter bit [15:0] WPEYx_MASK = 16'h01FF;
	
	typedef struct packed	//RW,1800D0
	{
		bit         N1LOG;
		bit         UNUSED;
		bit         N1SWE;
		bit         N1SWA;
		bit         N1W1E;
		bit         N1W1A;
		bit         N1W0E;
		bit         N1W0A;
		bit         N0LOG;
		bit         UNUSED2;
		bit         N0SWE;
		bit         N0SWA;
		bit         N0W1E;
		bit         N0W1A;
		bit         N0W0E;
		bit         N0W0A;
	} WCTLA_t;
	parameter bit [15:0] WCTLA_MASK = 16'hBFBF;
	
	typedef struct packed	//RW,1800D2
	{
		bit         N3LOG;
		bit         UNUSED;
		bit         N3SWE;
		bit         N3SWA;
		bit         N3W1E;
		bit         N3W1A;
		bit         N3W0E;
		bit         N3W0A;
		bit         N2LOG;
		bit         UNUSED2;
		bit         N2SWE;
		bit         N2SWA;
		bit         N2W1E;
		bit         N2W1A;
		bit         N2W0E;
		bit         N2W0A;
	} WCTLB_t;
	parameter bit [15:0] WCTLB_MASK = 16'hBFBF;
	
	typedef struct packed	//RW,1800D4
	{
		bit         SPLOG;
		bit         UNUSED;
		bit         SPSWE;
		bit         SPSWA;
		bit         SPW1E;
		bit         SPW1A;
		bit         SPW0E;
		bit         SPW0A;
		bit         R0LOG;
		bit         UNUSED2;
		bit         R0SWE;
		bit         R0SWA;
		bit         R0W1E;
		bit         R0W1A;
		bit         R0W0E;
		bit         R0W0A;
	} WCTLC_t;
	parameter bit [15:0] WCTLC_MASK = 16'hBFBF;
	
	typedef struct packed	//RW,1800D6
	{
		bit         CCLOG;
		bit         UNUSED;
		bit         CCSWE;
		bit         CCSWA;
		bit         CCW1E;
		bit         CCW1A;
		bit         CCW0E;
		bit         CCW0A;
		bit         RPLOG;
		bit [ 2: 0] UNUSED2;
		bit         RPW1E;
		bit         RPW1A;
		bit         RPW0E;
		bit         RPW0A;
	} WCTLD_t;
	parameter bit [15:0] WCTLD_MASK = 16'hBF8F;
	
	typedef struct packed	//RW,1800D8,1800DC
	{
		bit         WxLWE;
		bit [11: 0] UNUSED;
		bit [18:16] WxLWTA;
	} LWTAxU_t;
	parameter bit [15:0] LWTAxU_MASK = 16'h8007;
	
	typedef struct packed	//RW,1800DA,1800DE
	{
		bit [15: 1] WxLWTA;
		bit         UNUSED;
	} LWTAxL_t;
	parameter bit [15:0] LWTAxL_MASK = 16'hFFFE;
	
	typedef struct packed	//RW,1800E0
	{
		bit [ 1: 0] UNUSED;
		bit [ 1: 0] SPCCCS;
		bit         UNUSED2;
		bit [ 2: 0] SPCCN;
		bit [ 1: 0] UNUSED3;
		bit         SPCLMD;
		bit         SPWINEN;
		bit [ 3: 0] SPTYPE;
	} SPCTL_t;
	parameter bit [15:0] SPCTL_MASK = 16'h373F;
	
	typedef struct packed	//RW,1800E2
	{
		bit [ 6: 0] UNUSED;
		bit         TPSDSL;
		bit [ 1: 0] UNUSED2;
		bit         BKSDEN;
		bit         R0SDEN;
		bit         N3SDEN;
		bit         N2SDEN;
		bit         N1SDEN;
		bit         N0SDEN;
	} SDCTL_t;
	parameter bit [15:0] SDCTL_MASK = 16'h013F;
	
	typedef struct packed	//RW,1800E4
	{
		bit         UNUSED;
		bit [ 2: 0] N3CAOS;
		bit         UNUSED2;
		bit [ 2: 0] N2CAOS;
		bit         UNUSED3;
		bit [ 2: 0] N1CAOS;
		bit         UNUSED4;
		bit [ 2: 0] N0CAOS;
	} CRAOFA_t;
	parameter bit [15:0] CRAOFA_MASK = 16'h7777;
	
	typedef struct packed	//RW,1800E6
	{
		bit [ 8: 0] UNUSED;
		bit [ 2: 0] SPCAOS;
		bit         UNUSED2;
		bit [ 2: 0] R0CAOS;
	} CRAOFB_t;
	parameter bit [15:0] CRAOFB_MASK = 16'h0077;
	
	typedef struct packed	//RW,1800E8
	{
		bit [ 9: 0] UNUSED;
		bit         SPLCEN;
		bit         R0LCEN;
		bit         N3LCEN;
		bit         N2LCEN;
		bit         N1LCEN;
		bit         N0LCEN;
	} LNCLEN_t;
	parameter bit [15:0] LNCLEN_MASK = 16'h003F;
	
	typedef struct packed	//RW,1800EA
	{
		bit [ 5: 0] UNUSED;
		bit [ 1: 0] R0SPRM;
		bit [ 1: 0] N3SPRM;
		bit [ 1: 0] N2SPRM;
		bit [ 1: 0] N1SPRM;
		bit [ 1: 0] N0SPRM;
	} SFPRMD_t;
	parameter bit [15:0] SFPRMD_MASK = 16'h03FF;
	
	typedef struct packed	//RW,1800EC
	{
		bit         BOKEN;
		bit [ 2: 0] BOKN;
		bit         UNUSED;
		bit         EXCCEN;
		bit         CCRTMD;
		bit         CCMD;
		bit         UNUSED2;
		bit         SPCCEN;
		bit         LCCCEN;
		bit         R0CCEN;
		bit         N3CCEN;
		bit         N2CCEN;
		bit         N1CCEN;
		bit         N0CCEN;
	} CCCTL_t;
	parameter bit [15:0] CCCTL_MASK = 16'hF77F;
	
	typedef struct packed	//RW,1800EE
	{
		bit [ 5: 0] UNUSED;
		bit [ 1: 0] R0SCCM;
		bit [ 1: 0] N3SCCM;
		bit [ 1: 0] N2SCCM;
		bit [ 1: 0] N1SCCM;
		bit [ 1: 0] N0SCCM;
	} SFCCMD_t;
	parameter bit [15:0] SFCCMD_MASK = 16'h03FF;
	
	typedef struct packed	//RW,1800F0
	{
		bit [ 4: 0] UNUSED;
		bit [ 2: 0] S1PRIN;
		bit [ 4: 0] UNUSED2;
		bit [ 2: 0] S0PRIN;
	} PRISA_t;
	parameter bit [15:0] PRISA_MASK = 16'h0707;
	
	typedef struct packed	//RW,1800F2
	{
		bit [ 4: 0] UNUSED;
		bit [ 2: 0] S3PRIN;
		bit [ 4: 0] UNUSED2;
		bit [ 2: 0] S2PRIN;
	} PRISB_t;
	parameter bit [15:0] PRISB_MASK = 16'h0707;
	
	typedef struct packed	//RW,1800F4
	{
		bit [ 4: 0] UNUSED;
		bit [ 2: 0] S5PRIN;
		bit [ 4: 0] UNUSED2;
		bit [ 2: 0] S4PRIN;
	} PRISC_t;
	parameter bit [15:0] PRISC_MASK = 16'h0707;
	
	typedef struct packed	//RW,1800F6
	{
		bit [ 4: 0] UNUSED;
		bit [ 2: 0] S7PRIN;
		bit [ 4: 0] UNUSED2;
		bit [ 2: 0] S6PRIN;
	} PRISD_t;
	parameter bit [15:0] PRISD_MASK = 16'h0707;
	
	typedef struct packed	//RW,1800F8
	{
		bit [ 4: 0] UNUSED;
		bit [ 2: 0] N1PRIN;
		bit [ 4: 0] UNUSED2;
		bit [ 2: 0] N0PRIN;
	} PRINA_t;
	parameter bit [15:0] PRINA_MASK = 16'h0707;
	
	typedef struct packed	//RW,1800FA
	{
		bit [ 4: 0] UNUSED;
		bit [ 2: 0] N3PRIN;
		bit [ 4: 0] UNUSED2;
		bit [ 2: 0] N2PRIN;
	} PRINB_t;
	parameter bit [15:0] PRINB_MASK = 16'h0707;
	
	typedef struct packed	//RW,1800FC
	{
		bit [12: 0] UNUSED;
		bit [ 2: 0] R0PRIN;
	} PRIR_t;
	parameter bit [15:0] PRIR_MASK = 16'h0007;
	
	typedef struct packed	//RW,180100
	{
		bit [ 2: 0] UNUSED;
		bit [ 4: 0] S1CCRT;
		bit [ 2: 0] UNUSED2;
		bit [ 4: 0] S0CCRT;
	} CCRSA_t;
	parameter bit [15:0] CCRSA_MASK = 16'h1F1F;
	
	typedef struct packed	//RW,180102
	{
		bit [ 2: 0] UNUSED;
		bit [ 4: 0] S3CCRT;
		bit [ 2: 0] UNUSED2;
		bit [ 4: 0] S2CCRT;
	} CCRSB_t;
	parameter bit [15:0] CCRSB_MASK = 16'h1F1F;
	
	typedef struct packed	//RW,180104
	{
		bit [ 2: 0] UNUSED;
		bit [ 4: 0] S5CCRT;
		bit [ 2: 0] UNUSED2;
		bit [ 4: 0] S4CCRT;
	} CCRSC_t;
	parameter bit [15:0] CCRSC_MASK = 16'h1F1F;
	
	typedef struct packed	//RW,180106
	{
		bit [ 2: 0] UNUSED;
		bit [ 4: 0] S7CCRT;
		bit [ 2: 0] UNUSED2;
		bit [ 4: 0] S6CCRT;
	} CCRSD_t;
	parameter bit [15:0] CCRSD_MASK = 16'h1F1F;
	
	typedef struct packed	//RW,180108
	{
		bit [ 2: 0] UNUSED;
		bit [ 4: 0] N1CCRT;
		bit [ 2: 0] UNUSED2;
		bit [ 4: 0] N0CCRT;
	} CCRNA_t;
	parameter bit [15:0] CCRNA_MASK = 16'h1F1F;
	
	typedef struct packed	//RW,18010A
	{
		bit [ 2: 0] UNUSED;
		bit [ 4: 0] N3CCRT;
		bit [ 2: 0] UNUSED2;
		bit [ 4: 0] N2CCRT;
	} CCRNB_t;
	parameter bit [15:0] CCRNB_MASK = 16'h1F1F;
	
	typedef struct packed	//RW,18010C
	{
		bit [10: 0] UNUSED;
		bit [ 4: 0] R0CCRT;
	} CCRR_t;
	parameter bit [15:0] CCRR_MASK = 16'h001F;
	
	typedef struct packed	//RW,18010E
	{
		bit [ 2: 0] UNUSED;
		bit [ 4: 0] BKCCRT;
		bit [ 2: 0] UNUSED2;
		bit [ 4: 0] LCCCRT;
	} CCRLB_t;
	parameter bit [15:0] CCRLB_MASK = 16'h1F1F;
	
	typedef struct packed	//RW,180110
	{
		bit [ 8: 0] UNUSED;
		bit         SPCOEN;
		bit         BKCOEN;
		bit         R0COEN;
		bit         N3COEN;
		bit         N2COEN;
		bit         N1COEN;
		bit         N0COEN;
	} CLOFEN_t;
	parameter bit [15:0] CLOFEN_MASK = 16'h007F;
	
	typedef struct packed	//RW,180112
	{
		bit [ 8: 0] UNUSED;
		bit         SPCOSL;
		bit         BKCOSL;
		bit         R0COSL;
		bit         N3COSL;
		bit         N2COSL;
		bit         N1COSL;
		bit         N0COSL;
	} CLOFSL_t;
	parameter bit [15:0] CLOFSL_MASK = 16'h007F;
	
	typedef struct packed	//RW,180114,18011A
	{
		bit [ 6: 0] UNUSED;
		bit [ 8: 0] CORD;
	} COxR_t;
	parameter bit [15:0] COxR_MASK = 16'h01FF;
	
	typedef struct packed	//RW,180116,18011C
	{
		bit [ 6: 0] UNUSED;
		bit [ 8: 0] COGR;
	} COxG_t;
	parameter bit [15:0] COxG_MASK = 16'h01FF;
	
	typedef struct packed	//RW,180118,18011E
	{
		bit [ 6: 0] UNUSED;
		bit [ 8: 0] COBL;
	} COxB_t;
	parameter bit [15:0] COxB_MASK = 16'h01FF;
	
	typedef struct packed	//18000C,1800FE
	{
		bit [15: 0] UNUSED;
	} RSRV_t;
	parameter bit [15:0] RSRV_MASK = 16'h0000;
	
	typedef struct packed
	{
		TVMD_t   TVMD;			//180000
		EXTEN_t  EXTEN;		//180002
		TVSTAT_t TVSTAT;		//180004
		VRSIZE_t VRSIZE;		//180006
		HCNT_t   HCNT;			//180008
		VCNT_t   VCNT;			//18000A
		RSRV_t   RSRV0;		//18000C
		RAMCTL_t RAMCTL;		//18000E
		CYCx0L_t CYCA0L;		//180010
		CYCx0U_t CYCA0U;		//180012
		CYCx1L_t CYCA1L;		//180014
		CYCx1U_t CYCA1U;		//180016
		CYCx0L_t CYCB0L;		//180018
		CYCx0U_t CYCB0U;		//18001A
		CYCx1L_t CYCB1L;		//18001C
		CYCx1U_t CYCB1U;		//18001E
		BGON_t   BGON;			//180020
		MZCTL_t  MZCTL;		//180022
		SFSEL_t  SFSEL;		//180024
		SFCODE_t SFCODE;		//180026
		CHCTLA_t CHCTLA;		//180028
		CHCTLB_t CHCTLB;		//18002A
		BMPNA_t  BMPNA;		//18002C
		BMPNB_t  BMPNB;		//18002E
		PNCNx_t  PNCN0;		//180030
		PNCNx_t  PNCN1;		//180032
		PNCNx_t  PNCN2;		//180034
		PNCNx_t  PNCN3;		//180036
		PNCR_t   PNCR;			//180038
		PLSZ_t   PLSZ;			//18003A
		MPOFN_t  MPOFN;		//18003C
		MPOFR_t  MPOFR;		//18003E
		MPABNx_t MPABN0;		//180040
		MPCDNx_t MPCDN0;		//180042
		MPABNx_t MPABN1;		//180044
		MPCDNx_t MPCDN1;		//180046
		MPABNx_t MPABN2;		//180048
		MPCDNx_t MPCDN2;		//18004A
		MPABNx_t MPABN3;		//18004C
		MPCDNx_t MPCDN3;		//18004E
		MPABRx_t MPABRA;		//180050
		MPCDRx_t MPCDRA;		//180052
		MPEFRx_t MPEFRA;		//180054
		MPGHRx_t MPGHRA;		//180056
		MPIJRx_t MPIJRA;		//180058
		MPKLRx_t MPKLRA;		//18005A
		MPMNRx_t MPMNRA;		//18005C
		MPOPRx_t MPOPRA;		//18005E
		MPABRx_t MPABRB;		//180060
		MPCDRx_t MPCDRB;		//180062
		MPEFRx_t MPEFRB;		//180064
		MPGHRx_t MPGHRB;		//180066
		MPIJRx_t MPIJRB;		//180068
		MPKLRx_t MPKLRB;		//18006A
		MPMNRx_t MPMNRB;		//18006C
		MPOPRx_t MPOPRB;		//18006E
		SCXINx_t SCXIN0;		//180070
		SCXDNx_t SCXDN0;		//180072
		SCYINx_t SCYIN0;		//180074
		SCYDNx_t SCYDN0;		//180076
		ZMXINx_t ZMXIN0;		//180078
		ZMXDNx_t ZMXDN0;		//18007A
		ZMYINx_t ZMYIN0;		//18007C
		ZMYDNx_t ZMYDN0;		//18007E
		SCXINx_t SCXIN1;		//180080
		SCXDNx_t SCXDN1;		//180082
		SCYINx_t SCYIN1;		//180084
		SCYDNx_t SCYDN1;		//180086
		ZMXINx_t ZMXIN1;		//180088
		ZMXDNx_t ZMXDN1;		//18008A
		ZMYINx_t ZMYIN1;		//18008C
		ZMYDNx_t ZMYDN1;		//18008E
		SCXNx_t  SCXN2;		//180090
		SCYNx_t  SCYN2;		//180092
		SCXNx_t  SCXN3;		//180094
		SCYNx_t  SCYN3;		//180096
		ZMCTL_t  ZMCTL;		//180098
		SCRCTL_t SCRCTL;		//18009A
		VCSTAU_t VCSTAU;		//18009C
		VCSTAL_t VCSTAL;		//18009E
		LSTAxU_t LSTA0U;		//1800A0
		LSTAxL_t LSTA0L;		//1800A2
		LSTAxU_t LSTA1U;		//1800A4
		LSTAxL_t LSTA1L;		//1800A6
		LCTAU_t  LCTAU;		//1800A8
		LCTAL_t  LCTAL;		//1800AA
		BKTAU_t  BKTAU;		//1800AC
		BKTAL_t  BKTAL;		//1800AE
		RPMD_t   RPMD;			//1800B0
		RPRCTL_t RPRCTL;		//1800B2
		KTCTL_t  KTCTL;		//1800B4
		KTAOF_t  KTAOF;		//1800B6
		OVPNRx_t OVPNRA;		//1800B8
		OVPNRx_t OVPNRB;		//1800BA
		RPTAU_t  RPTAU;		//1800BC
		RPTAL_t  RPTAL;		//1800BE
		WPSXx_t  WPSX0;		//1800C0
		WPSYx_t  WPSY0;		//1800C2
		WPEXx_t  WPEX0;		//1800C4
		WPEYx_t  WPEY0;		//1800C6
		WPSXx_t  WPSX1;		//1800C8
		WPSYx_t  WPSY1;		//1800CA
		WPEXx_t  WPEX1;		//1800CC
		WPEYx_t  WPEY1;		//1800CE
		WCTLA_t  WCTLA;		//1800D0
		WCTLB_t  WCTLB;		//1800D2
		WCTLC_t  WCTLC;		//1800D4
		WCTLD_t  WCTLD;		//1800D6
		LWTAxU_t LWTA0U;		//1800D8
		LWTAxL_t LWTA0L;		//1800DA
		LWTAxU_t LWTA1U;		//1800DC
		LWTAxL_t LWTA1L;		//1800DE
		SPCTL_t  SPCTL;		//1800E0
		SDCTL_t  SDCTL;		//1800E2
		CRAOFA_t CRAOFA;		//1800E4
		CRAOFB_t CRAOFB;		//1800E6
		LNCLEN_t LNCLEN;		//1800E8
		SFPRMD_t SFPRMD;		//1800EA
		CCCTL_t  CCCTL;		//1800EC
		SFCCMD_t SFCCMD;		//1800EE
		PRISA_t  PRISA;		//1800F0
		PRISB_t  PRISB;		//1800F2
		PRISC_t  PRISC;		//1800F4
		PRISD_t  PRISD;		//1800F6
		PRINA_t  PRINA;		//1800F8
		PRINB_t  PRINB;		//1800FA
		PRIR_t   PRIR;			//1800FC
		RSRV_t   RSRV1;		//1800FE
		CCRSA_t  CCRSA;		//180100
		CCRSB_t  CCRSB;		//180102
		CCRSC_t  CCRSC;		//180104
		CCRSD_t  CCRSD;		//180106
		CCRNA_t  CCRNA;		//180108
		CCRNB_t  CCRNB;		//18010A
		CCRR_t   CCRR;			//18010C
		CCRLB_t  CCRLB;		//18010E
		CLOFEN_t CLOFEN;		//180110
		CLOFSL_t CLOFSL;		//180112
		COxR_t   COAR;			//180114
		COxG_t   COAG;			//180116
		COxB_t   COAB;			//180118
		COxR_t   COBR;			//18011A
		COxG_t   COBG;			//18011C
		COxB_t   COBB;			//18011E
	} VDP2Regs_t;
	
	typedef struct
	{
		bit [ 2: 0] CHCN;
		bit         CHSZ;
		bit [ 1: 0] BMSZ;
		bit         BMEN;
		bit [ 1: 0] PLSZ;
		bit [ 2: 0] BMP;
		bit         BMPR;
		bit         BMCC;
		PNCNx_t     PNC;
		bit [ 8: 6] MP;
		bit [ 5: 0] MPn[4];
		bit [18: 0] SCX;
		bit [18: 0] SCY;
		bit [10: 0] ZMX;
		bit [10: 0] ZMY;
		bit         ZMHF;
		bit         ZMQT;
		bit [18: 1] LSTA;
		bit         LSCX;
		bit         LSCY;
		bit         LZMX;
		bit         VCSC;
		bit [ 1: 0] LSS;
		bit [18: 1] LWTA;
		bit         TPON;
		bit         ON;
		bit [ 2: 0] CAOS;
		bit [ 2: 0] PRIN;
		bit [ 1: 0] SPRM;
		bit         COEN;
		bit         COSL;
		bit         CCEN;
		bit [ 4: 0] CCRT;
		bit [ 1: 0] SCCM;
	} VDP2NSRegs_t;
	typedef VDP2NSRegs_t VDP2NSxRegs_t [4];
	
	typedef struct
	{
		bit [ 2: 0] CHCN;
		bit         CHSZ;
		bit         BMSZ;
		bit         BMEN;
		PNCNx_t     PNC;
		bit [ 2: 0] BMP;
		bit         BMPR;
		bit         BMCC;
		bit         TPON;
		bit         ON;
		bit [ 2: 0] CAOS;
		bit [ 2: 0] PRIN;
		bit [ 1: 0] SPRM;
		bit         COEN;
		bit         COSL;
		bit         CCEN;
		bit [ 4: 0] CCRT;
		bit [ 1: 0] SCCM;
	} VDP2RSRegs_t;
	typedef VDP2RSRegs_t VDP2RSxRegs_t [2];
	
	typedef struct
	{
		bit [ 8: 6] MP;
		bit [ 5: 0] MPn[16];
		bit         KTE;
		bit [ 1: 0] KMD;
		bit [ 2: 0] KTAOS;
		bit         KDBS;
		bit         KLCE;
		bit [ 1: 0] PLSZ;
		bit [ 1: 0] OVR;
		bit [15: 0] OVPNR;
	} VDP2RPRegs_t;
	typedef VDP2RPRegs_t VDP2RPxRegs_t [2];
	
	
	function VDP2NSxRegs_t NSxRegs(input VDP2Regs_t REGS);
		VDP2NSxRegs_t S;

		S[0].CHCN = REGS.CHCTLA.N0CHCN;
		S[1].CHCN = {1'b0,REGS.CHCTLA.N1CHCN};
		S[2].CHCN = {2'b00,REGS.CHCTLB.N2CHCN};
		S[3].CHCN = {2'b00,REGS.CHCTLB.N3CHCN};
		
		S[0].CHSZ = REGS.CHCTLA.N0CHSZ;
		S[1].CHSZ = REGS.CHCTLA.N1CHSZ;
		S[2].CHSZ = REGS.CHCTLB.N2CHSZ;
		S[3].CHSZ = REGS.CHCTLB.N3CHSZ;
		
		S[0].BMSZ = REGS.CHCTLA.N0BMSZ;
		S[1].BMSZ = REGS.CHCTLA.N1BMSZ;
		S[2].BMSZ = '0;
		S[3].BMSZ = '0;
		
		S[0].BMEN = REGS.CHCTLA.N0BMEN;
		S[1].BMEN = REGS.CHCTLA.N1BMEN;
		S[2].BMEN = 0;
		S[3].BMEN = 0;
		
		S[0].PLSZ = REGS.PLSZ.N0PLSZ;
		S[1].PLSZ = REGS.PLSZ.N1PLSZ;
		S[2].PLSZ = REGS.PLSZ.N2PLSZ;
		S[3].PLSZ = REGS.PLSZ.N3PLSZ;
		
		S[0].BMP = REGS.BMPNA.N0BMP;
		S[1].BMP = REGS.BMPNA.N1BMP;
		S[2].BMP = '0;
		S[3].BMP = '0;
		
		S[0].BMPR = REGS.BMPNA.N0BMPR;
		S[1].BMPR = REGS.BMPNA.N1BMPR;
		S[2].BMPR = 0;
		S[3].BMPR = 0;
		
		S[0].BMCC = REGS.BMPNA.N0BMCC;
		S[1].BMCC = REGS.BMPNA.N1BMCC;
		S[2].BMCC = 0;
		S[3].BMCC = 0;
		
		S[0].PNC = REGS.PNCN0;
		S[1].PNC = REGS.PNCN1;
		S[2].PNC = REGS.PNCN2;
		S[3].PNC = REGS.PNCN3;
		
		S[0].MP = REGS.MPOFN.N0MP;
		S[1].MP = REGS.MPOFN.N1MP;
		S[2].MP = REGS.MPOFN.N2MP;
		S[3].MP = REGS.MPOFN.N3MP;
		
		S[0].MPn[0] = REGS.MPABN0.NxMPA;
		S[1].MPn[0] = REGS.MPABN1.NxMPA;
		S[2].MPn[0] = REGS.MPABN2.NxMPA;
		S[3].MPn[0] = REGS.MPABN3.NxMPA;
		S[0].MPn[1] = REGS.MPABN0.NxMPB;
		S[1].MPn[1] = REGS.MPABN1.NxMPB;
		S[2].MPn[1] = REGS.MPABN2.NxMPB;
		S[3].MPn[1] = REGS.MPABN3.NxMPB;
		S[0].MPn[2] = REGS.MPCDN0.NxMPC;
		S[1].MPn[2] = REGS.MPCDN1.NxMPC;
		S[2].MPn[2] = REGS.MPCDN2.NxMPC;
		S[3].MPn[2] = REGS.MPCDN3.NxMPC;
		S[0].MPn[3] = REGS.MPCDN0.NxMPD;
		S[1].MPn[3] = REGS.MPCDN1.NxMPD;
		S[2].MPn[3] = REGS.MPCDN2.NxMPD;
		S[3].MPn[3] = REGS.MPCDN3.NxMPD;
		
		S[0].SCX = {REGS.SCXIN0.NxSCXI,REGS.SCXDN0.NxSCXD};
		S[1].SCX = {REGS.SCXIN1.NxSCXI,REGS.SCXDN1.NxSCXD};
		S[2].SCX = {REGS.SCXN2.NxSCX,8'h00};
		S[3].SCX = {REGS.SCXN3.NxSCX,8'h00};
		
		S[0].SCY = {REGS.SCYIN0.NxSCYI,REGS.SCYDN0.NxSCYD};
		S[1].SCY = {REGS.SCYIN1.NxSCYI,REGS.SCYDN1.NxSCYD};
		S[2].SCY = {REGS.SCYN2.NxSCY,8'h00};
		S[3].SCY = {REGS.SCYN3.NxSCY,8'h00};
		
		S[0].ZMX = {REGS.ZMXIN0.NxZMXI,REGS.ZMXDN0.NxZMXD};
		S[1].ZMX = {REGS.ZMXIN1.NxZMXI,REGS.ZMXDN1.NxZMXD};
		S[2].ZMX = '0;
		S[3].ZMX = '0;
		
		S[0].ZMY = {REGS.ZMYIN0.NxZMYI,REGS.ZMYDN0.NxZMYD};
		S[1].ZMY = {REGS.ZMYIN1.NxZMYI,REGS.ZMYDN1.NxZMYD};
		S[2].ZMY = '0;
		S[3].ZMY = '0;
		
		S[0].ZMHF = REGS.ZMCTL.N0ZMHF;
		S[1].ZMHF = REGS.ZMCTL.N1ZMHF;
		S[2].ZMHF = '0;
		S[3].ZMHF = '0;
		
		S[0].ZMQT = REGS.ZMCTL.N0ZMQT;
		S[1].ZMQT = REGS.ZMCTL.N1ZMQT;
		S[2].ZMQT = '0;
		S[3].ZMQT = '0;
		
		S[0].LSTA = {REGS.LSTA0U.LSTA,REGS.LSTA0L.LSTA};
		S[1].LSTA = {REGS.LSTA1U.LSTA,REGS.LSTA1L.LSTA};
		S[2].LSTA = '0;
		S[3].LSTA = '0;
		
		S[0].VCSC = REGS.SCRCTL.N0VCSC;
		S[1].VCSC = REGS.SCRCTL.N1VCSC;
		S[2].VCSC = 0;
		S[3].VCSC = 0;
		
		S[0].LSCX = REGS.SCRCTL.N0LSCX;
		S[1].LSCX = REGS.SCRCTL.N1LSCX;
		S[2].LSCX = '0;
		S[3].LSCX = '0;
		
		S[0].LSCY = REGS.SCRCTL.N0LSCY;
		S[1].LSCY = REGS.SCRCTL.N1LSCY;
		S[2].LSCY = '0;
		S[3].LSCY = '0;
		
		S[0].LZMX = REGS.SCRCTL.N0LZMX;
		S[1].LZMX = REGS.SCRCTL.N1LZMX;
		S[2].LZMX = '0;
		S[3].LZMX = '0;
		
		S[0].LSS = REGS.SCRCTL.N0LSS;
		S[1].LSS = REGS.SCRCTL.N1LSS;
		S[2].LSS = '0;
		S[3].LSS = '0;
		
		S[0].LWTA = {REGS.LWTA0U.WxLWTA,REGS.LWTA0L.WxLWTA};
		S[1].LWTA = {REGS.LWTA1U.WxLWTA,REGS.LWTA1L.WxLWTA};
		S[2].LWTA = '0;
		S[3].LWTA = '0;
		
		S[0].TPON = REGS.BGON.N0TPON;
		S[1].TPON = REGS.BGON.N1TPON;
		S[2].TPON = REGS.BGON.N2TPON;
		S[3].TPON = REGS.BGON.N3TPON;
	
		S[0].ON = REGS.BGON.N0ON;
		S[1].ON = REGS.BGON.N1ON;
		S[2].ON = REGS.BGON.N2ON;
		S[3].ON = REGS.BGON.N3ON;
		
		S[0].CAOS = REGS.CRAOFA.N0CAOS;
		S[1].CAOS = REGS.CRAOFA.N1CAOS;
		S[2].CAOS = REGS.CRAOFA.N2CAOS;
		S[3].CAOS = REGS.CRAOFA.N3CAOS;
		
		S[0].PRIN = REGS.PRINA.N0PRIN;
		S[1].PRIN = REGS.PRINA.N1PRIN;
		S[2].PRIN = REGS.PRINB.N2PRIN;
		S[3].PRIN = REGS.PRINB.N3PRIN;
		
		S[0].SPRM = REGS.SFPRMD.N0SPRM;
		S[1].SPRM = REGS.SFPRMD.N1SPRM;
		S[2].SPRM = REGS.SFPRMD.N2SPRM;
		S[3].SPRM = REGS.SFPRMD.N3SPRM;
		
		S[0].COEN = REGS.CLOFEN.N0COEN;
		S[1].COEN = REGS.CLOFEN.N1COEN;
		S[2].COEN = REGS.CLOFEN.N2COEN;
		S[3].COEN = REGS.CLOFEN.N3COEN;
		
		S[0].COSL = REGS.CLOFSL.N0COSL;
		S[1].COSL = REGS.CLOFSL.N1COSL;
		S[2].COSL = REGS.CLOFSL.N2COSL;
		S[3].COSL = REGS.CLOFSL.N3COSL;
		
		S[0].CCEN = REGS.CCCTL.N0CCEN;
		S[1].CCEN = REGS.CCCTL.N1CCEN;
		S[2].CCEN = REGS.CCCTL.N2CCEN;
		S[3].CCEN = REGS.CCCTL.N3CCEN;
		
		S[0].CCRT = REGS.CCRNA.N0CCRT;
		S[1].CCRT = REGS.CCRNA.N1CCRT;
		S[2].CCRT = REGS.CCRNB.N2CCRT;
		S[3].CCRT = REGS.CCRNB.N3CCRT;
		
		S[0].SCCM = REGS.SFCCMD.N0SCCM;
		S[1].SCCM = REGS.SFCCMD.N1SCCM;
		S[2].SCCM = REGS.SFCCMD.N2SCCM;
		S[3].SCCM = REGS.SFCCMD.N3SCCM;
		
		return S;
	endfunction
	
	function VDP2RSxRegs_t RSxRegs(input VDP2Regs_t REGS);
		VDP2RSxRegs_t S;

		S[0].CHCN = REGS.CHCTLB.R0CHCN;
		S[1].CHCN = REGS.CHCTLA.N0CHCN;
		
		S[0].CHSZ = REGS.CHCTLB.R0CHSZ;
		S[1].CHSZ = REGS.CHCTLA.N0CHSZ;
		
		S[0].BMSZ = REGS.CHCTLB.R0BMSZ;
		S[1].BMSZ = 0;
		
		S[0].BMEN = REGS.CHCTLB.R0BMEN;
		S[1].BMEN = 0;
		
		S[0].PNC = REGS.PNCR;
		S[1].PNC = REGS.PNCN0;
	
		S[0].BMP = REGS.BMPNB.R0BMP;
		S[1].BMP = REGS.BMPNA.N0BMP;
		
		S[0].BMPR = REGS.BMPNB.R0BMPR;
		S[1].BMPR = REGS.BMPNA.N1BMPR;
		
		S[0].BMCC = REGS.BMPNB.R0BMCC;
		S[1].BMCC = REGS.BMPNA.N1BMCC;
		
		S[0].ON = REGS.BGON.R0ON;
		S[1].ON = REGS.BGON.R1ON;
		
		S[0].TPON = REGS.BGON.R0TPON;
		S[1].TPON = REGS.BGON.N0TPON;
		
		S[0].CAOS = REGS.CRAOFB.R0CAOS;
		S[1].CAOS = REGS.CRAOFA.N0CAOS;
		
		S[0].PRIN = REGS.PRIR.R0PRIN;
		S[1].PRIN = REGS.PRINA.N0PRIN;
		
		S[0].SPRM = REGS.SFPRMD.R0SPRM;
		S[1].SPRM = REGS.SFPRMD.N1SPRM;
		
		S[0].COEN = REGS.CLOFEN.R0COEN;
		S[1].COEN = REGS.CLOFEN.N0COEN;
		
		S[0].COSL = REGS.CLOFSL.R0COSL;
		S[1].COSL = REGS.CLOFSL.N0COSL;
		
		S[0].CCEN = REGS.CCCTL.R0CCEN;
		S[1].CCEN = REGS.CCCTL.N0CCEN;
		
		S[0].CCRT = REGS.CCRR.R0CCRT;
		S[1].CCRT = REGS.CCRNA.N0CCRT;
		
		S[0].SCCM = REGS.SFCCMD.R0SCCM;
		S[1].SCCM = REGS.SFCCMD.N1SCCM;
		
		return S;
	endfunction
	
	function VDP2RPxRegs_t RPxRegs(input VDP2Regs_t REGS);
		VDP2RPxRegs_t S;
		
		S[0].MP = REGS.MPOFR.RAMP;
		S[1].MP = REGS.MPOFR.RBMP;
		
		S[0].MPn[0] = REGS.MPABRA.RxMPA;
		S[1].MPn[0] = REGS.MPABRB.RxMPA;
		S[0].MPn[1] = REGS.MPABRA.RxMPB;
		S[1].MPn[1] = REGS.MPABRB.RxMPB;
		S[0].MPn[2] = REGS.MPCDRA.RxMPC;
		S[1].MPn[2] = REGS.MPCDRB.RxMPC;
		S[0].MPn[3] = REGS.MPCDRA.RxMPD;
		S[1].MPn[3] = REGS.MPCDRB.RxMPD;
		S[0].MPn[4] = REGS.MPEFRA.RxMPE;
		S[1].MPn[4] = REGS.MPEFRB.RxMPE;
		S[0].MPn[5] = REGS.MPEFRA.RxMPF;
		S[1].MPn[5] = REGS.MPEFRB.RxMPF;
		S[0].MPn[6] = REGS.MPGHRA.RxMPG;
		S[1].MPn[6] = REGS.MPGHRB.RxMPG;
		S[0].MPn[7] = REGS.MPGHRA.RxMPH;
		S[1].MPn[7] = REGS.MPGHRB.RxMPH;
		S[0].MPn[8] = REGS.MPIJRA.RxMPI;
		S[1].MPn[8] = REGS.MPIJRB.RxMPI;
		S[0].MPn[9] = REGS.MPIJRA.RxMPJ;
		S[1].MPn[9] = REGS.MPIJRB.RxMPJ;
		S[0].MPn[10] = REGS.MPKLRA.RxMPK;
		S[1].MPn[10] = REGS.MPKLRB.RxMPK;
		S[0].MPn[11] = REGS.MPKLRA.RxMPL;
		S[1].MPn[11] = REGS.MPKLRB.RxMPL;
		S[0].MPn[12] = REGS.MPMNRA.RxMPM;
		S[1].MPn[12] = REGS.MPMNRB.RxMPM;
		S[0].MPn[13] = REGS.MPMNRA.RxMPN;
		S[1].MPn[13] = REGS.MPMNRB.RxMPN;
		S[0].MPn[14] = REGS.MPOPRA.RxMPO;
		S[1].MPn[14] = REGS.MPOPRB.RxMPO;
		S[0].MPn[15] = REGS.MPOPRA.RxMPP;
		S[1].MPn[15] = REGS.MPOPRB.RxMPP;
		
		S[0].KTE = REGS.KTCTL.RAKTE;
		S[1].KTE = REGS.KTCTL.RBKTE;
		
		S[0].KMD = REGS.KTCTL.RAKMD;
		S[1].KMD = REGS.KTCTL.RBKMD;
		
		S[0].KTAOS = REGS.KTAOF.RAKTAOS;
		S[1].KTAOS = REGS.KTAOF.RBKTAOS;
		
		S[0].KDBS = REGS.KTCTL.RAKDBS;
		S[1].KDBS = REGS.KTCTL.RBKDBS;
		
		S[0].KLCE = REGS.KTCTL.RAKLCE;
		S[1].KLCE = REGS.KTCTL.RBKLCE;
		
		S[0].PLSZ = REGS.PLSZ.RAPLSZ;
		S[1].PLSZ = REGS.PLSZ.RBPLSZ;
		
		S[0].OVR = REGS.PLSZ.RAOVR;
		S[1].OVR = REGS.PLSZ.RBOVR;
		
		S[0].OVPNR = REGS.OVPNRA.RxOPN;
		S[1].OVPNR = REGS.OVPNRB.RxOPN;
		return S;
	endfunction

	//VRAM access command value
	parameter VCP_N0PN 	= 4'h0; 	//NBG0 pattern name data read
	parameter VCP_N1PN 	= 4'h1; 	//NBG1 pattern name data read
	parameter VCP_N2PN 	= 4'h2;	//NBG2 pattern name data read
	parameter VCP_N3PN 	= 4'h3;	//NBG3 pattern name data read
	parameter VCP_N0CH 	= 4'h4;	//NBG0 character data read
	parameter VCP_N1CH 	= 4'h5;	//NBG1 character data read
	parameter VCP_N2CH 	= 4'h6;	//NBG2 character data read
	parameter VCP_N3CH 	= 4'h7;	//NBG3 character data read
	parameter VCP_N0VS 	= 4'hC;	//NBG0 vertical cell scroll data read
	parameter VCP_N1VS 	= 4'hD;	//NBG1 vertical cell scroll data read
	parameter VCP_CPU 	= 4'hE;	//CPU read/write
	parameter VCP_NA 	   = 4'hF;	//No access
	
	//VRAM access timing
	parameter T0 	= 3'd0;
	parameter T1 	= 3'd1;
	parameter T2 	= 3'd2;
	parameter T3 	= 3'd3;
	parameter T4 	= 3'd4;
	parameter T5 	= 3'd5;
	parameter T6 	= 3'd6;
	parameter T7 	= 3'd7;
	
	typedef struct packed
	{
		bit         VF;
		bit         HF;
		bit         PR;
		bit         CC;
		bit [ 4: 0] UNUSED;
		bit [ 6: 0] PALN;
		bit         UNUSED2;
		bit [14: 0] CHRN;
	} PN_t;
	
	typedef struct packed
	{
		bit         PN; 
		bit         CH; 
		bit         VS; 
//		bit         LS; 
		bit         CPUA; 
		bit         CPUD; 
		bit [ 1: 0] Nx;
	} NVRAMAccess_t;
	
	typedef struct packed
	{
		bit         TP;
		bit [ 6: 0] LCSD;
		bit [15: 0] INT;
		bit [15: 0] FRAC;
	} CT_t;
	
	typedef struct packed
	{
		bit         PN; 
		bit         CH; 
		bit         CT; 
		bit [ 0: 0] Rx;
	} RVRAMAccess_t;
	
	typedef struct packed
	{
		bit [10: 0] INT;
		bit [ 7: 0] FRAC;
	} ScrollData_t;
	parameter ScrollData_t SCRLD_NULL = {11'h000,8'h00};
	
	typedef struct packed
	{
		bit [ 2: 0] INT;
		bit [ 7: 0] FRAC;
	} CoordInc_t;
	parameter CoordInc_t CRDI_NULL = {3'h0,8'h00};
	
	typedef bit [10: 0] NxDispCoord_t[4];
	typedef bit [ 1: 0] NxPNS_t[4];
	typedef bit [ 1: 0] NxCHS_t[4];
	typedef bit [ 1: 0] NxVSS_t[2];
	typedef bit [ 1: 0] NxPNCNT_t[2];
	typedef bit         NxPNEN_t[4];
	typedef bit [ 2: 0] NxCHCNT_t[4];
	typedef bit         NxCHEN_t[4];
	typedef bit [15: 0] RxDispCoord_t[2];
	typedef bit [ 1: 0] RxPNS_t[2];
	typedef bit [ 1: 0] RxCHS_t[2];
	typedef bit [ 2: 0] RxCELLX_t[2];
	typedef bit [ 1: 0] RxCTS_t[2];
	
	typedef struct
	{
		NxDispCoord_t NxX; 
		NxDispCoord_t NxY; 
		RxDispCoord_t RxX; 
		RxDispCoord_t RxY;
		bit [ 3: 0] NxA0PN;
		bit [ 3: 0] NxA1PN;
		bit [ 3: 0] NxB0PN;
		bit [ 3: 0] NxB1PN;
		bit [ 3: 0] NxA0CH;
		bit [ 3: 0] NxA1CH;
		bit [ 3: 0] NxB0CH;
		bit [ 3: 0] NxB1CH;
		bit [ 1: 0] NxA0VS;
		bit [ 1: 0] NxA1VS;
		bit [ 1: 0] NxB0VS;
		bit [ 1: 0] NxB1VS;
		bit         NxA0CPU;
		bit         NxA1CPU;
		bit         NxB0CPU;
		bit         NxB1CPU;
		NxPNEN_t    NxPN_FETCH;
		bit [ 1: 0] RxA0PN;
		bit [ 1: 0] RxA1PN;
		bit [ 1: 0] RxB0PN;
		bit [ 1: 0] RxB1PN;
		bit [ 1: 0] RxA0CH;
		bit [ 1: 0] RxA1CH;
		bit [ 1: 0] RxB0CH;
		bit [ 1: 0] RxB1CH;
		bit [ 1: 0] RxA0CT;
		bit [ 1: 0] RxA1CT;
		bit [ 1: 0] RxB0CT;
		bit [ 1: 0] RxB1CT;
		bit [ 1: 0] RxCRCT;
		bit [ 1: 0] RxCTTP;
		bit         LS;
		bit   [2:0] LS_POS;
		bit         LW;
		bit         LW_POS;
		bit         RPA;
		bit         RPB;
		bit         RCTA;
		bit         RCTB;
		bit         R0RP;
		bit   [7:2] RP_POS;
		bit         BS;
		bit         LN;
	} VRAMAccessState_t;
	typedef VRAMAccessState_t VRAMAccessPipeline_t [5];
	
	typedef struct
	{
		bit [ 3: 0] NxPN;
		NxPNS_t     NxPNS;
		bit [ 3: 0] NxCH;
		NxCHS_t     NxCHS;
		NxPNCNT_t   NxPN_CNT;
		NxPNEN_t    NxPN_EN;
		NxCHCNT_t   NxCH_CNT;
		NxCHEN_t    NxCH_EN;
		bit [ 1: 0] NxVS;
		NxVSS_t     NxVSS;
	} NBGState_t;
	typedef NBGState_t NBGPipeline_t [4];
	
	typedef struct
	{
		bit [ 1: 0] RxPN;
		RxPNS_t     RxPNS;
		bit [ 1: 0] RxCH;
		RxCHS_t     RxCHS;
		RxCELLX_t   RxCELLX;
		bit [ 1: 0] RxCT;
		RxCTS_t     RxCTS;
		bit [ 1: 0] RxCRCT;
		bit [ 1: 0] RxCTTP;
		bit [ 1: 0] RxOVR;
	} RBGState_t;
	typedef RBGState_t RBGPipeline_t [4];
	
	typedef PN_t        NxPND_t[8];
	typedef NxPND_t     PNPipe_t [5];
	
	typedef bit [31: 0] NxCHD_t[4];
	typedef NxCHD_t     CHPipe_t [2];
	
	typedef PN_t        RxPND_t[2];
	typedef RxPND_t     RPNPipe_t [5];
	
	typedef CT_t        RxCTD_t[2];
	typedef RxCTD_t     RCTPipe_t [4];
	
	function PN_t PNData(input PNCNx_t PNC, input bit CHSZ, input bit [2:0] CHCN, input bit [15:0] DW);
		PN_t res;
		
		res = '0;

		res.VF = DW[11] & ~PNC.NxCNSM; 
		res.HF = DW[10] & ~PNC.NxCNSM; 
		res.PR = PNC.NxSPR; 
		res.CC = PNC.NxSCC;
		case ({CHSZ,|CHCN})
			2'b00: begin 
				res.PALN = {PNC.NxSPLT,DW[15:12]};
				res.CHRN = {PNC.NxSCN[4:2],(PNC.NxSCN[1:0] & {2{~PNC.NxCNSM}}) | (DW[11:10] & {2{PNC.NxCNSM}}),DW[9:0]};
			end
			2'b01: begin 
				res.PALN = {DW[14:12],4'b0000};
				res.CHRN = {PNC.NxSCN[4:2],(PNC.NxSCN[1:0] & {2{~PNC.NxCNSM}}) | (DW[11:10] & {2{PNC.NxCNSM}}),DW[9:0]};
			end
			2'b10: begin 
				res.PALN = {PNC.NxSPLT,DW[15:12]};
				res.CHRN = {PNC.NxSCN[4],(PNC.NxSCN[3:2] & {2{~PNC.NxCNSM}}) | (DW[11:10] & {2{PNC.NxCNSM}}),DW[9:0],PNC.NxSCN[1:0]};
			end
			2'b11: begin 
				res.PALN = {DW[14:12],4'b0000};
				res.CHRN = {PNC.NxSCN[4],(PNC.NxSCN[3:2] & {2{~PNC.NxCNSM}}) | (DW[11:10] & {2{PNC.NxCNSM}}),DW[9:0],PNC.NxSCN[1:0]};
			end
		endcase
		
		return res;
	endfunction
	
	//Normal scroll screen
	
	function bit [19:1] NxPNAddr(input bit [1:0] NxPN_CNT, input bit [10:0] NxOFFX, input bit [10:0] NxOFFY,
	                             input bit [8:6] NxMP, input bit [5:0] NxMPn[4], 
										  input bit [1:0] NxPLSZ, input bit NxCHSZ, input bit NxPNB, input bit NxZMHF, input bit NxZMQT);
		bit  [19: 1] addr;
		bit  [ 1: 0] ZM_MASK;
		bit  [10: 0] OFFX;
		bit  [ 8: 0] map_addr;
		
		ZM_MASK = {NxZMQT,NxZMQT|NxZMHF};
		OFFX = NxOFFX + {NxPN_CNT&ZM_MASK,3'b000};
		case (NxPLSZ)
			2'b00: map_addr = {NxMP,NxMPn[{NxOFFY[ 9],OFFX[ 9]}][5:0]};
			2'b01: map_addr = {NxMP,NxMPn[{NxOFFY[ 9],OFFX[10]}][5:1],OFFX[9]};
			2'b10,
			2'b11: map_addr = {NxMP,NxMPn[{NxOFFY[10],OFFX[10]}][5:2],NxOFFY[9],OFFX[9]};
		endcase
		case ({NxPNB,NxCHSZ})
			2'b00: addr = {map_addr[5:0],NxOFFY[8:3],OFFX[8:3],1'b0};
			2'b01: addr = {map_addr[7:0],NxOFFY[8:4],OFFX[8:4],1'b0};
			2'b10: addr = {map_addr[6:0],NxOFFY[8:3],OFFX[8:3]};
			2'b11: addr = {map_addr[8:0],NxOFFY[8:4],OFFX[8:4]};
		endcase
	
		return addr;
	endfunction
	
	function bit [19:1] NxCHAddr(input PN_t NxPN[4], input bit [2:0] NxCH_CNT, input bit [10:0] NxOFFX, input bit [10:0] NxOFFY, 
	                             input bit [2:0] NxCHCN, input bit NxCHSZ, input bit NxZMHF, input bit NxZMQT);
		bit  [19: 1] addr;
		bit  [ 1: 0] ZM_MASK;
		PN_t         PN;
		bit  [10: 0] OFFX;
		bit  [ 4: 0] cell_offs;
		bit  [ 3: 0] x_offs;
		bit  [ 3: 0] y_offs;
		bit  [ 2: 0] ch_cnt;
		
		ZM_MASK = {NxZMQT,NxZMQT|NxZMHF};
		case (NxCHCN)
			3'b000:  PN = NxPN[      NxCH_CNT[1:0]&ZM_MASK[1:0] ];	//4bits/dot, 16 colors
			3'b001:  PN = NxPN[{1'b0,NxCH_CNT[1:1]&ZM_MASK[0:0]}];	//8bits/dot, 256 colors
			default: PN = NxPN[0];
		endcase
		
		case (NxCHCN)
			3'b000:  OFFX = NxOFFX + {     NxCH_CNT[1:0]&ZM_MASK[1:0],3'b000};
			3'b001:  OFFX = NxOFFX + {1'b0,NxCH_CNT[1:1]&ZM_MASK[0:0],3'b000};
			default: OFFX = NxOFFX;
		endcase

		x_offs =   OFFX[3:0] ^ {4{PN.HF}};
		y_offs = NxOFFY[3:0] ^ {4{PN.VF}};
		ch_cnt = NxCH_CNT[2:0] ^ {3{PN.HF}};
		
		case (NxCHSZ)
			1'b0: cell_offs = {      1'b0,     1'b0,y_offs[2:0] };
			1'b1: cell_offs = { y_offs[3],x_offs[3],y_offs[2:0] };
		endcase
		case (NxCHCN)
			3'b000: addr = {PN.CHRN[14:0],4'b0000} + {13'b000000000000,cell_offs[4:0],1'b0   };									//4bits/dot, 16 colors
			3'b001: addr = {PN.CHRN[14:0],4'b0000} + {12'b00000000000, cell_offs[4:0],2'b00  } + {ch_cnt[0:0],1'b0};		//8bits/dot, 256 colors
			3'b010,
			3'b011: addr = {PN.CHRN[14:0],4'b0000} + {11'b0000000000,  cell_offs[4:0],3'b000 } + {ch_cnt[1:0],1'b0};		//16bits/dot, 2048/32768 colors
			3'b100: addr = {PN.CHRN[14:0],4'b0000} + {10'b000000000,   cell_offs[4:0],4'b0000} + {ch_cnt[2:0],1'b0};		//32bits/dot, 16M colors
			default: addr = '0;
		endcase
	
		return addr;
	endfunction
	
	function bit [19:1] NxCHAddr2(input PN_t NxPN[2], input bit [2:0] NxCH_CNT, input bit [10:0] NxOFFX, input bit [10:0] NxOFFY, 
	                             input bit [2:0] NxCHCN, input bit NxCHSZ, input bit NxZMHF, input bit NxZMQT);
		bit  [19: 1] addr;
		PN_t         PN;
		bit  [10: 0] OFFX;
		bit  [ 4: 0] cell_offs;
		bit  [ 3: 0] x_offs;
		bit  [ 3: 0] y_offs;
		bit  [ 2: 0] ch_cnt;
		
		case (NxCHCN)
			3'b000:  PN = NxPN[0];	//4bits/dot, 16 colors
			3'b001:  PN = NxPN[NxCH_CNT[0]];	//8bits/dot, 256 colors
			default: PN = NxPN[0];
		endcase
		
		case (NxCHCN)
			3'b000:  OFFX = NxOFFX + {NxZMHF&NxCH_CNT[0],3'b000};
			3'b001:  OFFX = NxOFFX + {NxZMHF&NxCH_CNT[1],3'b000};
			default: OFFX = NxOFFX;
		endcase

		x_offs =   OFFX[3:0] ^ {4{PN.HF}};
		y_offs = NxOFFY[3:0] ^ {4{PN.VF}};
		ch_cnt = NxCH_CNT[2:0] ^ {3{PN.HF}};
		
		case (NxCHSZ)
			1'b0: cell_offs = {      1'b0,     1'b0,y_offs[2:0] };
			1'b1: cell_offs = { y_offs[3],x_offs[3],y_offs[2:0] };
		endcase
		case (NxCHCN)
			3'b000: addr = {PN.CHRN[14:0],4'b0000} + {13'b000000000000,cell_offs[4:0],1'b0   };									//4bits/dot, 16 colors
			3'b001: addr = {PN.CHRN[14:0],4'b0000} + {12'b00000000000, cell_offs[4:0],2'b00  } + {ch_cnt[0:0],1'b0};		//8bits/dot, 256 colors
			3'b010,
			3'b011: addr = {PN.CHRN[14:0],4'b0000} + {11'b0000000000,  cell_offs[4:0],3'b000 } + {ch_cnt[1:0],1'b0};		//16bits/dot, 2048/32768 colors
			3'b100: addr = {PN.CHRN[14:0],4'b0000} + {10'b000000000,   cell_offs[4:0],4'b0000} + {ch_cnt[2:0],1'b0};		//32bits/dot, 16M colors
			default: addr = '0;
		endcase
	
		return addr;
	endfunction
	
	function bit [19:1] NxBMAddr(input bit [2:0] NxMP, input bit [2:0] NxCH_CNT, input bit [2:0] NxBM_CNT, input bit [10:0] NxOFFX, input bit [10:0] NxOFFY, 
	                             input bit [2:0] NxCHCN, input bit [1:0] NxBMSZ, input bit NxZMHF, input bit NxZMQT);
		bit   [19:1] addr;
		bit   [15:0] offs;

		case (NxBMSZ)
			2'b00: offs = {2'b00,NxOFFY[7:0],NxOFFX[8:3]};	//512x256 dots
			2'b01: offs = {1'b0, NxOFFY[8:0],NxOFFX[8:3]};	//512x512 dots
			2'b10: offs = {      NxOFFY[7:0],NxOFFX[9:3]};	//1024x256 dots
			2'b11: offs = {      NxOFFY[8:0],NxOFFX[9:3]};	//1024x512 dots
		endcase
		
		case (NxCHCN)
			3'b000: addr = {NxMP,16'b0000000000000000} + {offs[15:0],1'b0   } + {NxBM_CNT[1:0],1'b0};	//4bits/dot, 16 colors
			3'b001: addr = {NxMP,16'b0000000000000000} + {offs[15:0],2'b00  } + {NxBM_CNT[1:0],1'b0};	//8bits/dot, 256 colors
			3'b010,
			3'b011: addr = {NxMP,16'b0000000000000000} + {offs[15:0],3'b000 } + {NxBM_CNT[1:0],1'b0};	//16bits/dot, 2048/32768 colors
			3'b100: addr = {NxMP,16'b0000000000000000} + {offs[14:0],4'b0000} + {NxBM_CNT,1'b0};	//32bits/dot, 16M colors
			default: addr = '0;
		endcase
	
		return addr;
	endfunction
	
	function bit [19:1] NxLSAddr(input bit [18:1] NxLSTA, input bit [12:2] TBL_OFFS, input bit [3:2] VAL_OFFS);
		return {NxLSTA,1'b0} + {TBL_OFFS,1'b0} + {VAL_OFFS,1'b0};
	endfunction
	
	function bit [4:2] NxLSTblSize(input bit LSCX, input bit LSCY, input bit LZMX, input bit DI);
		bit [2:0] res;
		
		case ({LZMX,LSCY,LSCX})
			3'b000: res = 3'd0;
			3'b001: res = 3'd1;
			3'b010: res = 3'd1;
			3'b011: res = 3'd2;
			3'b100: res = 3'd1;
			3'b101: res = 3'd2;
			3'b110: res = 3'd2;
			3'b111: res = 3'd3;
		endcase
		return (res<<DI);
	endfunction
	
	function bit [2:0] NxLSSMask(input bit [1:0] NxLSS, input bit DDI);
		bit [2:0] mask;
		
		case (NxLSS)
			2'b00: mask = 3'b000;
			2'b01: mask = 3'b001;
			2'b10: mask = 3'b011;
			2'b11: mask = 3'b111;
		endcase
		return (mask>>DDI);
	endfunction
	
	//Rotation scroll screen
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
		bit [11: 0] UNUSED;
		bit [ 3: 0] INT;
		bit [ 9: 0] FRAC;
		bit [ 5: 0] UNUSED2;
	} MatrParam_t;
	parameter MatrParam_t MATR_NULL = {12'h000,4'h0,10'h000,6'h00};
	
	typedef struct packed
	{
		bit [ 1: 0] UNUSED;
		bit [13: 0] INT;
	} ScrnCoord_t;
	parameter ScrnCoord_t SCNCRD_NULL = {2'h0,14'h0000};
	
	typedef struct packed
	{
		bit [ 1: 0] UNUSED;
		bit [13: 0] INT;
		bit [ 9: 0] FRAC;
		bit [ 5: 0] UNUSED2;
	} Shift_t;
	parameter Shift_t SHIFT_NULL = {2'h0,14'h0000,10'h000,6'h00};
	
	typedef struct packed
	{
		bit [ 7: 0] UNUSED;
		bit [ 7: 0] INT;
		bit [15: 0] FRAC;
	} Scalling_t;
	parameter Scalling_t SCALL_NULL = {8'h00,8'h00,16'h0000};

	typedef struct packed
	{
		bit [15: 0] INT;
		bit [ 9: 0] FRAC;
		bit [ 5: 0] UNUSED;
	} TblAddr_t;
	parameter TblAddr_t TBLADR_NULL = {16'h0000,10'h000,6'h00};
	
	typedef struct packed
	{
		bit [ 5: 0] UNUSED;
		bit [ 9: 0] INT;
		bit [ 9: 0] FRAC;
		bit [ 5: 0] UNUSED2;
	} AddrInc_t;
	parameter AddrInc_t ADRINC_NULL = {6'h00,10'h000,10'h000,6'h00};
	
	typedef struct packed
	{
		ScrnStart_t Xst;		//00
		ScrnStart_t Yst;		//04
		ScrnStart_t Zst;		//08
		ScrnInc_t   DXst;		//0C
		ScrnInc_t   DYst;		//10
		ScrnInc_t   DX;		//14
		ScrnInc_t   DY;		//18
		MatrParam_t A;			//1C
		MatrParam_t B;			//20
		MatrParam_t C;			//24
		MatrParam_t D;			//28
		MatrParam_t E;			//2C
		MatrParam_t F;			//30
		ScrnCoord_t PX;		//34
		ScrnCoord_t PY;		//36
		ScrnCoord_t PZ;		//38
		bit [15: 0] UNUSED;	//3A
		ScrnCoord_t CX;		//3C
		ScrnCoord_t CY;		//3E
		ScrnCoord_t CZ;		//40
		bit [15: 0] UNUSED2;	//42
		Shift_t     MX;		//44
		Shift_t     MY;		//48
		Scalling_t  KX;		//4C
		Scalling_t  KY;		//50
		TblAddr_t   KAst;		//54
		AddrInc_t   DKAst;	//58
		AddrInc_t   DKAx;		//5C
	} RotTbl_t;
	parameter RotTbl_t ROT_NULL = {SCNST_NULL, SCNST_NULL, SCNST_NULL,
	                               SCNINC_NULL, SCNINC_NULL, SCNINC_NULL, SCNINC_NULL,
											 MATR_NULL, MATR_NULL, MATR_NULL, MATR_NULL, MATR_NULL, MATR_NULL,
											 SCNCRD_NULL, SCNCRD_NULL, SCNCRD_NULL,
											 SCNCRD_NULL, SCNCRD_NULL, SCNCRD_NULL, 16'h0000,
											 SHIFT_NULL, SHIFT_NULL, 
											 SCALL_NULL, SCALL_NULL,
											 TBLADR_NULL, ADRINC_NULL, ADRINC_NULL};
	
	typedef struct packed
	{
		bit [15: 0] INT;
		bit [15: 0] FRAC;
	} RotCoord_t;
	parameter bit [31:0] RC_NULL = {16'h0000,16'h0000};
	parameter bit [31:0] RC_ONE = {16'h0001,16'h0000};
	
	typedef struct packed
	{
		bit [18: 0] INT;
		bit [15: 0] FRAC;
	} RotAddr_t;
	
	function RotCoord_t ScrnStartToRC(ScrnStart_t P);
		return { {{3{P.INT[12]}},P.INT}, {P.FRAC,6'b000000} };
	endfunction
	
	function RotCoord_t ScrnIncToRC(ScrnInc_t P);
		return { {{13{P.INT[2]}},P.INT}, {P.FRAC,6'b000000} };
	endfunction
	
	function RotCoord_t MatrParamToRC(MatrParam_t P);
		return { {{12{P.INT[3]}},P.INT}, {P.FRAC,6'b000000} };
	endfunction
	
	function RotCoord_t ScrnCoordToRC(ScrnCoord_t P);
		return { {{2{P.INT[13]}},P.INT}, {16'b0000000000000000} };
	endfunction
	
	function RotCoord_t ShiftToRC(Shift_t P);
		return { {{2{P.INT[13]}},P.INT}, {P.FRAC,6'b000000} };
	endfunction
	
	function RotCoord_t ScallingToRC(Scalling_t P);
		return { {{8{P.INT[7]}},P.INT}, {P.FRAC} };
	endfunction
	
	function RotCoord_t TblAddrToRC(TblAddr_t P);
		return {P.INT,P.FRAC,6'b000000};
	endfunction
	
	function RotCoord_t AddrIncToRC(AddrInc_t P);
		return {{6{P.INT[9]}},P.INT,P.FRAC,6'b000000};
	endfunction
	
	function RotAddr_t AddrIncToRA(AddrInc_t P);
		return {{9{P.INT[9]}},P.INT,P.FRAC,6'b000000};
	endfunction
	
	function RotCoord_t MultRC(input RotCoord_t a, input RotCoord_t b);
		bit [63:0] temp;
		temp = $signed(a) * $signed(b);
		return temp[47:16];
	endfunction
	
	function bit [29:0] MultFI(input bit [29:0] a, input bit [29:16] b);
		bit [43:0] temp;
		temp = $signed(a) * $signed(b);
		return {temp[43],temp[28:0]};
	endfunction
	
	function bit [19:1] RxPNAddr(input bit [11:0] RxOFFX, input bit [11:0] RxOFFY,
	                             input bit [8:6] RxMP, input bit [5:0] RxMPn[16], 
										  input bit [1:0] RxPLSZ, input bit RxCHSZ, input bit RxPNB);
		bit [19: 1] addr;
		bit [ 8: 0] map_addr;
		
		case (RxPLSZ)
			2'b00: map_addr = {RxMP,RxMPn[{RxOFFY[10: 9],RxOFFX[10: 9]}][5:0]          };
			2'b01: map_addr = {RxMP,RxMPn[{RxOFFY[10: 9],RxOFFX[11:10]}][5:1],RxOFFX[9]};
			2'b10,
			2'b11: map_addr = {RxMP,RxMPn[{RxOFFY[11:10],RxOFFX[11:10]}][5:2],RxOFFY[9],RxOFFX[9]};
		endcase
		case ({RxPNB,RxCHSZ})
			2'b00: addr = {map_addr[5:0],RxOFFY[8:3],RxOFFX[8:3],1'b0};
			2'b01: addr = {map_addr[7:0],RxOFFY[8:4],RxOFFX[8:4],1'b0};
			2'b10: addr = {map_addr[6:0],RxOFFY[8:3],RxOFFX[8:3]};
			2'b11: addr = {map_addr[8:0],RxOFFY[8:4],RxOFFX[8:4]};
		endcase
	
		return addr;
	endfunction
	
	function bit [19:1] RxCHAddr(input PN_t RxPNx, input bit [11:0] RxOFFX, input bit [11:0] RxOFFY, input bit [2:0] RxCHCN, input bit RxCHSZ);
		bit [19: 1] addr;
		bit [ 4: 0] cell_offs;
		bit [ 3: 0] x_offs;
		bit [ 3: 0] y_offs;

		x_offs = RxOFFX[3:0] ^ {4{RxPNx.HF}};
		y_offs = RxOFFY[3:0] ^ {4{RxPNx.VF}};
		
		case (RxCHSZ)
			1'b0: cell_offs = {      1'b0,     1'b0,y_offs[2:0] };
			1'b1: cell_offs = { y_offs[3],x_offs[3],y_offs[2:0] };
		endcase
		case (RxCHCN)
			3'b000: addr = {RxPNx.CHRN[14:0],4'b0000} + {13'b000000000000,cell_offs[4:0],            1'b0};	//4bits/dot, 16 colors
			3'b001: addr = {RxPNx.CHRN[14:0],4'b0000} + {12'b00000000000, cell_offs[4:0],x_offs[2:2],1'b0};	//8bits/dot, 256 colors
			3'b010,
			3'b011: addr = {RxPNx.CHRN[14:0],4'b0000} + {11'b0000000000,  cell_offs[4:0],x_offs[2:1],1'b0};	//16bits/dot, 2048/32768 colors
			3'b100: addr = {RxPNx.CHRN[14:0],4'b0000} + {10'b000000000,   cell_offs[4:0],x_offs[2:0],1'b0};	//32bits/dot, 16M colors
			default: addr = '0;
		endcase
	
		return addr;
	endfunction
	
	function bit [19:1] RxBMAddr(input bit [2:0] RxMP, input bit [11:0] RxOFFX, input bit [11:0] RxOFFY, input bit [2:0] RxCHCN, input bit RxBMSZ);
		bit   [19:1] addr;
		bit   [17:0] offs;
		
		case (RxBMSZ)
			1'b0: offs = {1'b0,RxOFFY[7:0],RxOFFX[8:0]};	//512x256 dots
			1'b1: offs = {     RxOFFY[8:0],RxOFFX[8:0]};	//512x512 dots
		endcase
		
		case (RxCHCN)
			3'b000: addr = {RxMP,16'b0000000000000000} + {offs[17:3],1'b0};	//4bits/dot, 16 colors
			3'b001: addr = {RxMP,16'b0000000000000000} + {offs[17:2],1'b0};	//8bits/dot, 256 colors
			3'b010,
			3'b011: addr = {RxMP,16'b0000000000000000} + {offs[17:1],1'b0};	//16bits/dot, 2048/32768 colors
			3'b100: addr = {RxMP,16'b0000000000000000} + {offs[17:0],1'b0};	//32bits/dot, 16M colors
			default: addr = '0;
		endcase
	
		return addr;
	endfunction
	
	function bit [19:1] RxRPAddr(input bit [18:1] RPTA, input bit [7:2] RP_POS);
		return ({RPTA,1'b0} & ~19'h00040) + {RP_POS,1'b0};
	endfunction
	
	function bit [19:1] RxCTAddr(input bit [15:0] RxKAst, input bit [18:0] RxKA, input bit [2:0] RxKTAOS, input bit RxKDBS);
		bit   [19:1] addr;
		bit   [18:0] offs;
		
		offs = {RxKTAOS,RxKAst} + RxKA;
		
		case (RxKDBS)
			1'b0: addr = {offs[17:0],1'b0};	//2 words
			1'b1: addr = {offs[18:0]     };	//1 word
		endcase
	
		return addr;
	endfunction
	
	function CT_t CTData(input bit [1:0] RxKMD, input bit RxKDBS, input bit [31:0] DW);
		CT_t CTD;
		
		CTD.TP = DW[31];
		CTD.LCSD = DW[30:24] & {7{~RxKDBS}};
		case ({&RxKMD,RxKDBS})
			2'b00: CTD.INT = { { 8{DW[23]}},DW[23:16] }; //mode 0-2, 2 words
			2'b01: CTD.INT = { {11{DW[30]}},DW[30:26] }; //mode 0-2, 1 word
			2'b10: CTD.INT = {              DW[23: 8] }; //mode 3, 2 words
			2'b11: CTD.INT = { { 3{DW[30]}},DW[30:18] }; //mode 3, 1 word
		endcase
		case ({&RxKMD,RxKDBS})
			2'b00: CTD.FRAC = { DW[15: 0]                  };//mode 0-2, 2 words
			2'b01: CTD.FRAC = { DW[25:16],6'b000000        };//mode 0-2, 1 word
			2'b10: CTD.FRAC = { DW[ 7: 0],8'b00000000      };//mode 3, 2 words
			2'b11: CTD.FRAC = { DW[17:16],12'b000000000000 };//mode 3, 1 word
		endcase
		
		return CTD;
	endfunction
	
	function bit RxScreenOver(input bit [1:0] RxOVR, input bit [15:0] RxOFFX, input bit [15:0] RxOFFY, input bit [1:0] RxPLSZ, input bit RxBMSZ, input bit RxBMEN);
		bit   [15:0] mx,my;
		bit          res;
				
		if (RxOVR == 2'b11) begin 
			mx = 16'b1111111000000000; my = 16'b1111111000000000; //512x512
		end else if (!RxBMEN)
			case (RxPLSZ)
				2'b00: begin mx = 16'b1111100000000000; my = 16'b1111100000000000; end //2048x2048
				2'b01: begin mx = 16'b1111000000000000; my = 16'b1111100000000000; end //4096x2048
				2'b10,
				2'b11: begin mx = 16'b1111000000000000; my = 16'b1111000000000000; end //4096x4096
			endcase
		else  
			case (RxBMSZ)
				1'b0: begin mx = 16'b1111111000000000; my = 16'b1111111100000000; end //512x256
				1'b1: begin mx = 16'b1111111000000000; my = 16'b1111111000000000; end //512x512
			endcase
		
		case (RxOVR)
			2'b00: res = 0;
			default: res = |(RxOFFX & mx) | |(RxOFFY & my);
		endcase
	
		return res;
	endfunction
	
	//Sprite data
	typedef struct packed
	{
		bit         P;
		bit         TP;
		bit         WN;
		bit         SD;
		bit [ 2: 0] PR;
		bit [ 2: 0] CC;
		bit [23: 0] DC;
	} SpriteDotData_t;
	parameter SpriteDotData_t SDD_NULL = {1'b0,1'b0,1'b0,3'b000,3'b000,15'h0000};
	
	function SpriteDotData_t SpriteData(input SPCTL_t SPCTL, input bit [15:0] DATA, input bit TPSDSL);
		SpriteDotData_t SDD;
		bit          MSB;
		bit          NSD;
		bit          MSD;
		bit          TSD;
		bit          TPEN;
		bit          TP,RGB_TP,PAL_TP;
		bit    [2:0] PR;
		bit    [2:0] CC;
		bit   [10:0] DC;
		bit   [23:0] RGB888;
	
		case (SPCTL.SPTYPE)
		4'h0: begin MSB = 1'b0    ; NSD = &DATA[10:1] & ~DATA[0]; TPEN = 0;        PR = {1'b0    ,DATA[15],DATA[14]}; CC = {DATA[13],DATA[12],DATA[11]}; DC = {         DATA[10:0]}; end
		4'h1: begin MSB = 1'b0    ; NSD = &DATA[10:1] & ~DATA[0]; TPEN = 0;        PR = {DATA[15],DATA[14],DATA[13]}; CC = {1'b0    ,DATA[12],DATA[11]}; DC = {         DATA[10:0]}; end
		4'h2: begin MSB = DATA[15]; NSD = &DATA[10:1] & ~DATA[0]; TPEN = DATA[15]; PR = {1'b0    ,1'b0    ,DATA[14]}; CC = {DATA[13],DATA[12],DATA[11]}; DC = {         DATA[10:0]}; end
		4'h3: begin MSB = DATA[15]; NSD = &DATA[10:1] & ~DATA[0]; TPEN = DATA[15]; PR = {1'b0    ,DATA[14],DATA[13]}; CC = {1'b0    ,DATA[12],DATA[11]}; DC = {         DATA[10:0]}; end
		4'h4: begin MSB = DATA[15]; NSD = &DATA[ 9:1] & ~DATA[0]; TPEN = DATA[15]; PR = {1'b0    ,DATA[14],DATA[13]}; CC = {DATA[12],DATA[11],DATA[10]}; DC = {1'b0    ,DATA[ 9:0]}; end
		4'h5: begin MSB = DATA[15]; NSD = &DATA[10:1] & ~DATA[0]; TPEN = DATA[15]; PR = {DATA[14],DATA[13],DATA[12]}; CC = {1'b0    ,1'b0    ,DATA[11]}; DC = {         DATA[10:0]}; end
		4'h6: begin MSB = DATA[15]; NSD = &DATA[ 9:1] & ~DATA[0]; TPEN = DATA[15]; PR = {DATA[14],DATA[13],DATA[12]}; CC = {1'b0    ,DATA[11],DATA[10]}; DC = {1'b0    ,DATA[ 9:0]}; end
		4'h7: begin MSB = DATA[15]; NSD = &DATA[ 8:1] & ~DATA[0]; TPEN = DATA[15]; PR = {DATA[14],DATA[13],DATA[12]}; CC = {DATA[11],DATA[10],DATA[ 9]}; DC = {2'b00   ,DATA[ 8:0]}; end
		4'h8: begin MSB = 1'b0    ; NSD = &DATA[ 6:1] & ~DATA[0]; TPEN = 1;        PR = {1'b0    ,1'b0    ,DATA[ 7]}; CC = {1'b0    ,1'b0    ,1'b0    }; DC = {4'b0000 ,DATA[ 6:0]}; end
		4'h9: begin MSB = 1'b0    ; NSD = &DATA[ 5:1] & ~DATA[0]; TPEN = 1;        PR = {1'b0    ,1'b0    ,DATA[ 7]}; CC = {1'b0    ,1'b0    ,DATA[ 6]}; DC = {5'b00000,DATA[ 5:0]}; end
		4'hA: begin MSB = 1'b0    ; NSD = &DATA[ 5:1] & ~DATA[0]; TPEN = 1;        PR = {1'b0    ,DATA[ 7],DATA[ 6]}; CC = {1'b0    ,1'b0    ,1'b0    }; DC = {5'b00000,DATA[ 5:0]}; end
		4'hB: begin MSB = 1'b0    ; NSD = &DATA[ 5:1] & ~DATA[0]; TPEN = 1;        PR = {1'b0    ,1'b0    ,1'b0    }; CC = {1'b0    ,DATA[ 7],DATA[ 6]}; DC = {5'b00000,DATA[ 5:0]}; end
		4'hC: begin MSB = 1'b0    ; NSD = &DATA[ 7:1] & ~DATA[0]; TPEN = 1;        PR = {1'b0    ,1'b0    ,DATA[ 7]}; CC = {1'b0    ,1'b0    ,1'b0    }; DC = {3'b000  ,DATA[ 7:0]}; end
		4'hD: begin MSB = 1'b0    ; NSD = &DATA[ 7:1] & ~DATA[0]; TPEN = 1;        PR = {1'b0    ,1'b0    ,DATA[ 7]}; CC = {1'b0    ,1'b0    ,DATA[ 6]}; DC = {3'b000  ,DATA[ 7:0]}; end
		4'hE: begin MSB = 1'b0    ; NSD = &DATA[ 7:1] & ~DATA[0]; TPEN = 1;        PR = {1'b0    ,DATA[ 7],DATA[ 6]}; CC = {1'b0    ,1'b0    ,1'b0    }; DC = {3'b000  ,DATA[ 7:0]}; end
		4'hF: begin MSB = 1'b0    ; NSD = &DATA[ 7:1] & ~DATA[0]; TPEN = 1;        PR = {1'b0    ,1'b0    ,1'b0    }; CC = {1'b0    ,DATA[ 7],DATA[ 6]}; DC = {3'b000  ,DATA[ 7:0]}; end
		endcase
		
		TP = ~|DATA[14:0];
		
		RGB888 = {DATA[14:10],3'b000,DATA[9:5],3'b000,DATA[4:0],3'b000};
		RGB_TP = TP & TPEN & SPCTL.SPWINEN;
		
		MSD = MSB & ~TP &          ~SPCTL.SPWINEN;
		TSD = MSB &  TP & TPSDSL & ~SPCTL.SPWINEN;
		PAL_TP = TP | NSD | TSD;
		
		if (SPCTL.SPCLMD && DATA[15])
			SDD = {1'b0, RGB_TP, 1'b0,        1'b0, 3'h0, 3'h0,        RGB888};
		else
			SDD = {1'b1, PAL_TP,  MSB, NSD|MSD|TSD,   PR,   CC, {13'h0000,DC}};

		return SDD;
	endfunction
	
	
	//Dot data
	typedef bit [7:0] CellDotsColor_t [8];
	
	typedef struct packed
	{
		bit         PR;	//Priority flag
		bit         CC;	//Color calculation flag
		bit         TPON;	//Transparent code enabled
		bit [ 6: 0] PALN;	//Palette number
	} CellParam_t;
	parameter CellParam_t CDP_NULL = {1'b0,1'b0,1'b0,7'h00};
	
	typedef struct packed
	{
		bit         PR;	//Priority flag
		bit         CC;	//Color calculation flag
		bit         P;		//Palette format
		bit         TP;	//Transparent flag
		bit [23: 0] DC;	//Dot color
	} DotData_t;
	parameter DotData_t DD_NULL = {1'b0,1'b0,1'b0,1'b0,24'h000000};
	
	typedef DotData_t DotsBuffer_t [16];
	
	function DotData_t MakeDotData(input bit [31:0] DCC, input CellParam_t CDP, input bit [2:0] CHCN);
		bit [23: 0] DC;
		bit [ 2: 0] NTP;
		bit         P;
		bit         TP;
		
		case (CHCN)
			3'b000:  DC = {13'h0000,CDP.PALN     ,DCC[3:0]};						//Palette 4bits/dot, 16 colors
			3'b001:  DC = {13'h0000,CDP.PALN[6:4],DCC[7:0]};						//Palette 8bits/dot, 256 colors
			3'b010:  DC = {13'h0000,DCC[10:0]};											//Palette 16bits/dot, 2048 colors
			3'b011:  DC = {DCC[14:10],3'b000,DCC[9:5],3'b000,DCC[4:0],3'b000};//RGB 16bits/dot, 32768 colors
			default: DC = DCC[23:0];														//RGB 32bits/dot, 16M colors
		endcase

		NTP = {|DCC[10:8],|DCC[7:4],|DCC[3:0]};
		case (CHCN)
			3'b000:  begin TP = ~(|NTP[0:0] | CDP.TPON); P = 1; end	//Palette 4bits/dot, 16 colors
			3'b001:  begin TP = ~(|NTP[1:0] | CDP.TPON); P = 1; end	//Palette 8bits/dot, 256 colors
			3'b010:  begin TP = ~(|NTP[2:0] | CDP.TPON); P = 1; end	//Palette 16bits/dot, 2048 colors
			3'b011:  begin TP = ~(DCC[15]   | CDP.TPON); P = 0; end	//RGB 16bits/dot, 32768 colors
			default: begin TP = ~(DCC[31]   | CDP.TPON); P = 0; end	//RGB 32bits/dot, 16M colors
		endcase
		
		return {CDP.PR, CDP.CC, P, TP, DC};
	endfunction
	
	typedef struct packed
	{
		bit [ 2: 0] CAOS;
		bit         CCEN;
		bit         CCM3;
		bit [ 4: 0] CCRT;
		bit         COEN;
		bit         COSL;
		bit         SDEN;
		bit         LCEN;
		bit         P;
		bit [23: 0] DC;
	} ScreenDot_t;
	parameter ScreenDot_t SD_NULL = {3'b000,1'b0,1'b0,5'b00000,1'b0,1'b0,1'b0,1'b0,1'b0,24'h000000};
	

	//Color calculation
	typedef struct packed
	{
		bit [ 7: 0] B;
		bit [ 7: 0] G;
		bit [ 7: 0] R;
	} DotColor_t;
	parameter DotColor_t DC_NULL = {8'h00,8'h00,8'h00};
	
	typedef struct packed
	{
		bit         CC;
		bit [ 7: 0] B;
		bit [ 7: 0] G;
		bit [ 7: 0] R;
	} Color_t;
	parameter Color_t C_NULL = {1'b0,8'h00,8'h00,8'h00};
	
	function bit [23:0] Color555To888(input bit [15:0] DW);
		return {DW[14:10],3'b000,DW[9:5],3'b000,DW[4:0],3'b000}; 
	endfunction
	
	function bit [7:0] ColorCalcRatio(input bit [7:0] CA, input bit [7:0] CB, input bit [5:0] RA, input bit [5:0] RB);
		bit [13:0] S;
		
		S = (CA * RA) + (CB * RB);
		return (S[12:5] | {8{S[13]}}); 
	endfunction
	
	function DotColor_t ColorCalc(input DotColor_t CFST, input DotColor_t CSEC, input bit [4:0] CCRT, input bit CCEN, input bit CCMD);
		DotColor_t TEMP;
		
		TEMP.R = ColorCalcRatio(CFST.R, CSEC.R, !CCMD ? {1'b0,~CCRT} : 6'h20, !CCMD ? {1'b0,CCRT}+1 : 6'h20);
		TEMP.G = ColorCalcRatio(CFST.G, CSEC.G, !CCMD ? {1'b0,~CCRT} : 6'h20, !CCMD ? {1'b0,CCRT}+1 : 6'h20);
		TEMP.B = ColorCalcRatio(CFST.B, CSEC.B, !CCMD ? {1'b0,~CCRT} : 6'h20, !CCMD ? {1'b0,CCRT}+1 : 6'h20);
		
		return !CCEN ? CFST : TEMP;
	endfunction
	
	function bit [7:0] ColorCalcExtRatio(input bit [7:0] CA, input bit [7:0] CB, input bit [7:0] CC, input bit RTA, input bit RTB);
		bit [7:0] S;
		
		S = (!RTA ? CA : {1'b0,CA[7:1]}) + (!RTA ? 8'h00 : !RTB ? {1'b0,CB[7:1]} : {2'b00,CB[7:2]}) + (!RTA || !RTB ? 8'h00 : {2'b00,CC[7:2]});
		return S; 
	endfunction
	
	function DotColor_t ExtColorCalc(input DotColor_t DCSEC, input bit CCENSEC, input DotColor_t DCTHD, input bit PTHD, input bit CCENTHD, input DotColor_t DCFTH, 
	                                 input bit LCEN, input bit [1:0] CRMD, input bit EXCCEN);
		bit RTSEC,RTTHD;
		DotColor_t TEMP;

		RTSEC = CCENSEC & ~(|CRMD && PTHD) & EXCCEN;
		RTTHD = CCENTHD & LCEN & EXCCEN;
		
		TEMP.R = ColorCalcExtRatio(DCSEC.R, DCTHD.R, DCFTH.R, RTSEC, RTTHD);
		TEMP.G = ColorCalcExtRatio(DCSEC.G, DCTHD.G, DCFTH.G, RTSEC, RTTHD);
		TEMP.B = ColorCalcExtRatio(DCSEC.B, DCTHD.B, DCFTH.B, RTSEC, RTTHD);
		
		return TEMP;
	endfunction
	
	function bit [7:0] ColorOffset(input bit [7:0] C, input bit [8:0] COAx, input bit [8:0] COBx, input bit COEN, input bit COSL);
		bit [8:0] CAS, CBS;

		CAS = $signed({1'b0,C}) + $signed(COAx);
		CBS = $signed({1'b0,C}) + $signed(COBx);
		return !COEN ? C : !COSL ? CAS[7:0] & ~{8{COAx[8]&CAS[8]}} | {8{~COAx[8]&CAS[8]}} : CBS[7:0] & ~{8{COBx[8]&CBS[8]}} | {8{~COBx[8]&CBS[8]}}; 
	endfunction
	
	function bit [7:0] Shadow(input bit [7:0] C, input bit SDEN);
		return SDEN ? {1'b0,C[7:1]} : C;
	endfunction
	
	//
	function bit SFCMatch(input bit SFCS, input SFCODE_t SFCODE, input bit [3:0] CODE);
		bit    [7:0] sfcd;
		bit    [7:0] match;

		sfcd = !SFCS ? SFCODE.SFCDA : SFCODE.SFCDB;
		match = {CODE[3:1] == 3'b111,
		         CODE[3:1] == 3'b110,
		         CODE[3:1] == 3'b101,
		         CODE[3:1] == 3'b100,
		         CODE[3:1] == 3'b011,
		         CODE[3:1] == 3'b010,
		         CODE[3:1] == 3'b001,
		         CODE[3:1] == 3'b000};
	
		return |(match & sfcd);
	endfunction
	
	//Windows
	function bit WinTest(input bit W0HIT, input bit W1HIT, input bit WSHIT, input bit W0E, input bit W1E, input bit SWE, input bit LOG);
		bit    log_and, log_or;

		case ({SWE,W1E,W0E})
		3'b000: begin log_and = 1'b0  & 1'b0  & 1'b0 ; log_or = 1'b0  | 1'b0  | 1'b0 ; end
		3'b001: begin log_and = 1'b1  & 1'b1  & W0HIT; log_or = 1'b0  | 1'b0  | W0HIT; end
		3'b010: begin log_and = 1'b1  & W1HIT & 1'b1 ; log_or = 1'b0  | W1HIT | 1'b0 ; end
		3'b011: begin log_and = 1'b1  & W1HIT & W0HIT; log_or = 1'b0  | W1HIT | W0HIT; end
		3'b100: begin log_and = WSHIT & 1'b1  & 1'b1 ; log_or = WSHIT | 1'b0  | 1'b0 ; end
		3'b101: begin log_and = WSHIT & 1'b1  & W0HIT; log_or = WSHIT | 1'b0  | W0HIT; end
		3'b110: begin log_and = WSHIT & W1HIT & 1'b1 ; log_or = WSHIT | W1HIT | 1'b0 ; end
		3'b111: begin log_and = WSHIT & W1HIT & W0HIT; log_or = WSHIT | W1HIT | W0HIT; end
		endcase
	
		return LOG ? log_and : log_or;
	endfunction
	
	function bit [19:1] LWAddr(input bit [18:1] WxLWTA, input bit [9:2] LW_OFFS);
		return {WxLWTA,1'b0} + {LW_OFFS,1'b0};
	endfunction
	
	//
	function bit [19:1] BSAddr(input bit [18:0] BKTA, input bit [8:0] LINE, input bit BKCLMD);
		return BKTA + (LINE & {9{BKCLMD}});
	endfunction
	
	function bit [19:1] LNAddr(input bit [18:0] LCTA, input bit [8:0] LINE, input bit LCCLMD);
		return LCTA + (LINE & {9{LCCLMD}});
	endfunction
	
endpackage

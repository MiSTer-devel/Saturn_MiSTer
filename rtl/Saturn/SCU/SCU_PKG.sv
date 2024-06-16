package SCU_PKG;

	typedef bit [31:0] DxR_t;	//R/W,25FE0000,25FE0020,25FE0040
	parameter bit [31:0] DxR_WMASK = 32'h07FFFFFF;
	parameter bit [31:0] DxR_RMASK = 32'h07FFFFFF;
	
	typedef bit [31:0] DxW_t;	//R/W,25FE0004,25FE0024,25FE0044
	parameter bit [31:0] DxW_WMASK = 32'h07FFFFFF;
	parameter bit [31:0] DxW_RMASK = 32'h07FFFFFF;
	
	typedef bit [31:0] DxC_t;	//R/W,25FE0008,25FE0028,25FE0048
	parameter bit [31:0] D0C_WMASK = 32'h000FFFFF;
	parameter bit [31:0] D0C_RMASK = 32'h000FFFFF;
	parameter bit [31:0] D12C_WMASK = 32'h00000FFF;
	parameter bit [31:0] D12C_RMASK = 32'h00000FFF;

	typedef struct packed		//W,25FE000C,25FE002C,25FE004C
	{
		bit [22: 0] UNUSED;
		bit         DRA;			//W
		bit [ 4: 0] UNUSED2;
		bit [ 2: 0] DWA;			//W
	} DxAD_t;
	parameter bit [31:0] DxAD_WMASK = 32'h00000107;
	parameter bit [31:0] DxAD_RMASK = 32'h00000000;
	parameter bit [31:0] DxAD_INIT = 32'h00000101;
	
	typedef struct packed		//W,25FE0010,25FE0030,25FE0050
	{
		bit [22: 0] UNUSED;
		bit         EN;			//W
		bit [ 6: 0] UNUSED2;
		bit         GO;			//W
	} DxEN_t;
	parameter bit [31:0] DxEN_WMASK = 32'h00000101;
	parameter bit [31:0] DxEN_RMASK = 32'h00000000;
	parameter bit [31:0] DxEN_INIT = 32'h00000000;
	
	typedef struct packed		//W,25FE0014,25FE0034,25FE0054
	{
		bit [ 6: 0] UNUSED;
		bit         MOD;			//W
		bit [ 6: 0] UNUSED2;
		bit         RUP;			//W
		bit [ 6: 0] UNUSED3;
		bit         WUP;			//W
		bit [ 4: 0] UNUSED4;
		bit [ 2: 0] FT;			//W
	} DxMD_t;
	parameter bit [31:0] DxMD_WMASK = 32'h01010107;
	parameter bit [31:0] DxMD_RMASK = 32'h00000000;
	parameter bit [31:0] DxMD_INIT = 32'h00000007;

	typedef struct packed		//W,25FE0060
	{
		bit [30: 0] UNUSED;
		bit         STOP;			//W
	} DSTP_t;
	parameter bit [31:0] DSTP_WMASK = 32'h00000001;
	parameter bit [31:0] DSTP_RMASK = 32'h00000000;
	parameter bit [31:0] DSTP_INIT = 32'h00000000;
	
	typedef struct packed		//R,25FE007C
	{
		bit [ 8: 0] UNUSED;
		bit         DACSD;		//R
		bit         DACSB;		//R
		bit         DACSA;		//R
		bit [ 1: 0] UNUSED2;
		bit         D1BK;			//R
		bit         D0BK;			//R
		bit [ 1: 0] UNUSED3;
		bit         D2WT;			//R
		bit         D2MV;			//R
		bit [ 1: 0] UNUSED4;
		bit         D1WT;			//R
		bit         D1MV;			//R
		bit [ 1: 0] UNUSED5;
		bit         D0WT;			//R
		bit         D0MV;			//R
		bit [ 1: 0] UNUSED6;
		bit         DDWT;			//R
		bit         DDMV;			//R
	} DSTA_t;
	parameter bit [31:0] DSTA_WMASK = 32'h00000000;
	parameter bit [31:0] DSTA_RMASK = 32'h00733333;
	parameter bit [31:0] DSTA_INIT = 32'h00000000;
	
	typedef struct packed		//R/W,25FE0080
	{
		bit [ 4: 0] UNUSED;
		bit         PR;			//W
		bit         EP;			//W
		bit         UNUSED2;
		bit         T0;			//R
		bit         S;				//R
		bit         Z;				//R
		bit         C;				//R
		bit         V;				//R
		bit         E;				//R
		bit         ES;			//W
		bit         EX;			//R/W
		bit         LE;			//W
		bit [ 6: 0] UNUSED3;
		bit [ 7: 0] P;				//R/W
	} PPAF_t;
	parameter bit [31:0] PPAF_WMASK = 32'h060380FF;
	parameter bit [31:0] PPAF_RMASK = 32'h00FD80FF;
	parameter bit [31:0] PPAF_INIT = 32'h00000000;
	
	typedef bit [31:0] PPD_t;	//W,25FE0084
	parameter bit [31:0] PPD_WMASK = 32'hFFFFFFFF;
	parameter bit [31:0] PPD_RMASK = 32'h00000000;
	
	typedef struct packed		//W,25FE0088
	{
		bit [23: 0] UNUSED;
		bit [ 7: 0] RA;			//W
	} PDA_t;
	parameter bit [31:0] PDA_WMASK = 32'h000000FF;
	parameter bit [31:0] PDA_RMASK = 32'h00000000;
	parameter bit [31:0] PDA_INIT = 32'h00000000;
	
	typedef bit [31:0] PDD_t;	//W/R,25FE008C
	parameter bit [31:0] PDD_WMASK = 32'hFFFFFFFF;
	parameter bit [31:0] PDD_RMASK = 32'hFFFFFFFF;
	
	typedef bit [31:0] T0C_t;	//W,25FE0090
	parameter bit [31:0] T0C_WMASK = 32'h000003FF;
	parameter bit [31:0] T0C_RMASK = 32'h00000000;
	
	typedef bit [31:0] T1S_t;	//W,25FE0094
	parameter bit [31:0] T1S_WMASK = 32'h000001FF;
	parameter bit [31:0] T1S_RMASK = 32'h00000000;
	
	typedef struct packed		//W,25FE0098
	{
		bit [22: 0] UNUSED;
		bit         MD;			//W
		bit [ 6: 0] UNUSED3;
		bit         ENB;			//W
	} T1MD_t;
	parameter bit [31:0] T1MD_WMASK = 32'h00000101;
	parameter bit [31:0] T1MD_RMASK = 32'h00000000;
	parameter bit [31:0] T1MD_INIT = 32'h00000000;
	
	typedef struct packed		//W,25FE00A0
	{
		bit [15: 0] UNUSED;
		bit         MS15;			//W
		bit         UNUSED2;
		bit         MS13;			//W
		bit         MS12;			//W
		bit         MS11;			//W
		bit         MS10;			//W
		bit         MS9;			//W
		bit         MS8;			//W
		bit         MS7;			//W
		bit         MS6;			//W
		bit         MS5;			//W
		bit         MS4;			//W
		bit         MS3;			//W
		bit         MS2;			//W
		bit         MS1;			//W
		bit         MS0;			//W
	} IMS_t;
	parameter bit [31:0] IMS_WMASK = 32'h0000BFFF;
	parameter bit [31:0] IMS_RMASK = 32'h00000000;
	parameter bit [31:0] IMS_INIT = 32'h0000BFFF;
	
	typedef struct packed		//R/W,25FE00A4
	{
		bit [15: 0] EIS;			//R/W
		bit [ 1: 0] UNUSED;
		bit         SDEI;			//R/W
		bit         DII;			//R/W
		bit         D0EI;			//R/W
		bit         D1EI;			//R/W
		bit         D2EI;			//R/W
		bit         PADI;			//R/W
		bit         SMI;			//R/W
		bit         SRI;			//R/W
		bit         DSPEI;		//R/W
		bit         T1I;			//R/W
		bit         T0I;			//R/W
		bit         HBII;			//R/W
		bit         VBOI;			//R/W
		bit         VBII;			//R/W
	} IST_t;
	parameter bit [31:0] IST_WMASK = 32'hFFFF3FFF;
	parameter bit [31:0] IST_RMASK = 32'hFFFF3FFF;
	parameter bit [31:0] IST_INIT = 32'h00000000;
	
	typedef bit AIACK_t;		//R/W,25FE00A8
	parameter bit [31:0] AIACK_WMASK = 32'h00000001;
	parameter bit [31:0] AIACK_RMASK = 32'h00000001;
	parameter bit [31:0] AIACK_INIT = 32'h00000000;
	
	typedef struct packed		//W,25FE00B0
	{
		bit         A0PRD;		//W
		bit         A0WPC;		//W
		bit         A0RPC;		//W
		bit         A0EWT;		//W
		bit [ 3: 0] A0BW;			//W
		bit [ 3: 0] A0NW;			//W
		bit [ 1: 0] A0LN;			//W
		bit         UNUSED;
		bit         A0SZ;			//W
		bit         A1PRD;		//W
		bit         A1WPC;		//W
		bit         A1RPC;		//W
		bit         A1EWT;		//W
		bit [ 3: 0] A1BW;			//W
		bit [ 3: 0] A1NW;			//W
		bit [ 1: 0] A1LN;			//W
		bit         UNUSED2;
		bit         A1SZ;			//W
	} ASR0_t;
	parameter bit [31:0] ASR0_WMASK = 32'hFFFDFFFD;
	parameter bit [31:0] ASR0_RMASK = 32'h00000000;
	parameter bit [31:0] ASR0_INIT = 32'h00000000;
	
	typedef struct packed		//W,25FE00B4
	{
		bit         A2PRD;		//W
		bit         A2WPC;		//W
		bit         A2RPC;		//W
		bit         A2EWT;		//W
		bit [ 7: 0] UNUSED;
		bit [ 1: 0] A2LN;			//W
		bit         UNUSED2;
		bit         A2SZ;			//W
		bit         A3PRD;		//W
		bit         A3WPC;		//W
		bit         A3RPC;		//W
		bit         A3EWT;		//W
		bit [ 3: 0] A3BW;			//W
		bit [ 3: 0] A3NW;			//W
		bit [ 1: 0] A3LN;			//W
		bit         UNUSED3;
		bit         A3SZ;			//W
	} ASR1_t;
	parameter bit [31:0] ASR1_WMASK = 32'hF00DFFFD;
	parameter bit [31:0] ASR1_RMASK = 32'h00000000;
	parameter bit [31:0] ASR1_INIT = 32'h00000000;
	
	typedef struct packed		//W,25FE00B8
	{
		bit [26: 0] UNUSED;
		bit         ARFEN;		//W
		bit [ 3: 0] ARWT;			//W
	} AREF_t;
	parameter bit [31:0] AREF_WMASK = 32'h0000001F;
	parameter bit [31:0] AREF_RMASK = 32'h00000000;
	parameter bit [31:0] AREF_INIT = 32'h00000000;
	
	typedef bit RSEL_t;			//R/W,25FE00C4
	parameter bit [31:0] RSEL_WMASK = 32'h00000001;
	parameter bit [31:0] RSEL_RMASK = 32'h00000001;
	parameter bit        RSEL_INIT = 1'h0;
	
	typedef bit [31:0] VER_t;	//R,25FE00C8
	parameter bit [31:0] VER_WMASK = 32'h00000000;
	parameter bit [31:0] VER_RMASK = 32'h0000000F;
	parameter bit [31:0] VER_INIT = 32'h00000000;
	
	
	parameter bit [19:0] DMA_TN_MASK[3] = '{20'hFFFFF,20'h00FFF,20'h00FFF};
	
endpackage

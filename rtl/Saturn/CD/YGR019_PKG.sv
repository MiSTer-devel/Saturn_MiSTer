package YGR019_PKG;

	typedef bit [15:0] DATATRNS_t;	//R/W;258XXX00,258XXX02
	parameter bit [15:0] DATATRNS_WMASK = 16'hFFFF;
	parameter bit [15:0] DATATRNS_RMASK = 16'hFFFF;
	parameter bit [15:0] DATATRNS_INIT = 16'hFFFF;
	
	typedef struct packed		//R;258XXX04,258XXX06
	{
		bit [12: 0] UNUSED;
		bit         DIR;		//R
		bit         FUL;		//R
		bit         EMP;		//R
	} DATASTAT_t;
	parameter bit [15:0] DATASTAT_WMASK = 16'h0007;
	parameter bit [15:0] DATASTAT_RMASK = 16'h0007;
	parameter bit [15:0] DATASTAT_INIT = 16'h0000;
	
	typedef struct packed		//R/W;258XXX08,258XXX0A
	{
		bit [ 1: 0] UNUSED;
		bit         MPST;		//R/W0
		bit         MPCM;		//R/W0
		bit         MPED;		//R/W0
		bit         SCDQ;		//R/W0
		bit         EFLS;		//R/W0
		bit         ECPY;		//R/W0
		bit         EHST;		//R/W0
		bit         ESEL;		//R/W0
		bit         DCHG;		//R/W0
		bit         PEND;		//R/W0
		bit         BFUL;		//R/W0
		bit         CSCT;		//R/W0
		bit         DRDY;		//R/W0
		bit         CMOK;		//R/W0
	} HIRQREQ_t;
	parameter bit [15:0] HIRQREQ_WMASK = 16'h3FFF;
	parameter bit [15:0] HIRQREQ_RMASK = 16'h3FFF;
	parameter bit [15:0] HIRQREQ_INIT = 16'h0000;
	
	typedef struct packed		//R/W;258XXX0C,258XXX0E
	{
		bit [ 1: 0] UNUSED;
		bit         MPST;		//R/W
		bit         MPCM;		//R/W
		bit         MPED;		//R/W
		bit         SCDQ;		//R/W
		bit         EFLS;		//R/W
		bit         ECPY;		//R/W
		bit         EHST;		//R/W
		bit         ESEL;		//R/W
		bit         DCHG;		//R/W
		bit         PEND;		//R/W
		bit         BFUL;		//R/W
		bit         CSCT;		//R/W
		bit         DRDY;		//R/W
		bit         CMOK;		//R/W
	} HIRQMSK_t;
	parameter bit [15:0] HIRQMSK_WMASK = 16'h3FFF;
	parameter bit [15:0] HIRQMSK_RMASK = 16'h3FFF;
	parameter bit [15:0] HIRQMSK_INIT = 16'hFFFF;
	
	typedef bit [15:0] CR_t;	//R/W;258XXX18-258XXX26
	parameter bit [15:0] CR_WMASK = 16'hFFFF;
	parameter bit [15:0] CR_RMASK = 16'hFFFF;
	parameter bit [15:0] CR_INIT = 16'h0000;
	
	typedef bit [15:0] MPEGRGB_t;	//R;258XXX28,258XXX2A
	parameter bit [15:0] MPEGRGB_WMASK = 16'hFFFF;
	parameter bit [15:0] MPEGRGB_RMASK = 16'hFFFF;
	parameter bit [15:0] MPEGRGB_INIT = 16'h0000;
	
	typedef bit [15:0] TRCTL_t;	//R/W;0A000002
	parameter bit [15:0] TRCTL_WMASK = 16'h000F;
	parameter bit [15:0] TRCTL_RMASK = 16'h000F;
	parameter bit [15:0] TRCTL_INIT = 16'h0000;
	
	typedef bit [15:0] CDIRQL_t;	//R/W;0A000004
	parameter bit [15:0] CDIRQL_WMASK = 16'h0003;
	parameter bit [15:0] CDIRQL_RMASK = 16'h0003;
	parameter bit [15:0] CDIRQL_INIT = 16'h0000;
	
	typedef bit [15:0] CDIRQU_t;	//R/W;0A000006
	parameter bit [15:0] CDIRQU_WMASK = 16'h0070;
	parameter bit [15:0] CDIRQU_RMASK = 16'h0070;
	parameter bit [15:0] CDIRQU_INIT = 16'h0000;
	
	typedef bit [15:0] CDMASKL_t;	//R/W;0A000008
	parameter bit [15:0] CDMASKL_WMASK = 16'h0003;
	parameter bit [15:0] CDMASKL_RMASK = 16'h0003;
	parameter bit [15:0] CDMASKL_INIT = 16'h0000;
	
	typedef bit [15:0] CDMASKU_t;	//R/W;0A00000A
	parameter bit [15:0] CDMASKU_WMASK = 16'h0070;
	parameter bit [15:0] CDMASKU_RMASK = 16'h0070;
	parameter bit [15:0] CDMASKU_INIT = 16'h0000;
	
	typedef bit [15:0] REG1A_t;	//R/W;0A00001A
	parameter bit [15:0] REG1A_WMASK = 16'h00FF;
	parameter bit [15:0] REG1A_RMASK = 16'h00FF;
	parameter bit [15:0] REG1A_INIT = 16'h0000;
	
endpackage

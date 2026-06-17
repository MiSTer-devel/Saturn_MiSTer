package SMPC_PKG; 
	
	typedef struct packed	//0x00
	{
		bit         IM0;
		bit         IF0;
		bit         RSP;
		bit         IE;
	} INTC0_t;
	parameter bit [3:0] INTC0_INIT = 4'h8;
	
	typedef struct packed	//0x01
	{
		bit         IMTA;
		bit         IFTA;
		bit         IM1;
		bit         IF1;
	} INTC1_t;
	parameter bit [3:0] INTC1_INIT = 4'hA;
	
	typedef struct packed	//0x02
	{
		bit         IMTC;
		bit         IFTC;
		bit         IMTB;
		bit         IFTB;
	} INTC2_t;
	parameter bit [3:0] INTC2_INIT = 4'hA;
	
	typedef struct packed	//0x03
	{
		bit         IMAD;
		bit         IFAD;
		bit         IMTD;
		bit         IFTD;
	} INTC3_t;
	parameter bit [3:0] INTC3_INIT = 4'hA;
	
	typedef struct packed	//0x04
	{
		bit         UNUSED3;
		bit         UNUSED2;
		bit         SI;
		bit         SO;
	} PMRA_t;
	parameter bit [3:0] PMRA_INIT = 4'h0;
	
	typedef bit [3:0] TMA_t;	//0x08
	parameter bit [3:0] TMA_INIT = 4'h0;
	
	typedef bit [3:0] TMC1_t;	//0x0D
	parameter bit [3:0] TMC1_INIT = 4'h0;
	
	typedef bit [3:0] TWCx_t;	//0x0E,0x0F
	parameter bit [3:0] TWCx_INIT = 4'h0;
	typedef bit [3:0] TRCx_t;	//0x0E,0x0F
	parameter bit [3:0] TRCx_INIT = 4'h0;
	
	typedef struct packed	//0x22
	{
		bit         IM3;
		bit         IF3;
		bit         IM2;
		bit         IF2;
	} RF2_t;
	parameter bit [3:0] RF2_INIT = 4'hA;
	
	typedef struct packed	//0x24
	{
		bit         UNUSED3;
		bit         INT3;
		bit         INT2;
		bit         INT1;
	} PMRB_t;
	parameter bit [3:0] PMRB_INIT = 4'h0;
	
	typedef struct packed	//0x25
	{
		bit         INT0;
		bit         STOPC;
		bit         UNKNOWN1;
		bit         UNKNOWN0;
	} PMRC_t;
	parameter bit [3:0] PMRC_INIT = 4'h0;
	
	typedef struct packed	//0x26
	{
		bit [ 1: 0] INT3E;
		bit [ 1: 0] INT2E;
	} ESR1_t;
	parameter bit [3:0] ESR1_INIT = 4'h0;
	
	typedef bit [3:0] DCDx_t;	//0x2C-0x2F
	parameter bit [3:0] DCDx_INIT = 4'h0;
	
	typedef bit [3:0] DCRx_t;	//0x30-0x37
	parameter bit [3:0] DCRx_INIT = 4'h0;
	
endpackage

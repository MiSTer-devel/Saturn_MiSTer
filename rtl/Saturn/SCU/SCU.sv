module SCU
#(parameter bit RAMH_SLOW=0)
(
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	
	input             RES_N,
	
	input      [24:0] CA,
	input      [31:0] CDI,
	output     [31:0] CDO,
	input             CCS1_N,
	input             CCS2_N,
	input             CCS3_N,
	input             CRD_WR_N,
	input       [3:0] CDQM_N,
	input             CRD_N,
	output            CWAIT_N,
	input             CIVECF_N,
	output reg  [3:0] CIRL_N,
	output            CBREQ_N,
	input             CBACK_N,
	
	output     [24:0] ECA,
	input      [31:0] ECDI,
	output     [31:0] ECDO,
	output      [3:0] ECDQM_N,
	output            ECRD_WR_N,
	output            ECCS3_N,
	output            ECRD_N,	//not present in original
	output            ECBURST,	//not present in original
	output            ECRFS,	//not present in original
	input             ECWAIT_N,//not present in original
	
	output reg [25:0] AA,
	input      [15:0] ADI,
	output reg [15:0] ADO,
	output reg  [1:0] AFC,
	output reg        AAS_N,
	output reg        ACS0_N,
	output reg        ACS1_N,
	output reg        ACS2_N,
	input             AWAIT_N,
	input             AIRQ_N,
	output reg        ARD_N,
	output reg        AWRL_N,
	output reg        AWRU_N,
	output reg        ATIM0_N,
	output reg        ATIM1_N,
	output reg        ATIM2_N,
	
	input      [15:0] BDI,
	output reg [15:0] BDO,
	output reg        BADDT_N,
	output reg        BDTEN_N,
	output reg        BREQ_N,	//not present in original
	output reg        BCS1_N,
	input             BRDY1_N,
	input             IRQ1_N,
	output reg        BCS2_N,
	input             BRDY2_N,
	input             IRQV_N,
	input             IRQH_N,
	input             IRQL_N,
	output reg        BCSS_N,
	input             BRDYS_N,
	input             IRQS_N,
	
	input             MIREQ_N,
	
	input             FAST
	
`ifdef DEBUG
	                  ,
	output     [ 7:0] DBG_WAIT_CNT,
	output     [ 7:0] DBG_BBUS_WAIT_CNT,
	output     [ 7:0] DBG_CBUS_WAIT_CNT,
	output reg        DBG_DMA_TN_ERR,
	output            DBG_DMA_RADDR_ERR,
	output            DBG_DMA_WADDR_ERR,
	output reg        DMA_BUF_SIZE_ERR,
	output reg        DMA_BUF_POS_ERR,
	output reg        DR_ERR,
	output reg        DW_ERR
`endif
);
	import SCU_PKG::*;
	
	DxR_t       DR[3];
	DxW_t       DW[3];
	DxC_t       DC[3];
	DxAD_t      DAD[3];
	DxEN_t      DEN[3];
	DxMD_t      DMD[3];
//	DSTP_t      DSTP;
	DSTA_t      DSTA;
	T0C_t       T0C;
	T1S_t       T1S;
	T1MD_t      T1MD;
	IMS_t       IMS;
	IST_t       IST;
	ASR0_t      ASR0;
	ASR1_t      ASR1;
	RSEL_t      RSEL;
	
	bit  [26:0] DSP_DR;
	bit  [26:0] DSP_DW;
	bit  [ 2:0] DSP_ADD;
	bit         DSP_HOLD;
		
	//IO, interrupts
	bit         CDQM_N_OLD0,CDQM_N_OLD1;
	bit         CRD_N_OLD;
	bit  [ 3:0] IVECF_LVL;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			{CDQM_N_OLD0,CDQM_N_OLD1} <= '1;
			CRD_N_OLD <= 1; 
		end else begin
			if (CE_R) begin
				IVECF_LVL <= CA[3:0];
			end 
			CDQM_N_OLD0 <= &CDQM_N;
			CDQM_N_OLD1 <= CDQM_N_OLD0;
			CRD_N_OLD <= CRD_N;
		end
	end
	wire        CWE = ~CDQM_N_OLD0 & CDQM_N_OLD1;
	wire        CRE = ~CRD_N & CRD_N_OLD;
	
	wire        ABUS_SEL = (~CCS1_N | (CA[24:20] <  5'h1A                      & ~CCS2_N));				//02000000-059FFFFF
	wire        BBUS_SEL = (          (CA[24:20] >= 5'h1A & CA[24:16] < 9'h1FE & ~CCS2_N));				//05A00000-05FDFFFF
	wire        ABUS_RW = ABUS_SEL & (~CRD_N | ~&CDQM_N);
	wire        BBUS_RW = BBUS_SEL & (~CRD_N | ~&CDQM_N);
	bit  [24:0] CPU_ABUS_CACHE_CA[2] = '{2{'1}};
	bit  [31:0] CPU_ABUS_CACHE_CDI[2] = '{2{'1}};
	bit  [ 3:0] CPU_ABUS_CACHE_CDQMN[2] = '{2{'1}};
	bit         CPU_ABUS_CACHE_CRDN[2] = '{2{1}};
	bit         CPU_ABUS_CACHE_CCS1N[2] = '{2{1}};
	bit         CPU_ABUS_CACHE_CCS2N[2] = '{2{1}};
	bit         CPU_ABUS_CACHE_FILL[2] = '{2{0}};
	bit         CPU_ABUS_CACHE_WPOS;
	bit         CPU_ABUS_CACHE_RPOS;
	bit  [24:0] CPU_BBUS_CACHE_CA[2] = '{2{'1}};
	bit  [31:0] CPU_BBUS_CACHE_CDI[2] = '{2{'1}};
	bit  [ 3:0] CPU_BBUS_CACHE_CDQMN[2] = '{2{'1}};
	bit         CPU_BBUS_CACHE_CRDN[2] = '{2{1}};
	bit         CPU_BBUS_CACHE_CCS1N[2] = '{2{1}};
	bit         CPU_BBUS_CACHE_CCS2N[2] = '{2{1}};
	bit         CPU_BBUS_CACHE_FILL[2] = '{2{0}};
	bit         CPU_BBUS_CACHE_WPOS;
	bit         CPU_BBUS_CACHE_RPOS;
	
	wire        REG_SEL = ~CCS2_N & CA[24:0] >= 25'h1FE0000 & CA[24:0] <= 25'h1FE00CF;	//25FE0000-25FE00CF
	wire        REG_WR = REG_SEL & CWE;
	wire        REG_RD = REG_SEL & CRE;
	wire        IVECF_RISE = CRD_N & ~CRD_N_OLD & ~CIVECF_N;

	bit         IRQV_N_OLD, IRQH_N_OLD;
	bit         IRQS_N_OLD;
	bit         IRQ1_N_OLD;
	bit         IRQL_N_OLD;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			IRQV_N_OLD <= 1;
			IRQH_N_OLD <= 1;
			IRQS_N_OLD <= 1;
			IRQ1_N_OLD <= 1;
			IRQL_N_OLD <= 1;
		end
		else begin
			if (!RES_N) begin
				IRQV_N_OLD <= 1;
				IRQH_N_OLD <= 1;
			end else if (CE_R) begin
				IRQH_N_OLD <= IRQH_N;
				IRQV_N_OLD <= IRQV_N;
				IRQS_N_OLD <= IRQS_N;
				IRQ1_N_OLD <= IRQ1_N;
				IRQL_N_OLD <= IRQL_N;
			end
		end
	end
	wire        VBL_IN   = !IRQV_N &  IRQV_N_OLD;
	wire        VBL_OUT  =  IRQV_N & !IRQV_N_OLD;
	wire        HBL_IN   = !IRQH_N &  IRQH_N_OLD;
	wire        SCSP_REQ = !IRQS_N &  IRQS_N_OLD;
	wire        VDP1_REQ = !IRQ1_N &  IRQ1_N_OLD;
	wire        PAD_REQ = !IRQL_N &  IRQL_N_OLD;
	
	bit         VBIN_PEND;
	bit         VBOUT_PEND;
	bit         HBIN_PEND;
	bit         TM0_PEND;
	bit         TM1_PEND;
	bit         DSP_PEND;
	bit         SCSP_PEND;
	bit         SM_PEND;
	bit         PAD_PEND;
	bit         DMA_INT_PEND[3];
	bit         DMAIL_PEND;
	bit         VDP1_PEND;
	
	//DSP
	bit  [31:0] DSP_DMA_DO;
	bit  [31:0] DSP_DMA_DI;
	bit         DSP_DMA_WE;
	bit         DSP_DMA_REQ;
	bit         DSP_DMA_ACK;
	bit         DSP_DMA_RUN;
	bit         DSP_DMA_END;
	bit         DSP_DMA_LAST;
	bit         DSP_IRQ;
	
	//ABUS
	typedef enum bit [3:0] {
		ABUS_IDLE,  
		ABUS_ADDR_H, 
		ABUS_WAIT,
		ABUS_NEXT,
		ABUS_END,
		ABUS_DMA_READ,
		ABUS_DMA_READ_WAIT,
		ABUS_DMA_READ_NEXT,
		ABUS_DMA_WRITE,
		ABUS_DMA_WRITE_WAIT,
		ABUS_DMA_END
	} ABUSState_t;
	ABUSState_t ABUS_ST;
	
	bit         CPU_ABUS_REQ;
	
	//BBUS
	typedef enum bit [5:0] {
		BBUS_IDLE,  
		BBUS_ADDR16_H,
		BBUS_ADDR16_L, 
		BBUS_ADDR8_WAIT0,BBUS_ADDR8_WAIT1,
		BBUS_ADDR8_HH, 
		BBUS_ADDR8_HL, 
		BBUS_ADDR8_LH, 
		BBUS_ADDR8_LL, 
		BBUS_WRITE16_H,
		BBUS_WRITE16_L,
		BBUS_WRITE16_END0,BBUS_WRITE16_END1,BBUS_WRITE16_END2,
		BBUS_WRITE8_HH,
		BBUS_WRITE8_HL,
		BBUS_WRITE8_LH,
		BBUS_WRITE8_LL,
		BBUS_WRITE8_END0,BBUS_WRITE8_END1,BBUS_WRITE8_END2,
		BBUS_READ16_START,
		BBUS_READ8_START,
		BBUS_READ8_WAIT,
		BBUS_READ8_H,
		BBUS_READ8_L,
		BBUS_READ16_WAIT,
		BBUS_READ_NEXT,
		BBUS_READ_NEXT2,
		BBUS_READ_END0,BBUS_READ_END1,BBUS_READ_END2,
		BBUS_DMA_RADDR1,
		BBUS_DMA_RADDR2,
		BBUS_DMA_READ,
		BBUS_DMA_WADDR0,
		BBUS_DMA_WADDR1,
		BBUS_DMA_WADDR2,
		BBUS_DMA_WADDR3,
		BBUS_DMA_WRITE,
		BBUS_DMA_PAGE,
		BBUS_DMA_END
	} BBUSState_t;
	BBUSState_t BBUS_ST;
	
	bit         CPU_BBUS_REQ;
	wire        BBUS_RDY = ((!BCSS_N && !BRDYS_N) || (!BCS1_N && !BRDY1_N) || (!BCS2_N && !BRDY2_N));
	
	//CBUS
	typedef enum bit [3:0] {
		CBUS_IDLE,  
		CBUS_REQUEST, 
		CBUS_INIT,
		CBUS_START,
		CBUS_IND_READ,
		CBUS_READ, 
		CBUS_READ_END,
		CBUS_WRITE,
		CBUS_WRITE_WAIT,
		CBUS_WRITE_END,
		CBUS_REFRESH,
		CBUS_RELEASE,
		CBUS_END
	} CBUSState_t;
	CBUSState_t CBUS_ST;
	
	bit  [26: 0] CBUS_A;
	bit  [31: 0] CBUS_D;
	bit          CBUS_RD;
	bit  [ 3: 0] CBUS_WR;
	bit          CBUS_CS;
	bit          CBUS_BURST;
	bit          CBUS_REQ;
	bit          CBUS_REL;
	bit          CBUS_WAIT;
	bit  [ 3: 0] CBUS_RFS;
	
	bit          CCACHE_FULL[2];
	wire [ 2: 0] CCACHE_WADDR = CBUS_A[4:2];
	wire [31: 0] CCACHE_DATA = ECDI;
	wire         CCACHE_WREN = CBUS_ST == CBUS_READ && ECWAIT_N && !CCACHE_FULL[CBUS_A[4]] && CE_R;
	bit  [ 2: 0] CCACHE_RADDR;
	bit  [31: 0] CCACHE_Q;
	SCU_CBUS_CACHE CCACHE(CLK,CCACHE_WADDR,CCACHE_DATA,CCACHE_WREN,CCACHE_RADDR,CCACHE_Q);
	
	
	//DMA
	typedef enum bit [4:0] {
		DMA_IDLE,
		DMA_SELECT,
		DMA_IND_START, 
		DMA_IND_READ_BBUS, 
		DMA_IND_READ_CBUS, 
		DMA_IND_END, 
		DMA_START,
		DMA_ABUS_BBUS,
		DMA_ABUS_CBUS,
		DMA_BBUS_CBUS,
		DMA_CBUS_ABUS,
		DMA_CBUS_BBUS,
		DMA_ABUS_DSP,
		DMA_BBUS_DSP,
		DMA_CBUS_DSP,
		DMA_DSP_BBUS,
		DMA_DSP_CBUS,
		DMA_DSP_INIT, 
		DMA_DSP_START,
		DMA_STOP
	} DMAState_t;
	DMAState_t DMA_ST;
	
	bit  [26:0] DMA_IA;
	bit  [26:0] DMA_RA;
	bit  [26:0] DMA_WA;
	bit  [19:0] DMA_RTN;
	bit  [19:0] DMA_WTN;
	bit         DMA_EC;
	bit         DMA_RADD;
	bit  [ 2:0] DMA_WADD;
	bit  [ 1:0] DMA_CH;
	bit         DMA_RUN[3];
	
	bit         DMA_PEND[4];
	bit  [ 7:0] DMA_BUF[8];
	bit  [ 2:0] DMA_BUF_WPOS;
	bit  [ 2:0] DMA_BUF_RPOS;
	bit  [ 2:0] DMA_BUF_SIZE;
	bit  [ 3:0] DMA_WBE;
	bit         DMA_BUF_RDY;
	bit         DMA_IND;
	
	bit DMA_FACT[3];
	always_comb begin
		for (int i=0; i<3; i++) begin
			case (DMD[i].FT)
				3'b000: DMA_FACT[i] = VBL_IN;
				3'b001: DMA_FACT[i] = VBL_OUT;
				3'b010: DMA_FACT[i] = HBL_IN;
				3'b011: DMA_FACT[i] = TM0_INT;
				3'b100: DMA_FACT[i] = TM1_INT;
				3'b101: DMA_FACT[i] = SCSP_REQ;
				3'b110: DMA_FACT[i] = VDP1_REQ;
				3'b111: DMA_FACT[i] = DEN[i].GO;
			endcase
		end
	end
	
	bit         DMA_READ_A;
	bit         DMA_READ_B;
	bit         DMA_READ_C;
	bit         DMA_WRITE_A;
	bit         DMA_WRITE_B;
	bit         DMA_WRITE_C;
//	bit         DMA_READ_DSP;
//	bit         DMA_WRITE_DSP;
	
	bit  [31:0] ABUS_BUF;
	bit  [31:0] BBUS_BUF;
	always @(posedge CLK or negedge RST_N) begin
		bit  [24:0] ABUS_CA_INNER,BBUS_CA_INNER;
		bit  [31:0] ABUS_CDI_INNER,BBUS_CDI_INNER;
		bit   [3:0] ABUS_CDQMN_INNER,BBUS_CDQMN_INNER;
		bit         ABUS_CRDN_INNER,BBUS_CRDN_INNER;
		bit         ABUS_CCS1N_INNER,BBUS_CCS1N_INNER;
		bit         ABUS_CCS2N_INNER,BBUS_CCS2N_INNER;
		bit         ABUS_SEL_INNER;
		bit         BBUS_SEL_INNER;
		
		bit  [26:0] DMA_RA_NEW,DMA_WA_NEW,DMA_IA_NEW;
		bit         DMA_WTN_LESS2;
		bit         DMA_WTN_LESS4,DMA_RTN_LESS4;
		bit   [2:0] DMA_WTN_OFFS,DMA_RTN_OFFS;
		bit   [2:0] DMA_RTN_DEC;
		bit   [2:0] DMA_WTN_DEC;
		bit  [19:0] DMA_RTN_NEXT;
		bit  [19:0] DMA_WTN_NEXT;
		bit   [1:0] DMA_RBA;
		bit   [1:0] DMA_IND_REG;
		bit         DMA_LAST;
		bit         DMA_DSP;
		bit         DMA_END;
		bit         DSP_DMA_RUN_OLD;
		bit         DMA_RA_ERR;
		bit         DMA_WA_ERR;
		bit         DMA_ERR;
		bit         ABUS_RW_OLD;
		bit         BBUS_RW_OLD;
		bit         CPU_ABUS_PEND;
		bit         CPU_BBUS_PEND;
		bit         CPU_ABUS_ACT;
		bit         CPU_BBUS_ACT;
		bit         ABUS_A1;
		bit         ABUS_LONG;
		bit   [5:0] ABUS_WAIT_CNT;
		bit   [1:0] BBUS_WORD;
		bit         BBUS_WRITE_PAGE;
		bit         BBUS_WRITE_UNALIGNED;
		bit         BBUS_A1;
		bit         BBUS_RD;
		bit         CPU_ABUS_WAIT_CLR;
		bit         CPU_BBUS_WAIT_CLR;
		bit         BBUS_READ_PROCESS;
		bit         ABUS_WRITE_PROCESS;
		bit         BBUS_WRITE_PROCESS;
		bit   [1:0] BBUS_IND_POS;
		bit   [2:0] CBUS_IND_POS;
		bit         CBUS_RFS_PEND,CBUS_RAS_PEND;
		bit   [1:0] CBUS_RAS_CNT;
		
		bit         ABUS_DMA_START;
		bit         ABUS_READ_ACK;
		bit         ABUS_READ_DONE;
		bit         ABUS_WRITE_DONE;
		bit         ABUS_DATA_ACK;
		bit         BBUS_IND_DONE;
		bit         BBUS_DMA_START;
		bit         BBUS_READ_ACK;
		bit         BBUS_READ_DONE;
		bit         BBUS_WRITE_DONE;
		bit         BBUS_DATA_ACK;
		bit         CBUS_IND_DONE;
		bit         CBUS_DMA_START;
		bit         CBUS_READ_ACK;
		bit         CBUS_DATA_ACK;
		bit         CBUS_DMA_OUT;
		bit         CBUS_READ_DONE;
		bit  [31:0] RD_DATA;
				
		if (!RST_N) begin
			DR <= '{'0,'0,'0};
			DW <= '{'0,'0,'0};
			DC <= '{'0,'0,'0};
			DAD <= '{'0,'0,'0};
			DEN <= '{'0,'0,'0};
			DMD <= '{'0,'0,'0};
//			DSTP <= DSTP_INIT;

			AA <= '0;
			ADO <= '0;
			AAS_N <= 1;
			ARD_N <= 1;
			AWRL_N <= 1;
			AWRU_N <= 1;
			ACS0_N <= 1;
			ACS1_N <= 1;
			ACS2_N <= 1;
			AFC <= '1;
			ATIM0_N <= 1;
			ATIM1_N <= 1;
			ATIM2_N <= 1;
			
			BDO <= '0;
			BADDT_N <= 1;
			BDTEN_N <= 1;
			BCS1_N <= 1;
			BCS2_N <= 1;
			BCSS_N <= 1;
			
			DSTA <= DSTA_INIT;
			
			ABUS_RW_OLD <= 0;
			CPU_ABUS_CACHE_CA = '{2{'1}};
			CPU_ABUS_CACHE_CDI = '{2{'1}};
			CPU_ABUS_CACHE_CDQMN = '{2{'1}};
			CPU_ABUS_CACHE_CRDN = '{2{1}};
			CPU_ABUS_CACHE_CCS1N = '{2{1}};
			CPU_ABUS_CACHE_CCS2N = '{2{1}};
			CPU_ABUS_CACHE_FILL = '{2{0}};
			CPU_ABUS_CACHE_WPOS <= 0;
			CPU_ABUS_CACHE_RPOS <= 0;
			CPU_ABUS_WAIT_CLR <= 0;
			
			BBUS_RW_OLD <= 0;
			CPU_BBUS_CACHE_CA = '{2{'1}};
			CPU_BBUS_CACHE_CDI = '{2{'1}};
			CPU_BBUS_CACHE_CDQMN = '{2{'1}};
			CPU_BBUS_CACHE_CRDN = '{2{1}};
			CPU_BBUS_CACHE_CCS1N = '{2{1}};
			CPU_BBUS_CACHE_CCS2N = '{2{1}};
			CPU_BBUS_CACHE_FILL = '{2{0}};
			CPU_BBUS_CACHE_WPOS <= 0;
			CPU_BBUS_CACHE_RPOS <= 0;
			CPU_BBUS_WAIT_CLR <= 0;
			
			ABUS_ST <= ABUS_IDLE;
			ABUS_DMA_START <= 0;
			CPU_ABUS_REQ <= 0;
			ABUS_A1 <= 0;
			CPU_ABUS_ACT <= 0;
			
			BBUS_ST <= BBUS_IDLE;
			BBUS_DMA_START <= 0;
			CPU_BBUS_REQ <= 0;
			BBUS_A1 <= 0;
			CPU_BBUS_ACT <= 0;
			CPU_ABUS_PEND <= 0;
			CPU_BBUS_PEND <= 0;
			
			CBUS_ST <= CBUS_IDLE;
			CBUS_DMA_START <= 0;
			CBUS_A <= '0;
			CBUS_D <= '0;
			CBUS_WAIT <= 0;
			CBUS_RFS_PEND <= 0;
			CBUS_RFS <= '0;
			CBUS_BURST <= 0;
			
			DMA_ST <= DMA_IDLE;
			DMA_RA <= '0;
			DMA_WA <= '0;
			DMA_IA <= '0;
			DMA_RTN <= '0;
			DMA_WTN <= '0;
			DMA_EC <= 0;
			DMA_CH <= '0;
			DMA_PEND <= '{4{0}};
			DMA_DSP <= 0;
			DMA_IND <= 0;
			DMA_RUN <= '{3{0}};
			DMA_INT_PEND <= '{3{0}};
			DMAIL_PEND <= 0;
			
			DMA_READ_A <= 0;
			DMA_READ_B <= 0;
			DMA_READ_C <= 0;
			DMA_WRITE_A <= 0;
			DMA_WRITE_B <= 0;
			DMA_WRITE_C <= 0;
//			DMA_READ_DSP <= 0;
//			DMA_WRITE_DSP <= 0;
		end else if (!RES_N) begin
//			DR <= '{'0,'0,'0};
//			DW <= '{'0,'0,'0};
//			DC <= '{'0,'0,'0};
//			DAD <= '{'0,'0,'0};
//			DEN <= '{'0,'0,'0};
//			DMD <= '{'0,'0,'0};
//			DSTP <= DSTP_INIT;
			DSTA <= DSTA_INIT;
			
			ABUS_RW_OLD <= 0;
			BBUS_RW_OLD <= 0;
			CPU_ABUS_WAIT_CLR <= 0;
			CPU_BBUS_WAIT_CLR <= 0;
			
			ABUS_ST <= ABUS_IDLE;
			ABUS_DMA_START <= 0;
			CPU_ABUS_REQ <= 0;
			ABUS_A1 <= 0;
			
			BBUS_ST <= BBUS_IDLE;
			BBUS_DMA_START <= 0;
			CPU_BBUS_REQ <= 0;
			BBUS_A1 <= 0;
			
			CBUS_ST <= CBUS_IDLE;
			CBUS_DMA_START <= 0;
			CBUS_A <= '0;
			CBUS_D <= '0;
			CBUS_WAIT <= 0;
			CBUS_RFS_PEND <= 0;
			CBUS_RFS <= '0;
			CBUS_BURST <= 0;
			
			DMA_ST <= DMA_IDLE;
			DMA_RA <= '0;
			DMA_WA <= '0;
			DMA_IA <= '0;
			DMA_RTN <= '0;
			DMA_WTN <= '0;
			DMA_EC <= 0;
			DMA_CH <= '0;
			DMA_PEND <= '{4{0}};
			DMA_DSP <= 0;
			DMA_IND <= 0;
			DMA_RUN <= '{3{0}};
			DMA_INT_PEND <= '{3{0}};
			DMAIL_PEND <= 0;
			
			DMA_READ_A <= 0;
			DMA_READ_B <= 0;
			DMA_READ_C <= 0;
			DMA_WRITE_A <= 0;
			DMA_WRITE_B <= 0;
			DMA_WRITE_C <= 0;
//			DMA_READ_DSP <= 0;
//			DMA_WRITE_DSP <= 0;
		end else begin
			ABUS_CA_INNER = CPU_ABUS_CACHE_CA[CPU_ABUS_CACHE_RPOS];
			ABUS_CDI_INNER = CPU_ABUS_CACHE_CDI[CPU_ABUS_CACHE_RPOS];
			ABUS_CDQMN_INNER = CPU_ABUS_CACHE_CDQMN[CPU_ABUS_CACHE_RPOS];
			ABUS_CRDN_INNER = CPU_ABUS_CACHE_CRDN[CPU_ABUS_CACHE_RPOS];
			ABUS_CCS1N_INNER = CPU_ABUS_CACHE_CCS1N[CPU_ABUS_CACHE_RPOS];
			ABUS_CCS2N_INNER = CPU_ABUS_CACHE_CCS2N[CPU_ABUS_CACHE_RPOS];
			
			BBUS_CA_INNER = CPU_BBUS_CACHE_CA[CPU_BBUS_CACHE_RPOS];
			BBUS_CDI_INNER = CPU_BBUS_CACHE_CDI[CPU_BBUS_CACHE_RPOS];
			BBUS_CDQMN_INNER = CPU_BBUS_CACHE_CDQMN[CPU_BBUS_CACHE_RPOS];
			BBUS_CRDN_INNER = CPU_BBUS_CACHE_CRDN[CPU_BBUS_CACHE_RPOS];
			BBUS_CCS1N_INNER = CPU_BBUS_CACHE_CCS1N[CPU_BBUS_CACHE_RPOS];
			BBUS_CCS2N_INNER = CPU_BBUS_CACHE_CCS2N[CPU_BBUS_CACHE_RPOS];
			
			ABUS_SEL_INNER = (~ABUS_CCS1N_INNER | (ABUS_CA_INNER[24:20] < 5'h19 & ~ABUS_CCS2N_INNER)) & CPU_ABUS_CACHE_FILL[CPU_ABUS_CACHE_RPOS];				//02000000-058FFFFF
			BBUS_SEL_INNER = BBUS_CA_INNER[24:16] >= 9'h1A0 & BBUS_CA_INNER[24:16] < 9'h1FE & ~BBUS_CCS2N_INNER & CPU_BBUS_CACHE_FILL[CPU_BBUS_CACHE_RPOS];	//05A00000-05FDFFFF
			
			if (CE_R) begin
				ABUS_RW_OLD <= ABUS_RW;
				if (ABUS_RW && !ABUS_RW_OLD) begin
					CBUS_WAIT <= 1;
				end

				if (ABUS_RW && !CRD_WR_N && !CPU_ABUS_CACHE_FILL[CPU_ABUS_CACHE_WPOS] && CBUS_WAIT) begin
					CPU_ABUS_CACHE_CA[CPU_ABUS_CACHE_WPOS] <= CA;
					CPU_ABUS_CACHE_CDI[CPU_ABUS_CACHE_WPOS] <= CDI;
					CPU_ABUS_CACHE_CDQMN[CPU_ABUS_CACHE_WPOS] <= CDQM_N;
					CPU_ABUS_CACHE_CRDN[CPU_ABUS_CACHE_WPOS] <= CRD_N;
					CPU_ABUS_CACHE_CCS1N[CPU_ABUS_CACHE_WPOS] <= CCS1_N;
					CPU_ABUS_CACHE_CCS2N[CPU_ABUS_CACHE_WPOS] <= CCS2_N;
					CPU_ABUS_CACHE_FILL[CPU_ABUS_CACHE_WPOS] <= 1;
					CPU_ABUS_CACHE_WPOS <= ~CPU_ABUS_CACHE_WPOS;
					CBUS_WAIT <= 0;
				end else if (ABUS_RW && CRD_WR_N && !CPU_ABUS_CACHE_FILL[0] && !CPU_ABUS_CACHE_FILL[1] && CBUS_WAIT) begin
					CPU_ABUS_CACHE_CA[CPU_ABUS_CACHE_WPOS] <= CA;
					CPU_ABUS_CACHE_CDI[CPU_ABUS_CACHE_WPOS] <= CDI;
					CPU_ABUS_CACHE_CDQMN[CPU_ABUS_CACHE_WPOS] <= CDQM_N;
					CPU_ABUS_CACHE_CRDN[CPU_ABUS_CACHE_WPOS] <= CRD_N;
					CPU_ABUS_CACHE_CCS1N[CPU_ABUS_CACHE_WPOS] <= CCS1_N;
					CPU_ABUS_CACHE_CCS2N[CPU_ABUS_CACHE_WPOS] <= CCS2_N;
					CPU_ABUS_CACHE_FILL[CPU_ABUS_CACHE_WPOS] <= 1;
					CPU_ABUS_CACHE_WPOS <= ~CPU_ABUS_CACHE_WPOS;
				end 
				if (CPU_ABUS_CACHE_FILL[CPU_ABUS_CACHE_RPOS] && !CPU_ABUS_PEND && !CPU_ABUS_REQ && !CPU_ABUS_ACT) begin
					CPU_ABUS_REQ <= ABUS_SEL_INNER;
					CPU_ABUS_PEND <= 1;
				end
				
				if (CPU_ABUS_WAIT_CLR && CPU_ABUS_CACHE_FILL[CPU_ABUS_CACHE_RPOS]) begin
					CPU_ABUS_CACHE_FILL[CPU_ABUS_CACHE_RPOS] <= 0;
					CPU_ABUS_CACHE_RPOS <= ~CPU_ABUS_CACHE_RPOS;
					if (!CPU_ABUS_CACHE_CRDN[CPU_ABUS_CACHE_RPOS]) CBUS_WAIT <= 0;
					CPU_ABUS_PEND <= 0;
					CPU_ABUS_WAIT_CLR <= 0;
				end
				
				//CPU B-BUS
				BBUS_RW_OLD <= BBUS_RW;
				if (BBUS_RW && !BBUS_RW_OLD) begin
					CBUS_WAIT <= 1;
				end

				if (BBUS_RW && !CRD_WR_N && !CPU_BBUS_CACHE_FILL[CPU_BBUS_CACHE_WPOS] && CBUS_WAIT) begin
					CPU_BBUS_CACHE_CA[CPU_BBUS_CACHE_WPOS] <= CA;
					CPU_BBUS_CACHE_CDI[CPU_BBUS_CACHE_WPOS] <= CDI;
					CPU_BBUS_CACHE_CDQMN[CPU_BBUS_CACHE_WPOS] <= CDQM_N;
					CPU_BBUS_CACHE_CRDN[CPU_BBUS_CACHE_WPOS] <= CRD_N;
					CPU_BBUS_CACHE_CCS1N[CPU_BBUS_CACHE_WPOS] <= CCS1_N;
					CPU_BBUS_CACHE_CCS2N[CPU_BBUS_CACHE_WPOS] <= CCS2_N;
					CPU_BBUS_CACHE_FILL[CPU_BBUS_CACHE_WPOS] <= 1;
					CPU_BBUS_CACHE_WPOS <= ~CPU_BBUS_CACHE_WPOS;
					CBUS_WAIT <= 0;
				end else if (BBUS_RW && CRD_WR_N && !CPU_BBUS_CACHE_FILL[0] && !CPU_BBUS_CACHE_FILL[1] && CBUS_WAIT) begin
					CPU_BBUS_CACHE_CA[CPU_BBUS_CACHE_WPOS] <= CA;
					CPU_BBUS_CACHE_CDI[CPU_BBUS_CACHE_WPOS] <= CDI;
					CPU_BBUS_CACHE_CDQMN[CPU_BBUS_CACHE_WPOS] <= CDQM_N;
					CPU_BBUS_CACHE_CRDN[CPU_BBUS_CACHE_WPOS] <= CRD_N;
					CPU_BBUS_CACHE_CCS1N[CPU_BBUS_CACHE_WPOS] <= CCS1_N;
					CPU_BBUS_CACHE_CCS2N[CPU_BBUS_CACHE_WPOS] <= CCS2_N;
					CPU_BBUS_CACHE_FILL[CPU_BBUS_CACHE_WPOS] <= 1;
					CPU_BBUS_CACHE_WPOS <= ~CPU_BBUS_CACHE_WPOS;
				end 
				if (CPU_BBUS_CACHE_FILL[CPU_BBUS_CACHE_RPOS] && !CPU_BBUS_PEND && !CPU_BBUS_REQ && !CPU_BBUS_ACT) begin
					CPU_BBUS_REQ <= BBUS_SEL_INNER;
					CPU_BBUS_PEND <= 1;
				end
				
				if (CPU_BBUS_WAIT_CLR && CPU_BBUS_CACHE_FILL[CPU_BBUS_CACHE_RPOS]) begin
					CPU_BBUS_CACHE_FILL[CPU_BBUS_CACHE_RPOS] <= 0;
					CPU_BBUS_CACHE_RPOS <= ~CPU_BBUS_CACHE_RPOS;
					if (!CPU_BBUS_CACHE_CRDN[CPU_BBUS_CACHE_RPOS]) CBUS_WAIT <= 0;
					CPU_BBUS_PEND <= 0;
					CPU_BBUS_WAIT_CLR <= 0;
				end
`ifdef DEBUG
				if (CBUS_WAIT) DBG_CBUS_WAIT_CNT <= DBG_CBUS_WAIT_CNT + 1'd1;
				else DBG_CBUS_WAIT_CNT <= '0;
`endif
			end
			
			if (CE_R) begin
				DMAIL_PEND <= 0;
				if (DSP_DMA_ACK) DSP_DMA_ACK <= 0;
				
				if (DMA_FACT[0] && DEN[0].EN && !DMA_PEND[0]) begin DMA_PEND[0] <= 1; DSTA.D0WT <= 1; end
				if (DMA_FACT[1] && DEN[1].EN && !DMA_PEND[1]) begin DMA_PEND[1] <= 1; DSTA.D1WT <= 1; end
				if (DMA_FACT[2] && DEN[2].EN && !DMA_PEND[2]) begin DMA_PEND[2] <= 1; DSTA.D2WT <= 1; end
				DSP_DMA_RUN_OLD <= DSP_DMA_RUN;
				if (DSP_DMA_RUN && !DSP_DMA_RUN_OLD) begin DMA_PEND[3] <= 1; DSTA.DDWT <= 1; end
				
				DMA_INT_PEND <= '{3{0}};
			end
			
			DMA_RTN_LESS4 = ~|DMA_RTN[19:2];
			if (DMA_DSP) begin
				DMA_RTN_DEC = 3'd4;
			end else if (DMA_READ_A || DMA_READ_B || DMA_READ_C) begin
				case (DMA_RA[1:0])
					2'b00: DMA_RTN_OFFS = 3'd4;
					2'b01: DMA_RTN_OFFS = 3'd3;
					2'b10: DMA_RTN_OFFS = 3'd2;
					2'b11: DMA_RTN_OFFS = 3'd1;
				endcase
				DMA_RTN_DEC = DMA_RTN_OFFS;
				if (DMA_RTN_LESS4) begin
					if (!DMA_RTN[1:0]) begin
						DMA_RTN_DEC = 3'd4;
					end else if (DMA_RTN[1:0] && {1'b0,DMA_RTN[1:0]} < DMA_RTN_OFFS) begin
						DMA_RTN_DEC = {1'b0,DMA_RTN[1:0]};
					end
				end
			end else begin
				DMA_RTN_DEC = 3'd0;
			end
			DMA_RTN_NEXT = (DMA_RTN - DMA_RTN_DEC) & (DMA_TN_MASK[DMA_CH] | {20{DMD[DMA_CH].MOD}});
			
			DMA_WTN_LESS2 = ~|DMA_WTN[19:1];
			DMA_WTN_LESS4 = ~|DMA_WTN[19:2];
			if (DMA_DSP) begin
				DMA_WTN_DEC = 3'd4;
			end else if (DMA_WRITE_C) begin
				case (DMA_WA[1:0])
					2'b00: DMA_WTN_OFFS = 3'd4;
					2'b01: DMA_WTN_OFFS = 3'd3;
					2'b10: DMA_WTN_OFFS = 3'd2;
					2'b11: DMA_WTN_OFFS = 3'd1;
				endcase
				DMA_WTN_DEC = DMA_WTN_OFFS;
				if (DMA_WTN_LESS4) begin
					if (!DMA_WTN[1:0]) begin
						DMA_WTN_DEC = 3'd4;
					end else if (DMA_WTN[1:0] && {1'b0,DMA_WTN[1:0]} < DMA_WTN_OFFS) begin
						DMA_WTN_DEC = {1'b0,DMA_WTN[1:0]};
					end
				end
			end else if (DMA_WRITE_A || DMA_WRITE_B) begin
				case (DMA_WA[0])
					1'b0: DMA_WTN_OFFS = 3'd2;
					1'b1: DMA_WTN_OFFS = 3'd1;
				endcase
				DMA_WTN_DEC = DMA_WTN_OFFS;
				if (DMA_WTN_LESS2 && DMA_WTN[0]) begin
					DMA_WTN_DEC = 3'd1;
				end
			end else begin
				DMA_WTN_DEC = 3'd0;
			end
			DMA_WTN_NEXT = (DMA_WTN - DMA_WTN_DEC) & (DMA_TN_MASK[DMA_CH] | {20{DMD[DMA_CH].MOD}});
			
			//A-BUS 02000000-058FFFFF
			if (ABUS_WAIT_CNT && CE_R) ABUS_WAIT_CNT <= ABUS_WAIT_CNT - 6'd1;
			if (DSTA.DACSA && ABUS_DMA_START && CE_R) ABUS_DMA_START <= 0;
			ABUS_READ_ACK = 0;
			ABUS_READ_DONE <= 0;
			ABUS_DATA_ACK = 0;
			ABUS_WRITE_DONE = 0;
			case (ABUS_ST)
				ABUS_IDLE : if (CE_R) begin
					if (CPU_ABUS_REQ) begin
						ABUS_A1 <= ABUS_CA_INNER[1];
						CPU_ABUS_REQ <= 0;
						CPU_ABUS_ACT <= 1;
//						ABUS_ST <= ABUS_ACCESS;
						if      (!ABUS_CCS1N_INNER)  ACS0_N <= 0;
						else if (!ABUS_CA_INNER[24]) ACS1_N <= 0;
						else                    ACS2_N <= 0;
						
						AAS_N <= 0;
						if (!(&ABUS_CDQMN_INNER[3:2]) || !ABUS_CRDN_INNER) begin
							AA <= !ABUS_CCS1N_INNER ? {1'b1,ABUS_CA_INNER[24:2],2'b00} : {1'b0,ABUS_CA_INNER[24:2],2'b00};
							ADO <= ABUS_CDI_INNER[31:16];
							ARD_N <= ABUS_CRDN_INNER;
							AWRL_N <= ABUS_CDQMN_INNER[2];
							AWRU_N <= ABUS_CDQMN_INNER[3];
							ABUS_LONG <= ~&ABUS_CDQMN_INNER[1:0] | (ABUS_CA_INNER[24:20] == 5'h18 & ~ABUS_CA_INNER[19] & ~ABUS_CCS2N_INNER & ~ABUS_CRDN_INNER) | (ABUS_CA_INNER[24:20] < 5'h18 & ~ABUS_CCS2N_INNER & ~ABUS_CRDN_INNER) | (~ABUS_CCS1N_INNER & ~ABUS_CRDN_INNER);
						end else begin //end else if (!(&ABUS_CDQMN_INNER[1:0])) begin
							AA <= !ABUS_CCS1N_INNER ? {1'b1,ABUS_CA_INNER[24:2],2'b10} : {1'b0,ABUS_CA_INNER[24:2],2'b10};
							ADO <= ABUS_CDI_INNER[15:0];
							ARD_N <= ABUS_CRDN_INNER;
							AWRL_N <= ABUS_CDQMN_INNER[0];
							AWRU_N <= ABUS_CDQMN_INNER[1];
							ABUS_LONG <= 0;
						end
						ABUS_WAIT_CNT <= !ABUS_CCS1N_INNER  ? ASR0.A0NW + 6'd3 : 
						                 !ABUS_CA_INNER[24] ? ASR0.A1NW + 6'd3 : 
											  !ABUS_CA_INNER[23] ? ASR1.A3NW + 6'd3 : '0;
						ABUS_ST <= ABUS_WAIT;
					end
					else if (DMA_READ_A && !DMA_RA_ERR && DMA_DSP) begin
						if (!DSP_DMA_WE) begin
							ABUS_A1 <= DMA_RA[1];
							ABUS_DMA_START <= 1;
							ABUS_ST <= ABUS_DMA_READ;
						end else begin
							
						end
					end
					else if (DMA_READ_A && !DMA_WA_ERR && !DMA_RA_ERR && !DMA_DSP && (!CBRLS || !DMA_WRITE_C)) begin
						ABUS_A1 <= DMA_RA[1];
						ABUS_DMA_START <= 1;
						ABUS_ST <= ABUS_DMA_READ;
					end
					else if (DMA_WRITE_A && !DMA_WA_ERR && !DMA_RA_ERR && !DMA_DSP && (!CBRLS || !DMA_READ_C)) begin
						ABUS_A1 <= DMA_WA[1];
						ABUS_DMA_START <= 1;
						ABUS_ST <= ABUS_DMA_WRITE;
					end
				end
				
				ABUS_ADDR_H: if (CE_R) begin
					if      (!ABUS_CCS1N_INNER)  ACS0_N <= 0;
					else if (!ABUS_CA_INNER[24]) ACS1_N <= 0;
					else                    ACS2_N <= 0;
					
					AAS_N <= 0;
					AA <= !ABUS_CCS1N_INNER ? {1'b1,ABUS_CA_INNER[24:2],2'b10} : {1'b0,ABUS_CA_INNER[24:2],2'b10};
					ADO <= ABUS_CDI_INNER[15:0];
					ARD_N <= ABUS_CRDN_INNER;
					AWRL_N <= ABUS_CDQMN_INNER[0];
					AWRU_N <= ABUS_CDQMN_INNER[1];
					ABUS_LONG <= 0;
					ABUS_WAIT_CNT <= !ABUS_CCS1N_INNER  ? ASR0.A0NW + 6'd3 : 
						              !ABUS_CA_INNER[24] ? ASR0.A1NW + 6'd3 : 
										  !ABUS_CA_INNER[23] ? ASR1.A3NW + 6'd3 : '0;
					ABUS_ST <= ABUS_WAIT;
				end
				
				ABUS_WAIT: if (CE_R) begin
					AAS_N <= 1;
					if (AWAIT_N && !ABUS_WAIT_CNT) begin
						ARD_N <= 1;
						AWRL_N <= 1;
						AWRU_N <= 1;
						ACS0_N <= 1;
						ACS1_N <= 1;
						ACS2_N <= 1;
						if (!ABUS_A1) ABUS_BUF[31:16] <= ADI;
						else          ABUS_BUF[15: 0] <= ADI;
						ABUS_ST <= ABUS_NEXT;
					end
				end
				
				ABUS_NEXT: if (CE_R) begin
					if (ABUS_LONG) begin
						ABUS_A1 <= 1;
						ABUS_ST <= ABUS_ADDR_H;
					end else begin
						ABUS_ST <= ABUS_END;
					end
				end
					
				ABUS_END: if (CE_R) begin
					CPU_ABUS_WAIT_CLR <= 1;
					CPU_ABUS_ACT <= 0;
					ABUS_ST <= ABUS_IDLE;
				end
				
				ABUS_DMA_READ: if (CE_R) begin
					if (!DMA_BUF_SIZE[2]) begin
						casez (DMA_RA[26:24])
							3'b0??: ACS0_N <= 0;
							3'b100: ACS1_N <= 0;
							default: ACS2_N <= 0;
						endcase
						AA <= {DMA_RA[25:2],ABUS_A1,1'b0};
						AAS_N <= 0;
						ARD_N <= 0;
						ABUS_READ_ACK = ABUS_A1;
						ABUS_WAIT_CNT <= !DMA_RA[26] ? ASR0.A0NW + 6'd2 : !DMA_RA[24] ? ASR0.A1NW + 6'd2 : !DMA_RA[23] ? ASR1.A3NW + 6'd2 : '0;
						ABUS_ST <= ABUS_DMA_READ_WAIT;
					end
				end
				
				ABUS_DMA_READ_WAIT: if (CE_R) begin
					AAS_N <= 1;
					if (AWAIT_N && !ABUS_WAIT_CNT) begin
						ARD_N <= 1;
						AWRL_N <= 1;
						AWRU_N <= 1;
						ACS0_N <= 1;
						ACS1_N <= 1;
						ACS2_N <= 1;
						
						if (!ABUS_A1) begin
							ABUS_BUF[31:16] <= ADI;
							ABUS_A1 <= 1;
							ABUS_ST <= ABUS_DMA_READ_NEXT;
						end else begin
							ABUS_BUF[15: 0] <= ADI;
							ABUS_A1 <= 0;
							ABUS_READ_DONE <= 1;
							ABUS_WRITE_DONE = ABUS_WRITE_PROCESS;
							ABUS_WRITE_PROCESS <= 0;

							if ((!DMA_DSP && !DMA_RTN) || (DMA_DSP && DSP_DMA_LAST)) begin
								ABUS_ST <= ABUS_DMA_END;
							end else begin
								ABUS_ST <= ABUS_DMA_READ_NEXT;
							end
						end
					end
				end
				
				ABUS_DMA_READ_NEXT: if (CE_R) begin
					ABUS_ST <= ABUS_DMA_READ;
				end
				
				ABUS_DMA_WRITE: if (CE_R) begin
					if ((!DMA_DSP && !DMA_WTN) || (DMA_DSP && DMA_LAST && !DMA_BUF_SIZE)) begin
						ABUS_ST <= ABUS_DMA_END;
					end else if (DMA_BUF_SIZE && (DMA_BUF_SIZE[2:1] || DMA_WA[0] || (DMA_WTN_LESS2 && DMA_WTN[0]))) begin
						casez (DMA_WA[26:24])
							3'b0??: ACS0_N <= 0;
							3'b100: ACS1_N <= 0;
							default: ACS2_N <= 0;
						endcase
						AA <= DMA_WA[25:0];
						ADO <= {DMA_BUF[DMA_BUF_RPOS+0],DMA_BUF[DMA_BUF_RPOS+1]};
						AAS_N <= 0;
						AWRL_N <= 0;
						AWRU_N <= 0;
						ABUS_DATA_ACK = 1;
						ABUS_WRITE_PROCESS <= 1;
						ABUS_WAIT_CNT <= !DMA_RA[26] ? ASR0.A0NW + 6'd2 : !DMA_RA[24] ? ASR0.A1NW + 6'd2 : !DMA_RA[23] ? ASR1.A3NW + 6'd2 : '0;
						ABUS_ST <= ABUS_DMA_WRITE_WAIT;
					end
				end
				
				ABUS_DMA_WRITE_WAIT: if (CE_R) begin
					AAS_N <= 1;
					if (AWAIT_N && !ABUS_WAIT_CNT) begin
						ARD_N <= 1;
						AWRL_N <= 1;
						AWRU_N <= 1;
						ACS0_N <= 1;
						ACS1_N <= 1;
						ACS2_N <= 1;
						
						if (!ABUS_A1) begin
							ABUS_A1 <= 1;
							ABUS_ST <= ABUS_DMA_WRITE;
						end else begin
							ABUS_A1 <= 0;
							ABUS_WRITE_DONE = ABUS_WRITE_PROCESS;
							ABUS_WRITE_PROCESS <= 0;
							
							if ((!DMA_DSP && !DMA_WTN) || (DMA_DSP && DMA_LAST && !DMA_BUF_SIZE)) begin
								ABUS_ST <= ABUS_DMA_END;
							end else begin
								ABUS_ST <= ABUS_DMA_WRITE;
							end
						end
					end
				end
					
				ABUS_DMA_END: if (CE_R) begin
					if (!DMA_READ_A && !DMA_WRITE_A) begin
						ABUS_ST <= ABUS_IDLE;
					end
				end
			endcase
			
			//B-BUS 05A00000-05FDFFFF
			BREQ_N <= 1;
			if (DSTA.DACSB && BBUS_DMA_START && CE_R) BBUS_DMA_START <= 0;
			BBUS_WRITE_DONE = 0;
			BBUS_DATA_ACK = 0;
			BBUS_READ_ACK = 0;
			BBUS_READ_DONE <= 0;
			if (CE_R) BBUS_IND_DONE <= 0;
			BBUS_WRITE_PAGE = (DMA_WADD == 3'b001) && DMA_WA[22];
			case (BBUS_ST)
				BBUS_IDLE : if (CE_R) begin
					if (CPU_BBUS_REQ) begin
						BBUS_A1 <= BBUS_CA_INNER[1];
						BBUS_RD <= ~BBUS_CRDN_INNER;
						BBUS_WORD <= {~&BBUS_CDQMN_INNER[3:2],~&BBUS_CDQMN_INNER[1:0]} | {2{~BBUS_CRDN_INNER}};
						CPU_BBUS_REQ <= 0;
						CPU_BBUS_ACT <= 1;
						
						if (BBUS_CA_INNER[22]) begin
							case (BBUS_CA_INNER[21])
								1'b0: BCS1_N <= 0;
								1'b1: BCS2_N <= 0;
							endcase
							BDO <= {1'b0,&BBUS_CDQMN_INNER,2'b00,BBUS_CA_INNER[20:9]};
							BDTEN_N <= 1;
							BADDT_N <= 1;
							BBUS_ST <= BBUS_ADDR16_L;
						end else begin
							BBUS_ST <= BBUS_ADDR8_HH;
						end
					end else if (DMA_READ_B && DMA_IND) begin
						case (DMA_IA[22:21])
							2'b01: BCSS_N <= 0;
							2'b10: BCS1_N <= 0;
							2'b11: BCS2_N <= 0;
						endcase
						BDO <= {1'b0,1'b1,2'b11,DMA_IA[20:9]};
						BDTEN_N <= 1;
						BADDT_N <= 1;
						
						BBUS_IND_POS <= '0;
						BBUS_A1 <= 0;
//						BBUS_RD <= 1;
						BBUS_WORD <= 2'b11;
						BBUS_ST <= BBUS_DMA_RADDR1;
					end else if (DMA_READ_B && !DMA_WRITE_B && ((!DMA_DSP && ((!CBRLS && DMA_WRITE_C) || DMA_WRITE_A)) || (DMA_DSP && !DSP_DMA_WE))) begin
						case (DMA_RA[22:21])
							2'b01: BCSS_N <= 0;
							2'b10: BCS1_N <= 0;
							2'b11: BCS2_N <= 0;
						endcase
						BDO <= {1'b0,1'b1,2'b11,DMA_RA[20:9]};
						BDTEN_N <= 1;
						BADDT_N <= 1;
						
						BBUS_A1 <= 0;
//						BBUS_RD <= 1;
						BBUS_WORD <= 2'b11;
						BBUS_DMA_START <= 1;
						BBUS_ST <= BBUS_DMA_RADDR1;
					end else if (DMA_WRITE_B && !DMA_READ_B && ((!DMA_DSP && ((!CBRLS && DMA_READ_C) || DMA_READ_A)) || (DMA_DSP && DSP_DMA_WE))) begin
						case (DMA_WA[22:21])
							2'b01: BCSS_N <= 0;
							2'b10: BCS1_N <= 0;
							2'b11: BCS2_N <= 0;
						endcase
						BDO <= {1'b0,1'b0,{2{BBUS_WRITE_PAGE}},DMA_WA[20:9]};
						BDTEN_N <= 1;
						BADDT_N <= 1;
						
						BBUS_A1 <= 0;
//						BBUS_RD <= 0;
						BBUS_WORD <= 2'b11;
						BBUS_DMA_START <= 1;
						BBUS_ST <= BBUS_DMA_WADDR0;
					end
				end
				
				BBUS_ADDR16_H: if (CE_R) begin
					case (BBUS_CA_INNER[21])
						1'b0: BCS1_N <= 0;
						1'b1: BCS2_N <= 0;
					endcase
					BDO <= {1'b0,&BBUS_CDQMN_INNER,2'b00,BBUS_CA_INNER[20:9]};
					BDTEN_N <= 1;
					BADDT_N <= 1;
					BBUS_ST <= BBUS_ADDR16_L;
				end
				
				BBUS_ADDR16_L: if (CE_R) begin
					if (BBUS_RDY) begin
						if (!BBUS_CRDN_INNER) 
							BDO <= {2'b10,2'b00,4'b0000,BBUS_CA_INNER[8:2],BBUS_A1};
						else if (!(&BBUS_CDQMN_INNER[3:2])) 
							BDO <= {2'b10,BBUS_CDQMN_INNER[3:2],4'b0000,BBUS_CA_INNER[8:1]};
						else
							BDO <= {2'b10,BBUS_CDQMN_INNER[1:0],4'b0000,BBUS_CA_INNER[8:1]};
						BDTEN_N <= 1;
						BADDT_N <= 1;
						BBUS_ST <= BBUS_RD ? BBUS_READ16_START : BBUS_WORD[1] ? BBUS_WRITE16_H : BBUS_WRITE16_L;
					end
				end
				
				BBUS_WRITE16_H: if (CE_R) begin
`ifdef DEBUG
					DBG_BBUS_WAIT_CNT <= DBG_BBUS_WAIT_CNT + 1'd1;
`endif
					BADDT_N <= 0;
					if (BBUS_RDY) begin
						BDO <= BBUS_CDI_INNER[31:16];
						BDTEN_N <= 0;
						BREQ_N <= 0;
						BBUS_WORD[1] <= 0;
						if (BBUS_WORD[0]) begin
							BBUS_ST <= BBUS_WRITE16_L;
						end else if (!BBUS_CA_INNER[21]) begin //VDP1
							BBUS_ST <= BBUS_WRITE16_END0;
						end else begin //VDP2
							CPU_BBUS_WAIT_CLR <= 1;
							BBUS_ST <=  BBUS_WRITE16_END2;
						end
`ifdef DEBUG
					DBG_BBUS_WAIT_CNT <= '0;
`endif
					end
				end
				
				BBUS_WRITE16_L: if (CE_R) begin
`ifdef DEBUG
					DBG_BBUS_WAIT_CNT <= DBG_BBUS_WAIT_CNT + 1'd1;
`endif
					BADDT_N <= 0;
					if (BBUS_RDY) begin
						BDO <= BBUS_CDI_INNER[15:0];
						BDTEN_N <= 0;
						BREQ_N <= 0;
						BBUS_WORD[0] <= 0;
						if (!BBUS_CA_INNER[21]) begin //VDP1
							BBUS_ST <= BBUS_WRITE16_END0;
						end else begin //VDP2
							CPU_BBUS_WAIT_CLR <= 1;
							BBUS_ST <= BBUS_WRITE16_END2;
						end
`ifdef DEBUG
					DBG_BBUS_WAIT_CNT <= '0;
`endif
					end
				end
				
				BBUS_WRITE16_END0: if (CE_R) begin
					BDTEN_N <= 1;
					BCS1_N <= 1;
					BCS2_N <= 1;
					BBUS_ST <= BBUS_WRITE16_END1;
				end
				
				BBUS_WRITE16_END1: if (CE_R) begin
					BBUS_ST <= BBUS_WRITE16_END2;
				end
				
				BBUS_WRITE16_END2: if (CE_R) begin
					BDTEN_N <= 1;
					BCS1_N <= 1;
					BCS2_N <= 1;
					CPU_BBUS_ACT <= 0;
					if (!CPU_BBUS_WAIT_CLR) CPU_BBUS_WAIT_CLR <= 1;
					BBUS_ST <= BBUS_IDLE;
				end
				
				BBUS_READ16_START: if (CE_R) begin
					if (BBUS_RDY) begin
						BADDT_N <= 0;
						BREQ_N <= 0;
						
						BBUS_ST <= BBUS_READ16_WAIT;
					end
//					DBG_BBUS_WAIT_CNT <= '0;
				end
					
				BBUS_READ16_WAIT: if (CE_R) begin
`ifdef DEBUG
					DBG_BBUS_WAIT_CNT <= DBG_BBUS_WAIT_CNT + 1'd1;
`endif
					if (BBUS_RDY) begin
						BCS1_N <= 1;
						BCS2_N <= 1;
						if (BBUS_WORD[1]) BBUS_BUF[31:16] <= BDI;
						else              BBUS_BUF[15: 0] <= BDI;
						
						BBUS_WORD[1] <= 0;
						if (BBUS_WORD[1] && BBUS_WORD[0]) begin
							BBUS_A1 <= 1;
							BBUS_ST <= BBUS_CA_INNER[22] && BBUS_CA_INNER[21] ? BBUS_READ_NEXT : BBUS_READ_NEXT2;
						end else begin
							BBUS_ST <= BBUS_READ_END0;
						end
`ifdef DEBUG
					DBG_BBUS_WAIT_CNT <= '0;
`endif
					end
				end
				
				BBUS_ADDR8_WAIT0: if (CE_R) begin
					if (!BRDYS_N) begin
						BBUS_ST <= BBUS_ADDR8_WAIT1;
					end
				end
				
				BBUS_ADDR8_WAIT1: if (CE_R) begin
					BBUS_ST <= BBUS_ADDR8_HH;
				end
				
				BBUS_ADDR8_HH: if (CE_R) begin
					if (!BRDYS_N) begin
						BCSS_N <= 0;
						BDO <= {1'b0,&BBUS_CDQMN_INNER,2'b00,BBUS_CA_INNER[20:9]};
						BDTEN_N <= 1;
						BADDT_N <= 1;
						BBUS_ST <= BBUS_ADDR8_HL;
					end else begin
						BBUS_ST <= BBUS_ADDR8_WAIT0;
					end
				end
				
				BBUS_ADDR8_HL: if (CE_R) begin
					if (!BBUS_CRDN_INNER) 
						BDO <= {2'b10,2'b00,4'b0000,BBUS_CA_INNER[8:2],BBUS_A1};
					else if (!(&BBUS_CDQMN_INNER[3:2])) 
						BDO <= {2'b10,BBUS_CDQMN_INNER[3:2],4'b0000,BBUS_CA_INNER[8:1]};
					else
						BDO <= {2'b10,BBUS_CDQMN_INNER[1:0],4'b0000,BBUS_CA_INNER[8:1]};
					BDTEN_N <= 1;
					BADDT_N <= 1;
					BBUS_ST <= BBUS_ADDR8_LH;
				end
				
				BBUS_ADDR8_LH: if (CE_R) begin
					BADDT_N <= 0;
					BBUS_ST <= BBUS_ADDR8_LL;
				end
				
				BBUS_ADDR8_LL: if (CE_R) begin
					BBUS_ST <= BBUS_RD ? BBUS_READ8_START : BBUS_WORD[1] ? BBUS_WRITE8_HH : BBUS_WRITE8_LH;
				end
				
				BBUS_WRITE8_HH: if (CE_R) begin
//					if (!BRDYS_N) begin
						BDTEN_N <= 0;
						BADDT_N <= 0;
						BBUS_ST <= BBUS_WRITE8_HL;
//					end
				end
				
				BBUS_WRITE8_HL: if (CE_R) begin
					BDO <= BBUS_CDI_INNER[31:16];
					BDTEN_N <= 0;
					BADDT_N <= 0;
					BREQ_N <= 0;
					
					BBUS_WORD[1] <= 0;
					if (BBUS_WORD[0]) begin
						BBUS_ST <= BBUS_WRITE8_LH;
					end else begin
						BBUS_ST <= BBUS_WRITE8_END0;
					end
				end
				
				BBUS_WRITE8_LH: if (CE_R) begin
					if (!BRDYS_N) begin
						BDTEN_N <= 0;
						BADDT_N <= 0;
						BBUS_ST <= BBUS_WRITE8_LL;
					end
				end
				
				BBUS_WRITE8_LL: if (CE_R) begin
					BDO <= BBUS_CDI_INNER[15:0];
					BDTEN_N <= 0;
					BADDT_N <= 0;
					BREQ_N <= 0;

					BBUS_WORD[0] <= 0;
					BBUS_ST <= BBUS_WRITE8_END0;
				end
				
				BBUS_WRITE8_END0: if (CE_R) begin
					BDTEN_N <= 1;
					BCSS_N <= 1;
					BBUS_ST <= BBUS_WRITE8_END1;
				end
				
				BBUS_WRITE8_END1: if (CE_R) begin
					BBUS_ST <= BBUS_WRITE8_END2;
				end
				
				BBUS_WRITE8_END2: if (CE_R) begin
					CPU_BBUS_ACT <= 0;
					CPU_BBUS_WAIT_CLR <= 1;
					BBUS_ST <= BBUS_IDLE;
				end
				
				BBUS_READ8_START: if (CE_R) begin
//					if (!BRDYS_N) begin
						BADDT_N <= 0;
						BREQ_N <= 0;
						
						BBUS_ST <= BBUS_READ8_WAIT;
//					end
				end
				
				BBUS_READ8_WAIT: if (CE_R) begin
					if (!BRDYS_N) begin
						BBUS_ST <= BBUS_READ8_H;
					end
				end
				
				BBUS_READ8_H: if (CE_R) begin
					BBUS_ST <= BBUS_READ8_L;
				end
				
				BBUS_READ8_L: if (CE_R) begin
					BCSS_N <= 1;
					if (BBUS_WORD[1]) BBUS_BUF[31:16] <= BDI;
					else              BBUS_BUF[15: 0] <= BDI;
					
					BBUS_WORD[1] <= 0;
					if (BBUS_WORD[1] && BBUS_WORD[0]) begin
						BBUS_A1 <= 1;
						BBUS_ST <= BBUS_READ_NEXT2;
					end else begin
						BBUS_ST <= BBUS_READ_END0;
					end
				end
				
				BBUS_READ_NEXT: if (CE_R) begin
					BBUS_ST <= BBUS_READ_NEXT2;
				end
				
				BBUS_READ_NEXT2: if (CE_R) begin
					BBUS_ST <= !BBUS_CA_INNER[22] ? BBUS_ADDR8_HH : BBUS_ADDR16_H;
				end
				
				BBUS_READ_END0: if (CE_R) begin
					BBUS_ST <= BBUS_READ_END1;
				end
				
				BBUS_READ_END1: if (CE_R) begin
					BBUS_ST <= BBUS_READ_END2;
				end
				
				BBUS_READ_END2: if (CE_R) begin
					CPU_BBUS_WAIT_CLR <= 1;
					CPU_BBUS_ACT <= 0;
					BBUS_ST <= BBUS_IDLE;
				end
				
				BBUS_DMA_RADDR1: if (CE_R) begin
					if (!DMA_IND)
						BDO <= {4'b1000,4'b0000,DMA_RA[8:1]};
					else
						BDO <= {4'b1000,4'b0000,DMA_IA[8:1]};
					BBUS_ST <= BBUS_DMA_RADDR2;
`ifdef DEBUG
					DBG_BBUS_WAIT_CNT <= '0;
`endif
				end
				
				BBUS_DMA_RADDR2: if (CE_R) begin
					BADDT_N <= 0;
					if (!DMA_BUF_SIZE) begin
						BREQ_N <= 0;
						if (!DMA_IND) BBUS_READ_ACK = 1;
						BBUS_READ_PROCESS <= 1;
						BBUS_ST <= BBUS_DMA_READ;
					end
				end
					
				BBUS_DMA_READ: if (CE_R) begin
					if (BBUS_RDY) begin
						if (BBUS_WORD[1]) begin
							BBUS_BUF[31:16] <= BDI;
							BREQ_N <= 0;
							BBUS_WORD[1] <= 0;
						end else if (!DMA_BUF_SIZE[2]) begin
							if (BBUS_READ_PROCESS) begin
								BBUS_BUF[15: 0] <= BDI;
								if (!DMA_IND) BBUS_READ_DONE <= 1;
								if ( DMA_IND) BBUS_IND_DONE <= 1;
								BBUS_IND_POS <= BBUS_IND_POS + 2'd1;
							end
							BBUS_READ_PROCESS <= 0;
							
							if ((!DMA_DSP && !DMA_IND && !DMA_RTN) || (DMA_DSP && !DMA_IND && DSP_DMA_LAST) || (DMA_IND && BBUS_IND_POS == 2'd2)) begin
								BBUS_ST <= BBUS_DMA_END;
							end else begin
								BREQ_N <= 0;
								BBUS_WORD[1] <= 1;
								if (!DMA_IND) BBUS_READ_ACK = 1;
								BBUS_READ_PROCESS <= 1;
							end
						end
					end
				end
				
				BBUS_DMA_WADDR0: if (CE_R) begin
					if (DMA_WA[0])
						BDO <= {2'b10,2'b10,4'b0000,DMA_WA[8:1]};
					else if (DMA_WTN_LESS2 && DMA_WTN[0])
						BDO <= {2'b10,2'b01,4'b0000,DMA_WA[8:1]};
					else
						BDO <= {2'b10,2'b00,4'b0000,DMA_WA[8:1]};
					BBUS_ST <= !DMA_WA[22] ? BBUS_DMA_WADDR1 : BBUS_DMA_WADDR3;
`ifdef DEBUG
					DBG_BBUS_WAIT_CNT <= '0;
`endif
				end
				
				BBUS_DMA_WADDR1: if (CE_R) begin
					BADDT_N <= 0;
					BBUS_ST <= BBUS_DMA_WADDR2;
				end
				
				BBUS_DMA_WADDR2: if (CE_R) begin
					BBUS_ST <= BBUS_DMA_WADDR3;
				end
				
				BBUS_DMA_WADDR3: if (CE_R) begin
`ifdef DEBUG
					DBG_BBUS_WAIT_CNT <= DBG_BBUS_WAIT_CNT + 1'd1;
`endif
					BADDT_N <= 0;
					if (BBUS_RDY) begin
						if (DMA_BUF_SIZE && (DMA_BUF_SIZE[2:1] || DMA_WA[0] || (DMA_WTN_LESS2 && DMA_WTN[0]))) begin
							case (DMA_WA[0])
								1'b0: BDO <= {DMA_BUF[DMA_BUF_RPOS+0],DMA_BUF[DMA_BUF_RPOS+1]};
								1'b1: BDO <= {DMA_BUF[DMA_BUF_RPOS+0],DMA_BUF[DMA_BUF_RPOS+0]};
							endcase
							BDTEN_N <= 0;
							BREQ_N <= 0;
							BBUS_DATA_ACK = 1;
							BBUS_WRITE_PROCESS <= 1;
							BBUS_WRITE_UNALIGNED <= DMA_WA[0];
							BBUS_ST <= BBUS_DMA_WRITE;
`ifdef DEBUG
							DBG_BBUS_WAIT_CNT <= '0;
`endif
						end
					end
				end
					
				BBUS_DMA_WRITE: if (CE_R) begin
`ifdef DEBUG
					DBG_BBUS_WAIT_CNT <= DBG_BBUS_WAIT_CNT + 1'd1;
`endif
					BDTEN_N <= 1;
					if ((!DMA_DSP && !DMA_WTN) || (DMA_DSP && DMA_LAST && !DMA_BUF_SIZE)) begin
						BBUS_WRITE_DONE = BBUS_WRITE_PROCESS;
						BBUS_WRITE_PROCESS <= 0;
						BBUS_ST <= BBUS_DMA_END;
					end else if (BBUS_RDY) begin
						BBUS_WRITE_DONE = BBUS_WRITE_PROCESS;
						BBUS_WRITE_PROCESS <= 0;
						if (!BBUS_WRITE_PAGE) begin
							BDO <= {1'b0,1'b0,2'b00,DMA_WA[20:9]};
							BADDT_N <= 1;
							BBUS_ST <= BBUS_DMA_WADDR0;
						end else if (BBUS_WRITE_UNALIGNED || (DMA_WTN_LESS2 && DMA_WTN[0])) begin
							BDO <= {1'b0,1'b0,2'b11,DMA_WA[20:9]};
							BADDT_N <= 1;
							BBUS_ST <= BBUS_DMA_WADDR0;
						end else if (DMA_WA[8:1] == 8'd255) begin
							BBUS_ST <= BBUS_DMA_PAGE;
						end else if (DMA_BUF_SIZE && (DMA_BUF_SIZE[2:1] || (DMA_WTN_LESS2 && DMA_WTN[0]))) begin
							case (DMA_WA[0])
								1'b0: BDO <= {DMA_BUF[DMA_BUF_RPOS+0],DMA_BUF[DMA_BUF_RPOS+1]};
								1'b1: BDO <= {DMA_BUF[DMA_BUF_RPOS+0],DMA_BUF[DMA_BUF_RPOS+0]};
							endcase
							BDTEN_N <= 0;
							BREQ_N <= 0;
							BBUS_DATA_ACK = 1;
							BBUS_WRITE_PROCESS <= 1;
`ifdef DEBUG
							DBG_BBUS_WAIT_CNT <= '0;
`endif
						end
						BBUS_WRITE_UNALIGNED <= 0;
					end
				end
				
				BBUS_DMA_PAGE: if (CE_R) begin
					BDO <= {1'b0,1'b0,2'b11,DMA_WA[20:9]};
					BADDT_N <= 1;
					BBUS_ST <= BBUS_DMA_WADDR0;
				end
					
				BBUS_DMA_END: if (CE_R) begin
					BCSS_N <= 1;
					BCS1_N <= 1;
					BCS2_N <= 1;
					if (!DMA_READ_B && !DMA_WRITE_B)
						BBUS_ST <= BBUS_IDLE;
				end
			endcase
		
			//CBUS 06000000-06FFFFFF
			CBUS_RD <= 0;
			CBUS_WR <= '0;
			CBUS_IND_DONE = 0;
			CBUS_DATA_ACK = 0;
			CBUS_READ_ACK = 0;
			CBUS_READ_DONE = 0;
			CBUS_DMA_OUT <= 0;
			case (CBUS_ST)
				CBUS_IDLE: if (CE_R) begin
					if ((DMA_READ_C && !DMA_WRITE_C && !DMA_WA_ERR && (!DMA_WRITE_A || ABUS_ST == ABUS_IDLE) && (!DMA_WRITE_B || BBUS_ST == BBUS_IDLE) && !DMA_IND) || 
					    (DMA_WRITE_C && !DMA_READ_C && !DMA_RA_ERR && (!DMA_READ_A || ABUS_ST == ABUS_IDLE) && (!DMA_READ_B || BBUS_ST == BBUS_IDLE) && !DMA_IND)) begin
						CBUS_ST <= CBRLS ? CBUS_REQUEST : CBUS_INIT;
					end
					else if (DMA_READ_C && !DMA_WRITE_C && DMA_IND) begin
						CBUS_ST <= CBUS_REQUEST;
					end
					else if (!CBRLS && !DMA_READ_C && !DMA_WRITE_C && !DMA_IND) begin
						CBUS_ST <= CBUS_RELEASE;
					end
				end
				
				CBUS_REQUEST: if (CE_R) begin
					CBUS_ST <= CBUS_INIT;
				end
				
				CBUS_INIT: if (CE_R) begin
					if (!CBRLS) begin
						if (!DMA_IND) CBUS_DMA_START <= 1;
						CBUS_ST <= CBUS_START;
					end
				end
				
				CBUS_START: if (CE_R) begin
					if (DMA_READ_C && DMA_IND) begin
						CBUS_A <= {DMA_IA[26:4],4'b0000};
						CBUS_RD <= 1;
						CBUS_CS <= 1;
						CBUS_BURST <= 1;
						CBUS_IND_POS <= '0;
						CBUS_ST <= CBUS_IND_READ;
					end
					else if (DMA_READ_C && !DMA_IND) begin
						CBUS_A <= {DMA_RA[26:4],4'b0000};
						CBUS_RD <= 1;
						CBUS_CS <= 1;
						CBUS_BURST <= DMA_DSP;
						CCACHE_RADDR <= DMA_RA[4:2];
						CCACHE_FULL <= '{2{0}};
						CBUS_READ_ACK = 1;
						CBUS_ST <= CBUS_READ;
					end
					else if (DMA_WRITE_C && DMA_BUF_SIZE && (DMA_BUF_SIZE[2] || DMA_WA[1:0] || (DMA_WTN_LESS4 && DMA_WTN[1:0]))) begin
						CBUS_A <= {DMA_WA[26:2],2'b00};
						if (DMA_DSP) begin
							CBUS_D <= {DMA_BUF[DMA_BUF_RPOS+0],DMA_BUF[DMA_BUF_RPOS+1],DMA_BUF[DMA_BUF_RPOS+2],DMA_BUF[DMA_BUF_RPOS+3]};
							CBUS_WR <= 4'b1111;
						end else begin
							case (DMA_WA[1:0])
								2'b00: CBUS_D <= {DMA_BUF[DMA_BUF_RPOS+0],DMA_BUF[DMA_BUF_RPOS+1],DMA_BUF[DMA_BUF_RPOS+2],DMA_BUF[DMA_BUF_RPOS+3]};
								2'b01: CBUS_D <= {DMA_BUF[DMA_BUF_RPOS+0],DMA_BUF[DMA_BUF_RPOS+0],DMA_BUF[DMA_BUF_RPOS+1],DMA_BUF[DMA_BUF_RPOS+2]};
								2'b10: CBUS_D <= {DMA_BUF[DMA_BUF_RPOS+0],DMA_BUF[DMA_BUF_RPOS+0],DMA_BUF[DMA_BUF_RPOS+0],DMA_BUF[DMA_BUF_RPOS+1]};
								2'b11: CBUS_D <= {DMA_BUF[DMA_BUF_RPOS+0],DMA_BUF[DMA_BUF_RPOS+0],DMA_BUF[DMA_BUF_RPOS+0],DMA_BUF[DMA_BUF_RPOS+0]};
							endcase
							if (DMA_WTN_LESS4)
								case (DMA_WA[1:0])
									2'b00: case (DMA_WTN[1:0])
										2'b00: ;
										2'b01: CBUS_WR <= 4'b1000;
										2'b10: CBUS_WR <= 4'b1100;
										2'b11: CBUS_WR <= 4'b1110;
									endcase
									2'b01: case (DMA_WTN[1:0])
										2'b00: ;
										2'b01: CBUS_WR <= 4'b0100;
										2'b10: CBUS_WR <= 4'b0110;
										2'b11: CBUS_WR <= 4'b0111;
									endcase
									2'b10: case (DMA_WTN[1:0])
										2'b00: ;
										2'b01: CBUS_WR <= 4'b0010;
										2'b10: CBUS_WR <= 4'b0011;
										2'b11: CBUS_WR <= 4'b0011;
									endcase
									2'b11: case (DMA_WTN[1:0])
										2'b00: ;
										2'b01: CBUS_WR <= 4'b0001;
										2'b10: CBUS_WR <= 4'b0001;
										2'b11: CBUS_WR <= 4'b0001;
									endcase
								endcase
							else
								case (DMA_WA[1:0])
									2'b00: CBUS_WR <= 4'b1111;
									2'b01: CBUS_WR <= 4'b0111;
									2'b10: CBUS_WR <= 4'b0011;
									2'b11: CBUS_WR <= 4'b0001;
								endcase
						end
						CBUS_CS <= 1;
						CBUS_DATA_ACK = 1;
						CBUS_ST <= CBUS_WRITE_WAIT;
					end
				end
				
				CBUS_IND_READ: if (CE_R) begin
					if (ECWAIT_N) begin
						CBUS_A <= CBUS_A + 27'd4;
						CBUS_RD <= 1;
						CBUS_IND_POS <= CBUS_IND_POS + 3'd1;
						if (CBUS_IND_POS == 3'd3) begin
							CBUS_BURST <= 0;
						end
						if (CBUS_IND_POS == 3'd7) begin
							CBUS_RD <= 0;
							CBUS_CS <= 0;
							CBUS_ST <= CBUS_IDLE;
						end
						if (CBUS_A == DMA_IA && DMA_IND_REG <= 2'd2) CBUS_IND_DONE = 1;
					end
				end
				
				CBUS_READ: if (CE_R) begin
					if (ECWAIT_N && !CCACHE_FULL[CBUS_A[4]]) begin
						if (CBUS_RFS_PEND) begin
							CBUS_RFS <= CBUS_RFS + 4'd1;
							if (CBUS_RFS == 4'd15) CBUS_RFS_PEND <= 0;
						end else if (CBUS_RAS_PEND) begin
							CBUS_RFS <= CBUS_RFS + 4'd1;
							if (CBUS_RFS == 4'd3) begin
								CBUS_RFS <= '0;
								CBUS_RAS_PEND <= 0;
							end
						end else begin
							CBUS_A <= CBUS_A + 27'd4;
							CBUS_RD <= 1;
							/*if (CBUS_A[10:2] == 9'h1FF && !DMA_DSP && !RAMH_SLOW) begin
								CBUS_RFS_PEND <= 1;
							end else*/ if (CBUS_A[9:2] == 8'hFF && !DMA_DSP && !RAMH_SLOW) begin
								CBUS_RAS_PEND <= 1;
							end
						end
						if (CBUS_A[3:2] == 2'b11) begin
							CCACHE_FULL[CBUS_A[4]] <= 1;
						end
					end
					if (CBUS_DMA_OUT) begin
						if ((DMA_DSP && DSP_DMA_LAST) || (!DMA_DSP && !DMA_RTN)) begin
							CBUS_BURST <= 0;
							CBUS_ST <= CBUS_READ_END;
						end else
							CBUS_READ_ACK = 1;
					end
				end else if (CE_F) begin
					if (CCACHE_FULL[CCACHE_RADDR[2]] && !DMA_BUF_SIZE[2]) begin
						CCACHE_RADDR <= DMA_RA[4:2];
						if (CCACHE_RADDR[1:0] == 2'b11 && ((DMA_DSP && DMA_WADD) || (!DMA_DSP && DMA_RADD))) CCACHE_FULL[CCACHE_RADDR[2]] <= 0;
						CBUS_DMA_OUT <= 1;
						CBUS_READ_DONE = 1;
					end
				end
				
				CBUS_READ_END: if (CE_R) begin
					if (ECWAIT_N) begin
						if (CBUS_A[3:2] != 2'b11 && !RAMH_SLOW) begin
							CBUS_A <= CBUS_A + 27'd4;
							CBUS_RD <= 1;
						end
						else if (DSTA.DACSA || DSTA.DACSB || DSTA.DACSD) begin
							CBUS_RD <= 0;
							if (FAST) begin
								CBUS_DMA_START <= 0;
								CBUS_CS <= 0;
								CBUS_ST <= CBUS_RELEASE;
							end else begin
								CBUS_ST <= CBUS_REFRESH;
							end
						end
					end
				end
				
				CBUS_WRITE_WAIT: if (CE_R) begin
					if (ECWAIT_N) begin
						CBUS_ST <= CBUS_WRITE;
					end
				end
				
				CBUS_WRITE: if (CE_R) begin
//					if (ECWAIT_N) begin
						if (CBUS_RFS_PEND) begin
							CBUS_RFS <= CBUS_RFS + 4'd1;
							if (CBUS_RFS == 4'd7) CBUS_RFS_PEND <= 0;
						end else if (CBUS_RAS_PEND) begin
							CBUS_RFS <= CBUS_RFS + 4'd1;
							if (CBUS_RFS == 4'd3) begin
								CBUS_RFS <= '0;
								CBUS_RAS_PEND <= 0;
							end
						end else if (DMA_BUF_SIZE && (DMA_BUF_SIZE[2] || (DMA_WTN_LESS4 && DMA_WTN[1:0] && DMA_BUF_SIZE >= {1'b0,DMA_WTN[1:0]}))) begin
							CBUS_A <= {DMA_WA[26:2],2'b00};
							CBUS_D <= {DMA_BUF[DMA_BUF_RPOS+0],DMA_BUF[DMA_BUF_RPOS+1],DMA_BUF[DMA_BUF_RPOS+2],DMA_BUF[DMA_BUF_RPOS+3]};
							if (DMA_DSP)
								CBUS_WR <= 4'b1111;
							else if (DMA_WTN_LESS4)
								case (DMA_WTN[1:0])
									2'b00: ;
									2'b01: CBUS_WR <= 4'b1000;
									2'b10: CBUS_WR <= 4'b1100;
									2'b11: CBUS_WR <= 4'b1110;
								endcase
							else
								CBUS_WR <= 4'b1111;
							CBUS_DATA_ACK = 1;
							
							/*if (CBUS_A[10:2] == 9'h1FF && !DMA_DSP && !RAMH_SLOW) begin
								CBUS_RFS_PEND <= 1;
							end else*/ if (CBUS_A[9:2] == 8'hFF && !DMA_DSP && !RAMH_SLOW) begin
								CBUS_RAS_PEND <= 1;
							end
							CBUS_ST <= CBUS_WRITE_WAIT;
						end
						else if ((!DMA_DSP && !DMA_WTN) || (DMA_DSP && DMA_LAST)) begin
							CBUS_WR <= 4'b0000;
							if (FAST) begin
								CBUS_DMA_START <= 0;
								CBUS_CS <= 0;
								CBUS_ST <= CBUS_RELEASE;
							end else begin
								CBUS_ST <= CBUS_WRITE_END;
							end
						end
//					end
				end
				
				CBUS_WRITE_END: if (CE_R) begin
					CBUS_RFS <= CBUS_RFS + 4'd1;
					if (CBUS_RFS == 4'd3) begin
						CBUS_RFS <= '0;
						CBUS_ST <= CBUS_REFRESH;
					end
				end
				
				CBUS_REFRESH: if (CE_R) begin
					CBUS_RFS <= CBUS_RFS + 4'd1;
					if (CBUS_RFS == 4'd3) begin
						CBUS_RFS <= '0;
						CBUS_DMA_START <= 0;
						CBUS_CS <= 0;
						CBUS_ST <= CBUS_RELEASE;
					end
				end
				
				CBUS_RELEASE: if (CE_R) begin
					if (!DMA_READ_C && !DMA_WRITE_C) begin
						CBUS_ST <= CBUS_END;
					end
				end
				
				CBUS_END: if (CE_R) begin
					if (CBRLS) begin
						CBUS_ST <= CBUS_IDLE;
					end
				end
			endcase
			
			//DMA
			DMA_END = 0;
			case (DMA_ST)
				DMA_IDLE: if (CE_R) begin
					DSTA.D0MV <= 0;//?
					DSTA.D1MV <= 0;//?
					DSTA.D2MV <= 0;//?
					DSTA.DDMV <= 0;//?
					if (DMA_PEND[3]) begin
						DMA_PEND[3] <= 0;
						DMA_RA <= DSP_DR;
						DMA_WA <= DSP_DW;
						DMA_RADD <= DSP_ADD[0];
						DMA_WADD <= DSP_ADD;
							
						DMA_DSP <= 1;
						DMA_IND <= 0;
						DMA_CH <= 2'd3;
						DMA_ST <= DMA_SELECT;
						DSTA.DDWT <= 0;
						DSTA.DDMV <= 1;
					end else if (DMA_PEND[0]) begin
						DMA_PEND[0] <= 0;
						if (!DMD[0].MOD) begin
							DMA_RA <= DR[0][26:0];
							DMA_WA <= DW[0][26:0];
							DMA_RTN <= DC[0][19:0];
							DMA_WTN <= DC[0][19:0];
							DMA_RADD <= DAD[0].DRA;
							DMA_WADD <= DAD[0].DWA;
							DMA_IND <= 0;
							DMA_ST <= DMA_SELECT;
						end else begin
							DMA_IA <= {DW[0][26:2],2'b00};
							DMA_IND <= 1;
							DMA_ST <= DMA_IND_START;
						end
						DMA_CH <= 2'd0;
						DMA_RUN[0] <= 1;
						DSTA.D0WT <= 0;
						DSTA.D0MV <= 1;
					end else if (DMA_PEND[1]) begin
						DMA_PEND[1] <= 0;
						if (!DMD[1].MOD) begin
							DMA_RA <= DR[1][26:0];
							DMA_WA <= DW[1][26:0];
							DMA_RTN <= DC[1][19:0];
							DMA_WTN <= DC[1][19:0];
							DMA_RADD <= DAD[1].DRA;
							DMA_WADD <= DAD[1].DWA;
							DMA_IND <= 0;
							DMA_ST <= DMA_SELECT;
						end else begin
							DMA_IA <= {DW[1][26:2],2'b00};
							DMA_IND <= 1;
							DMA_ST <= DMA_IND_START;
						end
						DMA_CH <= 2'd1;
						DMA_RUN[1] <= 1;
						DSTA.D1WT <= 0;
						DSTA.D1MV <= 1;
					end else if (DMA_PEND[2]) begin
						DMA_PEND[2] <= 0;
						if (!DMD[2].MOD) begin
							DMA_RA <= DR[2][26:0];
							DMA_WA <= DW[2][26:0];
							DMA_RTN <= DC[2][19:0];
							DMA_WTN <= DC[2][19:0];
							DMA_RADD <= DAD[2].DRA;
							DMA_WADD <= DAD[2].DWA;
							DMA_IND <= 0;
							DMA_ST <= DMA_SELECT;
						end else begin
							DMA_IA <= {DW[2][26:2],2'b00};
							DMA_IND <= 1;
							DMA_ST <= DMA_IND_START;
						end
						DMA_CH <= 2'd2;
						DMA_RUN[2] <= 1;
						DSTA.D2WT <= 0;
						DSTA.D2MV <= 1;
					end
`ifdef DEBUG
					DBG_WAIT_CNT <= '0;
					DMA_BUF_SIZE_ERR <= 0;
					DMA_BUF_POS_ERR <= 0;
`endif
				end
				
				DMA_IND_START: if (CE_R) begin
					if (DMA_IA[26:16] >= 11'h5A0 && DMA_IA[26:16] < 11'h5FE) begin
						if (BBUS_ST == BBUS_IDLE) begin
							DMA_READ_B <= 1;
							DMA_IND_REG <= 2'd0;
							DMA_ST <= DMA_IND_READ_BBUS;
						end
					end
					else if (DMA_IA[26:24] == 3'h6) begin
						if (CBUS_ST == CBUS_IDLE) begin
							DMA_READ_C <= 1;
							DMA_IND_REG <= 2'd0;
							DMA_ST <= DMA_IND_READ_CBUS;
						end
					end
				end
				
				DMA_IND_READ_BBUS: if (CE_R) begin
					if (BBUS_IND_DONE) begin
						case (DMA_IND_REG)
							2'd0: {DMA_RTN,DMA_WTN} <= {2{BBUS_BUF[19:0]}};
							2'd1: DMA_WA <= BBUS_BUF[26:0];
							2'd2: {DMA_EC,DMA_RA} <= {BBUS_BUF[31],BBUS_BUF[26:0]};
						endcase
						
						DMA_IND_REG <= DMA_IND_REG + 2'd1;
						if (DMA_IND_REG == 2'd2) begin
							DMA_RADD <= DAD[DMA_CH].DRA;
							DMA_WADD <= DAD[DMA_CH].DWA;
							DMA_READ_B <= 0;
							DMA_ST <= DMA_IND_END;
						end
					end
				end
				
				DMA_IND_READ_CBUS: if (CE_R) begin
					if (CBUS_IND_DONE) begin
						case (DMA_IND_REG)
							2'd0: {DMA_RTN,DMA_WTN} <= {2{ECDI[19:0]}};
							2'd1: DMA_WA <= ECDI[26:0];
							2'd2: {DMA_EC,DMA_RA} <= {ECDI[31],ECDI[26:0]};
						endcase
						
						DMA_IND_REG <= DMA_IND_REG + 2'd1;
						if (DMA_IND_REG == 2'd2) begin
							DMA_RADD <= DAD[DMA_CH].DRA;
							DMA_WADD <= DAD[DMA_CH].DWA;
							DMA_READ_C <= 0;
							DMA_ST <= DMA_IND_END;
						end
					end
				end
				
				DMA_IND_END: if (CE_R) begin
					if (CBUS_ST == CBUS_IDLE && BBUS_ST == BBUS_IDLE) begin
						DMA_ST <= DMA_SELECT;
					end
				end
				
				DMA_SELECT: if (CE_R) begin
`ifdef DEBUG
					DBG_WAIT_CNT <= DBG_WAIT_CNT + 1'd1;
`endif
					DMA_IND <= 0;
					
					DMA_RA_ERR <= 1;
					if (DMA_DSP && DSP_DMA_WE) begin
						DMA_RA_ERR <= 0;
					end
					else if (DMA_RA[26:20] >= 7'h20 && DMA_RA[26:20] < 7'h59) begin
						DMA_READ_A <= 1;
//						DMA_WRITE_DSP <= DMA_DSP & ~DSP_DMA_WE;
						DMA_RA_ERR <= 0;
					end
					else if (DMA_RA[26:16] >= 11'h5A0 && DMA_RA[26:16] < 11'h5FE) begin
						DMA_READ_B <= 1;
//						DMA_WRITE_DSP <= DMA_DSP & ~DSP_DMA_WE;
						DMA_RA_ERR <= 0;
					end
					else if (DMA_RA[26:24] == 3'h6) begin
						DMA_READ_C <= 1;
//						DMA_WRITE_DSP <= DMA_DSP & ~DSP_DMA_WE;
						DMA_RA_ERR <= 0;
					end
					
					DMA_WA_ERR <= 1;
					if (DMA_DSP && !DSP_DMA_WE) begin
						DMA_WA_ERR <= 0;
					end
					else if (DMA_WA[26:20] >= 7'h20 && DMA_WA[26:20] < 7'h59) begin
						DMA_WRITE_A <= 1;
//						DMA_READ_DSP <= DMA_DSP & DSP_DMA_WE;
						DMA_WA_ERR <= 0;
					end
					else if (DMA_WA[26:16] >= 11'h5A0 && DMA_WA[26:16] < 11'h5FE) begin
						DMA_WRITE_B <= 1;
//						DMA_READ_DSP <= DMA_DSP & DSP_DMA_WE;
						DMA_WA_ERR <= 0;
					end
					else if (DMA_WA[26:24] == 3'h6) begin
						DMA_WRITE_C <= 1;
//						DMA_READ_DSP <= DMA_DSP & DSP_DMA_WE;
						DMA_WA_ERR <= 0;
					end
					DMA_RBA <= DMA_RA[1:0];
					DMA_BUF_WPOS <= 3'd0;
					DMA_BUF_RPOS <= 3'd0;
					DMA_BUF_SIZE <= 3'd0;
					DMA_ST <= !DMA_DSP ? DMA_START : DMA_DSP_START;
				end
				
				DMA_START: if (CE_R) begin
`ifdef DEBUG
					DBG_WAIT_CNT <= DBG_WAIT_CNT + 1'd1;
`endif
					DMA_ERR <= 0;
					if (DMA_RA_ERR || DMA_WA_ERR || (DMA_READ_A && DMA_WRITE_A) || (DMA_READ_B && DMA_WRITE_B) || (DMA_READ_C && DMA_WRITE_C)) begin
						DMA_ERR <= 1;
						DMA_ST <= DMA_STOP;
					end else if (DMA_READ_A && DMA_WRITE_B) begin
						if (ABUS_DMA_START && BBUS_DMA_START) begin
							DSTA.DACSA <= 1;
							DSTA.DACSB <= 1;
							DMA_ST <= DMA_ABUS_BBUS;
`ifdef DEBUG
							DBG_WAIT_CNT <= '0;
`endif
						end
					end else if (DMA_READ_A && DMA_WRITE_C) begin
						if (ABUS_DMA_START && CBUS_DMA_START) begin
							DSTA.DACSA <= 1;
							DMA_ST <= DMA_ABUS_CBUS;
`ifdef DEBUG
							DBG_WAIT_CNT <= '0;
`endif
						end
//					end else if (DMA_READ_A && !DMA_WRITE_B && !DMA_WRITE_C) begin
//						if (ABUS_DMA_START) begin
//							DBG_WAIT_CNT <= '0;
//							DMA_ST <= DMA_UNUSED_READ;
//						end
					end else if (DMA_READ_B && DMA_WRITE_C) begin
						if (BBUS_DMA_START && CBUS_DMA_START) begin
							DSTA.DACSB <= 1;
							DMA_ST <= DMA_BBUS_CBUS;
`ifdef DEBUG
							DBG_WAIT_CNT <= '0;
`endif
						end
//					end else if (DMA_READ_B && !DMA_WRITE_A && !DMA_WRITE_C) begin
//						if (BBUS_DMA_START) begin
//							DBG_WAIT_CNT <= '0;
//							DMA_ST <= DMA_UNUSED_READ;
//						end
					end else if (DMA_READ_C && DMA_WRITE_A) begin
						if (ABUS_DMA_START && CBUS_DMA_START) begin
							DSTA.DACSA <= 1;
							DMA_ST <= DMA_CBUS_ABUS;
`ifdef DEBUG
							DBG_WAIT_CNT <= '0;
`endif
						end
					end else if (DMA_READ_C && DMA_WRITE_B) begin
						if (BBUS_DMA_START && CBUS_DMA_START) begin
							DSTA.DACSB <= 1;
							DMA_ST <= DMA_CBUS_BBUS;
`ifdef DEBUG
							DBG_WAIT_CNT <= '0;
`endif
						end
					end 
				end
				
				DMA_CBUS_ABUS: if (CE_R) begin
`ifdef DEBUG
					DBG_WAIT_CNT <= DBG_WAIT_CNT + 1'd1;
`endif
					if (ABUS_DATA_ACK) begin
						DMA_BUF_RPOS <= DMA_BUF_RPOS + DMA_WTN_DEC;
						DMA_BUF_SIZE <= DMA_BUF_SIZE - DMA_WTN_DEC;
						DMA_WTN <= DMA_WTN_NEXT;
					end
					if (ABUS_WRITE_DONE) begin
						if (!DMA_WTN) begin
							DMA_ST <= DMA_STOP;
						end
`ifdef DEBUG
						DBG_WAIT_CNT <= '0;
`endif
					end
				end
				
				DMA_ABUS_BBUS,
				DMA_CBUS_BBUS: if (CE_R) begin
`ifdef DEBUG
					DBG_WAIT_CNT <= DBG_WAIT_CNT + 1'd1;
`endif
					if (BBUS_DATA_ACK) begin
						DMA_BUF_RPOS <= DMA_BUF_RPOS + DMA_WTN_DEC;
						DMA_BUF_SIZE <= DMA_BUF_SIZE - DMA_WTN_DEC;
						DMA_WTN <= DMA_WTN_NEXT;
					end
					if (BBUS_WRITE_DONE) begin
						if (!DMA_WTN) begin
							DMA_ST <= DMA_STOP;
						end
`ifdef DEBUG
						DBG_WAIT_CNT <= '0;
`endif
					end
				end else if (CE_F) begin
					
				end
				
				DMA_ABUS_CBUS,
				DMA_BBUS_CBUS: if (CE_R) begin
`ifdef DEBUG
					DBG_WAIT_CNT <= DBG_WAIT_CNT + 1'd1;
`endif
					if (CBUS_DATA_ACK) begin
						DMA_BUF_RPOS <= DMA_BUF_RPOS + DMA_WTN_DEC;
						DMA_BUF_SIZE <= DMA_BUF_SIZE - DMA_WTN_DEC;
						DMA_WTN <= DMA_WTN_NEXT;
					end
					if (ECWAIT_N && CBUS_ST == CBUS_WRITE) begin
						if (!DMA_WTN) begin
							DMA_ST <= DMA_STOP;
						end
`ifdef DEBUG
						DBG_WAIT_CNT <= '0;
`endif
					end
				end else if (CE_F) begin
					
				end
				
				//DSP
				DMA_DSP_START: if (CE_R) begin
					if (DMA_READ_A && !DSP_DMA_WE && ABUS_DMA_START) begin
						DSTA.DACSA <= 1;
						DSTA.DACSD <= 1;
						DMA_ST <= DMA_ABUS_DSP;
					end else if (DMA_READ_B && !DSP_DMA_WE && BBUS_DMA_START) begin
						DSTA.DACSB <= 1;
						DSTA.DACSD <= 1;
						DMA_ST <= DMA_BBUS_DSP;
					end else if (DMA_WRITE_B && DSP_DMA_WE && BBUS_DMA_START) begin
						DSTA.DACSB <= 1;
						DSTA.DACSD <= 1;
						DMA_ST <= DMA_DSP_BBUS;
					end else if (DMA_READ_C && !DSP_DMA_WE && CBUS_DMA_START) begin
						DSTA.DACSD <= 1;
						DMA_ST <= DMA_CBUS_DSP;
					end else if (DMA_WRITE_C && DSP_DMA_WE && CBUS_DMA_START) begin
						DSTA.DACSD <= 1;
						DMA_ST <= DMA_DSP_CBUS;
					end
`ifdef DEBUG
					DBG_WAIT_CNT <= '0;
`endif
				end
				
				DMA_ABUS_DSP,
				DMA_BBUS_DSP,
				DMA_CBUS_DSP: if (CE_F) begin

				end else if (CE_R) begin
					if (DSP_DMA_END) begin
						DMA_ST <= DMA_STOP;
					end
				end
				
				DMA_DSP_BBUS,
				DMA_DSP_CBUS: if (CE_F) begin
					if (DSP_DMA_REQ && !DMA_BUF_SIZE) begin
						{DMA_BUF[DMA_BUF_WPOS+3'd0],
						 DMA_BUF[DMA_BUF_WPOS+3'd1],
						 DMA_BUF[DMA_BUF_WPOS+3'd2],
						 DMA_BUF[DMA_BUF_WPOS+3'd3]} <= DSP_DMA_DO;
						DMA_BUF_WPOS <= DMA_BUF_WPOS + 3'd4;
						DMA_BUF_SIZE <= DMA_BUF_SIZE + 3'd4;
						DSP_DMA_ACK <= 1;
						if (DSP_DMA_LAST) begin
							DSP_DMA_END <= 1;
						end
					end
				end else if (CE_R) begin
`ifdef DEBUG
					DBG_WAIT_CNT <= DBG_WAIT_CNT + 1'd1;
`endif
					if (BBUS_WRITE_DONE) begin
						if (DMA_LAST && !DMA_BUF_SIZE) begin
							DMA_LAST <= 0;
							DMA_ST <= DMA_STOP;
						end
`ifdef DEBUG
						DBG_WAIT_CNT <= '0;
`endif
					end
					if (BBUS_DATA_ACK) begin
						DMA_BUF_RPOS <= DMA_BUF_RPOS + 3'd2;
						DMA_BUF_SIZE <= DMA_BUF_SIZE - 3'd2;
					end
					
					if (ECWAIT_N && CBUS_ST == CBUS_WRITE) begin
						if (DMA_LAST && !DMA_BUF_SIZE) begin
							DMA_LAST <= 0;
							DMA_ST <= DMA_STOP;
						end
`ifdef DEBUG
						DBG_WAIT_CNT <= '0;
`endif
					end
					if (CBUS_DATA_ACK) begin
						DMA_BUF_RPOS <= DMA_BUF_RPOS + 3'd4;
						DMA_BUF_SIZE <= DMA_BUF_SIZE - 3'd4;
					end
					
					if (DSP_DMA_ACK && DSP_DMA_LAST) begin
						DMA_LAST <= 1;
					end
				end
				
				DMA_STOP: if (CE_R) begin
					if ((!DMA_DSP && DMA_WRITE_A && ABUS_ST == ABUS_DMA_END && DMA_READ_C && CBUS_ST == CBUS_RELEASE) || 
					    (!DMA_DSP && DMA_WRITE_B && BBUS_ST == BBUS_DMA_END && DMA_READ_A && ABUS_ST == ABUS_DMA_END) || 
					    (!DMA_DSP && DMA_WRITE_B && BBUS_ST == BBUS_DMA_END && DMA_READ_C && CBUS_ST == CBUS_RELEASE) || 
					    (!DMA_DSP && DMA_WRITE_C && CBUS_ST == CBUS_RELEASE && DMA_READ_A && ABUS_ST == ABUS_DMA_END) || 
					    (!DMA_DSP && DMA_WRITE_C && CBUS_ST == CBUS_RELEASE && DMA_READ_B && BBUS_ST == BBUS_DMA_END) || 
						 (!DMA_DSP && DMA_ERR) ||
						 ( DMA_DSP && DMA_READ_A && ABUS_ST == ABUS_DMA_END) ||
						 ( DMA_DSP && DMA_READ_B && BBUS_ST == BBUS_DMA_END) ||
						 ( DMA_DSP && DMA_WRITE_B && BBUS_ST == BBUS_DMA_END) ||
						 ( DMA_DSP && DMA_READ_C && CBUS_ST == CBUS_RELEASE) ||
						 ( DMA_DSP && DMA_WRITE_C && CBUS_ST == CBUS_RELEASE)) begin
						DMA_READ_A <= 0;
						DMA_READ_B <= 0;
						DMA_READ_C <= 0;
						DMA_WRITE_A <= 0;
						DMA_WRITE_B <= 0;
						DMA_WRITE_C <= 0;
//						DMA_READ_DSP <= 0;
//						DMA_WRITE_DSP <= 0;
						DSTA.DACSA <= 0;
						DSTA.DACSB <= 0;
						DSTA.DACSD <= 0;
						DMA_END = 1;
						if (DMA_DSP) begin
							DMA_DSP <= 0;
							DSP_DMA_END <= 0;
							DMA_ST <= DMA_IDLE;
						end else if (!DMD[DMA_CH].MOD || DMA_EC || DMA_ERR) begin
							DMA_RUN[DMA_CH] <= 0;
							if (!DMA_ERR) DMA_INT_PEND[DMA_CH] <= 1;
							else DMAIL_PEND <= 1;
							DMA_ST <= DMA_IDLE;
						end else begin
							DMA_IND <= 1;
							DMA_ST <= DMA_IND_START;
						end 
`ifdef DEBUG
						DMA_BUF_SIZE_ERR <= |DMA_BUF_SIZE;
						DMA_BUF_POS_ERR <= DMA_BUF_RPOS != DMA_BUF_WPOS;
`endif
					end
				end
			endcase
			
			if (CE_F) begin
				RD_DATA = ABUS_READ_DONE ? ABUS_BUF : BBUS_READ_DONE ? BBUS_BUF : CCACHE_Q;
				if ((ABUS_READ_DONE || BBUS_READ_DONE || (CBUS_READ_DONE && !DMA_IND)) && DMA_BUF_SIZE < 3'd4 && !DMA_DSP) begin
					case (DMA_RBA[1:0])
						2'b00: {DMA_BUF[DMA_BUF_WPOS+3'd0],DMA_BUF[DMA_BUF_WPOS+3'd1],DMA_BUF[DMA_BUF_WPOS+3'd2],DMA_BUF[DMA_BUF_WPOS+3'd3]} <= RD_DATA[31:0];
						2'b01: {DMA_BUF[DMA_BUF_WPOS+3'd0],DMA_BUF[DMA_BUF_WPOS+3'd1],DMA_BUF[DMA_BUF_WPOS+3'd2]}                            <= RD_DATA[23:0];
						2'b10: {DMA_BUF[DMA_BUF_WPOS+3'd0],DMA_BUF[DMA_BUF_WPOS+3'd1]}                                                       <= RD_DATA[15:0];
						2'b11: {DMA_BUF[DMA_BUF_WPOS+3'd0]}                                                                                  <= RD_DATA[ 7:0];
					endcase
					case (DMA_RBA[1:0])
						2'b00: begin DMA_BUF_WPOS <= DMA_BUF_WPOS + 3'd4; DMA_BUF_SIZE <= DMA_BUF_SIZE + 3'd4; end
						2'b01: begin DMA_BUF_WPOS <= DMA_BUF_WPOS + 3'd3; DMA_BUF_SIZE <= DMA_BUF_SIZE + 3'd3; end
						2'b10: begin DMA_BUF_WPOS <= DMA_BUF_WPOS + 3'd2; DMA_BUF_SIZE <= DMA_BUF_SIZE + 3'd2; end
						2'b11: begin DMA_BUF_WPOS <= DMA_BUF_WPOS + 3'd1; DMA_BUF_SIZE <= DMA_BUF_SIZE + 3'd1; end
					endcase
					DMA_RBA <= '0;
				end
				if ((ABUS_READ_DONE || BBUS_READ_DONE || CBUS_READ_DONE) && DMA_DSP) begin
					{DMA_BUF[0],DMA_BUF[1],DMA_BUF[2],DMA_BUF[3]} <= RD_DATA;
					
					DSP_DMA_ACK <= 1;
					if (DSP_DMA_LAST) begin
						DSP_DMA_END <= 1;
					end
				end
			end
			
			if (CE_R) begin
				if (DMA_DSP) 
					DMA_RA_NEW = DMA_RA + (DMA_READ_B ? 27'd4 : DMA_WADD[1] ? 27'd4 : 27'd0);
				else 
					DMA_RA_NEW = DMA_RA + DMA_RTN_DEC;
					
				if (DMA_WRITE_A)
					DMA_WA_NEW = DMA_WA + (/*DMA_WTN_DEC < 3'd2 ?*/ DMA_WTN_DEC /*: (27'd1 << DMA_WADD)*/);
				else if (DMA_WRITE_B)
					DMA_WA_NEW = DMA_WA + (DMA_WTN_DEC < 3'd2 ? DMA_WTN_DEC : (27'd1 << DMA_WADD));
				else if (DMA_WRITE_C)
					DMA_WA_NEW = DMA_WA + (DMA_WTN_DEC < 3'd4 ? DMA_WTN_DEC : (27'd1 << DMA_WADD));
				else
					DMA_WA_NEW = DMA_WA;
					
				DMA_IA_NEW = DMA_IA + 27'd4;
				
				if (ABUS_READ_ACK || BBUS_READ_ACK || CBUS_READ_ACK) begin
					if (!DMA_DSP) begin
						if (DMA_RADD) DMA_RA <= DMA_RA_NEW;
						DMA_RTN <= DMA_RTN_NEXT;
						if (DMD[DMA_CH].RUP && !DMD[DMA_CH].MOD) DR[DMA_CH] <= {5'b0000_0,DMA_RA_NEW};
					end else begin
						if (DMA_WADD) DMA_RA <= DMA_RA_NEW;
						if (DMA_WADD[1] && !DSP_HOLD) DSP_DR <= DMA_RA_NEW;
					end 
				end
				
				if (ABUS_DATA_ACK || BBUS_DATA_ACK || CBUS_DATA_ACK) begin
					if (!DMA_DSP) begin
						if (DMA_WADD) DMA_WA <= DMA_WA_NEW;
						if (DMA_WADD && DMD[DMA_CH].WUP && !DMD[DMA_CH].MOD) DW[DMA_CH] <= {5'b0000_0,DMA_WA_NEW};
					end else begin
						if (DMA_WADD) DMA_WA <= DMA_WA_NEW;
						if (DMA_WADD && !DSP_HOLD) DSP_DW <= DSP_DMA_END ? DSP_DW : DMA_WA_NEW;
					end 
				end
				
				if (BBUS_IND_DONE || CBUS_IND_DONE) begin
					DMA_IA <= DMA_IA_NEW;
					if (DMD[DMA_CH].WUP && DMD[DMA_CH].MOD) DW[DMA_CH] <= {5'b0000_0,DMA_IA_NEW};
				end
				
				if (DMA_END && DMA_DSP) begin
					if (!DSP_DMA_WE && !DMA_WADD[1] && !DSP_HOLD) DSP_DR <= DSP_DR + 27'd4;
					if ( DSP_DMA_WE                 && !DSP_HOLD) DSP_DW <= DSP_DW + 27'd4;
				end
			end
			
			AFC <= '1;
			ATIM0_N <= 1;
			ATIM1_N <= 1;
			ATIM2_N <= 1;
			
			if (CE_R) begin
				DEN[0].GO <= 0;
				DEN[1].GO <= 0;
				DEN[2].GO <= 0;
				if (REG_WWAIT) begin
					case ({REG_A,2'b00})
						8'h00: begin
							if (!CDQM_N[3]) DR[0][31:24] <= REG_WDI[31:24] & DxR_WMASK[31:24];
							if (!CDQM_N[2]) DR[0][23:16] <= REG_WDI[23:16] & DxR_WMASK[23:16];
							if (!CDQM_N[1]) DR[0][15: 8] <= REG_WDI[15: 8] & DxR_WMASK[15: 8];
							if (!CDQM_N[0]) DR[0][ 7: 0] <= REG_WDI[ 7: 0] & DxR_WMASK[ 7: 0];
`ifdef DEBUG
							DR_ERR <= REG_WDI[26:24] <= 3'h1 || REG_WDI[26:24] >= 3'h7;
`endif
						end
						8'h04: begin
							if (!CDQM_N[3]) DW[0][31:24] <= REG_WDI[31:24] & DxW_WMASK[31:24];
							if (!CDQM_N[2]) DW[0][23:16] <= REG_WDI[23:16] & DxW_WMASK[23:16];
							if (!CDQM_N[1]) DW[0][15: 8] <= REG_WDI[15: 8] & DxW_WMASK[15: 8];
							if (!CDQM_N[0]) DW[0][ 7: 0] <= REG_WDI[ 7: 0] & DxW_WMASK[ 7: 0];
`ifdef DEBUG
							DW_ERR <= REG_WDI[26:24] <= 3'h1 || REG_WDI[26:24] >= 3'h7;
`endif
						end
						8'h08: begin
							if (!CDQM_N[3]) DC[0][31:24] <= REG_WDI[31:24] & D0C_WMASK[31:24];
							if (!CDQM_N[2]) DC[0][23:16] <= REG_WDI[23:16] & D0C_WMASK[23:16];
							if (!CDQM_N[1]) DC[0][15: 8] <= REG_WDI[15: 8] & D0C_WMASK[15: 8];
							if (!CDQM_N[0]) DC[0][ 7: 0] <= REG_WDI[ 7: 0] & D0C_WMASK[ 7: 0];
						end
						8'h0C: if (!DMA_RUN[0]) begin
							if (!CDQM_N[3]) DAD[0][31:24] <= REG_WDI[31:24] & DxAD_WMASK[31:24];
							if (!CDQM_N[2]) DAD[0][23:16] <= REG_WDI[23:16] & DxAD_WMASK[23:16];
							if (!CDQM_N[1]) DAD[0][15: 8] <= REG_WDI[15: 8] & DxAD_WMASK[15: 8];
							if (!CDQM_N[0]) DAD[0][ 7: 0] <= REG_WDI[ 7: 0] & DxAD_WMASK[ 7: 0];
						end
						8'h10: begin
							if (!CDQM_N[3]) DEN[0][31:24] <= REG_WDI[31:24] & DxEN_WMASK[31:24];
							if (!CDQM_N[2]) DEN[0][23:16] <= REG_WDI[23:16] & DxEN_WMASK[23:16];
							if (!CDQM_N[1]) DEN[0][15: 8] <= REG_WDI[15: 8] & DxEN_WMASK[15: 8];
							if (!CDQM_N[0]) DEN[0][ 7: 0] <= REG_WDI[ 7: 0] & DxEN_WMASK[ 7: 0];
						end
						8'h14: if (!DMA_RUN[0]) begin
							if (!CDQM_N[3]) DMD[0][31:24] <= REG_WDI[31:24] & DxMD_WMASK[31:24];
							if (!CDQM_N[2]) DMD[0][23:16] <= REG_WDI[23:16] & DxMD_WMASK[23:16];
							if (!CDQM_N[1]) DMD[0][15: 8] <= REG_WDI[15: 8] & DxMD_WMASK[15: 8];
							if (!CDQM_N[0]) DMD[0][ 7: 0] <= REG_WDI[ 7: 0] & DxMD_WMASK[ 7: 0];
						end
						8'h20: begin
							if (!CDQM_N[3]) DR[1][31:24] <= REG_WDI[31:24] & DxR_WMASK[31:24];
							if (!CDQM_N[2]) DR[1][23:16] <= REG_WDI[23:16] & DxR_WMASK[23:16];
							if (!CDQM_N[1]) DR[1][15: 8] <= REG_WDI[15: 8] & DxR_WMASK[15: 8];
							if (!CDQM_N[0]) DR[1][ 7: 0] <= REG_WDI[ 7: 0] & DxR_WMASK[ 7: 0];
`ifdef DEBUG
							DR_ERR <= REG_WDI[26:24] <= 3'h1 || REG_WDI[26:24] >= 3'h7;
`endif
						end
						8'h24: begin
							if (!CDQM_N[3]) DW[1][31:24] <= REG_WDI[31:24] & DxW_WMASK[31:24];
							if (!CDQM_N[2]) DW[1][23:16] <= REG_WDI[23:16] & DxW_WMASK[23:16];
							if (!CDQM_N[1]) DW[1][15: 8] <= REG_WDI[15: 8] & DxW_WMASK[15: 8];
							if (!CDQM_N[0]) DW[1][ 7: 0] <= REG_WDI[ 7: 0] & DxW_WMASK[ 7: 0];
`ifdef DEBUG
							DW_ERR <= REG_WDI[26:24] <= 3'h1 || REG_WDI[26:24] >= 3'h7;
`endif
						end
						8'h28: begin
							if (!CDQM_N[3]) DC[1][31:24] <= REG_WDI[31:24] & D0C_WMASK[31:24];
							if (!CDQM_N[2]) DC[1][23:16] <= REG_WDI[23:16] & D0C_WMASK[23:16];
							if (!CDQM_N[1]) DC[1][15: 8] <= REG_WDI[15: 8] & D0C_WMASK[15: 8];
							if (!CDQM_N[0]) DC[1][ 7: 0] <= REG_WDI[ 7: 0] & D0C_WMASK[ 7: 0];
						end
						8'h2C: if (!DMA_RUN[1]) begin
							if (!CDQM_N[3]) DAD[1][31:24] <= REG_WDI[31:24] & DxAD_WMASK[31:24];
							if (!CDQM_N[2]) DAD[1][23:16] <= REG_WDI[23:16] & DxAD_WMASK[23:16];
							if (!CDQM_N[1]) DAD[1][15: 8] <= REG_WDI[15: 8] & DxAD_WMASK[15: 8];
							if (!CDQM_N[0]) DAD[1][ 7: 0] <= REG_WDI[ 7: 0] & DxAD_WMASK[ 7: 0];
						end
						8'h30: begin
							if (!CDQM_N[3]) DEN[1][31:24] <= REG_WDI[31:24] & DxEN_WMASK[31:24];
							if (!CDQM_N[2]) DEN[1][23:16] <= REG_WDI[23:16] & DxEN_WMASK[23:16];
							if (!CDQM_N[1]) DEN[1][15: 8] <= REG_WDI[15: 8] & DxEN_WMASK[15: 8];
							if (!CDQM_N[0]) DEN[1][ 7: 0] <= REG_WDI[ 7: 0] & DxEN_WMASK[ 7: 0];
						end
						8'h34: if (!DMA_RUN[1]) begin
							if (!CDQM_N[3]) DMD[1][31:24] <= REG_WDI[31:24] & DxMD_WMASK[31:24];
							if (!CDQM_N[2]) DMD[1][23:16] <= REG_WDI[23:16] & DxMD_WMASK[23:16];
							if (!CDQM_N[1]) DMD[1][15: 8] <= REG_WDI[15: 8] & DxMD_WMASK[15: 8];
							if (!CDQM_N[0]) DMD[1][ 7: 0] <= REG_WDI[ 7: 0] & DxMD_WMASK[ 7: 0];
						end
						8'h40: begin
							if (!CDQM_N[3]) DR[2][31:24] <= REG_WDI[31:24] & DxR_WMASK[31:24];
							if (!CDQM_N[2]) DR[2][23:16] <= REG_WDI[23:16] & DxR_WMASK[23:16];
							if (!CDQM_N[1]) DR[2][15: 8] <= REG_WDI[15: 8] & DxR_WMASK[15: 8];
							if (!CDQM_N[0]) DR[2][ 7: 0] <= REG_WDI[ 7: 0] & DxR_WMASK[ 7: 0];
`ifdef DEBUG
							DR_ERR <= REG_WDI[26:24] <= 3'h1 || REG_WDI[26:24] >= 3'h7;
`endif
						end
						8'h44: begin
							if (!CDQM_N[3]) DW[2][31:24] <= REG_WDI[31:24] & DxW_WMASK[31:24];
							if (!CDQM_N[2]) DW[2][23:16] <= REG_WDI[23:16] & DxW_WMASK[23:16];
							if (!CDQM_N[1]) DW[2][15: 8] <= REG_WDI[15: 8] & DxW_WMASK[15: 8];
							if (!CDQM_N[0]) DW[2][ 7: 0] <= REG_WDI[ 7: 0] & DxW_WMASK[ 7: 0];
`ifdef DEBUG
							DW_ERR <= REG_WDI[26:24] <= 3'h1 || REG_WDI[26:24] >= 3'h7;
`endif
						end
						8'h48: begin
							if (!CDQM_N[3]) DC[2][31:24] <= REG_WDI[31:24] & D0C_WMASK[31:24];
							if (!CDQM_N[2]) DC[2][23:16] <= REG_WDI[23:16] & D0C_WMASK[23:16];
							if (!CDQM_N[1]) DC[2][15: 8] <= REG_WDI[15: 8] & D0C_WMASK[15: 8];
							if (!CDQM_N[0]) DC[2][ 7: 0] <= REG_WDI[ 7: 0] & D0C_WMASK[ 7: 0];
						end
						8'h4C: if (!DMA_RUN[2]) begin
							if (!CDQM_N[3]) DAD[2][31:24] <= REG_WDI[31:24] & DxAD_WMASK[31:24];
							if (!CDQM_N[2]) DAD[2][23:16] <= REG_WDI[23:16] & DxAD_WMASK[23:16];
							if (!CDQM_N[1]) DAD[2][15: 8] <= REG_WDI[15: 8] & DxAD_WMASK[15: 8];
							if (!CDQM_N[0]) DAD[2][ 7: 0] <= REG_WDI[ 7: 0] & DxAD_WMASK[ 7: 0];
						end
						8'h50: begin
							if (!CDQM_N[3]) DEN[2][31:24] <= REG_WDI[31:24] & DxEN_WMASK[31:24];
							if (!CDQM_N[2]) DEN[2][23:16] <= REG_WDI[23:16] & DxEN_WMASK[23:16];
							if (!CDQM_N[1]) DEN[2][15: 8] <= REG_WDI[15: 8] & DxEN_WMASK[15: 8];
							if (!CDQM_N[0]) DEN[2][ 7: 0] <= REG_WDI[ 7: 0] & DxEN_WMASK[ 7: 0];
						end
						8'h54: if (!DMA_RUN[2]) begin
							if (!CDQM_N[3]) DMD[2][31:24] <= REG_WDI[31:24] & DxMD_WMASK[31:24];
							if (!CDQM_N[2]) DMD[2][23:16] <= REG_WDI[23:16] & DxMD_WMASK[23:16];
							if (!CDQM_N[1]) DMD[2][15: 8] <= REG_WDI[15: 8] & DxMD_WMASK[15: 8];
							if (!CDQM_N[0]) DMD[2][ 7: 0] <= REG_WDI[ 7: 0] & DxMD_WMASK[ 7: 0];
						end
					
						8'h60: begin
//							DSTP <= REG_WDI & DSTP_WMASK;
							if (REG_WDI[0]) begin
								DMA_RUN[0] <= 0;
								DMA_RUN[1] <= 0;
								DMA_RUN[2] <= 0;
								DMA_ST <= DMA_IDLE;
							end
						end
						
						default:;
					endcase
				end
			
				if (DSP_RA0_SET) begin
					DSP_DR <= {DSP_DSO[24:0],2'b00};
				end
				if (DSP_WA0_SET) begin
					DSP_DW <= {DSP_DSO[24:0],2'b00};
				end
				if (DSP_DMA_SET) begin
					DSP_ADD <= DSP_DSO[17:15];
					DSP_HOLD <= DSP_DSO[14];
				end
			end
		end
	end
`ifdef DEBUG
	assign DBG_DMA_RADDR_ERR = |DMA_RA[7:0];
	assign DBG_DMA_WADDR_ERR = |DMA_WA[7:0];
`endif

	assign CBUS_REQ = (CBUS_ST == CBUS_REQUEST);
	assign CBUS_REL = (CBUS_ST == CBUS_RELEASE) && !DMA_READ_C && !DMA_WRITE_C;
						
	bit CBRLS;
	bit CBREQ;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			CBREQ <= 0;
			CBRLS <= 1;
		end else begin
			if (!RES_N) begin
				CBREQ <= 0;
				CBRLS <= 1;
			end else if (CE_F) begin
				if (CBUS_REQ && !CBREQ && CBRLS) begin
					CBREQ <= 1;
				end
				else if (CBREQ && !CBACK_N && CBRLS) begin
					CBRLS <= 0;
				end
				else if (CBUS_REL && CBREQ && !CBRLS) begin
					CBREQ <= 0;
				end
				else if (!CBREQ && !CBRLS) begin
					CBRLS <= 1;
				end
			end
		end
	end
	assign CBREQ_N = ~CBREQ;
	
				
	assign ECA = CBUS_A[24:0];
	assign ECDO = CBUS_D;
	assign ECDQM_N = ~CBUS_WR;
	assign ECRD_WR_N = ~|CBUS_WR;
	assign ECRD_N = ~CBUS_RD;
	assign ECBURST = CBUS_BURST;
	assign ECCS3_N = ~CBUS_CS;
	assign ECRFS = |CBUS_RFS & CBUS_RFS[0];
	
	//DSP
	bit DSP_CE;
	always @(posedge CLK) if (CE_R) DSP_CE <= ~DSP_CE;
	
	wire DSP_SEL = REG_SEL && CA[7:0] >= 8'h80 && CA[7:0] <= 8'h8F;	//25FE0080-25FE008F
	
	bit [31:0] DSP_DSO;
	bit        DSP_RA0_SET;
	bit        DSP_WA0_SET;
	bit        DSP_DMA_SET;
	bit [31:0] DSP_DO;
	SCU_DSP dsp(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE(DSP_CE & CE_R),
		
		.RES_N(RES_N),
		
		.CE_R(CE_R),
		.CE_F(CE_F),
		.A(REG_A[3:2]),
		.DI(REG_WDI),
		.DO(DSP_DO),
		.WE(DSP_SEL & REG_WWAIT & CE_R),
		.RE(DSP_SEL & REG_RWAIT & REG_WAIT_DELAY == 3'd2 & CE_F),
		
		.DSO(DSP_DSO),
		.RA0W(DSP_RA0_SET),
		.WA0W(DSP_WA0_SET),
		.DMAW(DSP_DMA_SET),
		
		.DMA_DI(DSP_DMA_DI),
		.DMA_DO(DSP_DMA_DO),
		.DMA_WE(DSP_DMA_WE),
		.DMA_REQ(DSP_DMA_REQ),
		.DMA_ACK(DSP_DMA_ACK),
		.DMA_RUN(DSP_DMA_RUN),
		.DMA_LAST(DSP_DMA_LAST),
		.DMA_END(DSP_DMA_END),
		
		.IRQ(DSP_IRQ)
	);
	assign DSP_DMA_DI = {DMA_BUF[0],DMA_BUF[1],DMA_BUF[2],DMA_BUF[3]};

	
	//Timers
	bit  [ 9: 0] TM0;
	bit  [11: 0] TM1;
	always @(posedge CLK or negedge RST_N) begin
		bit          TM0_MATCH,TM1_ZERO,TM1_MATCH;
		bit  [ 1: 0] TM0_MATCH_OLD,TM1_MATCH_OLD;
		bit          T1MD_ENB_OLD;
		bit          TM1_SYNC_EN;
		
		if (!RST_N) begin
			TM0 <= '0;
			TM1 <= '0;
			TM0_PEND <= 0;
			TM1_PEND <= 0;
		end
		else if (!RES_N) begin
			TM0 <= '0;
			TM1 <= '0;
			TM1_SYNC_EN <= 0;
			TM0_MATCH_OLD <= '1;
			TM0_PEND <= 0;
			TM1_PEND <= 0;
		end else if (CE_R) begin
			TM0_PEND <= 0;
			TM1_PEND <= 0;
			
			TM0_MATCH = (TM0 == T0C[9:0]);
			TM1_MATCH = (TM1 == 12'h002);
			TM1_ZERO = !TM1;
			
			if (!TM1_ZERO) TM1 <= TM1 - 11'd1;
			if (HBL_IN) begin
				if (T1MD.ENB && TM1_ZERO) begin
					TM1 <= {~|T1S[8:0],T1S[8:0],2'b00};
				end
			end
			
			if (VBL_OUT) begin
				TM0 <= '0;
			end
			if (HBL_IN) begin
				if (T1MD.ENB) TM0 <= TM0 + 10'd1;
				TM1_SYNC_EN <= 0;
			end
			
			TM0_MATCH_OLD <= {TM0_MATCH_OLD[0],TM0_MATCH};
			if (TM0_MATCH_OLD[0] && !TM0_MATCH_OLD[1]) begin
				if (T1MD.ENB) TM0_PEND <= 1;
				if (T1MD.ENB) TM1_SYNC_EN <= 1;
			end
			
			T1MD_ENB_OLD <= T1MD.ENB;
			if (T1MD.ENB && !T1MD_ENB_OLD) begin
				TM0 <= '0;
				TM0_MATCH_OLD <= '0;
			end
			
			TM1_MATCH_OLD <= {TM1_MATCH_OLD[0],TM1_MATCH};
			if (TM1_MATCH_OLD[0] && !TM1_MATCH_OLD[1]) begin
				if (!T1MD.MD || (T1MD.MD && TM1_SYNC_EN)) begin
					TM1_PEND <= 1;
				end
			end
		end
	end
				
	//Interrupts
	always @(posedge CLK or negedge RST_N) begin
		bit DSP_IRQ_OLD;
		bit MIREQ_N_OLD;
		if (!RST_N) begin
			VBIN_PEND <= 0;
			VBOUT_PEND <= 0;
			HBIN_PEND <= 0;
			DSP_PEND <= 0;
			SCSP_PEND <= 0;
			DSP_IRQ_OLD <= 0;
		end else if (!RES_N) begin
			VBIN_PEND <= 0;
			VBOUT_PEND <= 0;
			HBIN_PEND <= 0;
			DSP_PEND <= 0;
			SCSP_PEND <= 0;
			PAD_PEND <= 0;
		end else if (CE_R) begin
			VBIN_PEND <= 0;	
			if (VBL_IN && !VBIN_PEND) VBIN_PEND <= 1;
			
			VBOUT_PEND <= 0;	
			if (VBL_OUT && !VBOUT_PEND) VBOUT_PEND <= 1;
			
			HBIN_PEND <= 0;
			if (HBL_IN && !HBIN_PEND) HBIN_PEND <= 1;
			
			SCSP_PEND <= 0;
			if (SCSP_REQ && !SCSP_PEND) SCSP_PEND <= 1;
			
			VDP1_PEND <= 0;
			if (VDP1_REQ && !VDP1_PEND) VDP1_PEND <= 1;
			
			DSP_PEND <= 0;
			DSP_IRQ_OLD <= DSP_IRQ;
			if (DSP_IRQ && !DSP_IRQ_OLD && !DSP_PEND) DSP_PEND <= 1;
			
			SM_PEND <= 0;
			MIREQ_N_OLD <= MIREQ_N;
			if (!MIREQ_N && MIREQ_N_OLD && !SM_PEND) SM_PEND <= 1;
			
			PAD_PEND <= 0;
			if (PAD_REQ && !PAD_PEND) PAD_PEND <= 1;
		end
	end
	
	bit        VBIN_INT;
	bit        VBOUT_INT;
	bit        HBIN_INT;
	bit        TM0_INT;
	bit        TM1_INT;
	bit        DSP_INT;
	bit        SCSP_INT;
	bit        SM_INT;
	bit        PAD_INT;
	bit  [2:0] DMA_INT;
	bit        DMAIL_INT;
	bit        VDP1_INT;
	bit [15:0] EXT_INT;
	bit        INT_SET; 
	always @(posedge CLK or negedge RST_N) begin
		bit        TM1_SYNC_ALLOW;
		bit [15:0] IMS_OB;
		
		if (!RST_N) begin
			IMS <= IMS_INIT;
			IST <= IST_INIT;
			IMS_OB <= IMS_INIT[15:0];
			
			VBIN_INT <= 0;
			VBOUT_INT <= 0;
			HBIN_INT <= 0;
			DSP_INT <= 0;
			SCSP_INT <= 0;
			EXT_INT <= '0;
			PAD_INT <= 0;
			DMAIL_INT <= 0;
			INT_SET <= 0;
			TM1_SYNC_ALLOW <= 0;
		end else if (!RES_N) begin
			IMS <= IMS_INIT;
			IST <= IST_INIT;
			IMS_OB <= IMS_INIT[15:0];
			
			VBIN_INT <= 0;
			VBOUT_INT <= 0;
			HBIN_INT <= 0;
			DSP_INT <= 0;
			SCSP_INT <= 0;
			EXT_INT <= '0;
			PAD_INT <= 0;
			DMAIL_INT <= 0;
			INT_SET <= 0;
			TM1_SYNC_ALLOW <= 0;
		end else if (CE_R) begin
			if (VBIN_PEND      ) IST.VBII <= 1;
			if (VBOUT_PEND     ) IST.VBOI <= 1;
			if (HBIN_PEND      ) IST.HBII <= 1;
			if (TM0_PEND       ) IST.T0I <= 1;
			if (TM1_PEND       ) IST.T1I <= 1;
			if (DSP_PEND       ) IST.DSPEI <= 1;
			if (SCSP_PEND      ) IST.SRI <= 1;
			if (SM_PEND        ) IST.SMI <= 1;
			if (PAD_PEND       ) IST.PADI <= 1;
			if (DMA_INT_PEND[2]) IST.D2EI <= 1;
			if (DMA_INT_PEND[1]) IST.D1EI <= 1;
			if (DMA_INT_PEND[0]) IST.D0EI <= 1;
			if (DMAIL_PEND     ) IST.DII <= 1;
			if (VDP1_PEND      ) IST.SDEI <= 1;
			
			if ((IMS.MS3 && !TM1_SYNC_ALLOW) || !T1MD.MD) begin
				TM1_SYNC_ALLOW <= 1;
			end
			
			if (REG_WWAIT1 && REG_A == 8'hA0>>2) begin	//IMS
				IMS[15:0] <= {REG_WREN[1] ? REG_WDI[15:8] : IMS_OB[15:8], REG_WREN[0] ? REG_WDI[7:0] : IMS_OB[7:0]};
				if (REG_WREN[1]) IMS_OB[15: 8] <= REG_WDI[15: 8];
				if (REG_WREN[0]) IMS_OB[ 7: 0] <= REG_WDI[ 7: 0];
			end
			if (REG_WWAIT2 && REG_A == 8'hA4>>2) begin	//IST
				if (REG_WREN[0] && !REG_WDI[0]  && IST.VBII ) IST.VBII <= 0;
				if (REG_WREN[0] && !REG_WDI[1]  && IST.VBOI ) IST.VBOI <= 0;
				if (REG_WREN[0] && !REG_WDI[2]  && IST.HBII ) IST.HBII <= 0;
				if (REG_WREN[0] && !REG_WDI[3]  && IST.T0I  ) IST.T0I <= 0;
				if (REG_WREN[0] && !REG_WDI[4]  && IST.T1I  ) IST.T1I <= 0;
				if (REG_WREN[0] && !REG_WDI[5]  && IST.DSPEI) IST.DSPEI <= 0;
				if (REG_WREN[0] && !REG_WDI[6]  && IST.SRI  ) IST.SRI <= 0;
				if (REG_WREN[0] && !REG_WDI[7]  && IST.SMI  ) IST.SMI <= 0;
				if (REG_WREN[1] && !REG_WDI[8]  && IST.PADI ) IST.PADI <= 0;
				if (REG_WREN[1] && !REG_WDI[9]  && IST.D2EI ) IST.D2EI <= 0;
				if (REG_WREN[1] && !REG_WDI[10] && IST.D1EI ) IST.D1EI <= 0;
				if (REG_WREN[1] && !REG_WDI[11] && IST.D0EI ) IST.D0EI <= 0;
				if (REG_WREN[1] && !REG_WDI[12] && IST.DII  ) IST.DII <= 0;
				if (REG_WREN[1] && !REG_WDI[13] && IST.SDEI ) IST.SDEI <= 0;
			end 
			
			if      (IST.VBII  && !IMS.MS0  && !INT_SET) begin VBIN_INT <= 1;   IST.VBII <= 0;  INT_SET <= 1; end
			else if (IST.VBOI  && !IMS.MS1  && !INT_SET) begin VBOUT_INT <= 1;  IST.VBOI <= 0;  INT_SET <= 1; end
			else if (IST.HBII  && !IMS.MS2  && !INT_SET) begin HBIN_INT <= 1;   IST.HBII <= 0;  INT_SET <= 1; end
			else if (IST.T0I   && !IMS.MS3  && !INT_SET) begin TM0_INT <= 1;    IST.T0I <= 0;   INT_SET <= 1; TM1_SYNC_ALLOW <= 0; end
			else if (IST.T1I   && !IMS.MS4  && !INT_SET &&
		                                TM1_SYNC_ALLOW) begin TM1_INT <= 1;    IST.T1I <= 0;   INT_SET <= 1; end
			else if (IST.DSPEI && !IMS.MS5  && !INT_SET) begin DSP_INT <= 1;    IST.DSPEI <= 0; INT_SET <= 1; end
			else if (IST.SRI   && !IMS.MS6  && !INT_SET) begin SCSP_INT <= 1;   IST.SRI <= 0;   INT_SET <= 1; end
			else if (IST.SMI   && !IMS.MS7  && !INT_SET) begin SM_INT <= 1;     IST.SMI <= 0;   INT_SET <= 1; end
			else if (IST.PADI  && !IMS.MS8  && !INT_SET) begin PAD_INT <= 1;    IST.PADI <= 0;  INT_SET <= 1; end
			else if (IST.D2EI  && !IMS.MS9  && !INT_SET) begin DMA_INT[2] <= 1; IST.D2EI <= 0;  INT_SET <= 1; end
			else if (IST.D1EI  && !IMS.MS10 && !INT_SET) begin DMA_INT[1] <= 1; IST.D1EI <= 0;  INT_SET <= 1; end
			else if (IST.D0EI  && !IMS.MS11 && !INT_SET) begin DMA_INT[0] <= 1; IST.D0EI <= 0;  INT_SET <= 1; end
			else if (IST.DII   && !IMS.MS12 && !INT_SET) begin DMAIL_INT <= 1;  IST.DII <= 0;   INT_SET <= 1; end
			else if (IST.SDEI  && !IMS.MS13 && !INT_SET) begin VDP1_INT <= 1;   IST.SDEI <= 0;  INT_SET <= 1; end

			EXT_INT <= '0;
			
			if (IVECF_RISE) begin
				case (IVECF_LVL)
					4'hF: if (VBIN_INT) VBIN_INT <= 0;
					4'hE: if (VBOUT_INT) VBOUT_INT <= 0;
					4'hD: if (HBIN_INT) HBIN_INT <= 0;
					4'hC: if (TM0_INT) TM0_INT <= 0;
					4'hB: if (TM1_INT) TM1_INT <= 0;
					4'hA: if (DSP_INT) DSP_INT <= 0;
					4'h9: if (SCSP_INT) SCSP_INT <= 0;
					4'h8: begin 
						if (SM_INT) SM_INT <= 0;
						if (PAD_INT) PAD_INT <= 0;
					end
					4'h6: begin 
						if (DMA_INT[2]) DMA_INT[2] <= 0;
						if (DMA_INT[1]) DMA_INT[1] <= 0;
					end
					4'h5: if (DMA_INT[0]) DMA_INT[0] <= 0;
					4'h3: if (DMAIL_INT) DMAIL_INT <= 0;
					4'h2: if (VDP1_INT) VDP1_INT <= 0;
					default:;
				endcase
				INT_SET <= 0;
				IMS <= IMS_INIT;
			end
		end
	end
`ifdef DEBUG
	assign DBG_IST = IST[15:0];
	assign DBG_IMS = IMS[15:0];
`endif
		
	always @(posedge CLK) begin
		bit [3:0] INT_LVL;
	
		if (CE_R) begin
			if      (VBIN_INT      ) INT_LVL = 4'hF;	//F
			else if (VBOUT_INT     ) INT_LVL = 4'hE;	//E
			else if (HBIN_INT      ) INT_LVL = 4'hD;	//D
			else if (TM0_INT       ) INT_LVL = 4'hC;	//C
			else if (TM1_INT       ) INT_LVL = 4'hB;	//B
			else if (DSP_INT       ) INT_LVL = 4'hA;	//A
			else if (SCSP_INT      ) INT_LVL = 4'h9;	//9
			else if (SM_INT        ) INT_LVL = 4'h8;	//8
			else if (PAD_INT       ) INT_LVL = 4'h8;	//8
	//		else if ((EXT_INT[0] ||
	//					 EXT_INT[1] ||
	//					 EXT_INT[2] ||
	//					 EXT_INT[3])  ) INT_LVL = 4'h7;	//7
			else if (DMA_INT[2]    ) INT_LVL = 4'h6;	//6
			else if (DMA_INT[1]    ) INT_LVL = 4'h6;	//6
			else if (DMA_INT[0]    ) INT_LVL = 4'h5;	//5
	//		else if ((EXT_INT[4] ||
	//					 EXT_INT[5] ||
	//					 EXT_INT[6] ||
	//					 EXT_INT[7])  ) INT_LVL = 4'h4;	//4
			else if (DMAIL_INT     ) INT_LVL = 4'h3;	//3
			else if (VDP1_INT      ) INT_LVL = 4'h2;	//2
	//		else if ((EXT_INT[8]  ||
	//					 EXT_INT[9]  ||
	//					 EXT_INT[10] ||
	//					 EXT_INT[11] ||
	//					 EXT_INT[12] ||
	//					 EXT_INT[13] ||
	//					 EXT_INT[14] ||
	//					 EXT_INT[15]) ) INT_LVL = 4'h1;	//1
			else                     INT_LVL = 4'h0;	//0
			
			CIRL_N <= ~INT_LVL;
		end
	end

	
	bit [7:0] IVEC;
	always_comb begin
		case (CA[3:0])
			4'hF: IVEC = 8'h40;
			4'hE: IVEC = 8'h41;
			4'hD: IVEC = 8'h42;
			4'hC: IVEC = 8'h43;
			4'hB: IVEC = 8'h44;
			4'hA: IVEC = 8'h45;
			4'h9: IVEC = 8'h46;
			4'h8: IVEC = PAD_INT     ? 8'h48 : 8'h47;
			4'h7: IVEC = EXT_INT[0]  ? 8'h50 : 
			             EXT_INT[1]  ? 8'h51 : 
							 EXT_INT[2]  ? 8'h52 : 8'h53;
			4'h6: IVEC = DMA_INT[1]  ? 8'h4A : 8'h49;
			4'h5: IVEC = 8'h4B;
			4'h4: IVEC = EXT_INT[4]  ? 8'h54 : 
			             EXT_INT[5]  ? 8'h54 : 
							 EXT_INT[6]  ? 8'h56 : 8'h57;
			4'h3: IVEC = 8'h4C;
			4'h2: IVEC = 8'h4D;
			4'h1: IVEC = EXT_INT[8]  ? 8'h58 : 
			             EXT_INT[9]  ? 8'h59 : 
							 EXT_INT[10] ? 8'h5A : 
							 EXT_INT[11] ? 8'h5B :
							 EXT_INT[12] ? 8'h5C :
							 EXT_INT[13] ? 8'h5D :
							 EXT_INT[14] ? 8'h5E : 8'h5F;
			4'h0: IVEC = 8'h00;
		endcase
	end
	
	bit [7:0] IVEC_DO;
	bit       IVEC_WAIT;
	always @(posedge CLK or negedge RST_N) begin
		bit [2:0] IVEC_WAIT_CNT;
		bit       IVEC_STATE;
		
		if (!RST_N) begin
			IVEC_DO <= '0;
			IVEC_WAIT <= 0;
			IVEC_STATE <= 0;
		end
		else if (!RES_N) begin
			IVEC_DO <= '0;
			IVEC_WAIT <= 0;
			IVEC_STATE <= 0;
		end 
		else if (CE_F) begin
			if (!IVEC_WAIT && !IVEC_STATE && !CIVECF_N && !CRD_N) begin
				IVEC_STATE <= 1;
				IVEC_WAIT <= 1;
				IVEC_WAIT_CNT <= FAST ? 3'd0 : 3'd6;
			end else if (IVEC_WAIT && IVEC_STATE) begin
				IVEC_WAIT_CNT <= IVEC_WAIT_CNT - 3'd1;
				if (IVEC_WAIT_CNT == 3'd0) begin
					IVEC_WAIT <= 0;
					IVEC_DO <= IVEC;
				end
			end else if (IVEC_STATE && CRD_N) begin
				IVEC_STATE <= 0;
			end
		end
	end
	
	
	//Registers
	bit [ 7: 2] REG_A;
	bit [31: 0] REG_WDI;
	bit [ 3: 0] REG_WREN;
	bit [31: 0] REG_DO;
	bit         REG_WWAIT,REG_WWAIT1,REG_WWAIT2,REG_RWAIT;
	bit [ 2: 0] REG_WAIT_DELAY;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			T0C <= '0;
			T1S <= '0;
			T1MD <= T1MD_INIT;
			ASR0 <= ASR0_INIT;
			ASR1 <= ASR1_INIT;
			RSEL <= RSEL_INIT;
			
			{REG_WWAIT,REG_WWAIT1,REG_WWAIT2,REG_RWAIT} <= '0;
		end
		else if (!RES_N) begin
			T0C <= '0;
			T1S <= '0;
			T1MD <= T1MD_INIT;
			ASR0 <= ASR0_INIT;
			ASR1 <= ASR1_INIT;
			RSEL <= RSEL_INIT;
		end else begin
			if (REG_WR) begin
				REG_A <= CA[7:2];
				REG_WDI <= CDI;
				REG_WREN <= ~CDQM_N;
				REG_WWAIT <= 1;
			end
			if (REG_RD) begin
				REG_A <= CA[7:2];
				REG_WAIT_DELAY <= 3'd4;
				REG_RWAIT <= 1;
			end
			
			if (REG_WWAIT && CE_R) begin
				case ({REG_A,2'b00})
					8'h90: begin
						if (REG_WREN[3]) T0C[31:24] <= REG_WDI[31:24] & T0C_WMASK[31:24];
						if (REG_WREN[2]) T0C[23:16] <= REG_WDI[23:16] & T0C_WMASK[23:16];
						if (REG_WREN[1]) T0C[15: 8] <= REG_WDI[15: 8] & T0C_WMASK[15: 8];
						if (REG_WREN[0]) T0C[ 7: 0] <= REG_WDI[ 7: 0] & T0C_WMASK[ 7: 0];
					end
					8'h94: begin
						if (REG_WREN[3]) T1S[31:24] <= REG_WDI[31:24] & T1S_WMASK[31:24];
						if (REG_WREN[2]) T1S[23:16] <= REG_WDI[23:16] & T1S_WMASK[23:16];
						if (REG_WREN[1]) T1S[15: 8] <= REG_WDI[15: 8] & T1S_WMASK[15: 8];
						if (REG_WREN[0]) T1S[ 7: 0] <= REG_WDI[ 7: 0] & T1S_WMASK[ 7: 0];
					end
					8'h98: begin
						if (REG_WREN[3]) T1MD[31:24] <= REG_WDI[31:24] & T1MD_WMASK[31:24];
						if (REG_WREN[2]) T1MD[23:16] <= REG_WDI[23:16] & T1MD_WMASK[23:16];
						if (REG_WREN[1]) T1MD[15: 8] <= REG_WDI[15: 8] & T1MD_WMASK[15: 8];
						if (REG_WREN[0]) T1MD[ 7: 0] <= REG_WDI[ 7: 0] & T1MD_WMASK[ 7: 0];
					end
					8'hB0: ASR0 <= REG_WDI & ASR0_WMASK;
					8'hB4: ASR1 <= REG_WDI & ASR1_WMASK;
					8'hC4: RSEL <= REG_WDI[0] & RSEL_WMASK[0];
					default:;
				endcase
			end
			
			if (REG_RWAIT && REG_WAIT_DELAY == 3'd2 && CE_F) begin
				case ({REG_A,2'b00})
					8'h00: REG_DO <= DR[0] & DxR_RMASK;
					8'h04: REG_DO <= DW[0] & DxW_RMASK;
					8'h08: REG_DO <= DC[0] & D0C_RMASK;
					8'h20: REG_DO <= DR[1] & DxR_RMASK;
					8'h24: REG_DO <= DW[1] & DxW_RMASK;
					8'h28: REG_DO <= DC[1] & D12C_RMASK;
					8'h40: REG_DO <= DR[2] & DxR_RMASK;
					8'h44: REG_DO <= DW[2] & DxW_RMASK;
					8'h48: REG_DO <= DC[2] & D12C_RMASK;
					8'h7C: REG_DO <= DSTA & DSTA_RMASK;
					
					8'hA4: REG_DO <= IST & IST_RMASK;
					
					8'hB0: REG_DO <= ASR0 & ASR0_RMASK;
					8'hB4: REG_DO <= ASR1 & ASR1_RMASK;
					
					8'hC4: REG_DO <= RSEL & RSEL_RMASK;
					8'hC8: REG_DO <= 32'h00000004;
					
					default: REG_DO <= '0;
				endcase
			end
			
			if (CE_R) begin
				if (REG_WAIT_DELAY) REG_WAIT_DELAY <= REG_WAIT_DELAY - 3'd1;
				else if (REG_RWAIT) REG_RWAIT <= 0;
				
				REG_WWAIT1 <= REG_WWAIT;
				REG_WWAIT2 <= REG_WWAIT1;
				if (REG_WWAIT) REG_WWAIT <= 0;
			end
		end
	end
	
	assign CDO = ABUS_SEL  ? ABUS_BUF : 
	             BBUS_SEL  ? BBUS_BUF :
	             !CIVECF_N ? {24'h000000,IVEC_DO} :
					 DSP_SEL   ? DSP_DO : 
					             REG_DO;
	assign CWAIT_N = ~(CBUS_WAIT | IVEC_WAIT | REG_RWAIT | REG_WWAIT);
	
endmodule

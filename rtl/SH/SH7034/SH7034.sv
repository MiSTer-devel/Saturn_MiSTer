module SH7034
#(
	parameter rom_file = "sh7034.mif", bit UBC_DISABLE=0, bit SCI0_DISABLE=0, bit SCI1_DISABLE=0, bit WDT_DISABLE=0
)
(
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	input             EN,
	
	input             RES_N,
	input             NMI_N,
	
	output     [21:0] A,
	input      [15:0] DI,
	output     [15:0] DO,

	//PA in
	input             PA0I_TIOCA0,
	input             PA1I,
	input             PA2I_TIOCB0,
	input             PA3I_WAITN,
	input             PA4I,
	input             PA5I,
	input             PA6I,
	input             PA7I,
	input             PA8I_BREQN,
	input             PA9I_ADTRGN,
	input             PA10I_DPL_TIOCA1,
	input             PA11I_DPH_TIOCB1,
	input             PA12I_IRQ0N_TCLKA,
	input             PA13I_IRQ1N_TCLKB_DREQ0N,
	input             PA14I_IRQ2N,
	input             PA15I_IRQ3N_DREQ1N,
	//PB in
	input             PB0I_TIOCA2,
	input             PB1I_TIOCB2,
	input             PB2I_TIOCA3,
	input             PB3I_TIOCB3,
	input             PB4I_TIOCA4,
	input             PB5I_TIOCB4,
	input             PB6I_TCLKC,
	input             PB7I_TCLKD,
	input             PB8I_RXD0,
	input             PB9I,
	input             PB10I_RXD1,
	input             PB11I,
	input             PB12I_IRQ4N_SCK0I,
	input             PB13I_IRQ5N_SCK1I,
	input             PB14I_IRQ6N,
	input             PB15I_IRQ7N,
	//PC in
	input             PC0I,
	input             PC1I,
	input             PC2I,
	input             PC3I,
	input             PC4I,
	input             PC5I,
	input             PC6I,
	input             PC7I,
	//PA out
	output            PA0O_CS4N_TIOCA0,
	output            PA1O_CS5N_RASN,
	output            PA2O_CS6N_TIOCB0,
	output            PA3O_CS7N,
	output            PA4O_WRLN,
	output            PA5O_WRHN,
	output            PA6O_RDN,
	output            PA7O_BACKN,
	output            PA8O,
	output            PA9O_AHN_IRQOUTN,
	output            PA10O_DPL_TIOCA1,
	output            PA11O_DPH_TIOCB1,
	output            PA12O_DACK0,
	output            PA13O,
	output            PA14O_DACK1,
	output            PA15O,
	//PB out
	output            PB0O_TIOCA2_TP0,
	output            PB1O_TIOCB2_TP1,
	output            PB2O_TIOCA3_TP2,
	output            PB3O_TIOCB3_TP3,
	output            PB4O_TIOCA4_TP4,
	output            PB5O_TIOCB4_TP5,
	output            PB6O_TOCXA4_TP6,
	output            PB7O_TOCXB4_TP7,
	output            PB8O_TP8,
	output            PB9O_TXD0_TP9,
	output            PB10O_TP10,
	output            PB11O_TXD1_TP11,
	output            PB12O_SCK0O_TP12,
	output            PB13O_SCK1O_TP13,
	output            PB14O_TP14,
	output            PB15O_TP15,
	
	output            CS0N,
	output            CS1N_CASHN,
	output            CS2N,
	output            CS3N_CASLN,
	
	output            WDTOVF_N,
	
	input       [2:0] MD
);
	import SH7034_PKG::*;
	
	bit [27:0] CBUS_A;
	bit [31:0] CBUS_DO;
	bit [31:0] CBUS_DI;
	bit        CBUS_WR;
	bit  [3:0] CBUS_BA;
	bit        CBUS_REQ;
	bit        CBUS_WAIT;
	
	bit [27:0] IBUS_A;
	bit [31:0] IBUS_DO;
	bit [31:0] IBUS_DI;
	bit  [3:0] IBUS_BA;
	bit        IBUS_WE;
	bit        IBUS_REQ;
	bit        IBUS_WAIT;
	bit        IBUS_LOCK;
	
	bit  [3:0] INT_LVL;
	bit  [7:0] INT_VEC;
	bit        INT_REQ;
	bit  [3:0] INT_MASK;
	bit        INT_ACK;
	bit        INT_ACP;
	bit        VECT_REQ;
	bit        VECT_WAIT;
	
	//BSC
	bit  [7:0] BSC_CS_N;
	bit        BSC_RAS_N;
	bit        BSC_CASL_N;
	bit        BSC_CASH_N;
	bit        BSC_WRL_N;
	bit        BSC_WRH_N;
	bit        BSC_RD_N;
	bit        BSC_WAIT_N;
	bit        BSC_BACK_N;
	bit        BSC_BREQ_N;
	bit [31:0] BSC_DO;
	bit        BSC_BUSY;
	bit        BSC_ACK;
	
	//DMAC
	bit        DREQ0_N;
	bit        DREQ1_N;
	bit        DACK0;
	bit        DACK1;
	bit [31:0] DMAC_DO;
	bit        DMAC_ACT;
	bit        DMAC_BUSY;
	bit        DMAC0_IRQ;
	bit        DMAC1_IRQ;
	bit        DMAC2_IRQ;
	bit        DMAC3_IRQ;
	
	//RAM
	bit [31:0] RAM_DO;
	bit        RAM_ACT;
	
	//ROM
	bit [31:0] ROM_DO;
	bit        ROM_ACT;
	
	//INTC
	bit  [7:0] INTC_IRQ_N;
	bit        INTC_IRQOUT_N;
	bit [31:0] INTC_DO;
	bit        INTC_ACT;
	bit        INTC_BUSY;
	
	//MULT
	bit  [1:0] MAC_SEL;
	bit  [3:0] MAC_OP;
	bit        MAC_S;
	bit        MAC_WE;
	bit [31:0] MULT_DO;
	
	//SCI
	bit        SCI_RXD0;
	bit        SCI_RXD1;
	bit        SCI_TXD0;
	bit        SCI_TXD1;
	bit        SCI_SCK0I;
	bit        SCI_SCK1I;
	bit        SCI_SCK0O;
	bit        SCI_SCK1O;
	bit [31:0] SCI0_DO;
	bit [31:0] SCI1_DO;
	bit        SCI0_ACT;
	bit        SCI1_ACT;
	bit        TEI0_IRQ;
	bit        TXI0_IRQ;
	bit        RXI0_IRQ;
	bit        ERI0_IRQ;
	bit        TEI1_IRQ;
	bit        TXI1_IRQ;
	bit        RXI1_IRQ;
	bit        ERI1_IRQ;
	
	//ITU
	bit        TCLKA;
	bit        TCLKB;
	bit        TCLKC;
	bit        TCLKD;
	bit  [4:0] TIOCAI;
	bit  [4:0] TIOCBI;
	bit  [4:0] TIOCAO;
	bit  [4:0] TIOCBO;
	bit        TOCXA4;
	bit        TOCXB4;
	bit [31:0] ITU_DO;
	bit        ITU_ACT;
	bit  [4:0] IMIA_IRQ;
	bit  [4:0] IMIB_IRQ;
	bit  [4:0] OVI_IRQ;
	
	//WDT
	bit [31:0] WDT_DO;
	bit        WDT_ACT;
	bit        ITI_IRQ;
	bit        WDT_PRES;
	bit        WDT_MRES;
	
	//UBC
	bit [31:0] UBC_DO;
	bit        UBC_ACT;
	bit        UBC_IRQ;
	
	//PFC
	bit [31:0] PFC_DO;
	bit        PFC_ACT;
	
	//Internal clocks
	bit        CLK2_CE;
	bit        CLK4_CE;
	bit        CLK8_CE;
	bit        CLK16_CE;
//	bit        CLK32_CE;
	bit        CLK64_CE;
	bit        CLK128_CE;
	bit        CLK256_CE;
	bit        CLK512_CE;
	bit        CLK1024_CE;
	//bit        CLK2048_CE;
	bit        CLK4096_CE;
	bit        CLK8192_CE;
	
	bit        RES_SYNC_N;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			RES_SYNC_N <= 0;
		end
		else begin	
			if (CE_R) begin
				RES_SYNC_N <= RES_N;
			end
		end
	end
	
	SH_core #(.VER(0)) core
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE(CE_R),
		.EN(EN),
		
		.RES_N(RES_SYNC_N),
		.NMI_N(NMI_N),
		
		.BUS_A(CBUS_A),
		.BUS_DI(CBUS_DI),
		.BUS_DO(CBUS_DO),
		.BUS_WR(CBUS_WR),
		.BUS_BA(CBUS_BA),
		.BUS_REQ(CBUS_REQ),
		.BUS_WAIT(CBUS_WAIT),
		
		.MAC_SEL(MAC_SEL),
		.MAC_OP(MAC_OP),
		.MAC_S(MAC_S),
		.MAC_WE(MAC_WE),
		
		.INT_LVL(INT_LVL),
		.INT_VEC(INT_VEC),
		.INT_REQ(INT_REQ),
		.INT_MASK(INT_MASK),
		.INT_ACK(INT_ACK),
		.INT_ACP(INT_ACP),
		.VECT_REQ(VECT_REQ),
		.VECT_WAIT(VECT_WAIT)
	);
	
	assign CBUS_DI = |MAC_SEL && MAC_OP == 4'b1100 && !MAC_WE ? MULT_DO : IBUS_DI;
	assign CBUS_WAIT = IBUS_WAIT;
	
	wire [31:0] MULT_DI = |MAC_SEL && MAC_OP[3:2] == 2'b10 ? IBUS_DI : CBUS_DO;
	SH7034_MULT mult
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.RES_N(RES_SYNC_N),
		
		.CBUS_A(CBUS_A),
		.CBUS_DI(MULT_DI),
		.CBUS_DO(MULT_DO),
		.CBUS_WR(CBUS_WR),
		.CBUS_BA(CBUS_BA),
		.CBUS_REQ(CBUS_REQ),
		.CBUS_BUSY(),
		
		.MAC_SEL(MAC_SEL),
		.MAC_OP(MAC_OP),
		.MAC_S(MAC_S),
		.MAC_WE(MAC_WE)
	);
	
	assign IBUS_A = CBUS_A;
	assign IBUS_BA = CBUS_BA;
	assign IBUS_DO = |MAC_SEL && MAC_OP == 4'b1110 && !MAC_WE ? MULT_DO : CBUS_DO;
	assign IBUS_WE = CBUS_WR;
	assign IBUS_REQ = CBUS_REQ;
	
	assign IBUS_DI = INTC_ACT ? INTC_DO : 
						  ITU_ACT  ? ITU_DO : 
						  WDT_ACT  ? WDT_DO : 
						  SCI0_ACT ? SCI0_DO : 
						  SCI1_ACT ? SCI1_DO : 
						  UBC_ACT  ? UBC_DO : 
						  PFC_ACT  ? PFC_DO :
						             DMAC_DO;
	assign IBUS_WAIT = DMAC_BUSY;
	
	SH7034_UBC #(UBC_DISABLE) ubc
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.RES_N(RES_SYNC_N),
		
		.IBUS_A(IBUS_A),
		.IBUS_DI(IBUS_DO),
		.IBUS_DO(UBC_DO),
		.IBUS_BA(IBUS_BA),
		.IBUS_WE(IBUS_WE),
		.IBUS_REQ(IBUS_REQ),
		.IBUS_BUSY(),
		.IBUS_ACT(UBC_ACT),
		
		.IRQ(UBC_IRQ)
	);
	
	bit  [27:0] DBUS_A;
	bit  [31:0] DBUS_DI;
	bit  [31:0] DBUS_DO;
	bit   [3:0] DBUS_BA;
	bit         DBUS_WE;
	bit         DBUS_REQ;
	bit         DBUS_WAIT;
	bit         DBUS_LOCK;
	SH7034_DMAC dmac
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.RES_N(RES_SYNC_N),
		.NMI_N(NMI_N),
		
		.DREQ0_N(DREQ0_N),
		.DACK0(DACK0),
		.DREQ1_N(DREQ1_N),
		.DACK1(DACK1),
		
		.RXI0_IRQ(RXI0_IRQ),
		.TXI0_IRQ(TXI0_IRQ),
		.RXI1_IRQ(RXI1_IRQ),
		.TXI1_IRQ(TXI1_IRQ),
		.IMIA0_IRQ(IMIA_IRQ[0]),
		.IMIA1_IRQ(IMIA_IRQ[1]),
		.IMIA2_IRQ(IMIA_IRQ[2]),
		.IMIA3_IRQ(IMIA_IRQ[3]),
		.ADI_IRQ(1'b0),
		
		.IBUS_A(IBUS_A),
		.IBUS_DI(IBUS_DO),
		.IBUS_DO(DMAC_DO),
		.IBUS_BA(IBUS_BA),
		.IBUS_WE(IBUS_WE),
		.IBUS_REQ(IBUS_REQ),
		.IBUS_BUSY(DMAC_BUSY),
		.IBUS_LOCK(IBUS_LOCK),
		.IBUS_ACT(DMAC_ACT),
		
		.DBUS_A(DBUS_A),
		.DBUS_DI(DBUS_DI),
		.DBUS_DO(DBUS_DO),
		.DBUS_BA(DBUS_BA),
		.DBUS_WE(DBUS_WE),
		.DBUS_REQ(DBUS_REQ),
		.DBUS_WAIT(BSC_BUSY),
		.DBUS_LOCK(DBUS_LOCK),
		
		.BSC_ACK(BSC_ACK),
		
		.DMAC0_IRQ(DMAC0_IRQ),
		.DMAC1_IRQ(DMAC1_IRQ),
		.DMAC2_IRQ(DMAC2_IRQ),
		.DMAC3_IRQ(DMAC3_IRQ)
	);
	assign DBUS_DI = RAM_ACT ? RAM_DO : 
	                 ROM_ACT ? ROM_DO : 
	                           BSC_DO;
	
	SH7034_RAM ram
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.IBUS_A(IBUS_A),
		.IBUS_DI(IBUS_DO),
		.IBUS_DO(RAM_DO),
		.IBUS_BA(IBUS_BA),
		.IBUS_WE(IBUS_WE),
		.IBUS_REQ(IBUS_REQ),
		.IBUS_BUSY(),
		.IBUS_ACT(RAM_ACT)
	);
	
	SH7034_ROM #(rom_file) rom
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.IBUS_A(DBUS_A),
		.IBUS_DI(DBUS_DO),
		.IBUS_DO(ROM_DO),
		.IBUS_BA(DBUS_BA),
		.IBUS_WE(DBUS_WE),
		.IBUS_REQ(DBUS_REQ),
		.IBUS_BUSY(),
		.IBUS_ACT(ROM_ACT)
	);
	
	bit  [23:0] IA;
	bit  [15:0] IDI;
	bit  [15:0] IDO;
	bit         BUS_RLS;
	SH7034_BSC #(.AREA3(0), .W3(1), .IW3(0), .LW3(0)) bsc
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.RES_N(RES_SYNC_N),
		
		.A(A),
		.DI(DI),
		.DO(DO),
		.CS_N(BSC_CS_N),
		.WRL_N(BSC_WRL_N),
		.WRH_N(BSC_WRH_N),
		.RD_N(BSC_RD_N),
		.WAIT_N(BSC_WAIT_N),
		.BREQ_N(BSC_BREQ_N),
		.BACK_N(BSC_BACK_N),
		.MD(MD),
		
		.IBUS_A(DBUS_A),
		.IBUS_DI(DBUS_DO),
		.IBUS_DO(BSC_DO),
		.IBUS_BA(DBUS_BA),
		.IBUS_WE(DBUS_WE),
		.IBUS_REQ(DBUS_REQ),
		.IBUS_BUSY(BSC_BUSY),
		.IBUS_LOCK(DBUS_LOCK),
		.IBUS_ACT(),
		
		.IRQ(),
		
		.CACK(BSC_ACK),
		.BUS_RLS(BUS_RLS)
	);
	
	SH7034_INTC intc
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.RES_N(RES_SYNC_N),
		.NMI_N(NMI_N),
		.IRQ_N(INTC_IRQ_N),
		.IRQOUT_N(INTC_IRQOUT_N),
		
		.INT_MASK(INT_MASK),
		.INT_ACK(INT_ACK),
		.INT_ACP(INT_ACP),
		.INT_LVL(INT_LVL),
		.INT_VEC(INT_VEC),
		.INT_REQ(INT_REQ),
		.VECT_REQ(VECT_REQ),
		.VECT_WAIT(VECT_WAIT),
		
		.UBC_IRQ(UBC_IRQ),
		.DMAC0_IRQ(DMAC0_IRQ),
		.DMAC1_IRQ(DMAC1_IRQ),
		.WDT_IRQ(ITI_IRQ),
		.BSC_IRQ(1'b0),
		.SCI0_ERI_IRQ(ERI0_IRQ),
		.SCI0_RXI_IRQ(RXI0_IRQ),
		.SCI0_TXI_IRQ(TXI0_IRQ),
		.SCI0_TEI_IRQ(TEI0_IRQ),
		.SCI1_ERI_IRQ(ERI1_IRQ),
		.SCI1_RXI_IRQ(RXI1_IRQ),
		.SCI1_TXI_IRQ(TXI1_IRQ),
		.SCI1_TEI_IRQ(TEI1_IRQ),
		.ITU_IMIA_IRQ(IMIA_IRQ),
		.ITU_IMIB_IRQ(IMIB_IRQ),
		.ITU_OVI_IRQ(OVI_IRQ),
		
		.IBUS_A(IBUS_A),
		.IBUS_DI(IBUS_DO),
		.IBUS_DO(INTC_DO),
		.IBUS_BA(IBUS_BA),
		.IBUS_WE(IBUS_WE),
		.IBUS_REQ(IBUS_REQ),
		.IBUS_BUSY(INTC_BUSY),
		.IBUS_ACT(INTC_ACT),
		
		.VBUS_WAIT(IBUS_WAIT)
	);

	
	//Clock divider
	always @(posedge CLK or negedge RST_N) begin
		bit [12:0] DIV_CNT;
		
		if (!RST_N) begin
			CLK2_CE <= 0;
			CLK4_CE <= 0;
			CLK8_CE <= 0;
			CLK16_CE <= 0;
			//CLK32_CE <= 0;
			CLK64_CE <= 0;
			CLK128_CE <= 0;
			CLK256_CE <= 0;
			CLK512_CE <= 0;
			CLK1024_CE <= 0;
			//CLK2048_CE <= 0;
			CLK4096_CE <= 0;
			CLK8192_CE <= 0;
			DIV_CNT <= '0;
		end
		else if (CE_R) begin	
			DIV_CNT <= DIV_CNT + 13'd1;
			CLK2_CE    <= (DIV_CNT ==? 13'b????????????1);
			CLK4_CE    <= (DIV_CNT ==? 13'b???????????11);
			CLK8_CE    <= (DIV_CNT ==? 13'b??????????111);
			CLK16_CE   <= (DIV_CNT ==? 13'b?????????1111);
			//CLK32_CE   <= (DIV_CNT ==? 13'b????????11111);
			CLK64_CE   <= (DIV_CNT ==? 13'b???????111111);
			CLK128_CE  <= (DIV_CNT ==? 13'b??????1111111);
			CLK256_CE  <= (DIV_CNT ==? 13'b?????11111111);
			CLK512_CE  <= (DIV_CNT ==? 13'b????111111111);
			CLK1024_CE <= (DIV_CNT ==? 13'b???1111111111);
			//CLK2048_CE <= (DIV_CNT ==? 13'b??11111111111);
			CLK4096_CE <= (DIV_CNT ==? 13'b?111111111111);
			CLK8192_CE <= (DIV_CNT ==? 13'b1111111111111);
		end
	end

	SH7034_SCI #(0,SCI0_DISABLE) sci0
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.RES_N(RES_SYNC_N),
		
		.RXD(SCI_RXD0),
		.TXD(SCI_TXD0),
		.SCKO(SCI_SCK0O),
		.SCKI(SCI_SCK0I),
		
		.CLK4_CE(CLK4_CE),
		.CLK16_CE(CLK16_CE),
		.CLK64_CE(CLK64_CE),
		
		.IBUS_A(DBUS_A),
		.IBUS_DI(DBUS_DO),
		.IBUS_DO(SCI0_DO),
		.IBUS_BA(DBUS_BA),
		.IBUS_WE(DBUS_WE),
		.IBUS_REQ(DBUS_REQ),
		.IBUS_BUSY(),
		.IBUS_ACT(SCI0_ACT),
		
		.TEI_IRQ(TEI0_IRQ),
		.TXI_IRQ(TXI0_IRQ),
		.RXI_IRQ(RXI0_IRQ),
		.ERI_IRQ(ERI0_IRQ)
	);

	SH7034_SCI #(1,SCI1_DISABLE) sci1
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.RES_N(RES_SYNC_N),
		
		.RXD(SCI_RXD1),
		.TXD(SCI_TXD1),
		.SCKO(SCI_SCK1O),
		.SCKI(SCI_SCK1I),
		
		.CLK4_CE(CLK4_CE),
		.CLK16_CE(CLK16_CE),
		.CLK64_CE(CLK64_CE),
		
		.IBUS_A(DBUS_A),
		.IBUS_DI(DBUS_DO),
		.IBUS_DO(SCI1_DO),
		.IBUS_BA(DBUS_BA),
		.IBUS_WE(DBUS_WE),
		.IBUS_REQ(DBUS_REQ),
		.IBUS_BUSY(),
		.IBUS_ACT(SCI1_ACT),
		
		.TEI_IRQ(TEI1_IRQ),
		.TXI_IRQ(TXI1_IRQ),
		.RXI_IRQ(RXI1_IRQ),
		.ERI_IRQ(ERI1_IRQ)
	);
	
	SH7034_ITU itu
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.RES_N(RES_SYNC_N),
		
		.TCLKA(TCLKA),
		.TCLKB(TCLKB),
		.TCLKC(TCLKC),
		.TCLKD(TCLKD),
		.TIOCAI(TIOCAI),
		.TIOCBI(TIOCBI),
		.TIOCAO(TIOCAO),
		.TIOCBO(TIOCBO),
		.TOCXA4(TOCXA4),
		.TOCXB4(TOCXB4),
		
		.CLK2_CE(CLK2_CE),
		.CLK4_CE(CLK4_CE),
		.CLK8_CE(CLK8_CE),
		
		.IBUS_A(DBUS_A),
		.IBUS_DI(DBUS_DO),
		.IBUS_DO(ITU_DO),
		.IBUS_BA(DBUS_BA),
		.IBUS_WE(DBUS_WE),
		.IBUS_REQ(DBUS_REQ),
		.IBUS_BUSY(),
		.IBUS_ACT(ITU_ACT),
		
		.IMIA_IRQ(IMIA_IRQ),
		.IMIB_IRQ(IMIB_IRQ),
		.OVI_IRQ(OVI_IRQ)
	);
	
	SH7034_WDT #(WDT_DISABLE) wdt
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.RES_N(RES_SYNC_N),
		
		.WDTOVF_N(WDTOVF_N),
		
		.CLK2_CE(CLK8_CE),
		.CLK64_CE(CLK64_CE),
		.CLK128_CE(CLK128_CE),
		.CLK256_CE(CLK256_CE),
		.CLK512_CE(CLK512_CE),
		.CLK1024_CE(CLK1024_CE),
		.CLK4096_CE(CLK4096_CE),
		.CLK8192_CE(CLK8192_CE),
		
		.IBUS_A(DBUS_A),
		.IBUS_DI(DBUS_DO),
		.IBUS_DO(WDT_DO),
		.IBUS_BA(DBUS_BA),
		.IBUS_WE(DBUS_WE),
		.IBUS_REQ(DBUS_REQ),
		.IBUS_BUSY(),
		.IBUS_ACT(WDT_ACT),
		
		.ITI_IRQ(ITI_IRQ),
		.PRES(WDT_PRES),
		.MRES(WDT_MRES)
	);

	SH7034_PFC pfc
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		
		.RES_N(RES_SYNC_N),
		
		.PA0I_TIOCA0(PA0I_TIOCA0),
		.PA1I(PA1I),
		.PA2I_TIOCB0(PA2I_TIOCB0),
		.PA3I_WAITN(PA3I_WAITN),
		.PA4I(PA4I),
		.PA5I(PA5I),
		.PA6I(PA6I),
		.PA7I(PA7I),
		.PA8I_BREQN(PA8I_BREQN),
		.PA9I_ADTRGN(PA9I_ADTRGN),
		.PA10I_DPL_TIOCA1(PA10I_DPL_TIOCA1),
		.PA11I_DPH_TIOCB1(PA11I_DPH_TIOCB1),
		.PA12I_IRQ0N_TCLKA(PA12I_IRQ0N_TCLKA),
		.PA13I_IRQ1N_TCLKB_DREQ0N(PA13I_IRQ1N_TCLKB_DREQ0N),
		.PA14I_IRQ2N(PA14I_IRQ2N),
		.PA15I_IRQ3N_DREQ1N(PA15I_IRQ3N_DREQ1N),
		
		.PB0I_TIOCA2(PB0I_TIOCA2),
		.PB1I_TIOCB2(PB1I_TIOCB2),
		.PB2I_TIOCA3(PB2I_TIOCA3),
		.PB3I_TIOCB3(PB3I_TIOCB3),
		.PB4I_TIOCA4(PB4I_TIOCA4),
		.PB5I_TIOCB4(PB5I_TIOCB4),
		.PB6I_TCLKC(PB6I_TCLKC),
		.PB7I_TCLKD(PB7I_TCLKD),
		.PB8I_RXD0(PB8I_RXD0),
		.PB9I(PB9I),
		.PB10I_RXD1(PB10I_RXD1),
		.PB11I(PB11I),
		.PB12I_IRQ4N_SCK0I(PB12I_IRQ4N_SCK0I),
		.PB13I_IRQ5N_SCK1I(PB13I_IRQ5N_SCK1I),
		.PB14I_IRQ6N(PB14I_IRQ6N),
		.PB15I_IRQ7N(PB15I_IRQ7N),
		
		.PC0I(PC0I),
		.PC1I(PC1I),
		.PC2I(PC2I),
		.PC3I(PC3I),
		.PC4I(PC4I),
		.PC5I(PC5I),
		.PC6I(PC6I),
		.PC7I(PC7I),
		
		.PA0O_CS4N_TIOCA0(PA0O_CS4N_TIOCA0),
		.PA1O_CS5N_RASN(PA1O_CS5N_RASN),
		.PA2O_CS6N_TIOCB0(PA2O_CS6N_TIOCB0),
		.PA3O_CS7N(PA3O_CS7N),
		.PA4O_WRLN(PA4O_WRLN),
		.PA5O_WRHN(PA5O_WRHN),
		.PA6O_RDN(PA6O_RDN),
		.PA7O_BACKN(PA7O_BACKN),
		.PA8O(PA8O),
		.PA9O_AHN_IRQOUTN(PA9O_AHN_IRQOUTN),
		.PA10O_DPL_TIOCA1(PA10O_DPL_TIOCA1),
		.PA11O_DPH_TIOCB1(PA11O_DPH_TIOCB1),
		.PA12O_DACK0(PA12O_DACK0),
		.PA13O(PA13O),
		.PA14O_DACK1(PA14O_DACK1),
		.PA15O(PA15O),
		
		.PB0O_TIOCA2_TP0(PB0O_TIOCA2_TP0),
		.PB1O_TIOCB2_TP1(PB1O_TIOCB2_TP1),
		.PB2O_TIOCA3_TP2(PB2O_TIOCA3_TP2),
		.PB3O_TIOCB3_TP3(PB3O_TIOCB3_TP3),
		.PB4O_TIOCA4_TP4(PB4O_TIOCA4_TP4),
		.PB5O_TIOCB4_TP5(PB5O_TIOCB4_TP5),
		.PB6O_TOCXA4_TP6(PB6O_TOCXA4_TP6),
		.PB7O_TOCXB4_TP7(PB7O_TOCXB4_TP7),
		.PB8O_TP8(PB8O_TP8),
		.PB9O_TXD0_TP9(PB9O_TXD0_TP9),
		.PB10O_TP10(PB10O_TP10),
		.PB11O_TXD1_TP11(PB11O_TXD1_TP11),
		.PB12O_SCK0O_TP12(PB12O_SCK0O_TP12),
		.PB13O_SCK1O_TP13(PB13O_SCK1O_TP13),
		.PB14O_TP14(PB14O_TP14),
		.PB15O_TP15(PB15O_TP15),
		
		.CS0N(CS0N),
		.CS1N_CASHN(CS1N_CASHN),
		.CS2N(CS2N),
		.CS3N_CASLN(CS3N_CASLN),
		
		//BSC
		.CS_N(BSC_CS_N),
		.RAS_N(1'b1),
		.CASL_N(1'b1),
		.CASH_N(1'b1),
		.WRL_N(BSC_WRL_N),
		.WRH_N(BSC_WRH_N),
		.RD_N(BSC_RD_N),
		.AH_N(1'b1),
		.WAIT_N(BSC_WAIT_N),
		.BACK_N(BSC_BACK_N),
		.BREQ_N(BSC_BREQ_N),
		.DPLO(1'b1),
		.DPHO(1'b1),
		//DMAC
		.DACK0(DACK0),
		.DACK1(DACK1),
		.DREQ0_N(DREQ0_N),
		.DREQ1_N(DREQ1_N),
		//SCI
		.RXD0(SCI_RXD0),
		.TXD0(SCI_TXD0),
		.SCK0I(SCI_SCK0I),
		.SCK0O(SCI_SCK0O),
		.RXD1(SCI_RXD1),
		.TXD1(SCI_TXD1),
		.SCK1I(SCI_SCK1I),
		.SCK1O(SCI_SCK1O),
		
		.TCLKA(TCLKA),
		.TCLKB(TCLKB),
		.TCLKC(TCLKC),
		.TCLKD(TCLKD),
		.TIOCAI(TIOCAI),
		.TIOCBI(TIOCBI),
		.TIOCAO(TIOCAO),
		.TIOCBO(TIOCBO),
		.TOCXA4(TOCXA4),
		.TOCXB4(TOCXB4),
	
		.TP('0),
		
		.IRQOUT_N(INTC_IRQOUT_N),
		.IRQ_N(INTC_IRQ_N),
		
		.IBUS_A(DBUS_A),
		.IBUS_DI(DBUS_DO),
		.IBUS_DO(PFC_DO),
		.IBUS_BA(DBUS_BA),
		.IBUS_WE(DBUS_WE),
		.IBUS_REQ(DBUS_REQ),
		.IBUS_BUSY(),
		.IBUS_ACT(PFC_ACT)
	);
	
	
endmodule

module SH7034_PFC 
(
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	
	input             RES_N,
	
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
	
	input             PC0I,
	input             PC1I,
	input             PC2I,
	input             PC3I,
	input             PC4I,
	input             PC5I,
	input             PC6I,
	input             PC7I,
	
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
	
	//BSC
	input       [7:0] CS_N,
	input             RAS_N,
	input             CASL_N,
	input             CASH_N,
	input             WRL_N,
	input             WRH_N,
	input             RD_N,
	input             AH_N,
	output            WAIT_N,
	input             BACK_N,
	output            BREQ_N,
	input             DPLO,
	input             DPHO,
	//DMAC
	input             DACK0,
	input             DACK1,
	output            DREQ0_N,
	output            DREQ1_N,
	//SCI
	output            RXD0,
	input             TXD0,
	output            SCK0I,
	input             SCK0O,
	output            RXD1,
	input             TXD1,
	output            SCK1I,
	input             SCK1O,
	
	output            TCLKA,
	output            TCLKB,
	output            TCLKC,
	output            TCLKD,
	output      [4:0] TIOCAI,
	output      [4:0] TIOCBI,
	input       [4:0] TIOCAO,
	input       [4:0] TIOCBO,
	input             TOCXA4,
	input             TOCXB4,
	
	input      [15:0] TP,
	//INTC
	input             IRQOUT_N,
	output      [7:0] IRQ_N,
	
	input      [27:0] IBUS_A,
	input      [31:0] IBUS_DI,
	output     [31:0] IBUS_DO,
	input       [3:0] IBUS_BA,
	input             IBUS_WE,
	input             IBUS_REQ,
	output            IBUS_BUSY,
	output            IBUS_ACT
);

	import SH7034_PKG::*;
	
	PADR_t     PADR;
	PBDR_t     PBDR;
	PAIOR_t    PAIOR;
	PBIOR_t    PBIOR;
	PACR1_t    PACR1;
	PACR2_t    PACR2;
	PBCR1_t    PBCR1;
	PBCR2_t    PBCR2;
	CASCR_t    CASCR;
	
	bit [15:0] PAI;
	bit [15:0] PBI;
	bit [15:0] PCI;
	
	assign PAI[0]  = PACR2.PA0MD  ==? 2'b00 ? PA0I_TIOCA0              : 1'b0;
	assign PAI[1]  = PACR2.PA1MD  ==? 2'b00 ? PA1I                     : 1'b0;
	assign PAI[2]  = PACR2.PA2MD  ==? 2'b00 ? PA2I_TIOCB0              : 1'b0;
	assign PAI[3]  = PACR2.PA3MD  ==? 2'b00 ? PA3I_WAITN               : 1'b0;
	assign PAI[4]  = PACR2.PA4MD  ==? 2'b?0 ? PA4I                     : 1'b0;
	assign PAI[5]  = PACR2.PA5MD  ==? 2'b?0 ? PA5I                     : 1'b0;
	assign PAI[6]  = PACR2.PA6MD  ==? 2'b?0 ? PA6I                     : 1'b0;
	assign PAI[7]  = PACR2.PA7MD  ==? 2'b?0 ? PA7I                     : 1'b0;
	assign PAI[8]  = PACR1.PA8MD  ==? 2'b?0 ? PA8I_BREQN               : 1'b0;
	assign PAI[9]  = PACR1.PA9MD  ==? 2'b00 ? PA9I_ADTRGN              : 1'b0;
	assign PAI[10] = PACR1.PA10MD ==? 2'b00 ? PA10I_DPL_TIOCA1         : 1'b0;
	assign PAI[11] = PACR1.PA11MD ==? 2'b00 ? PA11I_DPH_TIOCB1         : 1'b0;
	assign PAI[12] = PACR1.PA12MD ==? 2'b00 ? PA12I_IRQ0N_TCLKA        : 1'b0;
	assign PAI[13] = PACR1.PA13MD ==? 2'b00 ? PA13I_IRQ1N_TCLKB_DREQ0N : 1'b0;
	assign PAI[14] = PACR1.PA14MD ==? 2'b00 ? PA14I_IRQ2N              : 1'b0;
	assign PAI[15] = PACR1.PA15MD ==? 2'b00 ? PA15I_IRQ3N_DREQ1N       : 1'b0;
	
	assign PBI[0]  = PBCR2.PB0MD  ==? 2'b00 ? PB0I_TIOCA2              : 1'b0;
	assign PBI[1]  = PBCR2.PB1MD  ==? 2'b00 ? PB1I_TIOCB2              : 1'b0;
	assign PBI[2]  = PBCR2.PB2MD  ==? 2'b00 ? PB2I_TIOCA3              : 1'b0;
	assign PBI[3]  = PBCR2.PB3MD  ==? 2'b00 ? PB3I_TIOCB3              : 1'b0;
	assign PBI[4]  = PBCR2.PB4MD  ==? 2'b00 ? PB4I_TIOCA4              : 1'b0;
	assign PBI[5]  = PBCR2.PB5MD  ==? 2'b00 ? PB5I_TIOCB4              : 1'b0;
	assign PBI[6]  = PBCR2.PB6MD  ==? 2'b00 ? PB6I_TCLKC               : 1'b0;
	assign PBI[7]  = PBCR2.PB7MD  ==? 2'b00 ? PB7I_TCLKD               : 1'b0;
	assign PBI[8]  = PBCR1.PB8MD  ==? 2'b00 ? PB8I_RXD0                : 1'b0;
	assign PBI[9]  = PBCR1.PB9MD  ==? 2'b00 ? PB9I                     : 1'b0;
	assign PBI[10] = PBCR1.PB10MD ==? 2'b00 ? PB10I_RXD1               : 1'b0;
	assign PBI[11] = PBCR1.PB11MD ==? 2'b00 ? PB11I                    : 1'b0;
	assign PBI[12] = PBCR1.PB12MD ==? 2'b00 ? PB12I_IRQ4N_SCK0I        : 1'b0;
	assign PBI[13] = PBCR1.PB13MD ==? 2'b00 ? PB13I_IRQ5N_SCK1I        : 1'b0;
	assign PBI[14] = PBCR1.PB14MD ==? 2'b00 ? PB14I_IRQ6N              : 1'b0;
	assign PBI[15] = PBCR1.PB15MD ==? 2'b00 ? PB15I_IRQ7N              : 1'b0;
	
	assign PCI = {8'h00,PC7I,PC6I,PC5I,PC4I,PC3I,PC2I,PC1I,PC0I};
	
	assign PA0O_CS4N_TIOCA0 = PACR2.PA0MD  ==? 2'b00 ? PADR[0]   : 
	                          PACR2.PA0MD  ==? 2'b01 ? CS_N[4]   : 
	                          PACR2.PA0MD  ==? 2'b10 ? TIOCAO[0] : 
	                                                   1'b0;
	assign PA1O_CS5N_RASN   = PACR2.PA1MD  ==? 2'b00 ? PADR[1]   : 
	                          PACR2.PA1MD  ==? 2'b01 ? CS_N[5]   : 
	                          PACR2.PA1MD  ==? 2'b10 ? RAS_N     : 
	                                                   1'b0;
	assign PA2O_CS6N_TIOCB0 = PACR2.PA2MD  ==? 2'b00 ? PADR[2]   : 
	                          PACR2.PA2MD  ==? 2'b01 ? CS_N[6]   : 
	                          PACR2.PA2MD  ==? 2'b10 ? TIOCBO[0] : 
	                                                   1'b0;
	assign PA3O_CS7N        = PACR2.PA3MD  ==? 2'b00 ? PADR[3]   : 
	                          PACR2.PA3MD  ==? 2'b01 ? CS_N[7]   : 
	                                                   1'b0;
	assign PA4O_WRLN        = PACR2.PA4MD  ==? 2'b?0 ? PADR[4]   : 
	                          PACR2.PA4MD  ==? 2'b?1 ? WRL_N     : 
	                                                   1'b0;
	assign PA5O_WRHN        = PACR2.PA5MD  ==? 2'b?0 ? PADR[5]   : 
	                          PACR2.PA5MD  ==? 2'b?1 ? WRH_N     : 
	                                                   1'b0;
	assign PA6O_RDN         = PACR2.PA6MD  ==? 2'b?0 ? PADR[6]   : 
	                          PACR2.PA6MD  ==? 2'b?1 ? RD_N      : 
	                                                   1'b0;
	assign PA7O_BACKN       = PACR2.PA7MD  ==? 2'b?0 ? PADR[7]   : 
	                          PACR2.PA7MD  ==? 2'b?1 ? BACK_N    : 
	                                                   1'b0;
	assign PA8O             = PACR1.PA8MD  ==? 2'b?0 ? PADR[8]   : 
	                                                   1'b0;
	assign PA9O_AHN_IRQOUTN = PACR1.PA9MD  ==? 2'b00 ? PADR[9]   : 
	                          PACR1.PA9MD  ==? 2'b01 ? AH_N      : 
	                          PACR1.PA9MD  ==? 2'b10 ? 1'b0      : 
	                                                   IRQOUT_N;
	assign PA10O_DPL_TIOCA1 = PACR1.PA10MD ==? 2'b00 ? PADR[10]  : 
	                          PACR1.PA10MD ==? 2'b01 ? DPLO      : 
	                          PACR1.PA10MD ==? 2'b10 ? TIOCAO[1] : 
	                                                   1'b0;
	assign PA11O_DPH_TIOCB1 = PACR1.PA11MD ==? 2'b00 ? PADR[11]  : 
	                          PACR1.PA11MD ==? 2'b01 ? DPHO      : 
	                          PACR1.PA11MD ==? 2'b10 ? TIOCBO[1] : 
	                                                   1'b0;
	assign PA12O_DACK0      = PACR1.PA12MD ==? 2'b00 ? PADR[12]  : 
	                          PACR1.PA12MD ==? 2'b01 ? 1'b0      : 
	                          PACR1.PA12MD ==? 2'b10 ? 1'b0      : 
	                                                   DACK0;
	assign PA13O            = PACR1.PA13MD ==? 2'b00 ? PADR[13]  : 
	                                                   1'b0;
	assign PA14O_DACK1      = PACR1.PA14MD ==? 2'b00 ? PADR[14]  : 
	                          PACR1.PA14MD ==? 2'b01 ? 1'b0      : 
	                          PACR1.PA14MD ==? 2'b10 ? 1'b0      : 
	                                                   DACK1;
	assign PA15O            = PACR1.PA15MD ==? 2'b00 ? PADR[15]  : 
	                                                   1'b0;
									  
	assign PB0O_TIOCA2_TP0  = PBCR2.PB0MD  ==? 2'b00 ? PBDR[0]   : 
	                          PBCR2.PB0MD  ==? 2'b01 ? 1'b0      : 
	                          PBCR2.PB0MD  ==? 2'b10 ? TIOCAO[2] : 
	                                                   TP[0];
	assign PB1O_TIOCB2_TP1  = PBCR2.PB1MD  ==? 2'b00 ? PBDR[1]   : 
	                          PBCR2.PB1MD  ==? 2'b01 ? 1'b0      : 
	                          PBCR2.PB1MD  ==? 2'b10 ? TIOCBO[2] : 
	                                                   TP[1];
	assign PB2O_TIOCA3_TP2  = PBCR2.PB2MD  ==? 2'b00 ? PBDR[2]   : 
	                          PBCR2.PB2MD  ==? 2'b01 ? 1'b0      : 
	                          PBCR2.PB2MD  ==? 2'b10 ? TIOCAO[3] : 
	                                                   TP[2];
	assign PB3O_TIOCB3_TP3  = PBCR2.PB3MD  ==? 2'b00 ? PBDR[3]   : 
	                          PBCR2.PB3MD  ==? 2'b01 ? 1'b0      : 
	                          PBCR2.PB3MD  ==? 2'b10 ? TIOCBO[3] : 
	                                                   TP[3];
	assign PB4O_TIOCA4_TP4  = PBCR2.PB4MD  ==? 2'b00 ? PBDR[4]   : 
	                          PBCR2.PB4MD  ==? 2'b01 ? 1'b0      : 
	                          PBCR2.PB4MD  ==? 2'b10 ? TIOCAO[4] : 
	                                                   TP[4];
	assign PB5O_TIOCB4_TP5  = PBCR2.PB5MD  ==? 2'b00 ? PBDR[5]   : 
	                          PBCR2.PB5MD  ==? 2'b01 ? 1'b0      : 
	                          PBCR2.PB5MD  ==? 2'b10 ? TIOCAO[4] : 
	                                                   TP[5];
	assign PB6O_TOCXA4_TP6  = PBCR2.PB6MD  ==? 2'b00 ? PBDR[6]   : 
	                          PBCR2.PB6MD  ==? 2'b01 ? 1'b0      : 
	                          PBCR2.PB6MD  ==? 2'b10 ? TOCXA4    : 
	                                                   TP[6];
	assign PB7O_TOCXB4_TP7  = PBCR2.PB7MD  ==? 2'b00 ? PBDR[7]   : 
	                          PBCR2.PB7MD  ==? 2'b01 ? 1'b0      : 
	                          PBCR2.PB7MD  ==? 2'b10 ? TOCXB4    : 
	                                                   TP[7];
	assign PB8O_TP8         = PBCR1.PB8MD  ==? 2'b00 ? PBDR[8]   : 
	                          PBCR1.PB8MD  ==? 2'b01 ? 1'b0      : 
	                          PBCR1.PB8MD  ==? 2'b10 ? 1'b0      : 
	                                                   TP[8];
	assign PB9O_TXD0_TP9    = PBCR1.PB9MD  ==? 2'b00 ? PBDR[9]   : 
	                          PBCR1.PB9MD  ==? 2'b01 ? 1'b0      : 
	                          PBCR1.PB9MD  ==? 2'b10 ? TXD0      : 
	                                                   TP[9];
	assign PB10O_TP10       = PBCR1.PB10MD ==? 2'b00 ? PBDR[10]  : 
	                          PBCR1.PB10MD ==? 2'b01 ? 1'b0      : 
	                          PBCR1.PB10MD ==? 2'b10 ? 1'b0      : 
	                                                   TP[10];
	assign PB11O_TXD1_TP11  = PBCR1.PB11MD ==? 2'b00 ? PBDR[11]  : 
	                          PBCR1.PB11MD ==? 2'b01 ? 1'b0      : 
	                          PBCR1.PB11MD ==? 2'b10 ? TXD1      : 
	                                                   TP[11];
	assign PB12O_SCK0O_TP12 = PBCR1.PB12MD ==? 2'b00 ? PBDR[12]  : 
	                          PBCR1.PB12MD ==? 2'b01 ? 1'b0      : 
	                          PBCR1.PB12MD ==? 2'b10 ? SCK0O     : 
	                                                   TP[12];
	assign PB13O_SCK1O_TP13 = PBCR1.PB13MD ==? 2'b00 ? PBDR[13]  : 
	                          PBCR1.PB13MD ==? 2'b01 ? 1'b0      : 
	                          PBCR1.PB13MD ==? 2'b10 ? SCK1O     : 
	                                                   TP[13];
	assign PB14O_TP14       = PBCR1.PB14MD ==? 2'b00 ? PBDR[14]  : 
	                          PBCR1.PB14MD ==? 2'b01 ? 1'b0      : 
	                          PBCR1.PB14MD ==? 2'b10 ? 1'b0      : 
	                                                   TP[14];
	assign PB15O_TP15       = PBCR1.PB15MD ==? 2'b00 ? PBDR[15]  : 
	                          PBCR1.PB15MD ==? 2'b01 ? 1'b0      : 
	                          PBCR1.PB15MD ==? 2'b10 ? 1'b0      : 
	                                                   TP[15];
	
	assign CS0N             = CS_N[0];
	assign CS1N_CASHN       = CASCR.CASHMD  ==? 2'b01 ? CS_N[1]  : 
	                          CASCR.CASHMD  ==? 2'b10 ? CASH_N   : 
						           1'b1;
	assign CS2N             = CS_N[2];
	assign CS3N_CASLN       = CASCR.CASLMD  ==? 2'b01 ? CS_N[3]  : 
	                          CASCR.CASLMD  ==? 2'b10 ? CASL_N   : 
						           1'b1;
						 
	assign WAIT_N   = PA3I_WAITN;//PACR2.PA3MD  ==? 2'b10 ? PA3I_WAITN                 : 1'b1;
	assign BREQ_N   = PACR1.PA8MD  ==? 2'b?1 ? PA8I_BREQN                 : 1'b1;
	
	assign DREQ0_N  = PACR1.PA13MD ==? 2'b11 ? PA13I_IRQ1N_TCLKB_DREQ0N   : 1'b1;
	assign DREQ1_N  = PACR1.PA15MD ==? 2'b11 ? PA15I_IRQ3N_DREQ1N         : 1'b1;
	
	assign IRQ_N[0] = PACR1.PA12MD ==? 2'b01 ? PA12I_IRQ0N_TCLKA          : 1'b1;
	assign IRQ_N[1] = PACR1.PA13MD ==? 2'b01 ? PA13I_IRQ1N_TCLKB_DREQ0N   : 1'b1;
	assign IRQ_N[2] = PACR1.PA14MD ==? 2'b01 ? PA14I_IRQ2N                : 1'b1;
	assign IRQ_N[3] = PACR1.PA15MD ==? 2'b01 ? PA15I_IRQ3N_DREQ1N         : 1'b1;
	assign IRQ_N[4] = PBCR1.PB12MD ==? 2'b01 ? PB12I_IRQ4N_SCK0I          : 1'b1;
	assign IRQ_N[5] = PBCR1.PB13MD ==? 2'b01 ? PB13I_IRQ5N_SCK1I          : 1'b1;
	assign IRQ_N[6] = PBCR1.PB14MD ==? 2'b01 ? PB14I_IRQ6N                : 1'b1;
	assign IRQ_N[7] = PBCR1.PB15MD ==? 2'b01 ? PB15I_IRQ7N                : 1'b1;
	
	assign TCLKA      = PACR1.PA12MD ==? 2'b10 ? PA12I_IRQ0N_TCLKA        : 1'b0;
	assign TCLKB      = PACR1.PA13MD ==? 2'b10 ? PA13I_IRQ1N_TCLKB_DREQ0N : 1'b0;
	assign TCLKC      = PBCR2.PB6MD  ==? 2'b00 ? PB6I_TCLKC               : 1'b0;
	assign TCLKD      = PBCR2.PB7MD  ==? 2'b00 ? PB7I_TCLKD               : 1'b0;
	assign TIOCAI[0]  = PACR2.PA0MD  ==? 2'b10 ? PA0I_TIOCA0              : 1'b0;
	assign TIOCBI[0]  = PACR2.PA2MD  ==? 2'b10 ? PA2I_TIOCB0              : 1'b0;
	assign TIOCAI[1]  = PACR1.PA10MD ==? 2'b10 ? PA10I_DPL_TIOCA1         : 1'b0;
	assign TIOCBI[1]  = PACR1.PA11MD ==? 2'b10 ? PA11I_DPH_TIOCB1         : 1'b0;
	assign TIOCAI[2]  = PBCR2.PB0MD  ==? 2'b10 ? PB0I_TIOCA2              : 1'b0;
	assign TIOCBI[2]  = PBCR2.PB1MD  ==? 2'b10 ? PB1I_TIOCB2              : 1'b0;
	assign TIOCAI[3]  = PBCR2.PB2MD  ==? 2'b10 ? PB2I_TIOCA3              : 1'b0;
	assign TIOCBI[3]  = PBCR2.PB3MD  ==? 2'b10 ? PB3I_TIOCB3              : 1'b0;
	assign TIOCAI[4]  = PBCR2.PB4MD  ==? 2'b10 ? PB4I_TIOCA4              : 1'b0;
	assign TIOCBI[4]  = PBCR2.PB5MD  ==? 2'b10 ? PB5I_TIOCB4              : 1'b0;
	
	assign RXD0     = PBCR1.PB8MD  ==? 2'b10 ? PB8I_RXD0                  : 1'b1;
	assign SCK0I    = PBCR1.PB12MD ==? 2'b10 ? PB12I_IRQ4N_SCK0I          : 1'b1;
	assign RXD1     = PBCR1.PB10MD ==? 2'b10 ? PB10I_RXD1                 : 1'b1;
	assign SCK1I    = PBCR1.PB13MD ==? 2'b10 ? PB13I_IRQ5N_SCK1I          : 1'b1;
	
	
	//Registers
	wire REG_SEL = (IBUS_A >= 28'h5FFFFC0 & IBUS_A <= 28'h5FFFFEF);
	
	wire [15:0] PADRI = (PAI & ~PAIOR) | (PADR & PAIOR);
	wire [15:0] PBDRI = (PBI & ~PBIOR) | (PBDR & PBIOR);
	
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			PADR  <= PADR_INIT;
			PBDR  <= PBDR_INIT;
			PAIOR <= PAIOR_INIT;
			PBIOR <= PBIOR_INIT;
			PACR1 <= PACR1_INIT;
			PACR2 <= PACR2_INIT;
			PBCR1 <= PBCR1_INIT;
			PBCR2 <= PBCR2_INIT;
			CASCR <= CASCR_INIT;
			// synopsys translate_off
			
			// synopsys translate_on
		end
		else if (CE_R) begin
			if (REG_SEL && IBUS_WE && IBUS_REQ) begin
				case ({IBUS_A[5:2],2'b00})
					6'h00: begin
						if (IBUS_BA[3]) PADR[15:8]  <= IBUS_DI[31:24] & PADR_WMASK[15:8];
						if (IBUS_BA[2]) PADR[ 7:0]  <= IBUS_DI[23:16] & PADR_WMASK[7:0];
						if (IBUS_BA[1]) PBDR[15:8] <= IBUS_DI[15: 8] & PBDR_WMASK[15:8];
						if (IBUS_BA[0]) PBDR[ 7:0] <= IBUS_DI[ 7: 0] & PBDR_WMASK[7:0];
					end 
					6'h04: begin
						if (IBUS_BA[3]) PAIOR[15:8] <= IBUS_DI[31:24] & PAIOR_WMASK[15:8];
						if (IBUS_BA[2]) PAIOR[ 7:0] <= IBUS_DI[23:16] & PAIOR_WMASK[7:0];
						if (IBUS_BA[1]) PBIOR[15:8] <= IBUS_DI[15: 8] & PBIOR_WMASK[15:8];
						if (IBUS_BA[0]) PBIOR[ 7:0] <= IBUS_DI[ 7: 0] & PBIOR_WMASK[7:0];
					end 
					6'h08: begin
						if (IBUS_BA[3]) PACR1[15:8] <= IBUS_DI[31:24] & PACR1_WMASK[15:8];
						if (IBUS_BA[2]) PACR1[ 7:0] <= IBUS_DI[23:16] & PACR1_WMASK[7:0];
						if (IBUS_BA[1]) PACR2[15:8] <= IBUS_DI[15: 8] & PACR2_WMASK[15:8];
						if (IBUS_BA[0]) PACR2[ 7:0] <= IBUS_DI[ 7: 0] & PACR2_WMASK[7:0];
					end 
					6'h0C: begin
						if (IBUS_BA[3]) PBCR1[15:8] <= IBUS_DI[31:24] & PBCR1_WMASK[15:8];
						if (IBUS_BA[2]) PBCR1[ 7:0] <= IBUS_DI[23:16] & PBCR1_WMASK[7:0];
						if (IBUS_BA[1]) PBCR2[15:8] <= IBUS_DI[15: 8] & PBCR2_WMASK[15:8];
						if (IBUS_BA[0]) PBCR2[ 7:0] <= IBUS_DI[ 7: 0] & PBCR2_WMASK[7:0];
					end 
					6'h20: begin
						if (IBUS_BA[3]) CASCR[15:8] <= IBUS_DI[31:24] & CASCR_WMASK[15:8];
						if (IBUS_BA[2]) CASCR[ 7:0] <= IBUS_DI[23:16] & CASCR_WMASK[7:0];
					end 
					default:;
				endcase
			end
		end
	end
	
	bit [31:0] REG_DO;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			REG_DO <= '0;
		end
		else if (CE_F) begin
			if (REG_SEL && !IBUS_WE && IBUS_REQ) begin
				case ({IBUS_A[5:2],2'b00})
					6'h00: REG_DO <= {PADRI & PADR_RMASK,PBDRI & PBDR_RMASK};
					6'h04: REG_DO <= {PAIOR & PAIOR_RMASK,PBIOR & PBIOR_RMASK};
					6'h08: REG_DO <= {PACR1 & PACR1_RMASK,PACR2 & PACR2_RMASK};
					6'h0C: REG_DO <= {PBCR1 & PBCR1_RMASK,PBCR2 & PBCR2_RMASK};
					6'h10: REG_DO <= {PCI & PCDR_RMASK,16'h0000};
					6'h20: REG_DO <= {CASCR & CASCR_RMASK,16'h0000};
					default:REG_DO <= '0;
				endcase
			end
		end
	end
	
	assign IBUS_DO = REG_DO;
	assign IBUS_BUSY = 0;
	assign IBUS_ACT = REG_SEL;
	
endmodule

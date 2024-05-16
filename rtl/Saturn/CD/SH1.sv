module SH1
#(
	parameter rom_file = " "
)
(
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	input             EN,
	
	input             RES_N,
	
	output     [21:0] A,
	input      [15:0] DI,
	output     [15:0] DO,

	//PA in
	input             TIOCA0,
	input             TIOCA1,
	input             DREQ0N,
	input             DREQ1N,
	//PA out
	output            RASN,
	output            CS6N,
	output            WRLN,
	output            WRHN,
	output            RDN,
	output            DACK0,
	output            DACK1,
	
	//PB in
	input             TIOCA2,
	input             TIOCB2,
	input             PB2I,
	input             TIOCB3,
	input             RXD0,
	input             IRQ6N,
	input             IRQ7N,
	//PB out
	output            PB6O,
	output            TXD0,
	output            SCK0O,
	
	output            CS1N_CASHN,
	output            CS2N,
	output            CASLN,
	input             WAITN
);

	SH7034 #(.rom_file(rom_file), .UBC_DISABLE(1), .SCI0_DISABLE(0), .SCI1_DISABLE(1), .WDT_DISABLE(1)) sh7034
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_R(CE_R),
		.CE_F(CE_F),
		.EN(EN),
		
		.RES_N(RES_N),
		.NMI_N(1'b1),
		
		.A(A),
		.DI(DI),
		.DO(DO),
		
		.PA0I_TIOCA0(TIOCA0),
		.PA1I(1'b0),
		.PA2I_TIOCB0(1'b0),
		.PA3I_WAITN(WAITN),
		.PA4I(1'b0),
		.PA5I(1'b0),
		.PA6I(1'b0),
		.PA7I(1'b0),
		.PA8I_BREQN(1'b0),
		.PA9I_ADTRGN(1'b0),
		.PA10I_DPL_TIOCA1(TIOCA1),
		.PA11I_DPH_TIOCB1(1'b0),
		.PA12I_IRQ0N_TCLKA(1'b0),
		.PA13I_IRQ1N_TCLKB_DREQ0N(DREQ0N),
		.PA14I_IRQ2N(1'b0),
		.PA15I_IRQ3N_DREQ1N(DREQ1N),
		
		.PB0I_TIOCA2(TIOCA2),
		.PB1I_TIOCB2(TIOCB2),
		.PB2I_TIOCA3(PB2I),
		.PB3I_TIOCB3(TIOCB3),
		.PB4I_TIOCA4(1'b0),
		.PB5I_TIOCB4(1'b0),
		.PB6I_TCLKC(1'b0),
		.PB7I_TCLKD(1'b0),
		.PB8I_RXD0(RXD0),
		.PB9I(1'b0),
		.PB10I_RXD1(1'b1),
		.PB11I(1'b0),
		.PB12I_IRQ4N_SCK0I(1'b0),
		.PB13I_IRQ5N_SCK1I(1'b0),
		.PB14I_IRQ6N(IRQ6N),
		.PB15I_IRQ7N(IRQ7N),
		
		.PC0I(1'b0),
		.PC1I(1'b0),
		.PC2I(1'b0),
		.PC3I(1'b0),
		.PC4I(1'b0),
		.PC5I(1'b0),
		.PC6I(1'b0),
		.PC7I(1'b0),
		
		.PA0O_CS4N_TIOCA0(),
		.PA1O_CS5N_RASN(RASN),
		.PA2O_CS6N_TIOCB0(CS6N),
		.PA3O_CS7N(),
		.PA4O_WRLN(WRLN),
		.PA5O_WRHN(WRHN),
		.PA6O_RDN(RDN),
		.PA7O_BACKN(),
		.PA8O(),
		.PA9O_AHN_IRQOUTN(),
		.PA10O_DPL_TIOCA1(),
		.PA11O_DPH_TIOCB1(),
		.PA12O_DACK0(DACK0),
		.PA13O(),
		.PA14O_DACK1(DACK1),
		.PA15O(),
		
		.PB0O_TIOCA2_TP0(),
		.PB1O_TIOCB2_TP1(),
		.PB2O_TIOCA3_TP2(),
		.PB3O_TIOCB3_TP3(),
		.PB4O_TIOCA4_TP4(),
		.PB5O_TIOCB4_TP5(),
		.PB6O_TOCXA4_TP6(PB6O),
		.PB7O_TOCXB4_TP7(),
		.PB8O_TP8(),
		.PB9O_TXD0_TP9(TXD0),
		.PB10O_TP10(),
		.PB11O_TXD1_TP11(),
		.PB12O_SCK0O_TP12(SCK0O),
		.PB13O_SCK1O_TP13(),
		.PB14O_TP14(),
		.PB15O_TP15(),
		
		.CS0N(),
		.CS1N_CASHN(CS1N_CASHN),
		.CS2N(CS2N),
		.CS3N_CASLN(CASLN),
		
		.WDTOVF_N(),
		
		.MD(3'b010)
	);


endmodule

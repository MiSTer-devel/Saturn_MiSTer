package SCUDSP_PKG;

	typedef struct packed
	{
		bit [15: 0] H;
		bit [31: 0] L;
	} ALUReg_t;

	typedef struct packed
	{
		bit         RAMR;
		bit [ 1: 0] RAMS;
		bit         MULS;
		bit         RXW;
		bit         PW;
		bit [ 3: 0] CTI;
	} XBusInst_t;
	
	typedef struct packed
	{
		bit         RAMR;
		bit [ 1: 0] RAMS;
		bit [ 1: 0] ACS;
		bit         RYW;
		bit         ACW;
		bit [ 3: 0] CTI;
	} YBusInst_t;
	
	typedef struct packed
	{
		bit         IMMS;
		bit [ 1: 0] IMMT;		//Immadiate type (8/25/19)
		bit         ALUS;
		bit         RAMR;
		bit [ 1: 0] RAMS;
		bit         RXW;
		bit         PW;
		bit         RA0W;
		bit         WA0W;
		bit         LOPW;
		bit         TOPW;
		bit         PCW;
		bit         DMAW;		//DMA opcode out
		bit [ 3: 0] RAMW;
		bit [ 3: 0] CTW;
		bit [ 3: 0] CTI;
	} D1BusInst_t;
	
	typedef struct packed
	{
		bit         ST;		//DMA start
		bit         DIR;		//DMA direction (0: D0->RAM, 1: RAM->D0)
		bit [ 3: 0] RAMW;		//DMA DATA RAM write
		bit         PRGW;		//DMA PRG RAM write
		bit [ 3: 0] RAMR;		//DMA DATA RAM read
		bit [ 1: 0] RAMS;		//DMA DATA RAM bank select
//		bit [ 2: 0] ADDI;		//DMA address increment
		bit         CNTM;		//DMA counter source mode (0: IMM8, 1: RAMx)
		bit [ 1: 0] CNTS;		//DMA TN0 source (RAMx)
		bit [ 3: 0] CTI;		//DMA counter source DATA RAM address increment
//		bit         HOLD;
	} DMAInst_t;
	
	typedef struct packed
	{
		bit         BTM;
		bit         LPS;
		bit         END;
		bit         EI;
	} CtlInst_t;
	
	typedef struct packed
	{
		bit         ALU;
		XBusInst_t  XBUS;
		YBusInst_t  YBUS;
		D1BusInst_t D1BUS;
		bit         JPCW;		//Set PC in JUMP command
		DMAInst_t   DMA;
		CtlInst_t   CTL;
	} DecInst_t;
	
	parameter DecInst_t DECINST_RESET = '{1'b0,
	                                  {1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 4'b0000},
	                                  {1'b0, 2'b00, 2'b00, 1'b0, 1'b0, 4'b0000},
										       {1'b0, 2'b00, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0000, 4'b0000, 4'b0000},
										       1'b0,
												 {1'b0, 1'b0, 4'b0000, 1'b0, 4'b0000, 2'b00/*, 3'b000*/, 1'b0, 2'b00, 4'b0000/*, 1'b0*/},
												 {1'b0, 1'b0, 1'b0, 1'b0}};

	function DecInst_t Decode(input bit [31:0] IC, bit COND);
		DecInst_t di;
			
		di = DECINST_RESET;
		case (IC[31:28])
			4'b0000,4'b0001,4'b0010,4'b0011: begin
				di.ALU = |IC[29:26];
				
				di.XBUS.RAMR = IC[25] | &IC[24:23];
				di.XBUS.RAMS = IC[21:20];
				di.XBUS.MULS = ~IC[23];
				di.XBUS.RXW = IC[25];
				di.XBUS.PW = IC[24];
				case (IC[21:20])
					2'b00: di.XBUS.CTI[0] = |IC[25:23] & IC[22];
					2'b01: di.XBUS.CTI[1] = |IC[25:23] & IC[22];
					2'b10: di.XBUS.CTI[2] = |IC[25:23] & IC[22];
					2'b11: di.XBUS.CTI[3] = |IC[25:23] & IC[22];
				endcase
				
				di.YBUS.RAMR = IC[19];
				di.YBUS.RAMS = IC[15:14];
				di.YBUS.ACS = IC[18:17];
				di.YBUS.RYW = IC[19];
				di.YBUS.ACW = |IC[18:17];
				case (IC[15:14])
					2'b00: di.YBUS.CTI[0] = |IC[19:17] & IC[16];
					2'b01: di.YBUS.CTI[1] = |IC[19:17] & IC[16];
					2'b10: di.YBUS.CTI[2] = |IC[19:17] & IC[16];
					2'b11: di.YBUS.CTI[3] = |IC[19:17] & IC[16];
				endcase
				
				di.D1BUS.IMMS = ~IC[13] & IC[12];
				di.D1BUS.IMMT = 2'b00;
				di.D1BUS.ALUS = IC[13] & IC[12] & (IC[3:0] == 4'h9 | IC[3:0] == 4'hA);
				di.D1BUS.RAMR = IC[13] & IC[12] & ~IC[3];
				di.D1BUS.RAMS = IC[1:0];
				case (IC[11:8])
					4'b0000: di.D1BUS.RAMW[0] = IC[12];
					4'b0001: di.D1BUS.RAMW[1] = IC[12];
					4'b0010: di.D1BUS.RAMW[2] = IC[12];
					4'b0011: di.D1BUS.RAMW[3] = IC[12];
					4'b0100: di.D1BUS.RXW = IC[12];
					4'b0101: di.D1BUS.PW = IC[12];
					4'b0110: di.D1BUS.RA0W = IC[12];
					4'b0111: di.D1BUS.WA0W = IC[12];
					4'b1010: di.D1BUS.LOPW = IC[12];
					4'b1011: di.D1BUS.TOPW = IC[12];
					4'b1100: di.D1BUS.CTW[0] = IC[12];
					4'b1101: di.D1BUS.CTW[1] = IC[12];
					4'b1110: di.D1BUS.CTW[2] = IC[12];
					4'b1111: di.D1BUS.CTW[3] = IC[12];
					default:;
				endcase
				case (IC[1:0])
					2'b00: di.D1BUS.CTI[0] = &IC[13:12] & ~IC[3] & IC[2];
					2'b01: di.D1BUS.CTI[1] = &IC[13:12] & ~IC[3] & IC[2];
					2'b10: di.D1BUS.CTI[2] = &IC[13:12] & ~IC[3] & IC[2];
					2'b11: di.D1BUS.CTI[3] = &IC[13:12] & ~IC[3] & IC[2];
				endcase
				case (IC[9:8])
					2'b00: di.D1BUS.CTI[0] = |IC[13:12] & ~IC[11] & ~IC[10];
					2'b01: di.D1BUS.CTI[1] = |IC[13:12] & ~IC[11] & ~IC[10];
					2'b10: di.D1BUS.CTI[2] = |IC[13:12] & ~IC[11] & ~IC[10];
					2'b11: di.D1BUS.CTI[3] = |IC[13:12] & ~IC[11] & ~IC[10];
				endcase
			end
			
			4'b1000,4'b1001,4'b1010,4'b1011: begin
				di.D1BUS.IMMS = 1;
				di.D1BUS.IMMT = {1'b1,IC[25]};
				case (IC[29:26])
					4'b0000: di.D1BUS.RAMW[0] = ~IC[25] | COND;
					4'b0001: di.D1BUS.RAMW[1] = ~IC[25] | COND;
					4'b0010: di.D1BUS.RAMW[2] = ~IC[25] | COND;
					4'b0011: di.D1BUS.RAMW[3] = ~IC[25] | COND;
					4'b0100: di.D1BUS.RXW = ~IC[25] | COND;
					4'b0101: di.D1BUS.PW = ~IC[25] | COND;
					4'b0110: di.D1BUS.RA0W = ~IC[25] | COND;
					4'b0111: di.D1BUS.WA0W = ~IC[25] | COND;
					4'b1010: di.D1BUS.LOPW = ~IC[25] | COND;
					//4'b1011: di.D1BUS.TOPW = ~IC[25] | COND;
					4'b1100: di.D1BUS.PCW = ~IC[25] | COND;
					default:;
				endcase
				case (IC[27:26])
					2'b00: di.D1BUS.CTI[0] = ~IC[29] & ~IC[28] & (~IC[25] | COND);
					2'b01: di.D1BUS.CTI[1] = ~IC[29] & ~IC[28] & (~IC[25] | COND);
					2'b10: di.D1BUS.CTI[2] = ~IC[29] & ~IC[28] & (~IC[25] | COND);
					2'b11: di.D1BUS.CTI[3] = ~IC[29] & ~IC[28] & (~IC[25] | COND);
				endcase
			end
			
			4'b1100: begin
				di.DMA.ST = 1;
				di.DMA.DIR = IC[12];
				case (IC[10:8])
					3'b000: di.DMA.RAMW[0] = ~IC[12];
					3'b001: di.DMA.RAMW[1] = ~IC[12];
					3'b010: di.DMA.RAMW[2] = ~IC[12];
					3'b011: di.DMA.RAMW[3] = ~IC[12];
					3'b100: di.DMA.PRGW = ~IC[12];
					default:;
				endcase
				case (IC[10:8])
					3'b000: di.DMA.RAMR[0] = ~IC[10] & IC[12];
					3'b001: di.DMA.RAMR[1] = ~IC[10] & IC[12];
					3'b010: di.DMA.RAMR[2] = ~IC[10] & IC[12];
					3'b011: di.DMA.RAMR[3] = ~IC[10] & IC[12];
					default:;
				endcase
				di.DMA.RAMS = IC[9:8];
//				di.DMA.ADDI = IC[17:15];
				di.DMA.CNTM = IC[13];
				di.DMA.CNTS = IC[1:0];
				case (IC[1:0])
					2'b00: di.DMA.CTI[0] = IC[13] & IC[2];
					2'b01: di.DMA.CTI[1] = IC[13] & IC[2];
					2'b10: di.DMA.CTI[2] = IC[13] & IC[2];
					2'b11: di.DMA.CTI[3] = IC[13] & IC[2];
				endcase
//				di.DMA.HOLD = IC[14];
				di.D1BUS.DMAW = 1;
			end
			
			4'b1101: begin
				di.JPCW = ~IC[25] | COND;
			end
			
			4'b1110: begin
				di.CTL.BTM = ~IC[27];
				di.CTL.LPS = IC[27];
			end
			
			4'b1111: begin
				di.CTL.END = 1;
				di.CTL.EI = IC[27];
			end
			
			default: ;
		endcase
	
		return di;
	endfunction

	function bit [31:0] ImmSext(input bit [31:0] val, input bit [1:0] mode);
		bit [31:0] res;
		
		//0: 8->32, 2: 25->32, 3: 19->32
		res[7:0] = val[7:0];
		case (mode)
			2'b10:   res[18:8] = val[18:8];
			2'b11:   res[18:8] = val[18:8];
			default: res[18:8] = {11{val[7]}};
		endcase
		case (mode)
			2'b10:   res[24:19] = val[24:19];
			2'b11:   res[24:19] = {6{val[18]}};
			default: res[24:19] = {6{val[7]}};
		endcase
		case (mode)
			2'b10:   res[31:25] = {7{val[24]}};
			2'b11:   res[31:25] = {7{val[18]}};
			default: res[31:25] = {7{val[7]}};
		endcase
	
		return res;
	endfunction
	
	function bit [8:0] DMAAddrAdd(input bit [2:0] mode, input bit dir);
		bit [8:0] res;
		
		res = 9'd0;
//		if (!dir) begin
			case (mode)
				3'b000: res = 9'd0;
				3'b001: res = 9'd4;
				3'b010: res = 9'd8;
				3'b011: res = 9'd16;
				3'b100: res = 9'd32;
				3'b101: res = 9'd64;
				3'b110: res = 9'd128;
				3'b111: res = 9'd256;
			endcase
//		end else begin
//			case (mode)
//				3'b000: res = 7'd0;
//				3'b001: res = 7'd1;
//			endcase
//		end
		
		return res;
	endfunction
	
endpackage

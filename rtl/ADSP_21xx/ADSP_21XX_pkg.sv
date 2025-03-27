package ADSP_21XX_PKG;

	typedef enum bit[2:0] {
		NA_NOP = 3'b000,
		NA_PC = 3'b001,  
		NA_STACK = 3'b010,
		NA_INT = 3'b011,
		NA_IMM = 3'b100,
		NA_IMMF = 3'b101
	} Addr_t;

	typedef struct packed
	{
		Addr_t       NADDR;	//next instruction address 
		bit          IJMP;	//Indirect jump instruction
		bit          PCPUSH;	//write to PC stack
		bit          PCPOP;	//read from PC stack
		bit          STPUSH;	//write to STAT stack
		bit          STPOP;	//read from STAT stack
		bit          CNPOP;	//read from CNTR stack
		bit          LPPOP;	//read from LOOP stack
		bit          DOI;		//Do Until instruction
		bit          MFU;		//MF update
		bit  [ 2: 0] ALUX;	//ALU X source
		bit  [ 2: 0] ALUY;	//ALU Y source
		bit          ALUZ;	//ALU destination
		bit  [ 4: 0] ALUFC;	//ALU function code
		bit          AMI;		//ALU/MAC instruction
		bit          DIVQ;	//DIVQ instruction
		bit          DIVS;	//DIVS instruction
		bit          SHFTI;	//Shift instruction
		bit          SATMR;	//MR saturation instruction
		bit          MOVI;	//Move instruction
		bit          LDRI;	//Load data register instruction
		bit          LNDRI;	//Load non-data register instruction
		bit  [ 1: 0] SRGP;	//Source register group
		bit  [ 3: 0] SREG;	//Source register
		bit  [ 1: 0] DRGP;	//Destination register group
		bit  [ 3: 0] DREG;	//Destination register
		bit  [ 1: 0] DREG2;	//Destination 2nd register (for dual data read)
		bit          DMRI;	//Data mem read instruction
		bit          DMWI;	//Data mem write instruction
		bit          IDMRI;	//Indirect Data mem read instruction
		bit          IDMWI;	//Indirect Data mem write instruction
		bit          IPMRI;	//Indirect program mem read instruction
		bit          IPMWI;	//Indirect program mem write instruction
		bit          IMMDMWI;//Immediate data mem write instruction
		bit          IORI;	//IO read instruction
		bit          IOWI;	//IO write instruction
		bit          DAG1U;	//DAG1 I update
		bit          DAG2U;	//DAG1 I update
		bit  [ 1: 0] DAG1I;	//DAG1 I register number
		bit  [ 1: 0] DAG2I;	//DAG2 I register number
		bit  [ 1: 0] DAG1M;	//DAG1 M register number
		bit  [ 1: 0] DAG2M;	//DAG2 M register number
		bit          MODE;	//Mode control instruction
		bit          EINT;	//Enable/disable interrupts
		bit          MFO;		//Modify flag out instruction
		bit          IDLE;	//Idle instruction
		bit  [ 3: 0] CC;		//Condition code
		bit          ILI;		//Illegal instruction (for debug)
	} DecInstr_t;
	
	function DecInstr_t Decode(input [23:0] IR);
		DecInstr_t DECI;
		
		DECI = '0;//DECI_RESET;
		DECI.CC = 4'hF;
		casex (IR)
			24'b000000000000000000000000: begin	//NOP
				
			end
			
			24'b00000001_x_xxxxxxxxxxx_xxxx: begin	//IO read/write
				DECI.IORI = ~IR[15];
				DECI.IOWI = IR[15];
				DECI.SRGP = 2'b00;
				DECI.SREG = IR[3:0];
				DECI.DRGP = 2'b00;
				DECI.DREG = IR[3:0];
			end
			
			24'b000000100000_xx_xx_xx_xx_xxxx: begin	//Modify flag out
				DECI.MFO = 1;
				DECI.CC = IR[3:0];
			end
			
			24'b00000010100000000000_xxxx: begin	//Idle
				DECI.IDLE = 1;
			end
			
			24'b00000011_xxxxxxxxxxxxxx_x_x: begin	//Jump/Call direct on Flag In
				DECI.NADDR = NA_IMMF;
				DECI.PCPUSH = IR[0];
			end
			
			24'b00000100000000000_xxxxxxx: begin	//Stack control, ENA/DIS INTS
				DECI.STPUSH = IR[1]&~IR[0];
				DECI.STPOP = IR[1]&IR[0];
				DECI.CNPOP = IR[2];
				DECI.LPPOP = IR[3];
				DECI.PCPOP = IR[4];
				DECI.EINT = IR[6];
			end
			
			24'b000001010000000000000000: begin	//SAT MR
				DECI.SATMR = 1;
				DECI.CC = 4'hC;
			end
			
			24'b0000011_x_000_xx_xxx_00000000: begin	//DIVQ/DIVS
				DECI.DIVQ = IR[16];
				DECI.DIVS = ~IR[16];
				DECI.ALUZ = 1;
				DECI.ALUY = {1'b0,IR[12:11]};
				DECI.ALUX = IR[10:8];
			end
			
			24'b0000100100000000000_x_xx_xx: begin	//Modify address register
				DECI.DAG1I = IR[3:2];
				DECI.DAG2I = IR[3:2];
				DECI.DAG1M = IR[1:0];
				DECI.DAG2M = IR[1:0];
				DECI.DAG1U = ~IR[4];
				DECI.DAG2U = IR[4];
			end
			
			24'b00001010000000000000_xxxx: begin	//RTS
				DECI.NADDR = NA_STACK;
				DECI.PCPOP = 1;
				DECI.CC = IR[3:0];
			end
			
			24'b00001010000000000001_xxxx: begin	//RTI
				DECI.NADDR = NA_STACK;
				DECI.PCPOP = 1;
				DECI.STPOP = 1;
				DECI.CC = IR[3:0];
			end
			
			24'b0000101100000000_xx_00_xxxx: begin	//Jump indirect
				DECI.IJMP = 1;
				DECI.CC = IR[3:0];
			end
			
			24'b0000101100000000_xx_01_xxxx: begin	//Call indirect
				DECI.IJMP = 1;
				DECI.PCPUSH = 1;
				DECI.CC = IR[3:0];
			end
			
			24'b00001100_xx_xx_xx_xx_xx_xx_xx_00: begin	//Mode control
				DECI.MODE = 1;
			end
			
			24'b000011010000_xx_xx_xxxx_xxxx: begin	//Move, TOPCPSTACK
				DECI.MOVI = 1;
				DECI.SRGP = IR[9:8];
				DECI.SREG = IR[3:0];
				DECI.DRGP = IR[11:10];
				DECI.DREG = IR[7:4];
				
				DECI.PCPUSH = &{IR[11:10],IR[7:4]};
				DECI.PCPOP = &{IR[9:8],IR[3:0]};
			end
			
			24'b000011100_xxxx_xxx_0000_xxxx: begin	//Shift
				DECI.SHFTI = 1;
				DECI.ALUX = IR[10:8];
				DECI.CC = IR[3:0];
			end
			
			24'b000011110_xxxx_xxx_xxxxxxxx: begin	//Shift imm
				DECI.SHFTI = 1;
				DECI.ALUX = IR[10:8];
			end
			
			24'b000100000_xxxx_xxx_xxxx_xxxx: begin	//Move, Shift
				DECI.SHFTI = 1;
				DECI.ALUX = IR[10:8];
				DECI.MOVI = 1;
				DECI.SRGP = 2'b00;
				DECI.SREG = IR[3:0];
				DECI.DRGP = 2'b00;
				DECI.DREG = IR[7:4];
			end
			
			24'b000100010_xxxx_xxx_xxxx_xx_xx: begin	//Indirect prog mem read, Shift
				DECI.SHFTI = 1;
				DECI.ALUX = IR[10:8];
				DECI.IPMRI = 1;
				DECI.DRGP = 2'b00;
				DECI.DREG = IR[7:4];
				DECI.DAG2I = IR[3:2];
				DECI.DAG2M = IR[1:0];
				DECI.DAG2U = 1;
			end
			
			24'b000100011_xxxx_xxx_xxxx_xx_xx: begin	//Indirect prog mem write, Shift
				DECI.SHFTI = 1;
				DECI.ALUX = IR[10:8];
				DECI.IPMWI = 1;
				DECI.SRGP = 2'b00;
				DECI.SREG = IR[7:4];
				DECI.DAG2I = IR[3:2];
				DECI.DAG2M = IR[1:0];
				DECI.DAG2U = 1;
			end
			
			24'b0001001_x_0_xxxx_xxx_xxxx_xx_xx: begin	//Indirect data mem read, Shift
				DECI.SHFTI = 1;
				DECI.ALUX = IR[10:8];
				DECI.IDMRI = 1;
				DECI.DRGP = 2'b00;
				DECI.DREG = IR[7:4];
				DECI.DAG1I = IR[3:2];
				DECI.DAG2I = IR[3:2];
				DECI.DAG1M = IR[1:0];
				DECI.DAG2M = IR[1:0];
				DECI.DAG1U = ~IR[16];
				DECI.DAG2U = IR[16];
			end
			
			24'b0001001_x_1_xxxx_xxx_xxxx_xx_xx: begin	//Indirect data mem write, Shift
				DECI.SHFTI = 1;
				DECI.ALUX = IR[10:8];
				DECI.IDMWI = 1;
				DECI.SRGP = 2'b00;
				DECI.SREG = IR[7:4];
				DECI.DAG1I = IR[3:2];
				DECI.DAG2I = IR[3:2];
				DECI.DAG1M = IR[1:0];
				DECI.DAG2M = IR[1:0];
				DECI.DAG1U = ~IR[16];
				DECI.DAG2U = IR[16];
			end
			
			24'b000101_xxxxxxxxxxxxxx_xxxx: begin	//Do Until
				DECI.DOI = 1;
				DECI.PCPUSH = 1;
			end
			
			24'b000110_xxxxxxxxxxxxxx_xxxx: begin	//Jump direct
				DECI.NADDR = NA_IMM;
				DECI.CC = IR[3:0];
			end
			
			24'b000111_xxxxxxxxxxxxxx_xxxx: begin	//Call direct
				DECI.NADDR = NA_IMM;
				DECI.PCPUSH = 1;
				DECI.CC = IR[3:0];
			end
			
			24'b00100_x_xxxxx_xx_xxx_xxxx_xxxx: begin	//ALU/MAC
				DECI.AMI = 1;
				DECI.ALUZ = IR[18];
				DECI.ALUFC = IR[17:13];
				DECI.ALUY = IR[4] ? 3'b100 : {1'b0,IR[12:11]};
				DECI.ALUX = IR[10:8];
				DECI.CC = IR[3:0];
			end
			
			24'b00101_x_xxxxx_xx_xxx_xxxx_xxxx: begin	//Move, ALU/MAC
				DECI.AMI = 1;
				DECI.ALUZ = IR[18];
				DECI.ALUFC = IR[17:13];
				DECI.ALUY = {1'b0,IR[12:11]};
				DECI.ALUX = IR[10:8];
				DECI.MOVI = 1;
				DECI.SRGP = 2'b00;
				DECI.SREG = IR[3:0];
				DECI.DRGP = 2'b00;
				DECI.DREG = IR[7:4];
			end
			
			24'b0011_xx_xxxxxxxxxxxxxx_xxxx: begin	//Load non-data reg
				DECI.LDRI = 1;
				DECI.DRGP = IR[19:18];
				DECI.DREG = IR[3:0];
			end
			
			24'b0100_xxxxxxxxxxxxxxxx_xxxx: begin	//Load data reg
				DECI.LDRI = 1;
				DECI.DRGP = 2'b00;
				DECI.DREG = IR[3:0];
			end
			
			24'b01010_x_xxxxx_xx_xxx_xxxx_xx_xx: begin	//Indirect prog mem read, ALU/MAC
				DECI.AMI = 1;
				DECI.ALUZ = IR[18];
				DECI.ALUFC = IR[17:13];
				DECI.ALUY = {1'b0,IR[12:11]};
				DECI.ALUX = IR[10:8];
				DECI.IPMRI = 1;
				DECI.DRGP = 2'b00;
				DECI.DREG = IR[7:4];
				DECI.DAG2I = IR[3:2];
				DECI.DAG2M = IR[1:0];
				DECI.DAG2U = 1;
			end
			
			24'b01011_x_xxxxx_xx_xxx_xxxx_xx_xx: begin	//Indirect prog mem write, ALU/MAC
				DECI.AMI = 1;
				DECI.ALUZ = IR[18];
				DECI.ALUFC = IR[17:13];
				DECI.ALUY = {1'b0,IR[12:11]};
				DECI.ALUX = IR[10:8];
				DECI.IPMWI = 1;
				DECI.SRGP = 2'b00;
				DECI.SREG = IR[7:4];
				DECI.DAG2I = IR[3:2];
				DECI.DAG2M = IR[1:0];
				DECI.DAG2U = 1;
			end
			
			24'b011x0_x_xxxxx_xx_xxx_xxxx_xx_xx: begin	//Indirect data mem read, ALU/MAC
				DECI.AMI = 1;
				DECI.ALUZ = IR[18];
				DECI.ALUFC = IR[17:13];
				DECI.ALUY = {1'b0,IR[12:11]};
				DECI.ALUX = IR[10:8];
				DECI.IDMRI = 1;
				DECI.DRGP = 2'b00;
				DECI.DREG = IR[7:4];
				DECI.DAG1I = IR[3:2];
				DECI.DAG2I = IR[3:2];
				DECI.DAG1M = IR[1:0];
				DECI.DAG2M = IR[1:0];
				DECI.DAG1U = ~IR[20];
				DECI.DAG2U = IR[20];
			end
			
			24'b011x1_x_xxxxx_xx_xxx_xxxx_xx_xx: begin	//Indirect data mem write, ALU/MAC
				DECI.AMI = 1;
				DECI.ALUZ = IR[18];
				DECI.ALUFC = IR[17:13];
				DECI.ALUY = {1'b0,IR[12:11]};
				DECI.ALUX = IR[10:8];
				DECI.IDMWI = 1;
				DECI.SRGP = 2'b00;
				DECI.SREG = IR[7:4];
				DECI.DAG1I = IR[3:2];
				DECI.DAG2I = IR[3:2];
				DECI.DAG1M = IR[1:0];
				DECI.DAG2M = IR[1:0];
				DECI.DAG1U = ~IR[20];
				DECI.DAG2U = IR[20];
			end
			
			24'b1000_xx_xxxxxxxxxxxxxx_xxxx: begin	//Data mem read
				DECI.DMRI = 1;
				DECI.DRGP = IR[19:18];
				DECI.DREG = IR[3:0];
			end
			
			24'b1001_xx_xxxxxxxxxxxxxx_xxxx: begin	//Data mem write
				DECI.DMWI = 1;
				DECI.SRGP = IR[19:18];
				DECI.SREG = IR[3:0];
			end
			
			24'b101x_xxxxxxxxxxxxxxxx_xx_xx: begin	//Imm data mem write
				DECI.IMMDMWI = 1;
				DECI.DAG1I = IR[3:2];
				DECI.DAG2I = IR[3:2];
				DECI.DAG1M = IR[1:0];
				DECI.DAG2M = IR[1:0];
				DECI.DAG1U = ~IR[20];
				DECI.DAG2U = IR[20];
			end
			
			24'b11_xx_xx_xxxxx_xx_xxx_xx_xx_xx_xx: begin	//Indirect data and prog mem read, ALU/MAC
				DECI.AMI = 1;
				DECI.ALUZ = 1'b0;
				DECI.ALUFC = IR[17:13];
				DECI.ALUY = {1'b0,IR[12:11]};
				DECI.ALUX = IR[10:8];
				DECI.IDMRI = 1;
				DECI.IPMRI = 1;
				DECI.DRGP = 2'b00;
				DECI.DREG = {2'b00,IR[19:18]};
				DECI.DREG2 = IR[21:20];
				DECI.DAG1I = IR[3:2];
				DECI.DAG2I = IR[7:6];
				DECI.DAG1M = IR[1:0];
				DECI.DAG2M = IR[5:4];
				DECI.DAG1U = 1;
				DECI.DAG2U = 1;
			end

			default: DECI.ILI = 1;
		endcase
		
		return DECI;
	endfunction


	//ALU
	function bit [15:0] Constant(input bit [1:0] yy, input bit [1:0] cc, input bit [1:0] bo);
		bit [15:0] temp;
		
		case ({yy,cc})
			4'b0000: temp = 16'h0001;
			4'b0001: temp = 16'h0002;
			4'b0010: temp = 16'h0004;
			4'b0011: temp = 16'h0008;
			4'b0100: temp = 16'h0010;
			4'b0101: temp = 16'h0020;
			4'b0110: temp = 16'h0040;
			4'b0111: temp = 16'h0080;
			4'b1000: temp = 16'h0100;
			4'b1001: temp = 16'h0200;
			4'b1010: temp = 16'h0400;
			4'b1011: temp = 16'h0800;
			4'b1100: temp = 16'h1000;
			4'b1101: temp = 16'h2000;
			4'b1110: temp = 16'h4000;
			4'b1111: temp = 16'h8000;
		endcase
		
		return (temp ^ {16{bo[1]}});
	endfunction
	
	function bit [31:0] Shifter(input bit [15:0] i, input bit [7:0] x, input bit ar, input bit r);
		bit [31:0] res;
		bit [63:0] temp,temp2,temp3;
		bit        ci2;
		bit        co;
	
		temp = {{48{i[15]&ar}},i};
		temp2 = temp << {~r,4'h0};
		
		if (!x[7]) begin
			temp3 = temp2 << (+x[6:0]);
		end else 
			temp3 = temp2 >> (-x[6:0]);
		
		return temp3[31:0];
	endfunction
	
	function bit [13:0] Modulus(input bit [13:0] i, input bit [13:0] m, input bit [13:0] l);
		bit [13:0] sum;
		bit [13:0] mask;
		bit [13:0] base;
		
		sum = i + m;
		
		mask = 14'b00000000000000; 
		if (!l[13:13]) mask = 14'b10000000000000; 
		if (!l[13:12]) mask = 14'b11000000000000; 
		if (!l[13:11]) mask = 14'b11100000000000; 
		if (!l[13:10]) mask = 14'b11110000000000; 
		if (!l[13: 9]) mask = 14'b11111000000000; 
		if (!l[13: 8]) mask = 14'b11111100000000; 
		if (!l[13: 7]) mask = 14'b11111110000000; 
		if (!l[13: 6]) mask = 14'b11111111000000; 
		if (!l[13: 5]) mask = 14'b11111111100000; 
		if (!l[13: 4]) mask = 14'b11111111110000; 
		if (!l[13: 3]) mask = 14'b11111111111000; 
		if (!l[13: 2]) mask = 14'b11111111111100; 
		if (!l[13: 1]) mask = 14'b11111111111110; 
		if (!l[13: 0]) mask = 14'b11111111111111;
		base = i & mask;
		
		return (sum < base ? sum + l : sum >= base + l ? sum - l : sum);
	endfunction
	
	function bit [13:0] AddrReverse(input bit [13:0] a);
		return {a[0],a[1],a[2],a[3],a[4],a[5],a[6],a[7],a[8],a[9],a[10],a[11],a[12],a[13]};
	endfunction
	
	
	
	localparam ASTAT_AZ 	= 0;
	localparam ASTAT_AN 	= 1;
	localparam ASTAT_AV 	= 2;
	localparam ASTAT_AC 	= 3;
	localparam ASTAT_AS 	= 4;
	localparam ASTAT_AQ 	= 5;
	localparam ASTAT_MV 	= 6;
	localparam ASTAT_SS 	= 7;
	
	localparam MSTAT_SEC_REG 	= 0;
	localparam MSTAT_BIT_REV 	= 1;
	localparam MSTAT_AV_LATCH 	= 2;
	localparam MSTAT_AR_SAT 	= 3;
	localparam MSTAT_M_MODE 	= 4;
	localparam MSTAT_TIMER 	   = 5;
	localparam MSTAT_G_MODE 	= 6;
	
	localparam IMASK_TMR 	= 0;
	localparam IMASK_SP1R 	= 1;
	localparam IMASK_SP1T 	= 2;
	localparam IMASK_BDMA 	= 3;
	localparam IMASK_IRQE 	= 4;
	localparam IMASK_SP0R 	= 5;
	localparam IMASK_SP0T 	= 6;
	localparam IMASK_IRQL0 	= 7;
	localparam IMASK_IRQL1 	= 8;
	localparam IMASK_IRQ2 	= 9;
	
endpackage

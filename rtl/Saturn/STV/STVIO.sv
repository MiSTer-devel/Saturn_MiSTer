module STVIO (
	input              CLK,
	input              RST_N,
	input              CE_R,
	input              CE_F,
	
	input              RES_N,
	
	input      [ 6: 1] A,
	input      [ 7: 0] DI,
	output     [ 7: 0] DO,
	input              CS_N,
	input              RW_N,
	
	input      [13: 0] JOY1,
	input      [13: 0] JOY2,
	
	input      [ 7: 0] MODE
);
	
	bit  [ 3: 0] J1UDLR,J2UDLR;
	bit          J1B1,J1B2,J1B3,J1B4,J1B5,J1B6,J2B1,J2B2,J2B3,J2B4,J2B5,J2B6;
	bit          J1START,J2START,J1COIN,J2COIN,J1SERVICE,J2SERVICE,J1TEST,J2TEST;
	assign {J1TEST,J1SERVICE,J1COIN,J1START,J1B6,J1B5,J1B4,J1B3,J1B2,J1B1,J1UDLR} = JOY1;
	assign {J2TEST,J2SERVICE,J2COIN,J2START,J2B6,J2B5,J2B4,J2B3,J2B2,J2B1,J2UDLR} = JOY2;
	
	bit  [ 7: 0] IN[8];
	bit  [ 7: 0] OUT[8];
	bit  [ 7: 0] DIR;
	always_comb begin
		// 0x0001 PORT-A (P1)      JAMMA (56P)
		// 0x0003 PORT-B (P2)      JAMMA (56P)
		// 0x0005 PORT-C (SYSTEM)  JAMMA (56P)
		// 0x0007 PORT-D (OUTPUT)  JAMMA (56P) + CN25 (JST NH 5P) RESERVED OUTPUT 4bit. (?)
		// 0x0009 PORT-E (P3)      CN32 (JST NH 9P) EXTENSION I/O 8bit.
		// 0x000b PORT-F (P4 / Extra 6B layout)    CN21 (JST NH 11P) EXTENSION I/O 8bit.
		// 0x000d PORT-G           CN20 (JST HN 10P) EXTENSION INPUT 8bit. (?)
		// 0x000f unused
		// 0x0011 PORT_DIR
		//
		// (each bit of PORT_DIR configures the DIRection of each 8-bit IO port. 1=input, 0=output.)
		//
		//  eg. PORT_DIR[0]=1=PORTA pins are all INPUTs.
		//  eg. PORT_DIR[1]=1=PORTB pins are all INPUTs.
		//  eg. PORT_DIR[2]=1=PORTC pins are all INPUTs.
		//  eg. PORT_DIR[3]=0=PORTD pins are all OUTPUTs.


		// PORTs A, B, E, F. (Player 1, 2, 3, 4)...
		// 
		// b7 = Left
		// b6 = Right
		// b5 = Up
		// b4 = Down
		// b3 = Button 4 (P3/P4 use this for Start)
		// b2 = Button 3
		// b1 = Button 2
		// b0 = Button 1
		//	
		IN[0][7:4] = {J1UDLR[1],J1UDLR[0],J1UDLR[3],J1UDLR[2]};
		IN[1][7:4] = {J2UDLR[1],J2UDLR[0],J2UDLR[3],J2UDLR[2]};
		if (MODE[3:0] == 4'h3) begin	//batmanfr
			IN[0][3:0] = {J1B3,J1B2,J1B1,1'b1};
			IN[1][3:0] = {J2B3,J2B2,J2B1,1'b1};
		end else begin
			IN[0][3:0] = {1'b1,J1B3,J1B2,J1B1};
			IN[1][3:0] = {1'b1,J2B3,J2B2,J2B1};
		end
	
		// PORTC (System) inputs...
		// 
		// b7 = Pause (if the game supports it)
		// b6 = Multi-Cart Select.
		// b5 = Start 2 ?
		// b4 = Start 1 ?
		// b3 = Service 1.
		// b2 = Test ?
		// b1 = Coin 2
		// b0 = Coin 1
		//
		// Button inputs to core are Active-LOW !
		// 
		IN[2] = {1'b1,1'b1,J2START,J1START,J1SERVICE,J1TEST,J2COIN,J1COIN};
		IN[3] = 8'h00;
		IN[4] = 8'hFF;
		IN[5] = {1'b1,J2B6,J2B5,J2B4,1'b1,J1B6,J1B5,J1B4};
		IN[6] = 8'hFF;
		IN[7] = 8'hFF;
	end
	
	bit  [ 7: 0] REG_DO;
	always @(posedge CLK or negedge RST_N) begin
		bit        RW_N_OLD;
		bit        CS_N_OLD;
		
		if (!RST_N) begin
			OUT <= '{8{'1}};
			DIR <= '1;
		end
		else if (!RES_N) begin
			
		end else begin
			RW_N_OLD <= RW_N;
			if (!RW_N && RW_N_OLD && !CS_N) begin
				case ({A,1'b1})
					7'h01: OUT[0] <= DI;
					7'h03: OUT[1] <= DI;
					7'h05: OUT[2] <= DI;
					7'h07: OUT[3] <= DI;
					7'h09: OUT[4] <= DI;
					7'h0B: OUT[5] <= DI;
					7'h0D: OUT[6] <= DI;
					7'h0F: OUT[7] <= DI;
					7'h11: DIR <= DI;
					default:;
				endcase
			end 
			
			CS_N_OLD <= CS_N;
			if (!CS_N && CS_N_OLD && RW_N) begin
				case ({A,1'b1})
					7'h01: REG_DO <= IN[0] & (OUT[0]|{8{DIR[0]}});
					7'h03: REG_DO <= IN[1] & (OUT[1]|{8{DIR[1]}});
					7'h05: REG_DO <= IN[2] & (OUT[2]|{8{DIR[2]}});
					7'h07: REG_DO <= IN[3] & (OUT[3]|{8{DIR[3]}});
					7'h09: REG_DO <= IN[4] & (OUT[4]|{8{DIR[4]}});
					7'h0B: REG_DO <= IN[5] & (OUT[5]|{8{DIR[5]}});
					7'h0D: REG_DO <= IN[6] & (OUT[6]|{8{DIR[6]}});
					7'h0F: REG_DO <= IN[7] & (OUT[7]|{8{DIR[7]}});
					7'h11: REG_DO <= DIR;
					
					7'h17: REG_DO <= '0;
					7'h19: REG_DO <= '0;
					default: REG_DO <= '1;
				endcase
			end
		end
	end
	assign DO = REG_DO;
	
endmodule

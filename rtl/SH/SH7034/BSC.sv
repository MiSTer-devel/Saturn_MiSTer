module SH7034_BSC 
#(parameter bit AREA3=0, bit [1:0] W3=0, bit [1:0] IW3=0, bit [1:0] LW3=0)
(
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	
	input             RES_N,
	
	output     [23:0] A,
	input      [15:0] DI,
	output reg [15:0] DO,
	output reg  [7:0] CS_N,
	output reg        WRL_N,
	output reg        WRH_N,
	output reg        RD_N,
	input             WAIT_N,
	input             BREQ_N,
	output            BACK_N,
	input       [2:0] MD,
	
	input      [27:0] IBUS_A,
	input      [31:0] IBUS_DI,
	output     [31:0] IBUS_DO,
	input       [3:0] IBUS_BA,
	input             IBUS_WE,
	input             IBUS_REQ,
	output            IBUS_BUSY,
	input             IBUS_LOCK,
	output            IBUS_ACT,
	
	output            IRQ,
	
	output reg        CACK,
	output reg        BUS_RLS
);

	import SH7034_PKG::*;

	BCR_t       BCR;
	WCR1_t      WCR1;
	WCR2_t      WCR2;
	WCR3_t      WCR3;
	DCR_t       DCR;
	PCR_t       PCR;
	RCR_t       RCR;
	RTCSR_t     RTCSR;
	RTCNT_t     RTCNT;
	RTCOR_t     RTCOR;
	
	function bit [1:0] GetAreaW(input bit [2:0] area, input WCR1_t wcr1);
		bit [1:0] res;
	
		case (area)
			3'd0: res = {1'b1,wcr1.RW0};
			3'd1: res = {1'b0,wcr1.RW1};
			3'd2: res = {1'b1,wcr1.RW2};
			3'd3: res = {1'b0,wcr1.RW3};
			3'd4: res = {1'b0,wcr1.RW4};
			3'd5: res = {1'b0,wcr1.RW5};
			3'd6: res = {1'b1,wcr1.RW6};
			3'd7: res = {1'b0,wcr1.RW7};
		endcase
		return res;
	endfunction
	
	function bit [1:0] GetAreaLW(input bit [2:0] area, input WCR3_t wcr3);
		bit [1:0] res;
	
		case (area)
			3'd0: res = wcr3.A02LW;
			3'd1: res = '0;
			3'd2: res = wcr3.A02LW;
			3'd3: res = '0;
			3'd4: res = '0;
			3'd5: res = '0;
			3'd6: res = wcr3.A6LW;
			3'd7: res = '0;
		endcase
		return res;
	endfunction
	
	function bit  GetAreaSZ(input bit [27:0] addr, input BCR_t bcr, input bit a0sz);
		bit [1:0] res;
	
		case (addr[26:24])
			3'd0: res = a0sz;
			3'd1: res = addr[27];
			3'd2: res = addr[27];
			3'd3: res = addr[27];
			3'd4: res = addr[27];
			3'd5: res = addr[27];
			3'd6: res = addr[27];
			3'd7: res = addr[27];
		endcase
		return res;
	endfunction
	
	bit         BACK;
	
	wire        A0_SZ = MD[0];
	
	typedef enum bit[2:0] {
		T0 = 3'b000,  
		T1 = 3'b001,
		T2 = 3'b010,
		TW = 3'b011
	} BusState_t;
	BusState_t BUS_STATE;
	
	wire DBUS_REQ = (IBUS_A[26:24] != 3'b000 | ~MD[1]) & IBUS_A[27:24] != 4'b1111 & IBUS_A[27:24] != 4'b0101 & IBUS_REQ; 
	wire BUS_ACCESS_REQ = DBUS_REQ; 
	
	bit         BUSY;
	bit  [27:0] ADDR;
	bit  [31:0] DAT_BUF;
	bit   [3:0] NEXT_BA;
	always @(posedge CLK or negedge RST_N) begin
		BusState_t STATE_NEXT;
		bit        STATE_T2_END;
		bit  [2:0] WAIT_CNT;
		bit [31:0] IBUS_DI_SAVE;
		bit        IBUS_WE_SAVE;
		bit        AREA_SZ;
		
		if (!RST_N) begin
			BUSY <= 0;
			ADDR <= '0;
			DO <= '0;
			CS_N <= '1;
			RD_N <= 1;
			WRL_N <= 1;
			WRH_N <= 1;
			CACK <= 0;
			BUS_STATE <= T0;
			WAIT_CNT <= '0;
			NEXT_BA <= '0;
		end
		else begin
			AREA_SZ = GetAreaSZ(ADDR,BCR,A0_SZ);
			STATE_NEXT = BUS_STATE;
			case (BUS_STATE)
				T0:;
				
				T1: if (CE_R) begin
					case (GetAreaW(ADDR[26:24],WCR1))
						2'b00: begin
//							STATE_NEXT = T2;
						end
						2'b01: begin
							WAIT_CNT <= 3'd0;
//							STATE_NEXT = !WAIT_N ? TW : T2;
						end
						2'b10,2'b11: begin
							case (GetAreaLW(ADDR[26:24],WCR3))
								2'b00: begin WAIT_CNT <= 3'd1 - 3'd1; /*STATE_NEXT = !WAIT_N ? TW : T2;*/ end
								2'b01: begin WAIT_CNT <= 3'd2 - 3'd1; /*STATE_NEXT = TW;*/ end
								2'b10: begin WAIT_CNT <= 3'd3 - 3'd1; /*STATE_NEXT = TW;*/ end
								2'b11: begin WAIT_CNT <= 3'd4 - 3'd1; /*STATE_NEXT = TW;*/ end
							endcase
						end
					endcase
					STATE_T2_END <= 0;
					STATE_NEXT = T2;
				end
				
//				TW: if (CE_R) begin
//					if (WAIT_N) begin
//						if (WAIT_CNT) begin
//							WAIT_CNT <= WAIT_CNT - 3'd1;
//						end
//						else begin
//							STATE_NEXT = T2;
//						end
//					end
//				end
				
				T2: if (CE_F) begin
					if (WAIT_N) begin
						if (WAIT_CNT) begin
							WAIT_CNT <= WAIT_CNT - 3'd1;
						end
						else begin
							case (AREA_SZ)
								1'b0: 
									case (A[1:0])
										2'b00: DAT_BUF[31:24] <= DI[7:0];
										2'b01: DAT_BUF[23:16] <= DI[7:0];
										2'b10: DAT_BUF[15: 8] <= DI[7:0];
										2'b11: DAT_BUF[ 7: 0] <= DI[7:0];
									endcase
								1'b1: 
									case (A[1])
										1'b0: DAT_BUF[31:16] <= DI[15:0];
										1'b1: DAT_BUF[15: 0] <= DI[15:0];
									endcase
								default:;
							endcase
							if (!NEXT_BA) begin
								BUSY <= 0;
							end
							WRL_N <= 1;
							WRH_N <= 1;
							RD_N <= 1;
							CACK <= 0;
							
							STATE_T2_END <= 1;
						end
					end
				end else if (CE_R) begin
					if (STATE_T2_END) begin
						if (!NEXT_BA) begin
							CS_N <= '1;
						end
						STATE_NEXT = T0;
					end
				end
				
				default:;
			endcase
			
			begin
				if (BUS_STATE == T0 || BUS_STATE == T2) begin
					if (BUS_ACCESS_REQ && !BUS_RLS && !BUSY && CE_F) begin
						BUSY <= 1;
					end
					if (STATE_T2_END && BUSY && CE_R) begin
						case (AREA_SZ)
							/*1'b0: begin 
								ADDR[1:0] <= ADDR[1:0] + 2'd1; 
								case (ADDR[1:0] + 2'd1)
									2'b01: begin 
										DO <= {8'h00,IBUS_DI_SAVE[23:16]};
										WRL_N <= ~(IBUS_WE_SAVE & NEXT_BA[2]);
										WRH_N <= 1;
										NEXT_BA <= {2'b00,NEXT_BA[1:0]};
									end
									2'b10: begin 
										DO <= {8'h00,IBUS_DI_SAVE[15: 8]}; 
										WRL_N <= ~(IBUS_WE_SAVE & NEXT_BA[1]);
										WRH_N <= 1;
										NEXT_BA <= {3'b000,NEXT_BA[0]};
									end
									2'b11: begin 
										DO <= {8'h00,IBUS_DI_SAVE[ 7: 0]};
										WRL_N <= ~(IBUS_WE_SAVE & NEXT_BA[0]); 
										WRH_N <= 1;
										NEXT_BA <= 4'b0000;
									end
									default: begin //shouldn't happen
										WRL_N <= 1;
										WRH_N <= 1;
										NEXT_BA <= 4'b0000;
									end
								endcase
							end*/
							1'b1: begin 
								ADDR[1:0] <= ADDR[1:0] + 2'd2; 
								DO <= IBUS_DI_SAVE[15: 0];
								WRL_N <= ~(IBUS_WE_SAVE & NEXT_BA[0]); 
								WRH_N <= ~(IBUS_WE_SAVE & NEXT_BA[1]);
								NEXT_BA <= 4'b0000;
							end
							default: ;
						endcase
						RD_N <= IBUS_WE_SAVE;
						CACK <= 1;
						STATE_NEXT = T1;
					end
					else if (BUS_ACCESS_REQ && !BUS_RLS && !BACK && !BUSY && CE_F) begin
						BUSY <= 1;
						
						case (GetAreaSZ(IBUS_A,BCR,A0_SZ))
							/*1'b0: begin 
								case (IBUS_A[1:0])
									2'b00: begin 
										DO <= {8'h00,IBUS_DI[31:24]}; 
										WRL_N <= ~(IBUS_WE & IBUS_BA[3]);
										WRH_N <= 1;
										NEXT_BA <= {1'b0,IBUS_BA[2:0]};
									end
									2'b01: begin 
										DO <= {8'h00,IBUS_DI[23:16]};
										WRL_N <= ~(IBUS_WE & IBUS_BA[2]);
										WRH_N <= 1;
										NEXT_BA <= {2'b00,IBUS_BA[1:0]};
									end
									2'b10: begin 
										DO <= {8'h00,IBUS_DI[15: 8]}; 
										WRL_N <= ~(IBUS_WE & IBUS_BA[1]);
										WRH_N <= 1;
										NEXT_BA <= {3'b000,IBUS_BA[0]};
									end
									2'b11: begin 
										DO <= {8'h00,IBUS_DI[ 7: 0]};
										WRL_N <= ~(IBUS_WE & IBUS_BA[0]);
										WRH_N <= 1;
										NEXT_BA <= 4'b0000;
									end
								endcase
							end*/
							1'b1: begin 
								case (IBUS_A[1])
									1'b0: begin 
										DO <= IBUS_DI[31:16]; 
										WRL_N <= ~(IBUS_WE & IBUS_BA[2]);
										WRH_N <= ~(IBUS_WE & IBUS_BA[3]);
										NEXT_BA <= {2'b00,IBUS_BA[1:0]};
									end
									1'b1: begin 
										DO <= IBUS_DI[15: 0]; 
										WRL_N <= ~(IBUS_WE & IBUS_BA[0]);
										WRH_N <= ~(IBUS_WE & IBUS_BA[1]);
										NEXT_BA <= 4'b0000;
									end
								endcase
							end
							default:; 
						endcase
						ADDR <= IBUS_A;
						CS_N[0] <= ~(IBUS_A[26:24] == 3'b000);
						CS_N[1] <= ~(IBUS_A[26:24] == 3'b001);
						CS_N[2] <= ~(IBUS_A[26:24] == 3'b010);
						CS_N[3] <= ~(IBUS_A[26:24] == 3'b011);
						CS_N[4] <= ~(IBUS_A[26:24] == 3'b000);
						CS_N[5] <= ~(IBUS_A[26:24] == 3'b101);
						CS_N[6] <= ~(IBUS_A[26:24] == 3'b110);
						CS_N[7] <= ~(IBUS_A[26:24] == 3'b111);
						RD_N <= IBUS_WE;
						CACK <= 1;
						
						IBUS_WE_SAVE <= IBUS_WE;
						IBUS_DI_SAVE <= IBUS_DI; 
						
						if (BUS_STATE == T0 /*|| BUS_STATE == T2*/) begin
							STATE_NEXT = T1;
						end
					end
				end
			end
			BUS_STATE <= STATE_NEXT;
		end
	end
	assign A = ADDR[23:0];

	
	wire        BREQ = ~BREQ_N;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			BACK <= 0;
			BUS_RLS <= 0;
		end else if (!RES_N) begin
			BACK <= 0;
			BUS_RLS <= 0;
		end else if (CE_F) begin
			if (BREQ && !BACK  && (BUS_STATE == T2 || BUS_STATE == T0) && !BUSY && !IBUS_LOCK && !BUS_RLS) begin
				BACK <= 1;
			end
			else if (BREQ && BACK && !BUS_RLS) begin
				BUS_RLS <= 1;
			end
			else if (!BREQ && BUS_RLS) begin
				BACK <= 0;
				BUS_RLS <= 0;
			end
		end
	end
	
	assign BACK_N = ~BACK;
	
		
	//Registers
	wire REG_SEL = (IBUS_A >= 28'h5FFFFA0 & IBUS_A <= 28'h5FFFFB3);
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			BCR   <= BCR_INIT;
			WCR1  <= WCR1_INIT;
			WCR2  <= WCR2_INIT;
			WCR3  <= WCR3_INIT;
			DCR   <= DCR_INIT;
			PCR   <= PCR_INIT;
			RCR   <= RCR_INIT;
			RTCSR <= RTCSR_INIT;
			RTCNT <= RTCNT_INIT;
			RTCOR <= RTCOR_INIT;
			// synopsys translate_off
			
			// synopsys translate_on
		end
		else if (CE_R) begin
			if (REG_SEL /*&& IBUS_DI[31:16] == 16'hA55A*/ && IBUS_WE && IBUS_REQ) begin
				case ({IBUS_A[4:2],2'b00})
					5'h00: begin
						if (IBUS_BA[3]) BCR[15:8]  <= IBUS_DI[31:24] & BCR_WMASK[15:8];
						if (IBUS_BA[2]) BCR[ 7:0]  <= IBUS_DI[23:16] & BCR_WMASK[7:0];
						if (IBUS_BA[1]) WCR1[15:8] <= IBUS_DI[15: 8] & WCR1_WMASK[15:8];
						if (IBUS_BA[0]) WCR1[ 7:0] <= IBUS_DI[ 7: 0] & WCR1_WMASK[7:0];
					end 
					5'h04: begin
						if (IBUS_BA[3]) WCR2[15:8] <= IBUS_DI[31:24] & WCR2_WMASK[15:8];
						if (IBUS_BA[2]) WCR2[ 7:0] <= IBUS_DI[23:16] & WCR2_WMASK[7:0];
						if (IBUS_BA[1]) WCR3[15:8] <= IBUS_DI[15: 8] & WCR3_WMASK[15:8];
						if (IBUS_BA[0]) WCR3[ 7:0] <= IBUS_DI[ 7: 0] & WCR3_WMASK[7:0];
					end 
					5'h08: begin
						if (IBUS_BA[3]) DCR[15:8] <= IBUS_DI[31:24] & DCR_WMASK[15:8];
						if (IBUS_BA[2]) DCR[ 7:0] <= IBUS_DI[23:16] & DCR_WMASK[7:0];
						if (IBUS_BA[1]) PCR[15:8] <= IBUS_DI[15: 8] & PCR_WMASK[15:8];
						if (IBUS_BA[0]) PCR[ 7:0] <= IBUS_DI[ 7: 0] & PCR_WMASK[7:0];
					end 
					5'h0C: begin
						if (IBUS_BA[3]) RCR[15:8] <= IBUS_DI[31:24] & RCR_WMASK[15:8];
						if (IBUS_BA[2]) RCR[ 7:0] <= IBUS_DI[23:16] & RCR_WMASK[7:0];
						if (IBUS_BA[1]) RTCSR[15:8] <= IBUS_DI[15: 8] & RTCSR_WMASK[15:8];
						if (IBUS_BA[0]) RTCSR[ 7:0] <= IBUS_DI[ 7: 0] & RTCSR_WMASK[7:0];
					end 
					5'h10: begin
						if (IBUS_BA[2]) RTCNT[ 7:0] <= IBUS_DI[23:16] & RTCNT_WMASK[7:0];
						if (IBUS_BA[0]) RTCOR[ 7:0] <= IBUS_DI[ 7: 0] & RTCOR_WMASK[7:0];
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
				case ({IBUS_A[4:2],2'b00})
					5'h00: REG_DO <= {BCR & BCR_RMASK,WCR1 & WCR1_RMASK};
					5'h04: REG_DO <= {WCR2 & WCR2_RMASK,WCR3 & WCR3_RMASK};
					5'h08: REG_DO <= {DCR & DCR_RMASK,PCR & PCR_RMASK};
					5'h0C: REG_DO <= {RCR & RCR_RMASK,RTCSR & RTCSR_RMASK};
					5'h10: REG_DO <= {8'h00,RTCNT & RTCNT_RMASK,8'h00,RTCOR & RTCOR_RMASK};
					default:REG_DO <= '0;
				endcase
			end
		end
	end
	
	assign IBUS_DO = REG_SEL ? REG_DO : DAT_BUF;
	assign IBUS_BUSY = BUSY | ((BUS_RLS | BACK) & DBUS_REQ);
	assign IBUS_ACT = REG_SEL;
	
	assign IRQ = 0;
	

endmodule

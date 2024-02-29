module SH7604_BSC 
#(parameter bit AREA3=0, bit [1:0] W3=0, bit [1:0] IW3=0, bit [1:0] LW3=0)
(
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	input             EN,
	
	input             RES_N,
	
	output reg [26:0] A,
	input      [31:0] DI,
	output reg [31:0] DO,
	output reg        BS_N,
	output reg        CS0_N,
	output reg        CS1_N,
	output reg        CS2_N,
	output reg        CS3_N,
	output reg        RD_WR_N,
	output reg        CE_N,		//RAS_N
	output reg        OE_N,		//CAS_N
	output reg  [3:0] WE_N,		//CASxx_N, DQMxx
	output reg        RD_N,
	input             WAIT_N,
	input             BRLS_N,	//BACK_N
	output            BGR_N,	//BREQ_N
	output reg        IVECF_N,
	input       [5:0] MD,
	
	input      [31:0] DBUS_A,
	input      [31:0] DBUS_DI,
	output     [31:0] DBUS_DO,
	input       [3:0] DBUS_BA,
	input             DBUS_WE,
	input             DBUS_REQ,
	input             DBUS_BURST,
	input             DBUS_LOCK,
	output            DBUS_BUSY,
	output            DBUS_ACT,
	
	input       [3:0] VBUS_A,
	output      [7:0] VBUS_DO,
	input             VBUS_REQ,
	output            VBUS_BUSY,
	
	output            EBUS_END,
	
	output            IRQ,
	
	output reg        CACK,
	output            BUS_RLS
);

	import SH7604_PKG::*;

	BCR1_t      BCR1;
	BCR2_t      BCR2;
	WCR_t       WCR;
	MCR_t       MCR;
	RTCSR_t     RTCSR;
	RTCNT_t     RTCNT;
	RTCOR_t     RTCOR;
	
	function bit [1:0] GetAreaW(input bit [1:0] area, input WCR_t wcr);
		bit [1:0] res;
	
		case (area)
			2'd0: res = wcr.W0;
			2'd1: res = wcr.W1;
			2'd2: res = wcr.W2;
			2'd3: res = AREA3 ? W3 : wcr.W3;
		endcase
		return res;
	endfunction
	
	function bit [1:0] GetAreaIW(input bit [1:0] area, input WCR_t wcr);
		bit [1:0] res;
	
		case (area)
			2'd0: res = wcr.IW0;
			2'd1: res = wcr.IW1;
			2'd2: res = wcr.IW2;
			2'd3: res = AREA3 ? IW3 : wcr.IW3;
		endcase
		return res;
	endfunction
	
	function bit [1:0] GetAreaLW(input bit [1:0] area, input BCR1_t bcr1);
		bit [1:0] res;
	
		case (area)
			2'd0: res = bcr1.A0LW;
			2'd1: res = bcr1.A1LW;
			2'd2: res = bcr1.AHLW;
			2'd3: res = AREA3 ? LW3 : bcr1.AHLW;
		endcase
		return res;
	endfunction
	
	function bit [1:0] GetAreaSZ(input bit [1:0] area, input BCR1_t bcr1, input BCR2_t bcr2, input bit [1:0] a0sz, input bit [1:0] dramsz);
		bit [1:0] res;
	
		case (area)
			2'd0: res = a0sz;
			2'd1: res = bcr2.A1SZ;
			2'd2: res = bcr1.DRAM[2]    ? dramsz : bcr2.A2SZ;
			2'd3: res = ^bcr1.DRAM[1:0] ? dramsz : bcr2.A3SZ;
		endcase
		return res;
	endfunction	
	
	function bit IsSDRAMArea(input bit [1:0] area, input BCR1_t bcr1);
		bit       res;
	
		case (area)
			2'd0: res = 0;
			2'd1: res = 0;
			2'd2: res = bcr1.DRAM[2];
			2'd3: res = ~bcr1.DRAM[1] & bcr1.DRAM[0];
		endcase
		return res;
	endfunction 
	
	bit         BREQ;
	wire        BACK = ~BRLS_N;
	bit         BGR;
	wire        BRLS = ~BRLS_N;
	
	wire        MASTER = ~MD[5];
	wire [1:0]  A0_SZ = MD[4:3] + 2'b01;
	wire [1:0]  DRAM_SZ = {1'b1,MCR.SZ};
	
	typedef enum bit[2:0] {
		T0  = 3'b000,  
		T1  = 3'b001,
		T2  = 3'b010,
		TW  = 3'b011,
		TD  = 3'b100,
		TRC = 3'b101,
		TV1 = 3'b110,
		TV2 = 3'b111
	} BusState_t;
	BusState_t BUS_STATE;
	
	wire DBUS_SEL = (DBUS_A[31:27] ==? 5'b00?00) && DBUS_REQ; 
	wire BUS_SEL = DBUS_SEL | VBUS_REQ; 
	
	bit         BUSY;
	bit         DBUSY;
	bit         VBUSY;
	bit         VBUS_ACTIVE;
	bit  [31:0] DAT_BUF;
	bit  [ 7:0] VEC_BUF;
	bit   [3:0] NEXT_BA;
	bit   [2:0] BURST_CNT;
	bit         BURST_EN;
	always @(posedge CLK or negedge RST_N) begin
		BusState_t STATE_NEXT;
		bit  [2:0] WAIT_CNT;
		bit [31:0] DBUS_DI_SAVE;
		bit        DBUS_WE_SAVE;
		bit  [1:0] AREA_SZ;
		bit        IS_SDRAM;
		bit        BURST_LAST;
		
		if (!RST_N) begin
			BUSY <= 0;
			CS0_N <= 1;
			CS1_N <= 1;
			CS2_N <= 1;
			CS3_N <= 1;
			BS_N <= 1;
			RD_WR_N <= 1;
			RD_N <= 1;
			WE_N <= 4'b1111;
			IVECF_N <= 1;
			CACK <= 0;
			DBUSY <= 0;
			VBUSY <= 0;
			VBUS_ACTIVE <= 0;
			BUS_STATE <= T0;
			WAIT_CNT <= '0;
			NEXT_BA <= '0;
		end
		else begin
			AREA_SZ = GetAreaSZ(A[26:25],BCR1,BCR2,A0_SZ,DRAM_SZ);
			BURST_LAST = (BURST_CNT == {2'b11,~AREA_SZ[0]});
						
			STATE_NEXT = BUS_STATE;
			case (BUS_STATE)
				T0: begin
					if (CE_F) begin
						if (DBUS_A[28:27] != 2'b00)
							DAT_BUF <= '0;
					end
				end
				
				T1: begin
					if (CE_R) begin
						BS_N <= 1;
						case (GetAreaW(A[26:25],WCR))
							2'b00: begin
								if (!NEXT_BA) begin
									DBUSY <= 0;
									BUSY <= 0;
								end
								STATE_NEXT = T2;
							end
							2'b01: begin
								WAIT_CNT <= 3'd0;
								STATE_NEXT = TW;
							end
							2'b10: begin
								WAIT_CNT <= 3'd1;
								STATE_NEXT = TW;
							end
							2'b11: begin
								case (GetAreaLW(A[26:25],BCR1))
									2'b00: WAIT_CNT <= 3'd2;
									2'b01: WAIT_CNT <= 3'd3;
									2'b10: WAIT_CNT <= 3'd4;
									2'b11: WAIT_CNT <= 3'd5;
								endcase
								STATE_NEXT = TW;
							end
						endcase
					end
				end
				
				TW: begin
					if (CE_R) begin
						if (WAIT_CNT) begin
							WAIT_CNT <= WAIT_CNT - 3'd1;
						end
						else if (WAIT_N) begin
							if (!NEXT_BA) begin
								DBUSY <= 0;
								BUSY <= 0;
							end
							STATE_NEXT = T2;
						end
					end
				end
				
				T2: begin
					if (CE_F) begin
						case (AREA_SZ)
							/*2'b01: 
								case (A[1:0])
									2'b00: DAT_BUF[31:24] <= DI[7:0];
									2'b01: DAT_BUF[23:16] <= DI[7:0];
									2'b10: DAT_BUF[15: 8] <= DI[7:0];
									2'b11: DAT_BUF[ 7: 0] <= DI[7:0];
								endcase*/
							2'b10:
								case (A[1])
									1'b0: DAT_BUF[31:16] <= DI[15:0];
									1'b1: DAT_BUF[15: 0] <= DI[15:0];
								endcase
							2'b11: DAT_BUF <= DI;
							default:;
						endcase
						RD_N <= 1;
						WE_N <= 4'b1111;
						CACK <= 0;
					end
					else if (CE_R) begin
						if (!NEXT_BA) begin
							CS0_N <= 1;
							CS1_N <= 1;
							CS2_N <= 1;
							CS3_N <= 1;
							RD_WR_N <= 1;
						end
						STATE_NEXT = T0;
					end
				end
				
				TRC: begin
					if (CE_R) begin
						BS_N <= 1;
						if (WAIT_N) begin
							if (!NEXT_BA) begin
								DBUSY <= 0;
								BUSY <= 0;
							end
							STATE_NEXT = TD;
						end
					end
				end
				
				TD: begin
					if (CE_F) begin
						case (AREA_SZ)
							2'b10:
								case (A[1])
									1'b0: DAT_BUF[31:16] <= DI[15:0];
									1'b1: DAT_BUF[15: 0] <= DI[15:0];
								endcase
							2'b11: DAT_BUF <= DI;
							default:;
						endcase
						RD_N <= 1;
						WE_N <= 4'b1111;
						CACK <= 0;
					end
					else if (CE_R) begin
						if (BURST_EN) begin
							case (AREA_SZ)
								2'b10: BURST_CNT <= BURST_CNT + 3'd1;
								2'b11: BURST_CNT <= BURST_CNT + 3'd2;
								default:;
							endcase
							if (BURST_LAST) BURST_EN <= 0;
						end
						if (!BURST_CNT[0] && BURST_EN && RD_WR_N) begin
							DBUSY <= 0;
							BUSY <= 0;
						end 
						if ((!NEXT_BA && !BURST_EN) || BURST_LAST) begin
							CS0_N <= 1;
							CS1_N <= 1;
							CS2_N <= 1;
							CS3_N <= 1;
							RD_WR_N <= 1;
						end
						STATE_NEXT = T0;
					end
				end
				
				TV1: begin
					if (CE_R) begin
						BS_N <= 1;
						if (WAIT_N) begin
							VBUSY <= 0;
							BUSY <= 0;
							STATE_NEXT = TV2;
						end
					end
				end
				
				TV2: begin
					if (CE_F) begin
						VEC_BUF <= DI[7:0];
						RD_N <= 1;
					end else if (CE_R) begin
						IVECF_N <= 1;
						RD_WR_N <= 1;
						STATE_NEXT = T0;
					end
				end
				
				default:;
			endcase
			
			if (CE_R) begin
				if (BUS_STATE == T0 || BUS_STATE == T2 || BUS_STATE == TD || BUS_STATE == TV2) begin
					if (DBUS_SEL && !BUS_RLS && !BUSY && (BURST_CNT[0] || !BURST_EN)) begin
						BUSY <= 1;
						DBUSY <= 1;
					end
					if (VBUS_REQ && !BUS_RLS && !BUSY) begin
						BUSY <= 1;
						VBUSY <= 1;
					end
					
					VBUS_ACTIVE <= 0;
					if (((BUS_STATE == T2 || BUS_STATE == TD) && BUSY && DBUSY && !BURST_EN) || (BUS_STATE == TD && BURST_EN && !BURST_LAST)) begin
						IS_SDRAM = IsSDRAMArea(A[26:25],BCR1);
						case (AREA_SZ)
							/*2'b01: begin 
								A[3:0] <= A[3:0] + 4'd1; 
								case (A[1:0] + 2'd1)
									2'b01: begin 
										DO <= {24'h000000,DBUS_DI_SAVE[23:16]};
										WE_N <= ~{3'b000,DBUS_WE_SAVE & NEXT_BA[2]};
										NEXT_BA <= {2'b00,NEXT_BA[1:0]};
									end
									2'b10: begin 
										DO <= {24'h000000,DBUS_DI_SAVE[15: 8]}; 
										WE_N <= ~{3'b000,DBUS_WE_SAVE & NEXT_BA[1]};
										NEXT_BA <= {3'b000,NEXT_BA[0]};
									end
									2'b11: begin 
										DO <= {24'h000000,DBUS_DI_SAVE[ 7: 0]};
										WE_N <= ~{3'b000,DBUS_WE_SAVE & NEXT_BA[0]}; 
										NEXT_BA <= 4'b0000;
									end
									default: begin //shouldn't happen
										WE_N <= 4'b1111;
										NEXT_BA <= 4'b0000;
									end
								endcase
							end*/
							2'b10: begin 
								A[3:0] <= A[3:0] + 4'd2; 
								case (A[1])
									1'b0: begin 
										DO <= {16'h0000,DBUS_DI_SAVE[15: 0]};
										WE_N <= ~({2'b00,DBUS_WE_SAVE,DBUS_WE_SAVE} & {2'b00,NEXT_BA[1:0]}); 
										NEXT_BA <= 4'b0000;
									end
									1'b1: begin 
										DO <= 32'h00000000; 
										WE_N <= 4'b1111;
										NEXT_BA <= {2'b00,{2{BURST_EN}}};
									end
								endcase
							end
							2'b11: begin 
								A[3:0] <= A[3:0] + 4'd4; 
								WE_N <= 4'b1111;
								NEXT_BA <= 4'b0000;
							end
							default: ;
						endcase
						BS_N <= 0;
						RD_N <= DBUS_WE_SAVE;
						CACK <= 1;
						STATE_NEXT = IS_SDRAM ? (BURST_EN ? TD : TRC) : T1;
					end
					else if (BUS_SEL && !BUS_RLS && ((!BGR && MASTER) || (BREQ && !MASTER))) begin
						BUSY <= 1;
						DBUSY <= DBUS_SEL;
						VBUSY <= VBUS_REQ;
						
						IS_SDRAM = IsSDRAMArea(DBUS_A[26:25],BCR1); 
						
						if (!VBUS_REQ || DBUS_LOCK) begin
							case (GetAreaSZ(DBUS_A[26:25],BCR1,BCR2,A0_SZ,DRAM_SZ))
								2'b01: begin 
									case (DBUS_A[1:0])
										2'b00: begin 
											DO <= {24'h000000,DBUS_DI[31:24]}; 
											WE_N <= ~{3'b000,DBUS_WE & DBUS_BA[3]};
											NEXT_BA <= {1'b0,DBUS_BA[2:0]};
										end
										2'b01: begin 
											DO <= {24'h000000,DBUS_DI[23:16]};
											WE_N <= ~{3'b000,DBUS_WE & DBUS_BA[2]};
											NEXT_BA <= {2'b00,DBUS_BA[1:0]};
										end
										2'b10: begin 
											DO <= {24'h000000,DBUS_DI[15: 8]}; 
											WE_N <= ~{3'b000,DBUS_WE & DBUS_BA[1]};
											NEXT_BA <= {3'b000,DBUS_BA[0]};
										end
										2'b11: begin 
											DO <= {24'h000000,DBUS_DI[ 7: 0]};
											WE_N <= ~{3'b000,DBUS_WE & DBUS_BA[0]}; 
											NEXT_BA <= 4'b0000;
										end
									endcase
								end
								2'b10: begin 
									case (DBUS_A[1])
										1'b0: begin 
											DO <= {16'h0000,DBUS_DI[31:16]}; 
											WE_N <= ~{2'b00,{2{DBUS_WE}} & DBUS_BA[3:2]};
											NEXT_BA <= {2'b00,DBUS_BA[1:0]};
										end
										1'b1: begin 
											DO <= {16'h0000,DBUS_DI[15: 0]}; 
											WE_N <= ~{2'b00,{2{DBUS_WE}} & DBUS_BA[1:0]};
											NEXT_BA <= 4'b0000;
										end
									endcase
								end
								2'b11: begin 
									DO <= DBUS_DI; 
									WE_N <= ~({DBUS_WE,DBUS_WE,DBUS_WE,DBUS_WE} & DBUS_BA);
									NEXT_BA <= 4'b0000;
								end
								default:; 
							endcase
							if (DBUS_BURST && IS_SDRAM && !DBUS_WE) begin
								if (!BURST_EN || BURST_LAST) begin
									BURST_CNT <= 3'd0;
									BURST_EN <= 1;
								end
							end else begin
								BURST_CNT <= 3'd0;
								BURST_EN <= 0;
							end
							A <= DBUS_A[26:0];
							CS0_N <= ~(DBUS_A[26:25] == 2'b00);
							CS1_N <= ~(DBUS_A[26:25] == 2'b01);
							CS2_N <= ~(DBUS_A[26:25] == 2'b10);
							CS3_N <= ~(DBUS_A[26:25] == 2'b11);
							BS_N <= 0;
							RD_WR_N <= ~DBUS_WE;
							RD_N <= DBUS_WE;
							CACK <= 1;
							
							DBUS_WE_SAVE <= DBUS_WE;
							DBUS_DI_SAVE <= DBUS_DI; 
							if (BUS_STATE == T0 || BUS_STATE == T2 || BUS_STATE == TD) begin
								STATE_NEXT = IS_SDRAM ? TRC : T1;
							end
						end else begin
							A <= {23'h000000,VBUS_A};
							DO <= '0; 
							CS0_N <= 1;
							CS1_N <= 1;
							CS2_N <= 1;
							CS3_N <= 1;
							IVECF_N <= 0;
							BS_N <= 0;
							RD_WR_N <= 1;
							WE_N <= 4'b1111;
							RD_N <= 0;
							CACK <= 0;
							
							NEXT_BA <= 4'b0000;
							DBUS_WE_SAVE <= '0;
							DBUS_DI_SAVE <= '0;
							VBUS_ACTIVE <= 1;
							STATE_NEXT = TV1;
						end
					end
				end
				else if ((BUS_STATE == T1 || BUS_STATE == TW || BUS_STATE == TRC) && BUS_SEL && !BUS_RLS) begin
					if (!VBUSY && VBUS_REQ) VBUSY <= 1;
				end
			end
			BUS_STATE <= STATE_NEXT;
		end
	end
	
		
	bit MST_BUS_RLS;
	bit SLV_BUS_RLS;
	bit MST_RLS_END;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			BREQ <= 0;
			BGR <= 0;
			MST_BUS_RLS <= 0;
			SLV_BUS_RLS <= 1;
			MST_RLS_END <= 0;
		end else if (CE_F) begin
			if (MASTER) begin
				if (BRLS && !BGR && (BUS_STATE == T0 || BUS_STATE == T2 || BUS_STATE == TD || BUS_STATE == TV2) && !BUSY && !DBUS_LOCK && !MST_BUS_RLS) begin
					BGR <= 1;
				end
				else if (BRLS && BGR && !MST_BUS_RLS) begin
					MST_BUS_RLS <= 1;
				end
				else if (!BRLS && MST_BUS_RLS) begin
					BGR <= 0;
					MST_BUS_RLS <= 0;
				end
			end
			else begin
				if (BUS_SEL && !BREQ && SLV_BUS_RLS) begin
					BREQ <= 1;
				end
				else if (BREQ && BACK && SLV_BUS_RLS) begin
					SLV_BUS_RLS <= 0;
				end
				else if ((BREQ && (BUS_STATE == T2 || BUS_STATE == TD || BUS_STATE == TV2) && !BUSY && !DBUS_LOCK && !SLV_BUS_RLS) || 
				         (BREQ && BUS_STATE == T0 && !BUSY && !RES_N && !SLV_BUS_RLS)) begin
					BREQ <= 0;
				end
				else if (!BREQ && !SLV_BUS_RLS ) begin
					SLV_BUS_RLS <= 1;
				end
			end
		end
		else if (CE_R) begin
			MST_RLS_END <= 0;
			if (MASTER) begin
				if (!BRLS && MST_BUS_RLS) begin
					MST_RLS_END <= 1;
				end
			end
			else begin
				
			end
		end
	end
	
	assign BGR_N = MASTER ? ~BGR : ~BREQ;
	assign BUS_RLS = MASTER ? MST_BUS_RLS : SLV_BUS_RLS;
	
		
	//Registers
	wire REG_SEL = (DBUS_A >= 32'hFFFFFFE0);
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			BCR1  <= BCR1_INIT;
			BCR2  <= BCR2_INIT;
			WCR   <= WCR_INIT;
			MCR   <= MCR_INIT;
			RTCSR <= RTCSR_INIT;
			RTCNT <= RTCNT_INIT;
			RTCOR <= RTCOR_INIT;
		end
		else if (CE_R) begin
			if (REG_SEL && DBUS_DI[31:16] == 16'hA55A && DBUS_WE && DBUS_REQ) begin
				case ({DBUS_A[4:2],2'b00})
					5'h00: BCR1  <= DBUS_DI[15:0] & BCR1_WMASK;
					5'h04: BCR2  <= DBUS_DI[15:0] & BCR2_WMASK;
					5'h08: WCR   <= DBUS_DI[15:0] & WCR_WMASK;
					5'h0C: MCR   <= DBUS_DI[15:0] & MCR_WMASK;
					5'h10: RTCSR <= DBUS_DI[15:0] & RTCSR_WMASK;
					5'h14: RTCNT <= DBUS_DI[7:0]  & RTCNT_WMASK;
					5'h18: RTCOR <= DBUS_DI[7:0]  & RTCOR_WMASK;
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
			if (REG_SEL && !DBUS_WE && DBUS_REQ) begin
				REG_DO[31:16] <= 16'h0000;
				case ({DBUS_A[4:2],2'b00})
					5'h00: REG_DO[15:0] <= {MD[5],BCR1[14:0]} & BCR1_RMASK;
					5'h04: REG_DO[15:0] <= BCR2 & BCR2_RMASK;
					5'h08: REG_DO[15:0] <= WCR & WCR_RMASK;
					5'h0C: REG_DO[15:0] <= MCR & MCR_RMASK;
					5'h10: REG_DO[15:0] <= RTCSR & RTCSR_RMASK;
					5'h14: REG_DO[15:0] <= {8'h00,RTCNT} & RTCNT_RMASK;
					5'h18: REG_DO[15:0] <= {8'h00,RTCOR} & RTCOR_RMASK;
					default:REG_DO[15:0] <= '0;
				endcase
			end
		end
	end
	
	assign EBUS_END = MST_RLS_END;
	
	assign DBUS_DO = REG_SEL ? REG_DO : DAT_BUF;
	assign DBUS_BUSY = DBUSY | ((BUS_RLS | (BGR & MASTER) | (~BREQ & ~MASTER)) & DBUS_SEL) | VBUS_ACTIVE;
	assign DBUS_ACT = REG_SEL;
	
	assign VBUS_DO = VEC_BUF;
	assign VBUS_BUSY = VBUSY | ((BUS_RLS | BGR) & VBUS_REQ);
	
	assign OE_N = 1;
	assign CE_N = 1;
	assign IRQ = 0;
	

endmodule

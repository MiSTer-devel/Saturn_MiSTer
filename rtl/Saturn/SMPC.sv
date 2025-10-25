module SMPC (
	input              CLK,
	input              RST_N,
	input              CE,
	
	input              MRES_N,
	input              TIME_SET,
	
	input      [64: 0] EXT_RTC,
	
	input      [ 3: 0] AC,
	
	input      [ 6: 1] A,
	input      [ 7: 0] DI,
	output     [ 7: 0] DO,
	input              CS_N,
	input              RW_N,
	
	input              SRES_N,
	
	input              IRQV_N,
	output             EXL_N,
	
	output reg         MSHRES_N,
	output reg         MSHNMI_N,
	output reg         SSHRES_N,
	output reg         SSHNMI_N,
	output reg         SYSRES_N,
	output reg         SNDRES_N,
	output reg         CDRES_N,
	
	output reg         MIRQ_N,

	output reg         DOTSEL,
	
	input      [ 6: 0] PDR1I,
	output reg [ 6: 0] PDR1O,
	output reg [ 6: 0] DDR1,
	input      [ 6: 0] PDR2I,
	output reg [ 6: 0] PDR2O,
	output reg [ 6: 0] DDR2
);

	//Registers
	bit  [ 7: 0] COMREG;
	bit  [ 7: 0] SR;
	bit          SF;
	bit  [ 7: 0] IREG[7];
	
	wire [ 6: 0] PDR_I[2] = '{PDR1I,PDR2I};
	bit  [ 7: 0] PDR_O[2];
	bit  [ 6: 0] DDR[2];
	bit  [ 1: 0] IOSEL;
	bit  [ 1: 0] EXLE;
	bit  [ 1: 0] PMD[2];
	
	bit          RESD;
	bit          STE;
	
	typedef enum bit [4:0] {
		CS_IDLE,
		CS_WAIT, 
//		CS_VBIN,
//		CS_VBOUT,
		CS_COMMAND_HNIB,CS_COMMAND_LNIB,CS_COMMAND_UNKNOWN,
		CS_RESET_START,CS_RESET_EXEC,
		CS_INTBACK_STAT,
		CS_EXEC,
		CS_INTBACK_WAIT,
		CS_INTBACK_CONT,CS_INTBACK_CONT2,
		CS_INTBACK_PERI,CS_INTBACK_PERI2,CS_INTBACK_PERI3,
		CS_INTBACK_BREAK, 
		CS_END
	} CommExecState_t;
	CommExecState_t COMM_ST;
	bit  [ 7: 0] COMMAND;
	
	`define THTR 6:5
	`define TH 6
	`define TR 5
	
	typedef enum bit [5:0] {
		PS_IDLE,
		PS_START,
		PS_ID1_0,PS_ID1_1,PS_ID1_2,PS_ID1_3,PS_ID1_4,
		PS_TYPE_SEL, 
		PS_DPAD_0,PS_DPAD_1,PS_DPAD_2,PS_DPAD_3,PS_DPAD_4,PS_DPAD_5,PS_DPAD_6,PS_DPAD_7,
		PS_MOUSE_0,PS_MOUSE_1,PS_MOUSE_2,PS_MOUSE_3,PS_MOUSE_4,PS_MOUSE_5,PS_MOUSE_6,PS_MOUSE_7,PS_MOUSE_8,PS_MOUSE_9,PS_MOUSE_10,
		PS_ID5_0,PS_ID5_1,PS_ID5_2,PS_ID5_3,PS_ID5_4,PS_ANALOG_5,PS_ANALOG_6,PS_ANALOG_7,PS_ANALOG_8,PS_ANALOG_9,PS_ANALOG_10,
		PS_NOTHING_STUNNER,
		PS_NEXT,
		PS_END
	} PortState_t;
	PortState_t PORT_ST;
	
	
	bit  [ 7: 0] RTC_SEC;
	bit  [ 7: 0] RTC_MIN;
	bit  [ 7: 0] RTC_HOUR;
	bit  [ 7: 0] RTC_DAYS = 8'h01;
	bit  [ 3: 0] RTC_DAY = 4'h1;
	bit  [ 3: 0] RTC_MONTH = 4'h1;
	bit  [15: 0] RTC_YEAR = 16'h2024;
	bit          SETTIME_EXEC,SETTIME_UPDATE,SETTIME_TICK;
	bit  [ 2: 0] SETTIME_POS;
	bit  [16: 0] SETTIME_DELAY;
	bit          RTC_IRQ;
	
	bit         SEC_CLK;
	always @(posedge CLK) begin
`ifdef DEBUG
		SEC <= 8'h00;
		MIN <= 8'h00;
		HOUR <= 8'h00;
		DAYS <= 8'h02;
		{DAY,MONTH} <= 8'h01;
		YEAR <= 16'h2024;
`else
		bit [21: 0] CLK_CNT;
		bit         MIN_CLK,HOUR_CLK,DAYS_CLK,MONTH_CLK,YEAR_CLK;
		bit [ 7: 0] SETTIME_BUF[7];
		bit         EXT_RTC64_OLD = 0;
		
		if (CE) begin
			SEC_CLK <= 0;
			MIN_CLK <= 0;
			HOUR_CLK <= 0;
			DAYS_CLK <= 0;
			MONTH_CLK <= 0;
			YEAR_CLK <= 0;
			
			if (SETTIME_TICK) begin
				RTC_SEC[3:0] <= RTC_SEC[3:0] + 4'd1;
				if (RTC_SEC[3:0] == 4'd9) begin
					RTC_SEC[3:0] <= 4'd0;
					RTC_SEC[7:4] <= RTC_SEC[7:4] + 4'd1;
					if (RTC_SEC[7:4] == 4'd5) begin
						RTC_SEC[7:4] <= 4'd0;
						MIN_CLK <= 1;
					end
				end
			end
			if (MIN_CLK) begin
				RTC_MIN[3:0] <= RTC_MIN[3:0] + 4'd1;
				if (RTC_MIN[3:0] == 4'd9) begin
					RTC_MIN[3:0] <= 4'd0;
					RTC_MIN[7:4] <= RTC_MIN[7:4] + 4'd1;
					if (RTC_MIN[7:4] == 4'd5) begin
						RTC_MIN[7:4] <= 4'd0;
						HOUR_CLK <= 1;
					end
				end
			end
			if (HOUR_CLK) begin
				RTC_HOUR[3:0] <= RTC_HOUR[3:0] + 4'd1;
				if (RTC_HOUR[3:0] == 4'd9) begin
					RTC_HOUR[3:0] <= 4'd0;
					RTC_HOUR[7:4] <= RTC_HOUR[7:4] + 4'd1;
				end
				else if (RTC_HOUR == 8'h23) begin
					RTC_HOUR <= 8'h00;
					DAYS_CLK <= 1;
				end
			end
			if (DAYS_CLK) begin
				RTC_DAYS[3:0] <= RTC_DAYS[3:0] + 4'd1;
				if (RTC_DAYS[3:0] == 4'd9) begin
					RTC_DAYS[7:4] <= RTC_DAYS[7:4] + 4'd1;
					RTC_DAYS[3:0] <= 4'd0;
				end
				else if ((RTC_DAYS == 8'h28 && RTC_MONTH == 4'd2) || 
							(RTC_DAYS == 8'h30 && RTC_MONTH == 4'd4) || 
							(RTC_DAYS == 8'h30 && RTC_MONTH == 4'd6) || 
							(RTC_DAYS == 8'h30 && RTC_MONTH == 4'd9) || 
							(RTC_DAYS == 8'h30 && RTC_MONTH == 4'd11) || 
							 RTC_DAYS == 8'h31) begin
					RTC_DAYS <= 8'h01;
					MONTH_CLK <= 1;
				end
			end
			if (MONTH_CLK) begin
				RTC_MONTH <= RTC_MONTH + 4'd1;
				if (RTC_MONTH == 4'd12) begin
					RTC_MONTH <= 4'd1;
					YEAR_CLK <= 1;
				end
			end
			if (YEAR_CLK) begin
				RTC_YEAR <= RTC_YEAR + 16'd1;
			end
			
			if (SETTIME_UPDATE) begin
				RTC_SEC <= SETTIME_BUF[6];
				RTC_MIN <= SETTIME_BUF[5];
				RTC_HOUR <= SETTIME_BUF[4];
				RTC_DAYS <= SETTIME_BUF[3];
				{RTC_DAY,RTC_MONTH} <= SETTIME_BUF[2];
				RTC_YEAR <= {SETTIME_BUF[0],SETTIME_BUF[1]};
			end
			if (SETTIME_EXEC) begin
				for (int i=0;i<7;i++) SETTIME_BUF[i] <= IREG[i];
			end
		end
		
		if (EXT_RTC[64] != EXT_RTC64_OLD) begin
			EXT_RTC64_OLD <= EXT_RTC[64];
			RTC_SEC <= EXT_RTC[7:0];
			RTC_MIN <= EXT_RTC[15:8];
			RTC_HOUR <= EXT_RTC[23:16];
			RTC_DAYS <= EXT_RTC[31:24];
			RTC_MONTH <= EXT_RTC[35:32] + (EXT_RTC[36] == 0 ? 4'd0 : 4'd10);
			RTC_YEAR <= {8'h20,EXT_RTC[47:40]};
		end
`endif
	end
	
	
	bit [ 7: 0] REG_DO;
	bit [ 4: 0] OREG_CNT;
	always @(posedge CLK or negedge RST_N) begin
		CommExecState_t WAIT_ST,RET_COMM_ST,RET_WAIT_ST;
		bit [ 5: 0] IDLE_DELAY;
		bit         IDLE_DELAY2;
		bit         VBLANK_PEND;
		bit         COMREG_SET;
		bit         VBIN_PEND,VBOUT_PEND;
		bit         IRQ_EN;
		bit         RW_N_OLD;
		bit         CS_N_OLD;
		bit [ 7: 0] IO_BUF;
		bit         IRQV_N_OLD;
		bit [ 1: 0] FRAME_CNT;
		bit [19: 0] WAIT_CNT,RET_WAIT_CNT;
		bit [16: 0] TIME_CNT,INTBACK_TIME;
		bit         SRES_EXEC;
		bit         INTBACK_EXEC;
		bit         INTBACK_PERI;
		bit         INTBACK_OPTIM_EN;
		bit         INTBACK_OPTIM_TIME,INTBACK_NOT_OPTIM_TIME;
		bit [ 3: 0] INTBACK_VB_CNT;
		bit         CHECK_CONTINUE;
		bit         BREAK,CONT,CONT_PREV;
		bit [21: 0] RTC_CLK_CNT;
		bit         SETTIME_PEND;
		
		bit [ 8: 0] PORT_DELAY;
		bit         JOY_START;
		bit [15: 0] JOY_DATA;
		bit         PORT_NUM;
		bit [ 3: 0] PORT_DATA_CNT;
		bit [ 7: 0] PERI_OREG_DATA;
		bit         PERI_OREG_WRITE;
		bit         PERI_OREG_END;
		bit [ 3: 0] MD_ID;
		bit [ 7: 0] ID2;
		
		if (!RST_N) begin
			COMREG <= '0;
			SR <= '0;
			SF <= 0;
			IREG <= '{7{'0}};
			PDR_O <= '{2{'1}};
			DDR <= '{2{'0}};
			IOSEL <= '0;
			EXLE <= '0;
			
			MSHRES_N <= 0;
			MSHNMI_N <= 0;
			SSHRES_N <= 0;
			SSHNMI_N <= 0;
			SYSRES_N <= 0;
			SNDRES_N <= 0;
			CDRES_N <= 0;
			MIRQ_N <= 1;
			DOTSEL <= 0;
			RESD <= 1;
			STE <= 0;
			
			REG_DO <= '0;
			RW_N_OLD <= 1;
			CS_N_OLD <= 1;
			IRQV_N_OLD <= 1;
			COMM_ST <= CS_IDLE;
			{VBIN_PEND,VBOUT_PEND,IRQ_EN} <= '0;
			SRES_EXEC <= 0;
			INTBACK_EXEC <= 0;
			INTBACK_PERI <= 0;
			BREAK <= 0;
			CONT <= 0;
			CONT_PREV <= 0;
			VBLANK_PEND <= 0;
			
			PORT_ST <= PS_IDLE;
		end
		else if (!MRES_N) begin
			MSHRES_N <= 1;
			MSHNMI_N <= 1;
			SSHRES_N <= 0;
			SSHNMI_N <= 1;
			SYSRES_N <= 1;
			SNDRES_N <= 0;
			CDRES_N <= 1;
			MIRQ_N <= 1;
			DOTSEL <= 0;
			SR <= '0;
			RESD <= 1;
			STE <= TIME_SET;/////////////////
			
			COMM_ST <= CS_IDLE;
			{VBIN_PEND,VBOUT_PEND,IRQ_EN} <= '0;
			INTBACK_EXEC <= 0;
			INTBACK_PERI <= 0;
			{INTBACK_OPTIM_TIME,INTBACK_NOT_OPTIM_TIME} <= '0;
			BREAK <= 0;
			CONT <= 0;
			CONT_PREV <= 0;
			CHECK_CONTINUE <= 0;
			VBLANK_PEND <= 0;
			
			SETTIME_DELAY <= '0;
			
			PORT_ST <= PS_IDLE;
		end else begin
			OREG_RAM_WE <= '0;			
			if (CE) begin
				IRQV_N_OLD <= IRQV_N;
				
				if (WAIT_CNT) WAIT_CNT <= WAIT_CNT - 20'd1;
				
				if (!SRES_N && !RESD && !SRES_EXEC) begin
					MSHNMI_N <= 0;
					SSHNMI_N <= 0;
					WAIT_CNT <= 20'd60000;
					SRES_EXEC <= 1;
				end else if (SRES_EXEC && !WAIT_CNT) begin
					MSHNMI_N <= 1;
					SSHNMI_N <= 1;
				end
				
				TIME_CNT <= TIME_CNT + 17'd1;
				if (IRQV_N && !IRQV_N_OLD) begin
					TIME_CNT <= '0;
					VBOUT_PEND <= 1;
				end
				if (!IRQV_N && IRQV_N_OLD) begin
					INTBACK_TIME <= TIME_CNT - 17'd6020;//~1ms prior to vblank
					VBIN_PEND <= 1;
				end
				
				if (!IRQV_N) begin
					INTBACK_OPTIM_TIME <= 0;
					INTBACK_NOT_OPTIM_TIME <= 0;
				end else begin
					if (TIME_CNT == 17'd209) begin
						INTBACK_NOT_OPTIM_TIME <= 1;
					end
					if (TIME_CNT == INTBACK_TIME) begin
						INTBACK_OPTIM_TIME <= 1;
					end
				end
				
				RTC_CLK_CNT <= RTC_CLK_CNT + 22'd1;
				if (RTC_CLK_CNT == 22'd4000000-1) begin
					RTC_CLK_CNT <= 22'd0;
					RTC_IRQ <= 1;
				end
												
				SETTIME_UPDATE <= 0;
				SETTIME_EXEC <= 0;
				SETTIME_TICK <= 0;
				JOY_START <= 0;
				MIRQ_N <= 1;
				case (COMM_ST)
					CS_IDLE: begin
						IRQ_EN <= 1;
						if (INTBACK_EXEC && VBLANK_PEND) begin
							WAIT_CNT <= /*16'd158*/16'd128-16'd3;
							WAIT_ST <= CS_INTBACK_BREAK;
							COMM_ST <= CS_WAIT;
						end 
						else if (CHECK_CONTINUE && CONT != CONT_PREV && INTBACK_EXEC) begin
							WAIT_CNT <= 16'd100-16'd2;
							WAIT_ST <= CS_INTBACK_CONT;
							COMM_ST <= CS_WAIT;
						end
						else if (CHECK_CONTINUE && BREAK && INTBACK_EXEC) begin
							BREAK <= 0;
							CHECK_CONTINUE <= 0;
							WAIT_CNT <= 16'd158-16'd3;
							WAIT_ST <= CS_INTBACK_BREAK;
							COMM_ST <= CS_WAIT;
						end
						else if (INTBACK_PERI && ((INTBACK_OPTIM_EN && INTBACK_OPTIM_TIME) || (!INTBACK_OPTIM_EN && INTBACK_NOT_OPTIM_TIME)) && IRQV_N && !SRES_EXEC) begin
							OREG_CNT <= '0;
							JOY_START <= 1;
							COMM_ST <= CS_INTBACK_PERI;
						end 
						else if (COMREG_SET && !SRES_EXEC) begin
							COMREG_SET <= 0;
							COMMAND <= COMREG;
							OREG_CNT <= '0;
							IRQ_EN <= 0;
							INTBACK_VB_CNT <= '0;
							if (COMREG[7:5] == 3'b000) begin	//command 0x00-0x1F
								WAIT_CNT <= 16'd75-16'd2;
								WAIT_ST <= CS_COMMAND_HNIB;
							end else begin							//command 0x20-0xFF
								WAIT_CNT <= 16'd82-16'd2;
								WAIT_ST <= CS_COMMAND_UNKNOWN;
							end
							COMM_ST <= CS_WAIT;
						end else if (RTC_IRQ) begin
							RTC_IRQ <= 0;
							if (SETTIME_PEND) begin
								SETTIME_UPDATE <= 1;
								SETTIME_PEND <= 0;
							end else begin
								SETTIME_TICK <= 1;
							end
						end
					end
					
					CS_WAIT: begin
						if (!WAIT_CNT) begin
							COMM_ST <= WAIT_ST;
						end
					end
					
//					CS_VBIN: begin
////						if (!WAIT_CNT) begin
//							WAIT_CNT <= RET_WAIT_CNT;
//							WAIT_ST <= RET_WAIT_ST;
//							COMM_ST <= RET_COMM_ST;
////						end
//					end
//					
//					CS_VBOUT: begin
////						if (!WAIT_CNT) begin
//							WAIT_CNT <= RET_WAIT_CNT;
//							WAIT_ST <= RET_WAIT_ST;
//							COMM_ST <= RET_COMM_ST;
////						end
//					end
					
					CS_COMMAND_HNIB: begin
						OREG_RAM_WA <= 5'd31;
						OREG_RAM_D <= COMMAND;
						OREG_RAM_WE[1] <= 1;
						WAIT_CNT <= 16'd12 - 16'd2;
						WAIT_ST <= CS_COMMAND_LNIB;
						COMM_ST <= CS_WAIT;
					end
					
					CS_COMMAND_LNIB: begin
						OREG_RAM_WA <= 5'd31;
						OREG_RAM_D <= COMMAND;
						OREG_RAM_WE[0] <= 1;
						case (COMMAND) 
							8'h00: begin		//MSHON
								WAIT_CNT <= 16'd123 - 16'd87 - 16'd10 - 16'd2;
								WAIT_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h02: begin		//SSHON
								WAIT_CNT <= 16'd123 - 16'd87 - 16'd10 - 16'd2;
								WAIT_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h03: begin		//SSHOFF
								WAIT_CNT <= 16'd123 - 16'd87 - 16'd10 - 16'd2;
								WAIT_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h06: begin		//SNDON
								WAIT_CNT <= 16'd119 - 16'd87 - 16'd10 - 16'd2;
								WAIT_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h07: begin		//SNDOFF
								WAIT_CNT <= 16'd119 - 16'd87 - 16'd10 - 16'd2;
								WAIT_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h08: begin		//CDON
								WAIT_CNT <= 16'd131 - 16'd87 - 16'd10 - 16'd2;
								WAIT_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h09: begin		//CDOFF
								WAIT_CNT <= 16'd135 - 16'd87 - 16'd10 - 16'd2;
								WAIT_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h0A: begin		//
								WAIT_CNT <= 16'd130 - 16'd87 - 16'd2;
								WAIT_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h0B: begin		//
								WAIT_CNT <= 16'd142 - 16'd87 - 16'd2;
								WAIT_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h0D: begin		//SYSRES
								MSHRES_N <= 0;
								MSHNMI_N <= 0;
								SSHRES_N <= 0;
								SSHNMI_N <= 0;
								SNDRES_N <= 0;
								CDRES_N <= 0;
								SYSRES_N <= 0;
								WAIT_CNT <= 16'd120 - 16'd87 - 16'd2;
								WAIT_ST <= CS_RESET_START;
								COMM_ST <= CS_WAIT;
							end
							
							8'h0E: begin		//CKCHG352
								MSHNMI_N <= 1;
								SSHRES_N <= 0;
								SSHNMI_N <= 0;
								SNDRES_N <= 0;
								SYSRES_N <= 0;
								DOTSEL <= 1;
								WAIT_CNT <= 16'd120 - 16'd87 - 16'd2;
								WAIT_ST <= CS_RESET_START;
								COMM_ST <= CS_WAIT;
							end
							
							8'h0F: begin		//CKCHG320
								MSHNMI_N <= 1;
								SSHRES_N <= 0;
								SSHNMI_N <= 0;
								SNDRES_N <= 0;
								SYSRES_N <= 0;
								DOTSEL <= 0;
								WAIT_CNT <= 16'd120 - 16'd87 - 16'd2;
								WAIT_ST <= CS_RESET_START;
								COMM_ST <= CS_WAIT;
							end
							
							8'h10: begin		//INTBACK
								if (IREG[0][3:0] || IREG[1][3]) begin
									INTBACK_OPTIM_EN <= ~IREG[1][1] & IREG[1][3];
									if (IREG[0][3:0]) begin
										if (SETTIME_PEND) begin
											SETTIME_PEND <= 0;
											SETTIME_UPDATE <= 1;
										end
										WAIT_CNT <= 16'd996;
										COMM_ST <= CS_INTBACK_STAT;
									end else begin
										INTBACK_EXEC <= 1;
										INTBACK_PERI <= 1;
										CONT_PREV <= 0;
										COMM_ST <= IREG[2][3:0] ? CS_INTBACK_WAIT : CS_IDLE;
									end
									VBLANK_PEND <= 0;
									PMD[0] <= IREG[1][5:4];
									PMD[1] <= IREG[1][7:6];
								end else begin
									COMM_ST <= CS_END;
								end
							end
							
							8'h16: begin		//SETTIME
								WAIT_CNT <= 16'd470 - 16'd87 - 16'd2;
								WAIT_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h17: begin		//SETSMEM
								WAIT_CNT <= 16'd319 - 16'd87 - 16'd2;
								WAIT_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h18: begin		//NMIREQ
								WAIT_CNT <= 16'd130 - 16'd87;
								WAIT_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h19: begin		//RESENAB
								WAIT_CNT <= 16'd122 - 16'd87 - 16'd2;
								WAIT_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h1A: begin		//RESDISA
								WAIT_CNT <= 16'd122 - 16'd87 - 16'd2;
								WAIT_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h1E: begin		//
								WAIT_CNT <= 16'd170 - 16'd87 - 16'd2;
								WAIT_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h1F: begin		//
								WAIT_CNT <= 16'd7470 - 16'd87 - 16'd2;
								WAIT_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							default: begin
								WAIT_CNT <= 16'd110 - 16'd87 - 16'd2;
								WAIT_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
						endcase
					end
					
					CS_COMMAND_UNKNOWN: begin
						COMM_ST <= CS_END;
					end
					
					CS_RESET_START: begin
						WAIT_CNT <= 20'd406480 - 20'd120;
						WAIT_ST <= CS_RESET_EXEC;
						COMM_ST <= CS_WAIT;
					end
					
					CS_RESET_EXEC: begin
						case (COMMAND) 
							8'h0D: begin		//SYSRES
								CDRES_N <= 1;
								SNDRES_N <= 1;
								SYSRES_N <= 1;
							end
							
							8'h0E: begin		//CKCHG352
								MSHNMI_N <= 0;
								SYSRES_N <= 1;
							end
							
							8'h0F: begin		//CKCHG320
								MSHNMI_N <= 0;
								SYSRES_N <= 1;
							end
							
							default: ;
						endcase
						WAIT_CNT <= 20'd12-20'd2;
						WAIT_ST <= CS_EXEC;
						COMM_ST <= CS_WAIT;
					end
					
					CS_INTBACK_STAT: begin
						case (WAIT_CNT)
							16'd0996: if (INTBACK_OPTIM_EN) WAIT_CNT <= WAIT_CNT - 16'd30;
							16'd0932: begin OREG_RAM_WA <= 5'h00; OREG_RAM_D <= {STE,RESD,6'b000000};                                        OREG_RAM_WE <= '1; end
							16'd0908: begin OREG_RAM_WA <= 5'h01; OREG_RAM_D <= RTC_YEAR[15:8];                                              OREG_RAM_WE <= '1; end
							16'd0860: begin OREG_RAM_WA <= 5'h02; OREG_RAM_D <= RTC_YEAR[7:0];                                               OREG_RAM_WE <= '1; end
							16'd0812: begin OREG_RAM_WA <= 5'h03; OREG_RAM_D <= {RTC_DAY,RTC_MONTH};                                         OREG_RAM_WE <= '1; end
							16'd0764: begin OREG_RAM_WA <= 5'h04; OREG_RAM_D <= RTC_DAYS;                                                    OREG_RAM_WE <= '1; end
							16'd0716: begin OREG_RAM_WA <= 5'h05; OREG_RAM_D <= RTC_HOUR;                                                    OREG_RAM_WE <= '1; end
							16'd0668: begin OREG_RAM_WA <= 5'h06; OREG_RAM_D <= RTC_MIN;                                                     OREG_RAM_WE <= '1; end
							16'd0620: begin OREG_RAM_WA <= 5'h07; OREG_RAM_D <= RTC_SEC;                                                     OREG_RAM_WE <= '1; end
							16'd0571: begin OREG_RAM_WA <= 5'h08; OREG_RAM_D <= 8'h00;                                                       OREG_RAM_WE <= '1; end
							16'd0521: begin OREG_RAM_WA <= 5'h09; OREG_RAM_D <= {4'b0000,AC};                                                OREG_RAM_WE <= '1; end
							16'd0471: begin OREG_RAM_WA <= 5'h0A; OREG_RAM_D <= {1'b0,DOTSEL,1'b1,SSHRES_N,MSHNMI_N,1'b1,SYSRES_N,SNDRES_N}; OREG_RAM_WE <= '1; end
							16'd0421: begin OREG_RAM_WA <= 5'h0B; OREG_RAM_D <= {1'b0,CDRES_N,6'b000010};                                    OREG_RAM_WE <= '1; end
							16'd0368: begin OREG_RAM_WA <= 5'h0C; OREG_RAM_D <= SMEM_Q;                                                      OREG_RAM_WE <= '1; end
							16'd0314: begin OREG_RAM_WA <= 5'h0D; OREG_RAM_D <= SMEM_Q;                                                      OREG_RAM_WE <= '1; end
							16'd0259: begin OREG_RAM_WA <= 5'h0E; OREG_RAM_D <= SMEM_Q;                                                      OREG_RAM_WE <= '1; end
							16'd0202: begin OREG_RAM_WA <= 5'h0F; OREG_RAM_D <= SMEM_Q;                                                      OREG_RAM_WE <= '1; end
							16'd0087: if (!IREG[1][3]) WAIT_CNT <= WAIT_CNT - 16'd24;
							16'd0063: begin
								SR[7:4] <= {1'b0,1'b1,1'b0,~SRES_N};
								SR[3:0] <= 4'b1111;
								if (IREG[1][3]) begin
									INTBACK_EXEC <= 1;
									INTBACK_OPTIM_EN <= ~IREG[1][1];
									SR[5] <= 1;
								end
								CONT_PREV <= 0;
							end
							16'd0034: begin 
								MIRQ_N <= 0; 
								CHECK_CONTINUE <= 1;
								if (IREG[1][3]) begin
									WAIT_CNT <= '0;
									IRQ_EN <= 1;
									COMM_ST <= CS_IDLE;
								end
							end
							16'd0000: begin 
								IRQ_EN <= 1;
								COMM_ST <= CS_END;
							end
							default:;
						endcase
					end
					
					CS_EXEC: begin
						case (COMMAND) 
							8'h00: begin		//MSHON
								MSHRES_N <= 1;
								MSHNMI_N <= 1;//?
								WAIT_CNT <= 16'd10 - 16'd2;
								WAIT_ST <= CS_END;
								COMM_ST <= CS_WAIT;
							end
							
							8'h02: begin		//SSHON
								SSHRES_N <= 1;
								SSHNMI_N <= 1;//?
								WAIT_CNT <= 16'd10 - 16'd2;
								WAIT_ST <= CS_END;
								COMM_ST <= CS_WAIT;
							end
							
							8'h03: begin		//SSHOFF
								SSHRES_N <= 0;
								SSHNMI_N <= 1;//?
								WAIT_CNT <= 16'd10 - 16'd2;
								WAIT_ST <= CS_END;
								COMM_ST <= CS_WAIT;
							end
							
							8'h06: begin		//SNDON
								SNDRES_N <= 1;
								WAIT_CNT <= 16'd10 - 16'd2;
								WAIT_ST <= CS_END;
								COMM_ST <= CS_WAIT;
							end
							
							8'h07: begin		//SNDOFF
								SNDRES_N <= 0;
								WAIT_CNT <= 16'd10 - 16'd2;
								WAIT_ST <= CS_END;
								COMM_ST <= CS_WAIT;
							end
							
							8'h08: begin		//CDON
								CDRES_N <= 1;
								WAIT_CNT <= 16'd10 - 16'd2;
								WAIT_ST <= CS_END;
								COMM_ST <= CS_WAIT;
							end
							
							8'h09: begin		//CDOFF
								CDRES_N <= 0;
								WAIT_CNT <= 16'd10 - 16'd2;
								WAIT_ST <= CS_END;
								COMM_ST <= CS_WAIT;
							end
							
							8'h0D: begin		//SYSRES
								COMM_ST <= CS_END;
							end
							
							8'h0E: begin		//CKCHG352
								COMM_ST <= CS_END;
							end
							
							8'h0F: begin		//CKCHG320
								COMM_ST <= CS_END;
							end
							
							8'h10: begin		//INTBACK
								COMM_ST <= CS_END;
							end
							
							8'h16: begin		//SETTIME
								STE <= 1;
								SETTIME_PEND <= 1;
								SETTIME_EXEC <= 1;
								RTC_CLK_CNT <= 22'd0;
								COMM_ST <= CS_END;
							end
							
							8'h17: begin		//SETSMEM
								OREG_CNT <= OREG_CNT + 5'd1;
								if (OREG_CNT == 5'd3) begin
									COMM_ST <= CS_END;
								end
							end
							
							8'h18: begin		//NMIREQ
								MSHNMI_N <= 0;
								COMM_ST <= CS_END;
							end
							
							8'h19: begin		//RESENAB
								RESD <= 0;
								COMM_ST <= CS_END;
							end
							
							8'h1A: begin		//RESDISA
								RESD <= 1;
								COMM_ST <= CS_END;
							end
							
							default: begin
								COMM_ST <= CS_END;
							end
						endcase
						IRQ_EN <= 1;
					end
					
					CS_INTBACK_WAIT: begin
						if (INTBACK_VB_CNT == IREG[2][3:0]) begin
							COMM_ST <= CS_IDLE;
						end
					end
					
					CS_INTBACK_CONT: begin
						if (CONT != CONT_PREV) begin
							CONT_PREV <= CONT;
							CHECK_CONTINUE <= 0;
							WAIT_CNT <= 16'd483-16'd100-16'd2;
							WAIT_ST <= CS_INTBACK_CONT2;
							COMM_ST <= CS_WAIT;
						end else begin
							COMM_ST <= CS_IDLE;
						end
					end
					
					CS_INTBACK_CONT2: begin
						INTBACK_PERI <= 1;
						COMM_ST <= CS_IDLE;
					end
					
					CS_INTBACK_PERI: begin
						if (PERI_OREG_WRITE) begin
							OREG_CNT <= OREG_CNT + 5'd1;
							OREG_RAM_WA <= OREG_CNT;
							OREG_RAM_D <= PERI_OREG_DATA;
							OREG_RAM_WE <= '1;
						end
						if (PERI_OREG_END) begin
							OREG_RAM_WA <= 5'd31;
							OREG_RAM_D <= COMMAND;
							OREG_RAM_WE <= '1;
							
							COMM_ST <= CS_INTBACK_PERI2;
						end
						if (INTBACK_OPTIM_EN && !IRQV_N) begin
							COMM_ST <= CS_IDLE;
						end
					end
					
					CS_INTBACK_PERI2: begin
						SR[7:4] <= {1'b1,1'b1,1'b0,~SRES_N};
						SR[3:0] <= IREG[1][7:4];
						//CHECK_CONTINUE <= 1;//TODO: multiple requests for large peripheral data
						
						WAIT_CNT <= 16'd26-16'd2;
						WAIT_ST <= CS_INTBACK_PERI3;
						COMM_ST <= CS_WAIT;
					end
					
					CS_INTBACK_PERI3: begin
						MIRQ_N <= 0; 
						
						WAIT_CNT <= 16'd74-16'd2;
						WAIT_ST <= CS_INTBACK_BREAK;
						COMM_ST <= CS_WAIT;
					end
					
					CS_INTBACK_BREAK: begin
						INTBACK_EXEC <= 0;
						INTBACK_PERI <= 0;
						CHECK_CONTINUE <= 0;
						SF <= 0;
						COMM_ST <= CS_IDLE;
					end
					
					CS_END: begin
						SF <= 0;
						case (COMMAND) 
							8'h00: begin		//MSHON
								
							end
							
							8'h02: begin		//SSHON
								
							end
							
							8'h03: begin		//SSHOFF
								
							end
							
							8'h06: begin		//SNDON
								
							end
							
							8'h07: begin		//SNDOFF
								
							end
							
							8'h08: begin		//CDON
								
							end
							
							8'h09: begin		//CDOFF
								
							end
							
							8'h0D: begin		//SYSRES
								MSHRES_N <= 1;
								MSHNMI_N <= 1;
								SSHRES_N <= 1;
								SSHNMI_N <= 1;
							end
							
							8'h0E: begin		//CKCHG352
								
							end
							
							8'h0F: begin		//CKCHG320
								
							end
							
							8'h10: begin		//INTBACK
								if (INTBACK_EXEC) SF <= 1;
							end
							
							8'h16: begin		//SETTIME
							end
							
							8'h17: begin		//SETSMEM
								
							end
							
							8'h18: begin		//NMIREQ
								MSHNMI_N <= 1;
							end
							
							8'h19: begin		//RESENAB
								
							end
							
							8'h1A: begin		//RESDISA
								
							end
							
							default:;
						endcase
						COMM_ST <= CS_IDLE;
					end
				endcase
				
//				if (VBIN_PEND && IRQ_EN) begin
//					VBIN_PEND <= 0;
//					RET_WAIT_CNT <= WAIT_CNT;
//					RET_WAIT_ST <= WAIT_ST;
//					RET_COMM_ST <= COMM_ST;
//					WAIT_CNT <= /*16'd174*/16'd2-16'd2 + (DBG_EXT[0] ? 16'd10 : DBG_EXT[1] ? 16'd50 : DBG_EXT[2] ? 16'd100 : 16'd0);
//					WAIT_ST <= CS_VBIN;
//					COMM_ST <= CS_WAIT;
//				end 
//				if (VBOUT_PEND && IRQ_EN) begin
//					VBOUT_PEND <= 0;
//					RET_WAIT_CNT <= WAIT_CNT;
//					RET_WAIT_ST <= WAIT_ST;
//					RET_COMM_ST <= COMM_ST;
//					WAIT_CNT <= /*16'd70*/16'd2-16'd2 + (DBG_EXT[0] ? 16'd10 : DBG_EXT[1] ? 16'd30 : DBG_EXT[2] ? 16'd70 : 16'd0);
//					WAIT_ST <= CS_VBIN;
//					COMM_ST <= CS_WAIT;
//				end 
				
				if (!IRQV_N && IRQV_N_OLD) begin
					if (INTBACK_VB_CNT == IREG[2][3:0]) begin
						VBLANK_PEND <= 1;
					end else if (INTBACK_EXEC) begin
						INTBACK_VB_CNT <= INTBACK_VB_CNT + 4'd1;
					end
				end
			
			
				//Peripheral ports
				PERI_OREG_WRITE <= 0;
				PERI_OREG_END <= 0;
				
				if (PORT_DELAY) PORT_DELAY <= PORT_DELAY - 9'd1;
				if (!PORT_DELAY) 
				case (PORT_ST)
					PS_IDLE: begin
					end
					
					PS_START: begin
						if (PMD[PORT_NUM] == 2'b11) begin
							PORT_ST <= PS_NEXT;
						end else if (!IOSEL[PORT_NUM]) begin
							PDR_O[PORT_NUM] <= '1; 
							PORT_DELAY <= !PORT_NUM ? 9'd224-9'd1 : 9'd245-9'd1;
							PORT_ST <= PS_ID1_0;
						end else begin
							PERI_OREG_DATA <= 8'hA0;//8'hF0; //temporary hack
							PERI_OREG_WRITE <= 1;
							PORT_ST <= PS_NEXT;
						end
					end
					
					PS_ID1_0: begin
						DDR[PORT_NUM][`THTR] <= 2'b10;
						PDR_O[PORT_NUM][`THTR] <= 2'b11;
						PORT_DELAY <= 9'd43-9'd2;
						PORT_ST <= PS_ID1_1;
					end
					
					PS_ID1_1: begin
						JOY_DATA[3:0] <= PDR_I[PORT_NUM][3:0];
						PORT_ST <= PS_ID1_2;
					end
					
					PS_ID1_2: begin
						DDR[PORT_NUM][`THTR] <= 2'b10;
						PDR_O[PORT_NUM][`THTR] <= 2'b01;
						PORT_DELAY <= 9'd44-9'd2;
						PORT_ST <= PS_ID1_3;
					end
					
					PS_ID1_3: begin
						JOY_DATA[15:12] <= PDR_I[PORT_NUM][3:0];
						PORT_ST <= PS_ID1_4;
					end
					
					PS_ID1_4: begin
						MD_ID <= {|JOY_DATA[3:2], |JOY_DATA[1:0], |JOY_DATA[15:14], |JOY_DATA[13:12]};
						PORT_ST <= PS_TYPE_SEL;
					end
					
					PS_TYPE_SEL: begin
						if (MD_ID == 4'hB)
							PORT_ST <= PS_DPAD_0;
//						else if (MD_ID == 4'hD)
//							PORT_ST <= PS_MD_0;
						else if (MD_ID == 4'h3)
							PORT_ST <= PS_MOUSE_0;
						else if (MD_ID == 4'h5)
							PORT_ST <= PS_ID5_0;
						else if (MD_ID == 4'hF || 4'hA)
							PORT_ST <= PS_NOTHING_STUNNER;
						else 
							PORT_ST <= PS_END;
					end
					
					//Nothing Detected or Stunner
					PS_NOTHING_STUNNER: begin
						PERI_OREG_DATA <= {MD_ID,4'b0000};
						PERI_OREG_WRITE <= 1;
						PORT_ST <= PS_NEXT;
					end	
					
					//Standart PAD
					PS_DPAD_0: begin
						DDR[PORT_NUM][`THTR] <= 2'b11;
						PDR_O[PORT_NUM][`THTR] <= 2'b10;
						PORT_DELAY <= 9'd44-9'd2;
						PORT_ST <= PS_DPAD_1;
					end
					
					PS_DPAD_1: begin
						JOY_DATA[11:8] <= PDR_I[PORT_NUM][3:0];
						PORT_ST <= PS_DPAD_2;
					end
					
					PS_DPAD_2: begin
						DDR[PORT_NUM][`THTR] <= 2'b11;
						PDR_O[PORT_NUM][`THTR] <= 2'b00;
						PORT_DELAY <= 9'd44-9'd2;
						PORT_ST <= PS_DPAD_3;
					end
					
					PS_DPAD_3: begin
						JOY_DATA[7:4] <= PDR_I[PORT_NUM][3:0];
						PORT_ST <= PS_DPAD_4;
					end
					
					PS_DPAD_4: begin
						PERI_OREG_DATA <= 8'hF1;
						PERI_OREG_WRITE <= 1;
						PORT_DELAY <= 9'd43-9'd2;
						PORT_ST <= PS_DPAD_5;
					end
					
					PS_DPAD_5: begin
						PERI_OREG_DATA <= 8'h02;
						PERI_OREG_WRITE <= 1;
						PORT_DELAY <= 9'd43-9'd2;
						PORT_ST <= PS_DPAD_6;
					end
					
					PS_DPAD_6: begin
						PERI_OREG_DATA <= JOY_DATA[15:8];
						PERI_OREG_WRITE <= 1;
						PORT_DELAY <= 9'd43-9'd2;
						PORT_ST <= PS_DPAD_7;
					end
					
					PS_DPAD_7: begin
						PERI_OREG_DATA <= {JOY_DATA[7:3],3'b111};
						PERI_OREG_WRITE <= 1;
						PORT_DELAY <= 9'd171+9'd43-9'd2;
						PORT_ST <= PS_NEXT;
					end
					
					//Mouse,Wheel(Arcade racer)
					PS_MOUSE_0: begin
						DDR[PORT_NUM][`THTR] <= 2'b11;
						PDR_O[PORT_NUM][`THTR] <= 2'b00;
						PORT_DELAY <= 9'd60;
						PORT_ST <= PS_MOUSE_1;
					end
					
					PS_MOUSE_1: begin
						if (!PDR_I[PORT_NUM][4]) begin
							ID2[7:4] <= PDR_I[PORT_NUM][3:0];
							PORT_ST <= PS_MOUSE_2;
						end
					end
					
					PS_MOUSE_2: begin
						DDR[PORT_NUM][`THTR] <= 2'b11;
						PDR_O[PORT_NUM][`THTR] <= 2'b01;
						PORT_DELAY <= 9'd60;
						PORT_ST <= PS_MOUSE_3;
					end
					
					PS_MOUSE_3: begin
						if (PDR_I[PORT_NUM][4]) begin
							ID2[3:0] <= PDR_I[PORT_NUM][3:0];
							PORT_ST <= PS_MOUSE_4;
						end
					end
					
					PS_MOUSE_4: begin
						PERI_OREG_DATA <= 8'hF1;
						PERI_OREG_WRITE <= 1;
						PORT_ST <= PS_MOUSE_5;
					end
					
					PS_MOUSE_5: begin
						PERI_OREG_DATA <= 8'hE3;
						PERI_OREG_WRITE <= 1;
						PORT_DATA_CNT <= 4'd3 - 4'd1;
						PORT_ST <= PS_MOUSE_6;
					end
					
					PS_MOUSE_6: begin
						DDR[PORT_NUM][`THTR] <= 2'b11;
						PDR_O[PORT_NUM][`THTR] <= 2'b00;
						PORT_DELAY <= 9'd60;
						PORT_ST <= PS_MOUSE_7;
					end
					
					PS_MOUSE_7: begin
						if (!PDR_I[PORT_NUM][4]) begin
							JOY_DATA[7:4] <= PDR_I[PORT_NUM][3:0];
							PORT_ST <= PS_MOUSE_8;
						end
					end
					
					PS_MOUSE_8: begin
						DDR[PORT_NUM][`THTR] <= 2'b11;
						PDR_O[PORT_NUM][`THTR] <= 2'b01;
						PORT_DELAY <= 9'd60;
						PORT_ST <= PS_MOUSE_9;
					end
					
					PS_MOUSE_9: begin
						if (PDR_I[PORT_NUM][4]) begin
							JOY_DATA[3:0] <= PDR_I[PORT_NUM][3:0];
							PORT_ST <= PS_MOUSE_10;
						end
					end
					
					PS_MOUSE_10: begin
						PERI_OREG_DATA <= JOY_DATA[7:0];
						PERI_OREG_WRITE <= 1;
						PORT_DATA_CNT <= PORT_DATA_CNT - 4'd1; 
						PORT_ST <= !PORT_DATA_CNT ? PS_NEXT : PS_MOUSE_6;
					end
					
					//Analog joystick, 3D Pad
					PS_ID5_0: begin
						DDR[PORT_NUM][`THTR] <= 2'b11;
						PDR_O[PORT_NUM][`THTR] <= 2'b00;
						PORT_DELAY <= 9'd60;
						PORT_ST <= PS_ID5_1;
					end
					
					PS_ID5_1: begin
						if (!PDR_I[PORT_NUM][4]) begin
							ID2[7:4] <= PDR_I[PORT_NUM][3:0];
							PORT_ST <= PS_ID5_2;
						end
					end
					
					PS_ID5_2: begin
						DDR[PORT_NUM][`THTR] <= 2'b11;
						PDR_O[PORT_NUM][`THTR] <= 2'b01;
						PORT_DELAY <= 9'd60;
						PORT_ST <= PS_ID5_3;
					end
					
					PS_ID5_3: begin
						if (PDR_I[PORT_NUM][4]) begin
							ID2[3:0] <= PDR_I[PORT_NUM][3:0];
							PORT_ST <= PS_ID5_4;
						end
					end
					
					PS_ID5_4: begin
						if (ID2 == 8'h02 || ID2 == 8'h13 || ID2 == 8'h15 || ID2 == 8'h16 || ID2 == 8'h19) begin//8'h13-wheel,8'h15-mission stick,8'h16-3dpad,8'h19-dual mission stick
							PERI_OREG_DATA <= 8'hF1;
							PERI_OREG_WRITE <= 1;
							PORT_ST <= PS_ANALOG_5;
						end else begin //TODO: keyboard,multitap
							PORT_ST <= PS_NEXT;
						end
					end
					
					PS_ANALOG_5: begin
						PERI_OREG_DATA <= ID2;
						PERI_OREG_WRITE <= 1;
						PORT_DATA_CNT <= ID2[3:0] - 4'd1;
						PORT_ST <= PS_ANALOG_6;
					end
					
					PS_ANALOG_6: begin
						DDR[PORT_NUM][`THTR] <= 2'b11;
						PDR_O[PORT_NUM][`THTR] <= 2'b00;
						PORT_DELAY <= 9'd60;
						PORT_ST <= PS_ANALOG_7;
					end
					
					PS_ANALOG_7: begin
						if (!PDR_I[PORT_NUM][4]) begin
							JOY_DATA[7:4] <= PDR_I[PORT_NUM][3:0];
							PORT_ST <= PS_ANALOG_8;
						end
					end
					
					PS_ANALOG_8: begin
						DDR[PORT_NUM][`THTR] <= 2'b11;
						PDR_O[PORT_NUM][`THTR] <= 2'b01;
						PORT_DELAY <= 9'd60;
						PORT_ST <= PS_ANALOG_9;
					end
					
					PS_ANALOG_9: begin
						if (PDR_I[PORT_NUM][4]) begin
							JOY_DATA[3:0] <= PDR_I[PORT_NUM][3:0];
							PORT_ST <= PS_ANALOG_10;
						end
					end
					
					PS_ANALOG_10: begin
						PERI_OREG_DATA <= JOY_DATA[7:0];
						PERI_OREG_WRITE <= 1;
						PORT_DATA_CNT <= PORT_DATA_CNT - 4'd1; 
						PORT_ST <= !PORT_DATA_CNT ? PS_NEXT : PS_ANALOG_6;
					end
					
					
					PS_NEXT: begin
						DDR[PORT_NUM][`THTR] <= 2'b11;
						PDR_O[PORT_NUM][`THTR] <= 2'b11;
							
						PORT_NUM <= ~PORT_NUM;
						if (!PORT_NUM) begin
							PORT_ST <= PS_START;
						end else begin
							PORT_ST <= PS_END;
						end
					end

					PS_END: begin
						PERI_OREG_END <= 1;
						PORT_ST <= PS_IDLE;
					end
				endcase
				
				if (JOY_START) begin
					PORT_NUM <= 0;
					PORT_ST <= PS_START;
				end
			end
			
			RW_N_OLD <= RW_N;
			if (!RW_N && RW_N_OLD && !CS_N) begin
				case ({A,1'b1})
					7'h01: begin 
						{CONT,BREAK} <= DI[7:6];
						IREG[0] <= DI;
					end
					7'h03: IREG[1] <= DI;
					7'h05: IREG[2] <= DI;
					7'h07: IREG[3] <= DI;
					7'h09: IREG[4] <= DI;
					7'h0B: IREG[5] <= DI;
					7'h0D: IREG[6] <= DI;
					7'h1F: begin COMREG <= DI; COMREG_SET <= 1; end
					7'h63: SF <= 1;
					7'h75: if (IOSEL[0]) PDR_O[0] <= DI;
					7'h77: if (IOSEL[1]) PDR_O[1] <= DI;
					7'h79: DDR[0] <= DI[6:0];
					7'h7B: DDR[1] <= DI[6:0];
					7'h7D: IOSEL <= DI[1:0];
					7'h7F: EXLE <= DI[1:0];
					default:;
				endcase
				IO_BUF <= DI;
			end 
			
			CS_N_OLD <= CS_N;
			if (!CS_N && CS_N_OLD && RW_N) begin
				if ({A,1'b1} >= 7'h21 && {A,1'b1} <= 7'h5F)
					REG_DO <= OREG_RAM_Q;
				else
					case ({A,1'b1})
						7'h61: REG_DO <= SR;
						7'h63: REG_DO <= {IO_BUF[7:1],SF};
						7'h75: REG_DO <= {IO_BUF[7],PDR1I};
						7'h77: REG_DO <= {IO_BUF[7],PDR2I};
						default: REG_DO <= IO_BUF;
					endcase
			end
		end
	end
	
	assign PDR1O = PDR_O[0][6:0];
	assign PDR2O = PDR_O[1][6:0];
	assign DDR1 = DDR[0];
	assign DDR2 = DDR[1];
	assign EXL_N = (~EXLE[0] | PDR1I[6]) & (~EXLE[1] | PDR2I[6]);
	
	bit  [ 7: 0] SMEM_Q;
	wire [ 7: 0] SMEM_RADDR = OREG_RAM_WA[1:0] + 2'h1;
	SMPC_SMEM SMEM (CLK, OREG_CNT[1:0], IREG[OREG_CNT[2:0]], (COMM_ST == CS_EXEC && COMMAND == 8'h17 && CE), SMEM_RADDR, SMEM_Q);
	
	bit  [ 4: 0] OREG_RAM_WA;
	bit  [ 7: 0] OREG_RAM_D;
	bit  [ 1: 0] OREG_RAM_WE;
	bit  [ 7: 0] OREG_RAM_Q;
	SMPC_OREG_RAM OREG_RAM_H (CLK, OREG_RAM_WA, OREG_RAM_D[7:4], OREG_RAM_WE[1], (A - 6'h10), OREG_RAM_Q[7:4]);
	SMPC_OREG_RAM OREG_RAM_L (CLK, OREG_RAM_WA, OREG_RAM_D[3:0], OREG_RAM_WE[0], (A - 6'h10), OREG_RAM_Q[3:0]);
	
	assign DO = REG_DO;

endmodule


module SMPC_OREG_RAM
(
	input        CLK,
	input  [4:0] WADDR,
	input  [3:0] DATA,
	input        WREN,
	input  [4:0] RADDR,
	output [3:0] Q
);

	wire [3:0] sub_wire0;
	
	altdpram	altdpram_component (
				.data (DATA),
				.inclock (CLK),
				.rdaddress (RADDR),
				.wraddress (WADDR),
				.wren (WREN),
				.q (sub_wire0),
				.aclr (1'b0),
				.byteena (1'b1),
				.inclocken (1'b1),
				.rdaddressstall (1'b0),
				.rden (1'b1),
//				.sclr (1'b0),
				.wraddressstall (1'b0));
	defparam
		altdpram_component.indata_aclr = "OFF",
		altdpram_component.indata_reg = "INCLOCK",
		altdpram_component.intended_device_family = "Cyclone V",
		altdpram_component.lpm_type = "altdpram",
		altdpram_component.outdata_aclr = "OFF",
		altdpram_component.outdata_reg = "UNREGISTERED",
		altdpram_component.ram_block_type = "MLAB",
		altdpram_component.rdaddress_aclr = "OFF",
		altdpram_component.rdaddress_reg = "UNREGISTERED",
		altdpram_component.rdcontrol_aclr = "OFF",
		altdpram_component.rdcontrol_reg = "UNREGISTERED",
		altdpram_component.read_during_write_mode_mixed_ports = "CONSTRAINED_DONT_CARE",
		altdpram_component.width = 4,
		altdpram_component.widthad = 5,
		altdpram_component.width_byteena = 1,
		altdpram_component.wraddress_aclr = "OFF",
		altdpram_component.wraddress_reg = "INCLOCK",
		altdpram_component.wrcontrol_aclr = "OFF",
		altdpram_component.wrcontrol_reg = "INCLOCK";
		
	assign Q = sub_wire0;
	
endmodule


module SMPC_SMEM
(
	input        CLK,
	input  [1:0] WADDR,
	input  [7:0] DATA,
	input        WREN,
	input  [1:0] RADDR,
	output [7:0] Q
);

	wire [7:0] sub_wire0;
	
	altdpram	altdpram_component (
				.data (DATA),
				.inclock (CLK),
				.rdaddress (RADDR),
				.wraddress (WADDR),
				.wren (WREN),
				.q (sub_wire0),
				.aclr (1'b0),
				.byteena (1'b1),
				.inclocken (1'b1),
				.rdaddressstall (1'b0),
				.rden (1'b1),
//				.sclr (1'b0),
				.wraddressstall (1'b0));
	defparam
		altdpram_component.indata_aclr = "OFF",
		altdpram_component.indata_reg = "INCLOCK",
		altdpram_component.intended_device_family = "Cyclone V",
		altdpram_component.lpm_type = "altdpram",
		altdpram_component.outdata_aclr = "OFF",
		altdpram_component.outdata_reg = "UNREGISTERED",
		altdpram_component.ram_block_type = "MLAB",
		altdpram_component.rdaddress_aclr = "OFF",
		altdpram_component.rdaddress_reg = "UNREGISTERED",
		altdpram_component.rdcontrol_aclr = "OFF",
		altdpram_component.rdcontrol_reg = "UNREGISTERED",
		altdpram_component.read_during_write_mode_mixed_ports = "CONSTRAINED_DONT_CARE",
		altdpram_component.width = 8,
		altdpram_component.widthad = 2,
		altdpram_component.width_byteena = 1,
		altdpram_component.wraddress_aclr = "OFF",
		altdpram_component.wraddress_reg = "INCLOCK",
		altdpram_component.wrcontrol_aclr = "OFF",
		altdpram_component.wrcontrol_reg = "INCLOCK";
		
	assign Q = sub_wire0;
	
endmodule

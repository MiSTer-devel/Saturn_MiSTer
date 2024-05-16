module SMPC (
	input              CLK,
	input              RST_N,
	input              CE,
	
	input              MRES_N,
	input              TIME_SET,
	
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
	bit  [7 : 0] COMREG;
	bit  [7 : 0] SR;
	bit          SF;
	bit  [7 : 0] IREG[7];
	
	wire [6 : 0] PDR_I[2] = '{PDR1I,PDR2I};
	bit  [7 : 0] PDR_O[2];
	bit  [6 : 0] DDR[2];
	bit  [1 : 0] IOSEL;
	bit  [1 : 0] EXLE;
	
	bit          RESD;
	bit          STE;
	
	bit  [ 7: 0] SEC;
	bit  [ 7: 0] MIN;
	bit  [ 7: 0] HOUR;
	bit  [ 7: 0] DAYS;
	bit  [ 3: 0] DAY;
	bit  [ 3: 0] MONTH;
	bit  [15: 0] YEAR;
	
//	bit  [ 7: 0] SMEM[4];

	parameter SR_PDE = 2;
	parameter SR_RESB = 3;
	
	typedef enum bit [3:0] {
		CS_IDLE,
		CS_WAIT, 
		CS_COMMAND,
		CS_RESET, 
		CS_RESET_WAIT,
		CS_EXEC,
		CS_INTBACK_PERI,
		CS_INTBACK_BREAK, 
		CS_END
	} CommExecState_t;
	CommExecState_t COMM_ST;
	
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
		PS_NEXT,
		PS_END
	} PortState_t;
	PortState_t PORT_ST;
	

	always @(posedge CLK or negedge RST_N) begin
		bit [21: 0] CLK_CNT;
		bit         SEC_CLK,MIN_CLK,HOUR_CLK,DAYS_CLK,MONTH_CLK,YEAR_CLK;
		
		if (!RST_N) begin
			SEC <= 8'h00;
			MIN <= 8'h00;
			HOUR <= 8'h00;
			DAYS <= 8'h01;
			{DAY,MONTH} <= 8'h01;
			YEAR <= 16'h2024;
		end else if (COMM_ST == CS_EXEC && COMREG == 8'h16) begin
`ifndef DEBUG
			SEC <= IREG[6];
			MIN <= IREG[5];
			HOUR <= IREG[4];
			DAYS <= IREG[3];
			{DAY,MONTH} <= IREG[2];
			YEAR <= {IREG[0],IREG[1]};
`endif
		end else if (CE) begin
`ifndef DEBUG
			SEC_CLK <= 0;
			MIN_CLK <= 0;
			HOUR_CLK <= 0;
			DAYS_CLK <= 0;
			MONTH_CLK <= 0;
			YEAR_CLK <= 0;
				
			CLK_CNT <= CLK_CNT + 3'd1;
			if (CLK_CNT == 22'd4000000-1) begin
				CLK_CNT <= 22'd0;
				SEC_CLK <= 1;
			end
			
			if (SEC_CLK) begin
				SEC[3:0] <= SEC[3:0] + 4'd1;
				if (SEC[3:0] == 4'd9) begin
					SEC[3:0] <= 4'd0;
					SEC[7:4] <= SEC[7:4] + 4'd1;
					if (SEC[7:4] == 4'd5) begin
						SEC[7:4] <= 4'd0;
						MIN_CLK <= 1;
					end
				end
			end
			if (MIN_CLK) begin
				MIN[3:0] <= MIN[3:0] + 4'd1;
				if (MIN[3:0] == 4'd9) begin
					MIN[3:0] <= 4'd0;
					MIN[7:4] <= MIN[7:4] + 4'd1;
					if (MIN[7:4] == 4'd5) begin
						MIN[7:4] <= 4'd0;
						HOUR_CLK <= 1;
					end
				end
			end
			if (HOUR_CLK) begin
				HOUR[3:0] <= HOUR[3:0] + 4'd1;
				if (HOUR[3:0] == 4'd9) begin
					HOUR[3:0] <= 4'd0;
					HOUR[7:4] <= HOUR[7:4] + 4'd1;
				end
				else if (HOUR == 8'h23) begin
					HOUR <= 8'h00;
					DAYS_CLK <= 1;
				end
			end
			if (DAYS_CLK) begin
				DAYS[3:0] <= DAYS[3:0] + 4'd1;
				if (DAYS[3:0] == 4'd9) begin
					DAYS[7:4] <= DAYS[7:4] + 4'd1;
					DAYS[3:0] <= 4'd0;
				end
				else if ((DAYS == 8'h28 && MONTH == 4'd2) || 
							(DAYS == 8'h30 && MONTH == 4'd4) || 
							(DAYS == 8'h30 && MONTH == 4'd6) || 
							(DAYS == 8'h30 && MONTH == 4'd9) || 
							(DAYS == 8'h30 && MONTH == 4'd11) || 
							 DAYS == 8'h31) begin
					DAYS <= 8'h01;
					MONTH_CLK <= 1;
				end
			end
			if (MONTH_CLK) begin
				MONTH <= MONTH + 4'd1;
				if (MONTH == 4'd12) begin
					MONTH <= 4'd1;
					YEAR_CLK <= 1;
				end
			end
			if (YEAR_CLK) begin
				YEAR <= YEAR + 16'd1;
			end
`endif
		end
	end
	
	
	bit [ 7: 0] REG_DO;
	bit [ 4: 0] OREG_CNT;
	bit [ 7: 0] OREG_DATA;
	bit         OREG_WRITE;
	bit         OREG_END;
	always @(posedge CLK or negedge RST_N) begin
		CommExecState_t NEXT_COMM_ST;
		bit         VBLANK_PEND;
		bit         COMREG_SET;
		bit         INTBACK_BREAK_PEND;
		bit         RW_N_OLD;
		bit         CS_N_OLD;
		bit         IRQV_N_OLD;
		bit [ 1: 0] FRAME_CNT;
		bit [15: 0] WAIT_CNT;
		bit [15: 0] INTBACK_WAIT_CNT;
		bit         SRES_EXEC;
		bit         INTBACK_EXEC;
		bit         INTBACK_PERI;
		bit         INTBACK_OPTIM_EN;
		bit         INTBACK_OPTIM_COND;
		bit         CHECK_CONTINUE;
		bit         BREAK,CONT,CONT_PREV;
		
		bit [15: 0] PORT_DELAY;
		bit         JOY_START;
		bit [15: 0] JOY_DATA;
		bit         PORT_NUM;
		bit [ 3: 0] PORT_DATA_CNT;
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
			SRES_EXEC <= 0;
			INTBACK_EXEC <= 0;
			INTBACK_PERI <= 0;
			BREAK <= 0;
			CONT <= 0;
			CONT_PREV <= 0;
			INTBACK_BREAK_PEND <= 0;
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
			INTBACK_EXEC <= 0;
			INTBACK_PERI <= 0;
			INTBACK_OPTIM_COND <= 0;
			BREAK <= 0;
			CONT <= 0;
			CONT_PREV <= 0;
			CHECK_CONTINUE <= 0;
			INTBACK_BREAK_PEND <= 0;
			VBLANK_PEND <= 0;
			
			PORT_ST <= PS_IDLE;
		end else begin
			OREG_RAM_WE <= 0;
			
			if (CE) begin
				IRQV_N_OLD <= IRQV_N;
				
				if (WAIT_CNT) WAIT_CNT <= WAIT_CNT - 16'd1;
				
				if (!SRES_N && !RESD && !SRES_EXEC) begin
					MSHNMI_N <= 0;
					SSHNMI_N <= 0;
					WAIT_CNT <= 16'd60000;
					SRES_EXEC <= 1;
				end else if (SRES_EXEC && !WAIT_CNT) begin
					MSHNMI_N <= 1;
					SSHNMI_N <= 1;
				end
				
				if (!IRQV_N) begin
					INTBACK_OPTIM_COND <= 0;
					INTBACK_WAIT_CNT <= 16'd51700;
				end
				else if (!INTBACK_WAIT_CNT) begin
					INTBACK_OPTIM_COND <= 1;
				end
				else begin
					INTBACK_WAIT_CNT <= INTBACK_WAIT_CNT - 16'd1;
				end
				
				SR[4:0] <= {~SRES_N,IREG[1][7:4]};
				
				JOY_START <= 0;
				case (COMM_ST)
					CS_IDLE: begin
						if (INTBACK_EXEC && (INTBACK_BREAK_PEND || VBLANK_PEND)) begin
							INTBACK_BREAK_PEND <= 0;
							WAIT_CNT <= 16'd70;
							NEXT_COMM_ST <= CS_INTBACK_BREAK;
							COMM_ST <= CS_WAIT;
						end 
						else if (INTBACK_PERI && ((INTBACK_OPTIM_EN && INTBACK_OPTIM_COND) || !INTBACK_OPTIM_EN) && IRQV_N && !SRES_EXEC) begin
							OREG_CNT <= '0;
							WAIT_CNT <= INTBACK_OPTIM_EN ? 16'd70 : 16'd2000;
							NEXT_COMM_ST <= CS_INTBACK_PERI;
							COMM_ST <= CS_WAIT;
						end 
						else if (COMREG_SET && !SRES_EXEC) begin
							COMREG_SET <= 0;
							OREG_CNT <= '0;
							WAIT_CNT <= 16'd90;
							NEXT_COMM_ST <= CS_COMMAND;
							COMM_ST <= CS_WAIT;
						end
						VBLANK_PEND <= 0;
						MIRQ_N <= 1;
						
						if (CHECK_CONTINUE) begin
							if (BREAK) begin
								INTBACK_BREAK_PEND <= 1;
								BREAK <= 0;
								CHECK_CONTINUE <= 0;
							end
							else if (CONT != CONT_PREV) begin
								INTBACK_PERI <= 1;
								SF <= 1;
								CONT_PREV <= CONT;
								CHECK_CONTINUE <= 0;
							end
						end
					end
					
					CS_WAIT: begin
						if (!WAIT_CNT) begin
							if (NEXT_COMM_ST == CS_INTBACK_PERI) JOY_START <= 1;
							COMM_ST <= NEXT_COMM_ST;
						end
					end
					
					CS_COMMAND: begin
						case (COMREG) 
							8'h00: begin		//MSHON
								WAIT_CNT <= 16'd120;
								NEXT_COMM_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h02: begin		//SSHON
								WAIT_CNT <= 16'd120;
								NEXT_COMM_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h03: begin		//SSHOFF
								WAIT_CNT <= 16'd120;
								NEXT_COMM_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h06: begin		//SNDON
								WAIT_CNT <= 16'd120;
								NEXT_COMM_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h07: begin		//SNDOFF
								WAIT_CNT <= 16'd120;
								NEXT_COMM_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h08: begin		//CDON
								WAIT_CNT <= 16'd159;
								NEXT_COMM_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h09: begin		//CDOFF
								WAIT_CNT <= 16'd159;
								NEXT_COMM_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h0D: begin		//SYSRES
								if (IRQV_N && !IRQV_N_OLD) begin
									MSHRES_N <= 0;
									MSHNMI_N <= 0;
									SSHRES_N <= 0;
									SSHNMI_N <= 0;
									SNDRES_N <= 0;
									CDRES_N <= 0;
									SYSRES_N <= 0;
									COMM_ST <= CS_RESET;
								end
							end
							
							8'h0E: begin		//CKCHG352
								if (IRQV_N && !IRQV_N_OLD) begin
									SSHRES_N <= 0;
									SSHNMI_N <= 0;
									SNDRES_N <= 0;
									SYSRES_N <= 0;
									DOTSEL <= 1;
									COMM_ST <= CS_RESET;
								end
							end
							
							8'h0F: begin		//CKCHG320
								if (IRQV_N && !IRQV_N_OLD) begin
									SSHRES_N <= 0;
									SSHNMI_N <= 0;
									SNDRES_N <= 0;
									SYSRES_N <= 0;
									DOTSEL <= 0;
									COMM_ST <= CS_RESET;
								end
							end
							
							8'h10: begin		//INTBACK
								if (IREG[2] == 8'hF0 && (IREG[0][0] || IREG[1][3])) begin
									if (IREG[0][0]) begin
										WAIT_CNT <= 16'd800;
										NEXT_COMM_ST <= CS_EXEC;
										COMM_ST <= CS_WAIT;
									end else begin
										INTBACK_EXEC <= 1;
										INTBACK_PERI <= 1;
										INTBACK_OPTIM_EN <= ~IREG[1][1];
										CONT_PREV <= 0;
										COMM_ST <= CS_IDLE;
									end
								end else begin
									COMM_ST <= CS_END;
								end
							end
							
							8'h16: begin		//SETTIME
								WAIT_CNT <= 16'd279;
								NEXT_COMM_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h17: begin		//SETSMEM
								WAIT_CNT <= 16'd159;
								NEXT_COMM_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h18: begin		//NMIREQ
								WAIT_CNT <= 16'd127;
								NEXT_COMM_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h19: begin		//RESENAB
								WAIT_CNT <= 16'd127;
								NEXT_COMM_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							8'h1A: begin		//RESDISA
								WAIT_CNT <= 16'd127;
								NEXT_COMM_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
							
							default: begin
								COMM_ST <= CS_EXEC;
							end
						endcase
					end
					
					CS_RESET: begin
						case (COMREG) 
							8'h0D: begin		//SYSRES
								CDRES_N <= 1;
								SNDRES_N <= 1;
								SYSRES_N <= 1;
							end
							
							8'h0E: begin		//CKCHG352
								SYSRES_N <= 1;
							end
							
							8'h0F: begin		//CKCHG320
								SYSRES_N <= 1;
							end
							
							default: ;
						endcase
						COMM_ST <= CS_RESET_WAIT;
					end
					
					CS_RESET_WAIT: begin
						if (IRQV_N && !IRQV_N_OLD) begin
							FRAME_CNT <= FRAME_CNT + 2'd1;
							if (FRAME_CNT == 2'd2) begin
								FRAME_CNT <= '0;
								WAIT_CNT <= 16'd32700;
								NEXT_COMM_ST <= CS_EXEC;
								COMM_ST <= CS_WAIT;
							end
						end
					end
					
					CS_EXEC: begin
						OREG_RAM_WA <= 5'd31;
						OREG_RAM_D <= COMREG;
						OREG_RAM_WE <= 1;
						case (COMREG) 
							8'h00: begin		//MSHON
								MSHRES_N <= 1;
								MSHNMI_N <= 1;//?
								COMM_ST <= CS_END;
							end
							
							8'h02: begin		//SSHON
								SSHRES_N <= 1;
								SSHNMI_N <= 1;//?
								COMM_ST <= CS_END;
							end
							
							8'h03: begin		//SSHOFF
								SSHRES_N <= 0;
								SSHNMI_N <= 1;//?
								COMM_ST <= CS_END;
							end
							
							8'h06: begin		//SNDON
								SNDRES_N <= 1;
								COMM_ST <= CS_END;
							end
							
							8'h07: begin		//SNDOFF
								SNDRES_N <= 0;
								COMM_ST <= CS_END;
							end
							
							8'h08: begin		//CDON
								CDRES_N <= 1;
								COMM_ST <= CS_END;
							end
							
							8'h09: begin		//CDOFF
								CDRES_N <= 0;
								COMM_ST <= CS_END;
							end
							
							8'h0D: begin		//SYSRES
								COMM_ST <= CS_END;
							end
							
							8'h0E: begin		//CKCHG352
								MSHNMI_N <= 0;
								COMM_ST <= CS_END;
							end
							
							8'h0F: begin		//CKCHG320
								MSHNMI_N <= 0;
								COMM_ST <= CS_END;
							end
							
							8'h10: begin		//INTBACK
								if (!INTBACK_EXEC) begin
									OREG_RAM_WA <= OREG_CNT;
									case (OREG_CNT)
										5'd0: OREG_RAM_D <= {STE,RESD,6'b000000};
										5'd1: OREG_RAM_D <= YEAR[15:8];
										5'd2: OREG_RAM_D <= YEAR[7:0];
										5'd3: OREG_RAM_D <= {DAY,MONTH};
										5'd4: OREG_RAM_D <= DAYS;
										5'd5: OREG_RAM_D <= HOUR;
										5'd6: OREG_RAM_D <= MIN;
										5'd7: OREG_RAM_D <= SEC;
										5'd8: OREG_RAM_D <= 8'h00;
										5'd9: OREG_RAM_D <= {4'b0000,AC};
										5'd10: OREG_RAM_D <= {1'b0,DOTSEL,2'b11,~MSHNMI_N,1'b1,~SYSRES_N,~SNDRES_N};
										5'd11: OREG_RAM_D <= {1'b0,~CDRES_N,6'b000000};
										5'd12: OREG_RAM_D <= SMEM_Q;
										5'd13: OREG_RAM_D <= SMEM_Q;
										5'd14: OREG_RAM_D <= SMEM_Q;
										5'd15: OREG_RAM_D <= SMEM_Q;
										5'd31: OREG_RAM_D <= COMREG;
										default:OREG_RAM_D <= 8'h00;
									endcase
									OREG_RAM_WE <= 1;
									
									if (OREG_CNT == 5'd31) begin
										SR[7:6] <= 2'b01;
										SR[5] <= 0;
										SR[3:0] <= 4'b1111;
										if (IREG[1][3]) begin
											INTBACK_EXEC <= 1;
											INTBACK_OPTIM_EN <= ~IREG[1][1];
											SR[5] <= 1;
											CHECK_CONTINUE <= 1;
										end
										CONT_PREV <= 0;
										MIRQ_N <= 0;
										COMM_ST <= CS_END;
									end
									OREG_CNT <= OREG_CNT + 5'd1;
								end else begin
									COMM_ST <= CS_END;
								end
							end
							
							8'h16: begin		//SETTIME
								STE <= 1;
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
					end
					
					CS_INTBACK_PERI: begin
						if (OREG_WRITE) begin
							OREG_CNT <= OREG_CNT + 5'd1;
							OREG_RAM_WA <= OREG_CNT;
							OREG_RAM_D <= OREG_DATA;
							OREG_RAM_WE <= 1;
						end
						if (OREG_END) begin
							OREG_RAM_WA <= 5'd31;
							OREG_RAM_D <= COMREG;
							OREG_RAM_WE <= 1;
							SR[7:5] <= {1'b1,1'b1,1'b0};
							//CHECK_CONTINUE <= 1;//TODO: multiple requests for large peripheral data
							MIRQ_N <= 0;
							COMM_ST <= CS_INTBACK_BREAK;
						end
					end
					
					CS_INTBACK_BREAK: begin
						INTBACK_EXEC <= 0;
						INTBACK_PERI <= 0;
						SF <= 0;
						COMM_ST <= CS_IDLE;
					end
					
					CS_END: begin
						case (COMREG) 
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
								MSHNMI_N <= 1;
							end
							
							8'h0F: begin		//CKCHG320
								MSHNMI_N <= 1;
							end
							
							8'h10: begin		//INTBACK

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
						SF <= 0;
						COMM_ST <= CS_IDLE;
					end
				endcase
				
				if (!IRQV_N && IRQV_N_OLD) begin
					VBLANK_PEND <= 1;
				end
			
				if (PORT_DELAY) PORT_DELAY <= PORT_DELAY - 16'd1;
					
				OREG_WRITE <= 0;
				OREG_END <= 0;
				
				if (!PORT_DELAY) 
				case (PORT_ST)
					PS_IDLE: begin
						if (JOY_START) begin
							PORT_NUM <= 0;
							PORT_ST <= PS_START;
						end
					end
					
					PS_START: begin
						if (!IOSEL[PORT_NUM]) begin
							PDR_O[PORT_NUM] <= '1; 
							PORT_ST <= PS_ID1_0;
						end else begin
							OREG_DATA <= 8'hF0;
							OREG_WRITE <= 1;
							PORT_ST <= PS_NEXT;
						end
					end
					
					PS_ID1_0: begin
						DDR[PORT_NUM][`THTR] <= 2'b10;
						PDR_O[PORT_NUM][`THTR] <= 2'b11;
						PORT_DELAY <= 16'd60;
						PORT_ST <= PS_ID1_1;
					end
					
					PS_ID1_1: begin
						JOY_DATA[3:0] <= PDR_I[PORT_NUM][3:0];
						PORT_ST <= PS_ID1_2;
					end
					
					PS_ID1_2: begin
						DDR[PORT_NUM][`THTR] <= 2'b10;
						PDR_O[PORT_NUM][`THTR] <= 2'b01;
						PORT_DELAY <= 16'd60;
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
						else if (MD_ID == 4'hF)
							PORT_ST <= PS_NEXT;
						else 
							PORT_ST <= PS_END;
					end
					
					//Standart PAD
					PS_DPAD_0: begin
						DDR[PORT_NUM][`THTR] <= 2'b11;
						PDR_O[PORT_NUM][`THTR] <= 2'b10;
						PORT_DELAY <= 16'd60;
						PORT_ST <= PS_DPAD_1;
					end
					
					PS_DPAD_1: begin
						JOY_DATA[11:8] <= PDR_I[PORT_NUM][3:0];
						PORT_ST <= PS_DPAD_2;
					end
					
					PS_DPAD_2: begin
						DDR[PORT_NUM][`THTR] <= 2'b11;
						PDR_O[PORT_NUM][`THTR] <= 2'b00;
						PORT_DELAY <= 16'd60;
						PORT_ST <= PS_DPAD_3;
					end
					
					PS_DPAD_3: begin
						JOY_DATA[7:4] <= PDR_I[PORT_NUM][3:0];
						PORT_ST <= PS_DPAD_4;
					end
					
					PS_DPAD_4: begin
						OREG_DATA <= 8'hF1;
						OREG_WRITE <= 1;
						PORT_ST <= PS_DPAD_5;
					end
					
					PS_DPAD_5: begin
						OREG_DATA <= 8'h02;
						OREG_WRITE <= 1;
						PORT_ST <= PS_DPAD_6;
					end
					
					PS_DPAD_6: begin
						OREG_DATA <= JOY_DATA[15:8];
						OREG_WRITE <= 1;
						PORT_ST <= PS_DPAD_7;
					end
					
					PS_DPAD_7: begin
						OREG_DATA <= {JOY_DATA[7:3],3'b111};
						OREG_WRITE <= 1;
						PORT_ST <= PS_NEXT;
					end
					
					//Mouse,Wheel(Arcade racer)
					PS_MOUSE_0: begin
						DDR[PORT_NUM][`THTR] <= 2'b11;
						PDR_O[PORT_NUM][`THTR] <= 2'b00;
						PORT_DELAY <= 16'd60;
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
						PORT_DELAY <= 16'd60;
						PORT_ST <= PS_MOUSE_3;
					end
					
					PS_MOUSE_3: begin
						if (PDR_I[PORT_NUM][4]) begin
							ID2[3:0] <= PDR_I[PORT_NUM][3:0];
							PORT_ST <= PS_MOUSE_4;
						end
					end
					
					PS_MOUSE_4: begin
						OREG_DATA <= 8'hF1;
						OREG_WRITE <= 1;
						PORT_ST <= PS_MOUSE_5;
					end
					
					PS_MOUSE_5: begin
						OREG_DATA <= 8'hE3;
						OREG_WRITE <= 1;
						PORT_DATA_CNT <= 4'd3 - 4'd1;
						PORT_ST <= PS_MOUSE_6;
					end
					
					PS_MOUSE_6: begin
						DDR[PORT_NUM][`THTR] <= 2'b11;
						PDR_O[PORT_NUM][`THTR] <= 2'b00;
						PORT_DELAY <= 16'd60;
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
						PORT_DELAY <= 16'd60;
						PORT_ST <= PS_MOUSE_9;
					end
					
					PS_MOUSE_9: begin
						if (PDR_I[PORT_NUM][4]) begin
							JOY_DATA[3:0] <= PDR_I[PORT_NUM][3:0];
							PORT_ST <= PS_MOUSE_10;
						end
					end
					
					PS_MOUSE_10: begin
						OREG_DATA <= JOY_DATA[7:0];
						OREG_WRITE <= 1;
						PORT_DATA_CNT <= PORT_DATA_CNT - 4'd1; 
						PORT_ST <= !PORT_DATA_CNT ? PS_NEXT : PS_MOUSE_6;
					end
					
					//Analog joystick, 3D Pad
					PS_ID5_0: begin
						DDR[PORT_NUM][`THTR] <= 2'b11;
						PDR_O[PORT_NUM][`THTR] <= 2'b00;
						PORT_DELAY <= 16'd60;
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
						PORT_DELAY <= 16'd60;
						PORT_ST <= PS_ID5_3;
					end
					
					PS_ID5_3: begin
						if (PDR_I[PORT_NUM][4]) begin
							ID2[3:0] <= PDR_I[PORT_NUM][3:0];
							PORT_ST <= PS_ID5_4;
						end
					end
					
					PS_ID5_4: begin
						if (ID2 == 8'h15 || ID2 == 8'h16) begin
							OREG_DATA <= 8'hF1;
							OREG_WRITE <= 1;
							PORT_ST <= PS_ANALOG_5;
						end else begin //TODO: keyboard,multitap
							PORT_ST <= PS_NEXT;
						end
					end
					
					PS_ANALOG_5: begin
						OREG_DATA <= ID2;
						OREG_WRITE <= 1;
						PORT_DATA_CNT <= ID2[3:0] - 4'd1;
						PORT_ST <= PS_ANALOG_6;
					end
					
					PS_ANALOG_6: begin
						DDR[PORT_NUM][`THTR] <= 2'b11;
						PDR_O[PORT_NUM][`THTR] <= 2'b00;
						PORT_DELAY <= 16'd60;
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
						PORT_DELAY <= 16'd60;
						PORT_ST <= PS_ANALOG_9;
					end
					
					PS_ANALOG_9: begin
						if (PDR_I[PORT_NUM][4]) begin
							JOY_DATA[3:0] <= PDR_I[PORT_NUM][3:0];
							PORT_ST <= PS_ANALOG_10;
						end
					end
					
					PS_ANALOG_10: begin
						OREG_DATA <= JOY_DATA[7:0];
						OREG_WRITE <= 1;
						PORT_DATA_CNT <= PORT_DATA_CNT - 4'd1; 
						PORT_ST <= !PORT_DATA_CNT ? PS_NEXT : PS_ANALOG_6;
					end
					
					
					PS_NEXT: begin
						DDR[PORT_NUM][`THTR] <= 2'b11;
						PDR_O[PORT_NUM][`THTR] <= 2'b11;
						PORT_DELAY <= 16'd60;
							
						PORT_NUM <= ~PORT_NUM;
						if (!PORT_NUM) begin
							PORT_ST <= PS_START;
						end else begin
							OREG_DATA <= 8'hF0;
							OREG_WRITE <= 1;
							PORT_ST <= PS_END;
						end
					end

					PS_END: begin
						OREG_END <= 1;
						PORT_ST <= PS_IDLE;
					end
				endcase
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
					7'h63: if (DI[0]) SF <= 1;
					7'h75: if (IOSEL[0]) PDR_O[0] <= DI;
					7'h77: if (IOSEL[1]) PDR_O[1] <= DI;
					7'h79: DDR[0] <= DI[6:0];
					7'h7B: DDR[1] <= DI[6:0];
					7'h7D: IOSEL <= DI[1:0];
					7'h7F: EXLE <= DI[1:0];
					default:;
				endcase
			end 
			
			CS_N_OLD <= CS_N;
			if (!CS_N && CS_N_OLD && RW_N) begin
				if ({A,1'b1} <= 7'h5F)
					REG_DO <= OREG_RAM_Q;
				else
					case ({A,1'b1})
						7'h61: REG_DO <= SR;
						7'h63: REG_DO <= {7'b1111000,SF};
						7'h75: REG_DO <= {PDR_O[0][7],PDR1I};
						7'h77: REG_DO <= {PDR_O[1][7],PDR2I};
						default: REG_DO <= '0;
					endcase
			end
		end
	end
	
	assign PDR1O = PDR_O[0][6:0];
	assign PDR2O = PDR_O[1][6:0];
	assign DDR1 = DDR[0];
	assign DDR2 = DDR[1];
	assign EXL_N = (~EXLE[0] | PDR1I[6]) & (~EXLE[1] | PDR2I[6]);
	
	bit [ 7: 0] SMEM_Q;
	SMPC_SMEM SMEM (CLK, OREG_CNT[1:0], IREG[OREG_CNT[2:0]], (COMM_ST == CS_EXEC && COMREG == 8'h17 && CE), OREG_CNT[1:0], SMEM_Q);
	
	bit [4:0] OREG_RAM_WA;
	bit [7:0] OREG_RAM_D;
	bit       OREG_RAM_WE;
	bit [7:0] OREG_RAM_Q;
	SMPC_OREG_RAM OREG_RAM (CLK, OREG_RAM_WA, OREG_RAM_D, OREG_RAM_WE, (A - 6'h10), OREG_RAM_Q);
	
	assign DO = REG_DO;

endmodule


module SMPC_OREG_RAM
(
	input        CLK,
	input  [4:0] WADDR,
	input  [7:0] DATA,
	input        WREN,
	input  [4:0] RADDR,
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

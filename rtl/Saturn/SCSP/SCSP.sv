// synopsys translate_off
`define SIM
// synopsys translate_on

module SCSP (
	input              CLK,
	input              RST_N,
	input              CE,
	
	input              RES_N,
	
	input              CE_R,
	input              CE_F,
	input      [15: 0] DI,
	output     [15: 0] DO,
	input              CS_N,
	input              AD_N,
	input              DTEN_N,
	input              REQ_N,
	output             RDY_N,
	output             INT_N,
	
	output             SCCE_R,
	output             SCCE_F,
	input      [23: 1] SCA,
	input      [15: 0] SCDI,
	output     [15: 0] SCDO,
	input              SCRW_N,
	input              SCAS_N,
	input              SCLDS_N,
	input              SCUDS_N,
	output reg         SCDTACK_N,
	input      [ 2: 0] SCFC,
	output             SCAVEC_N,
	output     [ 2: 0] SCIPL_N,

	output     [18: 1] RAM_A,
	output     [15: 0] RAM_D,
	input      [15: 0] RAM_Q,
	output     [ 1: 0] RAM_WE,
	output             RAM_RD,
	output             RAM_CS,
	output             RAM_RFS,
	input              RAM_RDY,
	
	input      [15: 0] ESL,
	input      [15: 0] ESR,
	
	output     [15: 0] SOUND_L,
	output     [15: 0] SOUND_R,
	
	input      [ 2: 0] SND_EN,
	input      [31: 0] SLOT_EN
`ifdef DEBUG
                      ,
	output reg         DBG_68K_ERR,
	output reg         DBG_SCU_HOOK,
	output reg [ 7: 0] DBG_SCU_700,
	output reg [ 7: 0] DBG_SCU_710,
	output reg [ 7: 0] DBG_SCU_720,
	output reg [ 7: 0] DBG_SCU_740,
	output             PCM_EN_DBG,
	output     [23: 0] SCA_DBG,
	output     [12: 0] ENV_SAMPLE_CNT_DBG,
	output     [ 2: 0] ENV_STEP_CNT_DBG,
	output     [ 5: 0] OP4_EFF_RATE_DBG,
	output             ATTACK_DBG,
	output             DECAY1_DBG,
	output             DECAY2_DBG,
	output             RELEASE_DBG,
	output SCR0_t      SCR0_DBG,
	output SA_t        SA_DBG,
	output LSA_t       LSA_DBG,
	output LEA_t       LEA_DBG,
	output SCR1_t      SCR1_DBG,
	output SCR2_t      SCR2_DBG,
	output SCR3_t      SCR3_DBG,
	output SCR4_t      SCR4_DBG,
	output SCR5_t      SCR5_DBG,
	output SCR6_t      SCR6_DBG,
	output SCR7_t      SCR7_DBG,
	output SCR8_t      SCR8_DBG,
	output EGState_t   EST_DBG,
	output     [ 6: 0] DSP_MPRO_STEP,
	output MPRO_t      DSP_MPRO_DBG,
	output     [23: 0] INPUTS_DBG,
	output     [23: 0] X_DBG,
	output     [12: 0] Y_DBG,
	output     [25: 0] B_DBG,
	output     [25: 0] MUL_DBG,
	output     [19: 0] ADP_DBG,
	output signed [15:0] LVL_DBG,
	output signed [15:0] PAN_L_DBG,
	output signed [15:0] PAN_R_DBG,
	output             DIR_ACC_L_OF,
	output             DIR_ACC_R_OF,
	output             EFF_ACC_L_OF,
	output             EFF_ACC_R_OF,
	output             SUM_L_OF,
	output             SUM_R_OF
`endif
);
	import SCSP_PKG::*;
	
	CR0_t        CR0;
	CR1_t        CR1;
	CR2_t        CR2;
	CR3_t        CR3;
	CR4_t        CR4;
	CR5_t        CR5;
	CR6_t        CR6;
	CR7_t        CR7;
	CR8_t        CR8;
	CR9_t        CR9;
	CR10_t       CR10;
	CR11_t       CR11;
	CR12_t       CR12;
	CR13_t       CR13;
	CR14_t       CR14;
	CR15_t       CR15;
	CR16_t       CR16;
	CR17_t       CR17;
	CR18_t       CR18;
	CR19_t       CR19;
	bit  [ 3: 0] CR4_CA;
	
	SCR0_t       SCR0;
	SA_t         SA;
	LSA_t        LSA;
	LEA_t        LEA;
	SCR1_t       SCR1;
	SCR2_t       SCR2;
	SCR3_t       SCR3;
	SCR4_t       SCR4;
	SCR5_t       SCR5;
	SCR6_t       SCR6;
	SCR7_t       SCR7;
	SCR8_t       SCR8;
	
	OP2_t        OP2;
	OP3_t        OP3;
	OP4_t        OP4;
	OP5_t        OP5;
	OP6_t        OP6;
	OP7_t        OP7;
	
	
	
	bit [19:0] ADP;
	bit        WD_READ;
	bit [15:0] MEM_WD;

	
	typedef enum bit [5:0] {
		MS_IDLE     = 6'b000001,  
		MS_WD_WAIT  = 6'b000010,
		MS_DSP_WAIT = 6'b000100, 
		MS_DMA_WAIT = 6'b001000, 
		MS_SCU_WAIT = 6'b010000, 
		MS_SCPU_WAIT= 6'b100000
	} MemState_t;
	MemState_t MEM_ST;
	MemState_t REG_ST;
	
	bit  [18: 1] MEM_A;
	bit  [15: 0] MEM_D;
	bit  [15: 0] MEM_Q;
	bit  [ 1: 0] MEM_WE;
	bit          MEM_RD;
	bit          MEM_CS;
	bit          MEM_RFS;
	
	bit  [11: 1] REG_A;
	bit  [15: 0] REG_D;
	bit  [15: 0] REG_Q;
	bit  [ 1: 0] REG_WE;
	bit          REG_RD;
	
	bit  [19: 1] DMA_MA;
	bit  [11: 1] DMA_RA;
	bit  [10: 0] DMA_LEN;
	bit  [15: 0] DMA_DAT;
	bit          DMA_WR;
	bit          DMA_EXEC;
	
	bit          CLK_DIV;
	always @(posedge CLK) if (CE) CLK_DIV <= ~CLK_DIV;
	assign SCCE_R =  CLK_DIV & CE;
	assign SCCE_F = ~CLK_DIV & CE;
		
	bit  [2:0] CYCLE_NUM;
	always @(posedge CLK) 
		if (CLK_DIV && CE) 
			CYCLE_NUM <= CYCLE_NUM + 3'd1;
		
	wire DSP_EN = (CYCLE_NUM[2:1] == 2'b00) || (CYCLE_NUM[2:1] == 2'b10);
	wire PCM_EN = (CYCLE_NUM[2:1] == 2'b01);
	wire SLOT0_EN = (CYCLE_NUM[2:1] == 2'b00);
	wire SLOT1_EN = (CYCLE_NUM[2:1] == 2'b11);
	
	wire CYCLE0_CE = ~CYCLE_NUM[0] & CLK_DIV & CE;
	wire CYCLE1_CE =  CYCLE_NUM[0] & CLK_DIV & CE;
//	wire DSP_CE = DSP_EN & CYCLE1_CE;
//	wire PCM_CE = PCM_EN & CYCLE1_CE;
	wire SLOT0_CE = SLOT0_EN & CYCLE0_CE;
	wire SLOT1_CE = SLOT1_EN & CYCLE1_CE;
	
	wire SAMPLE_CE = (OP7.SLOT == 5'd0) && (CYCLE_NUM[2:1] == 2'b00) && CYCLE1_CE;
	
	
	always @(posedge CLK or negedge RST_N) begin
		bit       KYONEX;
		bit       KEYON_OLD[32];
		
		if (!RST_N) begin
			SCR0 <= '0;
			SCR1 <= '0;
			SCR2 <= '0;
			SCR3 <= '0;
			SCR4 <= '0;
			SCR5 <= '0;
			SCR6 <= '0;
			SCR7 <= '0;
			SCR8 <= '0;
			SA <= '0;
			LSA <= '0;
			LEA <= '0;
			// synopsys translate_off
			// synopsys translate_on
		end else if (!RES_N) begin
			
		end else begin
			if (SLOT0_CE) begin
				SCR0 <= SCR_SCR0_Q;
				SCR1 <= SCR_SCR1_Q;
				SCR2 <= SCR_SCR2_Q;
				SCR3 <= SCR_SCR3_Q;
				SCR4 <= SCR_SCR4_Q;
				SCR5 <= SCR_SCR5_Q;
				SCR6 <= SCR_SCR6_Q;
				SCR7 <= SCR_SCR7_Q;
				SCR8 <= SCR_SCR8_Q;
				SA <= SCR_SA_Q;
				LSA <= SCR_LSA_Q;
				LEA <= SCR_LEA_Q;
			end
		end
	end

	//Operation 1: PG, KEY ON/OFF
	bit        SCR0_KB[32];
	bit        KEYON[32],KEYOFF[32];
	bit  [4:0] SLOT;
	bit        RST;
	
	wire [25:0] PHASE = PhaseCalc(SCR5);
	
	always @(posedge CLK or negedge RST_N) begin
		bit       KYONEX_PEND;
		bit       SCR0_KB_OLD[32];
		
		if (!RST_N) begin
			// synopsys translate_off
			SCR0_KB <= '{32{0}};
			SCR0_KB_OLD <= '{32{0}};
			KEYON <= '{32{0}};
			KEYOFF <= '{32{0}};
			KYONEX_PEND <= 0;
			SLOT <= '0;
			RST <= 1;
			OP2 <= OP2_RESET;
			// synopsys translate_on
		end else if (!RES_N) begin
			SCR0_KB <= '{32{0}};
			SCR0_KB_OLD <= '{32{0}};
			KEYON <= '{32{0}};
			KEYOFF <= '{32{0}};
			KYONEX_PEND <= 0;
			SLOT <= '0;
			RST <= 1;
			OP2 <= OP2_RESET;
		end else begin
			if (SLOT1_CE) begin
				SLOT <= SLOT + 5'd1;
//				OP2.PLFO <= LFOWave(LFOP_RAM_Q,8'h00,SCR6.PLFOWS) ^ 8'h80;
				
				KEYON[SLOT] <= 0;
				KEYOFF[SLOT] <= 0;
				if (SLOT == 5'd31) RST <= 0;
				
				OP2.SLOT <= SLOT;
				OP2.RST <= RST;
				OP2.KON <= 0;
				OP2.KOFF <= 0;
				
				if (RST)
					{OP2.PHASE_INT,OP2.PHASE_FRAC} <= '0;
				else
					{OP2.PHASE_INT,OP2.PHASE_FRAC} <= {8'h00,PHASE_FRAC_RAM_Q} + PHASE;
				
				if (KEYON[SLOT]) begin
					OP2.KON <= 1;
					{OP2.PHASE_INT,OP2.PHASE_FRAC} <= '0;
				end
				else if (KEYOFF[SLOT]) begin
					OP2.KOFF <= 1;
				end
				OP2.BASE_RATE <= BaseRateCalc(SCR5);
			end
			
			if (CYCLE1_CE) begin
				if (REG_A[11:10] == 2'b00 && {REG_A[4:1],1'b0} == 5'h00 && REG_WE[1]) begin
					SCR0_KB[REG_A[9:5]] <= REG_D[11];
					KYONEX_PEND <= REG_D[12];
				end
			end
			
			if (CE) begin
				if (KYONEX_PEND) begin
					for (int i=0;i<32;i++) begin
						SCR0_KB_OLD[i] <= SCR0_KB[i];
						if (SCR0_KB[i] && !SCR0_KB_OLD[i]) begin
							KEYON[i] <= 1;
						end
						if (!SCR0_KB[i] & SCR0_KB_OLD[i]) begin
							KEYOFF[i] <= 1;
						end
					end
					KYONEX_PEND <= 0;
				end
			end
		end
	end
	
	bit  [17:0] PHASE_FRAC_RAM_Q;
	SCSP_PHASE_RAM PHASE_FRAC_RAM(CLK, OP2.SLOT, OP2.PHASE_FRAC, SLOT1_CE, SLOT, PHASE_FRAC_RAM_Q);
	
//	bit  [7:0] LFOP_RAM_Q;
//	SCSP_LFOP_RAM LFOP_RAM(CLK, OP2.SLOT, OP2.PHASE_FRAC, SLOT1_CE, SLOT, LFOP_RAM_Q);
	
	//Operation 2: MD read, ADP
	bit  [ 9: 0] EVOL;//Current envelope volume
	EGState_t    EST;//Current envelope state
	assign {EST,EVOL} = EVOL_RAM_Q;
	
	bit  [ 5: 0] STACK_RA;
	always_comb begin
		casex (CYCLE_NUM)
			3'bxx1: STACK_RA = {1'b0,OP7.SLOT};
			3'bx00: STACK_RA = {1'b0,OP2.SLOT} + SCR4.MDXSL;
			3'bx10: STACK_RA = {1'b0,OP2.SLOT} + SCR4.MDYSL;
		endcase
	end
	
	bit [15: 0] SAO;	//Sample offset integer
	bit         SADIR;//Sample address direction
	bit         SALOOP;//Sample address loop state
	always @(posedge CLK or negedge RST_N) begin
		bit  [15: 0] SOUSX;
		bit  [15: 0] SOUSY;
		bit  [15: 0] CUR_SO;
		bit          CUR_SADIR;
		bit          CUR_SALOOP;
		bit  [15: 0] CALC_SO;
		bit          CALC_SO_OVF;
		bit  [15: 0] MOD_SO;
		bit  [15: 0] DELTA;
		bit  [15: 0] NEW_SAO;
		bit          NEW_SADIR;
		bit          NEW_SALOOP;
		
		if (!RST_N) begin
			// synopsys translate_off
			OP3 <= OP3_RESET;
			// synopsys translate_on
			WD_READ <= 0;
		end else if (!RES_N) begin
			OP3 <= OP3_RESET;
			WD_READ <= 0;
		end else begin
			if (CYCLE0_CE) begin
				case (CYCLE_NUM[2:1])
					2'b10: SOUSX <= STACK_RA[5] ? STACK1_Q : STACK0_Q;
					2'b11: SOUSY <= STACK_RA[5] ? STACK1_Q : STACK0_Q;
				endcase
			end
		
			{CUR_SALOOP,CUR_SADIR,CUR_SO} = SO_RAM_Q;
			
			MOD_SO = CUR_SO + MDCalc(SOUSX, SOUSY, SCR4.MDL);
			
			DELTA = {8'h00,OP2.PHASE_INT};
			{CALC_SO_OVF,CALC_SO} = !CUR_SADIR || SCR0.LPCTL <= 2'b01 ? {1'b0,CUR_SO} + {1'b0,DELTA} : {1'b0,CUR_SO} - {1'b0,DELTA};
			
			if (SLOT1_CE) begin
				ADP <= {SCR0.SAH,SA} + (!SCR0.PCM8B ? {3'b000,MOD_SO,1'b0} : {4'b0000,MOD_SO});
				
				WD_READ <= 1;
				OP3.LOOP_END <= 0;
				if (OP2.RST) begin
					{NEW_SALOOP,NEW_SADIR,NEW_SAO} = '0;
					WD_READ <= 0;
				end else if (EST == EST_RELEASE && (EVOL == 10'h3FF || OP2.KON)) begin
					{NEW_SALOOP,NEW_SADIR,NEW_SAO} = '0;
					WD_READ <= 0;
				end else begin
					{NEW_SALOOP,NEW_SADIR,NEW_SAO} = {CUR_SALOOP,CUR_SADIR,CALC_SO};
					case (SCR0.LPCTL)
					2'b00: begin	//Loop off
						if (CALC_SO >= LEA || CALC_SO_OVF) begin
							NEW_SAO = '0;
							OP3.LOOP_END <= 1;
							WD_READ <= 0;
						end
					end
					2'b01: begin	//Normal loop
						if (!CUR_SALOOP) begin
							if (CALC_SO >= LSA || CALC_SO_OVF) begin
								NEW_SALOOP = 1;
							end
						end else begin
							if (CALC_SO >= LEA || CALC_SO_OVF) begin
								NEW_SAO = CALC_SO - (LEA - LSA);
							end
						end
					end
					2'b10: begin	//Reverse loop
						if (!CUR_SALOOP) begin
							if (CALC_SO >= LEA || CALC_SO_OVF) begin
								NEW_SALOOP = 1;
								NEW_SADIR = 1;
							end
						end else begin
							if (CALC_SO < LSA || CALC_SO_OVF) begin
								NEW_SAO = LSA;//TODO
							end
						end
					end
					2'b11: begin	//Alternative loop
						if (!CUR_SALOOP) begin
							if (CALC_SO >= LSA || CALC_SO_OVF) begin
								NEW_SALOOP = 1;
								NEW_SADIR = 0;
							end
						end else if (!CUR_SADIR) begin
							if (CALC_SO >= LEA || CALC_SO_OVF) begin
								NEW_SAO = CALC_SO - (LEA - LSA);
								NEW_SADIR = 1;
							end
						end else begin
							if (CALC_SO < LSA || CALC_SO_OVF) begin
								NEW_SAO = LSA;//TODO
								NEW_SADIR = 0;
							end
						end
					end
					endcase
					
				end
				{SALOOP,SADIR,SAO} <= {NEW_SALOOP,NEW_SADIR,NEW_SAO};
				
				OP3.SLOT <= OP2.SLOT;
				OP3.RST <= OP2.RST;
				OP3.KON <= OP2.KON;
				OP3.KOFF <= OP2.KOFF;
				OP3.PCM8B <= SCR0.PCM8B;
				OP3.BASE_RATE <= OP2.BASE_RATE;
				OP3.LOOP <= CUR_SALOOP;
				OP3.SBCTL <= SCR0.SBCTL;
				OP3.SSCTL <= SCR0.SSCTL;
				OP3.EVOL <= EVOL;
				OP3.EST <= EST;
			end
		end
	end
	bit [17:0] SO_RAM_Q;
	SCSP_SO_RAM SO_RAM(CLK, OP3.SLOT, {SALOOP,SADIR,SAO}, SLOT1_CE, OP2.SLOT, SO_RAM_Q);
	
	//Operation 3:  
	always @(posedge CLK or negedge RST_N) begin
		bit [15: 0] WAVE;
		bit [16: 0] NOISE;
		
		if (!RST_N) begin
			OP4 <= OP4_RESET;
			// synopsys translate_off
			NOISE <= 17'h00001;
			// synopsys translate_on
		end else if (!RES_N) begin
			OP4 <= OP4_RESET;
			NOISE <= 17'h00001;
		end else begin
			WAVE = !WD_READ ? 16'h0000 : !OP3.PCM8B ? MEM_WD : !ADP[0] ? {MEM_WD[15:8],8'h00} : {MEM_WD[7:0],8'h00};
			
			if (SLOT1_CE) begin
				NOISE <= {NOISE[5]^NOISE[0],NOISE[16:1]};
				
				OP4.SLOT <= OP3.SLOT;
				OP4.RST <= OP3.RST;
				OP4.KON <= OP3.KON;
				OP4.KOFF <= OP3.KOFF;
				OP4.LOOP <= OP3.LOOP;
				OP4.LOOP_END <= OP3.LOOP_END;
				OP4.BASE_RATE <= OP3.BASE_RATE;
				OP4.EVOL <= OP3.EVOL;
				OP4.EST <= OP3.EST;
				OP4.WD <= SoundSel(WAVE,{NOISE[7:0],8'h00},OP3.SBCTL,OP3.SSCTL);
			end
		end
	end
	
	//Operation 4: EG
	bit  [ 5: 0] EFF_RATE;//Effective rate
	always_comb begin
		bit  [ 4: 0] RATE;
		
		case (OP4.EST)
			EST_ATTACK: RATE = SCR1.AR;	
			EST_DECAY1: RATE = SCR1.D1R;
			EST_DECAY2: RATE = SCR1.D2R;
			EST_RELEASE: RATE = SCR2.RR;
		endcase
		if (OP4.EST != EST_RELEASE && OP4.KOFF) begin
			RATE = SCR2.RR;
		end
		EFF_RATE = EffRateCalc(OP4.BASE_RATE, RATE, SCR2.KRS);
	end
	
	wire [12: 0] CUR_SAMPLE_CNT = ENV_CNT_RAM_Q[12:0];
	wire [ 2: 0] CUR_STEP_CNT = ENV_CNT_RAM_Q[15:13];
	bit  [12: 0] NEW_SAMPLE_CNT;
	bit  [ 2: 0] NEW_STEP_CNT;
	bit          ENV_STEP;
	always_comb begin
		ENV_STEP = 0;
		if (!EFF_RATE[5:1] || (OP4.EST == EST_RELEASE && OP4.KON)) begin
			NEW_SAMPLE_CNT = '0;
			NEW_STEP_CNT = '0;
		end else if (EFF_RATE[5:1] < (6'h30>>1)) begin
			NEW_SAMPLE_CNT = CUR_SAMPLE_CNT + 13'd1;
			NEW_STEP_CNT = '0;
			if (CUR_SAMPLE_CNT == ENV_TBL[EFF_RATE][CUR_STEP_CNT].CNT) begin
				NEW_SAMPLE_CNT = '0;
				NEW_STEP_CNT = CUR_STEP_CNT + 3'd1;
				if (ENV_TBL[EFF_RATE][CUR_STEP_CNT].LAST) begin
					NEW_STEP_CNT = '0;
				end
				ENV_STEP = 1;
			end
		end else begin
			NEW_SAMPLE_CNT = CUR_SAMPLE_CNT + 13'd1;
			if (CUR_SAMPLE_CNT == 13'h0001) begin
				NEW_SAMPLE_CNT = '0;
				ENV_STEP = 1;
			end
			NEW_STEP_CNT = '0;
		end
	end
	
	bit  [12: 0] ENV_SAMPLE_CNT;
	bit  [ 2: 0] ENV_STEP_CNT;
	always @(posedge CLK or negedge RST_N) begin
		bit  [10: 0] VOL_CALC;
		bit  [ 9: 0] NEW_EVOL;
		bit  [ 1: 0] NEW_EST;
		
		if (!RST_N) begin
			OP5 <= OP5_RESET;
			// synopsys translate_off
			// synopsys translate_on
		end else if (!RES_N) begin
			OP5 <= OP5_RESET;
		end else begin
`ifdef DEBUG
			if (CYCLE1_CE) begin
				DECAY1_DBG <= 0;
				DECAY2_DBG <= 0;
				ATTACK_DBG <= 0;
				RELEASE_DBG <= 0;
			end
`endif
			
			if (SLOT1_CE) begin
				ENV_SAMPLE_CNT <= NEW_SAMPLE_CNT;
				ENV_STEP_CNT <= NEW_STEP_CNT;
				
				NEW_EVOL = OP4.EVOL;
				NEW_EST = OP4.EST;
				case (OP4.EST)
					EST_ATTACK: begin
						VOL_CALC = {1'b0,OP4.EVOL} - (ENV_STEP ? AttackEnvCalc(EFF_RATE,OP4.EVOL) : 11'd0);
						if (!VOL_CALC[10] && !SCR1.EGHOLD) begin
							NEW_EVOL = VOL_CALC[9:0];
						end else begin
							NEW_EVOL = 10'h000;
						end
						if ((!VOL_CALC && !SCR2.LPSLNK) || (OP4.LOOP && SCR2.LPSLNK)) begin
							NEW_EST = EST_DECAY1;
							ENV_STEP_CNT <= '0;
`ifdef DEBUG
							DECAY1_DBG <= 1;
`endif
						end
					end
					
					EST_DECAY1: begin
						VOL_CALC = {1'b0,OP4.EVOL} + (ENV_STEP ? DecayEnvCalc(EFF_RATE) : 11'd0);
						if (!VOL_CALC[10]) begin
							NEW_EVOL = VOL_CALC[9:0];
						end else begin
							NEW_EVOL = 10'h3FF;
						end
						if (VOL_CALC[10] || VOL_CALC[9:5] >= SCR2.DL) begin
							NEW_EST = EST_DECAY2;
							ENV_STEP_CNT <= '0;
`ifdef DEBUG
							DECAY2_DBG <= 1;
`endif
						end
					end
					
					EST_DECAY2: begin
						VOL_CALC = {1'b0,OP4.EVOL} + (ENV_STEP ? DecayEnvCalc(EFF_RATE) : 11'd0);
						if (SCR1.D2R == 5'h00) begin
							NEW_EVOL = OP4.EVOL;
						end else if (!VOL_CALC[10]) begin
							NEW_EVOL = VOL_CALC[9:0];
						end else begin
							NEW_EVOL = 10'h3FF;
						end
					end
					
					EST_RELEASE: begin
						VOL_CALC = {1'b0,OP4.EVOL} + (ENV_STEP ? DecayEnvCalc(EFF_RATE) : 11'd0);
						if (!VOL_CALC[10]) begin
							NEW_EVOL = VOL_CALC[9:0];
						end else begin
							NEW_EVOL = 10'h3FF;
						end
					end
				endcase
				
				if (OP4.RST) begin
					NEW_EVOL = 10'h3FF;
					NEW_EST = EST_RELEASE;
					ENV_SAMPLE_CNT <= '0;
					ENV_STEP_CNT <= '0;
				end else if (OP4.EST == EST_RELEASE && OP4.KON) begin
					NEW_EVOL = 10'h3FF;
					NEW_EST = EST_ATTACK;
					ENV_SAMPLE_CNT <= '0;
					ENV_STEP_CNT <= '0;
`ifdef DEBUG
					ATTACK_DBG <= 1;
`endif
				end else if (OP4.EST != EST_RELEASE && OP4.KOFF) begin
					VOL_CALC = {1'b0,OP4.EVOL} + (ENV_STEP ? DecayEnvCalc(EFF_RATE) : 11'd0);
					if (!VOL_CALC[10]) begin
						NEW_EVOL = VOL_CALC[9:0];
					end else begin
						NEW_EVOL = 10'h3FF;
					end
					NEW_EST = EST_RELEASE;
					ENV_SAMPLE_CNT <= '0;
					ENV_STEP_CNT <= '0;
`ifdef DEBUG
					RELEASE_DBG <= 1;
`endif
				end else if (OP4.LOOP_END) begin
					NEW_EVOL = 10'h3FF;
					NEW_EST = EST_RELEASE;
					ENV_SAMPLE_CNT <= '0;
					ENV_STEP_CNT <= '0;
`ifdef DEBUG
					RELEASE_DBG <= 1;
`endif
				end
				EVOL_RAM_D <= {NEW_EST,NEW_EVOL};
				
				OP5.SLOT <= OP4.SLOT;
				OP5.RST <= OP4.RST;
				OP5.KON <= OP4.KON;
				OP5.KOFF <= OP4.KOFF;
				OP5.EST <= OP4.EST;
				OP5.EVOL <= OP4.EVOL;
				OP5.ALFO <= 8'h00;//TODO
				OP5.WD <= OP4.WD;
			end
		end
	end
	bit [11:0] EVOL_RAM_D;
	bit [11:0] EVOL_RAM_Q;
	SCSP_EVOL_RAM EVOL_RAM(CLK, OP5.SLOT, EVOL_RAM_D, SLOT1_CE, OP2.SLOT, EVOL_RAM_Q);
	
	bit [15:0] ENV_CNT_RAM_Q;
	SCSP_ENV_CNT_RAM ENV_CNT_RAM(CLK, OP5.SLOT, {ENV_STEP_CNT,ENV_SAMPLE_CNT}, SLOT1_CE, OP4.SLOT, ENV_CNT_RAM_Q);
	
	//Operation 5: Level calculation
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			OP6 <= OP6_RESET;
			// synopsys translate_off
			// synopsys translate_on
		end else if (!RES_N) begin
			OP6 <= OP6_RESET;
		end else begin
			if (SLOT1_CE) begin
				OP6.SLOT <= OP5.SLOT;
				OP6.RST <= OP5.RST;
				OP6.KON <= OP5.KON;
				OP6.KOFF <= OP5.KOFF;
				OP6.LEVEL <= LevelAddALFO(OP5.EVOL, OP5.ALFO);
//				OP6.SDIR <= SCR3.SDIR;
				OP6.WD <= OP5.WD;
//				OP6.SD <= EnvVolCalc(OP5.WD, OP5.EVOL);
			end
		end
	end
	
	//Operation 6: Level calculation
	always @(posedge CLK or negedge RST_N) begin
		bit [ 9: 0] LEVEL;
		
		LEVEL = LevelAddTL(OP6.LEVEL, SCR3.TL);
		
		if (!RST_N) begin
			OP7 <= OP7_RESET;
		end else if (!RES_N) begin
			OP7 <= OP7_RESET;
		end else begin
			if (SLOT1_CE) begin
				OP7.SLOT <= OP6.SLOT;
				OP7.RST <= OP6.RST;
				OP7.KON <= OP6.KON;
				OP7.KOFF <= OP6.KOFF;
				OP7.SD <= SCR3.SDIR ? OP6.WD : VolCalc(OP6.WD, LEVEL);
//				OP7.SD <= SCR3.SDIR ? OP6.WD : TotalVolCalc(OP6.SD, SCR3.TL);
				OP7.STWINH <= SCR3.STWINH;
			end
		end
	end
	
	//Operation 7: Stack save
	//Direct out
	bit [17:0] DIR_ACC_L,DIR_ACC_R;
	always @(posedge CLK or negedge RST_N) begin
		bit [ 4:0] S;
		bit signed [15:0] TEMP;
		bit signed [15:0] PAN_L,PAN_R;
		
		if (!RST_N) begin
			// synopsys translate_off
			DIR_ACC_L <= 0;
			DIR_ACC_R <= 0;
			// synopsys translate_on
		end else if (!RES_N) begin
			DIR_ACC_L <= 0;
			DIR_ACC_R <= 0;
		end else begin
			S = OP7.SLOT;
			if ((!SLOT_EN[ 0] && S == 5'd0 ) || (!SLOT_EN[ 1] && S == 5'd1 ) || (!SLOT_EN[ 2] && S == 5'd2 ) || (!SLOT_EN[ 3] && S == 5'd 3) ||
						 (!SLOT_EN[ 4] && S == 5'd4 ) || (!SLOT_EN[ 5] && S == 5'd5 ) || (!SLOT_EN[ 6] && S == 5'd6 ) || (!SLOT_EN[ 7] && S == 5'd7 ) ||
						 (!SLOT_EN[ 8] && S == 5'd8 ) || (!SLOT_EN[ 9] && S == 5'd9 ) || (!SLOT_EN[10] && S == 5'd10) || (!SLOT_EN[11] && S == 5'd11) ||
						 (!SLOT_EN[12] && S == 5'd12) || (!SLOT_EN[13] && S == 5'd13) || (!SLOT_EN[14] && S == 5'd14) || (!SLOT_EN[15] && S == 5'd15) ||
						 (!SLOT_EN[16] && S == 5'd16) || (!SLOT_EN[17] && S == 5'd17) || (!SLOT_EN[18] && S == 5'd18) || (!SLOT_EN[19] && S == 5'd19) ||
						 (!SLOT_EN[20] && S == 5'd20) || (!SLOT_EN[21] && S == 5'd21) || (!SLOT_EN[22] && S == 5'd22) || (!SLOT_EN[23] && S == 5'd23) ||
						 (!SLOT_EN[24] && S == 5'd24) || (!SLOT_EN[25] && S == 5'd25) || (!SLOT_EN[26] && S == 5'd26) || (!SLOT_EN[27] && S == 5'd27) ||
						 (!SLOT_EN[28] && S == 5'd28) || (!SLOT_EN[29] && S == 5'd29) || (!SLOT_EN[30] && S == 5'd30) || (!SLOT_EN[31] && S == 5'd31))
				TEMP = '0;
			else 
				TEMP = LevelCalc(OP7.SD,SCR8.DISDL);
			PAN_L = PanLCalc(TEMP,SCR8.DIPAN);
			PAN_R = PanRCalc(TEMP,SCR8.DIPAN);
			
			if (SLOT1_CE) begin
				if (S == 5'd0) begin
					DIR_ACC_L <= {{2{PAN_L[15]}},PAN_L[15:0]};
					DIR_ACC_R <= {{2{PAN_R[15]}},PAN_R[15:0]};
				end else begin
					DIR_ACC_L <= DIR_ACC_L + {{2{PAN_L[15]}},PAN_L[15:0]};
					DIR_ACC_R <= DIR_ACC_R + {{2{PAN_R[15]}},PAN_R[15:0]};
				end
			end
			
`ifdef DEBUG
			LVL_DBG <= TEMP;
			PAN_L_DBG <= PAN_L;
			PAN_R_DBG <= PAN_R;
`endif
		end
	end
`ifdef DEBUG
	assign DIR_ACC_L_OF = (DIR_ACC_L[17] && DIR_ACC_L[16:15] != 2'b11) || (!DIR_ACC_L[17] && DIR_ACC_L[16:15] != 2'b00);
	assign DIR_ACC_R_OF = (DIR_ACC_R[17] && DIR_ACC_R[16:15] != 2'b11) || (!DIR_ACC_R[17] && DIR_ACC_R[16:15] != 2'b00);
`endif
	
	//DSP
	MPRO_t       MPRO0_Q,MPRO1_Q;
	EFREG_t      EFREG_Q;
	assign MPRO0_Q = MPRO_RAM_Q & {64{DSP_MPRO_SET[DSP_MPRO_STEP]}};
	
	bit          DSP_MPRO_SET[128];
	
	//DSP input
	bit  [ 3: 0] PCM_MIXS_RA;
	bit          PCM_MIXS_RD;
	bit  [ 3: 0] PCM_MIXS_WA;
	bit          PCM_MIXS_WE;
	MIXS_t       PCM_MIXS_D;
	
	bit  [15: 0] DSP_EXTS[2];
	MIXS_t       DSP_MIXS[16];
	always @(posedge CLK or negedge RST_N) begin
		bit  [15: 0] SD;
		MIXS_t       MIXS_SUM[16];
		MIXS_t       MIXS_OLD;
		
		if (!RST_N) begin
			// synopsys translate_off
			DSP_EXTS <= '{2{'0}};
			DSP_MIXS <= '{16{'0}};
			MIXS_SUM <= '{16{'0}};
			// synopsys translate_on
		end else if (!RES_N) begin
			MIXS_SUM <= '{16{'0}};
		end else begin
			SD = LevelCalc(OP7.SD,SCR7.IMXL);

			if (CYCLE1_CE) begin
				if (CYCLE_NUM[2:1] == 2'b00) begin
					MIXS_OLD <= MIXS_SUM[SCR7.ISEL];
				end
				if (CYCLE_NUM[2:1] == 2'b10) begin
					MIXS_SUM[SCR7.ISEL] <= MIXS_OLD + {SD,4'h00};
				end
			end
			
			if (OP7.SLOT == 5'd31 && SLOT1_CE) begin
				MIXS_SUM <= '{16{'0}};
				DSP_MIXS <= MIXS_SUM;
				DSP_EXTS[0] <= !SND_EN[2] ? 16'h0000 : ESL;
				DSP_EXTS[1] <= !SND_EN[2] ? 16'h0000 : ESR;
			end
		end
	end
	
	//DSP execute
`ifndef DEBUG
	bit  [ 6: 0] DSP_MPRO_STEP;
`endif
	assign DSP_MPRO_STEP = {OP7.SLOT,CYCLE_NUM[2:1]};
	
	bit  [ 6: 0] DSP_TEMP_RA;
	bit  [ 6: 0] DSP_TEMP_WA;
	TEMP_t       DSP_TEMP_D;
	bit          DSP_TEMP_WE;
	bit  [ 4: 0] DSP_MEMS_RA;
	bit  [ 4: 0] DSP_MEMS_WA;
	MEMS_t       DSP_MEMS_D;
	bit          DSP_MEMS_WE;
	bit  [ 5: 0] DSP_COEF_RA;
	bit  [ 4: 0] DSP_MADRS_RA;
//	bit  [ 3: 0] DSP_MIXS_RA;
	bit  [ 3: 0] DSP_EFREG_RA;
	bit  [ 3: 0] DSP_EFREG_WA;
	bit          DSP_EFREG_WE;
	EFREG_t      DSP_EFREG_D;
	bit  [15: 0] MDEC_CT;
	bit  [25: 0] SFT_REG;
	bit  [19: 1] DSP_MEMA_REG;
	bit  [15: 0] DSP_INP_REG;
	bit  [15: 0] DSP_OUT_REG;
	bit          DSP_READ;
	bit          DSP_WRITE;
	bit          DSP_READ_NOFL;
	
	wire [23: 0] SHFT_OUT = DSPShifter(SFT_REG, MPRO1_Q.SHFT);
	
	always @(posedge CLK or negedge RST_N) begin
		TEMP_t       TEMP_Q;
		MEMS_t       MEMS_Q;
		COEF_t       COEF_Q;
		MADRS_t      MADRS_Q;
		MIXS_t       MIXS_Q;
		bit  [15: 0] EXTS_Q;
		bit  [23: 0] INPUTS;
		bit  [23: 0] X;
		bit  [12: 0] Y;
		bit  [25: 0] BS;
		bit  [25: 0] B;
		bit  [23: 0] Y_REG;
		bit  [12: 0] FRC_REG;
		bit  [11: 0] ADRS_REG;
		bit  [25: 0] MUL;
		bit  [16: 1] ADDR;
		
		if (!RST_N) begin
			MDEC_CT <= '0;
			DSP_READ <= 0;
			DSP_WRITE <= 0;
			// synopsys translate_off
			Y_REG <= '0;
			FRC_REG <= '0;
			ADRS_REG <= '0;
			DSP_MEMA_REG <= '0;
			DSP_OUT_REG <= '0;
			// synopsys translate_on
		end else if (!RES_N) begin
			MPRO1_Q <= '0;
			MDEC_CT <= '0;
			DSP_READ <= 0;
			DSP_WRITE <= 0;
		end else begin
			if (!MPRO1_Q.IRA[5])
				INPUTS = MEMS_Q;
			else if (!MPRO1_Q.IRA[4])
				INPUTS = {MIXS_Q,4'h0};
			else if (!MPRO1_Q.IRA[3:1])
				INPUTS = {EXTS_Q,8'h00};
			
			case (MPRO1_Q.XSEL)
				1'b0: X = TEMP_Q;
				1'b1: X = INPUTS;
			endcase
			case (MPRO1_Q.YSEL)
				2'b00: Y = FRC_REG;
				2'b01: Y = COEF_Q;
				2'b10: Y = Y_REG[23:11];
				2'b11: Y = {1'b0,Y_REG[15:4]};
			endcase
			
			BS = !MPRO1_Q.BSEL ? {{2{TEMP_Q[23]}},TEMP_Q} : SFT_REG;
			if (MPRO1_Q.ZERO)
				B = '0;
			else if (MPRO1_Q.NEGB)
				B = 26'd0 - BS;
			else
				B = BS;
				
			MUL = DSPMult(X, Y);
			
			ADDR = MADRS_Q + (!MPRO1_Q.TABLE ? MDEC_CT : 16'h0000) + (MPRO1_Q.ADREB ? {{4{ADRS_REG[11]}},ADRS_REG} : 16'h0000) + (MPRO1_Q.NXADR ? 16'h0001 : 16'h0000);
			
			if (CYCLE0_CE) begin
				MPRO1_Q <= MPRO0_Q;
				MEMS_Q <= {MEMS_RAM_Q[31:16],MEMS_RAM_Q[7:0]};
				MIXS_Q <= DSP_MIXS[MPRO0_Q.IRA[3:0]];
				EXTS_Q <= DSP_EXTS[MPRO0_Q.IRA[0]];
				TEMP_Q <= {TEMP_RAM_Q[31:16],TEMP_RAM_Q[7:0]};
				COEF_Q <= COEF_RAM_Q[15:3];
				MADRS_Q <= MADRS_RAM_Q;
			end
			if (CYCLE1_CE) begin
				if (OP7.SLOT == 5'd31 && SLOT1_CE) 
					MDEC_CT <= MDEC_CT - 16'd1;
				
				SFT_REG <= MUL + B;

				if (MPRO1_Q.YRL)
					Y_REG <= INPUTS;
				
				if (MPRO1_Q.FRCL) begin
					if (MPRO1_Q.SHFT == 2'b11)
						FRC_REG <= {1'b0,SHFT_OUT[11:0]};
					else
						FRC_REG <= SHFT_OUT[23:11];
				end
				
				if (MPRO1_Q.ADRL) begin
					if (MPRO1_Q.SHFT == 2'b11)
						ADRS_REG <= SHFT_OUT[23:12];
					else
						ADRS_REG <= {{4{INPUTS[23]}},INPUTS[23:16]};
				end
				
				case (CR1.RBL | {2{MPRO1_Q.TABLE}})
					2'b00: DSP_MEMA_REG <= {CR1.RBP,12'h000} + {6'b000000,ADDR[13:1]};
					2'b01: DSP_MEMA_REG <= {CR1.RBP,12'h000} + {5'b00000,ADDR[14:1]};
					2'b10: DSP_MEMA_REG <= {CR1.RBP,12'h000} + {4'b0000,ADDR[15:1]};
					2'b11: DSP_MEMA_REG <= {CR1.RBP,12'h000} + {3'b000,ADDR[16:1]};
				endcase
				DSP_OUT_REG <= !MPRO1_Q.NOFL ? DSPItoF(SHFT_OUT) : SHFT_OUT[23:8];
				DSP_READ <= MPRO1_Q.MRD;
				DSP_READ_NOFL <= MPRO1_Q.NOFL;
				DSP_WRITE <= MPRO1_Q.MWT & |CR1.RBP;//TODO
			end
`ifdef DEBUG
			INPUTS_DBG <= INPUTS;
			X_DBG <= X;
			Y_DBG <= Y;
			B_DBG <= B;
			MUL_DBG <= MUL;
`endif
		end
	end
	assign DSP_TEMP_RA = MPRO0_Q.TRA + MDEC_CT[6:0];
	assign DSP_TEMP_WA = MPRO1_Q.TWA + MDEC_CT[6:0];
	assign DSP_TEMP_WE = MPRO1_Q.TWT;
	assign DSP_TEMP_D = SHFT_OUT;
	
	assign DSP_MEMS_RA = MPRO0_Q.IRA[4:0];
	assign DSP_MEMS_WA = MPRO1_Q.IWA;
	assign DSP_MEMS_WE = MPRO1_Q.IWT;
	assign DSP_MEMS_D = !DSP_READ_NOFL ? DSPFtoI(DSP_INP_REG) : {DSP_INP_REG,8'h00};
	
	assign DSP_COEF_RA = MPRO0_Q.COEF;
	assign DSP_MADRS_RA = MPRO0_Q.MASA;
	
//	assign DSP_MIXS_RA = MPRO0_Q.IRA[3:0];

	assign DSP_EFREG_RA = OP7.SLOT[3:0];
	assign DSP_EFREG_WA = MPRO1_Q.EWA;
	assign DSP_EFREG_WE = MPRO1_Q.EWT;
	assign DSP_EFREG_D = SHFT_OUT[23:8];
	
	
	
	//Effect out
	bit signed [17:0] EFF_ACC_L,EFF_ACC_R;
	always @(posedge CLK or negedge RST_N) begin
		bit [ 4:0] S;
		bit [15:0] TEMP;
		bit [15:0] PAN_L,PAN_R;
		
		if (!RST_N) begin
			// synopsys translate_off
			EFF_ACC_L <= '0;
			EFF_ACC_R <= '0;
			// synopsys translate_on
		end else if (!RES_N) begin
			EFF_ACC_L <= '0;
			EFF_ACC_R <= '0;
		end else begin
			S = OP7.SLOT;
			
			TEMP = '0;
			if (S <= 5'd15) begin
				TEMP = LevelCalc(EFREG_Q,SCR8.EFSDL);
			end else if (S == 5'd16) begin
				TEMP = !SND_EN[2] ? 16'h0000 : LevelCalc(ESL,SCR8.EFSDL);
			end else if (S == 5'd17) begin
				TEMP = !SND_EN[2] ? 16'h0000 : LevelCalc(ESR,SCR8.EFSDL);
			end
			PAN_L = PanLCalc(TEMP,SCR8.EFPAN);
			PAN_R = PanRCalc(TEMP,SCR8.EFPAN);
			
			if (SLOT0_CE) begin
				EFREG_Q <= EFREG_RAM_Q;
			end
			
			if (SLOT1_CE) begin
				if (S == 5'd0) begin
					EFF_ACC_L <= {{2{PAN_L[15]}},PAN_L[15:0]};
					EFF_ACC_R <= {{2{PAN_R[15]}},PAN_R[15:0]};
				end else begin
					EFF_ACC_L <= EFF_ACC_L + {{2{PAN_L[15]}},PAN_L[15:0]};
					EFF_ACC_R <= EFF_ACC_R + {{2{PAN_R[15]}},PAN_R[15:0]};
				end
			end
		end
	end
`ifdef DEBUG
	assign EFF_ACC_L_OF = (EFF_ACC_L[17] && EFF_ACC_L[16:15] != 2'b11) || (!EFF_ACC_L[17] && EFF_ACC_L[16:15] != 2'b00);
	assign EFF_ACC_R_OF = (EFF_ACC_R[17] && EFF_ACC_R[16:15] != 2'b11) || (!EFF_ACC_R[17] && EFF_ACC_R[16:15] != 2'b00);
`endif
	
	//Out
	bit [15:0] DIR_L,DIR_R;
	bit [15:0] EFF_L,EFF_R;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			// synopsys translate_off
			DIR_L <= '0;
			DIR_R <= '0;
			// synopsys translate_on
		end else if (!RES_N) begin
			
		end else begin
			if (SAMPLE_CE) begin
				DIR_L <= !SND_EN[0] ? 16'h0000 : DIR_ACC_L[17] && DIR_ACC_L[16:15] != 2'b11 ? 16'h8000 : !DIR_ACC_L[17] && DIR_ACC_L[16:15] != 2'b00 ? 16'h7FFF : DIR_ACC_L[15:0];
				DIR_R <= !SND_EN[0] ? 16'h0000 : DIR_ACC_R[17] && DIR_ACC_R[16:15] != 2'b11 ? 16'h8000 : !DIR_ACC_R[17] && DIR_ACC_R[16:15] != 2'b00 ? 16'h7FFF : DIR_ACC_R[15:0];
				EFF_L <= !SND_EN[1] ? 16'h0000 : EFF_ACC_L[17] && EFF_ACC_L[16:15] != 2'b11 ? 16'h8000 : !EFF_ACC_L[17] && EFF_ACC_L[16:15] != 2'b00 ? 16'h7FFF : EFF_ACC_L[15:0];
				EFF_R <= !SND_EN[1] ? 16'h0000 : EFF_ACC_R[17] && EFF_ACC_R[16:15] != 2'b11 ? 16'h8000 : !EFF_ACC_R[17] && EFF_ACC_R[16:15] != 2'b00 ? 16'h7FFF : EFF_ACC_R[15:0];
			end
		end
	end
	
	bit [16:0] SUM_L,SUM_R;
	assign SUM_L = {DIR_L[15],DIR_L} + {EFF_L[15],EFF_L};
	assign SUM_R = {DIR_R[15],DIR_R} + {EFF_R[15],EFF_R};
	assign SOUND_L = MVolCalc(SUM_L[15:0], CR0.MVOL, CR0.DB);
	assign SOUND_R = MVolCalc(SUM_R[15:0], CR0.MVOL, CR0.DB);
`ifdef DEBUG
	assign SUM_L_OF = (SUM_L[16] && !SUM_L[15]) || (!SUM_L[16] && SUM_L[15]);
	assign SUM_R_OF = (SUM_R[16] && !SUM_R[15]) || (!SUM_R[16] && SUM_R[15]);
`endif
	
	
	
	//Timers
	bit [7:0] TMR_CE;
	always @(posedge CLK or negedge RST_N) begin
		bit [6:0] CNT;
	
		if (!RST_N) begin
			CNT <= '0;
			TMR_CE <= '0;
		end else if (!RES_N) begin
			CNT <= '0;
			TMR_CE <= '0;
		end else begin
			TMR_CE <= '0;
			if (SAMPLE_CE) begin
				CNT <= CNT + 7'd1;
				TMR_CE[0] <= 1;
				TMR_CE[1] <= &CNT[0:0];
				TMR_CE[2] <= &CNT[1:0];
				TMR_CE[3] <= &CNT[2:0];
				TMR_CE[4] <= &CNT[3:0];
				TMR_CE[5] <= &CNT[4:0];
				TMR_CE[6] <= &CNT[5:0];
				TMR_CE[7] <= &CNT[6:0];
			end
		end
	end
	wire TMRA_CE = TMR_CE[CR8.TACTL];
	wire TMRB_CE = TMR_CE[CR9.TBCTL];
	wire TMRC_CE = TMR_CE[CR10.TCCTL];
	
	//DMA
	always @(posedge CLK or negedge RST_N) begin
		bit          DEXE_OLD;
		bit  [10: 0] DMA_LEN_NEXT;
	
		if (!RST_N) begin
			DMA_MA <= '0;
			DMA_RA <= '0;
			DMA_LEN <= '0;
			DMA_WR <= 0;
			DMA_EXEC <= 0;
			DEXE_OLD <= 0;
		end else if (!RES_N) begin
			DMA_EXEC <= 0;
		end else begin
			DEXE_OLD <= CR7.DEXE;
			if (CR7.DEXE && !DEXE_OLD) begin
				DMA_MA <= {CR6.DMEAH,CR5.DMEAL};
				DMA_RA <= CR6.DRGA;
				DMA_LEN <= CR7.DTLG;
				DMA_WR <= 0;
				DMA_EXEC <= 1;
			end
			
			DMA_LEN_NEXT = DMA_LEN - 11'd1;
			if (DMA_EXEC) begin
				if (!DMA_WR && MEM_DEV_LATCH == 3'd3 && CYCLE1_CE) begin
					DMA_MA <= DMA_MA + 19'd1;
					DMA_WR <= 1;
				end else if (DMA_WR && REG_ST == MS_DMA_WAIT && CYCLE1_CE) begin
					DMA_RA <= DMA_RA + 11'd1;
					DMA_WR <= 0;
					DMA_LEN <= DMA_LEN_NEXT;
					if (!DMA_LEN_NEXT) DMA_EXEC <= 0;
				end
			end
		end
	end
	
	//RAM access
	bit [20: 1] A;
	bit         WE_N;
	bit [ 1: 0] DQM;
//	bit         BURST;
	
	wire SCU_REQ = ~AD_N & ~CS_N & ~REQ_N;	//25A00000-25BFFFFF
	bit [20: 1] SCU_RA;
	bit         SCU_RPEND;
	bit         SCU_RRDY;
	bit [20: 1] SCU_WA;
	bit [15: 0] SCU_D;
	bit [ 1: 0] SCU_WE;
	bit         SCU_WPEND;
	bit         SCU_WRDY;
	bit [20: 1] SAVE_WA;
	bit [15: 0] SAVE_D;
	bit [ 1: 0] SAVE_WE;
	bit         SCPU_PEND;
	bit [ 2: 0] MEM_DEV_LATCH;
	always @(posedge CLK or negedge RST_N) begin
		bit         MEM_START;
		bit [ 2: 0] MEM_DEV;
		bit         REG_START;
		
		if (!RST_N) begin
			MEM_ST <= MS_IDLE;
			MEM_A <= '0;
			MEM_D <= '0;
			MEM_WE <= '0;
			MEM_RD <= 0;
			MEM_DEV_LATCH <= '0;
			REG_ST <= MS_IDLE;
			REG_A <= '0;
			REG_D <= '0;
			REG_WE <= '0;
			REG_RD <= 0;
			A <= '0;
			WE_N <= 1;
			DQM <= '1;
//			BURST <= 0;
			SCPU_PEND <= 0;
			SCDTACK_N <= 1;
			SCU_RPEND <= 0;
			SCU_RRDY <= 1;
			SCU_WPEND <= 0;
			SCU_WRDY <= 1;
//		end else if (!RES_N) begin
//			MEM_ST <= MS_IDLE;
//			MEM_WE <= '0;
//			MEM_RD <= 0;
//			MEM_DEV_LATCH <= '0;
//			REG_ST <= MS_IDLE;
//			REG_WE <= '0;
//			REG_RD <= 0;
//			
//			SCPU_PEND <= 0;
//			SCDTACK_N <= 1;
//			SCU_RPEND <= 0;
//			SCU_RRDY <= 1;
//			SCU_WPEND <= 0;
//			SCU_WRDY <= 1;
		end else begin
			if (!CS_N && DTEN_N && AD_N && CE_R) begin
				if (!DI[15]) begin
					A[20:9] <= DI[11:0];
					WE_N <= DI[14];
//					BURST <= DI[13];
				end else begin
					A[8:1] <= DI[7:0];
					DQM <= DI[13:12];
				end
			end
			
			if (SCU_REQ && WE_N) begin
				SCU_RA <= A;
				SCU_RPEND <= 1;
				SCU_RRDY <= 0;
				A <= A + 20'd1;
			end
			
			if (SCU_REQ && !WE_N && !DTEN_N) begin
				if (!SCU_WPEND) begin
					SCU_WA <= A;
					SCU_D <= DI;
					SCU_WE <= ~{2{WE_N}} & ~DQM;
					SCU_WPEND <= 1;
				end else begin
					SAVE_WA <= A;
					SAVE_D <= DI;
					SAVE_WE <= ~{2{WE_N}} & ~DQM;
					SCU_WRDY <= 0;
				end
				A <= A + 20'd1;
			end
			if (!SCU_WRDY && !SCU_WPEND) begin
				SCU_WA <= SAVE_WA;
				SCU_D <= SAVE_D;
				SCU_WE <= SAVE_WE;
				SCU_WPEND <= 1;
				SCU_WRDY <= 1;
			end
			
			if ((MEM_DEV_LATCH == 3'd4 && CYCLE0_CE) || (REG_ST == MS_SCU_WAIT && REG_RD && CYCLE1_CE)) begin
				SCU_RRDY <= 1;
				SCU_RPEND <= 0;
			end
			
			if (!SCAS_N && (!SCLDS_N || !SCUDS_N) && SCDTACK_N && SCFC != 3'b111 && MEM_DEV_LATCH != 3'd5 && !SCPU_PEND) SCPU_PEND <= 1;
			if ((MEM_ST == MS_SCPU_WAIT && CYCLE1_CE) || (REG_ST == MS_SCPU_WAIT && CYCLE1_CE)) SCPU_PEND <= 0;
			
			MEM_START <= CYCLE1_CE;
			MEM_RFS <= 0;
			case (MEM_ST)
				MS_IDLE: if (MEM_START) begin
					if (WD_READ && PCM_EN) begin
						MEM_A <= ADP[18:1];
						MEM_D <= '0;
						MEM_WE <= '0;
						MEM_RD <= 1;
						MEM_CS <= 1;
						MEM_DEV <= 3'd1;
						MEM_ST <= MS_WD_WAIT;
					end else if ((DSP_READ || DSP_WRITE) && DSP_EN) begin
						MEM_A <= DSP_MEMA_REG[18:1];
						MEM_D <= DSP_OUT_REG;
						MEM_WE <= {2{DSP_WRITE&~DSP_MEMA_REG[19]}};
						MEM_RD <= DSP_READ;
						MEM_CS <= 1;
						MEM_DEV <= 3'd2;
						MEM_ST <= MS_DSP_WAIT;
					end else if (DMA_EXEC && !DMA_WR) begin
						MEM_A <= DMA_MA[18:1];
						MEM_D <= '0;
						MEM_WE <= '0;
						MEM_RD <= 1;
						MEM_CS <= 1;
						MEM_DEV <= 3'd3;
						MEM_ST <= MS_DMA_WAIT;
					end else if (!SCU_WA[20] && SCU_WPEND) begin
						SCU_WPEND <= 0;
						MEM_A <= SCU_WA[18:1];
						MEM_D <= SCU_D;
						MEM_WE <= SCU_WE;
						MEM_RD <= 0;
						MEM_CS <= ~SCU_WA[19];
						MEM_DEV <= 3'd0;
						MEM_ST <= MS_SCU_WAIT;
`ifdef DEBUG
						if ({SCU_WA[19:1],1'b0} == 20'h004E0 && SCU_WE == 2'b10) DBG_SCU_HOOK <= SCU_D[15];
						if ({SCU_WA[19:1],1'b0} == 20'h00700 && SCU_WE[1]) DBG_SCU_700 <= SCU_D[15:8];
						if ({SCU_WA[19:1],1'b0} == 20'h00710 && SCU_WE[1]) DBG_SCU_710 <= SCU_D[15:8];
						if ({SCU_WA[19:1],1'b0} == 20'h00720 && SCU_WE[1]) DBG_SCU_720 <= SCU_D[15:8];
						if ({SCU_WA[19:1],1'b0} == 20'h00740 && SCU_WE[1]) DBG_SCU_740 <= SCU_D[15:8];
`endif
					end else if (!SCU_RA[20] && SCU_RPEND && MEM_DEV_LATCH != 3'd4) begin
						MEM_A <= SCU_RA[18:1];
						MEM_WE <= 2'b00;
						MEM_RD <= 1;
						MEM_CS <= ~SCU_RA[19];
						MEM_DEV <= 3'd4;
						MEM_ST <= MS_SCU_WAIT;
					end else if (SCA[23:20] == 4'h0 && SCPU_PEND) begin
						MEM_A <= SCA[18:1];
						MEM_D <= SCDI;
						MEM_WE <= {~SCRW_N&~SCUDS_N,~SCRW_N&~SCLDS_N};
						MEM_RD <= SCRW_N;
						MEM_CS <= 1;
						MEM_DEV <= SCRW_N ? 3'd5 : 3'd0;
						if (!SCRW_N) SCDTACK_N <= 0;
						MEM_ST <= MS_SCPU_WAIT;
`ifdef DEBUG
//						DBG_68K_ERR <= ({SCA[20:1],1'b0} == 21'h001682) || ({SCA[20:1],1'b0} == 21'h00168C) || ({SCA[20:1],1'b0} == 21'h001696);
						DBG_68K_ERR <= ({SCA[23:1],1'b0} >= 24'h080000 && {SCA[23:1],1'b0} < 24'h100000) || ({SCA[23:1],1'b0} >= 24'h100EE4);
						if ({SCA[19:1],1'b0} == 20'h004E0 && !SCUDS_N && !SCRW_N) DBG_SCU_HOOK <= SCDI[15];
						if ({SCA[19:1],1'b0} == 20'h00700 && !SCUDS_N && !SCRW_N) DBG_SCU_700 <= SCDI[15:8];
						if ({SCA[19:1],1'b0} == 20'h00710 && !SCUDS_N && !SCRW_N) DBG_SCU_710 <= SCDI[15:8];
						if ({SCA[19:1],1'b0} == 20'h00720 && !SCUDS_N && !SCRW_N) DBG_SCU_720 <= SCDI[15:8];
						if ({SCA[19:1],1'b0} == 20'h00740 && !SCUDS_N && !SCRW_N) DBG_SCU_740 <= SCDI[15:8];
`endif
					end else begin
						MEM_DEV <= 3'd0;
						MEM_RFS <= 1;
					end
				end
				
				MS_WD_WAIT: begin
					if (CYCLE1_CE) begin
						MEM_WE <= '0;
						MEM_RD <= 0;
						MEM_CS <= 0;
						MEM_ST <= MS_IDLE;
					end
				end

				
				MS_DSP_WAIT: begin
					if (CYCLE1_CE) begin
						MEM_WE <= '0;
						MEM_RD <= 0;
						MEM_CS <= 0;
						MEM_ST <= MS_IDLE;
					end
				end
				
				MS_DMA_WAIT: begin
					if (CYCLE1_CE) begin
						MEM_WE <= '0;
						MEM_RD <= 0;
						MEM_CS <= 0;
						MEM_ST <= MS_IDLE;
					end
				end
				
				MS_SCU_WAIT: begin
					if (CYCLE1_CE) begin
						MEM_WE <= '0;
						MEM_RD <= 0;
						MEM_CS <= 0;
						MEM_ST <= MS_IDLE;
					end
				end
				
				MS_SCPU_WAIT: begin
					if (CYCLE1_CE) begin
						MEM_WE <= '0;
						MEM_RD <= 0;
						MEM_CS <= 0;
						MEM_ST <= MS_IDLE;
					end
				end
				
				default:;
			endcase
			
			if (CYCLE0_CE) begin
				MEM_DEV_LATCH <= MEM_DEV;
				case (MEM_DEV_LATCH)
					3'd1: MEM_WD <= RAM_Q;
					3'd2: DSP_INP_REG <= RAM_Q;
					3'd3: DMA_DAT <= RAM_Q;
					3'd4: DO <= RAM_Q;
					3'd5: SCDO <= RAM_Q;
				endcase
			end
			if (CYCLE1_CE) begin
				case (MEM_DEV_LATCH)
					3'd5: SCDTACK_N <= 0;
				endcase
			end
			
			REG_START <= CYCLE0_CE;
			case (REG_ST)
				MS_IDLE: if (REG_START) begin
					if (DMA_EXEC && DMA_WR) begin
						REG_A <= DMA_RA;
						REG_D <= DMA_DAT & {16{~CR7.DGATE}};
						REG_WE <= '1;
						REG_RD <= 0;
						REG_ST <= MS_DMA_WAIT;
					end else if (SCU_WA[20] && SCU_WPEND) begin
						SCU_WPEND <= 0;
						REG_A <= SCU_WA[11:1];
						REG_D <= SCU_D;
						REG_WE <= SCU_WE;
						REG_RD <= 0;
						REG_ST <= MS_SCU_WAIT;
					end else if (SCU_RA[20] && SCU_RPEND) begin
						REG_A <= SCU_RA[11:1];
						REG_WE <= 2'b00;
						REG_RD <= 1;
						REG_ST <= MS_SCU_WAIT;
					end else if (SCA[23:20] == 4'h1 && SCPU_PEND) begin
						SCDTACK_N <= 0;
						REG_A <= SCA[11:1];
						REG_D <= SCDI;
						REG_WE <= {~SCRW_N&~SCUDS_N,~SCRW_N&~SCLDS_N};
						REG_RD <= SCRW_N;
						REG_ST <= MS_SCPU_WAIT;
`ifdef DEBUG
						DBG_68K_ERR <= ({SCA[23:1],1'b0} >= 24'h080000 && {SCA[23:1],1'b0} < 24'h100000) || ({SCA[23:1],1'b0} >= 24'h100EE4);
`endif
					end
				end
				
				MS_DMA_WAIT: begin
					if (CYCLE1_CE) begin
						REG_WE <= '0;
						REG_RD <= 0;
						REG_ST <= MS_IDLE;
					end
				end
				
				MS_SCU_WAIT: begin
					if (CYCLE1_CE) begin
						DO <= REG_Q;
						REG_WE <= '0;
						REG_RD <= 0;
						REG_ST <= MS_IDLE;
					end
				end
				
				MS_SCPU_WAIT: begin
					if (CYCLE1_CE) begin
						SCDO <= REG_Q;
						REG_WE <= '0;
						REG_RD <= 0;
						REG_ST <= MS_IDLE;
					end
				end
				
				default:;
			endcase
			
			if (SCAS_N && !SCDTACK_N) begin
				SCDTACK_N <= 1;
			end
		end
	end
	
	assign RAM_A = MEM_A;
	assign RAM_D = MEM_D;
	assign RAM_WE = MEM_WE;
	assign RAM_RD = MEM_RD;
	assign RAM_CS = MEM_CS;
	assign RAM_RFS = MEM_RFS;
	
	//Registers
	always @(posedge CLK or negedge RST_N) begin
		bit DMA_EXEC_OLD;
		bit REG_RD_DELAY;
		
		if (!RST_N) begin
			CR0 <= '0;
			CR1 <= '0;
			CR2 <= '0;
			CR3 <= '0;
			CR4 <= 16'h007F;
			CR5 <= '0;
			CR6 <= '0;
			CR7 <= '0;
			CR8 <= '0;
			CR9 <= '0;
			CR10 <= '0;
			CR11 <= '0;
			CR12 <= '0;
			CR13 <= '0;
			CR14 <= '0;
			CR15 <= '0;
			CR16 <= '0;
			CR17 <= '0;
			CR18 <= '0;
			CR19 <= '0;
			DSP_MPRO_SET <= '{128{0}};
			REG_Q <= '0;
		end else begin
			if (!RES_N) begin
				CR0 <= '0;
				CR1 <= '0;
				CR2 <= '0;
				CR3 <= '0;
				CR4 <= 16'h007F;
				CR5 <= '0;
				CR6 <= '0;
				CR7 <= '0;
				CR8 <= '0;
				CR9 <= '0;
				CR10 <= '0;
				CR11 <= '0;
				CR12 <= '0;
				CR13 <= '0;
				CR14 <= '0;
				CR15 <= '0;
				CR16 <= '0;
				CR17 <= '0;
				CR18 <= '0;
				CR19 <= '0;
				DSP_MPRO_SET <= '{128{0}};
			end else begin
				DMA_EXEC_OLD <= DMA_EXEC;
				if (!DMA_EXEC && DMA_EXEC_OLD) begin
					{CR12.SCIPD[4],CR18.MCIPD[4]} <= '1;
					CR7.DEXE <= 0;
				end
				if (TMRA_CE) begin
					CR8.TIMA  <= CR8.TIMA  + 8'd1;
					if (CR8.TIMA == 8'hFF) {CR12.SCIPD[6],CR18.MCIPD[6]} <= '1;
				end
				if (TMRB_CE) begin
					CR9.TIMB  <= CR9.TIMB  + 8'd1;
					if (CR9.TIMB == 8'hFF) {CR12.SCIPD[7],CR18.MCIPD[7]} <= '1;
				end
				if (TMRC_CE) begin
					CR10.TIMC <= CR10.TIMC + 8'd1;
					if (CR10.TIMC == 8'hFF) {CR12.SCIPD[8],CR18.MCIPD[8]} <= '1;
				end
				if (SAMPLE_CE) begin
					{CR12.SCIPD[10],CR18.MCIPD[10]} <= '1;
				end

				REG_RD_DELAY <= REG_RD;
				if (REG_WE && CYCLE1_CE) begin
					if (REG_A[11:9] == 3'b010) begin
						case ({REG_A[5:1],1'b0})
							6'h00: begin
								if (REG_WE[0]) CR0[ 7:0] <= REG_D[ 7:0] & CR0_MASK[ 7:0];
								if (REG_WE[1]) CR0[15:8] <= REG_D[15:8] & CR0_MASK[15:8];
							end
							6'h02: begin
								if (REG_WE[0]) CR1[ 7:0] <= REG_D[ 7:0] & CR1_MASK[ 7:0];
								if (REG_WE[1]) CR1[15:8] <= REG_D[15:8] & CR1_MASK[15:8];
							end
							6'h04: begin
								if (REG_WE[0]) CR2[ 7:0] <= REG_D[ 7:0] & CR2_MASK[ 7:0];
								if (REG_WE[1]) CR2[15:8] <= REG_D[15:8] & CR2_MASK[15:8];
							end
							6'h06: begin
								if (REG_WE[0]) CR3[ 7:0] <= REG_D[ 7:0] & CR3_MASK[ 7:0];
								if (REG_WE[1]) CR3[15:8] <= REG_D[15:8] & CR3_MASK[15:8];
							end
							6'h08: begin
								//if (MEM_WE[0]) CR4[ 7:0] <= MEM_D[ 7:0] & CR4_WMASK[ 7:0];
								//if (MEM_WE[1]) CR4[15:8] <= MEM_D[15:8] & CR4_WMASK[15:8];
								if (REG_WE[1]) CR4[15:11] <= REG_D[15:11];
							end
							6'h12: begin
								if (REG_WE[0] && !DMA_EXEC) CR5[ 7:0] <= REG_D[ 7:0] & CR5_MASK[ 7:0];
								if (REG_WE[1] && !DMA_EXEC) CR5[15:8] <= REG_D[15:8] & CR5_MASK[15:8];
							end
							6'h14: begin
								if (REG_WE[0] && !DMA_EXEC) CR6[ 7:0] <= REG_D[ 7:0] & CR6_MASK[ 7:0];
								if (REG_WE[1] && !DMA_EXEC) CR6[15:8] <= REG_D[15:8] & CR6_MASK[15:8];
							end
							6'h16: begin
								if (REG_WE[0] && !DMA_EXEC) CR7[ 7:0] <= REG_D[ 7:0] & CR7_MASK[ 7:0];
								if (REG_WE[1] && !DMA_EXEC) CR7[15:8] <= REG_D[15:8] & CR7_MASK[15:8];
							end
							6'h18: begin
								if (REG_WE[0]) CR8[ 7:0] <= REG_D[ 7:0] & CR8_MASK[ 7:0];
								if (REG_WE[1]) CR8[15:8] <= REG_D[15:8] & CR8_MASK[15:8];
							end
							6'h1A: begin
								if (REG_WE[0]) CR9[ 7:0] <= REG_D[ 7:0] & CR9_MASK[ 7:0];
								if (REG_WE[1]) CR9[15:8] <= REG_D[15:8] & CR9_MASK[15:8];
							end
							6'h1C: begin
								if (REG_WE[0]) CR10[ 7:0] <= REG_D[ 7:0] & CR10_MASK[ 7:0];
								if (REG_WE[1]) CR10[15:8] <= REG_D[15:8] & CR10_MASK[15:8];
							end
							6'h1E: begin
								if (REG_WE[0]) CR11[ 7:0] <= REG_D[ 7:0] & CR11_MASK[ 7:0];
								if (REG_WE[1]) CR11[15:8] <= REG_D[15:8] & CR11_MASK[15:8];
							end
							6'h20: begin
								if (REG_WE[0]) CR12[5] <= REG_D[5];
							end
							6'h22: begin
								if (REG_WE[0]) CR13[ 7:0] <= REG_D[ 7:0] & CR13_MASK[ 7:0];
								if (REG_WE[1]) CR13[15:8] <= REG_D[15:8] & CR13_MASK[15:8];
								if (REG_WE[0]) CR12.SCIPD[ 7:0] <= CR12.SCIPD[ 7:0] & ~REG_D[ 7:0];
								if (REG_WE[1]) CR12.SCIPD[10:8] <= CR12.SCIPD[10:8] & ~REG_D[10:8];
							end
							6'h24: begin
								if (REG_WE[0]) CR14[ 7:0] <= REG_D[ 7:0] & CR14_MASK[ 7:0];
								if (REG_WE[1]) CR14[15:8] <= REG_D[15:8] & CR14_MASK[15:8];
							end
							6'h26: begin
								if (REG_WE[0]) CR15[ 7:0] <= REG_D[ 7:0] & CR15_MASK[ 7:0];
								if (REG_WE[1]) CR15[15:8] <= REG_D[15:8] & CR15_MASK[15:8];
							end
							6'h28: begin
								if (REG_WE[0]) CR16[ 7:0] <= REG_D[ 7:0] & CR16_MASK[ 7:0];
								if (REG_WE[1]) CR16[15:8] <= REG_D[15:8] & CR16_MASK[15:8];
							end
							6'h2A: begin
								if (REG_WE[0]) CR17[ 7:0] <= REG_D[ 7:0] & CR17_MASK[ 7:0];
								if (REG_WE[1]) CR17[15:8] <= REG_D[15:8] & CR17_MASK[15:8];
							end
							6'h2C: begin
								if (REG_WE[0]) CR18[5] <= REG_D[5];
							end
							6'h2E: begin
								if (REG_WE[0]) CR19[ 7:0] <= REG_D[ 7:0] & CR19_MASK[ 7:0];
								if (REG_WE[1]) CR19[15:8] <= REG_D[15:8] & CR19_MASK[15:8];
								if (REG_WE[0]) CR18.MCIPD[ 7:0] <= CR18.MCIPD[ 7:0] & ~REG_D[ 7:0];
								if (REG_WE[1]) CR18.MCIPD[10:8] <= CR18.MCIPD[10:8] & ~REG_D[10:8];
							end
							default:;
						endcase
	//				end else if (REG_A[11:9] == 3'b011) begin
	//					if (MEM_WE[0]) STACK[REG_A[7:1]][ 7:0] <= MEM_D[ 7:0];
	//					if (MEM_WE[1]) STACK[REG_A[7:1]][15:8] <= MEM_D[15:8];
					end else if (MPRO_SEL) begin
						if (REG_A[2:1] == 2'b11) DSP_MPRO_SET[REG_A[9:3]] <= 1;
					end
				end else if (REG_RD_DELAY) begin
					if (REG_A[11:10] == 2'b00) begin
						case ({REG_A[4:1],1'b0})
							5'h00: REG_Q <= SCR_SCR0_Q & SCR0_MASK;
							5'h02: REG_Q <= SCR_SA_Q & SA_MASK;
							5'h04: REG_Q <= SCR_LSA_Q & LSA_MASK;
							5'h06: REG_Q <= SCR_LEA_Q & LEA_MASK;
							5'h08: REG_Q <= SCR_SCR1_Q & SCR1_MASK;
							5'h0A: REG_Q <= SCR_SCR2_Q & SCR2_MASK;
							5'h0C: REG_Q <= SCR_SCR3_Q & SCR3_MASK;
							5'h0E: REG_Q <= SCR_SCR4_Q & SCR4_MASK;
							5'h10: REG_Q <= SCR_SCR5_Q & SCR5_MASK;
							5'h12: REG_Q <= SCR_SCR6_Q & SCR6_MASK;
							5'h14: REG_Q <= SCR_SCR7_Q & SCR7_MASK;
							5'h16: REG_Q <= SCR_SCR8_Q & SCR8_MASK;
							default:REG_Q <= '0;
						endcase
					end else if (REG_A[11:9] == 3'b010) begin
						case ({REG_A[5:1],1'b0})
							6'h00: REG_Q <= CR0 & CR0_MASK;
							6'h02: REG_Q <= CR1 & CR1_MASK;
							6'h04: REG_Q <= CR2 & CR2_MASK;
							6'h06: REG_Q <= CR3 & CR3_MASK;
							6'h08: REG_Q <= CR4 & CR4_RMASK;
							6'h12: REG_Q <= CR5 & CR5_MASK;
							6'h14: REG_Q <= CR6 & CR6_MASK;
							6'h16: REG_Q <= CR7 & CR7_MASK;
							6'h18: REG_Q <= CR8 & CR8_MASK;
							6'h1A: REG_Q <= CR9 & CR9_MASK;
							6'h1C: REG_Q <= CR10 & CR10_MASK;
							6'h1E: REG_Q <= CR11 & CR11_MASK;
							6'h20: REG_Q <= CR12 & CR12_MASK;
							6'h22: REG_Q <= CR13 & CR13_MASK;
							6'h24: REG_Q <= CR14 & CR14_MASK;
							6'h26: REG_Q <= CR15 & CR15_MASK;
							6'h28: REG_Q <= CR16 & CR16_MASK;
							6'h2A: REG_Q <= CR17 & CR17_MASK;
							6'h2C: REG_Q <= CR18 & CR18_MASK;
							6'h2E: REG_Q <= CR19 & CR19_MASK;
							default: REG_Q <= '0;
						endcase
`ifndef DEBUG
//					end else if (SOUS_SEL) begin
//						REG_Q <= STACK1_Q;
					end else if (COEF_SEL) begin
						REG_Q <= COEF_RAM_Q & COEF_MASK;
					end else if (MADRS_SEL) begin
						REG_Q <= MADRS_RAM_Q & MADRS_MASK;
					end else if (MPRO_SEL) begin
						case (REG_A[2:1])
							2'b00: REG_Q <= MPRO_RAM_Q[63:48] & MPRO_MASK[63:48];
							2'b01: REG_Q <= MPRO_RAM_Q[47:32] & MPRO_MASK[47:32];
							2'b10: REG_Q <= MPRO_RAM_Q[31:16] & MPRO_MASK[31:16];
							2'b11: REG_Q <= MPRO_RAM_Q[15: 0] & MPRO_MASK[15: 0];
						endcase
					end else if (TEMP_SEL) begin
						case (REG_A[1])
							1'b0: REG_Q <= TEMP_RAM_Q[15: 0] & TEMP_MASK[15: 0];
							1'b1: REG_Q <= TEMP_RAM_Q[31:16] & TEMP_MASK[31:16];
						endcase
					end else if (MEMS_SEL) begin
						case (REG_A[1])
							1'b0: REG_Q <= MEMS_RAM_Q[15: 0] & MEMS_MASK[15: 0];
							1'b1: REG_Q <= MEMS_RAM_Q[31:16] & MEMS_MASK[31:16];
						endcase
//					end else if (MIXS_SEL) begin
//						case (REG_A[1])
//							1'b0: REG_Q <= MIXS_RAM_Q[15: 0] & MIXS_MASK[15: 0];
//							1'b1: REG_Q <= MIXS_RAM_Q[31:16] & MIXS_MASK[31:16];
//						endcase
					end else if (EFREG_SEL) begin
						REG_Q <= EFREG_RAM_Q & EFREG_MASK;
					end else if (EXTS_SEL) begin
						REG_Q <= DSP_EXTS[REG_A[1]];
`endif
					end else begin
						REG_Q <= '0;
					end
				end
				
				if (OP3.SLOT == CR4.MSLC && SLOT1_CE) begin
					CR4.CA <= SAO[15:12];
					CR4.SGC <= 2'b11;
				end
			end
		end
	end
	
	
	wire       SCR_SEL = REG_A[11:10] == 2'b00;	
	wire       SCR_SCR0_SEL  = SCR_SEL & (REG_A[4:1] == 5'h00>>1);
	bit [15:0] SCR_SCR0_Q;
	SCSP_RAM_8X2 #(5) SCR_SCR0(CLK, OP2.RST ? OP2.SLOT : REG_A[9:5], OP2.RST ? '0 : REG_D, OP2.RST ? 2'b11 : (REG_WE & {2{SCR_SCR0_SEL}}), (REG_RD ? REG_A[9:5] : OP2.SLOT), SCR_SCR0_Q);
	
	wire       SCR_SA_SEL   = SCR_SEL & (REG_A[4:1] == 5'h02>>1);
	bit [15:0] SCR_SA_Q;
	SCSP_RAM_8X2 #(5) SCR_SA  (CLK, OP2.RST ? OP2.SLOT : REG_A[9:5], OP2.RST ? '0 : REG_D, OP2.RST ? 2'b11 : (REG_WE & {2{SCR_SA_SEL}})  , (REG_RD ? REG_A[9:5] : OP2.SLOT), SCR_SA_Q);
	
	wire       SCR_LSA_SEL  = SCR_SEL & (REG_A[4:1] == 5'h04>>1);
	bit [15:0] SCR_LSA_Q;
	SCSP_RAM_8X2 #(5) SCR_LSA (CLK, OP2.RST ? OP2.SLOT : REG_A[9:5], OP2.RST ? '0 : REG_D, OP2.RST ? 2'b11 : (REG_WE & {2{SCR_LSA_SEL}}) , (REG_RD ? REG_A[9:5] : OP2.SLOT), SCR_LSA_Q);
	
	wire       SCR_LEA_SEL  = SCR_SEL & (REG_A[4:1] == 5'h06>>1);
	bit [15:0] SCR_LEA_Q;
	SCSP_RAM_8X2 #(5) SCR_LEA (CLK, OP2.RST ? OP2.SLOT : REG_A[9:5], OP2.RST ? '0 : REG_D, OP2.RST ? 2'b11 : (REG_WE & {2{SCR_LEA_SEL}}) , (REG_RD ? REG_A[9:5] : OP2.SLOT), SCR_LEA_Q);
	
	wire       SCR_SCR1_SEL = SCR_SEL & (REG_A[4:1] == 5'h08>>1);
	bit [15:0] SCR_SCR1_Q;
	SCSP_RAM_8X2 #(5) SCR_SCR1(CLK, OP4.RST ? OP4.SLOT : REG_A[9:5], OP4.RST ? '0 : REG_D, OP4.RST ? 2'b11 : (REG_WE & {2{SCR_SCR1_SEL}}), (REG_RD ? REG_A[9:5] : OP4.SLOT), SCR_SCR1_Q);
	
	wire       SCR_SCR2_SEL = SCR_SEL & (REG_A[4:1] == 5'h0A>>1);
	bit [15:0] SCR_SCR2_Q;
	SCSP_RAM_8X2 #(5) SCR_SCR2(CLK, OP4.RST ? OP4.SLOT : REG_A[9:5], OP4.RST ? '0 : REG_D, OP4.RST ? 2'b11 : (REG_WE & {2{SCR_SCR2_SEL}}), (REG_RD ? REG_A[9:5] : OP4.SLOT), SCR_SCR2_Q);
	
	wire       SCR_SCR3_SEL = SCR_SEL & (REG_A[4:1] == 5'h0C>>1);
	bit [15:0] SCR_SCR3_Q;
	SCSP_RAM_8X2 #(5) SCR_SCR3(CLK, OP6.RST ? OP6.SLOT : REG_A[9:5], OP6.RST ? '0 : REG_D, OP6.RST ? 2'b11 : (REG_WE & {2{SCR_SCR3_SEL}}), (REG_RD ? REG_A[9:5] : OP6.SLOT), SCR_SCR3_Q);
	
	wire       SCR_SCR4_SEL = SCR_SEL & (REG_A[4:1] == 5'h0E>>1);
	bit [15:0] SCR_SCR4_Q;
	SCSP_RAM_8X2 #(5) SCR_SCR4(CLK, OP2.RST ? OP2.SLOT : REG_A[9:5], OP2.RST ? '0 : REG_D, OP2.RST ? 2'b11 : (REG_WE & {2{SCR_SCR4_SEL}}), (REG_RD ? REG_A[9:5] : OP2.SLOT), SCR_SCR4_Q);
	
	wire       SCR_SCR5_SEL = SCR_SEL & (REG_A[4:1] == 5'h10>>1);
	bit [15:0] SCR_SCR5_Q;
	SCSP_RAM_8X2 #(5) SCR_SCR5(CLK,     RST ?     SLOT : REG_A[9:5],     RST ? '0 : REG_D,     RST ? 2'b11 : (REG_WE & {2{SCR_SCR5_SEL}}), (REG_RD ? REG_A[9:5] :     SLOT), SCR_SCR5_Q);
	
	wire       SCR_SCR6_SEL = SCR_SEL & (REG_A[4:1] == 5'h12>>1);
	bit [15:0] SCR_SCR6_Q;
	SCSP_RAM_8X2 #(5) SCR_SCR6(CLK,     RST ?     SLOT : REG_A[9:5],     RST ? '0 : REG_D,     RST ? 2'b11 : (REG_WE & {2{SCR_SCR6_SEL}}), (REG_RD ? REG_A[9:5] :     SLOT), SCR_SCR6_Q);

	wire       SCR_SCR7_SEL = SCR_SEL & (REG_A[4:1] == 5'h14>>1);
	bit [15:0] SCR_SCR7_Q;
	SCSP_RAM_8X2 #(5) SCR_SCR7(CLK, OP7.RST ? OP7.SLOT : REG_A[9:5], OP7.RST ? '0 : REG_D, OP7.RST ? 2'b11 : (REG_WE & {2{SCR_SCR7_SEL}}), (REG_RD ? REG_A[9:5] : OP7.SLOT), SCR_SCR7_Q);
	
	wire       SCR_SCR8_SEL = SCR_SEL & (REG_A[4:1] == 5'h16>>1);
	bit [15:0] SCR_SCR8_Q;
	SCSP_RAM_8X2 #(5) SCR_SCR8(CLK, OP7.RST ? OP7.SLOT : REG_A[9:5], OP7.RST ? '0 : REG_D, OP7.RST ? 2'b11 : (REG_WE & {2{SCR_SCR8_SEL}}), (REG_RD ? REG_A[9:5] : OP7.SLOT), SCR_SCR8_Q);
	
	//STACK,100600-10067F
	wire       SOUS_SEL = REG_A[11:7] == 5'b01100;
	bit [15:0] STACK0_Q,STACK1_Q;
	SCSP_STACK_RAM STACK1 (CLK, OP7.SLOT, OP7.SD  , {2{~OP7.STWINH&SLOT1_CE}}, STACK_RA[4:0], STACK1_Q);
	SCSP_STACK_RAM STACK0 (CLK, OP7.SLOT, STACK1_Q, {2{            SLOT1_CE}}, STACK_RA[4:0], STACK0_Q);
	
	//COEF,100700-10077F
	wire       COEF_SEL = REG_A[11:7] == 5'b01110;
	bit [15:0] COEF_RAM_Q;
	SCSP_RAM_8X2 #(6) COEF_RAM (CLK, REG_A[6:1], REG_D, REG_WE & {2{COEF_SEL}} & {2{CYCLE1_CE}}, (REG_RD ? REG_A[6:1] : DSP_COEF_RA), COEF_RAM_Q);
	
	//MADRS,100780-1007BF
	wire       MADRS_SEL = REG_A[11:6] == 6'b011110;
	bit [15:0] MADRS_RAM_Q;
	SCSP_RAM_8X2 #(5) MADRS_RAM (CLK, REG_A[5:1], REG_D, REG_WE & {2{MADRS_SEL}} & {2{CYCLE1_CE}}, (REG_RD ? REG_A[5:1] : DSP_MADRS_RA), MADRS_RAM_Q);
	
	//MPRO,100800-100BFF
	wire       MPRO_SEL = REG_A[11:10] == 2'b10;
	wire       MPRO0_SEL = MPRO_SEL & (REG_A[2:1] == 3'h0>>1);
	wire       MPRO1_SEL = MPRO_SEL & (REG_A[2:1] == 3'h2>>1);
	wire       MPRO2_SEL = MPRO_SEL & (REG_A[2:1] == 3'h4>>1);
	wire       MPRO3_SEL = MPRO_SEL & (REG_A[2:1] == 3'h6>>1);
	bit [63:0] MPRO_RAM_Q;
	SCSP_MPRO_RAM MPRO_RAM (CLK, REG_A[9:3], {4{REG_D}}, ({4{REG_WE}} & {{2{MPRO0_SEL}},{2{MPRO1_SEL}},{2{MPRO2_SEL}},{2{MPRO3_SEL}}}), (REG_RD ? REG_A[9:3] : DSP_MPRO_STEP), MPRO_RAM_Q);
	
	//TEMP,100C00-100DFF
	wire       TEMP_SEL = REG_A[11:9] == 3'b110;
	wire       TEMP0_SEL = TEMP_SEL & (REG_A[1:1] == 2'h0>>1);
	wire       TEMP1_SEL = TEMP_SEL & (REG_A[1:1] == 2'h2>>1);
	bit [31:0] TEMP_RAM_Q;
	SCSP_RAM_8X4 #(7) TEMP_RAM (CLK, (DSP_TEMP_WE ? DSP_TEMP_WA : REG_A[8:2]), (DSP_TEMP_WE ? {DSP_TEMP_D[23:8],8'h00,DSP_TEMP_D[7:0]} : {2{REG_D}}), (({2{REG_WE}} & {{2{TEMP0_SEL}},{2{TEMP1_SEL}}}) | {4{DSP_TEMP_WE}}) & {4{CYCLE1_CE}}, (REG_RD ? REG_A[8:2] : DSP_TEMP_RA), TEMP_RAM_Q);
	
	//MEMS,100E00-100E7F
	wire       MEMS_SEL = REG_A[11:7] == 5'b11100;
	wire       MEMS0_SEL = MEMS_SEL & (REG_A[1:1] == 2'h0>>1);
	wire       MEMS1_SEL = MEMS_SEL & (REG_A[1:1] == 2'h2>>1);
	bit [31:0] MEMS_RAM_Q;
	SCSP_RAM_8X4 #(5) MEMS_RAM (CLK, (DSP_MEMS_WE ? DSP_MEMS_WA : REG_A[6:2]), (DSP_MEMS_WE ? {DSP_MEMS_D[23:8],8'h00,DSP_MEMS_D[7:0]} : {2{REG_D}}), ((REG_WE & {{2{MEMS0_SEL}},{2{MEMS1_SEL}}}) | {4{DSP_MEMS_WE}}) & {4{CYCLE1_CE}}, (REG_RD ? REG_A[6:2] : DSP_MEMS_RA), MEMS_RAM_Q);
	
	//MIXS,100E80-100EBF
//	wire       MIXS_SEL = REG_A[11:6] == 12'hE80>>6;
//	wire       MIXS0_SEL = MIXS_SEL & (REG_A[1:1] == 2'h0>>1);
//	wire       MIXS1_SEL = MIXS_SEL & (REG_A[1:1] == 2'h2>>1);
//	bit [31:0] MIXS_RAM_Q;
//	SCSP_RAM_8X4 #(4) MIXS_RAM (CLK, (PCM_MIXS_WE ? PCM_MIXS_WA : REG_A[5:2]), (PCM_MIXS_WE ? {PCM_MIXS_D[19:4],12'h000,PCM_MIXS_D[3:0]} : {2{REG_D}}), ((REG_WE & {{2{MIXS0_SEL}},{2{MIXS1_SEL}}}) | {4{PCM_MIXS_WE}}) & {4{CYCLE1_CE}}, (PCM_MIXS_RD ? PCM_MIXS_RA : REG_RD ? REG_A[5:2] : DSP_MIXS_RA), MIXS_RAM_Q);
	
	//EFREG,100EC0-100EDF
	wire       EFREG_SEL = REG_A[11:5] == 7'b1110110;
	bit [15:0] EFREG_RAM_Q;
	SCSP_RAM_8X2 #(4) EFREG_RAM (CLK, (DSP_EFREG_WE ? DSP_EFREG_WA : REG_A[4:1]), (DSP_EFREG_WE ? DSP_EFREG_D : REG_D), ((REG_WE & {2{EFREG_SEL}}) | {2{DSP_EFREG_WE}}) & {2{CYCLE1_CE}}, (REG_RD ? REG_A[4:1] : DSP_EFREG_RA), EFREG_RAM_Q);
	
	//EXTS,100EE0-100EE3
	wire       EXTS_SEL = REG_A[11:2] == 12'hEE0>>2;
	
	
	
	bit [2:0] ILV;
	always_comb begin
		if      (CR12.SCIPD[10] & CR11.SCIEB[10]) ILV = {CR16.SCILV2[7],CR15.SCILV1[7],CR14.SCILV0[7]};
		else if (CR12.SCIPD[ 8] & CR11.SCIEB[ 8]) ILV = {CR16.SCILV2[7],CR15.SCILV1[7],CR14.SCILV0[7]};
		else if (CR12.SCIPD[ 7] & CR11.SCIEB[ 7]) ILV = {CR16.SCILV2[7],CR15.SCILV1[7],CR14.SCILV0[7]};
		else if (CR12.SCIPD[ 6] & CR11.SCIEB[ 6]) ILV = {CR16.SCILV2[6],CR15.SCILV1[6],CR14.SCILV0[6]};
		else if (CR12.SCIPD[ 5] & CR11.SCIEB[ 5]) ILV = {CR16.SCILV2[5],CR15.SCILV1[5],CR14.SCILV0[5]};
		else if (CR12.SCIPD[ 4] & CR11.SCIEB[ 4]) ILV = {CR16.SCILV2[4],CR15.SCILV1[4],CR14.SCILV0[4]};
		else                                      ILV = 3'b000;
	end
	
	assign RDY_N = ~(SCU_RRDY & SCU_WRDY);
	assign INT_N = ~|(CR18.MCIPD & CR17.MCIEB);
	
	assign SCIPL_N = ~ILV;
	assign SCAVEC_N = ~&SCFC;
	
`ifdef DEBUG
	assign PCM_EN_DBG = PCM_EN;
	assign SCA_DBG = {SCA,1'b0};
	assign SCR0_DBG = SCR0;
	assign SA_DBG   = SA;
	assign LSA_DBG  = LSA;
	assign LEA_DBG  = LEA;
	assign SCR1_DBG = SCR1;
	assign SCR2_DBG = SCR2;
	assign SCR3_DBG = SCR3;
	assign SCR4_DBG = SCR4;
	assign SCR5_DBG = SCR5;
	assign SCR6_DBG = SCR6;
	assign SCR7_DBG = SCR7;
	assign SCR8_DBG = SCR8;
	assign EST_DBG = EST;
	assign OP4_EFF_RATE_DBG = EFF_RATE;
	assign ENV_SAMPLE_CNT_DBG = ENV_SAMPLE_CNT;
	assign ENV_STEP_CNT_DBG = ENV_STEP_CNT;
	assign DSP_MPRO_DBG = MPRO0_Q;
	assign ADP_DBG = ADP;
`endif
	
endmodule

module SCSP_PHASE_RAM (
	input	         CLK,
	input	 [ 4: 0] WRADDR,
	input	 [17: 0] DATA,
	input	         WREN,
	input	 [ 4: 0] RDADDR,
	output [17: 0] Q);

//`ifdef DEBUG
//
//	wire [17:0] sub_wire0;
//
//	altdpram	altdpram_component (
//				.data (DATA),
//				.inclock (CLK),
//				.rdaddress (RDADDR),
//				.wraddress (WRADDR),
//				.wren (WREN),
//				.q (sub_wire0),
//				.aclr (1'b0),
//				.byteena (1'b1),
//				.inclocken (1'b1),
//				.rdaddressstall (1'b0),
//				.rden (1'b1),
//				//.sclr (1'b0),
//				.wraddressstall (1'b0));
//	defparam
//		altdpram_component.indata_aclr = "OFF",
//		altdpram_component.indata_reg = "INCLOCK",
//		altdpram_component.intended_device_family = "Cyclone V",
//		altdpram_component.lpm_type = "altdpram",
//		altdpram_component.outdata_aclr = "OFF",
//		altdpram_component.outdata_reg = "UNREGISTERED",
//		altdpram_component.power_up_uninitialized = "TRUE",
//		altdpram_component.ram_block_type = "MLAB",
//		altdpram_component.rdaddress_aclr = "OFF",
//		altdpram_component.rdaddress_reg = "UNREGISTERED",
//		altdpram_component.rdcontrol_aclr = "OFF",
//		altdpram_component.rdcontrol_reg = "UNREGISTERED",
//		altdpram_component.read_during_write_mode_mixed_ports = "CONSTRAINED_DONT_CARE",
//		altdpram_component.width = 18,
//		altdpram_component.widthad = 5,
//		altdpram_component.width_byteena = 1,
//		altdpram_component.wraddress_aclr = "OFF",
//		altdpram_component.wraddress_reg = "INCLOCK",
//		altdpram_component.wrcontrol_aclr = "OFF",
//		altdpram_component.wrcontrol_reg = "INCLOCK";
//		
//	assign Q = sub_wire0;
//	
//`else

	wire [17:0] sub_wire0;
	
	altsyncram	altsyncram_component (
				.address_a (WRADDR),
				.byteena_a (WREN),
				.clock0 (CLK),
				.data_a (DATA),
				.wren_a (|WREN),
				.address_b (RDADDR),
				.q_b (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b ({18{1'b1}}),
				.eccstatus (),
				.q_a (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_input_b = "BYPASS",
		altsyncram_component.clock_enable_output_b = "BYPASS",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 32,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.ram_block_type = "M10K",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.widthad_a = 5,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.width_a = 18,
		altsyncram_component.width_b = 18,
		altsyncram_component.width_byteena_a = 1;
	
	assign Q = sub_wire0;
	
//`endif

endmodule

module SCSP_SO_RAM (
	input	         CLK,
	input	 [ 4: 0] WRADDR,
	input	 [17: 0] DATA,
	input	         WREN,
	input	 [ 4: 0] RDADDR,
	output [17: 0] Q);
//
//`ifdef DEBUG
//
//	wire [16:0] sub_wire0;
//
//	altdpram	altdpram_component (
//				.data (DATA),
//				.inclock (CLK),
//				.rdaddress (RDADDR),
//				.wraddress (WRADDR),
//				.wren (WREN),
//				.q (sub_wire0),
//				.aclr (1'b0),
//				.byteena (1'b1),
//				.inclocken (1'b1),
//				.rdaddressstall (1'b0),
//				.rden (1'b1),
//				//.sclr (1'b0),
//				.wraddressstall (1'b0));
//	defparam
//		altdpram_component.indata_aclr = "OFF",
//		altdpram_component.indata_reg = "INCLOCK",
//		altdpram_component.intended_device_family = "Cyclone V",
//		altdpram_component.lpm_type = "altdpram",
//		altdpram_component.outdata_aclr = "OFF",
//		altdpram_component.outdata_reg = "UNREGISTERED",
//		altdpram_component.power_up_uninitialized = "TRUE",
//		altdpram_component.ram_block_type = "MLAB",
//		altdpram_component.rdaddress_aclr = "OFF",
//		altdpram_component.rdaddress_reg = "UNREGISTERED",
//		altdpram_component.rdcontrol_aclr = "OFF",
//		altdpram_component.rdcontrol_reg = "UNREGISTERED",
//		altdpram_component.read_during_write_mode_mixed_ports = "CONSTRAINED_DONT_CARE",
//		altdpram_component.width = 17,
//		altdpram_component.widthad = 5,
//		altdpram_component.width_byteena = 1,
//		altdpram_component.wraddress_aclr = "OFF",
//		altdpram_component.wraddress_reg = "INCLOCK",
//		altdpram_component.wrcontrol_aclr = "OFF",
//		altdpram_component.wrcontrol_reg = "INCLOCK";
//		
//	assign Q = sub_wire0;
//	
//`else

	wire [17:0] sub_wire0;
	
	altsyncram	altsyncram_component (
				.address_a (WRADDR),
				.byteena_a (WREN),
				.clock0 (CLK),
				.data_a (DATA),
				.wren_a (|WREN),
				.address_b (RDADDR),
				.q_b (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b ({18{1'b1}}),
				.eccstatus (),
				.q_a (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_input_b = "BYPASS",
		altsyncram_component.clock_enable_output_b = "BYPASS",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 32,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.ram_block_type = "M10K",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.widthad_a = 5,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.width_a = 18,
		altsyncram_component.width_b = 18,
		altsyncram_component.width_byteena_a = 1;
	
	assign Q = sub_wire0;
	
//`endif

endmodule

module SCSP_ENV_CNT_RAM (
	input	         CLK,
	input	 [ 4: 0] WRADDR,
	input	 [15: 0] DATA,
	input	         WREN,
	input	 [ 4: 0] RDADDR,
	output [15: 0] Q);

//`ifdef DEBUG
//	
//	wire [15:0] sub_wire0;
//	
//	altdpram	altdpram_component (
//				.data (DATA),
//				.inclock (CLK),
//				.rdaddress (RDADDR),
//				.wraddress (WRADDR),
//				.wren (WREN),
//				.q (sub_wire0),
//				.aclr (1'b0),
//				.byteena (1'b1),
//				.inclocken (1'b1),
//				.rdaddressstall (1'b0),
//				.rden (1'b1),
//				//.sclr (1'b0),
//				.wraddressstall (1'b0));
//	defparam
//		altdpram_component.indata_aclr = "OFF",
//		altdpram_component.indata_reg = "INCLOCK",
//		altdpram_component.intended_device_family = "Cyclone V",
//		altdpram_component.lpm_type = "altdpram",
//		altdpram_component.outdata_aclr = "OFF",
//		altdpram_component.outdata_reg = "UNREGISTERED",
//		altdpram_component.power_up_uninitialized = "TRUE",
//		altdpram_component.ram_block_type = "MLAB",
//		altdpram_component.rdaddress_aclr = "OFF",
//		altdpram_component.rdaddress_reg = "UNREGISTERED",
//		altdpram_component.rdcontrol_aclr = "OFF",
//		altdpram_component.rdcontrol_reg = "UNREGISTERED",
//		altdpram_component.read_during_write_mode_mixed_ports = "CONSTRAINED_DONT_CARE",
//		altdpram_component.width = 16,
//		altdpram_component.widthad = 5,
//		altdpram_component.width_byteena = 1,
//		altdpram_component.wraddress_aclr = "OFF",
//		altdpram_component.wraddress_reg = "INCLOCK",
//		altdpram_component.wrcontrol_aclr = "OFF",
//		altdpram_component.wrcontrol_reg = "INCLOCK";
//		
//	assign Q = sub_wire0;
//	
//`else

	wire [15:0] sub_wire0;
	
	altsyncram	altsyncram_component (
				.address_a (WRADDR),
				.byteena_a (WREN),
				.clock0 (CLK),
				.data_a (DATA),
				.wren_a (|WREN),
				.address_b (RDADDR),
				.q_b (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b ({16{1'b1}}),
				.eccstatus (),
				.q_a (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_input_b = "BYPASS",
		altsyncram_component.clock_enable_output_b = "BYPASS",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 32,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.ram_block_type = "M10K",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.widthad_a = 5,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.width_a = 16,
		altsyncram_component.width_b = 16,
		altsyncram_component.width_byteena_a = 1;
	
	assign Q = sub_wire0;
	
//`endif

endmodule

module SCSP_EVOL_RAM (
	input	         CLK,
	input	 [ 4: 0] WRADDR,
	input	 [11: 0] DATA,
	input	         WREN,
	input	 [ 4: 0] RDADDR,
	output [11: 0] Q);

//`ifdef DEBUG
//	
//	wire [11:0] sub_wire0;
//	
//	altdpram	altdpram_component (
//				.data (DATA),
//				.inclock (CLK),
//				.rdaddress (RDADDR),
//				.wraddress (WRADDR),
//				.wren (WREN),
//				.q (sub_wire0),
//				.aclr (1'b0),
//				.byteena (1'b1),
//				.inclocken (1'b1),
//				.rdaddressstall (1'b0),
//				.rden (1'b1),
//				//.sclr (1'b0),
//				.wraddressstall (1'b0));
//	defparam
//		altdpram_component.indata_aclr = "OFF",
//		altdpram_component.indata_reg = "INCLOCK",
//		altdpram_component.intended_device_family = "Cyclone V",
//		altdpram_component.lpm_type = "altdpram",
//		altdpram_component.outdata_aclr = "OFF",
//		altdpram_component.outdata_reg = "UNREGISTERED",
//		altdpram_component.power_up_uninitialized = "TRUE",
//		altdpram_component.ram_block_type = "MLAB",
//		altdpram_component.rdaddress_aclr = "OFF",
//		altdpram_component.rdaddress_reg = "UNREGISTERED",
//		altdpram_component.rdcontrol_aclr = "OFF",
//		altdpram_component.rdcontrol_reg = "UNREGISTERED",
//		altdpram_component.read_during_write_mode_mixed_ports = "CONSTRAINED_DONT_CARE",
//		altdpram_component.width = 12,
//		altdpram_component.widthad = 5,
//		altdpram_component.width_byteena = 1,
//		altdpram_component.wraddress_aclr = "OFF",
//		altdpram_component.wraddress_reg = "INCLOCK",
//		altdpram_component.wrcontrol_aclr = "OFF",
//		altdpram_component.wrcontrol_reg = "INCLOCK";
//		
//	assign Q = sub_wire0;
//	
//`else

	wire [11:0] sub_wire0;
	
	altsyncram	altsyncram_component (
				.address_a (WRADDR),
				.byteena_a (WREN),
				.clock0 (CLK),
				.data_a (DATA),
				.wren_a (|WREN),
				.address_b (RDADDR),
				.q_b (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b ({12{1'b1}}),
				.eccstatus (),
				.q_a (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_input_b = "BYPASS",
		altsyncram_component.clock_enable_output_b = "BYPASS",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 32,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.ram_block_type = "M10K",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.widthad_a = 5,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.width_a = 12,
		altsyncram_component.width_b = 12,
		altsyncram_component.width_byteena_a = 1;
	
	assign Q = sub_wire0;
	
//`endif

endmodule

module SCSP_STACK_RAM
(
	input         CLK,
	
	input   [4:0] WRADDR,
	input  [15:0] DATA,
	input   [1:0] WREN,
	input   [4:0] RDADDR,
	output [15:0] Q
);

`ifdef SIM
	
	reg [15:0] MEM [32];
	
	always @(posedge CLK) begin
		if (WREN[0]) begin
			MEM[WADDR][7:0] <= DATA[7:0];
		end
		if (WREN[1]) begin
			MEM[WADDR][15:8] <= DATA[15:8];
		end
	end
		
	assign Q = MEM[RDADDR];
	
//`elsif DEBUG
//
//	wire [15:0] sub_wire0;
//	
//	altdpram	altdpram_component (
//				.data (DATA),
//				.inclock (CLK),
//				.rdaddress (RDADDR),
//				.wraddress (WRADDR),
//				.wren (|WREN),
//				.byteena (WREN),
//				.q (sub_wire0),
//				.aclr (1'b0),
//				.inclocken (1'b1),
//				.rdaddressstall (1'b0),
//				.rden (1'b1),
////				.sclr (1'b0),
//				.wraddressstall (1'b0));
//	defparam
//		altdpram_component.byte_size = 8,
//		altdpram_component.indata_aclr = "OFF",
//		altdpram_component.indata_reg = "INCLOCK",
//		altdpram_component.intended_device_family = "Cyclone V",
//		altdpram_component.lpm_type = "altdpram",
//		altdpram_component.outdata_aclr = "OFF",
//		altdpram_component.outdata_reg = "UNREGISTERED",
//		altdpram_component.ram_block_type = "MLAB",
//		altdpram_component.rdaddress_aclr = "OFF",
//		altdpram_component.rdaddress_reg = "UNREGISTERED",
//		altdpram_component.rdcontrol_aclr = "OFF",
//		altdpram_component.rdcontrol_reg = "UNREGISTERED",
//		altdpram_component.read_during_write_mode_mixed_ports = "CONSTRAINED_DONT_CARE",
//		altdpram_component.width = 16,
//		altdpram_component.widthad = 5,
//		altdpram_component.width_byteena = 2,
//		altdpram_component.wraddress_aclr = "OFF",
//		altdpram_component.wraddress_reg = "INCLOCK",
//		altdpram_component.wrcontrol_aclr = "OFF",
//		altdpram_component.wrcontrol_reg = "INCLOCK";
//		
//	assign Q = sub_wire0;
	
`else

	wire [15:0] sub_wire0;
	
	altsyncram	altsyncram_component (
				.address_a (WRADDR),
				.byteena_a (WREN),
				.clock0 (CLK),
				.data_a (DATA),
				.wren_a (|WREN),
				.address_b (RDADDR),
				.q_b (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b ({16{1'b1}}),
				.eccstatus (),
				.q_a (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.byte_size = 8,
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_input_b = "BYPASS",
		altsyncram_component.clock_enable_output_b = "BYPASS",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 32,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.ram_block_type = "M10K",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.widthad_a = 5,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.width_a = 16,
		altsyncram_component.width_b = 16,
		altsyncram_component.width_byteena_a = 2;
	
	assign Q = sub_wire0;
	
`endif
	
endmodule

module SCSP_RAM_8X2
#(
	parameter addr_width = 5
)
(
	input         CLK,
	
	input  [addr_width-1:0] WRADDR,
	input            [15:0] DATA,
	input             [1:0] WREN,
	input  [addr_width-1:0] RDADDR,
	output           [15:0] Q
);

`ifdef SIM
	
	reg [15:0] MEM [1**addr_width];
	
	always @(posedge CLK) begin
		if (WREN[0]) begin
			MEM[WRADDR][7:0] <= DATA[7:0];
		end
		if (WREN[1]) begin
			MEM[WRADDR][15:8] <= DATA[15:8];
		end
	end
		
	assign Q = MEM[RDADDR];
	
//`elsif DEBUG
//
//	wire [15:0] sub_wire0;
//	
//	altdpram	altdpram_component (
//				.data (DATA),
//				.inclock (CLK),
//				.rdaddress (RDADDR),
//				.wraddress (WRADDR),
//				.wren (|WREN),
//				.byteena (WREN),
//				.q (sub_wire0),
//				.aclr (1'b0),
//				.inclocken (1'b1),
//				.rdaddressstall (1'b0),
//				.rden (1'b1),
////				.sclr (1'b0),
//				.wraddressstall (1'b0));
//	defparam
//		altdpram_component.byte_size = 8,
//		altdpram_component.indata_aclr = "OFF",
//		altdpram_component.indata_reg = "INCLOCK",
//		altdpram_component.intended_device_family = "Cyclone V",
//		altdpram_component.lpm_type = "altdpram",
//		altdpram_component.outdata_aclr = "OFF",
//		altdpram_component.outdata_reg = "UNREGISTERED",
//		altdpram_component.ram_block_type = "MLAB",
//		altdpram_component.rdaddress_aclr = "OFF",
//		altdpram_component.rdaddress_reg = "UNREGISTERED",
//		altdpram_component.rdcontrol_aclr = "OFF",
//		altdpram_component.rdcontrol_reg = "UNREGISTERED",
//		altdpram_component.read_during_write_mode_mixed_ports = "CONSTRAINED_DONT_CARE",
//		altdpram_component.width = 16,
//		altdpram_component.widthad = addr_width,
//		altdpram_component.width_byteena = 2,
//		altdpram_component.wraddress_aclr = "OFF",
//		altdpram_component.wraddress_reg = "INCLOCK",
//		altdpram_component.wrcontrol_aclr = "OFF",
//		altdpram_component.wrcontrol_reg = "INCLOCK";
//		
//	assign Q = sub_wire0;
	
`else

	wire [15:0] sub_wire0;
	
	altsyncram	altsyncram_component (
				.address_a (WRADDR),
				.byteena_a (WREN),
				.clock0 (CLK),
				.data_a (DATA),
				.wren_a (|WREN),
				.address_b (RDADDR),
				.q_b (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b ({16{1'b1}}),
				.eccstatus (),
				.q_a (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.byte_size = 8,
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_input_b = "BYPASS",
		altsyncram_component.clock_enable_output_b = "BYPASS",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 2**addr_width,
		altsyncram_component.numwords_b = 2**addr_width,
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.ram_block_type = "M10K",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.widthad_a = addr_width,
		altsyncram_component.widthad_b = addr_width,
		altsyncram_component.width_a = 16,
		altsyncram_component.width_b = 16,
		altsyncram_component.width_byteena_a = 2;
	
	assign Q = sub_wire0;
	
`endif
	
endmodule

module SCSP_RAM_8X4
#(
	parameter addr_width = 5
)
(
	input         CLK,
	
	input  [addr_width-1:0] WRADDR,
	input            [31:0] DATA,
	input             [3:0] WREN,
	input  [addr_width-1:0] RDADDR,
	output           [31:0] Q
);

`ifdef SIM
	
	reg [31:0] MEM [1**addr_width];
	
	always @(posedge CLK) begin
		if (WREN[0]) begin
			MEM[WRADDR][7:0] <= DATA[7:0];
		end
		if (WREN[1]) begin
			MEM[WRADDR][15:8] <= DATA[15:8];
		end
		if (WREN[2]) begin
			MEM[WRADDR][23:16] <= DATA[23:16];
		end
		if (WREN[3]) begin
			MEM[WRADDR][31:24] <= DATA[31:24];
		end
	end
		
	assign Q = MEM[RDADDR];
	
//`elsif DEBUG
//
//	wire [31:0] sub_wire0;
//	
//	altdpram	altdpram_component (
//				.data (DATA),
//				.inclock (CLK),
//				.rdaddress (RDADDR),
//				.wraddress (WRADDR),
//				.wren (|WREN),
//				.byteena (WREN),
//				.q (sub_wire0),
//				.aclr (1'b0),
//				.inclocken (1'b1),
//				.rdaddressstall (1'b0),
//				.rden (1'b1),
////				.sclr (1'b0),
//				.wraddressstall (1'b0));
//	defparam
//		altdpram_component.byte_size = 8,
//		altdpram_component.indata_aclr = "OFF",
//		altdpram_component.indata_reg = "INCLOCK",
//		altdpram_component.intended_device_family = "Cyclone V",
//		altdpram_component.lpm_type = "altdpram",
//		altdpram_component.outdata_aclr = "OFF",
//		altdpram_component.outdata_reg = "UNREGISTERED",
//		altdpram_component.ram_block_type = "MLAB",
//		altdpram_component.rdaddress_aclr = "OFF",
//		altdpram_component.rdaddress_reg = "UNREGISTERED",
//		altdpram_component.rdcontrol_aclr = "OFF",
//		altdpram_component.rdcontrol_reg = "UNREGISTERED",
//		altdpram_component.read_during_write_mode_mixed_ports = "CONSTRAINED_DONT_CARE",
//		altdpram_component.width = 32,
//		altdpram_component.widthad = addr_width,
//		altdpram_component.width_byteena = 4,
//		altdpram_component.wraddress_aclr = "OFF",
//		altdpram_component.wraddress_reg = "INCLOCK",
//		altdpram_component.wrcontrol_aclr = "OFF",
//		altdpram_component.wrcontrol_reg = "INCLOCK";
//	
//	assign Q = sub_wire0;
	
`else

	wire [31:0] sub_wire0;
	
	altsyncram	altsyncram_component (
				.address_a (WRADDR),
				.byteena_a (WREN),
				.clock0 (CLK),
				.data_a (DATA),
				.wren_a (|WREN),
				.address_b (RDADDR),
				.q_b (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b ({32{1'b1}}),
				.eccstatus (),
				.q_a (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.byte_size = 8,
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_input_b = "BYPASS",
		altsyncram_component.clock_enable_output_b = "BYPASS",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 2**addr_width,
		altsyncram_component.numwords_b = 2**addr_width,
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.ram_block_type = "M10K",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.widthad_a = addr_width,
		altsyncram_component.widthad_b = addr_width,
		altsyncram_component.width_a = 32,
		altsyncram_component.width_b = 32,
		altsyncram_component.width_byteena_a = 4;
	
	assign Q = sub_wire0;
	
`endif
	
endmodule

module SCSP_MPRO_RAM
(
	input          CLK,
	
	input  [ 6: 0] WRADDR,
	input  [63: 0] DATA,
	input  [ 7: 0] WREN,
	input  [ 6: 0] RDADDR,
	output [63: 0] Q
);

`ifdef SIM
	
	reg [63:0] MEM [128];
	
	always @(posedge CLK) begin
		if (WREN) begin
			MEM[WRADDR] <= DATA;
		end
	end
		
	assign Q = MEM[RDADDR];
	
`else

	wire [63:0] sub_wire0;
	
	altsyncram	altsyncram_component (
				.address_a (WRADDR),
				.byteena_a (WREN),
				.clock0 (CLK),
				.data_a (DATA),
				.wren_a (|WREN),
				.address_b (RDADDR),
				.q_b (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b ({64{1'b1}}),
				.eccstatus (),
				.q_a (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.byte_size = 8,
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_input_b = "BYPASS",
		altsyncram_component.clock_enable_output_b = "BYPASS",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 128,
		altsyncram_component.numwords_b = 128,
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.ram_block_type = "M10K",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.widthad_a = 7,
		altsyncram_component.widthad_b = 7,
		altsyncram_component.width_a = 64,
		altsyncram_component.width_b = 64,
		altsyncram_component.width_byteena_a = 8;
	
	assign Q = sub_wire0;
	
`endif
	
endmodule

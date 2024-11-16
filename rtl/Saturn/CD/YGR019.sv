module YGR019 (
	input              CLK,
	input              RST_N,
	
	input              RES_N,
	
	input              CE_R,
	input              CE_F,
	input      [14: 1] AA,
	input      [15: 0] ADI,
	output     [15: 0] ADO,
	input      [ 1: 0] AFC,
	input              ACS2_N,
	input              ARD_N,
	input              AWRL_N,
	input              AWRU_N,
	input              ATIM0_N,
	input              ATIM2_N,
	output             AWAIT_N,
	output             ARQT_N,
	
	input              SHCE_R,
	input              SHCE_F,
	input      [21: 1] SA,
	input      [15: 0] SDI,
	input      [15: 0] BDI,
	output     [15: 0] SDO,
	input              SWRL_N,
	input              SWRH_N,
	input              SRD_N,
	input              SCS2_N,
	input              SCS6_N,
	input              DACK0,
	input              DACK1,
	output             DREQ0_N,
	output             DREQ1_N,
	output reg         SIRQL_N,
	output reg         SIRQH_N,
		
	input      [15: 0] CD_D,
	input              CD_CK,
	input              CD_AUDIO,
	
	output     [15: 0] CD_SL,
	output     [15: 0] CD_SR,
	
	input              FAST
	
`ifdef DEBUG
	                   ,
	output     [31: 0] DBG_HEADER,
	output     [15: 0] ABUS_READ_CNT_DBG,
	output     [ 7: 0] ABUS_WAIT_CNT_DBG,
	output     [11: 0] DBG_CDD_CNT
`endif
);
	import YGR019_PKG::*;

	CR_t       CR[4];
	CR_t       RR[4];
	bit [15:0] HIRQ;
	bit [15:0] HMASK;
	bit [15:0] DTR;
	bit [15:0] TRCTL;
	bit [ 7:0] CDIRQL;
	bit [ 7:0] CDIRQU;
	bit [ 7:0] CDMASKU;
	bit [ 7:0] CDMASKL;
	bit [15:0] REG1A;
	//bit [15:0] REG1C;
		
	bit [15:0] FIFO_BUF[8];
	bit  [2:0] FIFO_WR_POS;
	bit  [2:0] FIFO_RD_POS;
	bit  [2:0] FIFO_AMOUNT;
	bit        FIFO_EMPTY;
	bit        FIFO_FULL;
	bit        FIFO_DREQ;
	bit  [1:0] CDD_DREQ;
	bit [15:0] CDD_DATA;
	bit [15:0] HOST_DATA;
	
	wire SCU_REG_SEL = (AA[14:12] == 3'b000) & ~ACS2_N;
	wire SH_REG_SEL = (SA[21:20] == 2'b00) & ~SCS2_N;
	wire SH_MPEG_SEL = (SA[21:20] == 2'b01) & ~SCS2_N;
	bit [15:0] SCU_REG_DO;
	bit        ABUS_WAIT;
	bit [15:0] SH_REG_DO;
	always @(posedge CLK or negedge RST_N) begin
		bit        AWR_N_OLD;
		bit        ARD_N_OLD;
		bit        SWR_N_OLD;
		bit        SRD_N_OLD;
		bit        DACK0_OLD;
		bit        DACK1_OLD;
		bit        ABUS_DATA_PORT;
		bit [ 2:0] ABUS_WAIT_CNT;
		bit        FIFO_INC_AMOUNT;
		bit        FIFO_DEC_AMOUNT;
		bit        FIFO_DREQ_PEND;
		bit        TRCTL1_OLD,TRCTL2_OLD;
		bit        CDD_SYNCED;
		bit [11:0] CDD_CNT;
		bit        CDD_PEND;
		bit        CDDA_CHAN;

		if (!RST_N) begin
			CR <= '{4{'0}};
			RR <= '{4{'0}};
			HIRQ <= '0;
			HMASK <= '0;

			CDIRQL <= '0;
			CDMASKL <= '0;
			REG1A <= '0;
			//REG1C <= '0;
			
			CDIRQU <= '0;
			CDMASKU <= '0;
			
			SH_REG_DO <= '0;
			ABUS_WAIT <= 0;
			ABUS_WAIT_CNT <= '0;
			
			TRCTL <= '0;
			FIFO_BUF <= '{8{'0}};
			FIFO_WR_POS <= '0;
			FIFO_RD_POS <= '0;
			FIFO_AMOUNT <= '0;
			FIFO_EMPTY <= 1;
			FIFO_FULL <= 0;
			FIFO_DREQ_PEND <= 0;
			FIFO_DREQ <= 0;
			
			CDD_DREQ <= '0;
			CDD_SYNCED <= 0;
			CDD_CNT <= 4'd0;
			CDD_PEND <= 0;
			CDDA_CHAN <= 0;
		end else begin
			if (!RES_N) begin
				CR <= '{4{'0}};
				RR <= '{4{'0}};
				HIRQ <= '0;
				HMASK <= '0;

				CDIRQL <= '0;
				CDMASKL <= '0;
				REG1A <= '0;
				//REG1C <= '0;
				
				CDIRQU <= '0;
				CDMASKU <= '0;
				
				SH_REG_DO <= '0;
				ABUS_WAIT <= 0;
				ABUS_WAIT_CNT <= '0;
				
				TRCTL <= '0;
				FIFO_BUF <= '{8{'0}};
				FIFO_WR_POS <= '0;
				FIFO_RD_POS <= '0;
				FIFO_AMOUNT <= '0;
				FIFO_EMPTY <= 1;
				FIFO_FULL <= 0;
				FIFO_DREQ_PEND <= 0;
				FIFO_DREQ <= 0;
				
				CDD_DREQ <= '0;
				CDD_SYNCED <= 0;
				CDD_CNT <= 4'd0;
				CDD_PEND <= 0;
				CDDA_CHAN <= 0;
			end else begin
				if (CE_R) begin
					AWR_N_OLD <= AWRL_N & AWRU_N;
					ARD_N_OLD <= ARD_N;
				end
				if (SHCE_R) begin
					if (ABUS_WAIT_CNT) ABUS_WAIT_CNT <= ABUS_WAIT_CNT - 3'd1;
				end

`ifdef DEBUG
				if (ABUS_WAIT_CNT_DBG < 8'hF0 && CE_R) ABUS_WAIT_CNT_DBG <= ABUS_WAIT_CNT_DBG + 8'd1;
`endif
				if (SCU_REG_SEL) begin
					if ((!AWRL_N || !AWRU_N) && AWR_N_OLD && CE_F) begin
						case ({AA[5:2],2'b00})
							6'h00: ;
							6'h08: begin 
								for (int i=0; i<16; i++) if (!ADI[i]) HIRQ[i] <= 0;
							end
							6'h0C: HMASK <= ADI;
							6'h18: CR[0] <= ADI; 
							6'h1C: CR[1] <= ADI;
							6'h20: CR[2] <= ADI;
							6'h24: begin CR[3] <= ADI; if (!CDIRQL[0]) CDIRQL[0] <= 1; CDIRQL[1] <= 0; end
							default:;
						endcase
						
						case ({AA[5:2],2'b00})
							6'h00: begin
								ABUS_WAIT <= 1;
								ABUS_DATA_PORT <= 1;
								ABUS_WAIT_CNT <= FAST ? 3'd0 : 3'd3;
`ifdef DEBUG
								ABUS_WAIT_CNT_DBG <= '0;
`endif
							end
							default:begin
								ABUS_WAIT <= 0;
								ABUS_DATA_PORT <= 0;
								ABUS_WAIT_CNT <= FAST ? 3'd0 : 3'd3;
							end
						endcase
					end else if (!ARD_N && ARD_N_OLD && CE_F) begin
						case ({AA[5:2],2'b00})
							6'h00: ;
							6'h08: SCU_REG_DO <= HIRQ;
							6'h0C: SCU_REG_DO <= HMASK;
							6'h18: SCU_REG_DO <= RR[0];
							6'h1C: SCU_REG_DO <= RR[1];
							6'h20: SCU_REG_DO <= RR[2];
							6'h24: begin 
								SCU_REG_DO <= RR[3]; 
								if (!CDIRQL[1]) CDIRQL[1] <= 1; 
							end
							default: SCU_REG_DO <= '0;
						endcase
						
						case ({AA[5:2],2'b00})
							6'h00: begin
								ABUS_WAIT <= 1;
								ABUS_DATA_PORT <= 1;
								ABUS_WAIT_CNT <= FAST ? 3'd2 : 3'd5;
`ifdef DEBUG
								ABUS_WAIT_CNT_DBG <= '0;
								ABUS_READ_CNT_DBG <= ABUS_READ_CNT_DBG + 1'd1;
`endif
							end
							default: begin
								ABUS_WAIT <= 1;
								ABUS_DATA_PORT <= 0;
								ABUS_WAIT_CNT <= FAST ? 3'd1 : 3'd4;
							end
						endcase
					end
				end
				
				if (CE_F) begin
					if (ABUS_WAIT && !ABUS_WAIT_CNT && ABUS_DATA_PORT && !TRCTL[0] && (!FIFO_EMPTY || TRCTL[3])) begin
						SCU_REG_DO <= FIFO_BUF[FIFO_RD_POS]; 
						FIFO_RD_POS <= FIFO_RD_POS + 3'd1;
						FIFO_DEC_AMOUNT <= 1;
						if (FIFO_AMOUNT <= 7'd1) begin
							FIFO_DREQ_PEND <= 1;
						end
						ABUS_WAIT <= 0;
`ifdef DEBUG
						ABUS_WAIT_CNT_DBG <= 8'hFF;
`endif
					end
					if (ABUS_WAIT && !ABUS_WAIT_CNT && ABUS_DATA_PORT && TRCTL[0] && !FIFO_FULL) begin
						FIFO_BUF[FIFO_WR_POS] <= ADI;
						FIFO_WR_POS <= FIFO_WR_POS + 3'd1;
						FIFO_INC_AMOUNT <= 1;
						if (FIFO_AMOUNT >= 7'd5) begin
							FIFO_DREQ_PEND <= 1;
						end
						ABUS_WAIT <= 0;
`ifdef DEBUG
						ABUS_WAIT_CNT_DBG <= 8'hFF;
`endif
					end
					
					if (ABUS_WAIT && !ABUS_WAIT_CNT && !ABUS_DATA_PORT) begin
						ABUS_WAIT <= 0;
					end
				end
				
				if (SHCE_R) begin
					SWR_N_OLD <= SWRL_N & SWRH_N;
					SRD_N_OLD <= SRD_N;
					if (SH_REG_SEL) begin
						if ((!SWRL_N || !SWRH_N) && SWR_N_OLD) begin
							case ({SA[4:1],1'b0})
								5'h00:  begin 
									if (TRCTL[2] && !TRCTL[0]) begin
										FIFO_BUF[FIFO_WR_POS] <= SDI;
										FIFO_WR_POS <= FIFO_WR_POS + 3'd1;
										FIFO_INC_AMOUNT <= 1;
									end
								end
								5'h02: begin 
									TRCTL <= SDI & TRCTL_WMASK;
									if (SDI[2] && !SDI[0]) FIFO_DREQ_PEND <= 1;
									if (SDI[1]) begin
										FIFO_WR_POS <= '0;
										FIFO_RD_POS <= '0;
										FIFO_AMOUNT <= '0;
										FIFO_FULL <= 0;
										FIFO_EMPTY <= 1;
										FIFO_DREQ <= 0;
									end
								end
								5'h04: for (int i=0; i<8; i++) if (!SDI[i] && CDIRQL[i]) CDIRQL[i] <= 0;
								5'h06: for (int i=0; i<8; i++) if (!SDI[i] && CDIRQU[i]) CDIRQU[i] <= 0;
								5'h08: CDMASKL <= SDI[7:0] & CDMASKL_WMASK[7:0];
								5'h0A: CDMASKU <= SDI[7:0] & CDMASKU_WMASK[7:0];
								5'h10: RR[0] <= SDI;
								5'h12: RR[1] <= SDI;
								5'h14: RR[2] <= SDI;
								5'h16: RR[3] <= SDI;
								5'h1A: REG1A <= SDI & REG1A_WMASK;
		//						5'h1C: REG1C <= SDI;
								5'h1E: begin 
									for (int i=0; i<16; i++) if (SDI[i]) HIRQ[i] <= 1;
								end
								default:;
							endcase
						end else if (!SRD_N && SRD_N_OLD) begin
							case ({SA[4:1],1'b0})
								5'h00: begin
									SH_REG_DO <= FIFO_BUF[FIFO_RD_POS]; 
									FIFO_RD_POS <= FIFO_RD_POS + 3'd1;
									FIFO_DEC_AMOUNT <= 1;
									if (FIFO_RD_POS[1:0] == 2'd3) begin
										FIFO_DREQ_PEND <= 1;
									end
								end
								5'h02: SH_REG_DO <= TRCTL & TRCTL_RMASK;
								5'h04: SH_REG_DO <= {8'h00,CDIRQL} & CDIRQL_RMASK;
								5'h06: SH_REG_DO <= {8'h00,CDIRQU} & CDIRQU_RMASK;
								5'h08: SH_REG_DO <= {8'h00,CDMASKL} & CDMASKL_RMASK;
								5'h0A: SH_REG_DO <= {8'h00,CDMASKU} & CDMASKU_RMASK;
								5'h10: SH_REG_DO <= CR[0];
								5'h12: SH_REG_DO <= CR[1];
								5'h14: SH_REG_DO <= CR[2];
								5'h16: SH_REG_DO <= CR[3];
								5'h1A: SH_REG_DO <= REG1A & REG1A_RMASK;
								5'h1C: SH_REG_DO <= 16'h0016;//REG1C;
								default: SH_REG_DO <= '0;
							endcase
						end
					end else if (SH_MPEG_SEL) begin
						if (!SRD_N && SRD_N_OLD) begin
							case ({SA[4:1],1'b0})
								5'h02: SH_REG_DO <= 16'h006C;
								default: SH_REG_DO <= '0;
							endcase
						end
					end
				end
				
				//DREQ1
				if (SHCE_R) begin
					if (FIFO_DREQ_PEND) begin
						FIFO_DREQ_PEND <= 0;
						FIFO_DREQ <= 1;
					end

					DACK1_OLD <= DACK1;
					if (TRCTL[2] && DACK1 && !DACK1_OLD) begin
						if (!TRCTL[0]) begin
							FIFO_BUF[FIFO_WR_POS] <= BDI;
							FIFO_WR_POS <= FIFO_WR_POS + 3'd1;
							FIFO_INC_AMOUNT <= 1;
							if (FIFO_AMOUNT > 7'd2 && FIFO_DREQ) begin
								FIFO_DREQ <= 0;
							end
						end else begin
							FIFO_RD_POS <= FIFO_RD_POS + 3'd1;
							FIFO_DEC_AMOUNT <= 1;
							if (FIFO_AMOUNT < 7'd5 && FIFO_DREQ) begin
								FIFO_DREQ <= 0;
							end
						end
					end
				end
				HOST_DATA <= FIFO_BUF[FIFO_RD_POS]; 
				
				if (FIFO_INC_AMOUNT && FIFO_DEC_AMOUNT) begin
					FIFO_INC_AMOUNT <= 0;
					FIFO_DEC_AMOUNT <= 0;
				end else if (FIFO_INC_AMOUNT) begin
					FIFO_AMOUNT <= FIFO_AMOUNT + 3'd1;
					if (FIFO_AMOUNT == 3'd7) FIFO_AMOUNT <= 3'd7;
					if (FIFO_AMOUNT == 3'd6) FIFO_FULL <= 1;
					FIFO_EMPTY <= 0;
					FIFO_INC_AMOUNT <= 0;
				end else if (FIFO_DEC_AMOUNT) begin
					FIFO_AMOUNT <= FIFO_AMOUNT - 3'd1;
					if (FIFO_AMOUNT == 3'd0) FIFO_AMOUNT <= 3'd0;
					FIFO_FULL <= 0;
					if (FIFO_AMOUNT == 3'd1) FIFO_EMPTY <= 1;
					FIFO_DEC_AMOUNT <= 0;
				end
				
				//DREQ0
				if (CD_CK) begin
					if (!CD_AUDIO) begin
						CDD_CNT <= CDD_CNT + 12'd2;
						if (!CDD_SYNCED) begin
							if (CDD_CNT == 12'd10) begin
								CDD_SYNCED <= 1; 
								REG1A[7] <= 1; 
							end
						end else if (CDD_CNT == 12'd12) begin
`ifdef DEBUG
							DBG_HEADER[31:16] <= {CD_D[7:0],CD_D[15:8]};
`endif
						end else if (CDD_CNT == 12'd14) begin
							if (!CDIRQU[4]) CDIRQU[4] <= 1;
`ifdef DEBUG
							DBG_HEADER[15:0] <= {CD_D[7:0],CD_D[15:8]};
`endif
						end else if (CDD_CNT == 12'd2352-2) begin
							CDD_SYNCED <= 0;
							CDD_CNT <= 12'd0;
						end
						CDD_DATA <= {CD_D[7:0],CD_D[15:8]};
						CDD_PEND <= CDD_SYNCED;
						
						CD_SL <= '0;
						CD_SR <= '0;
						
					end else begin
						CDDA_CHAN <= ~CDDA_CHAN;
						if (!CDDA_CHAN) CD_SL <= CD_D[15:0];
						if ( CDDA_CHAN) CD_SR <= CD_D[15:0];
					end
				end
`ifdef DEBUG
				DBG_CDD_CNT <= CDD_CNT;
`endif
				
				if (SHCE_R) begin
					if (CDD_PEND) begin
						CDD_DREQ[0] <= REG1A[7];
						CDD_PEND <= 0;
					end else if (CDD_DREQ[0]) begin
						CDD_DREQ[0] <= 0;
					end
					CDD_DREQ[1] <= CDD_DREQ[0];
					
					DACK0_OLD <= DACK0;
					if (DACK0 && !DACK0_OLD) begin
					end
				end
			end
		end
	end

	assign ADO = SCU_REG_DO;
	assign AWAIT_N = ~(ABUS_WAIT & SCU_REG_SEL);
	assign ARQT_N = 1;//TODO
	
	assign SDO = !DACK0 ? CDD_DATA : 
	             !DACK1 ? HOST_DATA : SH_REG_DO;
	
	assign SIRQL_N = ~|(CDIRQL & CDMASKL);
	assign SIRQH_N = ~|(CDIRQU & CDMASKU);
	assign DREQ0_N = ~|CDD_DREQ;
	assign DREQ1_N = ~FIFO_DREQ;
	
	
endmodule

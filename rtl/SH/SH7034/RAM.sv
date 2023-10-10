module SH7034_RAM 
(
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	
	input      [27:0] IBUS_A,
	input      [31:0] IBUS_DI,
	output     [31:0] IBUS_DO,
	input       [3:0] IBUS_BA,
	input             IBUS_WE,
	input             IBUS_REQ,
	output            IBUS_BUSY,
	output            IBUS_ACT,
	
	
	output     [7:0] DBG_CD_STATE,
	output     [7:0] DBG_CD_FLAGS,
	output     [7:0] DBG_CD_STATUS,
	output     [7:0] DBG_CDD_RX_STAT,
	output     [7:0] DBG_CDD_COMM0,
	output     [7:0] DBG_CDD_COMM1,
	output     [7:0] DBG_CDD_COMM11,
	output     [7:0] DBG_7B0
);
	
	wire RAM_SEL = (IBUS_A[27:24] == 4'hF);
	
	bit  [31:0] RAM_Q;
	wire [31:0] RAM_D = {IBUS_BA[3] ? IBUS_DI[31:24] : RAM_Q[31:24],
	                     IBUS_BA[2] ? IBUS_DI[23:16] : RAM_Q[23:16],
								IBUS_BA[1] ? IBUS_DI[15: 8] : RAM_Q[15: 8],
								IBUS_BA[0] ? IBUS_DI[ 7: 0] : RAM_Q[ 7: 0]};
	CPU_RAM cpu_ram
	(
		.clock(CLK),
		.wraddress(IBUS_A[11:2]),
		.data(RAM_D),
		.wren(IBUS_WE & RAM_SEL & CE_R),
		.rdaddress(IBUS_A[11:2]),
		.q(RAM_Q)
	);
	
	assign IBUS_DO = RAM_Q;
	assign IBUS_BUSY = 0;
	assign IBUS_ACT = RAM_SEL;
	
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			
		end else begin
			if (IBUS_WE & RAM_SEL & CE_R) begin
				case ({IBUS_A[11:2],2'b00})
					12'h288:  begin
						if (IBUS_BA[1]) DBG_CD_STATUS <= IBUS_DI[15: 8];
					end
					12'h2A4: begin
						if (IBUS_BA[2]) DBG_CD_STATE <= IBUS_DI[23:16];
						if (IBUS_BA[1]) DBG_CD_FLAGS <= IBUS_DI[15:8];
					end
					12'h2C4: begin
						if (IBUS_BA[3]) DBG_CDD_COMM0 <= IBUS_DI[31:24];
						if (IBUS_BA[2]) DBG_CDD_COMM1 <= IBUS_DI[23:16];
					end
					12'h2CC: begin
						if (IBUS_BA[0]) DBG_CDD_COMM11 <= IBUS_DI[7:0];
					end
					12'h2D0: begin
						if (IBUS_BA[3]) DBG_CDD_RX_STAT <= IBUS_DI[31:24];
					end
					12'h7b0: begin
						if (IBUS_BA[3]) DBG_7B0 <= IBUS_DI[31:24];
					end
					default;
				endcase
			end
		end
	end
	
endmodule

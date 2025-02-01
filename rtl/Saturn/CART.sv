module CART (
	input             CLK,
	input             RST_N,
	
	input       [2:0] MODE,	//0-none, 1-ROM 2M, 2-DRAM 1M, 3-DRAM 4M, 4-BACKUP, 5-STV
	
	input             RES_N,
	
	input             CE_R,
	input             CE_F,
	input      [25:0] AA,
	input      [15:0] ADI,
	output     [15:0] ADO,
	input       [1:0] AFC,
	input             ACS0_N,
	input             ACS1_N,
	input             ACS2_N,
	input             ARD_N,
	input             AWRL_N,
	input             AWRU_N,
	input             ATIM0_N,
	input             ATIM2_N,
	output            AWAIT_N,
	output            ARQT_N,
	
	output     [25:1] MEM_A,
	input      [15:0] MEM_DI,
	output     [15:0] MEM_DO,
	output     [ 1:0] MEM_WE,
	output            MEM_RD,
	input             MEM_RDY
);

	wire [25:1] DRAM1M_ADDR = {6'b000000,AA[21],AA[18:1]};
	wire [25:1] DRAM4M_ADDR = {4'b0000,AA[21:1]};
	wire [25:1] ROM2M_ADDR = {5'b00000,AA[20:1]};
	wire [25:1] STV_ADDR = {ACS0_N,AA[24:1]};
	wire [25:1] BACKUP_ADDR = {6'b000000,AA[19:1]};
	
	wire CART_ID_SEL = (AA[23:1] == 24'hFFFFFF>>1) && ~ACS1_N;
	wire CART_MEM_SEL = ~ACS0_N || (~ACS1_N && MODE == 3'h5);
	wire BACKUP_MEM_SEL = ~ACS1_N;
	wire STV_RSG_WR = (AA[23:1] == 24'hFFFFF0>>1) && ~ACS1_N;
	wire STV_RSG_RD = (AA[23:1] >= 24'hFFFFFC>>1) && ~ACS1_N;
	bit [15:0] ABUS_DO;
	bit        ABUS_WAIT;
	always @(posedge CLK or negedge RST_N) begin
		bit        AWR_N_OLD;
		bit        ARD_N_OLD;
		bit [ 7:0] STV_RSG_CNT;
		bit        STV_RSG_EN;
		
		if (!RST_N) begin
			ABUS_WAIT <= 0;
			STV_RSG_CNT <= '0;
			STV_RSG_EN <= 0;
		end else begin
			if (!RES_N) begin
				
			end else begin
				AWR_N_OLD <= AWRL_N & AWRU_N;
				ARD_N_OLD <= ARD_N;

				if ((!AWRL_N || !AWRU_N) && AWR_N_OLD) begin
					if (CART_ID_SEL && MODE < 3'h5) begin
						
					end
					else if (STV_RSG_WR && MODE == 3'h5) begin
						STV_RSG_EN <= ADI[0];
						STV_RSG_CNT <= '0;
					end
					else if (CART_MEM_SEL || BACKUP_MEM_SEL) begin
						case (MODE)
							3'h2: MEM_A <= DRAM1M_ADDR;
							3'h3: MEM_A <= DRAM4M_ADDR;
							3'h4: MEM_A <= BACKUP_ADDR;
							default: MEM_A <= '1;
						endcase
						MEM_DO <= ADI;
						case (MODE)
							3'h2,
							3'h3,
							3'h4: MEM_WE <= ~{AWRU_N,AWRL_N};
							default: MEM_WE <= '0;
						endcase
						ABUS_WAIT <= (MODE == 3'h2 || MODE == 3'h3 || MODE == 3'h4);
					end
				end else if (!ARD_N && ARD_N_OLD) begin
					if (CART_ID_SEL && MODE < 3'h5) begin
						case (MODE)
							3'h1: ABUS_DO <= 16'hFFFF;
							3'h2: ABUS_DO <= 16'hFF5A;
							3'h3: ABUS_DO <= 16'hFF5C;
							3'h4: ABUS_DO <= 16'hFF21;
							default: ABUS_DO <= 16'hFFFF;
						endcase
					end
					else if (STV_RSG_RD && STV_RSG_EN && MODE == 3'h5) begin
						STV_RSG_CNT <= STV_RSG_CNT + 8'd1;
						ABUS_DO <= {STV_RSG_CNT[6:0],1'b0,STV_RSG_CNT[6:0],1'b1} & {{4{~STV_RSG_CNT[7]}},{4{STV_RSG_CNT[7]}},{4{~STV_RSG_CNT[7]}},{4{STV_RSG_CNT[7]}}};
					end
					else if (CART_MEM_SEL || BACKUP_MEM_SEL) begin
						case (MODE)
							3'h1: MEM_A <= ROM2M_ADDR;
							3'h2: MEM_A <= DRAM1M_ADDR;
							3'h3: MEM_A <= DRAM4M_ADDR;
							3'h4: MEM_A <= BACKUP_ADDR;
							3'h5: MEM_A <= STV_ADDR;
							default: MEM_A <= '1;
						endcase
						MEM_RD <= 1;
						ABUS_WAIT <= 1;
					end
				end
				
				if (ABUS_WAIT && MEM_RDY) begin
					case (MODE)
						3'h0:    ABUS_DO <= 16'hFFFF;
						default: ABUS_DO <= MEM_DI;
					endcase
					MEM_WE <= '0;
					MEM_RD <= 0;
					ABUS_WAIT <= 0;
				end
			end
		end
	end

	assign ADO = ABUS_DO;
	assign AWAIT_N = ~ABUS_WAIT;
	assign ARQT_N = 1;
	
endmodule

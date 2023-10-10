module CART (
	input             CLK,
	input             RST_N,
	
	input       [2:0] MODE,	//0-none, 1-ROM 2M, 2-DRAM 1M, 3-DRAM 4M
	
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
	
	output     [21:1] MEM_A,
	input      [15:0] MEM_DI,
	output     [15:0] MEM_DO,
	output     [ 1:0] MEM_WE,
	output            MEM_RD,
	input             MEM_RDY
);

//	wire        DRAM1M_SEL = (AA[24:20] ==? 5'b001?0) && ~ACS0_N;
	wire [21:1] DRAM1M_ADDR = {2'b00,AA[21],AA[18:1]};
	
//	wire        DRAM4M_SEL = (AA[24:20] ==? 5'b001??) && ~ACS0_N;
	wire [21:1] DRAM4M_ADDR = {AA[21:1]};
	
//	wire        ROM2M_SEL =  ~ACS0_N;
	wire [21:1] ROM2M_ADDR = {1'b0,AA[20:1]};
	
	wire CART_ID_SEL = (AA[23:1] == 24'hFFFFFF>>1) && ~ACS1_N;
	wire CART_MEM_SEL = ~ACS0_N || ~ACS1_N;
	bit [15:0] ABUS_DO;
	bit        ABUS_WAIT;
	always @(posedge CLK or negedge RST_N) begin
		bit        AWR_N_OLD;
		bit        ARD_N_OLD;
		
		if (!RST_N) begin
			ABUS_WAIT <= 0;
		end else begin
			if (!RES_N) begin
				
			end else begin
				AWR_N_OLD <= AWRL_N & AWRU_N;
				ARD_N_OLD <= ARD_N;

				if (CART_ID_SEL) begin
					if (!ARD_N && ARD_N_OLD) begin
						case (MODE)
							3'h1: ABUS_DO <= 16'hFFFF;
							3'h2: ABUS_DO <= 16'hFF5A;
							3'h3: ABUS_DO <= 16'hFF5C;
							default: ABUS_DO <= 16'hFFFF;
						endcase
					end
				end
				else if (CART_MEM_SEL) begin
					if ((!AWRL_N || !AWRU_N) && AWR_N_OLD) begin
						case (MODE)
							3'h2: MEM_A <= DRAM1M_ADDR;
							3'h3: MEM_A <= DRAM4M_ADDR;
							default: MEM_A <= '1;
						endcase
						MEM_DO <= ADI;
						case (MODE)
							3'h2,
							3'h3: MEM_WE <= ~{AWRU_N,AWRL_N};
							default: MEM_WE <= '0;
						endcase
						ABUS_WAIT <= (MODE == 3'h2 || MODE == 3'h3);
					end else if (!ARD_N && ARD_N_OLD) begin
						case (MODE)
							3'h1: MEM_A <= ROM2M_ADDR;
							3'h2: MEM_A <= DRAM1M_ADDR;
							3'h3: MEM_A <= DRAM4M_ADDR;
							default: MEM_A <= '1;
						endcase
						MEM_RD <= 1;
						ABUS_WAIT <= 1;
					end
				end
				
				if (ABUS_WAIT && MEM_RDY) begin
					case (MODE)
						3'h1,
						3'h2,
						3'h3: ABUS_DO <= MEM_DI;
						default: ABUS_DO <= 16'hFFFF;
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

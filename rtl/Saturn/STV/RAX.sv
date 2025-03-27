module ACCLAIM_RAX (
	input              CLK,
	input              RST_N,
	input              CE_R,
	input              CE_F,
	
	input              RES_N,
	
	input      [ 3: 1] ADDR,
	input      [15: 0] DI,
	output     [15: 0] DO,
	input              RD,
	input              WR,
	
	output     [24: 0] ROM_A,
	input      [ 7: 0] ROM_DI,
	output             ROM_RD,
	input              ROM_RDY,
	
	output     [15: 0] RAM_A,
	input      [15: 0] RAM_DI,
	output     [15: 0] RAM_DO,
	output             RAM_WR,
	output             RAM_RD,
	input              RAM_RDY,
	
	output     [15: 0] SOUND_L,
	output     [15: 0] SOUND_R
);

	bit  [13: 0] ADSP_A;
	bit  [23: 0] ADSP_DI;
	bit  [23: 0] ADSP_DO;
	bit          ADSP_WR_N;
	bit          ADSP_RD_N;
	bit          ADSP_WAIT;
	
	bit          ADSP_PMS_N;
	bit          ADSP_DMS_N;
	bit          ADSP_BMS_N;
	bit          ADSP_CMS_N;
	bit          ADSP_IOMS_N;
	
	bit          ADSP_IRQL0_N;
	
	bit  [ 2: 0] ADSP_FL;
	bit  [ 7: 0] ADSP_PFI;
	
	bit          ADSP_SCLK0;
	bit          ADSP_TFS0;
	bit          ADSP_DT0,ADSP_DT1;
	
	ADSP_2181 ADSP_2181
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.CE_F(CE_F),
		.CE_R(CE_R),
		
		.RES_N(RES_N),
		
		.IRQL0_N(ADSP_IRQL0_N),
		.IRQL1_N(1'b1),
		.IRQ2_N(1'b1),
		.IRQE_N(1'b1),
		
		.A(ADSP_A),
		.DI(ADSP_DI),
		.DO(ADSP_DO),
		.WR_N(ADSP_WR_N),
		.RD_N(ADSP_RD_N),
		.WAIT(ADSP_WAIT),
		
		.PMS_N(ADSP_PMS_N),
		.DMS_N(ADSP_DMS_N),
		.BMS_N(ADSP_BMS_N),
		.CMS_N(ADSP_CMS_N),
		.IOMS_N(ADSP_IOMS_N),
		
		.FI(1'b0),
		.FO(),
		.FL(ADSP_FL),
		
		.PFI(ADSP_PFI),
		.PFO(),
		
		.SCLK0_O(ADSP_SCLK0),
		.SCLK0_I(),
		.DT0(ADSP_DT0),
		.DR0(),
		.TFS0_O(ADSP_TFS0),
		
		.SCLK1_O(),
		.SCLK1_I(ADSP_SCLK0),
		.DT1(ADSP_DT1),
		.DR1(),
		.TFS1_O(),
	
		.MMAP(1'b0),
		.BMODE(1'b0)
	);
	
	//DAC
	always @(posedge CLK or negedge RST_N) begin
		bit         ADSP_SCLK0_OLD;
		bit         FRAME_START;
		bit [ 3: 0] BIT_CNT;
		bit [15: 0] BUF0,BUF1;
		
		if (!RST_N) begin
			BIT_CNT <= '0;
			{SOUND_L,SOUND_R} <= '0;
		end else if (!RES_N) begin
			BIT_CNT <= '0;
			{SOUND_L,SOUND_R} <= '0;
		end else begin
			if (CE_R) begin
				ADSP_SCLK0_OLD <= ADSP_SCLK0;
				if (!ADSP_SCLK0 && ADSP_SCLK0_OLD) begin
					FRAME_START <= ADSP_TFS0;
					BUF0 <= {BUF0[14:0],ADSP_DT0};
					BUF1 <= {BUF1[14:0],ADSP_DT1};
				end
				
				if (ADSP_SCLK0 && !ADSP_SCLK0_OLD) begin
					BIT_CNT <= BIT_CNT + 4'd1;
					if (FRAME_START) begin
						BIT_CNT <= '0;
					end
					if (BIT_CNT == 4'd15) begin
						SOUND_L <= BUF0;
						SOUND_R <= BUF1;
					end
				end
			end
		end
	end
	
	//HOST IO
	bit [ 2: 0] RAM_BANK;
	bit [ 2: 0] ROM_BANK;
	bit [15: 0] HOST_DATA_IN,HOST_DATA_OUT;
	bit         HOST_DATA_IN_RDY;
	bit         HOST_DATA_OUT_EMPTY;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			RAM_BANK <= '0;
			ROM_BANK <= '0;
			HOST_DATA_IN <= '0;
			HOST_DATA_IN_RDY <= 0;
			HOST_DATA_OUT <= '0;
			HOST_DATA_OUT_EMPTY <= 1;
		end else if (!RES_N) begin
			RAM_BANK <= '0;
			ROM_BANK <= '0;
			HOST_DATA_IN <= '0;
			HOST_DATA_IN_RDY <= 0;
			HOST_DATA_OUT <= '0;
			HOST_DATA_OUT_EMPTY <= 1;
		end else begin
			if (CE_R) begin
				if (!ADSP_IOMS_N && !ADSP_WR_N) begin
					case (ADSP_A[1:0])
						2'h0: RAM_BANK <= ADSP_DO[10:8];
						2'h1: ROM_BANK <= ADSP_DO[10:8];
						2'h2: ;//write 0x0001 once in init
						2'h3: begin HOST_DATA_OUT <= ADSP_DO[23:8]; HOST_DATA_OUT_EMPTY <= 0; end
					endcase
				end
				if (!ADSP_IOMS_N && !ADSP_RD_N) begin
					case (ADSP_A[1:0])
						2'h3: HOST_DATA_IN_RDY <= 0;
					endcase
				end
			end
			
			if (WR) begin
				HOST_DATA_IN <= DI;
				HOST_DATA_IN_RDY <= 1;
			end
			if (RD) begin
				HOST_DATA_OUT_EMPTY <= 1;
			end
		end
	end
	assign ADSP_PFI = {7'b0000000,HOST_DATA_OUT_EMPTY};
	assign ADSP_IRQL0_N = ~(HOST_DATA_IN_RDY);
	
	assign ADSP_DI = !ADSP_DMS_N ? {RAM_DI,8'h00} : 
	                 !ADSP_BMS_N ? {8'h00,ROM_DI,8'h00} : 
					     !ADSP_IOMS_N ? {HOST_DATA_IN,8'h00} : '0;
	assign ADSP_WAIT = ~(ROM_RDY|RAM_RDY);
	
	assign DO = HOST_DATA_OUT;
	
	//ROM,RAM
	assign ROM_A = {ROM_BANK,ADSP_DO[23:16],ADSP_A};
	assign ROM_RD = ~ADSP_RD_N & ~ADSP_BMS_N;
	
	assign RAM_A = {RAM_BANK,ADSP_A[12:0]};
	assign RAM_DO = ADSP_DO[23:8];
	assign RAM_RD = ~ADSP_RD_N & ~ADSP_DMS_N;
	assign RAM_WR = ~ADSP_WR_N & ~ADSP_DMS_N;
	
endmodule

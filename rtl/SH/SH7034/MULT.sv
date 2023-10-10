module SH7034_MULT (
	input             CLK,
	input             RST_N,
	input             CE_R,
	input             CE_F,
	
	input             RES_N,
	
	input      [27:0] CBUS_A,
	input      [31:0] CBUS_DI,
	output     [31:0] CBUS_DO,
	input             CBUS_WR,
	input       [3:0] CBUS_BA,
	input             CBUS_REQ,
	output            CBUS_BUSY,
	
	input       [1:0] MAC_SEL,
	input       [3:0] MAC_OP,
	input             MAC_S,
	input             MAC_WE
);

	import SH7034_PKG::*;
	
	bit [31:0] MACL;
	bit  [9:0] MACH;
	bit [15:0] MA;
	bit [15:0] MB;
	
	wire [31:0] SRES =   $signed(MA) *   $signed(MB);
	wire [31:0] URES = $unsigned(MA) * $unsigned(MB);
	wire [41:0] ACC  = {MACH,MACL} + {{10{SRES[31]}},SRES};
	
	always @(posedge CLK or negedge RST_N) begin
		bit        MUL_EXEC;
		bit        MACW_EXEC;
//		bit        SAT;
		bit        SIGNED;
		bit [15:0] DW;
		
		if (!RST_N) begin
			MACL <= '0;
			MACH <= '0;
			MA <= '0;
			MB <= '0;
			MUL_EXEC <= 0;
			MACW_EXEC <= 0;
			SIGNED <= 0;
			// synopsys translate_off
			MACL <= 32'h01234567;
			MACH <= 10'h0EF;
			// synopsys translate_on
		end
		else begin
			if (MAC_SEL && MAC_WE && CE_R) begin
				case (MAC_OP) 
					4'b0100,			//LDS Rm,MACx
					4'b1000: begin	//LDS @Rm+,MACx
						if (MAC_SEL[0]) MACL <= CBUS_DI;
						if (MAC_SEL[1]) MACH <= CBUS_DI[9:0];
					end
					4'b0001,				//MUL.L
					4'b0010,				//DMULU.L
					4'b0011: begin		//DMULS.L
					end
					4'b0110,				//MULU.W
					4'b0111: begin		//MULS.W
						MA <= CBUS_DI[15:0];
						MB <= CBUS_DI[31:16];
						MUL_EXEC <= MAC_SEL[1];
						SIGNED <= MAC_OP[0];
					end
					4'b1001: begin		//MAC.L
					end
					4'b1011: begin		//MAC.W
						DW = !CBUS_A[1] ? CBUS_DI[31:16] : CBUS_DI[15:0];
						if (MAC_SEL[0]) MA <= DW;
						if (MAC_SEL[1]) MB <= DW;
						MACW_EXEC <= MAC_SEL[1];
						SIGNED <= MAC_OP[0];
//						SAT <= MAC_S;
					end
					4'b1111: {MACH,MACL} <= '0;
				endcase
			end
			
			if (MUL_EXEC) begin
				if (SIGNED) MACL <= SRES[31:0];
				else        MACL <= URES[31:0];
				MUL_EXEC <= 0;
			end
			
			if (MACW_EXEC) begin
				{MACH,MACL} <= ACC;
				MACW_EXEC <= 0;
			end
		end
	end
	
	assign CBUS_DO = MAC_SEL[1] ? {{22{MACH[9]}},MACH} : MACL;
	assign CBUS_BUSY = 0;

endmodule

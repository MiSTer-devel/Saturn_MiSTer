module STV (
	input              CLK,
	input              RST_N,
	input              CE_R,
	input              CE_F,
	
	input              RES_N,
	
	input      [ 6: 1] A,
	input      [ 7: 0] DI,
	output     [ 7: 0] DO,
	input              CS_N,
	input              RW_N,
	
	input      [15: 0] JOY1,
	input      [15: 0] JOY2
);
	
	bit  [ 7: 0] IN[8];
	bit  [ 7: 0] OUT[8];
	bit  [ 7: 0] DIR;
	
	assign IN[0] = {1'b1,JOY1[15:12],JOY1[9],JOY1[8],JOY1[10]};
	assign IN[1] = {1'b1,JOY2[15:12],JOY2[9],JOY2[8],JOY2[10]};
	assign IN[2] = {1'b1,1'b1,JOY2[11],JOY1[11],JOY1[7],JOY1[3],1'b1,JOY1[11]};
	assign IN[3] = 8'h00;
	assign IN[4] = 8'hFF;
	assign IN[5] = {1'b1,JOY2[4],JOY2[5],JOY2[6],1'b1,JOY1[4],JOY1[5],JOY1[6]};
	assign IN[6] = 8'hFF;
	assign IN[7] = 8'hFF;
	
	bit  [ 7: 0] REG_DO;
	always @(posedge CLK or negedge RST_N) begin
		bit        RW_N_OLD;
		bit        CS_N_OLD;
		
		if (!RST_N) begin
			OUT <= '{8{'1}};
			DIR <= '1;
		end
		else if (!RES_N) begin
			
		end else begin
			RW_N_OLD <= RW_N;
			if (!RW_N && RW_N_OLD && !CS_N) begin
				case ({A,1'b1})
					7'h01: OUT[0] <= DI;
					7'h03: OUT[1] <= DI;
					7'h05: OUT[2] <= DI;
					7'h07: OUT[3] <= DI;
					7'h09: OUT[4] <= DI;
					7'h0B: OUT[5] <= DI;
					7'h0D: OUT[6] <= DI;
					7'h0F: OUT[7] <= DI;
					7'h11: DIR <= DI;
					default:;
				endcase
			end 
			
			CS_N_OLD <= CS_N;
			if (!CS_N && CS_N_OLD && RW_N) begin
				case ({A,1'b1})
					7'h01: REG_DO <= IN[0];
					7'h03: REG_DO <= IN[1];
					7'h05: REG_DO <= IN[2];
					7'h07: REG_DO <= IN[3];
					7'h09: REG_DO <= IN[4];
					7'h0B: REG_DO <= IN[5];
					7'h0D: REG_DO <= IN[6];
					7'h0F: REG_DO <= IN[7];
					7'h11: REG_DO <= DIR;
					default:;
				endcase
			end
		end
	end
	assign DO = REG_DO;
	
endmodule

module SEGA_315_5838 (
	input              CLK,
	input              RST_N,
	
	input              RES_N,
	
	input              CE_R,
	input              CE_F,
	input      [ 3: 1] ADDR,
	input      [15: 0] DI,
	output     [15: 0] DO,
	input              RD,
	input              WR,
	output reg         WAIT,
	
	output     [23: 1] MEM_A,
	input      [15: 0] MEM_DI,
	output             MEM_RD,
	input              MEM_RDY,
	
	output     [ 7: 0] TREE_LEN,
	output     [ 7: 0] TREE_IDX,
	output     [15: 0] TREE_PATT
);

	typedef struct packed
	{
		bit [ 7: 0] LEN;
		bit [ 7: 0] IDX;
		bit [15: 0] PATTERN;
	} DecompTree_t;
	
	DecompTree_t DEC_TREE[16];
	
	function bit [15:0] Decipher(input bit [15:0] v);
		bit [15:0] res;
	
		res = {~(v[10]),
		       ~(v[0]^v[11]^v[14]),
		        ((v[8]^v[1])?v[12]:v[7]),
		        (v[0]^v[2]),
		       ~(v[3]^v[10]),
		        (v[7]^(v[12]|~(v[1]^v[8]^v[7]))),
		        (v[6]^(v[8]|~(v[15]))),
		       ~(v[4]^v[13]),
		       ~((v[14]&(v[5]^v[12]))^v[7]^v[9]),
		        (v[4]^(v[3]|v[10])),
		        ((v[6]|v[8])^(v[8]&v[15])),
		        ((v[7]&(v[1]^v[8]^v[12]))^v[12]),
		       ~(v[11]^v[14]),
		       ~((v[6]&v[8])^(v[6]&v[15])^(v[8]&v[15])),
		       ~(((v[7]^v[9])&(v[12]^v[14]^v[5]))^v[14]),
		        (((v[7]^v[9]^v[14])?1'b0:(v[5]^v[12]))^v[14])
				};
		return res;
	endfunction

	typedef enum bit [3:0] {
		DEC_IDLE,  
		DEC_NEXT_WORD,
		DEC_READ_MEM,
		DEC_COMP_VAL, 
		DEC_VAL,
		DEC_WALK,
		DEC_DICT_READ,
		DEC_DONE
	} DecompState_t;
	DecompState_t DEC_ST;
	
	bit [23: 1] MEM_ADDR;
	bit         MEM_READ;
	bit         MODE;
	bit         IO_TREE_WORD;
	bit [ 3: 0] IO_TREE_NUM;
	bit [ 6: 0] IO_DICT_NUM;
	
	bit [15: 0] OUT_DATA;
	bit [ 7: 0] DICT_NUM;
		bit [ 3: 0] TREE_CNT;
	always @(posedge CLK or negedge RST_N) begin
		bit [15: 0] WORD,COMP_VAL;
		bit [15: 0] VAL;
		bit [ 3: 0] COMP_BIT_CNT;
		bit [ 3: 0] BIT_CNT;
		bit [15: 0] PATT_SHIFTED_CURR,PATT_SHIFTED_NEXT;
		bit         OUT_CNT;
		bit         REQ;
		
		if (!RST_N) begin
			DEC_ST <= DEC_IDLE;
			DEC_TREE <= '{16{'0}};
			VAL <= '0;
			COMP_BIT_CNT <= '0;
			BIT_CNT <= '0;
			TREE_CNT <= '0;
			OUT_CNT <= 0;
			
			MEM_ADDR <= '0;
			MEM_READ <= 0;
			MODE <= 0;
			{IO_TREE_NUM,IO_TREE_WORD} <= '0;
			IO_DICT_NUM <= '0;
			REQ <= 0;
			WAIT <= 0;
		end else if (!RES_N) begin
			DEC_ST <= DEC_IDLE;
			DEC_TREE <= '{16{'0}};
			VAL <= '0;
			COMP_BIT_CNT <= '0;
			BIT_CNT <= '0;
			TREE_CNT <= '0;
			OUT_CNT <= 0;
			
			MEM_ADDR <= '0;
			MEM_READ <= 0;
			MODE <= 0;
			{IO_TREE_NUM,IO_TREE_WORD} <= '0;
			IO_DICT_NUM <= '0;
			REQ <= 0;
			WAIT <= 0;
		end else begin
			if (WR) begin
				if (ADDR == (4'h0>>1) || ADDR == (4'h2>>1)) begin
					case (ADDR[1])
						1'b0: MEM_ADDR[23:17] <= DI[ 6: 0];
						1'b1: MEM_ADDR[16: 1] <= DI[15: 0];
					endcase
					VAL <= '0;
					COMP_BIT_CNT <= '0;
					BIT_CNT <= '0;
				end
				if (ADDR == (4'h4>>1)) begin
					if (!DI[7]) begin MODE <= 0; {IO_TREE_NUM,IO_TREE_WORD} <= '0; end
					else        begin MODE <= 1; IO_DICT_NUM <= '0; end
				end
				if (ADDR == (4'h6>>1)) begin
					if (!MODE) begin
						case (IO_TREE_WORD)
							1'b0: {DEC_TREE[IO_TREE_NUM].LEN,DEC_TREE[IO_TREE_NUM].IDX} <= DI;
							1'b1: DEC_TREE[IO_TREE_NUM].PATTERN <= DI;
						endcase
						{IO_TREE_NUM,IO_TREE_WORD} <= {IO_TREE_NUM,IO_TREE_WORD} + 5'd1;
					end else begin
						IO_DICT_NUM <= IO_DICT_NUM + 7'd1;
					end
				end
			end
			if (RD) begin
				if (ADDR == (4'h8>>1) || ADDR == (4'hA>>1)) begin
					REQ <= 1;
				end
			end


			case (DEC_ST)
				DEC_IDLE: begin
					if (REQ) begin
						REQ <= 0;
						WAIT <= 1;
						OUT_CNT <= 0;
						DEC_ST <= DEC_NEXT_WORD;
					end
				end
				
				DEC_NEXT_WORD: begin
					if (COMP_BIT_CNT == 4'd0) begin
						if (MEM_RDY) begin
							MEM_READ <= 1;
							DEC_ST <= DEC_READ_MEM;
						end
					end else begin
						DEC_ST <= DEC_VAL;
					end
				end
				
				DEC_READ_MEM: begin
					MEM_READ <= 0;
					if (!MEM_READ && MEM_RDY) begin
						WORD <= MEM_DI;
						MEM_ADDR <= MEM_ADDR + 1'd1;
						DEC_ST <= DEC_COMP_VAL;
					end
				end
				
				DEC_COMP_VAL: begin
					COMP_VAL <= Decipher(WORD);
					DEC_ST <= DEC_VAL;
				end
				
				DEC_VAL: begin
					VAL <= {VAL[14:0],COMP_VAL[15]};
					BIT_CNT <= BIT_CNT + 4'd1;
					COMP_VAL <= {COMP_VAL[14:0],1'b0};
					COMP_BIT_CNT <= COMP_BIT_CNT + 4'd1;
					TREE_CNT <= '0;
					DEC_ST <= DEC_WALK;
				end
				
				DEC_WALK: begin
					PATT_SHIFTED_CURR = DEC_TREE[TREE_CNT + 0].PATTERN >> (4'd12 - BIT_CNT);
					PATT_SHIFTED_NEXT = DEC_TREE[TREE_CNT + 1].PATTERN >> (4'd12 - BIT_CNT);
					
					if (BIT_CNT != DEC_TREE[TREE_CNT].LEN[3:0] ||
					    VAL < PATT_SHIFTED_CURR || (BIT_CNT < 4'd12 && VAL >= PATT_SHIFTED_NEXT)) begin
						TREE_CNT <= TREE_CNT + 4'd1;
						if (TREE_CNT == 4'd11) begin
							DEC_ST <= DEC_NEXT_WORD;
						end
					end else begin
						DICT_NUM <= DEC_TREE[TREE_CNT].IDX + (VAL - PATT_SHIFTED_CURR);
						VAL <= '0;
						BIT_CNT <= '0;
						DEC_ST <= DEC_DICT_READ;
					end
				end
				
				DEC_DICT_READ: begin
					DEC_ST <= DEC_DONE;
				end
				
				DEC_DONE: begin
					OUT_DATA <= {OUT_DATA[7:0],DICT_Q};
					OUT_CNT <= ~OUT_CNT;
					if (!OUT_CNT) begin
						DEC_ST <= DEC_NEXT_WORD;
					end else begin
						WAIT <= 0;
						DEC_ST <= DEC_IDLE;
					end
				end
				
				default: ;
			endcase
						
		end
	end
	
	assign DO = OUT_DATA;
	assign MEM_A = MEM_ADDR;
	assign MEM_RD = MEM_READ;
	
	bit  [ 7: 0] DICT_Q;
	wire [ 6: 0] IO_DICT_ADDR = IO_DICT_NUM;
	wire [15: 0] IO_DICT_DATA = {DI[7:0],DI[15:8]};
	wire         IO_DICT_WREN = ({ADDR,1'b0} == 4'h6 && WR && MODE);
	dpram_dif #(8,8,7,16) dict
	(
		.clock(CLK),

		.address_a(DICT_NUM),
		.q_a(DICT_Q),

		.address_b(IO_DICT_ADDR),
		.data_b(IO_DICT_DATA),
		.wren_b(IO_DICT_WREN)
	);
	
	assign TREE_LEN = DEC_TREE[TREE_CNT].LEN;
	assign TREE_IDX = DEC_TREE[TREE_CNT].IDX;
	assign TREE_PATT = DEC_TREE[TREE_CNT].PATTERN;
	
endmodule

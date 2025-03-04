module SEGA_315_5881 (
	input              CLK,
	input              RST_N,
	
	input              RES_N,
	
	input      [31: 0] KEY,
	
	input              CE_R,
	input              CE_F,
	input      [ 3: 1] ADDR,
	input      [15: 0] DI,
	output     [15: 0] DO,
	input              RD,
	input              WR,
	output reg         WAIT,
	output             ACT,
	
	output     [25: 1] MEM_A,
	input      [15: 0] MEM_DI,
	output             MEM_RD,
	input              MEM_RDY,
	
	output reg [ 7: 0] TREE_NODE
	
`ifdef DEBUG
	                   ,
	output reg [ 7: 0] DBG_BLOCK_CNT
`endif
);


	//Decryptor
	typedef bit [ 2: 0] Table_t[64];
	typedef bit [ 3: 0] Inputs_t[6];
	typedef bit [ 2: 0] Outputs_t[2];
	typedef struct
	{
		Table_t TABLE;
		Inputs_t INPUT;
		Outputs_t OUTPUT;
	} Sbox_t;
	
	typedef Sbox_t FN_t[4];
	
	parameter FN_t FNn[2][4] = 
	'{ 
		//fn1
		'{	
			'{   // 1st round
				'{'{0,3,2,2,1,3,1,2,3,2,1,2,1,2,3,1,3,2,2,0,2,1,3,0,0,3,2,3,2,1,2,0,2,3,1,1,2,2,1,1,1,0,2,3,3,0,2,1,1,1,1,1,3,0,3,2,1,0,1,2,0,3,1,3}, '{4'h3,4'h4,4'h5,4'h7,4'hF,4'hF}, '{3'h0,3'h4}},
				'{'{2,2,2,0,3,3,0,1,2,2,3,2,3,0,2,2,1,1,0,3,3,2,0,2,0,1,0,1,2,3,1,1,0,1,3,3,1,3,3,1,2,3,2,0,0,0,2,2,0,3,1,3,0,3,2,2,0,3,0,3,1,1,0,2}, '{4'h0,4'h1,4'h2,4'h5,4'h6,4'h7}, '{3'h1,3'h6}},
				'{'{0,1,3,0,3,1,1,1,1,2,3,1,3,0,2,3,3,2,0,2,1,1,2,1,1,3,1,0,0,2,0,1,1,3,1,0,0,3,2,3,2,0,3,3,0,0,0,0,1,2,3,3,2,0,3,2,1,0,0,0,2,2,3,3}, '{4'h0,4'h2,4'h5,4'h6,4'h7,4'hF}, '{3'h2,3'h3}},
				'{'{3,2,1,2,1,2,3,2,0,3,2,2,3,1,3,3,0,2,3,0,3,3,2,1,1,1,2,0,2,2,0,1,1,3,3,0,0,3,0,3,0,2,1,3,2,1,0,0,0,1,1,2,0,1,0,0,0,1,3,3,2,0,3,3}, '{4'h1,4'h2,4'h3,4'h4,4'h6,4'h7}, '{3'h5,3'h7}}
			},
			'{   // 2nd round
				'{'{3,3,1,2,0,0,2,2,2,1,2,1,3,1,1,3,3,0,0,3,0,3,3,2,1,1,3,2,3,2,1,3,2,3,0,1,3,2,0,1,2,1,3,1,2,2,3,3,3,1,2,2,0,3,1,2,2,1,3,0,3,0,1,3}, '{4'h0,4'h1,4'h3,4'h4,4'h5,4'h7}, '{3'h0,3'h4}},
				'{'{2,0,1,0,0,3,2,0,3,3,1,2,1,3,0,2,0,2,0,0,0,2,3,1,3,1,1,2,3,0,3,0,3,0,2,0,0,2,2,1,0,2,3,3,1,3,1,0,1,3,3,0,0,1,3,1,0,2,0,3,2,1,0,1}, '{4'h0,4'h1,4'h3,4'h4,4'h6,4'hF}, '{3'h1,3'h5}},
				'{'{2,2,2,3,1,1,0,1,3,3,1,1,2,2,2,0,0,3,2,3,3,0,2,1,2,2,3,0,1,3,0,0,3,2,0,3,2,0,1,0,0,1,2,2,3,3,0,2,2,1,3,1,1,1,1,2,0,3,1,0,0,2,3,2}, '{4'h1,4'h2,4'h5,4'h6,4'h7,4'h6}, '{3'h2,3'h7}},
				'{'{0,1,3,3,3,1,3,3,1,0,2,0,2,0,0,3,1,2,1,3,1,2,3,2,2,0,1,3,0,3,3,3,0,0,0,2,1,1,2,3,2,2,3,1,1,2,0,2,0,2,1,3,1,1,3,3,1,1,3,0,2,3,0,0}, '{4'h2,4'h3,4'h4,4'h5,4'h6,4'h7}, '{3'h3,3'h6}}
			},
			'{   // 3rd round
				'{'{0,0,1,0,1,0,0,3,2,0,0,3,0,1,0,2,0,3,0,0,2,0,3,2,2,1,3,2,2,1,1,2,0,0,0,3,0,1,1,0,0,2,1,0,3,1,2,2,2,0,3,1,3,0,1,2,2,1,1,1,0,2,3,1}, '{4'h1,4'h2,4'h3,4'h4,4'h5,4'h7}, '{3'h0,3'h5}},
				'{'{1,2,1,0,3,1,1,2,0,0,2,3,2,3,1,3,2,0,3,2,2,3,1,1,1,1,0,3,2,0,0,1,1,0,0,1,3,1,2,3,0,0,2,3,3,0,1,0,0,2,3,0,1,2,0,1,3,3,3,1,2,0,2,1}, '{4'h0,4'h2,4'h4,4'h5,4'h6,4'h7}, '{3'h1,3'h6}},
				'{'{0,3,0,2,1,2,0,0,1,1,0,0,3,1,1,0,0,3,0,0,2,3,3,2,3,1,2,0,0,2,3,0,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7}, '{4'h0,4'h2,4'h4,4'h6,4'h7,4'hF}, '{3'h2,3'h3}},
				'{'{0,0,1,0,0,1,0,2,3,3,0,3,3,2,3,0,2,2,2,0,3,2,0,3,1,0,0,3,3,0,0,0,2,2,1,0,2,0,3,2,0,0,3,1,3,3,0,0,2,1,1,2,1,0,1,1,0,3,1,2,0,2,0,3}, '{4'h0,4'h1,4'h2,4'h3,4'h6,4'hF}, '{3'h4,3'h7}}
			},
			'{   // 4th round
				'{'{0,3,3,3,3,3,2,0,0,1,2,0,2,2,2,2,1,1,0,2,2,1,3,2,3,2,0,1,2,3,2,1,3,2,2,3,1,0,1,0,0,2,0,1,2,1,2,3,1,2,1,1,2,2,1,0,1,3,2,3,2,0,3,1}, '{4'h0,4'h1,4'h3,4'h4,4'h5,4'h6}, '{3'h0,3'h5}},
				'{'{0,3,0,0,2,0,3,1,1,1,2,2,2,1,3,1,2,2,1,3,2,2,3,3,0,3,1,0,3,2,0,1,3,0,2,0,1,0,2,1,3,3,1,2,2,0,2,3,3,2,3,0,1,1,3,3,0,2,1,3,0,2,2,3}, '{4'h0,4'h1,4'h2,4'h3,4'h5,4'h7}, '{3'h1,3'h7}},
				'{'{0,1,2,3,3,3,3,1,2,0,2,3,2,1,0,1,2,2,1,2,0,3,2,0,1,1,0,1,3,1,3,1,3,1,0,0,1,0,0,0,0,1,2,2,1,1,3,3,1,2,3,3,3,2,3,0,2,2,1,3,3,0,2,0}, '{4'h2,4'h3,4'h4,4'h5,4'h6,4'h7}, '{3'h2,3'h3}},
				'{'{0,2,1,1,3,2,0,3,1,0,1,0,3,2,1,1,2,2,0,3,1,0,1,2,2,2,3,3,0,0,0,0,1,2,1,0,2,1,2,2,2,3,2,3,0,1,3,0,0,1,3,0,0,1,1,0,1,0,0,0,0,2,0,1}, '{4'h0,4'h1,4'h2,4'h4,4'h6,4'h7}, '{3'h4,3'h6}}
			}
		},
		//fn2
		'{
			'{   // 1st round
				'{'{3,3,0,1,0,1,0,0,0,3,0,0,1,3,1,2,0,3,3,3,2,1,0,1,1,1,2,2,2,3,2,2,2,1,3,3,1,3,1,1,0,0,1,2,0,2,2,1,1,2,3,1,2,1,3,1,2,2,0,1,3,0,2,2}, '{4'h1,4'h3,4'h4,4'h5,4'h6,4'h7}, '{3'h0,3'h7}},
				'{'{0,1,3,0,1,1,2,3,2,0,0,3,2,1,3,1,3,3,0,0,1,0,0,3,0,3,3,2,3,2,0,1,3,2,3,2,2,1,3,1,1,1,0,3,3,2,2,1,1,2,0,2,0,1,1,0,1,0,1,1,2,0,3,0}, '{4'h0,4'h3,4'h5,4'h6,4'h5,4'h0}, '{3'h1,3'h2}},
				'{'{0,2,2,1,0,1,2,1,2,0,1,2,3,3,0,1,3,1,1,2,1,2,1,3,3,2,3,3,2,1,0,1,0,1,0,2,0,1,1,3,2,0,3,2,1,1,1,3,2,3,0,2,3,0,2,2,1,3,0,1,1,2,2,2}, '{4'h0,4'h2,4'h3,4'h4,4'h7,4'hF}, '{3'h3,3'h4}},
				'{'{2,3,1,3,2,0,1,2,0,0,3,3,3,3,3,1,2,0,2,1,2,3,0,2,0,1,0,3,0,2,1,0,2,3,0,1,3,0,3,2,3,1,2,0,3,1,1,2,0,3,0,0,2,0,2,1,2,2,3,2,1,2,3,1}, '{4'h1,4'h2,4'h5,4'h6,4'hF,4'hF}, '{3'h5,3'h6}}
			},
			'{   // 2nd round
				'{'{2,3,1,3,1,0,3,3,3,2,3,3,2,0,0,3,2,3,0,3,1,1,2,3,1,1,2,2,0,1,0,0,2,1,0,1,2,0,1,2,0,3,1,1,2,3,1,2,0,2,0,1,3,0,1,0,2,2,3,0,3,2,3,0}, '{4'h0,4'h1,4'h4,4'h5,4'h6,4'h7}, '{3'h0,3'h7}},
				'{'{0,2,2,0,2,2,0,3,2,3,2,1,3,2,3,3,1,1,0,0,3,0,2,1,1,3,3,2,3,2,0,1,1,2,3,0,1,0,3,0,3,1,0,2,1,2,0,3,2,3,1,2,2,0,3,2,3,0,0,1,2,3,3,3}, '{4'h0,4'h2,4'h3,4'h6,4'h7,4'hF}, '{3'h1,3'h5}},
				'{'{1,0,3,0,0,1,2,1,0,0,1,0,0,0,2,3,2,2,0,2,0,1,3,0,2,0,1,3,2,3,0,1,1,2,2,2,1,3,0,3,0,1,1,0,3,2,3,3,2,0,0,3,1,2,1,3,3,2,1,0,2,1,2,3}, '{4'h2,4'h3,4'h4,4'h6,4'h7,4'h2}, '{3'h2,3'h3}},
				'{'{2,3,1,3,1,1,2,3,3,1,1,0,1,0,2,3,2,1,0,0,2,2,0,1,0,2,2,2,0,2,1,0,3,1,2,3,1,3,0,2,1,0,1,0,0,1,2,2,3,2,3,1,3,2,1,1,2,0,2,1,3,3,1,0}, '{4'h1,4'h2,4'h3,4'h4,4'h5,4'h6}, '{3'h4,3'h6}}
			},
			'{   // 3rd round
				'{'{0,3,0,1,3,0,0,2,1,0,1,3,2,2,2,0,3,3,3,0,2,2,0,3,0,0,2,3,0,3,2,1,3,3,0,3,0,2,3,3,1,1,1,0,2,2,1,1,3,0,3,1,2,0,2,0,0,0,3,2,1,1,0,0}, '{4'h1,4'h4,4'h5,4'h6,4'h7,4'h5}, '{3'h0,3'h5}},
				'{'{0,3,0,1,3,0,3,1,3,2,2,2,3,0,3,2,2,1,2,2,0,3,2,2,0,0,2,1,1,3,2,3,2,3,3,1,2,0,1,2,2,1,0,0,0,0,2,3,1,2,0,3,1,3,1,2,3,2,1,0,3,0,0,2}, '{4'h0,4'h2,4'h3,4'h4,4'h6,4'h7}, '{3'h1,3'h7}},
				'{'{2,2,0,3,0,3,1,0,1,1,2,3,2,3,1,0,0,0,3,2,2,0,2,3,1,3,2,0,3,3,1,3,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7}, '{4'h1,4'h2,4'h4,4'h7,4'h2,4'hF}, '{3'h2,3'h4}},
				'{'{0,2,3,1,3,1,1,0,0,1,3,0,2,1,3,3,2,0,2,1,1,2,3,3,0,0,0,2,0,2,3,0,3,3,3,3,2,3,3,2,3,0,1,0,2,3,3,2,0,1,3,1,0,1,2,3,3,0,2,0,3,0,3,3}, '{4'h0,4'h1,4'h2,4'h3,4'h5,4'h7}, '{3'h3,3'h6}}
			},
			'{   // 4th round
				'{'{0,1,1,0,0,1,0,2,3,3,0,1,2,3,0,2,1,0,3,3,2,0,3,0,0,2,1,0,1,0,1,3,0,3,3,1,2,0,3,0,1,3,2,0,3,3,1,3,0,2,3,3,2,1,1,2,2,1,2,1,2,0,1,1}, '{4'h0,4'h1,4'h2,4'h4,4'h7,4'hF}, '{3'h0,3'h5}},
				'{'{2,0,0,2,3,0,2,3,3,1,1,1,2,1,1,0,0,2,1,0,0,3,1,0,0,3,3,0,1,0,1,2,0,2,0,2,0,1,2,3,2,1,1,0,3,3,3,3,3,3,1,0,3,0,0,2,0,3,2,0,2,2,0,1}, '{4'h0,4'h1,4'h3,4'h5,4'h6,4'hF}, '{3'h1,3'h3}},
				'{'{0,1,1,2,1,3,1,1,0,0,3,1,1,1,2,0,3,2,0,1,1,2,3,3,3,0,3,0,0,2,0,3,3,2,0,0,3,2,3,1,2,3,0,3,2,0,1,2,2,2,0,2,0,1,2,2,3,1,2,2,1,1,1,1}, '{4'h0,4'h2,4'h3,4'h4,4'h5,4'h7}, '{3'h2,3'h7}},
				'{'{0,1,2,0,3,3,0,3,2,1,3,3,0,3,1,1,3,2,3,2,3,0,0,0,3,0,2,2,3,2,2,3,2,2,3,1,2,3,1,2,0,3,0,2,3,1,0,0,3,2,1,2,1,2,1,3,1,0,2,3,3,1,3,2}, '{4'h2,4'h3,4'h4,4'h5,4'h6,4'h7}, '{3'h4,3'h6}}
			}
		}
	};
	bit [23: 0] FN_SUBKEY[8];//0-3 for fn1, 4-7 fo fn2
	
	function bit [7:0] Feistel(input bit [7:0] in, input FN_t FN, input bit [23:0] subkeys);
		bit [7:0] res;
		bit [5:0] subkey[4];
		bit [5:0] temp[4];
		bit [1:0] aux[4];
		
		subkey = '{subkeys[5:0],subkeys[11:6],subkeys[17:12],subkeys[23:18]};
		
		res = '0;
		for (int i=0;i<4;i++) begin
			temp[i][0] = in[FN[i].INPUT[0][2:0]] & ~FN[i].INPUT[0][3];
			temp[i][1] = in[FN[i].INPUT[1][2:0]] & ~FN[i].INPUT[1][3];
			temp[i][2] = in[FN[i].INPUT[2][2:0]] & ~FN[i].INPUT[2][3];
			temp[i][3] = in[FN[i].INPUT[3][2:0]] & ~FN[i].INPUT[3][3];
			temp[i][4] = in[FN[i].INPUT[4][2:0]] & ~FN[i].INPUT[4][3];
			temp[i][5] = in[FN[i].INPUT[5][2:0]] & ~FN[i].INPUT[5][3];
			aux[i] = FN[i].TABLE[temp[i]^subkey[i]][1:0];
			res[FN[i].OUTPUT[0]] = aux[i][0];
			res[FN[i].OUTPUT[1]] = aux[i][1];
		end
		
		return res;
	endfunction
	
	function bit [95:0] FN1GameKeySheduling(input bit [31:0] key);
		return {1'b0   ,1'b0   ,1'b0   ,key[ 7],1'b0   ,key[10],key[ 8],1'b0   ,1'b0   ,key[29],1'b0   ,1'b0   ,1'b0   ,key[19],key[20],1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,key[ 4],1'b0   ,
		        key[ 1],1'b0   ,key[16],1'b0   ,1'b0   ,key[23],1'b0   ,key[12],1'b0   ,1'b0   ,key[26],1'b0   ,key[27],key[ 9],1'b0   ,key[ 4],1'b0   ,key[ 2],1'b0   ,1'b0   ,key[ 6],1'b0   ,key[13],1'b0   ,
		        1'b0   ,1'b0   ,key[24],key[14],key[18],1'b0   ,1'b0   ,key[15],key[ 9],1'b0   ,1'b0   ,1'b0   ,key[25],1'b0   ,1'b0   ,key[21],1'b0   ,1'b0   ,key[ 1],1'b0   ,1'b0   ,1'b0   ,key[28],1'b0   ,
		        key[18],1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,key[17],1'b0   ,key[24],key[25],key[ 5],key[27],key[ 9],key[ 3],1'b0   ,key[11],key[22],key[ 2],1'b0   ,1'b0   ,1'b0   ,1'b0   };
	endfunction
	
	function bit [95:0] FN2GameKeySheduling(input bit [31:0] key);
		return {1'b0   ,key[19],1'b0   ,key[26],1'b0   ,key[29],1'b0   ,key[18],key[ 9],key[ 9],key[23],1'b0   ,key[17],1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,key[16],
		        1'b0   ,1'b0   ,1'b0   ,1'b0   ,key[15],1'b0   ,1'b0   ,1'b0   ,key[14],1'b0   ,key[13],1'b0   ,key[12],1'b0   ,key[11],1'b0   ,key[ 9],1'b0   ,1'b0   ,1'b0   ,1'b0   ,key[10],1'b0   ,1'b0   ,
		        key[27],1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,key[ 8],key[ 7],1'b0   ,1'b0   ,key[20],1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,key[ 6],key[28],1'b0   ,1'b0   ,key[25],1'b0   ,
		        key[ 5],key[ 4],1'b0   ,key[ 3],1'b0   ,1'b0   ,key[21],key[24],1'b0   ,1'b0   ,1'b0   ,1'b0   ,key[ 2],1'b0   ,1'b0   ,1'b0   ,1'b0   ,key[22],1'b0   ,1'b0   ,key[ 1],1'b0   ,1'b0   ,key[ 0]};
	endfunction
	
	function bit [95:0] FN1SequenceKeySheduling(input bit [15:0] key);
		return {1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,key[ 4],1'b0   ,1'b0   ,1'b0   ,key[ 4],key[ 8],1'b0   ,1'b0   ,key[14],1'b0   ,1'b0   ,1'b0   ,key[ 7],1'b0   ,key[13],1'b0   ,1'b0   ,
		        1'b0   ,1'b0   ,1'b0   ,key[ 6],1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,key[ 5],1'b0   ,key[12],1'b0   ,1'b0   ,key[ 0],1'b0   ,1'b0   ,1'b0   ,key[ 6],
		        1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,key[10],1'b0   ,1'b0   ,key[11],1'b0   ,key[ 3],1'b0   ,key[ 1],1'b0   ,1'b0   ,1'b0   ,key[ 9],1'b0   ,1'b0   ,1'b0   ,key[15],1'b0   ,1'b0   ,
		        1'b0   ,key[10],1'b0   ,1'b0   ,key[14],1'b0   ,key[ 2],1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   };
	endfunction
	
	function bit [95:0] FN2SequenceKeySheduling(input bit [15:0] key);
		return {1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,key[10],1'b0   ,key[ 0],1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,
		        1'b0   ,1'b0   ,key[ 6],1'b0   ,1'b0   ,key[ 7],1'b0   ,key[15],1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,key[12],1'b0   ,
		        1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,key[ 3],1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,key[ 4],1'b0   ,key[ 1],1'b0   ,1'b0   ,key[11],1'b0   ,1'b0   ,1'b0   ,key[ 5],1'b0   ,1'b0   ,key[14],
		        1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,key[ 8],1'b0   ,1'b0   ,1'b0   ,key[ 9],key[ 2],key[13],1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   };
	endfunction
	
	function bit [95:0] MidResKeySheduling(input bit [15:0] dat);
		return {dat[ 7],1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,dat[ 6],1'b0   ,1'b0   ,dat[ 5],1'b0   ,1'b0   ,1'b0   ,dat[ 4],1'b0   ,1'b0   ,
		        1'b0   ,1'b0   ,1'b0   ,dat[ 3],1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,dat[15],1'b0   ,1'b0   ,1'b0   ,1'b0   ,dat[14],1'b0   ,dat[13],1'b0   ,1'b0   ,1'b0   ,
		        1'b0   ,1'b0   ,1'b0   ,dat[ 2],1'b0   ,1'b0   ,dat[12],dat[11],1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,dat[10],1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,
		        1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,dat[ 1],1'b0   ,1'b0   ,1'b0   ,1'b0   ,1'b0   ,dat[ 9],1'b0   ,dat[ 8],dat[ 0],1'b0   };
	endfunction
	
	function bit [15:0] SwapCounter(input bit [15:0] v);
		return {v[5],v[12],v[14],v[13],v[9],v[3],v[6],v[4],v[8],v[1],v[15],v[11],v[0],v[7],v[10],v[2]};
	endfunction
	
	function bit [15:0] SwapData(input bit [15:0] v);
		return {v[14],v[3],v[8],v[12],v[13],v[7],v[15],v[4],v[6],v[2],v[9],v[5],v[11],v[0],v[1],v[10]};
	endfunction
	
	function bit [15:0] SwapBlock(input bit [15:0] v);
		return {v[15],v[7],v[6],v[14],v[13],v[12],v[5],v[4],v[3],v[2],v[11],v[10],v[9],v[1],v[0],v[8]};
	endfunction

	typedef enum bit [3:0] {
		DECRYPT_IDLE,  
		DECRYPT_NEXT_WORD,
		DECRYPT_READ_MEM,
		DECRYPT_SWAP, 
		DECRYPT_FEISTEL_1_0,
		DECRYPT_FEISTEL_1_1,DECRYPT_FEISTEL_1_2,DECRYPT_FEISTEL_1_3,DECRYPT_FEISTEL_1_4,
		DECRYPT_MIDKEY_SHED,
		DECRYPT_FEISTEL_2_1,DECRYPT_FEISTEL_2_2,DECRYPT_FEISTEL_2_3,DECRYPT_FEISTEL_2_4,
		DECRYPT_SWAP_OUT,
		DECRYPT_DONE
	} DecryptState_t;
	DecryptState_t DECRYPT_ST;
	
	bit [31: 0] GAME_KEY;
	bit [15: 0] SEQ_KEY;
	bit [25: 1] MEM_ADDR;
	bit         MEM_READ;
	bit [15: 0] DECRYPT_OUT_BLOCK;
	bit         DECRYPT_REQ,DECRYPT_INIT,DECRYPT_READY;
	always @(posedge CLK or negedge RST_N) begin
		bit [15: 0] COUNTER,WORD;
		bit [15: 0] TEMP1,TEMP2;
		bit [ 7: 0] FF_VAL,FF_RES;
		bit [ 2: 0] FF_ROUND;
		bit [15: 0] CURR_BLOCK,PREV_BLOCK;
		bit         REQ;
		
		if (!RST_N) begin
			DECRYPT_ST <= DECRYPT_IDLE;
			FF_VAL <= '0;
			FF_ROUND <= '0;
			{CURR_BLOCK,PREV_BLOCK} <= '0;
			
			MEM_ADDR <= '0;
			MEM_READ <= 0;
			DECRYPT_READY <= 0;
		end else if (!RES_N) begin
			DECRYPT_ST <= DECRYPT_IDLE;
			FF_VAL <= '0;
			FF_ROUND <= '0;
			{CURR_BLOCK,PREV_BLOCK} <= '0;
			
			MEM_ADDR <= '0;
			MEM_READ <= 0;
			DECRYPT_READY <= 0;
		end else begin
			if (WR) begin
				if (ADDR == (4'h8>>1) || ADDR == (4'hA>>1)) begin
					case (ADDR[1])
						1'b0: MEM_ADDR[16: 1] <= DI[15: 0];
						1'b1: MEM_ADDR[25:17] <= DI[ 8: 0];
					endcase
				end
				if (ADDR == (4'hC>>1)) begin
					GAME_KEY <= KEY;
					SEQ_KEY <= DI;
				end
			end
			
			FF_RES = Feistel(FF_VAL, FNn[FF_ROUND[2]][FF_ROUND[1:0]], FN_SUBKEY[FF_ROUND]);
			
			case (DECRYPT_ST)
				DECRYPT_IDLE: begin
					if (DECRYPT_REQ) begin
						DECRYPT_READY <= 0;
						if (DECRYPT_INIT) PREV_BLOCK <= '0;
						DECRYPT_ST <= DECRYPT_NEXT_WORD;
					end
				end
				
				DECRYPT_NEXT_WORD: begin
					if (MEM_RDY) begin
						MEM_READ <= 1;
						DECRYPT_ST <= DECRYPT_READ_MEM;
					end
				end
				
				DECRYPT_READ_MEM: begin
					MEM_READ <= 0;
					if (!MEM_READ && MEM_RDY) begin
						WORD <= {MEM_DI[7:0],MEM_DI[15:8]};
						COUNTER <= MEM_ADDR[16:1];
						MEM_ADDR <= MEM_ADDR + 1'd1;
						DECRYPT_ST <= DECRYPT_SWAP;
					end
				end
				
				DECRYPT_SWAP: begin
					{FN_SUBKEY[3],FN_SUBKEY[2],FN_SUBKEY[1],FN_SUBKEY[0]} = FN1GameKeySheduling(GAME_KEY) ^ FN1SequenceKeySheduling(SEQ_KEY);
					{FN_SUBKEY[7],FN_SUBKEY[6],FN_SUBKEY[5],FN_SUBKEY[4]} = FN2GameKeySheduling(GAME_KEY) ^ FN2SequenceKeySheduling(SEQ_KEY);
					TEMP1 <= SwapCounter(COUNTER);
					TEMP2 <= SwapData(WORD);
					DECRYPT_ST <= DECRYPT_FEISTEL_1_0;
				end
				
				DECRYPT_FEISTEL_1_0: begin
					FF_VAL <= TEMP1[15:8];
					FF_ROUND <= 3'h0;
					DECRYPT_ST <= DECRYPT_FEISTEL_1_1;
				end
				
				DECRYPT_FEISTEL_1_1: begin
					TEMP1[7:0] <= TEMP1[7:0] ^ FF_RES;
					FF_VAL <= TEMP1[7:0] ^ FF_RES;
					FF_ROUND <= 3'h1;
					DECRYPT_ST <= DECRYPT_FEISTEL_1_2;
				end
				
				DECRYPT_FEISTEL_1_2: begin
					TEMP1[15:8] <= TEMP1[15:8] ^ FF_RES;
					FF_VAL <= TEMP1[15:8] ^ FF_RES;
					FF_ROUND <= 3'h2;
					DECRYPT_ST <= DECRYPT_FEISTEL_1_3;
				end
				
				DECRYPT_FEISTEL_1_3: begin
					TEMP1[7:0] <= TEMP1[7:0] ^ FF_RES;
					FF_VAL <= TEMP1[7:0] ^ FF_RES;
					FF_ROUND <= 3'h3;
					DECRYPT_ST <= DECRYPT_FEISTEL_1_4;
				end
				
				DECRYPT_FEISTEL_1_4: begin
					TEMP1[15:8] <= TEMP1[15:8] ^ FF_RES;
					FF_VAL <= TEMP2[15:8];
					FF_ROUND <= 3'h4;
					DECRYPT_ST <= DECRYPT_MIDKEY_SHED;
				end
				
				DECRYPT_MIDKEY_SHED: begin
					{FN_SUBKEY[7],FN_SUBKEY[6],FN_SUBKEY[5],FN_SUBKEY[4]} = {FN_SUBKEY[7],FN_SUBKEY[6],FN_SUBKEY[5],FN_SUBKEY[4]} ^ MidResKeySheduling(TEMP1);
					DECRYPT_ST <= DECRYPT_FEISTEL_2_1;
				end
				
				DECRYPT_FEISTEL_2_1: begin
					TEMP2[7:0] <= TEMP2[7:0] ^ FF_RES;
					FF_VAL <= TEMP2[7:0] ^ FF_RES;
					FF_ROUND <= 3'h5;
					DECRYPT_ST <= DECRYPT_FEISTEL_2_2;
				end
				
				DECRYPT_FEISTEL_2_2: begin
					TEMP2[15:8] <= TEMP2[15:8] ^ FF_RES;
					FF_VAL <= TEMP2[15:8] ^ FF_RES;
					FF_ROUND <= 3'h6;
					DECRYPT_ST <= DECRYPT_FEISTEL_2_3;
				end
				
				DECRYPT_FEISTEL_2_3: begin
					TEMP2[7:0] <= TEMP2[7:0] ^ FF_RES;
					FF_VAL <= TEMP2[7:0] ^ FF_RES;
					FF_ROUND <= 3'h7;
					DECRYPT_ST <= DECRYPT_FEISTEL_2_4;
				end
				
				DECRYPT_FEISTEL_2_4: begin
					TEMP2[15:8] <= TEMP2[15:8] ^ FF_RES;
					DECRYPT_ST <= DECRYPT_SWAP_OUT;
				end
				
				DECRYPT_SWAP_OUT: begin
					CURR_BLOCK <= SwapBlock(TEMP2);
					DECRYPT_ST <= DECRYPT_DONE;
				end
				
				DECRYPT_DONE: begin
					DECRYPT_OUT_BLOCK <= {PREV_BLOCK[15:2],CURR_BLOCK[1:0]};
					PREV_BLOCK <= CURR_BLOCK;
					DECRYPT_READY <= 1;
					DECRYPT_ST <= DECRYPT_IDLE;
				end
				
				default: ;
			endcase
						
		end
	end
	
	//Decompressor
	parameter bit [ 7: 0] TREES[9][2][32] = 
	'{
		'{
			'{8'h01,8'h10,8'h0f,8'h05,8'hc4,8'h13,8'h87,8'h0a,8'hcc,8'h81,8'hce,8'h0c,8'h86,8'h0e,8'h84,8'hc2,8'h11,8'hc1,8'hc3,8'hcf,8'h15,8'hc8,8'hcd,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
			'{8'hc7,8'h02,8'h03,8'h04,8'h80,8'h06,8'h07,8'h08,8'h09,8'hc9,8'h0b,8'h0d,8'h82,8'h83,8'h85,8'hc0,8'h12,8'hc6,8'hc5,8'h14,8'h16,8'hca,8'hcb,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff}
		},
		'{
			'{8'h02,8'h80,8'h05,8'h04,8'h81,8'h10,8'h15,8'h82,8'h09,8'h83,8'h0b,8'h0c,8'h0d,8'hdc,8'h0f,8'hde,8'h1c,8'hcf,8'hc5,8'hdd,8'h86,8'h16,8'h87,8'h18,8'h19,8'h1a,8'hda,8'hca,8'hc9,8'h1e,8'hce,8'hff},
			'{8'h01,8'h17,8'h03,8'h0a,8'h08,8'h06,8'h07,8'hc2,8'hd9,8'hc4,8'hd8,8'hc8,8'h0e,8'h84,8'hcb,8'h85,8'h11,8'h12,8'h13,8'h14,8'hcd,8'h1b,8'hdb,8'hc7,8'hc0,8'hc1,8'h1d,8'hdf,8'hc3,8'hc6,8'hcc,8'hff}
		},
		'{
			'{8'hc6,8'h80,8'h03,8'h0b,8'h05,8'h07,8'h82,8'h08,8'h15,8'hdc,8'hdd,8'h0c,8'hd9,8'hc2,8'h14,8'h10,8'h85,8'h86,8'h18,8'h16,8'hc5,8'hc4,8'hc8,8'hc9,8'hc0,8'hcc,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
			'{8'h01,8'h02,8'h12,8'h04,8'h81,8'h06,8'h83,8'hc3,8'h09,8'h0a,8'h84,8'h11,8'h0d,8'h0e,8'h0f,8'h19,8'hca,8'hc1,8'h13,8'hd8,8'hda,8'hdb,8'h17,8'hde,8'hcd,8'hcb,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff}
		},
		'{
			'{8'h01,8'h80,8'h0d,8'h04,8'h05,8'h15,8'h83,8'h08,8'hd9,8'h10,8'h0b,8'h0c,8'h84,8'h0e,8'hc0,8'h14,8'h12,8'hcb,8'h13,8'hca,8'hc8,8'hc2,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
			'{8'hc5,8'h02,8'h03,8'h07,8'h81,8'h06,8'h82,8'hcc,8'h09,8'h0a,8'hc9,8'h11,8'hc4,8'h0f,8'h85,8'hd8,8'hda,8'hdb,8'hc3,8'hdc,8'hdd,8'hc1,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff}
		},
		'{
			'{8'h01,8'h80,8'h06,8'h0c,8'h05,8'h81,8'hd8,8'h84,8'h09,8'hdc,8'h0b,8'h0f,8'h0d,8'h0e,8'h10,8'hdb,8'h11,8'hca,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
			'{8'hc4,8'h02,8'h03,8'h04,8'hcb,8'h0a,8'h07,8'h08,8'hd9,8'h82,8'hc8,8'h83,8'hc0,8'hc1,8'hda,8'hc2,8'hc9,8'hc3,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff}
		},
		'{
			'{8'h01,8'h02,8'h06,8'h0a,8'h83,8'h0b,8'h07,8'h08,8'h09,8'h82,8'hd8,8'h0c,8'hd9,8'hda,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
			'{8'hc3,8'h80,8'h03,8'h04,8'h05,8'h81,8'hca,8'hc8,8'hdb,8'hc9,8'hc0,8'hc1,8'h0d,8'hc2,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff}
		},
		'{
			'{8'h01,8'h02,8'h03,8'h04,8'h81,8'h07,8'h08,8'hd8,8'hda,8'hd9,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
			'{8'hc2,8'h80,8'h05,8'hc9,8'hc8,8'h06,8'h82,8'hc0,8'h09,8'hc1,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff}
		},
		'{
			'{8'h01,8'h80,8'h04,8'hc8,8'hc0,8'hd9,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
			'{8'hc1,8'h02,8'h03,8'h81,8'h05,8'hd8,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff}
		},
		'{
			'{8'h01,8'hd8,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff},
			'{8'hc0,8'h80,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff,8'hff}
		}
	};

	typedef enum bit [4:0] {
		DECOMP_IDLE,  
		DECOMP_HEADER_HI_0,DECOMP_HEADER_HI_1,
		DECOMP_HEADER_LO_0,DECOMP_HEADER_LO_1,
		DECOMP_DATA_0,DECOMP_DATA_1,
		
		DECOMP_GET_BIT,
		DECOMP_LINE_FILL,
		DECOMP_NEXT_BIT,
		DECOMP_LINE_READ,
		DECOMP_LINE_WRITE,
		DECOMP_LINE_COPY,
		DECOMP_COMP_NEXT,
		
		DECOMP_UNCOMP_OUT,
		DECOMP_UNCOMP_NEXT, 
		
		DECOMP_DONE
	} DecompState_t;
	DecompState_t DECOMP_ST;
	
	typedef enum bit [1:0] {
		LF_FIND_NODE,  
		LF_COPY,
		LF_GET_BYTE, 
		LF_REPEAT
	} LineFillState_t;
	LineFillState_t LF_ST;
	
	bit         PROT_EN;
	bit [31: 0] HEADER;
	bit [ 7: 0] BLOCK_CNT1;
	bit [ 8: 0] BLOCK_CNT2;
	bit [15: 0] OUT_DATA;
//	
	bit [ 7: 0] LINE_BYTE;
	bit         LINE_SEL;
	bit [ 8: 0] LINE_COPY_ADDR;
//	bit [ 7: 0] TREE_NODE;
	always @(posedge CLK or negedge RST_N) begin
		bit         INIT,REQ;
		bit [ 3: 0] COMP_BIT_CNT;
		bit [15: 0] COMP_WORD;
		bit         COMP_BIT;
		bit [ 3: 0] SLOT;
		bit [ 7: 0] NEXT_NODE;
		bit [ 2: 0] LINE_BIT_CNT;
		bit [ 2: 0] LINE_REPEAT_CNT;
		bit         OUT_CNT;
		
		if (!RST_N) begin
			DECOMP_ST <= DECOMP_IDLE;
			{BLOCK_CNT2,BLOCK_CNT1} <= '0;
			
			COMP_WORD <= '0;
			COMP_BIT_CNT <= '0;
			LF_ST <= LF_FIND_NODE;
			LINE_BYTE <= '0;
			LINE_BIT_CNT <= '0;
			LINE_REPEAT_CNT <= '0;
			LINE_SEL <= 0;
			OUT_CNT <= 0;
			
			PROT_EN <= 0;
			INIT <= 0;
			REQ <= 0;
			WAIT <= 0;
			
`ifdef DEBUG
			DBG_BLOCK_CNT <= '0;
`endif
		end else if (!RES_N) begin
			DECOMP_ST <= DECOMP_IDLE;
			{BLOCK_CNT2,BLOCK_CNT1} <= '0;
			
			COMP_WORD <= '0;
			COMP_BIT_CNT <= '0;
			LF_ST <= LF_FIND_NODE;
			LINE_BYTE <= '0;
			LINE_BIT_CNT <= '0;
			LINE_REPEAT_CNT <= '0;
			LINE_SEL <= 0;
			OUT_CNT <= 0;
			
			PROT_EN <= 0;
			INIT <= 0;
			REQ <= 0;
			WAIT <= 0;
			
`ifdef DEBUG
			DBG_BLOCK_CNT <= '0;
`endif
		end else begin
			if (WR) begin
				if (ADDR == (4'h0>>1)) begin
					PROT_EN <= DI[0];
				end
				if (/*ADDR == (4'h8>>1) ||*/ ADDR == (4'hA>>1)) begin
					INIT <= 1;
				end
			end
			if (RD) begin
				if (ADDR == (4'hC>>1) || ADDR == (4'hE>>1)) begin
					if (PROT_EN) begin
						REQ <= 1;
					end
				end
			end
			
			SLOT = BLOCK_CNT2 ? (BLOCK_CNT2 < (HEADER[16:8] + 9'd1 - 9'd7) ? 4'd1 : {1'b0,BLOCK_CNT2[2:0]} + 4'd1) : 4'd0;
			NEXT_NODE = TREES[SLOT][COMP_BIT][TREE_NODE];
			
			DECRYPT_REQ <= 0;
			DECRYPT_INIT <= 0;
			case (DECOMP_ST)
				DECOMP_IDLE: begin
					if (REQ) begin
						REQ <= 0;
						WAIT <= 1;
						if (COMP_BIT_CNT >= 4'd14) begin DECRYPT_REQ <= 1; DECRYPT_INIT <= 1; end
						DECOMP_ST <= DECOMP_HEADER_HI_0;
					end
				end
				
				DECOMP_HEADER_HI_0: begin
					DECOMP_ST <= DECOMP_HEADER_HI_1;
				end
				
				DECOMP_HEADER_HI_1: begin
					if (DECRYPT_READY) begin
						HEADER[31:16] <= DECRYPT_OUT_BLOCK;
						DECRYPT_REQ <= 1;
						DECOMP_ST <= DECOMP_HEADER_LO_0;
					end
				end
				
				DECOMP_HEADER_LO_0: begin
					DECOMP_ST <= DECOMP_HEADER_LO_1;
				end
				
				DECOMP_HEADER_LO_1: begin
					if (DECRYPT_READY) begin
						HEADER[15:0] <= DECRYPT_OUT_BLOCK;
						COMP_BIT_CNT <= !HEADER[17] ? 4'd15 : '0;
						DECRYPT_REQ <= 1;
						DECOMP_ST <= DECOMP_DATA_0;
					end
				end
				
				DECOMP_DATA_0: begin
					DECOMP_ST <= DECOMP_DATA_1;
				end
				
				DECOMP_DATA_1: begin
					if (DECRYPT_READY) begin
						COMP_WORD <= DECRYPT_OUT_BLOCK;
						DECOMP_ST <= HEADER[17] ? DECOMP_GET_BIT : DECOMP_UNCOMP_OUT;
					end
				end
				
				//compressed
				DECOMP_NEXT_BIT: begin
					COMP_BIT_CNT <= COMP_BIT_CNT + 4'd1;
					DECOMP_ST <= DECOMP_GET_BIT;
					if (COMP_BIT_CNT == 4'd15) begin
						DECRYPT_REQ <= 1;
						DECOMP_ST <= DECOMP_DATA_0;
					end
				end
				
				DECOMP_GET_BIT: begin
					{COMP_BIT,COMP_WORD[15:1]} <= COMP_WORD;
					DECOMP_ST <= DECOMP_LINE_FILL;
				end
				
				DECOMP_LINE_FILL: begin
					case (LF_ST)
						LF_FIND_NODE: begin
							if (NEXT_NODE[7] == 8'hFF) begin
								TREE_NODE <= 8'h00;
								LF_ST <= LF_FIND_NODE;
								DECOMP_ST <= DECOMP_NEXT_BIT;
							end else if (!NEXT_NODE[7]) begin
								TREE_NODE <= NEXT_NODE;
								LF_ST <= LF_FIND_NODE;
								DECOMP_ST <= DECOMP_NEXT_BIT;
							end else if (NEXT_NODE[6]) begin
								TREE_NODE <= NEXT_NODE;
								LF_ST <= LF_COPY;
								DECOMP_ST <= DECOMP_NEXT_BIT;
							end else begin
								TREE_NODE <= NEXT_NODE;
								LF_ST <= LF_GET_BYTE;
								DECOMP_ST <= DECOMP_NEXT_BIT;
							end
						end
						
						LF_COPY: begin
							LINE_REPEAT_CNT <= LINE_REPEAT_CNT + 3'd1;
							if (LINE_REPEAT_CNT == TREE_NODE[2:0]) begin
								LINE_REPEAT_CNT <= '0;
								TREE_NODE <= 8'h00;
								LF_ST <= LF_FIND_NODE;
							end
							LINE_COPY_ADDR <= BLOCK_CNT2 + {{8{TREE_NODE[4]&TREE_NODE[3]}},TREE_NODE[3]};
							DECOMP_ST <= DECOMP_LINE_READ;
						end
						
						LF_GET_BYTE: begin
							LINE_BYTE <= {LINE_BYTE[6:0],COMP_BIT};
							LINE_BIT_CNT <= LINE_BIT_CNT + 3'd1;
							if (LINE_BIT_CNT == 3'd7) begin
								LF_ST <= LF_REPEAT;
							end
							DECOMP_ST <= DECOMP_NEXT_BIT;
						end
						
						LF_REPEAT: begin
							LINE_REPEAT_CNT <= LINE_REPEAT_CNT + 3'd1;
							if (LINE_REPEAT_CNT == TREE_NODE[2:0]) begin
								LINE_REPEAT_CNT <= '0;
								TREE_NODE <= 8'h00;
								LF_ST <= LF_FIND_NODE;
							end
							DECOMP_ST <= DECOMP_LINE_WRITE;
						end
					endcase
				end
				
				DECOMP_LINE_READ: begin
					DECOMP_ST <= DECOMP_LINE_COPY;
				end
				
				DECOMP_LINE_WRITE,
				DECOMP_LINE_COPY: begin
					case (OUT_CNT)
						1'b0: OUT_DATA[15:8] <= UNCOMP_BYTE;
						1'b1: OUT_DATA[7:0] <= UNCOMP_BYTE;
					endcase
					OUT_CNT <= ~OUT_CNT;
					if (!OUT_CNT) begin
						DECOMP_ST <= DECOMP_LINE_FILL;
					end else begin
						WAIT <= 0;
						DECOMP_ST <= DECOMP_COMP_NEXT;
					end
					
					BLOCK_CNT2 <= BLOCK_CNT2 + 9'd1;
					if (BLOCK_CNT2 == HEADER[16:8]) begin
						BLOCK_CNT2 <= '0;
						BLOCK_CNT1 <= BLOCK_CNT1 + 8'd1;
						LINE_SEL <= ~LINE_SEL;
						if (BLOCK_CNT1 == HEADER[7:0]) begin
							BLOCK_CNT1 <= '0;
`ifdef DEBUG
							DBG_BLOCK_CNT <= DBG_BLOCK_CNT + 8'd1;
`endif
							DECOMP_ST <= DECOMP_DONE;
						end
					end
				end
				
				DECOMP_COMP_NEXT: begin
					if (REQ) begin
						REQ <= 0;
						WAIT <= 1;
						DECOMP_ST <= DECOMP_LINE_FILL;
					end
				end
				
				//uncompressed
				DECOMP_UNCOMP_OUT: begin
					OUT_DATA <= COMP_WORD;
					WAIT <= 0;
					
					BLOCK_CNT2 <= BLOCK_CNT2 + 9'd2;
					DECOMP_ST <= DECOMP_UNCOMP_NEXT;
					if (BLOCK_CNT2[8:1] == HEADER[16:9]) begin
						BLOCK_CNT2 <= '0;
						BLOCK_CNT1 <= BLOCK_CNT1 + 8'd1;
						if (BLOCK_CNT1 == HEADER[7:0]) begin
							BLOCK_CNT1 <= '0;
`ifdef DEBUG
							DBG_BLOCK_CNT <= DBG_BLOCK_CNT + 8'd1;
`endif
							DECOMP_ST <= DECOMP_DONE;
						end
					end
				end
				
				DECOMP_UNCOMP_NEXT: begin
					if (REQ) begin
						REQ <= 0;
						WAIT <= 1;
						DECRYPT_REQ <= 1;
						DECOMP_ST <= DECOMP_DATA_0;
					end
				end
				
				DECOMP_DONE: begin
					DECOMP_ST <= DECOMP_IDLE;
				end
				
				default: ;
			endcase
			
			if (INIT) begin
				INIT <= 0;
				DECOMP_ST <= DECOMP_IDLE;
				HEADER <= '0;
				COMP_BIT_CNT <= 4'd15;
				LF_ST <= LF_FIND_NODE;
				TREE_NODE <= 8'h00;
				LINE_BIT_CNT <= '0;
				LINE_REPEAT_CNT <= '0;
				{BLOCK_CNT2,BLOCK_CNT1} <= '0;
				OUT_CNT <= 0;
				
`ifdef DEBUG
				DBG_BLOCK_CNT <= '0;
`endif
			end
		end
	end
	
	assign DO = ADDR == (4'h0>>1)                      ? 16'h0000 : 
	            ADDR == (4'h8>>1)                      ? MEM_ADDR[16: 1] : 
	            ADDR == (4'hA>>1)                      ? {7'b0000000,MEM_ADDR[25:17]} :
	            ADDR == (4'hC>>1) || ADDR == (4'hE>>1) ? OUT_DATA : 
					                                         16'h0000;
	assign ACT = PROT_EN;
	assign MEM_A = MEM_ADDR;
	assign MEM_RD = MEM_READ;
	
	wire [ 8: 0] LINE_WRITE_ADDR = BLOCK_CNT2;
	wire         LINE_WREN = (DECOMP_ST == DECOMP_LINE_WRITE || DECOMP_ST == DECOMP_LINE_COPY);
	wire [ 8: 0] LINE_READ_ADDR = LINE_COPY_ADDR > HEADER[16:8] ? LINE_COPY_ADDR - (HEADER[16:8] + 9'd1): LINE_COPY_ADDR;
	bit  [ 7: 0] LINE0_Q;
	dpram #(9,8) line0
	(
		.clock(CLK),

		.address_a(LINE_WRITE_ADDR),
		.data_a(DECOMP_ST == DECOMP_LINE_WRITE ? LINE_BYTE : LINE1_Q),
		.wren_a(LINE_WREN && !LINE_SEL),

		.address_b(LINE_READ_ADDR),
		.q_b(LINE0_Q)
	);
	
	bit  [ 7: 0] LINE1_Q;
	dpram #(9,8) line1
	(
		.clock(CLK),

		.address_a(LINE_WRITE_ADDR),
		.data_a(DECOMP_ST == DECOMP_LINE_WRITE ? LINE_BYTE : LINE0_Q),
		.wren_a(LINE_WREN && LINE_SEL),

		.address_b(LINE_READ_ADDR),
		.q_b(LINE1_Q)
	);
	wire [ 7: 0] UNCOMP_BYTE = DECOMP_ST == DECOMP_LINE_WRITE ? LINE_BYTE : (!LINE_SEL ? LINE1_Q : LINE0_Q);
	
endmodule

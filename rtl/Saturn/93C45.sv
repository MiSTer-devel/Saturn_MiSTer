module E93C45
#(parameter init_file = " ")
(
	input              CLK,
	input              RST_N,
	
	input              DI,
	output             DO,
	input              CS,
	input              SK,
	
	input      [ 5: 0] MEM_A,
	input      [15: 0] MEM_DI,
	input              MEM_WREN,
	output     [15: 0] MEM_DO
);

	bit          SK_OLD,CS_OLD;
	always @(posedge CLK) begin
		SK_OLD <= SK;
		CS_OLD <= CS;
	end
	wire SK_FALL = !SK &  SK_OLD;
	wire SK_RISE =  SK & !SK_OLD;
	wire CS_FALL = !CS &  CS_OLD;
	wire CS_RISE =  CS & !CS_OLD;
	
	bit  [ 2: 0] STATE;
	bit  [ 1: 0] OPCODE;
	bit          WEN;
	bit  [ 5: 0] ADDRESS;
	bit  [15: 0] DATA;
	bit          WRITE;
	always @(posedge CLK or negedge RST_N) begin
		bit  [ 3: 0] BIT_CNT;
		
		if (!RST_N) begin
			STATE <= '0;
			BIT_CNT <= '0;
			OPCODE <= '0;
			ADDRESS <= '0;
			DATA <= '0;
			WRITE <= 0;
		end else begin
			WRITE <= 0;
			case (STATE)
				3'd0: begin
					if (CS_RISE) begin
						STATE <= 3'd1;
					end
				end
				
				3'd1: begin	//start
					if (DI && SK_RISE) begin
						DO <= 0;
						BIT_CNT <= '0;
						STATE <= 3'd2;
					end 
					if (CS_FALL) begin
						DO <= 1;
						STATE <= 3'd0;
					end 
				end
				
				3'd2: begin	//opcode
					if (SK_RISE) begin
						BIT_CNT <= BIT_CNT + 4'd1;
						case (BIT_CNT) 
							4'd0: begin OPCODE[1] <= DI; end
							4'd1: begin OPCODE[0] <= DI; BIT_CNT <= '0; STATE <= 3'd3; end
						endcase
					end 
					if (CS_FALL) begin
						DO <= 1;
						STATE <= 3'd0;
					end 
				end
				
				3'd3: begin	//address
					if (SK_RISE) begin
						BIT_CNT <= BIT_CNT + 4'd1;
						case (BIT_CNT) 
							4'd0: begin ADDRESS[5] <= DI; end
							4'd1: begin ADDRESS[4] <= DI; end
							4'd2: begin ADDRESS[3] <= DI; end
							4'd3: begin ADDRESS[2] <= DI; end
							4'd4: begin ADDRESS[1] <= DI; end
							4'd5: begin ADDRESS[0] <= DI; DO <= 0; BIT_CNT <= '0; STATE <= 3'd4; end
						endcase
					end 
					if (CS_FALL) begin
						DO <= 1;
						STATE <= 3'd0;
					end 
				end
				
				3'd4: begin	//read/ewen/ewds
					case (OPCODE)
						2'b00: begin
							if (ADDRESS[5:4] == 2'b11) WEN <= 1;
							if (ADDRESS[5:4] == 2'b00) WEN <= 0;
							//if (ADDRESS[5:4] == 2'b01) WEN <= 1;
							STATE <= 3'd7;
						end 
						2'b01: begin
							STATE <= 3'd6;
						end 
						2'b10: begin
							STATE <= 3'd5;
						end 
						2'b11: begin
							STATE <= 3'd7;
						end 
					endcase
				end
				
				3'd5: begin	//read to buf
					DATA <= EEPROM_Q;
					STATE <= 3'd6;
				end
				
				3'd6: begin	//data in/out
					if (SK_RISE) begin
						{DO,DATA} <= {DATA,DI};
						BIT_CNT <= BIT_CNT + 4'd1;
						if (BIT_CNT == 4'd15) begin 
							if (OPCODE == 2'b10) begin
								ADDRESS <= ADDRESS + 6'd1;
								STATE <= 3'd4; 
							end else begin
								STATE <= 3'd7; 
							end
						end
					end 
					if (CS_FALL) begin
						DO <= 1;
						STATE <= 3'd0;
					end 
				end
				
				3'd7: begin	//write
					if (CS_FALL) begin
						DO <= 1;
						WRITE <= (OPCODE == 2'b01 && WEN);
						STATE <= 3'd0;
					end 
				end
				
				default:;
			endcase
		end
	end
	
	bit  [15: 0] EEPROM_Q;
	dpram #(6,16,init_file) eeprom
	(
		.clock(CLK),

		.address_a(ADDRESS),
		.data_a(DATA),
		.wren_a(WRITE),
		.q_a(EEPROM_Q),

		.address_b(MEM_A),
		.data_b(MEM_DI),
		.wren_b(MEM_WREN),
		.q_b(MEM_DO)
	);


endmodule

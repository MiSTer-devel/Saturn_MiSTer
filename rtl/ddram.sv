//
// ddram.v
// Copyright (c) 2020 Sorgelig
//
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version. 
//
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License 
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// ------------------------------------------
//


module ddram
(
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,
	
	input         clk,
	input         rst,

	input  [25:1] mem0_addr,
	output [31:0] mem0_dout,
	input  [31:0] mem0_din,
	input         mem0_rd,
	input   [3:0] mem0_wr,
	input         mem0_16b,
	output        mem0_busy,
	
	input  [25:1] mem1_addr,
	output [31:0] mem1_dout,
	input  [31:0] mem1_din,
	input         mem1_rd,
	input   [3:0] mem1_wr,
	input         mem1_16b,
	output        mem1_busy,

	input  [25:1] mem2_addr,
	output [31:0] mem2_dout,
	input  [31:0] mem2_din,
	input         mem2_rd,
	input   [3:0] mem2_wr,
	input         mem2_16b,
	output        mem2_busy,

	input  [25:1] mem3_addr,
	output [31:0] mem3_dout,
	input  [31:0] mem3_din,
	input         mem3_rd,
	input   [3:0] mem3_wr,
	input         mem3_16b,
	output        mem3_busy,

	input  [25:1] mem4_addr,
	output [31:0] mem4_dout,
	input  [31:0] mem4_din,
	input         mem4_rd,
	input   [3:0] mem4_wr,
	input         mem4_16b,
	output        mem4_busy,

	input  [25:1] mem5_addr,
	output [31:0] mem5_dout,
	input  [31:0] mem5_din,
	input         mem5_rd,
	input   [3:0] mem5_wr,
	input         mem5_16b,
	output        mem5_busy,

	input  [25:1] mem6_addr,
	output [31:0] mem6_dout,
	input  [31:0] mem6_din,
	input         mem6_rd,
	input   [3:0] mem6_wr,
	input         mem6_16b,
	output        mem6_busy,

	input  [25:1] mem7_addr,
	output [31:0] mem7_dout,
	input  [31:0] mem7_din,
	input         mem7_rd,
	input   [3:0] mem7_wr,
	input         mem7_16b,
	output        mem7_busy,

	input  [25:1] mem8_addr,
	output [31:0] mem8_dout,
	input  [31:0] mem8_din,
	input         mem8_rd,
	input   [3:0] mem8_wr,
	input         mem8_16b,
	output        mem8_busy
);

reg  [ 25:  1] ram_address;
reg  [ 63:  0] ram_din;
reg  [  7:  0] ram_be;
reg  [  7:  0] ram_burst;
reg            ram_read = 0;
reg            ram_write = 0;
reg  [  3:  0] ram_chan;

reg  [ 25:  1] rcache_addr[9];
reg            rcache_dirty[9] = '{9{1}};
reg  [127:  0] rcache_buf[9];
reg            rcache_word[9];
reg            rcache_update[9];

reg            read_busy[9] = '{9{0}};
reg            write_busy[9] = '{9{0}};

wire           mem_rd[9] = '{mem0_rd,mem1_rd,mem2_rd,mem3_rd,mem4_rd,mem5_rd,mem6_rd,mem7_rd,mem8_rd};
wire [  3:  0] mem_wr[9] = '{mem0_wr,mem1_wr,mem2_wr,mem3_wr,mem4_wr,mem5_wr,mem6_wr,mem7_wr,mem8_wr};
wire [ 25:  1] mem_addr[9] = '{mem0_addr,mem1_addr,mem2_addr,mem3_addr,mem4_addr,mem5_addr,mem6_addr,mem7_addr,mem8_addr};
wire           mem_16b[9] = '{mem0_16b,mem1_16b,mem2_16b,mem3_16b,mem4_16b,mem5_16b,mem6_16b,mem7_16b,mem8_16b};
//wire [ 31:  0] mem_din[9] = '{mem0_din,mem1_din,mem2_din,mem3_din,mem4_din,mem5_din,mem6_din,mem7_din,mem8_din};
wire [ 31:  0] mem_dout[9];
wire           mem_busy[9];

reg  [  2:  0] state = 0;

reg  [  1:  0] cache_wraddr;
reg            cache_update;

reg            old_rd[9],old_wr[9],old_rst;
always @(posedge clk) begin
	for (int i=0; i<9; i++) begin
		old_rd[i] <= mem_rd[i];
		old_wr[i] <= |mem_wr[i];
	end
	old_rst <= rst;
end
wire           rst_pulse = (rst && !old_rst);

wire           fifo_wrreq[9];
wire           fifo_rdreq[9];
always_comb begin
	for (int i=0; i<9; i++) begin
		fifo_wrreq[i] = (|mem_wr[i] && !old_wr[i]);
		fifo_rdreq[i] = (state == 3'h1 && !DDRAM_BUSY && ram_chan == i);
	end
end

wire [ 60:  0] fifo_dout[9];
wire           fifo_empty[9];
wire           fifo_full[9];
ddr_infifo #(2) fifo0 (clk, rst_pulse, {mem0_addr,mem0_wr,mem0_din}, fifo_wrreq[0], fifo_rdreq[0], fifo_dout[0], fifo_empty[0], fifo_full[0]);
ddr_infifo #(3) fifo1 (clk, rst_pulse, {mem1_addr,mem1_wr,mem1_din}, fifo_wrreq[1], fifo_rdreq[1], fifo_dout[1], fifo_empty[1], fifo_full[1]);
ddr_infifo #(3) fifo2 (clk, rst_pulse, {mem2_addr,mem2_wr,mem2_din}, fifo_wrreq[2], fifo_rdreq[2], fifo_dout[2], fifo_empty[2], fifo_full[2]);
ddr_infifo #(3) fifo3 (clk, rst_pulse, {mem3_addr,mem3_wr,mem3_din}, fifo_wrreq[3], fifo_rdreq[3], fifo_dout[3], fifo_empty[3], fifo_full[3]);
ddr_infifo #(2) fifo4 (clk, rst_pulse, {mem4_addr,mem4_wr,mem4_din}, fifo_wrreq[4], fifo_rdreq[4], fifo_dout[4], fifo_empty[4], fifo_full[4]);
assign fifo_empty[5] = 1; assign fifo_full[5] = 0; assign fifo_dout[5] = '0;
ddr_infifo #(2) fifo6 (clk, rst_pulse, {mem6_addr,mem6_wr,mem6_din}, fifo_wrreq[6], fifo_rdreq[6], fifo_dout[6], fifo_empty[6], fifo_full[6]);
ddr_infifo2     fifo7 (clk, rst_pulse, {mem7_addr,mem7_wr,mem7_din}, fifo_wrreq[7], fifo_rdreq[7], fifo_dout[7], fifo_empty[7], fifo_full[7]);
ddr_infifo2     fifo8 (clk, rst_pulse, {mem8_addr,mem8_wr,mem8_din}, fifo_wrreq[8], fifo_rdreq[8], fifo_dout[8], fifo_empty[8], fifo_full[8]);

wire [ 25:  1] fifo_write_addr[9];
wire [ 63:  0] fifo_write_buf[9];
wire [  7:  0] fifo_write_be[9];
always_comb begin
	for (int i=0; i<9; i++) begin
		fifo_write_addr[i] = fifo_dout[i][25-1+4+32:1-1+4+32];
		if (mem_16b[i]) begin
			fifo_write_buf[i] = {4{fifo_dout[i][15:0]}};
			case (fifo_dout[i][2-1+4+32:1-1+4+32])
				2'b00: fifo_write_be[i] = {fifo_dout[i][1+32:0+32],6'b000000};
				2'b01: fifo_write_be[i] = {2'b00,fifo_dout[i][1+32:0+32],4'b0000};
				2'b10: fifo_write_be[i] = {4'b0000,fifo_dout[i][1+32:0+32],2'b00};
				2'b11: fifo_write_be[i] = {6'b000000,fifo_dout[i][1+32:0+32]};
			endcase
		end else begin
			fifo_write_buf[i] = {2{fifo_dout[i][31:0]}};
			case (fifo_dout[i][2-1+4+32])
				1'b0: fifo_write_be[i] = {fifo_dout[i][3+32:0+32],4'b0000};
				1'b1: fifo_write_be[i] = {4'b0000,fifo_dout[i][3+32:0+32]};
			endcase
		end
	end
end

always @(posedge clk) begin
	bit write,fifo_write,read;
	bit [3:0] chan;

	for (int i=0; i<9; i++) begin
		if (rst_pulse) begin
			rcache_dirty[i] <= 1;
			read_busy[i] <= 0;
		end
		else if (mem_rd[i] && !old_rd[i]) begin
			if (rcache_addr[i][25:5] != mem_addr[i][25:5] || rcache_dirty[i]) begin
				read_busy[i] <= 1;
			end
			rcache_addr[i] <= mem_addr[i];
			rcache_word[i] <= mem_16b[i];
			rcache_dirty[i] <= 0;
		end
		
		if (rst_pulse) begin
			write_busy[i] <= 0;		
		end
		else if (|mem_wr[i] && !old_wr[i]) begin
//			write_addr[i] <= mem_addr[i];
//			write_busy[i] <= 1;
//			if (mem_16b[i]) begin
//				write_buf[i] <= {2{mem_din[i][15:0]}};
//				case (mem_addr[i][2:1])
//					2'b00: write_be[i] <= {mem_wr[i][1:0],6'b000000};
//					2'b01: write_be[i] <= {2'b00,mem_wr[i][1:0],4'b0000};
//					2'b10: write_be[i] <= {4'b0000,mem_wr[i][1:0],2'b00};
//					2'b11: write_be[i] <= {6'b000000,mem_wr[i][1:0]};
//				endcase
//			end else begin
//				write_buf[i] <= mem_din[i];
//				case (mem_addr[i][2])
//					1'b0: write_be[i] <= {mem_wr[i][3:0],4'b0000};
//					1'b1: write_be[i] <= {4'b0000,mem_wr[i][3:0]};
//				endcase
//			end
//			
//			rcache_update[i] <= (rcache_addr[i][24:5] == mem_addr[i][24:5]);

			if (rcache_addr[i][25:5] == mem_addr[i][25:5]) begin
				rcache_dirty[i] <= 1;
//				if (mem_16b[i]) begin
//					write_buf[i] <= {2{mem_din[i][15:0]}};
//					case (mem_addr[i][2:1])
//						2'b00: write_be[i] <= {mem_wr[i][1:0],6'b000000};
//						2'b01: write_be[i] <= {2'b00,mem_wr[i][1:0],4'b0000};
//						2'b10: write_be[i] <= {4'b0000,mem_wr[i][1:0],2'b00};
//						2'b11: write_be[i] <= {6'b000000,mem_wr[i][1:0]};
//					endcase
//				end else begin
//					write_buf[i] <= mem_din[i];
//					case (mem_addr[i][2])
//						1'b0: write_be[i] <= {mem_wr[i][3:0],4'b0000};
//						1'b1: write_be[i] <= {4'b0000,mem_wr[i][3:0]};
//					endcase
//				end
//				rcache_update[i] <= 1;
			end
		end
	end
	
	if (rst_pulse) begin
		state <= '0;
		ram_write <= 0;
		ram_read  <= 0;
	end
	else if(!DDRAM_BUSY) begin
		ram_write <= 0;
		ram_read  <= 0;

		case (state)
			0: begin
				write = 0;
				fifo_write = 0;
				read = 0;
				chan = 4'h0;
//				if      (write_busy[0]) begin write = 1; chan = 4'h0; end
				if      (!fifo_empty[0]) begin fifo_write = 1; chan = 4'h0; end
				else if (read_busy[0])  begin read = 1;  chan = 4'h0; end
//				else if (write_busy[1]) begin write = 1; chan = 4'h1; end
				else if (!fifo_empty[1]) begin fifo_write = 1; chan = 4'h1; end
				else if (read_busy[1])  begin read = 1;  chan = 4'h1; end
//				else if (write_busy[2]) begin write = 1; chan = 4'h2; end
				else if (!fifo_empty[2]) begin fifo_write = 1; chan = 4'h2; end
				else if (read_busy[2])  begin read = 1;  chan = 4'h2; end
//				else if (write_busy[3]) begin write = 1; chan = 4'h3; end
				else if (!fifo_empty[3]) begin fifo_write = 1; chan = 4'h3; end
				else if (read_busy[3])  begin read = 1;  chan = 4'h3; end
//				else if (write_busy[4]) begin write = 1; chan = 4'h4; end
				else if (!fifo_empty[4]) begin fifo_write = 1; chan = 4'h4; end
				else if (read_busy[4])  begin read = 1;  chan = 4'h4; end
//				else if (write_busy[5]) begin write = 1; chan = 4'h5; end
				else if (!fifo_empty[5]) begin fifo_write = 1; chan = 4'h5; end
				else if (read_busy[5])  begin read = 1;  chan = 4'h5; end
//				else if (write_busy[6]) begin write = 1; chan = 4'h6; end
				else if (!fifo_empty[6]) begin fifo_write = 1; chan = 4'h6; end
				else if (read_busy[6])  begin read = 1;  chan = 4'h6; end
//				else if (write_busy[7]) begin write = 1; chan = 4'h7; end
				else if (!fifo_empty[7]) begin fifo_write = 1; chan = 4'h7; end
				else if (read_busy[7])  begin read = 1;  chan = 4'h7; end
//				else if (write_busy[8]) begin write = 1; chan = 4'h8; end
				else if (!fifo_empty[8]) begin fifo_write = 1; chan = 4'h8; end
				else if (read_busy[8])  begin read = 1;  chan = 4'h8; end
				
//				if (write) begin
//					ram_address <= {write_addr[chan][25:3],2'b00};
//					ram_din		<= {2{write_buf[chan]}};
//					ram_be      <= write_be[chan];
//					ram_write 	<= 1;
//					ram_burst   <= 1;
//					ram_chan    <= chan;
//					cache_wraddr<= write_addr[chan][4:3];
//					cache_update<= 0;//rcache_update[chan];
//					write_busy[chan] <= 0;
//					state       <= 3'h1;
//				end
				if (fifo_write) begin
					ram_address <= {fifo_write_addr[chan][25:3],2'b00};
					ram_din		<= fifo_write_buf[chan];
					ram_be      <= fifo_write_be[chan];
					ram_write 	<= 1;
					ram_burst   <= 1;
					ram_chan    <= chan;
					cache_wraddr<= fifo_write_addr[chan][4:3];
					cache_update<= 0;//rcache_update[chan];
//					write_busy[chan] <= 0;
					state       <= 3'h1;
				end
				if (read) begin
					ram_address <= {rcache_addr[chan][25:5],4'b0000};
					ram_be      <= 8'hFF;
					ram_read    <= 1;
					ram_burst   <= 4;
					ram_chan    <= chan;
					cache_wraddr <= '0;
					state       <= 3'h2;
				end
			end

			3'h1: begin
				cache_update <= 0;
				state <= 0;
			end
		
			3'h2: if (DDRAM_DOUT_READY) begin
				for (int i=0; i<9; i++) begin
					cache_wraddr <= cache_wraddr + 2'd1;
					if (cache_wraddr == 2'd3) begin
						read_busy[ram_chan] <= 0;
						state <= 0;
					end
				end
			end
		endcase
	end
end


wire [ 63:  0] cache_data[9] = '{state == 3'h2 ? DDRAM_DOUT : '0/*{2{write_buf[0]}}*/,
                                  state == 3'h2 ? DDRAM_DOUT : '0/*{2{write_buf[1]}}*/,
											 state == 3'h2 ? DDRAM_DOUT : '0/*{2{write_buf[2]}}*/,
											 state == 3'h2 ? DDRAM_DOUT : '0/*{2{write_buf[3]}}*/,
											 state == 3'h2 ? DDRAM_DOUT : '0/*{2{write_buf[4]}}*/,
											 state == 3'h2 ? DDRAM_DOUT : '0/*{2{write_buf[5]}}*/,
											 state == 3'h2 ? DDRAM_DOUT : '0/*{2{write_buf[6]}}*/,
											 state == 3'h2 ? DDRAM_DOUT : '0/*{2{write_buf[7]}}*/,
											 state == 3'h2 ? DDRAM_DOUT : '0/*{2{write_buf[8]}}*/}; 
wire [  7:  0] cache_be = state == 3'h2 ? 8'hFF : ram_be; 
wire           cache_wren = (state == 3'h2 ? DDRAM_DOUT_READY : state == 3'h1 ? cache_update : 1'b0) && !DDRAM_BUSY;
wire [ 63:  0] cache_q[9];

ddr_cache_ram cache0 (clk, cache_wraddr, cache_data[0], cache_be, cache_wren & ram_chan == 0, rcache_addr[0][4:3], cache_q[0]);
ddr_cache_ram cache1 (clk, cache_wraddr, cache_data[1], cache_be, cache_wren & ram_chan == 1, rcache_addr[1][4:3], cache_q[1]);
ddr_cache_ram cache2 (clk, cache_wraddr, cache_data[2], cache_be, cache_wren & ram_chan == 2, rcache_addr[2][4:3], cache_q[2]);
ddr_cache_ram cache3 (clk, cache_wraddr, cache_data[3], cache_be, cache_wren & ram_chan == 3, rcache_addr[3][4:3], cache_q[3]);
ddr_cache_ram cache4 (clk, cache_wraddr, cache_data[4], cache_be, cache_wren & ram_chan == 4, rcache_addr[4][4:3], cache_q[4]);
ddr_cache_ram cache5 (clk, cache_wraddr, cache_data[5], cache_be, cache_wren & ram_chan == 5, rcache_addr[5][4:3], cache_q[5]);
ddr_cache_ram cache6 (clk, cache_wraddr, cache_data[6], cache_be, cache_wren & ram_chan == 6, rcache_addr[6][4:3], cache_q[6]);
assign cache_q[7] = '0;
ddr_cache_ram cache8 (clk, cache_wraddr, cache_data[8], cache_be, cache_wren & ram_chan == 8, rcache_addr[8][4:3], cache_q[8]);

always_comb begin
	for (int i=0; i<9; i++) begin
		if (rcache_word[i]) 
			case (rcache_addr[i][2:1])
				2'b00: mem_dout[i] = {16'h0000,cache_q[i][63:48]};
				2'b01: mem_dout[i] = {16'h0000,cache_q[i][47:32]};
				2'b10: mem_dout[i] = {16'h0000,cache_q[i][31:16]};
				2'b11: mem_dout[i] = {16'h0000,cache_q[i][15:00]};
			endcase
		else
			case (rcache_addr[i][2])
				1'b0: mem_dout[i] = cache_q[i][63:32];
				1'b1: mem_dout[i] = cache_q[i][31:00];
			endcase
			
		mem_busy[i] = read_busy[i] | |write_busy[i] | fifo_full[i];
	end
end
assign {mem0_dout,mem1_dout,mem2_dout,mem3_dout,mem4_dout,mem5_dout,mem6_dout,mem7_dout,mem8_dout} = {mem_dout[0],mem_dout[1],mem_dout[2],mem_dout[3],mem_dout[4],mem_dout[5],mem_dout[6],mem_dout[7],mem_dout[8]};
assign {mem0_busy,mem1_busy,mem2_busy,mem3_busy,mem4_busy,mem5_busy,mem6_busy,mem7_busy,mem8_busy} = {mem_busy[0],mem_busy[1],mem_busy[2],mem_busy[3],mem_busy[4],mem_busy[5],mem_busy[6],mem_busy[7],mem_busy[8]};

assign DDRAM_CLK      = clk;
assign DDRAM_BURSTCNT = ram_burst;
assign DDRAM_BE       = ram_be;
assign DDRAM_ADDR     = {6'b001100, ram_address[25:3]}; // RAM at 0x30000000
assign DDRAM_RD       = ram_read;
assign DDRAM_DIN      = ram_din;
assign DDRAM_WE       = ram_write;

endmodule


module ddr_cache_ram (
	clock,
	wraddress,
	data,
	byteena,
	wren,
	rdaddress,
	q);

	input	  clock;
	input	[1:0]  wraddress;
	input	[63:0] data;
	input	 [7:0] byteena;
	input	       wren;
	input	[1:0]  rdaddress;
	output	[63:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri0	  wren;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [63:0] sub_wire0;
	wire [63:0] q = sub_wire0;

	altdpram	altdpram_component (
				.data (data),
				.inclock (clock),
				.rdaddress (rdaddress),
				.wraddress (wraddress),
				.wren (wren),
				.q (sub_wire0),
				.aclr (1'b0),
				.byteena (byteena),
				.inclocken (1'b1),
				.rdaddressstall (1'b0),
				.rden (1'b1),
				//.sclr (1'b0),
				.wraddressstall (1'b0));
	defparam
		altdpram_component.indata_aclr = "OFF",
		altdpram_component.indata_reg = "INCLOCK",
		altdpram_component.intended_device_family = "Cyclone V",
		altdpram_component.lpm_type = "altdpram",
		altdpram_component.outdata_aclr = "OFF",
		altdpram_component.outdata_reg = "UNREGISTERED",
		altdpram_component.power_up_uninitialized = "TRUE",
		altdpram_component.ram_block_type = "MLAB",
		altdpram_component.rdaddress_aclr = "OFF",
		altdpram_component.rdaddress_reg = "UNREGISTERED",
		altdpram_component.rdcontrol_aclr = "OFF",
		altdpram_component.rdcontrol_reg = "UNREGISTERED",
		altdpram_component.read_during_write_mode_mixed_ports = "CONSTRAINED_DONT_CARE",
		altdpram_component.width = 64,
		altdpram_component.widthad = 2,
		altdpram_component.byte_size = 8,
		altdpram_component.width_byteena = 8,
		altdpram_component.wraddress_aclr = "OFF",
		altdpram_component.wraddress_reg = "INCLOCK",
		altdpram_component.wrcontrol_aclr = "OFF",
		altdpram_component.wrcontrol_reg = "INCLOCK";

endmodule

module ddr_infifo 
#(parameter l = 3)
(
	input	         CLK,
	input          RST,
	
	input	 [59: 0] DATA,
	input	         WRREQ,
	
	input	         RDREQ,
	output [59: 0] Q,
	output	      EMPTY,
	output	      FULL
);

	wire [ 59: 0] sub_wire0;
	bit  [l-1: 0] RADDR;
	bit  [l-1: 0] WADDR;
	bit  [  l: 0] AMOUNT;
	
	always @(posedge CLK) begin
		if (RST) begin
			AMOUNT <= '0;
			RADDR <= '0;
			WADDR <= '0;
		end
		else begin
			if (WRREQ && !AMOUNT[l]) begin
				WADDR <= WADDR + 1'd1;
			end
			if (RDREQ && AMOUNT) begin
				RADDR <= RADDR + 1'd1;
			end
			
			if (WRREQ && !RDREQ && !AMOUNT[l]) begin
				AMOUNT <= AMOUNT + 1'd1;
			end else if (!WRREQ && RDREQ && AMOUNT) begin
				AMOUNT <= AMOUNT - 1'd1;
			end
		end
	end
	assign EMPTY = ~|AMOUNT;
	assign FULL = AMOUNT[l];
	
	altdpram	altdpram_component (
				.data (DATA),
				.inclock (CLK),
				.rdaddress (RADDR),
				.wraddress (WADDR),
				.wren (WRREQ),
				.q (sub_wire0),
				.aclr (1'b0),
				.byteena (1'b1),
				.inclocken (1'b1),
				.rdaddressstall (1'b0),
				.rden (1'b1),
//				.sclr (1'b0),
				.wraddressstall (1'b0));
	defparam
		altdpram_component.indata_aclr = "OFF",
		altdpram_component.indata_reg = "INCLOCK",
		altdpram_component.intended_device_family = "Cyclone V",
		altdpram_component.lpm_type = "altdpram",
		altdpram_component.outdata_aclr = "OFF",
		altdpram_component.outdata_reg = "UNREGISTERED",
		altdpram_component.ram_block_type = "MLAB",
		altdpram_component.rdaddress_aclr = "OFF",
		altdpram_component.rdaddress_reg = "UNREGISTERED",
		altdpram_component.rdcontrol_aclr = "OFF",
		altdpram_component.rdcontrol_reg = "UNREGISTERED",
		altdpram_component.read_during_write_mode_mixed_ports = "CONSTRAINED_DONT_CARE",
		altdpram_component.width = 60,
		altdpram_component.widthad = l,
		altdpram_component.width_byteena = 1,
		altdpram_component.wraddress_aclr = "OFF",
		altdpram_component.wraddress_reg = "INCLOCK",
		altdpram_component.wrcontrol_aclr = "OFF",
		altdpram_component.wrcontrol_reg = "INCLOCK";
		
	assign Q = sub_wire0;

endmodule

module ddr_infifo2
(
	input	         CLK,
	input          RST,
	
	input	 [59: 0] DATA,
	input	         WRREQ,
	
	input	         RDREQ,
	output [59: 0] Q,
	output	      EMPTY,
	output	      FULL
);

	bit  [ 59: 0] BUF;
	always @(posedge CLK) begin
		if (RST) begin
			EMPTY <= 1;
			FULL <= 0;
		end
		else begin
			if (WRREQ) begin
				BUF <= DATA;
				EMPTY <= 0;
				FULL <= 1;
			end
			if (RDREQ) begin
				EMPTY <= 1;
				FULL <= 0;
			end
		end
	end
		
	assign Q = BUF;

endmodule

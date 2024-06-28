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
	output         DDRAM_CLK,
	input          DDRAM_BUSY,
	output [ 7: 0] DDRAM_BURSTCNT,
	output [28: 0] DDRAM_ADDR,
	input  [63: 0] DDRAM_DOUT,
	input          DDRAM_DOUT_READY,
	output         DDRAM_RD,
	output [63: 0] DDRAM_DIN,
	output [ 7: 0] DDRAM_BE,
	output         DDRAM_WE,
	
	input          clk,
	input          rst,

	input  [19: 2] ramh_addr,
	output [31: 0] ramh_dout,
	input  [31: 0] ramh_din,
	input          ramh_rd,
	input  [ 3: 0] ramh_wr,
	output         ramh_busy,

	input  [18: 1] cdram_addr,
	output [15: 0] cdram_dout,
	input  [15: 0] cdram_din,
	input          cdram_rd,
	input  [ 1: 0] cdram_wr,
	output         cdram_busy,
	
	input  [21: 1] raml_addr,
	output [15: 0] raml_dout,
	input  [15: 0] raml_din,
	input          raml_rd,
	input  [ 1: 0] raml_wr,
	output         raml_busy,

	input  [18: 1] vdp1vram_addr,
	output [15: 0] vdp1vram_dout,
	input  [15: 0] vdp1vram_din,
	input          vdp1vram_rd,
	input  [ 1: 0] vdp1vram_wr,
	input  [ 8: 0] vdp1vram_blen,
	output         vdp1vram_busy,

	input  [18: 1] vdp1fb_addr,
	output [15: 0] vdp1fb_dout,
	input  [15: 0] vdp1fb_din,
	input          vdp1fb_rd,
	input  [ 1: 0] vdp1fb_wr,
	output         vdp1fb_busy,

	input  [13: 1] cdbuf_addr,
	output [15: 0] cdbuf_dout,
	input          cdbuf_rd,
	output         cdbuf_busy,

	input  [21: 1] cart_addr,
	output [15: 0] cart_dout,
	input  [15: 0] cart_din,
	input          cart_rd,
	input  [ 1: 0] cart_wr,
	output         cart_busy,

	input  [25: 1] bios_addr,
	input  [15: 0] bios_din,
	input  [ 1: 0] bios_wr,
	output         bios_busy,

	input  [15: 1] bsram_addr,
	output [15: 0] bsram_dout,
	input  [15: 0] bsram_din,
	input          bsram_rd,
	input  [ 1: 0] bsram_wr,
	output         bsram_busy
);

reg  [ 25:  1] ram_address;
reg  [ 63:  0] ram_din;
reg  [  7:  0] ram_be;
reg  [  7:  0] ram_burst;
reg            ram_read = 0;
reg            ram_write = 0;
reg  [  3:  0] ram_chan;

reg  [ 19:  2] ramh_rcache_addr;
reg            ramh_rcache_dirty = 1;
reg            ramh_read_busy;

reg  [ 18:  1] cdram_rcache_addr,cdram_write_addr;
reg            cdram_rcache_dirty = 1;
reg  [ 15:  0] cdram_write_data;
reg  [  1:  0] cdram_be;
reg            cdram_read_busy,cdram_write_busy;

reg  [ 21:  1] raml_rcache_addr,raml_write_addr;
reg            raml_rcache_dirty = 1;
reg  [ 15:  0] raml_write_data;
reg  [  1:  0] raml_be;
reg            raml_read_busy,raml_write_busy;

reg  [ 18:  1] vdp1vram_rcache_addr,vdp1vram_rcache_addr_end;
reg  [  9:  1] vdp1vram_rcache_addr_lsb;
reg  [  8:  0] vdp1vram_rcache_blen;
reg            vdp1vram_rcache_dirty = 1;
reg            vdp1vram_read_busy;

reg  [ 18:  1] vdp1fb_rcache_addr;
reg            vdp1fb_rcache_dirty = 1;
reg            vdp1fb_read_busy;

reg  [ 13:  1] cdbuf_rcache_addr;
reg            cdbuf_read_busy;

reg  [ 21:  1] cart_rcache_addr,cart_write_addr;
reg            cart_rcache_dirty = 1;
reg  [ 15:  0] cart_write_data;
reg  [  1:  0] cart_be;
reg            cart_read_busy,cart_write_busy;

reg  [ 25:  1] bios_write_addr;
reg  [ 15:  0] bios_write_data;
reg  [  1:  0] bios_be;
reg            bios_write_busy;

reg  [ 15:  1] bsram_rcache_addr,bsram_write_addr;
reg            bsram_rcache_dirty = 1;
reg  [ 15:  0] bsram_write_data;
reg  [  1:  0] bsram_be;
reg            bsram_read_busy,bsram_write_busy;

reg  [  2:  0] state = 0;

reg  [  6:  0] cache_wraddr;
reg            cache_update;

reg            old_rst;
reg            ramh_rd_old,ramh_wr_old;
reg            cdram_rd_old,cdram_wr_old;
reg            raml_rd_old,raml_wr_old;
reg            vdp1vram_rd_old,vdp1vram_wr_old;
reg            vdp1fb_rd_old,vdp1fb_wr_old;
reg            cdbuf_rd_old;
reg            cart_rd_old,cart_wr_old;
reg            bios_wr_old;
reg            bsram_rd_old,bsram_wr_old;
always @(posedge clk) begin
	{ramh_rd_old,ramh_wr_old} <= {ramh_rd,|ramh_wr};
	{cdram_rd_old,cdram_wr_old} <= {cdram_rd,|cdram_wr};
	{raml_rd_old,raml_wr_old} <= {raml_rd,|raml_wr};
	{vdp1vram_rd_old,vdp1vram_wr_old} <= {vdp1vram_rd,|vdp1vram_wr};
	{vdp1fb_rd_old,vdp1fb_wr_old} <= {vdp1fb_rd,|vdp1fb_wr};
	cdbuf_rd_old <= cdbuf_rd;
	{cart_rd_old,cart_wr_old} <= {cart_rd,|cart_wr};
	bios_wr_old <= |bios_wr;
	{bsram_rd_old,bsram_wr_old} <= {bsram_rd,|bsram_wr};
	old_rst <= rst;
end
wire           rst_pulse = (rst && !old_rst);

wire           ramh_fifo_wrreq,ramh_fifo_rdreq;
wire           vdp1vram_fifo_wrreq,vdp1vram_fifo_rdreq;
wire           vdp1fb_fifo_wrreq,vdp1fb_fifo_rdreq;
always_comb begin
	ramh_fifo_wrreq = (|ramh_wr && !ramh_wr_old);
	ramh_fifo_rdreq = (state == 3'h1 && !DDRAM_BUSY && ram_chan == 4'd0);
	vdp1vram_fifo_wrreq = (|vdp1vram_wr && !vdp1vram_wr_old);
	vdp1vram_fifo_rdreq = (state == 3'h1 && !DDRAM_BUSY && ram_chan == 4'd3);
	vdp1fb_fifo_wrreq = (|vdp1fb_wr && !vdp1fb_wr_old);
	vdp1fb_fifo_rdreq = (state == 3'h1 && !DDRAM_BUSY && ram_chan == 4'd4);
end

wire [ 53:  0] ramh_fifo_dout;
wire           ramh_fifo_empty,ramh_fifo_full;
wire [ 53:  0] vdp1vram_fifo_dout;
wire           vdp1vram_fifo_empty,vdp1vram_fifo_full;
wire [ 53:  0] vdp1fb_fifo_dout;
wire           vdp1fb_fifo_empty,vdp1fb_fifo_full;

ddr_infifo #(3) ramh_fifo (clk, rst_pulse, {ramh_addr,ramh_wr,ramh_din}, ramh_fifo_wrreq, ramh_fifo_rdreq, ramh_fifo_dout, ramh_fifo_empty, ramh_fifo_full);
ddr_infifo #(3) vdp1vram_fifo (clk, rst_pulse, {vdp1vram_addr,2'b00,vdp1vram_wr,16'h0000,vdp1vram_din}, vdp1vram_fifo_wrreq, vdp1vram_fifo_rdreq, vdp1vram_fifo_dout, vdp1vram_fifo_empty, vdp1vram_fifo_full);
ddr_infifo #(2) vdp1fb_fifo (clk, rst_pulse, {vdp1fb_addr,2'b00,vdp1fb_wr,16'h0000,vdp1fb_din}, vdp1fb_fifo_wrreq, vdp1fb_fifo_rdreq, vdp1fb_fifo_dout, vdp1fb_fifo_empty, vdp1fb_fifo_full);

wire [ 19:  2] ramh_write_addr;
wire [ 31:  0] ramh_write_data;
wire [  3:  0] ramh_write_be;
wire [ 18:  1] vdp1vram_write_addr;
wire [ 15:  0] vdp1vram_write_data;
wire [  1:  0] vdp1vram_write_be;
wire [ 18:  1] vdp1fb_write_addr;
wire [ 15:  0] vdp1fb_write_data;
wire [  1:  0] vdp1fb_write_be;

assign {ramh_write_addr,ramh_write_be,ramh_write_data} = ramh_fifo_dout;
assign {vdp1vram_write_addr,vdp1vram_write_be,vdp1vram_write_data} = {vdp1vram_fifo_dout[53:36],vdp1vram_fifo_dout[33:32],vdp1vram_fifo_dout[15:0]};
assign {vdp1fb_write_addr,vdp1fb_write_be,vdp1fb_write_data} = {vdp1fb_fifo_dout[53:36],vdp1fb_fifo_dout[33:32],vdp1fb_fifo_dout[15:0]};


always @(posedge clk) begin
	bit write,read,burst_read;
	bit [3:0] chan;
	bit [6:0] word_cnt;

	if (rst_pulse) begin		
		{cdram_rcache_dirty,raml_rcache_dirty,ramh_rcache_dirty,vdp1vram_rcache_dirty,vdp1fb_rcache_dirty,cart_rcache_dirty} <= '1;
		{cdram_read_busy,raml_read_busy,ramh_read_busy,vdp1vram_read_busy,vdp1fb_read_busy,cdbuf_read_busy,cart_read_busy} <= '0;
		vdp1vram_rcache_blen <= '0;
	end
	else begin
		if (ramh_rd && !ramh_rd_old) begin
			if (ramh_addr[19:5] != ramh_rcache_addr[19:5] || ramh_rcache_dirty) begin
				ramh_read_busy <= 1;
			end
			ramh_rcache_addr <= ramh_addr;
			ramh_rcache_dirty <= 0;
		end
		if (cdram_rd && !cdram_rd_old) begin
			if (cdram_addr[18:4] != cdram_rcache_addr[18:4] || cdram_rcache_dirty) begin
				cdram_read_busy <= 1;
			end
			cdram_rcache_addr <= cdram_addr;
			cdram_rcache_dirty <= 0;
		end
		if (raml_rd && !raml_rd_old) begin
			if (raml_addr[21:5] != raml_rcache_addr[21:5] || raml_rcache_dirty) begin
				raml_read_busy <= 1;
			end
			raml_rcache_addr <= raml_addr;
			raml_rcache_dirty <= 0;
		end
		if (vdp1vram_rd && !vdp1vram_rd_old) begin
			if (vdp1vram_blen) begin
				if (vdp1vram_addr != vdp1vram_rcache_addr || vdp1vram_rcache_dirty) begin
					vdp1vram_read_busy <= 1;
					vdp1vram_rcache_addr <= vdp1vram_addr;
					vdp1vram_rcache_addr_end <= vdp1vram_addr + vdp1vram_blen - 18'd1;
					vdp1vram_rcache_blen <= vdp1vram_blen;
				end
			end else if (vdp1vram_rcache_blen) begin
				if (vdp1vram_addr < vdp1vram_rcache_addr || vdp1vram_addr > vdp1vram_rcache_addr_end || vdp1vram_rcache_dirty) begin
					vdp1vram_read_busy <= 1;
					vdp1vram_rcache_addr <= vdp1vram_addr;
					vdp1vram_rcache_blen <= '0;
				end
			end else begin
				if (vdp1vram_addr[18:5] != vdp1vram_rcache_addr[18:5] || vdp1vram_rcache_dirty) begin
					vdp1vram_read_busy <= 1;
					vdp1vram_rcache_addr <= vdp1vram_addr;
				end
			end
			vdp1vram_rcache_addr_lsb <= vdp1vram_addr[9:1];
			vdp1vram_rcache_dirty <= 0;
		end
		if (vdp1fb_rd && !vdp1fb_rd_old) begin
			if (vdp1fb_addr[18:5] != vdp1fb_rcache_addr[18:5] || vdp1fb_rcache_dirty) begin
				vdp1fb_read_busy <= 1;
			end
			vdp1fb_rcache_addr <= vdp1fb_addr;
			vdp1fb_rcache_dirty <= 0;
		end
		if (cdbuf_rd && !cdbuf_rd_old) begin
			if (cdbuf_addr[13:4] != cdbuf_rcache_addr[13:4]) begin
				cdbuf_read_busy <= 1;
			end
			cdbuf_rcache_addr <= cdbuf_addr;
		end
		if (cart_rd && !cart_rd_old) begin
			if (cart_addr[21:5] != cart_rcache_addr[21:5] || cart_rcache_dirty) begin
				cart_read_busy <= 1;
			end
			cart_rcache_addr <= cart_addr;
			cart_rcache_dirty <= 0;
		end
		if (bsram_rd && !bsram_rd_old) begin
			if (bsram_addr[15:4] != bsram_rcache_addr[15:4] || bsram_rcache_dirty) begin
				bsram_read_busy <= 1;
			end
			bsram_rcache_addr <= bsram_addr;
			bsram_rcache_dirty <= 0;
		end
	end
		
	if (rst_pulse) begin
		{cdram_write_busy,raml_write_busy,cart_write_busy,bios_write_busy,bsram_write_busy} <= 0;		
	end
	else begin
		if (|ramh_wr && !ramh_wr_old) begin
			if (ramh_addr[19:5] == ramh_rcache_addr[19:5]) begin
				ramh_rcache_dirty <= 1;
			end	
		end
		if (|cdram_wr && !cdram_wr_old) begin
			if (cdram_addr[18:4] == cdram_rcache_addr[18:4]) begin
				cdram_rcache_dirty <= 1;
			end
			cdram_write_addr <= cdram_addr;
			cdram_write_data <= cdram_din;
			cdram_be <= cdram_wr;
			cdram_write_busy <= 1;	
		end
		if (|raml_wr && !raml_wr_old) begin
			if (raml_addr[21:5] == raml_rcache_addr[21:5]) begin
				raml_rcache_dirty <= 1;
			end
			raml_write_addr <= raml_addr;
			raml_write_data <= raml_din;
			raml_be <= raml_wr;
			raml_write_busy <= 1;	
		end
		if (|vdp1vram_wr && !vdp1vram_wr_old) begin
//			if (vdp1vram_addr[18:5] == vdp1vram_rcache_addr[18:5]) begin
//				vdp1vram_rcache_dirty <= 1;
//			end
			if (!vdp1vram_rcache_blen) begin
				if (vdp1vram_rcache_addr[18:5] == vdp1vram_addr[18:5]) begin
					vdp1vram_rcache_dirty <= 1;
				end
			end else begin
				if (vdp1vram_addr >= vdp1vram_rcache_addr && vdp1vram_addr <= (vdp1vram_rcache_addr + vdp1vram_rcache_blen - 1)) begin
					vdp1vram_rcache_dirty <= 1;
				end
			end
		end
		if (|vdp1fb_wr && !vdp1fb_wr_old) begin
			if (vdp1fb_addr[18:5] == vdp1fb_rcache_addr[18:5]) begin
				vdp1fb_rcache_dirty <= 1;
			end	
		end
		if (|cart_wr && !cart_wr_old) begin
			if (cart_addr[21:5] == cart_rcache_addr[21:5]) begin
				cart_rcache_dirty <= 1;
			end
			cart_write_addr <= cart_addr;
			cart_write_data <= cart_din;
			cart_be <= cart_wr;
			cart_write_busy <= 1;	
		end
		if (|bios_wr && !bios_wr_old) begin
			bios_write_addr <= bios_addr;
			bios_write_data <= bios_din;
			bios_be <= bios_wr;
			bios_write_busy <= 1;	
		end
		if (|bsram_wr && !bsram_wr_old) begin
			if (bsram_addr[15:4] == bsram_rcache_addr[15:4]) begin
				bsram_rcache_dirty <= 1;
			end
			bsram_write_addr <= bsram_addr;
			bsram_write_data <= bsram_din;
			bsram_be <= bsram_wr;
			bsram_write_busy <= 1;	
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
				if (!ramh_fifo_empty) begin
					ram_address <= {6'b000011,ramh_write_addr[19:3],2'b00};
					ram_din		<= {2{ramh_write_data}};
					case (ramh_write_addr[2])
						1'b0: ram_be <= {ramh_write_be,4'b0000};
						1'b1: ram_be <= {4'b0000,ramh_write_be};
					endcase
					ram_write 	<= 1;
					ram_burst   <= 1;
					ram_chan    <= 4'd0;
					state       <= 3'h1;
				end
				else if (ramh_read_busy) begin
					ram_address <= {6'b000011,ramh_rcache_addr[19:5],4'b0000};
					ram_be      <= 8'hFF;
					ram_read    <= 1;
					ram_burst   <= 4;
					ram_chan    <= 4'd0;
					cache_wraddr<= {ramh_rcache_addr[9:5],2'b00};
					word_cnt    <= '0;
					state       <= 3'h2;
				end
				else if (cdram_write_busy) begin
					cdram_write_busy <= 0;
					ram_address <= {7'b0010000,cdram_write_addr[18:3],2'b00};
					ram_din		<= {4{cdram_write_data}};
					case (cdram_write_addr[2:1])
						2'b00: ram_be <= {cdram_be,6'b000000};
						2'b01: ram_be <= {2'b00,cdram_be,4'b0000};
						2'b10: ram_be <= {4'b0000,cdram_be,2'b00};
						2'b11: ram_be <= {6'b000000,cdram_be};
					endcase
					ram_write 	<= 1;
					ram_burst   <= 1;
					ram_chan    <= 4'd1;
					state       <= 3'h1;
				end
				else if (cdram_read_busy) begin
					ram_address <= {7'b0010000,cdram_rcache_addr[18:4],3'b000};
					ram_be      <= 8'hFF;
					ram_read    <= 1;
					ram_burst   <= 2;
					ram_chan    <= 4'd1;
					cache_wraddr<= {cdram_rcache_addr[9:4],1'b0};
					word_cnt    <= '0;
					state       <= 3'h2;
				end
				else if (raml_write_busy) begin
					raml_write_busy <= 0;
					ram_address <= {4'b0000,raml_write_addr[21:3],2'b00};
					ram_din		<= {4{raml_write_data}};
					case (raml_write_addr[2:1])
						2'b00: ram_be <= {raml_be,6'b000000};
						2'b01: ram_be <= {2'b00,raml_be,4'b0000};
						2'b10: ram_be <= {4'b0000,raml_be,2'b00};
						2'b11: ram_be <= {6'b000000,raml_be};
					endcase
					ram_write 	<= 1;
					ram_burst   <= 1;
					ram_chan    <= 4'd2;
					state       <= 3'h1;
				end
				else if (raml_read_busy) begin
					ram_address <= {4'b0000,raml_rcache_addr[21:5],4'b0000};
					ram_be      <= 8'hFF;
					ram_read    <= 1;
					ram_burst   <= 4;
					ram_chan    <= 4'd2;
					cache_wraddr<= {raml_rcache_addr[9:5],2'b00};
					word_cnt    <= '0;
					state       <= 3'h2;
				end
				else if (!vdp1vram_fifo_empty) begin
					ram_address <= {7'b0001000,vdp1vram_write_addr[18:3],2'b00};
					ram_din		<= {4{vdp1vram_write_data}};
					case (vdp1vram_write_addr[2:1])
						2'b00: ram_be <= {vdp1vram_write_be,6'b000000};
						2'b01: ram_be <= {2'b00,vdp1vram_write_be,4'b0000};
						2'b10: ram_be <= {4'b0000,vdp1vram_write_be,2'b00};
						2'b11: ram_be <= {6'b000000,vdp1vram_write_be};
					endcase
					ram_write 	<= 1;
					ram_burst   <= 1;
					ram_chan    <= 4'd3;
					state       <= 3'h1;
				end
				else if (vdp1vram_read_busy) begin
					ram_address <= vdp1vram_rcache_blen ? {7'b0001000,vdp1vram_rcache_addr[18:3],2'b00} : {7'b0001000,vdp1vram_rcache_addr[18:5],4'b0000};
					ram_be      <= 8'hFF;
					ram_read    <= 1;
					ram_burst   <= vdp1vram_rcache_blen ? {1'b0,vdp1vram_rcache_blen[8:2]} + {7'b0000000,|vdp1vram_rcache_blen[1:0]} : 8'd4;
					ram_chan    <= 4'd3;
					cache_wraddr<= vdp1vram_rcache_blen ? {vdp1vram_rcache_addr[9:3]} : {vdp1vram_rcache_addr[9:5],2'b00};
					word_cnt    <= '0;
					state       <= 3'h2;
				end
				else if (!vdp1fb_fifo_empty) begin
					ram_address <= {7'b0001001,vdp1fb_write_addr[18:3],2'b00};
					ram_din		<= {4{vdp1fb_write_data}};
					case (vdp1fb_write_addr[2:1])
						2'b00: ram_be <= {vdp1fb_write_be,6'b000000};
						2'b01: ram_be <= {2'b00,vdp1fb_write_be,4'b0000};
						2'b10: ram_be <= {4'b0000,vdp1fb_write_be,2'b00};
						2'b11: ram_be <= {6'b000000,vdp1fb_write_be};
					endcase
					ram_write 	<= 1;
					ram_burst   <= 1;
					ram_chan    <= 4'd4;
					state       <= 3'h1;
				end
				else if (vdp1fb_read_busy) begin
					ram_address <= {7'b0001001,vdp1fb_rcache_addr[18:5],4'b0000};
					ram_be      <= 8'hFF;
					ram_read    <= 1;
					ram_burst   <= 4;
					ram_chan    <= 4'd4;
					cache_wraddr<= {vdp1fb_rcache_addr[9:5],2'b00};
					word_cnt    <= '0;
					state       <= 3'h2;
				end
				else if (cdbuf_read_busy) begin
					ram_address <= {12'b010000000000,cdbuf_rcache_addr[13:4],3'b000};
					ram_be      <= 8'hFF;
					ram_read    <= 1;
					ram_burst   <= 2;
					ram_chan    <= 4'd5;
					cache_wraddr<= {cdbuf_rcache_addr[9:4],1'b0};
					word_cnt    <= '0;
					state       <= 3'h2;
				end
				else if (cart_write_busy) begin
					cart_write_busy <= 0;
					ram_address <= {4'b0011,cart_write_addr[21:3],2'b00};
					ram_din		<= {4{cart_write_data}};
					case (cart_write_addr[2:1])
						2'b00: ram_be <= {cart_be,6'b000000};
						2'b01: ram_be <= {2'b00,cart_be,4'b0000};
						2'b10: ram_be <= {4'b0000,cart_be,2'b00};
						2'b11: ram_be <= {6'b000000,cart_be};
					endcase
					ram_write 	<= 1;
					ram_burst   <= 1;
					ram_chan    <= 4'd6;
					state       <= 3'h1;
				end
				else if (cart_read_busy) begin
					ram_address <= {4'b0011,cart_rcache_addr[21:5],4'b0000};
					ram_be      <= 8'hFF;
					ram_read    <= 1;
					ram_burst   <= 4;
					ram_chan    <= 4'd6;
					cache_wraddr<= {cart_rcache_addr[9:5],2'b00};
					word_cnt    <= '0;
					state       <= 3'h2;
				end
				else if (bios_write_busy) begin
					bios_write_busy <= 0;
					ram_address <= {bios_write_addr[25:3],2'b00};
					ram_din		<= {4{bios_write_data}};
					case (bios_write_addr[2:1])
						2'b00: ram_be <= {bios_be,6'b000000};
						2'b01: ram_be <= {2'b00,bios_be,4'b0000};
						2'b10: ram_be <= {4'b0000,bios_be,2'b00};
						2'b11: ram_be <= {6'b000000,bios_be};
					endcase
					ram_write 	<= 1;
					ram_burst   <= 1;
					ram_chan    <= 4'd7;
					state       <= 3'h1;
				end
				else if (bsram_write_busy) begin
					bsram_write_busy <= 0;
					ram_address <= {10'b0000010000,bsram_write_addr[15:3],2'b00};
					ram_din		<= {4{bsram_write_data}};
					case (bsram_write_addr[2:1])
						2'b00: ram_be <= {bsram_be,6'b000000};
						2'b01: ram_be <= {2'b00,bsram_be,4'b0000};
						2'b10: ram_be <= {4'b0000,bsram_be,2'b00};
						2'b11: ram_be <= {6'b000000,bsram_be};
					endcase
					ram_write 	<= 1;
					ram_burst   <= 1;
					ram_chan    <= 4'd8;
					state       <= 3'h1;
				end
				else if (bsram_read_busy) begin
					ram_address <= {10'b0000010000,bsram_rcache_addr[15:4],3'b000};
					ram_be      <= 8'hFF;
					ram_read    <= 1;
					ram_burst   <= 2;
					ram_chan    <= 4'd8;
					cache_wraddr<= {bsram_rcache_addr[9:4],1'b0};
					word_cnt    <= '0;
					state       <= 3'h2;
				end
			end

			3'h1: begin
				state <= 0;
			end
		
			3'h2: if (DDRAM_DOUT_READY) begin
				cache_wraddr <= cache_wraddr + 7'd1;
				word_cnt <= word_cnt + 7'd1;
				if (word_cnt == ram_burst[6:0] - 7'd1) begin
					if (ram_chan == 4'd0) ramh_read_busy <= 0;
					if (ram_chan == 4'd1) cdram_read_busy <= 0;
					if (ram_chan == 4'd2) raml_read_busy <= 0;
					if (ram_chan == 4'd3) vdp1vram_read_busy <= 0;
					if (ram_chan == 4'd4) vdp1fb_read_busy <= 0;
					if (ram_chan == 4'd5) cdbuf_read_busy <= 0;
					if (ram_chan == 4'd6) cart_read_busy <= 0;
					if (ram_chan == 4'd8) bsram_read_busy <= 0;
					state <= 0;
				end
			end
		endcase
	end
end


wire           cache_wren = (state == 3'h2) && DDRAM_DOUT_READY && !DDRAM_BUSY;
wire [ 63:  0] ramh_cache_q,cdram_cache_q,raml_cache_q,vdp1vram_cache_q,vdp1fb_cache_q,cdbuf_cache_q,cart_cache_q,bsram_cache_q;

ddr_cache_ram #(2) cache0 (clk, cache_wraddr[1:0], DDRAM_DOUT, cache_wren & ram_chan == 0, ramh_rcache_addr[4:3], ramh_cache_q);
ddr_cache_ram #(1) cache1 (clk, cache_wraddr[0:0], DDRAM_DOUT, cache_wren & ram_chan == 1, cdram_rcache_addr[3:3], cdram_cache_q);
ddr_cache_ram #(2) cache2 (clk, cache_wraddr[1:0], DDRAM_DOUT, cache_wren & ram_chan == 2, raml_rcache_addr[4:3], raml_cache_q);
ddr_cache_ram #(7) cache3 (clk, cache_wraddr[6:0], DDRAM_DOUT, cache_wren & ram_chan == 3, vdp1vram_rcache_addr_lsb[9:3], vdp1vram_cache_q);
ddr_cache_ram #(2) cache4 (clk, cache_wraddr[1:0], DDRAM_DOUT, cache_wren & ram_chan == 4, vdp1fb_rcache_addr[4:3], vdp1fb_cache_q);
ddr_cache_ram #(1) cache5 (clk, cache_wraddr[0:0], DDRAM_DOUT, cache_wren & ram_chan == 5, cdbuf_rcache_addr[3:3], cdbuf_cache_q);
ddr_cache_ram #(2) cache6 (clk, cache_wraddr[1:0], DDRAM_DOUT, cache_wren & ram_chan == 6, cart_rcache_addr[4:3], cart_cache_q);
ddr_cache_ram #(1) cache8 (clk, cache_wraddr[0:0], DDRAM_DOUT, cache_wren & ram_chan == 8, bsram_rcache_addr[3:3], bsram_cache_q);

always_comb begin
	case (ramh_rcache_addr[2])
		1'b0: ramh_dout = ramh_cache_q[63:32];
		1'b1: ramh_dout = ramh_cache_q[31:00];
	endcase
	ramh_busy = ramh_fifo_full | ramh_read_busy;
	
	case (cdram_rcache_addr[2:1])
		2'b00: cdram_dout = cdram_cache_q[63:48];
		2'b01: cdram_dout = cdram_cache_q[47:32];
		2'b10: cdram_dout = cdram_cache_q[31:16];
		2'b11: cdram_dout = cdram_cache_q[15:00];
	endcase
	cdram_busy = cdram_write_busy | cdram_read_busy;
	
	case (raml_rcache_addr[2:1])
		2'b00: raml_dout = raml_cache_q[63:48];
		2'b01: raml_dout = raml_cache_q[47:32];
		2'b10: raml_dout = raml_cache_q[31:16];
		2'b11: raml_dout = raml_cache_q[15:00];
	endcase
	raml_busy = raml_write_busy | raml_read_busy;
	
	case (vdp1vram_rcache_addr_lsb[2:1])
		2'b00: vdp1vram_dout = vdp1vram_cache_q[63:48];
		2'b01: vdp1vram_dout = vdp1vram_cache_q[47:32];
		2'b10: vdp1vram_dout = vdp1vram_cache_q[31:16];
		2'b11: vdp1vram_dout = vdp1vram_cache_q[15:00];
	endcase
	vdp1vram_busy = vdp1vram_fifo_full | vdp1vram_read_busy;
	
	case (vdp1fb_rcache_addr[2:1])
		2'b00: vdp1fb_dout = vdp1fb_cache_q[63:48];
		2'b01: vdp1fb_dout = vdp1fb_cache_q[47:32];
		2'b10: vdp1fb_dout = vdp1fb_cache_q[31:16];
		2'b11: vdp1fb_dout = vdp1fb_cache_q[15:00];
	endcase
	vdp1fb_busy = vdp1fb_fifo_full | vdp1fb_read_busy;
	
	case (cdbuf_rcache_addr[2:1])
		2'b00: cdbuf_dout = cdbuf_cache_q[63:48];
		2'b01: cdbuf_dout = cdbuf_cache_q[47:32];
		2'b10: cdbuf_dout = cdbuf_cache_q[31:16];
		2'b11: cdbuf_dout = cdbuf_cache_q[15:00];
	endcase
	cdbuf_busy = cdbuf_read_busy;
	
	case (cart_rcache_addr[2:1])
		2'b00: cart_dout = cart_cache_q[63:48];
		2'b01: cart_dout = cart_cache_q[47:32];
		2'b10: cart_dout = cart_cache_q[31:16];
		2'b11: cart_dout = cart_cache_q[15:00];
	endcase
	cart_busy = cart_write_busy | cart_read_busy;
	
	bios_busy = bios_write_busy;
	
	case (bsram_rcache_addr[2:1])
		2'b00: bsram_dout = bsram_cache_q[63:48];
		2'b01: bsram_dout = bsram_cache_q[47:32];
		2'b10: bsram_dout = bsram_cache_q[31:16];
		2'b11: bsram_dout = bsram_cache_q[15:00];
	endcase
	bsram_busy = bsram_write_busy | bsram_read_busy;
end

assign DDRAM_CLK      = clk;
assign DDRAM_BURSTCNT = ram_burst;
assign DDRAM_BE       = ram_be;
assign DDRAM_ADDR     = {6'b001100, ram_address[25:3]}; // RAM at 0x30000000
assign DDRAM_RD       = ram_read;
assign DDRAM_DIN      = ram_din;
assign DDRAM_WE       = ram_write;

endmodule


module ddr_cache_ram #(parameter wa = 2) (
	clock,
	wraddress,
	data,
	wren,
	rdaddress,
	q);

	input	  clock;
	input	[wa-1:0]  wraddress;
	input	[63:0] data;
	input	       wren;
	input	[wa-1:0]  rdaddress;
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
				.byteena (1'b1),
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
		altdpram_component.widthad = wa,
		altdpram_component.width_byteena = 1,
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
	
	input	 [53: 0] DATA,
	input	         WRREQ,
	
	input	         RDREQ,
	output [53: 0] Q,
	output	      EMPTY,
	output	      FULL
);

	wire [ 53: 0] sub_wire0;
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
		altdpram_component.width = 54,
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

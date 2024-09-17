`timescale 1ns / 100ps

/*
 * PS2 mouse protocol
 * Bit       7    6    5    4    3    2    1    0  
 * Byte 0: YOVR XOVR YSGN XSGN   1   MBUT RBUT LBUT
 * Byte 1:                 XMOVE
 * Byte 2:                 YMOVE
 */

module ps2_mouse
(
	input	clk,
	input	ce,

	input	reset,
	input	reset_acc,

	input [24:0] ps2_mouse,
	input [15:0] ps2_mouse_ext,

	output reg [3:0] flags,
	output reg [3:0] buttons,
	output reg [7:0] x,
	output reg [7:0] y
);


reg [10:0] curdx;
reg [10:0] curdy;
wire [10:0] newdx = curdx + {{3{ps2_mouse[4]}},ps2_mouse[15:8]};
wire [10:0] newdy = curdy + {{3{ps2_mouse[5]}},ps2_mouse[23:16]};
wire  [7:0] dx = curdx[7:0];
wire  [7:0] dy = curdy[7:0];

/* flags bits */
wire x_ov_p = ($signed(newdx) > $signed( 10'd255));
wire x_ov_n = ($signed(newdx) < $signed(-10'd256));
wire x_ov = x_ov_p | x_ov_n;
wire y_ov_p = ($signed(newdy) > $signed( 10'd255));
wire y_ov_n = ($signed(newdy) < $signed(-10'd256));
wire y_ov = y_ov_p | y_ov_n;
wire sdx = newdx[10];
wire sdy = newdy[10];

wire strobe = (old_stb != ps2_mouse[24]);
reg  old_stb = 0;
always @(posedge clk) old_stb <= ps2_mouse[24];

/* Capture flags state */
always@(posedge clk or posedge reset or posedge reset_acc) begin
	if (reset || reset_acc) flags[3:0] <= 4'b0;
	else if (strobe) begin
		flags <= {y_ov,x_ov,sdy,sdx};
	end
end

/* Clip x accumulator */
always@(posedge clk or posedge reset or posedge reset_acc) begin
	if (reset || reset_acc) curdx <= 0;
	else if (strobe) begin
		if(x_ov_p) curdx <= 10'd255;
		else if(x_ov_n) curdx <= -10'd256;
		else curdx <= newdx;
	end
end

/* Clip y accumulator */
always@(posedge clk or posedge reset or posedge reset_acc) begin
	if (reset || reset_acc) curdy <= 0;
	else if (strobe) begin
		if(y_ov_p) curdy <= 10'd255;
		else if(y_ov_n) curdy <= -10'd256;
		else curdy <= newdy;
	end
end

/* Capture button state */
always@(posedge clk or posedge reset)
	if (reset) buttons[3:0] <= 4'b0;
	else if (strobe) buttons[3:0] <= {|ps2_mouse_ext[15:8],ps2_mouse[2:0]};

always@(posedge clk or posedge reset) begin
	if (reset) x <= 0;
	else x <= dx;
end

always@(posedge clk or posedge reset) begin
	if (reset) y <= 0;
	else y <= dy;
end

endmodule

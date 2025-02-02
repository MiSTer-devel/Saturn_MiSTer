//============================================================================
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off 

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,
	output        HDMI_BLACKOUT,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
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

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

	assign ADC_BUS  = 'Z;
	assign {UART_RTS, UART_TXD, UART_DTR} = 0;
	assign BUTTONS   = {1'b0,osd_btn};
	assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;

	assign AUDIO_S = 1;
	assign AUDIO_MIX = 0;
	assign HDMI_FREEZE = 0;
	assign VGA_DISABLE = 0;
	
	assign LED_DISK  = 0;
	assign LED_POWER = 0;
	assign LED_USER  = bios_download;
	assign VGA_SCALER= 0;
	assign HDMI_BLACKOUT = 1;
	
	wire [1:0] ar = status[63:62];
	wire [7:0] arx,ary;

	
	always_comb begin
		if (status[10]) begin
			arx = 8'd0;
			ary = 8'd0;
		end else begin
			casez(res)
				4'b00?0: begin // 320 x 224
					arx = status[11] ? 8'd10: 8'd64;
					ary = status[11] ? 8'd7 : 8'd49;
				end
	
				4'b00?1: begin // 352 x 224
					arx = status[11] ? 8'd22: 8'd64;
					ary = status[11] ? 8'd14: 8'd49;
				end
	
				4'b01?0: begin // 320 x 240
					arx = status[11] ? 8'd4 : 8'd128;
					ary = status[11] ? 8'd3 : 8'd105;
				end
	
				4'b01?1: begin // 352 x 240
					arx = status[11] ? 8'd22: 8'd128;
					ary = status[11] ? 8'd15: 8'd105;
				end
	
				4'b10?0: begin // 320 x 256
					arx = status[11] ? 8'd5 : 8'd64;
					ary = status[11] ? 8'd4 : 8'd49;
				end
	
				4'b10?1: begin // 352 x 256
					arx = status[11] ? 8'd11: 8'd128;
					ary = status[11] ? 8'd8 : 8'd105;
				end
	
				default: begin // not supported
					arx = status[11] ? 8'd10: 8'd64;
					ary = status[11] ? 8'd7 : 8'd49;
				end
			endcase
		end
	end
	
	wire       vcrop_en = status[61];
	wire [3:0] vcopt    = status[54:51];
	reg        en216p;
	reg  [4:0] voff;
	always @(posedge CLK_VIDEO) begin
			en216p <= ((HDMI_WIDTH == 1920) && (HDMI_HEIGHT == 1080) && !forced_scandoubler && !scale);
			voff <= (vcopt < 6) ? {vcopt,1'b0} : ({vcopt,1'b0} - 5'd24);
	end

	wire vga_de;
	video_freak video_freak
	(
		.*,
		.VGA_DE_IN(vga_de),
		.ARX((!ar) ? arx : (ar - 1'd1)),
		.ARY((!ar) ? ary : 12'd0),
		.CROP_SIZE((en216p & vcrop_en) ? 10'd216 : 10'd0),
		.CROP_OFF(voff),
		.SCALE(status[56:55])
	);


	///////////////////////////////////////////////////
	
	// Status Bit Map:
	//             Upper                             Lower              
	// 0         1         2         3          4         5         6   
	// 01234567890123456789012345678901 23456789012345678901234567890123
	// 0123456789ABCDEFGHIJKLMNOPQRSTUV 0123456789ABCDEFGHIJKLMNOPQRSTUV
	// XXXX XXXXXXXXXXXXXXXXXXXXXXXXX     XXXXXXXXXXXXX    X  XXX    XXX
	
	`include "build_id.v"
	localparam CONF_STR = {
		"Saturn;;",
		"S0,CUECHD,Insert Disc;",
		"FS2,BIN,Load bios;",
		"FS3,BIN,Load cartridge;",
		"-;",
		"O[23:21],Cartridge,None,ROM 2M,DRAM 1M,DRAM 4M,BACKUP,STV;",
		"O[35:33],Region,Japan,Taiwan,USA,Brazil,Korea,Asia,Europe,Auto;",
		"-;",
		"D0R[24],Load Backup RAM;",
		"D0R[25],Save Backup RAM;",
		"D0O[26],Autosave,Off,On;", 
		"-;",
		
		"P1,Audio & Video;",
		"P1-;",
		"P1o[63:62],Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
		"P1O[11],320x224 Aspect,Original,Corrected;",
		"P1O[29],Deinterlacing, Weave, Bob;",
//		"P1O[3:1],Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
//		"P1-;",
//		"P1O[12],Border,No,Yes;",
//		"P1O[14:13],Composite Blend,Off,On,Adaptive;",
		"P1-;",
		"P1o[61],Vertical Crop,Disabled,216p(5x);",
		"P1o[54:51],Crop Offset,0,2,4,8,10,12,-12,-10,-8,-6,-4,-2;",
		"P1o[56:55],Scale,Normal,V-Integer,Narrower HV-Integer,Wider HV-Integer;",
	
		"P2,Input;",
		"P2-;",
		"P2OFH,Pad 1,Digital,Off,Wheel,Mission Stick,3D Pad,Dual Mission,Mouse;",
		"P2OIK,Pad 2,Digital,Off,Wheel,Mission Stick,3D Pad,Dual Mission,Mouse;",
		"P2OR,SNAC,OFF,ON;",
		"-;",
		
`ifndef MISTER_DUAL_SDRAM
		"P3,Hardware;",
		"P3-;",
		"P3OS,Timing,Original,Fast;",
`endif
		
/*
`ifndef DEBUG
		"P4,Debug;",
		"P4-;",
		"P4o[36],VDP2 NBG0,Enable,Disable;",
		"P4o[37],VDP2 NBG1,Enable,Disable;",
		"P4o[38],VDP2 NBG2,Enable,Disable;",
		"P4o[39],VDP2 NBG3,Enable,Disable;",
		"P4o[40],VDP2 RBG0,Enable,Disable;",
		"P4o[41],VDP2 Sprite,Enable,Disable;",
		"P4o[42],VDP2 Shadow,Enable,Disable;",
		"P4-;",
		"P4o[43],SCSP Direct sound,Enable,Disable;",
		"P4o[44],SCSP DSP sound,Enable,Disable;",
		"P4o[45],CD audio,Enable,Disable;",
`else
		"P4,Debug;",
		"P4o[36],SCSP slot 0,Enable,Disable;",
		"P4o[37],SCSP slot 1,Enable,Disable;",
		"P4o[38],SCSP slot 2,Enable,Disable;",
		"P4o[39],SCSP slot 3,Enable,Disable;",
		"P4o[40],SCSP slot 4,Enable,Disable;",
		"P4o[41],SCSP slot 5,Enable,Disable;",
		"P4o[42],SCSP slot 6,Enable,Disable;",
		"P4o[43],SCSP slot 7,Enable,Disable;",
		"P4o[44],SCSP slot 8,Enable,Disable;",
		"P4o[45],SCSP slot 9,Enable,Disable;",
		"P4o[46],SCSP slot 10,Enable,Disable;",
		"P4o[47],SCSP slot 11,Enable,Disable;",
		"P4o[48],SCSP slot 12,Enable,Disable;",
		"P4o[49],SCSP slot 13,Enable,Disable;",
		"P4o[50],SCSP slot 14,Enable,Disable;",
		"P4o[51],SCSP slot 15,Enable,Disable;",
		"P4o[52],SCSP slot 16,Enable,Disable;",
		"P4o[53],SCSP slot 17,Enable,Disable;",
		"P4o[54],SCSP slot 18,Enable,Disable;",
		"P4o[55],SCSP slot 19,Enable,Disable;",
		"P4o[56],SCSP slot 20,Enable,Disable;",
		"P4o[57],SCSP slot 21,Enable,Disable;",
		"P4o[58],SCSP slot 22,Enable,Disable;",
		"P4o[59],SCSP slot 23,Enable,Disable;",
		"P4o[60],SCSP slot 24,Enable,Disable;",
		"P4o[61],SCSP slot 25,Enable,Disable;",
		"P4o[62],SCSP slot 26,Enable,Disable;",
		"P4o[63],SCSP slot 27,Enable,Disable;",
		
		"P4O[28],SCSP slot 28,Enable,Disable;",
		"P4O[29],SCSP slot 29,Enable,Disable;",
		"P4O[30],SCSP slot 30,Enable,Disable;",
		"P4O[31],SCSP slot 31,Enable,Disable;",
`endif
*/
		"-;",
		"R0,Reset;",
		"J1,A,B,C,Start,R,X,Y,Z,L,Coin;",
//		"jn,A,B,R,Start,Select,X,Y,L;", 
//		"jp,Y,B,A,Start,Select,L,X,R;",
		"V,v",`BUILD_DATE
	};

	wire [63:0] status;
	wire  [1:0] buttons;
	wire [13:0] joystick_0,joystick_1,joystick_2,joystick_3,joystick_4;
	wire  [7:0] joy0_x0,joy0_y0,joy0_x1,joy0_y1,joy1_x0,joy1_y0,joy1_x1,joy1_y1;
	wire        ioctl_download;
	wire        ioctl_wr;
	wire [25:0] ioctl_addr;
	wire [15:0] ioctl_data;
	wire  [7:0] ioctl_index;
	reg         ioctl_wait = 0;
	
	reg  [31:0] sd_lba = '0;
	reg         sd_rd = 0;
	reg         sd_wr = 0;
	wire        sd_ack;
	wire  [7:0] sd_buff_addr;
	wire [15:0] sd_buff_dout;
	wire [15:0] sd_buff_din;
	wire        sd_buff_wr;
	wire        img_mounted;
	wire        img_readonly;
	wire [63:0] img_size;
	
	wire        forced_scandoubler;
	wire [10:0] ps2_key;
	wire [24:0] ps2_mouse;
	wire [15:0] ps2_mouse_ext;
	
	wire [64:0] RTC;
	
	wire [35:0] EXT_BUS;
	
	wire [21:0] gamma_bus;
	wire [15:0] sdram_sz;
	
	hps_io #(.CONF_STR(CONF_STR), .WIDE(1)) hps_io
	(
		.clk_sys(clk_sys),
		.HPS_BUS(HPS_BUS),
	
		.joystick_0(joystick_0),
		.joystick_1(joystick_1),
		.joystick_2(joystick_2),
		.joystick_3(joystick_3),
		.joystick_4(joystick_4),
		.joystick_l_analog_0({joy0_y0, joy0_x0}),
		.joystick_l_analog_1({joy1_y0, joy1_x0}),
		.joystick_r_analog_0({joy0_y1, joy0_x1}),
		.joystick_r_analog_1({joy1_y1, joy1_x1}),
	
		.buttons(buttons),
		.forced_scandoubler(forced_scandoubler),
		.new_vmode(new_vmode),
	
		.status(status),
		.status_in({status[63:8],region_req,status[5:0]}),
		.status_set(region_set),
		.status_menumask( {snac, 1'b1, 1'b1, ~status[8], 1'b1, ~bk_ena} ),
	
		.ioctl_download(ioctl_download),
		.ioctl_index(ioctl_index),
		.ioctl_wr(ioctl_wr),
		.ioctl_addr(ioctl_addr),
		.ioctl_dout(ioctl_data),
		.ioctl_wait(ioctl_wait),
	
		.sd_lba('{sd_lba}),
		.sd_rd(sd_rd),
		.sd_wr(sd_wr),
		.sd_ack(sd_ack),
		.sd_buff_addr(sd_buff_addr),
		.sd_buff_dout(sd_buff_dout),
		.sd_buff_din('{sd_buff_din}),
		.sd_buff_wr(sd_buff_wr),
		.img_mounted(img_mounted),
		.img_readonly(img_readonly),
		.img_size(img_size),
	
		.gamma_bus(gamma_bus),
		.sdram_sz(sdram_sz),
	
		.ps2_key(ps2_key),
		.ps2_mouse(ps2_mouse),
		.ps2_mouse_ext(ps2_mouse_ext),
		
		.RTC(RTC),
	
		.EXT_BUS(EXT_BUS)
	);
	
	reg  [1:0] region_req = '0;
	reg        region_set = 0;
	
	wire bios_download = ioctl_download & (ioctl_index[5:2] == 4'b0000 && ioctl_index[1:0] != 2'h3);
	wire cart_download = ioctl_download & (ioctl_index[5:2] == 4'b0000 && ioctl_index[1:0] == 2'h3);
	wire save_download = ioctl_download & (ioctl_index[5:2] == 4'b0001);
	wire cdd_download = ioctl_download & (ioctl_index[5:2] == 4'b0010);
	wire cdboot_download = ioctl_download & (ioctl_index[5:2] == 4'b0011);
	
	wire [2:0] cart_type = status[23:21];
	
	
	reg osd_btn = 0;
//	always @(posedge clk_sys) begin
//		integer timeout = 0;
//		reg     has_bootrom = 0;
//		reg     last_rst = 0;
//	
//		if (RESET) last_rst = 0;
//		if (status[0]) last_rst = 1;
//	
//		if (bios_download & ioctl_wr & status[0]) has_bootrom <= 1;
//	
//		if(last_rst & ~status[0]) begin
//			osd_btn <= 0;
//			if(timeout < 24000000) begin
//				timeout <= timeout + 1;
//				osd_btn <= ~has_bootrom;
//			end
//		end
//	end

	///////////////////////////////////////////////////
	wire clk_sys, clk_ram, locked;
	pll pll
	(
		.refclk(CLK_50M),
		.rst(0),
		.outclk_0(clk_sys),
		.outclk_1(clk_ram),
		.reconfig_to_pll(reconfig_to_pll),
		.reconfig_from_pll(reconfig_from_pll), 
		.locked(locked)
	);
	
	wire [63:0] reconfig_to_pll;
	wire [63:0] reconfig_from_pll;
	wire        cfg_waitrequest;
	reg         cfg_write;
	reg   [5:0] cfg_address;
	reg  [31:0] cfg_data;
	
	pll_cfg pll_cfg
	(
		.mgmt_clk(CLK_50M),
		.mgmt_reset(0),
		.mgmt_waitrequest(cfg_waitrequest),
		.mgmt_read(0),
		.mgmt_readdata(),
		.mgmt_write(cfg_write),
		.mgmt_address(cfg_address),
		.mgmt_writedata(cfg_data),
		.reconfig_to_pll(reconfig_to_pll),
		.reconfig_from_pll(reconfig_from_pll)
	);

	always @(posedge CLK_50M) begin
		reg pald = 0, pald2 = 0;
		reg dotsel = 0, dotsel2 = 0;
		reg resd = 0, resd2 = 0;
		reg [2:0] state = 0;

		pald  <= PAL;
		pald2 <= pald;
		
		dotsel  <= SMPC_DOTSEL;
		dotsel2 <= dotsel;
		
		resd  <= reset;
		resd2 <= resd;
	
		if (dotsel2 != dotsel || pald2 != pald || (resd && !resd2)) state <= 1;
	
		cfg_write <= 0;
		if (!cfg_waitrequest) begin
			if (state) state <= state + 1'd1;
			case (state)
				1: begin
						cfg_address <= 0;
						cfg_data <= 0;
						cfg_write <= 1;
					end
				3: begin
						cfg_address <= 4;
						cfg_data <= !dotsel2 ? 32'h00000404 : 32'h00020504;
						cfg_write <= 1;
					end
				5: begin
						cfg_address <= 7;
						cfg_data <= !pald2 ? (!dotsel2 ? 32'h9986B96D : 32'h29E4D329) :
						                     (!dotsel2 ? 32'h8A3D70A4 : 32'h1999999A);
						cfg_write <= 1;
					end
				7: begin
						cfg_address <= 2;
						cfg_data <= 0;
						cfg_write <= 1;
					end
			endcase
		end
	end 
	
	wire reset = RESET | status[0] | buttons[1];
	
	reg rst_ram = 0;
	reg download;
	always @(posedge clk_sys) begin
		reg [7:0] delay_cnt;
		
		download <= bios_download || cart_download;
		if (delay_cnt) delay_cnt <= delay_cnt - 8'd1;
		else rst_ram <= 0;
		
		if ((!bios_download && !cart_download && download) || reset) begin
			rst_ram <= 1;
			delay_cnt <= '1;
		end
	end
	
	wire rst_sys = reset | download | rst_ram;
	
`ifndef MISTER_DUAL_SDRAM
	wire fast_timing = status[28];
`else
	wire fast_timing = 0;
`endif
	
	//region select
	reg [7:0] cd_area_symbol;
	always @(posedge clk_sys) begin
		if (cdboot_download && ioctl_wr) begin
			case (ioctl_addr[7:0])
				8'h40: cd_area_symbol <= ioctl_data[7:0];
			endcase
		end
	end
	wire [3:0] cd_area_code = cd_area_symbol == "J" ? 4'h1 :
	                          cd_area_symbol == "T" ? 4'h2 :
	                          cd_area_symbol == "U" ? 4'h4 :
	                          cd_area_symbol == "B" ? 4'h5 :
	                          cd_area_symbol == "K" ? 4'h6 :
	                          cd_area_symbol == "A" ? 4'hA :
	                          cd_area_symbol == "E" ? 4'hC :
	                          cd_area_symbol == "L" ? 4'hD :
										                       4'h1;
	
	wire  [3:0] area_code = status[35:33] == 3'd0 ? 4'h1 :	//Japan area
									status[35:33] == 3'd1 ? 4'h2 :	//Asia NTSC area
									status[35:33] == 3'd2 ? 4'h4 :	//North America area
									status[35:33] == 3'd3 ? 4'h5 :	//Central/S. America NTSC area
									status[35:33] == 3'd4 ? 4'h6 :	//Korea area
									status[35:33] == 3'd5 ? 4'hA :	//Asia PAL area
									status[35:33] == 3'd6 ? 4'hC :	//Europe PAL area
																	cd_area_code;	//Auto
																	
	wire [15:0] joy1 = {~joystick_0[0]|joystick_0[1], ~joystick_0[1]|joystick_0[0], ~joystick_0[2]|joystick_0[3], ~joystick_0[3]|joystick_0[2], ~joystick_0[7], ~joystick_0[4], ~joystick_0[6], ~joystick_0[5],
							  ~joystick_0[8], ~joystick_0[9], ~joystick_0[10], ~joystick_0[11], ~joystick_0[12], 3'b111};
	wire [15:0] joy2 = {~joystick_1[0]|joystick_1[1], ~joystick_1[1]|joystick_1[0], ~joystick_1[2]|joystick_1[3], ~joystick_1[3]|joystick_1[2], ~joystick_1[7], ~joystick_1[4], ~joystick_1[6], ~joystick_1[5],
							  ~joystick_1[8], ~joystick_1[9], ~joystick_1[10], ~joystick_1[11], ~joystick_1[12], 3'b111};
	wire        coin1 = ~joystick_0[13];

	wire snac = status[27];
	reg  [6:0] USERJOYSTICK;
	wire [6:0] USERJOYSTICKOUT;
	always @(posedge clk_sys) begin
		if (snac) begin
			USERJOYSTICK <= {USER_IN[4], USER_IN[6], USER_IN[2], USER_IN[3], USER_IN[5], USER_IN[0], USER_IN[1]};//TH, C(TR), B(TL), R, L, D, U
			USER_OUT <= {USERJOYSTICKOUT[5], USERJOYSTICKOUT[2], USERJOYSTICKOUT[6], USERJOYSTICKOUT[3], USERJOYSTICKOUT[4], USERJOYSTICKOUT[0], USERJOYSTICKOUT[1]};
		end else begin
			USER_OUT <= '1;
		end
	end

	
	
	wire [24:0] MEM_A;
	wire [31:0] MEM_DI;
	wire [31:0] MEM_DO;
	wire        ROM_CS_N;
	wire        SRAM_CS_N;
	wire        RAML_CS_N;
	wire        RAMH_CS_N;
	wire        RAMH_RFS;
	wire        STVIO_CS_N;
	wire  [3:0] MEM_DQM_N;
	wire        MEM_RD_N;
	wire        MEM_WAIT_N;
	
	wire [18:1] VDP1_VRAM_A;
	wire [15:0] VDP1_VRAM_D;
	wire [15:0] VDP1_VRAM_Q;
	wire  [1:0] VDP1_VRAM_WE;
	wire        VDP1_VRAM_RD;
	wire  [8:0] VDP1_VRAM_BLEN;
	wire        VDP1_VRAM_RDY;
	wire [17:1] VDP1_FB0_A;
	wire [15:0] VDP1_FB0_D;
	wire [15:0] VDP1_FB0_Q;
	wire  [1:0] VDP1_FB0_WE;
	wire        VDP1_FB0_RD;
	wire [17:1] VDP1_FB1_A;
	wire [15:0] VDP1_FB1_D;
	wire [15:0] VDP1_FB1_Q;
	wire  [1:0] VDP1_FB1_WE;
	wire        VDP1_FB1_RD;
	wire        VDP1_FB_RDY;
	wire        VDP1_FB_MODE3;
	
	wire [17:1] VDP2_RA0_A;
	wire [16:1] VDP2_RA1_A;
	wire [63:0] VDP2_RA_D;
	wire  [7:0] VDP2_RA_WE;
	wire        VDP2_RA_RD;
	wire [31:0] VDP2_RA0_Q;
	wire [31:0] VDP2_RA1_Q;
	wire [17:1] VDP2_RB0_A;
	wire [16:1] VDP2_RB1_A;
	wire [63:0] VDP2_RB_D;
	wire  [7:0] VDP2_RB_WE;
	wire        VDP2_RB_RD;
	wire [31:0] VDP2_RB0_Q;
	wire [31:0] VDP2_RB1_Q;
	
	wire [18:1] SCSP_RAM_A;
	wire [15:0] SCSP_RAM_D;
	wire  [1:0] SCSP_RAM_WE;
	wire        SCSP_RAM_RD;
	wire        SCSP_RAM_CS;
	wire [15:0] SCSP_RAM_Q;
	wire        SCSP_RAM_RFS;
	wire        SCSP_RAM_RDY;
	
	wire         SMPC_DOTSEL;
	wire [ 6: 0] SMPC_PDR1I;
	wire [ 6: 0] SMPC_PDR1O;
	wire [ 6: 0] SMPC_DDR1;
	wire [ 6: 0] SMPC_PDR2I;
	wire [ 6: 0] SMPC_PDR2O;
	wire [ 6: 0] SMPC_DDR2;
	
	wire        CD_CDATA;
	wire        CD_HDATA;
	wire        CD_COMCLK;
	wire        CD_COMREQ_N;
	wire        CD_COMSYNC_N;
	wire [17:0] CD_DATA;
	wire        CD_CK;
	wire        CD_AUDIO;
	
	wire [18:1] CD_RAM_A;
	wire [15:0] CD_RAM_D;
	wire  [1:0] CD_RAM_WE;
	wire        CD_RAM_RD;
	wire        CD_RAM_CS;
	wire [15:0] CD_RAM_Q;
	wire        CD_RAM_RDY;
	
	wire [25:1] CART_MEM_A;
	wire [15:0] CART_MEM_D;
	wire [15:0] CART_MEM_Q;
	wire [ 1:0] CART_MEM_WE;
	wire        CART_MEM_RD;
	wire        CART_MEM_RDY;
	
	wire  [7:0] R, G, B;
	wire        HS_N,VS_N;
	wire        DCLK;
	wire        HBL_N, VBL_N;
	wire        FIELD;
	wire        INTERLACE;
	wire  [1:0] HRES;
	wire  [1:0] VRES;
	wire        DCE_R;
	
	bit MCLK_DIV;
	always @(posedge clk_sys) MCLK_DIV <= ~MCLK_DIV;
	wire SYS_CE_R =  MCLK_DIV;
	wire SYS_CE_F = ~MCLK_DIV;
	
	reg [31:0] in_clk;
	always @(posedge clk_sys) 
		in_clk <= !PAL ? (!SMPC_DOTSEL ? 53748200 : 57272800) :
	                    (!SMPC_DOTSEL ? 53375000 : 56875000);

	
	wire SMPC_CE;		//SMPC clock 4.0000MHz
	CEGen SMPC_CEGen
	(
		.CLK(clk_sys),
		.RST_N(1),
		.IN_CLK(in_clk),
		.OUT_CLK(4000000),
		.CE(SMPC_CE)
	);
	
	wire SCSP_CE;		//SCSP clock 22.5792MHz
	CEGen SCSP_CEGen
	(
		.CLK(clk_sys),
		.RST_N(1),
		.IN_CLK(in_clk),
		.OUT_CLK(22579200),
		.CE(SCSP_CE)
	);
	
	wire CD_CE;			//CD clock freq 20.000MHz
	CEGen CD_CEGen
	(
		.CLK(clk_sys),
		.RST_N(1),
		.IN_CLK(in_clk),
		.OUT_CLK(20000000*2),
		.CE(CD_CE)
	);
	
	wire CDD_2X_CE;	//CD data clock 44.1kHz x 2(channel) x 2(speed)
	CEGen CDD_CEGen
	(
		.CLK(clk_sys),
		.RST_N(1),
		.IN_CLK(in_clk),
		.OUT_CLK(44100*2*2),
		.CE(CDD_2X_CE)
	);
	
	Saturn 
`ifdef MISTER_DUAL_SDRAM
	#(.RAMH_SLOW(0))
`else
	#(.RAMH_SLOW(1))
`endif
	saturn
	(
		.CLK(clk_sys),
		.RST_N(~rst_sys),
		.EN(~DBG_PAUSE),
		
		.SYS_CE_F(SYS_CE_F),
		.SYS_CE_R(SYS_CE_R),
		
		.SRES_N(~status[0]),
		
		.PAL(PAL),
		
		.MEM_A(MEM_A),
		.MEM_DI(MEM_DI),
		.MEM_DO(MEM_DO),
		.MEM_DQM_N(MEM_DQM_N),
		.ROM_CS_N(ROM_CS_N),
		.SRAM_CS_N(SRAM_CS_N),
		.RAML_CS_N(RAML_CS_N),
		.RAMH_CS_N(RAMH_CS_N),
		.RAMH_RFS(RAMH_RFS),
		.STVIO_CS_N(STVIO_CS_N),
		.MEM_RD_N(MEM_RD_N),
		.MEM_WAIT_N(MEM_WAIT_N),
		
		.VDP1_VRAM_A(VDP1_VRAM_A),
		.VDP1_VRAM_D(VDP1_VRAM_D),
		.VDP1_VRAM_WE(VDP1_VRAM_WE),
		.VDP1_VRAM_RD(VDP1_VRAM_RD),
		.VDP1_VRAM_BLEN(VDP1_VRAM_BLEN),
		.VDP1_VRAM_Q(VDP1_VRAM_Q),
		.VDP1_VRAM_RDY(VDP1_VRAM_RDY),
		.VDP1_FB0_A(VDP1_FB0_A),
		.VDP1_FB0_D(VDP1_FB0_D),
		.VDP1_FB0_WE(VDP1_FB0_WE),
		.VDP1_FB0_RD(VDP1_FB0_RD),
		.VDP1_FB0_Q(VDP1_FB0_Q),
		.VDP1_FB1_A(VDP1_FB1_A),
		.VDP1_FB1_D(VDP1_FB1_D),
		.VDP1_FB1_WE(VDP1_FB1_WE),
		.VDP1_FB1_RD(VDP1_FB1_RD),
		.VDP1_FB1_Q(VDP1_FB1_Q),
		.VDP1_FB_RDY(VDP1_FB_RDY),
		.VDP1_FB_MODE3(VDP1_FB_MODE3),
			
		.VDP2_RA0_A(VDP2_RA0_A),
		.VDP2_RA1_A(VDP2_RA1_A),
		.VDP2_RA_D(VDP2_RA_D),
		.VDP2_RA_WE(VDP2_RA_WE),
		.VDP2_RA_RD(VDP2_RA_RD),
		.VDP2_RA0_Q(VDP2_RA0_Q),
		.VDP2_RA1_Q(VDP2_RA1_Q),
		.VDP2_RB0_A(VDP2_RB0_A),
		.VDP2_RB1_A(VDP2_RB1_A),
		.VDP2_RB_D(VDP2_RB_D),
		.VDP2_RB_WE(VDP2_RB_WE),
		.VDP2_RB_RD(VDP2_RB_RD),
		.VDP2_RB0_Q(VDP2_RB0_Q),
		.VDP2_RB1_Q(VDP2_RB1_Q),
		
		.SCSP_CE(SCSP_CE),
		.SCSP_RAM_A(SCSP_RAM_A),
		.SCSP_RAM_D(SCSP_RAM_D),
		.SCSP_RAM_WE(SCSP_RAM_WE),
		.SCSP_RAM_RD(SCSP_RAM_RD),
		.SCSP_RAM_CS(SCSP_RAM_CS),
		.SCSP_RAM_Q(SCSP_RAM_Q),
		.SCSP_RAM_RFS(SCSP_RAM_RFS),
		.SCSP_RAM_RDY(SCSP_RAM_RDY),
		
		.SMPC_CE(SMPC_CE),
		.TIME_SET(~status[32]),
		.RTC(RTC),
		.SMPC_AREA(area_code),
		.SMPC_DOTSEL(SMPC_DOTSEL),
		.SMPC_PDR1I(snac ? USERJOYSTICK : SMPC_PDR1I),
		.SMPC_PDR1O(SMPC_PDR1O),
		.SMPC_DDR1(SMPC_DDR1),
		.SMPC_PDR2I(SMPC_PDR2I),
		.SMPC_PDR2O(SMPC_PDR2O),
		.SMPC_DDR2(SMPC_DDR2),
		
		.CD_CE(CD_CE),
		.CD_CDATA(CD_CDATA),
		.CD_HDATA(CD_HDATA),
		.CD_COMCLK(CD_COMCLK),
		.CD_COMREQ_N(CD_COMREQ_N),
		.CD_COMSYNC_N(CD_COMSYNC_N),
		.CD_D(CD_DATA),
		.CD_CK(CD_CK),
		.CD_AUDIO(CD_AUDIO),
		.CD_RAM_A(CD_RAM_A),
		.CD_RAM_D(CD_RAM_D),
		.CD_RAM_WE(CD_RAM_WE),
		.CD_RAM_RD(CD_RAM_RD),
		.CD_RAM_CS(CD_RAM_CS),
		.CD_RAM_Q(CD_RAM_Q),
		.CD_RAM_RDY(CD_RAM_RDY),
		
		.CART_MODE(cart_type),
		.CART_MEM_A(CART_MEM_A),
		.CART_MEM_D(CART_MEM_D),
		.CART_MEM_WE(CART_MEM_WE),
		.CART_MEM_RD(CART_MEM_RD),
		.CART_MEM_Q(CART_MEM_Q),
		.CART_MEM_RDY(CART_MEM_RDY),
		
		.STV_SW('1),
		
		.R(R),
		.G(G),
		.B(B),
		.DCLK(DCLK),
		.VS_N(VS_N),
		.HS_N(HS_N),
		.HBL_N(HBL_N),
		.VBL_N(VBL_N),
		
		.FIELD(FIELD),
		.INTERLACE(INTERLACE),
		.HRES(HRES), 				//[1]:0-normal,1-hi-res; [0]:0-320p,1-352p
		.VRES(VRES), 				//0-224,1-240,2-256
		.DCE_R(DCE_R),
		
		.SOUND_L(AUDIO_L),
		.SOUND_R(AUDIO_R),
		
		.FAST(fast_timing),
		
		.SCRN_EN(SCRN_EN & SCRN_EN2),
		.SND_EN(SND_EN & SND_EN2),
		.SLOT_EN(SLOT_EN),
		.DBG_PAUSE(DBG_PAUSE),
		.DBG_BREAK(DBG_BREAK),
		.DBG_RUN(DBG_RUN),
		.DBG_EXT(DBG_EXT)
	);
	
	wire [ 7:0] STVIO_DO;
	STV STVIO
	(
		.CLK(clk_sys),
		.RST_N(~rst_sys),
		.CE_R(SYS_CE_R),
		.CE_F(SYS_CE_F),
		
		.RES_N(1'b1),
		
		.A(MEM_A[6:1]),
		.DI(MEM_DO[7:0]),
		.DO(STVIO_DO),
		.CS_N(STVIO_CS_N),
		.RW_N(MEM_DQM_N[0]),
		
		.JOY1(joy1),
		.JOY2(joy2),
		.COIN1(coin1)
	);
	
	assign USERJOYSTICKOUT = SMPC_PDR1O;
	
	HPS2PAD PAD
	(
		.CLK(clk_sys),
		.RST_N(~rst_sys),
		.SMPC_CE(SMPC_CE),
		
		.PDR1I(SMPC_PDR1I),
		.PDR1O(SMPC_PDR1O),
		.DDR1(SMPC_DDR1),
		.PDR2I(SMPC_PDR2I),
		.PDR2O(SMPC_PDR2O),
		.DDR2(SMPC_DDR2),
		
		.JOY1(joy1),
		.JOY2(joy2),

		.JOY1_X1(joy0_x0),
		.JOY1_Y1(joy0_y0),
		.JOY1_X2(joy0_x1),
		.JOY1_Y2(joy0_y1),
		.JOY2_X1(joy1_x0),
		.JOY2_Y1(joy1_y0),
		.JOY2_X2(joy1_x1),
		.JOY2_Y2(joy1_y1),

		.JOY1_TYPE(status[17:15]),
		.JOY2_TYPE(status[20:18]),

		.MOUSE(ps2_mouse),
		.MOUSE_EXT(ps2_mouse_ext),
		
		.LGUN_TRIGGER(lg_a),			// Active-HIGH input.
		.LGUN_START(lg_start),		// Active-HIGH input.
		.LGUN_SENSOR(lg_sensor)		// Active-HIGH input.
	);
	

	wire [2:0] lg_target;
	wire       lg_sensor;
	wire       lg_a;
	wire       lg_b;
	//wire       lg_c;
	wire       lg_start;

	wire        gun_type;
	wire  [7:0] gun_sensor_delay = 8'd2;

	wire [1:0] gun_mode = status[41:40];
	wire       gun_btn_mode = status[42];

	lightgun  lightgun_inst
	(
		.CLK(clk_sys),
		.RESET(~rst_sys),

		.MOUSE(ps2_mouse),
		.MOUSE_XY(gun_mode==2'd3),	// In Mouse XY mode, the lightgun module will ignore the Joystick X/Y stuff below.

		.JOY_X(gun_mode[0] ? joy0_x0    : joy1_x0),
		.JOY_Y(gun_mode[0] ? joy0_y0    : joy1_y0),
		.JOY(  gun_mode[0] ? joystick_0 : joystick_1),

		.BTN_MODE(gun_btn_mode),	// 0=Use Mouse buttons for LG. 1=Use Joystick buttons for LG.
		
		//.RELOAD(gun_type),
		.RELOAD(1'b1),		// Auto-Reload?

		.HDE(HBL_N),		// Blanking signals are Active-Low. So should act as "DE" (Data Enable) signals when High!
		.VDE(VBL_N),		// ie. No need to invert here?
		.CE_PIX(DCLK),
		
		.FIELD(FIELD),
		.INTERLACE(INTERLACE),
		.HRES(HRES), 				// input [1:0]   [1]:0-normal,1-hi-res; [0]:0-320p,1-352p
		.VRES(VRES), 				// input [1:0]   0-224,1-240,2-256
		.DCE_R(DCE_R),
		
		.SIZE( status[44:43] ),
		.SENSOR_DELAY(gun_sensor_delay),	// Originally based on the MD lightgun module. Not sure if any Saturn LG games use polling, or even need this? EA

		.TARGET(lg_target),		// output [2:0]  TARGET. (lg_target is used at the video_mixer inputs, to show the crosshair on-screen).
		
		.SENSOR(lg_sensor),		// output  SENSOR  ("Light detected" signal, to VDP2).
		.BTN_A(lg_a),				// output  BTN_A   (used as the Trigger "button" signal, to HPS2PAD).
		//.BTN_B(lg_b),			// output  BTN_B   (used for Auto-Reload in this module - Don't use the BTN_B / lg_b output when using the RELOAD option!)
		//.BTN_C(lg_c),
		.BTN_START(lg_start)		// (used as the Start button signal, to HPS2PAD).
	);

	
	wire [13:1] CD_BUF_ADDR;
	wire [15:0] CD_BUF_DI;
	wire        CD_BUF_RD;
	wire        CD_BUF_RDY;
	HPS2CDD CDD (
		.CLK(clk_sys),
		.RST_N(~rst_sys),
		
		.EXT_BUS(EXT_BUS),
		
		.CDD_CE(CDD_2X_CE),
		.CD_CDATA(CD_CDATA),
		.CD_HDATA(CD_HDATA),
		.CD_COMCLK(CD_COMCLK),
		.CD_COMREQ_N(CD_COMREQ_N),
		.CD_COMSYNC_N(CD_COMSYNC_N),
		
		.CDD_ACT(cdd_download),
		.CDD_WR(ioctl_wr),
		.CDD_DI(ioctl_data),
		
		.CD_BUF_ADDR(CD_BUF_ADDR),
		.CD_BUF_DI(CD_BUF_DI),
		.CD_BUF_RD(CD_BUF_RD),
		.CD_BUF_RDY(CD_BUF_RDY),
			
		.CD_DATA(CD_DATA),
		.CD_CK(CD_CK),
		.CD_AUDIO(CD_AUDIO)
	);

	//SDRAM1
	sdram1 sdram1
	(
		.SDRAM_CLK(SDRAM_CLK),
		.SDRAM_A(SDRAM_A),
		.SDRAM_BA(SDRAM_BA),
		.SDRAM_DQ(SDRAM_DQ),
		.SDRAM_DQML(SDRAM_DQML),
		.SDRAM_DQMH(SDRAM_DQMH),
		.SDRAM_nCS(SDRAM_nCS),
		.SDRAM_nWE(SDRAM_nWE),
		.SDRAM_nRAS(SDRAM_nRAS),
		.SDRAM_nCAS(SDRAM_nCAS),
		.SDRAM_CKE(SDRAM_CKE),
		
		.clk(clk_ram),
		.init(rst_ram),
		.sync(DCE_R),
	
		.addr_a0(VDP2_RA0_A[17:1]),
		.addr_a1(VDP2_RA1_A[16:1]),
		.din_a(VDP2_RA_D),
		.wr_a(VDP2_RA_WE),
		.rd_a(VDP2_RA_RD),
		.dout_a0(VDP2_RA0_Q),
		.dout_a1(VDP2_RA1_Q),
	
		.addr_b0(VDP2_RB0_A[17:1]),
		.addr_b1(VDP2_RB1_A[16:1]),
		.din_b(VDP2_RA_D),///////////////
		.wr_b(VDP2_RB_WE),
		.rd_b(VDP2_RB_RD),
		.dout_b0(VDP2_RB0_Q),
		.dout_b1(VDP2_RB1_Q),
		
		.ch2addr({1'b0,SCSP_RAM_A}),
		.ch2din(SCSP_RAM_D),
		.ch2wr(SCSP_RAM_WE & {2{SCSP_RAM_CS}}),
		.ch2rd(SCSP_RAM_RD & SCSP_RAM_CS),
		.ch2dout(SCSP_RAM_Q),
		.ch2rdy(SCSP_RAM_RDY)
	);

	//DDRAM
	always @(posedge clk_sys) begin
		reg old_busy;
		
//		old_busy <= ddr_busy[7];
//		if ((bios_download || cart_download) && ioctl_wr) ioctl_wait <= 1;
//		if (~ddr_busy[7] && old_busy) ioctl_wait <= 0;
		ioctl_wait <= bios_busy;
	end
	wire [26:1] IO_ADDR = cart_download ? {1'b1,ioctl_addr[25:1]} : {8'b00000000,ioctl_addr[18:1]};
	wire [15:0] IO_DATA = cart_type == 3'h5 ? ioctl_data : {ioctl_data[7:0],ioctl_data[15:8]};
	wire        IO_WR = (bios_download | cart_download) & ioctl_wr;
	
	wire [31:0] ddr_do[10];
	wire        ddr_busy[10];
	wire [15:0] cdram_do,raml_do,vdp1vram_do,vdp1fb_do,cdbuf_do,cart_do,bsram_do;
	wire [31:0] ramh_do;
	wire        cdram_busy,raml_busy,ramh_busy,vdp1vram_busy,vdp1fb_busy,cdbuf_busy,cart_busy,bios_busy,bsram_busy;
	ddram ddram
	(
		.*,
		.clk(clk_ram),
		.rst(reset || rst_ram),
		
		//CPU bus (RAMH)
`ifdef MISTER_DUAL_SDRAM
		.ramh_addr('0),
		.ramh_din ('0),
		.ramh_wr  ('0),
		.ramh_rd  (0),
`else
		.ramh_addr(MEM_A[19:2]),
		.ramh_din (MEM_DO),
		.ramh_wr  ({4{~RAMH_CS_N}} & ~MEM_DQM_N),
		.ramh_rd  (~RAMH_CS_N & ~MEM_RD_N),
`endif
		.ramh_dout(ramh_do),
		.ramh_busy(ramh_busy),
		
		//CD RAM
		.cdram_addr(CD_RAM_A[18:1]),
		.cdram_din (CD_RAM_D),
		.cdram_wr  (CD_RAM_WE & {2{CD_RAM_CS}}),
		.cdram_rd  (CD_RAM_RD & CD_RAM_CS),
		.cdram_dout(cdram_do),
		.cdram_busy(cdram_busy),
	
		//CPU bus (ROM,SRAM,RAML)
		.raml_addr({~RAML_CS_N,~SRAM_CS_N,ROM_CS_N&SRAM_CS_N&MEM_A[19],MEM_A[18:1]}),
		.raml_din (MEM_DO[15:0]),
		.raml_wr  ({2{~SRAM_CS_N|~RAML_CS_N}} & ~MEM_DQM_N[1:0]),
		.raml_rd  ((~ROM_CS_N | ~SRAM_CS_N | ~RAML_CS_N) & ~MEM_RD_N),
		.raml_dout(raml_do),
		.raml_busy(raml_busy),
	
		//VDP1 VRAM
		.vdp1vram_addr(VDP1_VRAM_A[18:1]),
		.vdp1vram_din (VDP1_VRAM_D),
		.vdp1vram_wr  (VDP1_VRAM_WE),
		.vdp1vram_rd  (VDP1_VRAM_RD),
		.vdp1vram_blen(VDP1_VRAM_BLEN),
		.vdp1vram_dout(vdp1vram_do),
		.vdp1vram_busy(vdp1vram_busy),
	
		//VDP1 FB (rest)
		.vdp1fb_addr(VDP1_A),
		.vdp1fb_din (VDP1_D),
		.vdp1fb_wr  (VDP1_WE),
		.vdp1fb_rd  (VDP1_RD),
		.vdp1fb_dout(vdp1fb_do),
		.vdp1fb_busy(vdp1fb_busy),
		
		//CD BUF
		.cdbuf_addr(CD_BUF_ADDR),
		.cdbuf_rd  (CD_BUF_RD),
		.cdbuf_dout(cdbuf_do),
		.cdbuf_busy(cdbuf_busy),
		
		//CART MEM
`ifdef DEBUG
		.cart_addr('0),
		.cart_din ('0),
		.cart_wr  ('0),
		.cart_rd  (0),
`else
		.cart_addr(CART_MEM_A),
		.cart_din (CART_MEM_D),
		.cart_wr  (CART_MEM_WE),
		.cart_rd  (CART_MEM_RD),
`endif
		.cart_dout(cart_do),
		.cart_busy(cart_busy),
	
		//BIOS/CART load
		.bios_addr(IO_ADDR),
		.bios_din (IO_DATA),
		.bios_wr  ({2{IO_WR}}),
		.bios_busy(bios_busy),
		
		//SRAM backup
		.bsram_addr(sd_lba[11:7] ? {1'b1,sd_lba[10:7]-4'h1,sd_lba[6:0],tmpram_addr} : {5'b00000,sd_lba[6:0],tmpram_addr}),
		.bsram_din ({8'hFF,tmpram_dout[15:8]}),
		.bsram_wr  ({2{tmpram_req & bk_loading}}),
		.bsram_rd  ((tmpram_req & ~bk_loading)),
		.bsram_dout(bsram_do),
		.bsram_busy(bsram_busy)
	);
	assign VDP1_VRAM_Q = vdp1vram_do;
	assign VDP1_VRAM_RDY = ~vdp1vram_busy;

	assign CD_BUF_DI = cdbuf_do;
	assign CD_BUF_RDY = ~cdbuf_busy;
	
	assign CART_MEM_Q = cart_do;
	assign CART_MEM_RDY = ~cart_busy;
	
	assign CD_RAM_Q = cdram_do;
	assign CD_RAM_RDY = ~cdram_busy;


`ifdef MISTER_DUAL_SDRAM
	//SDRAM2
	wire sdr2_busy;
	wire [31:0] sdr2_do;
	sdram2 sdram2
	(
		.SDRAM_CLK(SDRAM2_CLK),
		.SDRAM_A(SDRAM2_A),
		.SDRAM_BA(SDRAM2_BA),
		.SDRAM_DQ(SDRAM2_DQ),
		.SDRAM_nCS(SDRAM2_nCS),
		.SDRAM_nWE(SDRAM2_nWE),
		.SDRAM_nRAS(SDRAM2_nRAS),
		.SDRAM_nCAS(SDRAM2_nCAS),
		
		.init(rst_ram),
		.clk(clk_ram),
		
		.addr({MEM_A[19:2],1'b0}),
		.din(MEM_DO),
		.wr({4{~RAMH_CS_N}} & ~MEM_DQM_N),
		.rd(~RAMH_CS_N & ~MEM_RD_N),
		.dout(sdr2_do),
		.rfs(~RAMH_CS_N & RAMH_RFS),
		.busy(sdr2_busy)
	);
`endif
	
`ifdef MISTER_DUAL_SDRAM
	assign MEM_DI     = !RAMH_CS_N ? sdr2_do : !STVIO_CS_N ? {24'hFFFFFF,STVIO_DO} : raml_do;
	assign MEM_WAIT_N = !RAMH_CS_N ? ~sdr2_busy : !STVIO_CS_N ? 1'b1 : ~raml_busy;
`else
	assign MEM_DI     = !RAMH_CS_N ? ramh_do : !STVIO_CS_N ? {24'hFFFFFF,STVIO_DO} : raml_do;
	assign MEM_WAIT_N = !RAMH_CS_N ? ~ramh_busy : !STVIO_CS_N ? 1'b1 : ~raml_busy;
`endif


	//VDP1 FB
`ifdef SATURN_FULL_FB
	wire        FB0_EXT_SEL = 0;
	wire        FB1_EXT_SEL = 0;
`else
	wire        FB0_EXT_SEL = VDP1_FB_MODE3 ? VDP1_FB0_A[17:9] >= 9'd352 : VDP1_FB0_A[9:1] >= 9'd352;
	wire        FB1_EXT_SEL = VDP1_FB_MODE3 ? VDP1_FB1_A[17:9] >= 9'd352 : VDP1_FB1_A[9:1] >= 9'd352;
	bit  [15:0] FB0_EXT_Q;
	bit  [15:0] FB1_EXT_Q;
`endif
	wire [17:1] FB0_A = VDP1_FB_MODE3 ? {VDP1_FB0_A[17:9],VDP1_FB0_A[8:1]} : {VDP1_FB0_A[9:1],VDP1_FB0_A[17:10]};
	wire [17:1] FB1_A = VDP1_FB_MODE3 ? {VDP1_FB1_A[17:9],VDP1_FB1_A[8:1]} : {VDP1_FB1_A[9:1],VDP1_FB1_A[17:10]};
	
	bit [15:0] FB0_Q,FB1_Q;
`ifdef SATURN_FULL_FB
	vdp1_fb_512x256x16 vdp1_fb0
	(
		.clock(clk_sys),
		.address(FB0_A),
		.data(VDP1_FB0_D),
		.wren(VDP1_FB0_WE),
		.q(FB0_Q)
	);

	vdp1_fb_512x256x16 vdp1_fb1
	(
		.clock(clk_sys),
		.address(FB1_A),
		.data(VDP1_FB1_D),
		.wren(VDP1_FB1_WE),
		.q(FB1_Q)
	);
`else
	//first 352x256x16 bit
	vdp1_fb_352x256x16 vdp1_fb0
	(
		.clock(clk_sys),
		.address(FB0_A),
		.data(VDP1_FB0_D),
		.wren(VDP1_FB0_WE & {2{~FB0_EXT_SEL}}),
		.q(FB0_Q)
	);

	vdp1_fb_352x256x16 vdp1_fb1
	(
		.clock(clk_sys),
		.address(FB1_A),
		.data(VDP1_FB1_D),
		.wren(VDP1_FB1_WE & {2{~FB1_EXT_SEL}}),
		.q(FB1_Q)
	);
`endif

	assign VDP1_FB0_Q = !FB0_EXT_SEL ? FB0_Q : FB0_EXT_Q;
	assign VDP1_FB1_Q = !FB1_EXT_SEL ? FB1_Q : FB1_EXT_Q;

`ifndef SATURN_FULL_FB
`ifndef DEBUG
	bit [18:1] VDP1_A;
	bit [15:0] VDP1_D;
	bit [ 1:0] VDP1_WE;
	bit        VDP1_RD;
	bit        VDP1_FB0_BUSY;
	bit        VDP1_FB1_BUSY;
	always @(posedge clk_ram) begin
		reg vram_rd_old,fb0_rd_old,fb1_rd_old;
		reg vram_we_old,fb0_we_old,fb1_we_old;
		reg [1:0] VDP1_FB0_WPEND;
		reg [1:0] VDP1_FB1_WPEND;
		reg VDP1_FB0_RPEND;
		reg VDP1_FB1_RPEND;
		reg [1:0] vdp1_state;
		
		if (rst_sys) begin
			VDP1_FB0_WPEND <= '0;
			VDP1_FB1_WPEND <= '0;
			VDP1_FB0_RPEND <= 0;
			VDP1_FB1_RPEND <= 0;
			VDP1_FB0_BUSY <= 0;
			VDP1_FB1_BUSY <= 0;
			VDP1_WE <= '0;
			VDP1_RD <= 0;
			vdp1_state <= '0;
		end else begin
			//VDP1 FB0 (rest 160x256x16 bit)
			fb0_rd_old <= VDP1_FB0_RD;
			fb0_we_old <= |VDP1_FB0_WE;
			if (((VDP1_FB0_RD && !fb0_rd_old) || (VDP1_FB0_WE && !fb0_we_old)) && FB0_EXT_SEL) begin
				VDP1_FB0_WPEND <= VDP1_FB0_WE;  
				VDP1_FB0_RPEND <= VDP1_FB0_RD;  
				VDP1_FB0_BUSY <= 1;
			end
			
			//VDP1 FB1 (rest 160x256x16 bit)
			fb1_rd_old <= VDP1_FB1_RD;
			fb1_we_old <= |VDP1_FB1_WE;
			if (((VDP1_FB1_RD && !fb1_rd_old) || (VDP1_FB1_WE && !fb1_we_old)) && FB1_EXT_SEL) begin
				VDP1_FB1_WPEND <= VDP1_FB1_WE;  
				VDP1_FB1_RPEND <= VDP1_FB1_RD; 
				VDP1_FB1_BUSY <= 1;
			end
			
			VDP1_WE <= '0;
			VDP1_RD <= 0;
			case (vdp1_state)
				2'd0: begin
					if ((VDP1_FB0_RD && FB0_EXT_SEL) || VDP1_FB0_RPEND) begin
						VDP1_A <= {1'b0,FB0_A};
						VDP1_RD <= 1;
						VDP1_FB0_RPEND <= 0; 
						vdp1_state <= 2'd1;
					end else if (VDP1_FB0_WPEND && !VDP1_WE) begin
						if (!vdp1fb_busy) begin
							VDP1_A <= {1'b0,FB0_A};
							VDP1_D <= VDP1_FB0_D;
							VDP1_WE <= VDP1_FB0_WPEND;
							VDP1_FB0_WPEND <= '0;
							VDP1_FB0_BUSY <= 0;
							vdp1_state <= 2'd0;
						end
					end else if ((VDP1_FB1_RD && FB1_EXT_SEL) || VDP1_FB1_RPEND) begin
						VDP1_A <= {1'b1,FB1_A};
						VDP1_RD <= 1;
						VDP1_FB1_RPEND <= 0; 
						vdp1_state <= 2'd2;
					end else if (VDP1_FB1_WPEND && !VDP1_WE) begin
						if (!vdp1fb_busy) begin
							VDP1_A <= {1'b1,FB1_A};
							VDP1_D <= VDP1_FB1_D;
							VDP1_WE <= VDP1_FB1_WPEND;
							VDP1_FB1_WPEND <= '0;
							VDP1_FB1_BUSY <= 0;
							vdp1_state <= 2'd0;
						end
					end
				end
				
				2'd1: begin
					if (!vdp1fb_busy && !VDP1_RD) begin
						FB0_EXT_Q <= vdp1fb_do;
						VDP1_FB0_BUSY <= 0;
						vdp1_state <= 2'd0;
					end
				end
				
				2'd2: begin
					if (!vdp1fb_busy && !VDP1_RD) begin
						FB1_EXT_Q <= vdp1fb_do;
						VDP1_FB1_BUSY <= 0;
						vdp1_state <= 2'd0;
					end
				end
				
				default:;
			endcase
		end
	end
	assign VDP1_FB_RDY = ~(VDP1_FB0_BUSY | VDP1_FB1_BUSY);
`else
	wire [24:1] VDP1_A = '0;
	wire [15:0] VDP1_D = '0;
	wire [ 1:0] VDP1_WE = '0;
	wire        VDP1_RD = 0;
	
	assign FB0_EXT_Q = '0;
	assign FB1_EXT_Q = '0;
	assign VDP1_FB_RDY = 1;
`endif
`endif

/////////////////////////  BRAM SAVE/LOAD  /////////////////////////////
	wire downloading = save_download;
	wire bk_cart    = cart_type == 3'h4;
	wire bk_change  = (~SRAM_CS_N & ~MEM_DQM_N[0]) | (CART_MEM_WE[0] & bk_cart);
	wire bk_load    = status[24];
	wire bk_save    = status[25];
	wire autosave   = status[26];

	reg bk_ena = 0;
	reg sav_pending = 0;
	always @(posedge clk_sys) begin
		reg old_downloading = 0;
		reg old_change = 0;

		old_downloading <= downloading;
		if(downloading && !old_downloading) bk_ena <= 0;

		//Save file always mounted in the end of downloading state.
		if(downloading && img_mounted && !img_readonly) bk_ena <= 1;

		old_change <= bk_change;
		if (bk_change && !old_change) sav_pending <= 1;
		else if (bk_state) sav_pending <= 0;
	end

	wire bk_save_a  = autosave & OSD_STATUS;
	reg  bk_loading = 0;
	reg  bk_state   = 0;
	//reg  bk_reload  = 0;
	wire [11:0] last_block = {bk_cart,11'h07F};

	always @(posedge clk_sys) begin
		reg old_downloading = 0;
		reg old_load = 0, old_save = 0, old_save_a = 0, old_ack;
		reg [1:0] state;

		old_downloading <= downloading;

		old_load   <= bk_load;
		old_save   <= bk_save;
		old_save_a <= bk_save_a;
		old_ack    <= sd_ack;

		if(sd_ack && !old_ack) {sd_rd, sd_wr} <= 0;

		if (!bk_state) begin
			tmpram_tx_start <= 0;
			state <= 0;
			sd_lba <= 0;
	//		bk_reload <= 0;
			bk_loading <= 0;
			if (bk_ena && ((bk_load && !old_load) | (bk_save && !old_save) | (bk_save_a && !old_save_a && sav_pending))) begin
				bk_state <= 1;
				bk_loading <= bk_load;
	//			bk_reload <= bk_load;
				sd_rd <=  bk_load;
				sd_wr <= 0;
			end
			if (old_downloading && !bios_download && !cart_download && bk_ena) begin
				bk_state <= 1;
				bk_loading <= 1;
				sd_rd <= 1;
				sd_wr <= 0;
			end
		end
		else begin
			if (bk_loading) begin
				case(state)
					0: begin
							sd_rd <= 1;
							state <= 1;
						end
					1: if (!sd_ack && old_ack) begin
							tmpram_tx_start <= 1;
							state <= 2;
						end
					2: if(tmpram_tx_finish) begin
							tmpram_tx_start <= 0;
							state <= 0;
							sd_lba <= sd_lba + 1'd1;
							if (sd_lba[11:0] == last_block) bk_state <= 0;
						end
				endcase
			end
			else begin
				case(state)
					0: begin
							tmpram_tx_start <= 1;
							state <= 1;
						end
					1: if (tmpram_tx_finish) begin
							tmpram_tx_start <= 0;
							sd_wr <= 1;
							state <= 2;
						end
					2: if (!sd_ack && old_ack) begin
							state <= 0;
							sd_lba <= sd_lba + 1'd1;
							if (sd_lba[11:0] == last_block) bk_state <= 0;
						end
				endcase
			end
		end
	end

	wire [15:0] tmpram_dout;
	wire [15:0] tmpram_din = {bsram_do[7:0],bsram_do[15:8]};
	wire        tmpram_busy = bsram_busy;

	wire [15:0] tmpram_sd_buff_q;
	dpram_dif #(8,16,8,16) tmpram
	(
		.clock(clk_sys),

		.address_a(tmpram_addr),
		.wren_a(~bk_loading & tmpram_req & ~tmpram_busy),
		.data_a(tmpram_din),
		.q_a(tmpram_dout),

		.address_b(sd_buff_addr),
		.wren_b(sd_buff_wr & sd_ack /*& |sd_lba[10:4]*/),
		.data_b(sd_buff_dout),
		.q_b(tmpram_sd_buff_q)
	);

	//reg [10:0] tmpram_lba;
	reg  [8:1] tmpram_addr;
	reg tmpram_tx_start;
	reg tmpram_tx_finish;
	reg tmpram_req;
	always @(posedge clk_sys) begin
		reg state;

	//	tmpram_lba <= sd_lba[10:0] - 11'h10;
		
		if (tmpram_req && !tmpram_busy) tmpram_req <= 0;

		if (~tmpram_tx_start) {tmpram_addr, state, tmpram_tx_finish} <= '0;
		else if (~tmpram_tx_finish) begin
			if (!state) begin
				tmpram_req <= 1;
				state <= 1;
			end
			else if (tmpram_req && !tmpram_busy) begin
				state <= 0;
				if (~&tmpram_addr) tmpram_addr <= tmpram_addr + 1'd1;
				else tmpram_tx_finish <= 1;
			end
		end
	end

	assign sd_buff_din = tmpram_sd_buff_q; 

	
/////////////////////////  Video  /////////////////////////////
	wire PAL = (area_code >= 4'hA);//status[7];
	
	reg new_vmode;
	always @(posedge clk_sys) begin
		reg old_pal;
		int to;
		
		if(!rst_sys) begin
			old_pal <= PAL;
			if(old_pal != PAL) to <= 5000000;
		end
		else to <= 5000000;
		
		if(to) begin
			to <= to - 1;
			if(to == 1) new_vmode <= ~new_vmode;
		end
	end
	
	assign VGA_F1 = FIELD & ~status[29];
	
	//lock resolution for the whole frame.
	reg [3:0] res = 4'b0000;
	always @(posedge clk_sys) begin
		reg old_vbl;
		
		old_vbl <= VBL_N;
		if(old_vbl & ~VBL_N) res <= {VRES,HRES};
	end
	
//`ifndef DEBUG
	wire [2:0] scale = status[3:1];
	wire [2:0] sl = scale ? scale - 1'd1 : 3'd0;
//	wire scandoubler = ~INTERLACE & (|scale | forced_scandoubler);
//	wire hq2x = (scale == 1);
//`else
//	wire [2:0] sl = '0;
	wire scandoubler = 0;
	wire hq2x = 0;
//`endif

	assign CLK_VIDEO = clk_sys;
	assign VGA_SL = {~INTERLACE,~INTERLACE} & sl[1:0];

	video_mixer #(.LINE_LENGTH((352*2)+8), .HALF_DEPTH(0), .GAMMA(1)) video_mixer
	(
		.*,
	
		.ce_pix(DCLK),	
		.scandoubler(scandoubler),
		.hq2x(hq2x),	
		.freeze_sync(),
	
		.R((lg_target && gun_mode && (~&status[44:43])) ? {8{lg_target[0]}} : R),
		.G((lg_target && gun_mode && (~&status[44:43])) ? {8{lg_target[1]}} : G),
		.B((lg_target && gun_mode && (~&status[44:43])) ? {8{lg_target[2]}} : B),
	
		// Positive pulses.
		.HSync(~HS_N),
		.VSync(~VS_N),
		.HBlank(~HBL_N),
		.VBlank(~VBL_N)
	);


	//debug
	reg  [ 7: 0] SCRN_EN = 8'b11111111;
	reg  [ 2: 0] SND_EN = 3'b111;
	reg  [31: 0] SLOT_EN = '1;
	reg          DBG_PAUSE = 0;
	reg          DBG_BREAK = 0;
	reg          DBG_RUN = 0;
	
	reg  [ 7: 0] DBG_EXT = '0;
	
	wire         pressed = ps2_key[9];
	wire [ 8: 0] code    = ps2_key[8:0];
	always @(posedge clk_sys) begin
		reg old_state = 0;
	
		DBG_RUN <= 0;
		DBG_EXT <= '0;
		
		old_state <= ps2_key[10];
		if((ps2_key[10] != old_state) && pressed) begin
			casex(code)
`ifdef DEBUG
				'h005: begin SCRN_EN[0] <= ~SCRN_EN[0]; end 	// F1
				'h006: begin SCRN_EN[1] <= ~SCRN_EN[1]; end 	// F2
				'h004: begin SCRN_EN[2] <= ~SCRN_EN[2]; end 	// F3
				'h00C: begin SCRN_EN[3] <= ~SCRN_EN[3]; end 	// F4
				'h003: begin SCRN_EN[4] <= ~SCRN_EN[4]; end 	// F5
				'h00B: begin SCRN_EN[5] <= ~SCRN_EN[5]; end 	// F6
				'h083: begin SCRN_EN[6] <= ~SCRN_EN[6]; end 	// F7
				'h00A: begin SCRN_EN[7] <= ~SCRN_EN[7];
				             SND_EN[0] <= ~SND_EN[0]; end 	// F8
				'h001: begin SND_EN[1] <= ~SND_EN[1]; end 	// F9
				'h009: begin SND_EN[2] <= ~SND_EN[2]; end 	// F10
				'h078: begin SCRN_EN <= '1; SND_EN <= '1; DBG_EXT <= '0; end 	// F11
//				'h009: begin DBG_BREAK <= ~DBG_BREAK; end 	// F10
//				'h078: begin DBG_RUN <= 1; end 	// F11
				'h177: begin DBG_PAUSE <= ~DBG_PAUSE; end 	// Pause
`endif
				default:;
			endcase
		end
		
		if(/*(ps2_key[10] != old_state) &&*/ pressed) begin
			casex(code)
`ifdef DEBUG
				'h016: begin DBG_EXT[0] <= 1/*~DBG_EXT[0]*/; end 	// 1
				'h01E: begin DBG_EXT[1] <= 1/*~DBG_EXT[1]*/; end 	// 2
				'h026: begin DBG_EXT[2] <= 1/*~DBG_EXT[2]*/; end 	// 3
				'h025: begin DBG_EXT[3] <= 1/*~DBG_EXT[3]*/; end 	// 4
				'h02E: begin DBG_EXT[4] <= 1/*~DBG_EXT[4]*/; end 	// 5
				'h036: begin DBG_EXT[5] <= 1/*~DBG_EXT[5]*/; end 	// 6
				'h03D: begin DBG_EXT[6] <= 1/*~DBG_EXT[6]*/; end 	// 7
				'h03E: begin DBG_EXT[7] <= 1/*~DBG_EXT[7]*/; end 	// 8
`endif
				default:;
			endcase
		end
	end
	
	
	reg  [7:0] SCRN_EN2 = 8'b11111111;
	reg  [2:0] SND_EN2 = 3'b111;
`ifdef DEBUG
	assign SLOT_EN = {~status[31:28],~status[63:36]};
`else
	assign SCRN_EN2 = ~status[42:36];
	assign SND_EN2 = ~status[45:43];
`endif

endmodule

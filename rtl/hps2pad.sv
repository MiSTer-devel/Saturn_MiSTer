module HPS2PAD (
	input              CLK,
	input              RST_N,
	input              SMPC_CE,
	
	output     [ 6: 0] PDR1I,
	input      [ 6: 0] PDR1O,
	input      [ 6: 0] DDR1,
	output     [ 6: 0] PDR2I,
	input      [ 6: 0] PDR2O,
	input      [ 6: 0] DDR2,
	
	input      [15: 0] JOY1,
	input      [15: 0] JOY2,

   input      [ 7: 0] JOY1_X1,
   input      [ 7: 0] JOY1_Y1,
   input      [ 7: 0] JOY1_X2,
   input      [ 7: 0] JOY1_Y2,
   input      [ 7: 0] JOY2_X1,
   input      [ 7: 0] JOY2_Y1,
   input      [ 7: 0] JOY2_X2,
   input      [ 7: 0] JOY2_Y2,

   input      [ 3: 0] JOY1_TYPE,
   input      [ 3: 0] JOY2_TYPE,

   input      [24: 0] MOUSE,
   input      [15: 0] MOUSE_EXT,
   input      [10: 0] PS2_KEY,
   output     [ 2: 0] PS2_LED,
	
   input              LGUN_P1_TRIG,
   input              LGUN_P1_START,
   input              LGUN_P1_SENSOR,
   
   input              LGUN_P2_TRIG,
   input              LGUN_P2_START,
   input              LGUN_P2_SENSOR
);

  //joypad mouse
	parameter PAD_MOUSE_DEAD_ZONE = 7;

	wire [3:0] mouse_flags;
	wire [3:0] mouse_buttons;
	wire [7:0] mouse_x;
	wire [7:0] mouse_y;

	// reset ps2 mouse delta accumulators after completed read by saturn (PAD_MOUSE STATE == 10)
	wire reset_acc = (JOY1_TYPE == PAD_MOUSE && STATE1 == 5'd10) || (JOY2_TYPE == PAD_MOUSE && STATE2 == 5'd10);

	ps2_mouse ps2mouse
	(
		.clk(CLK),
		.ce(SMPC_CE),
		.reset(~RST_N),
		.reset_acc(reset_acc),

		.ps2_mouse(MOUSE),
		.ps2_mouse_ext(MOUSE_EXT),

		.flags(mouse_flags),
		.buttons(mouse_buttons),
		.x(mouse_x),
		.y(mouse_y)
	);


	// scale joypad analog to 37.5%. Default is way too sensitive
	wire signed [7:0] p1_mjx =  (($signed(JOY1_X1) >>> $signed(2)) + ($signed(JOY1_X1) >>> $signed(3)));
	wire signed [7:0] p1_mjy = -(($signed(JOY1_Y1) >>> $signed(2)) + ($signed(JOY1_Y1) >>> $signed(3)));
	// add a little deadzone around neutral on joypad analog
	wire [7:0] p1_mjx_dz = ($signed(p1_mjx) > $signed(PAD_MOUSE_DEAD_ZONE) || $signed(p1_mjx) < $signed(-PAD_MOUSE_DEAD_ZONE)) ? p1_mjx : '0;
	wire [7:0] p1_mjy_dz = ($signed(p1_mjy) > $signed(PAD_MOUSE_DEAD_ZONE) || $signed(p1_mjy) < $signed(-PAD_MOUSE_DEAD_ZONE)) ? p1_mjy : '0;

	// scale joypad analog to 37.5%. Default is way too sensitive
	wire signed [7:0] p2_mjx =  (($signed(JOY2_X1) >>> $signed(2)) + ($signed(JOY2_X1) >>> $signed(3)));
	wire signed [7:0] p2_mjy = -(($signed(JOY2_Y1) >>> $signed(2)) + ($signed(JOY2_Y1) >>> $signed(3)));
	// add a little deadzone around neutral on joypad analog
	wire [7:0] p2_mjx_dz = ($signed(p2_mjx) > $signed(PAD_MOUSE_DEAD_ZONE) || $signed(p2_mjx) < $signed(-PAD_MOUSE_DEAD_ZONE)) ? p2_mjx : '0;
	wire [7:0] p2_mjy_dz = ($signed(p2_mjy) > $signed(PAD_MOUSE_DEAD_ZONE) || $signed(p2_mjy) < $signed(-PAD_MOUSE_DEAD_ZONE)) ? p2_mjy : '0;

	// merge ps2 mouse with p1 joypad mouse
	wire [3:0] p1_m_flags   = mouse_flags | {2'b0,p1_mjy_dz[7],p1_mjx_dz[7]};
	wire [3:0] p1_m_buttons = mouse_buttons | ~JOY1[11: 8];
	wire [7:0] p1_m_x       = mouse_x | p1_mjx_dz;
	wire [7:0] p1_m_y       = mouse_y | p1_mjy_dz;

	// merge ps2 mouse with p2 joypad mouse
	wire [3:0] p2_m_flags   = mouse_flags | {2'b0,p2_mjy_dz[7],p2_mjx_dz[7]};
	wire [3:0] p2_m_buttons = mouse_buttons | ~JOY2[11: 8];
	wire [7:0] p2_m_x       = mouse_x | p2_mjx_dz;
	wire [7:0] p2_m_y       = mouse_y | p2_mjy_dz;

	parameter PAD_DIGITAL     = 0;
	parameter PAD_VIRT_LGUN   = 1;
	parameter PAD_WHEEL       = 2;
	parameter PAD_MISSION     = 3;
	parameter PAD_3D          = 4;
	parameter PAD_DUALMISSION = 5;
	parameter PAD_MOUSE       = 6;
	parameter PAD_KEYBOARD    = 7;
	parameter PAD_OFF         = 8;

	// Keyboard
	wire  [ 2:0] kbd_led;
	wire  [ 3:0] kbd_nib_dpad;
	wire  [ 3:0] kbd_nib_start_abc;
	wire  [ 3:0] kbd_nib_rxyz;
	wire  [ 3:0] kbd_nib_lxxx;
	wire         kbd_ev_valid;
	wire         kbd_ev_make;
	wire  [ 7:0] kbd_ev_sc;
	logic        kbd_ev_pop;
	logic        kbd_pkt_ev_valid;
	logic        kbd_pkt_ev_make;
	logic [ 7:0] kbd_pkt_ev_sc;
	wire         kbd_p1_req = (JOY1_TYPE == PAD_KEYBOARD);
	wire         kbd_p2_req = (JOY2_TYPE == PAD_KEYBOARD);
	wire         kbd_sel_p1 = kbd_p1_req;
	wire         kbd_sel_p2 = kbd_p2_req & ~kbd_p1_req;
	wire         kbd_ena    = kbd_sel_p1 | kbd_sel_p2;

	wire  [ 6:0] kbd_port_o = kbd_sel_p2 ? PDR2O : PDR1O;
	wire  [ 6:0] kbd_port_d = kbd_sel_p2 ? DDR2  : DDR1;
	wire         kbd_tr = kbd_port_o[5];
	wire         kbd_th = kbd_port_o[6];
	wire         kbd_idle_cmd = kbd_tr & kbd_th;
	wire         kbd_cfg_ok = (kbd_port_d[6:5] == 2'b11);
	wire         kbd_id_ok  = (kbd_port_d[6:5] == 2'b10);
	wire         kbd_active    = kbd_ena & kbd_cfg_ok;
	wire         kbd_id_active = kbd_ena & kbd_id_ok;

	logic        kbd_tr_d;
	logic        kbd_in_packet;
	logic        kbd_id2_done;
	logic [ 3:0] kbd_nib_idx;
	logic [ 3:0] kbd_nibble;
	wire         kbd_tl = kbd_tr;

	wire  [ 6:0] kbd_port_id_i  = {2'b11, 1'b1, 4'h1};
	wire  [ 6:0] kbd_port_kbd_i = {2'b11, kbd_tl, kbd_nibble};
	wire  [ 6:0] kbd_port_i = kbd_id_active ? kbd_port_id_i : kbd_port_kbd_i;

	assign PS2_LED = kbd_ena ? kbd_led : 3'b000;

	ps2keyboard keyboard (
		.clk(CLK),
		.reset(~RST_N),
		.enable(kbd_ena),
		.ps2_key(PS2_KEY),
		.ps2_led(kbd_led),
		.nib_dpad(kbd_nib_dpad),
		.nib_start_abc(kbd_nib_start_abc),
		.nib_rxyz(kbd_nib_rxyz),
		.nib_lxxx(kbd_nib_lxxx),
		.ev_valid(kbd_ev_valid),
		.ev_make(kbd_ev_make),
		.ev_sc(kbd_ev_sc),
		.ev_pop(kbd_ev_pop)
	);
	
	bit [ 3: 0] OUT1,OUT2;
	bit         TL1,TL2;
	bit [ 4: 0]  STATE1,STATE2;
	always @(posedge CLK or negedge RST_N) begin
		
		if (!RST_N) begin
			STATE1 <= '0;
			STATE2 <= '0;
			OUT1 <= '0;
			OUT2 <= '0;
			TL1 <= 1;
			TL2 <= 1;
		end else if (SMPC_CE) begin
			case (JOY1_TYPE)
				PAD_WHEEL: begin
					case (STATE1)
						5'd0,
						5'd1: if (PDR1O[6:5] == 2'b01) begin OUT1 <= 4'h1;                          TL1 <= 1; STATE1 <= 5'd2; end
						5'd2: if (PDR1O[6:5] == 2'b00) begin OUT1 <= 4'h1;                          TL1 <= 0; STATE1 <= 5'd3; end
						5'd3: if (PDR1O[6:5] == 2'b01) begin OUT1 <= 4'h3;                          TL1 <= 1; STATE1 <= 5'd4; end
						5'd4: if (PDR1O[6:5] == 2'b00) begin OUT1 <= JOY1[15:12];                   TL1 <= 0; STATE1 <= 5'd5; end
						5'd5: if (PDR1O[6:5] == 2'b01) begin OUT1 <= JOY1[11: 8];                   TL1 <= 1; STATE1 <= 5'd6; end
						5'd6: if (PDR1O[6:5] == 2'b00) begin OUT1 <= {1'b1,JOY1[ 6: 4]};            TL1 <= 0; STATE1 <= 5'd7; end
						5'd7: if (PDR1O[6:5] == 2'b01) begin OUT1 <= 4'b1111;                       TL1 <= 1; STATE1 <= 5'd8; end
						5'd8: if (PDR1O[6:5] == 2'b00) begin OUT1 <= JOY1_X1[7:4]^4'h8;             TL1 <= 0; STATE1 <= 5'd9; end
						5'd9: if (PDR1O[6:5] == 2'b01) begin OUT1 <= JOY1_X1[3:0];                  TL1 <= 1; STATE1 <= 5'd10; end
					endcase
					if (PDR1O[6:5] == 2'b11) begin OUT1 <= 4'h1; TL1 <= 1; STATE1 <= 5'd0; end
				end
				
				PAD_MOUSE: begin
					case (STATE1)
						5'd0,
						5'd1: if (PDR1O[6:5] == 2'b01) begin OUT1 <= 4'hB;                          TL1 <= 1; STATE1 <= 5'd2; end
						5'd2: if (PDR1O[6:5] == 2'b00) begin OUT1 <= 4'hF;                          TL1 <= 0; STATE1 <= 5'd3; end
						5'd3: if (PDR1O[6:5] == 2'b01) begin OUT1 <= 4'hF;                          TL1 <= 1; STATE1 <= 5'd4; end
						5'd4: if (PDR1O[6:5] == 2'b00) begin OUT1 <= p1_m_flags;                    TL1 <= 0; STATE1 <= 5'd5; end
						5'd5: if (PDR1O[6:5] == 2'b01) begin OUT1 <= p1_m_buttons;                  TL1 <= 1; STATE1 <= 5'd6; end
						5'd6: if (PDR1O[6:5] == 2'b00) begin OUT1 <= p1_m_x[7:4];                   TL1 <= 0; STATE1 <= 5'd7; end
						5'd7: if (PDR1O[6:5] == 2'b01) begin OUT1 <= p1_m_x[3:0];                   TL1 <= 1; STATE1 <= 5'd8; end
						5'd8: if (PDR1O[6:5] == 2'b00) begin OUT1 <= p1_m_y[7:4];                   TL1 <= 0; STATE1 <= 5'd9; end
						5'd9: if (PDR1O[6:5] == 2'b01) begin OUT1 <= p1_m_y[3:0];                   TL1 <= 1; STATE1 <= 5'd10; end
					endcase
					if (PDR1O[6:5] == 2'b11) begin OUT1 <= 4'h0; TL1 <= 1; STATE1 <= 5'd0; end
				end
				
				PAD_MISSION,
				PAD_3D: begin
					case (STATE1)
						5'd00,
						5'd01: if (PDR1O[6:5] == 2'b01) begin OUT1 <= 4'h1;                          TL1 <= 1; STATE1 <= 5'd2; end
						5'd02: if (PDR1O[6:5] == 2'b00) begin OUT1 <= 4'h1;                          TL1 <= 0; STATE1 <= 5'd3; end
						5'd03: if (PDR1O[6:5] == 2'b01) begin OUT1 <= JOY1_TYPE == PAD_3D ? 4'h6 : 
						                                              4'h5;                          TL1 <= 1; STATE1 <= 5'd4; end
						5'd04: if (PDR1O[6:5] == 2'b00) begin OUT1 <= JOY1[15:12];                   TL1 <= 0; STATE1 <= 5'd5; end
						5'd05: if (PDR1O[6:5] == 2'b01) begin OUT1 <= JOY1[11: 8];                   TL1 <= 1; STATE1 <= 5'd6; end
						5'd06: if (PDR1O[6:5] == 2'b00) begin OUT1 <= JOY1[ 7: 4];                   TL1 <= 0; STATE1 <= 5'd7; end
						5'd07: if (PDR1O[6:5] == 2'b01) begin OUT1 <= JOY1[ 3: 0];                   TL1 <= 1; STATE1 <= 5'd8; end
						5'd08: if (PDR1O[6:5] == 2'b00) begin OUT1 <= JOY1_X1[7:4]^4'h8;             TL1 <= 0; STATE1 <= 5'd9; end
						5'd09: if (PDR1O[6:5] == 2'b01) begin OUT1 <= JOY1_X1[3:0];                  TL1 <= 1; STATE1 <= 5'd10; end
						5'd10: if (PDR1O[6:5] == 2'b00) begin OUT1 <= JOY1_Y1[7:4]^4'h8;             TL1 <= 0; STATE1 <= 5'd11; end
						5'd11: if (PDR1O[6:5] == 2'b01) begin OUT1 <= JOY1_Y1[3:0];                  TL1 <= 1; STATE1 <= 5'd12; end
						5'd12: if (PDR1O[6:5] == 2'b00) begin OUT1 <= 4'h0/*JOY1_Z1[7:4]^4'h8*/;           TL1 <= 0; STATE1 <= 5'd13; end
						5'd13: if (PDR1O[6:5] == 2'b01) begin OUT1 <= 4'h0/*JOY1_Z1[3:0]*/;                TL1 <= 1; STATE1 <= 5'd14; end
						5'd14: if (JOY1_TYPE == PAD_3D &&
						           PDR1O[6:5] == 2'b00) begin OUT1 <= 4'h0/*JOY1_Z2[7:4]^4'h8*/;           TL1 <= 0; STATE1 <= 5'd15; end
						5'd15: if (PDR1O[6:5] == 2'b01) begin OUT1 <= 4'h1/*JOY1_Z2[3:0]*/;                TL1 <= 1; STATE1 <= 5'd16; end
					endcase
					if (PDR1O[6:5] == 2'b11) begin OUT1 <= 4'h1; TL1 <= 1; STATE1 <= 5'd0; end
				end
				
				PAD_DUALMISSION: begin
					case (STATE1)
						5'd00,
						5'd01: if (PDR1O[6:5] == 2'b01) begin OUT1 <= 4'h1;                          TL1 <= 1; STATE1 <= 5'd2; end
						5'd02: if (PDR1O[6:5] == 2'b00) begin OUT1 <= 4'h1;                          TL1 <= 0; STATE1 <= 5'd3; end
						5'd03: if (PDR1O[6:5] == 2'b01) begin OUT1 <= 4'h9;                          TL1 <= 1; STATE1 <= 5'd4; end
						5'd04: if (PDR1O[6:5] == 2'b00) begin OUT1 <= JOY1[15:12];                   TL1 <= 0; STATE1 <= 5'd5; end
						5'd05: if (PDR1O[6:5] == 2'b01) begin OUT1 <= JOY1[11: 8];                   TL1 <= 1; STATE1 <= 5'd6; end
						5'd06: if (PDR1O[6:5] == 2'b00) begin OUT1 <= JOY1[ 7: 4];                   TL1 <= 0; STATE1 <= 5'd7; end
						5'd07: if (PDR1O[6:5] == 2'b01) begin OUT1 <= JOY1[ 3: 0];                   TL1 <= 1; STATE1 <= 5'd8; end
						5'd08: if (PDR1O[6:5] == 2'b00) begin OUT1 <= JOY1_X1[7:4]^4'h8;             TL1 <= 0; STATE1 <= 5'd9; end
						5'd09: if (PDR1O[6:5] == 2'b01) begin OUT1 <= JOY1_X1[3:0];                  TL1 <= 1; STATE1 <= 5'd10; end
						5'd10: if (PDR1O[6:5] == 2'b00) begin OUT1 <= JOY1_Y1[7:4]^4'h8;             TL1 <= 0; STATE1 <= 5'd11; end
						5'd11: if (PDR1O[6:5] == 2'b01) begin OUT1 <= JOY1_Y1[3:0];                  TL1 <= 1; STATE1 <= 5'd12; end
						5'd12: if (PDR1O[6:5] == 2'b00) begin OUT1 <= 4'h0/*JOY1_Z1[7:4]^4'h8*/;     TL1 <= 0; STATE1 <= 5'd13; end
						5'd13: if (PDR1O[6:5] == 2'b01) begin OUT1 <= 4'h0/*JOY1_Z1[3:0]*/;          TL1 <= 1; STATE1 <= 5'd14; end
						5'd14: if (PDR1O[6:5] == 2'b00) begin OUT1 <= 4'hF;                          TL1 <= 0; STATE1 <= 5'd15; end
						5'd15: if (PDR1O[6:5] == 2'b01) begin OUT1 <= 4'hF;                          TL1 <= 1; STATE1 <= 5'd16; end
						5'd16: if (PDR1O[6:5] == 2'b00) begin OUT1 <= JOY1_X2[7:4]^4'h8;             TL1 <= 0; STATE1 <= 5'd17; end
						5'd17: if (PDR1O[6:5] == 2'b01) begin OUT1 <= JOY1_X2[3:0];                  TL1 <= 1; STATE1 <= 5'd18; end
						5'd18: if (PDR1O[6:5] == 2'b00) begin OUT1 <= JOY1_Y2[7:4]^4'h8;             TL1 <= 0; STATE1 <= 5'd19; end
						5'd19: if (PDR1O[6:5] == 2'b01) begin OUT1 <= JOY1_Y2[3:0];                  TL1 <= 1; STATE1 <= 5'd20; end
						5'd20: if (PDR1O[6:5] == 2'b00) begin OUT1 <= 4'h0/*JOY1_Z2[7:4]^4'h8*/;     TL1 <= 0; STATE1 <= 5'd21; end
						5'd21: if (PDR1O[6:5] == 2'b01) begin OUT1 <= 4'h0/*JOY1_Z2[3:0]*/;          TL1 <= 1; STATE1 <= 5'd22; end
					endcase
					if (PDR1O[6:5] == 2'b11) begin OUT1 <= 4'h1; TL1 <= 1; STATE1 <= 5'd0; end
				end
				
				default: ;
			endcase
			
			case (JOY2_TYPE)
				PAD_WHEEL: begin
					case (STATE2)
						5'd0,
						5'd1: if (PDR2O[6:5] == 2'b01) begin OUT2 <= 4'h1;                          TL2 <= 1; STATE2 <= 5'd2; end
						5'd2: if (PDR2O[6:5] == 2'b00) begin OUT2 <= 4'h1;                          TL2 <= 0; STATE2 <= 5'd3; end
						5'd3: if (PDR2O[6:5] == 2'b01) begin OUT2 <= 4'h3;                          TL2 <= 1; STATE2 <= 5'd4; end
						5'd4: if (PDR2O[6:5] == 2'b00) begin OUT2 <= JOY2[15:12];                   TL2 <= 0; STATE2 <= 5'd5; end
						5'd5: if (PDR2O[6:5] == 2'b01) begin OUT2 <= JOY2[11: 8];                   TL2 <= 1; STATE2 <= 5'd6; end
						5'd6: if (PDR2O[6:5] == 2'b00) begin OUT2 <= {1'b1,JOY2[ 6: 4]};            TL2 <= 0; STATE2 <= 5'd7; end
						5'd7: if (PDR2O[6:5] == 2'b01) begin OUT2 <= 4'b1111;                       TL2 <= 1; STATE2 <= 5'd8; end
						5'd8: if (PDR2O[6:5] == 2'b00) begin OUT2 <= JOY2_X1[7:4]^4'h8;             TL2 <= 0; STATE2 <= 5'd9; end
						5'd9: if (PDR2O[6:5] == 2'b01) begin OUT2 <= JOY2_X1[3:0];                  TL2 <= 1; STATE2 <= 5'd10; end
					endcase
					if (PDR2O[6:5] == 2'b11) begin OUT2 <= 4'h1; TL2 <= 1; STATE2 <= 5'd0; end
				end
				
				PAD_MOUSE: begin
					case (STATE2)
						5'd0,
						5'd1: if (PDR2O[6:5] == 2'b01) begin OUT2 <= 4'hB;                          TL2 <= 1; STATE2 <= 5'd2; end
						5'd2: if (PDR2O[6:5] == 2'b00) begin OUT2 <= 4'hF;                          TL2 <= 0; STATE2 <= 5'd3; end
						5'd3: if (PDR2O[6:5] == 2'b01) begin OUT2 <= 4'hF;                          TL2 <= 1; STATE2 <= 5'd4; end
						5'd4: if (PDR2O[6:5] == 2'b00) begin OUT2 <= p2_m_flags;                    TL2 <= 0; STATE2 <= 5'd5; end
						5'd5: if (PDR2O[6:5] == 2'b01) begin OUT2 <= p2_m_buttons;                  TL2 <= 1; STATE2 <= 5'd6; end
						5'd6: if (PDR2O[6:5] == 2'b00) begin OUT2 <= p2_m_x[7:4];                   TL2 <= 0; STATE2 <= 5'd7; end
						5'd7: if (PDR2O[6:5] == 2'b01) begin OUT2 <= p2_m_x[3:0];                   TL2 <= 1; STATE2 <= 5'd8; end
						5'd8: if (PDR2O[6:5] == 2'b00) begin OUT2 <= p2_m_y[7:4];                   TL2 <= 0; STATE2 <= 5'd9; end
						5'd9: if (PDR2O[6:5] == 2'b01) begin OUT2 <= p2_m_y[3:0];                   TL2 <= 1; STATE2 <= 5'd10; end
					endcase
					if (PDR2O[6:5] == 2'b11) begin OUT2 <= 4'h0; TL2 <= 1; STATE2 <= 5'd0; end
				end
				
				PAD_MISSION,
				PAD_3D: begin
					case (STATE2)
						5'd00,
						5'd01: if (PDR2O[6:5] == 2'b01) begin OUT2 <= 4'h1;                          TL2 <= 1; STATE2 <= 5'd2; end
						5'd02: if (PDR2O[6:5] == 2'b00) begin OUT2 <= 4'h1;                          TL2 <= 0; STATE2 <= 5'd3; end
						5'd03: if (PDR2O[6:5] == 2'b01) begin OUT2 <= JOY2_TYPE == PAD_3D ? 4'h6 : 
						                                              4'h5;                          TL2 <= 1; STATE2 <= 5'd4; end
						5'd04: if (PDR2O[6:5] == 2'b00) begin OUT2 <= JOY2[15:12];                   TL2 <= 0; STATE2 <= 5'd5; end
						5'd05: if (PDR2O[6:5] == 2'b01) begin OUT2 <= JOY2[11: 8];                   TL2 <= 1; STATE2 <= 5'd6; end
						5'd06: if (PDR2O[6:5] == 2'b00) begin OUT2 <= JOY2[ 7: 4];                   TL2 <= 0; STATE2 <= 5'd7; end
						5'd07: if (PDR2O[6:5] == 2'b01) begin OUT2 <= JOY2[ 3: 0];                   TL2 <= 1; STATE2 <= 5'd8; end
						5'd08: if (PDR2O[6:5] == 2'b00) begin OUT2 <= JOY2_X1[7:4]^4'h8;             TL2 <= 0; STATE2 <= 5'd9; end
						5'd09: if (PDR2O[6:5] == 2'b01) begin OUT2 <= JOY2_X1[3:0];                  TL2 <= 1; STATE2 <= 5'd10; end
						5'd10: if (PDR2O[6:5] == 2'b00) begin OUT2 <= JOY2_Y1[7:4]^4'h8;             TL2 <= 0; STATE2 <= 5'd11; end
						5'd11: if (PDR2O[6:5] == 2'b01) begin OUT2 <= JOY2_Y1[3:0];                  TL2 <= 1; STATE2 <= 5'd12; end
						5'd12: if (PDR2O[6:5] == 2'b00) begin OUT2 <= 4'h0/*JOY2_Z1[7:4]^4'h8*/;           TL2 <= 0; STATE2 <= 5'd13; end
						5'd13: if (PDR2O[6:5] == 2'b01) begin OUT2 <= 4'h0/*JOY2_Z1[3:0]*/;                TL2 <= 1; STATE2 <= 5'd14; end
						5'd14: if (JOY2_TYPE == PAD_3D &&
						           PDR2O[6:5] == 2'b00) begin OUT2 <= 4'h0/*JOY2_Z2[7:4]^4'h8*/;           TL2 <= 0; STATE2 <= 5'd15; end
						5'd15: if (PDR2O[6:5] == 2'b01) begin OUT2 <= 4'h1/*JOY2_Z2[3:0]*/;                TL2 <= 1; STATE2 <= 5'd16; end
					endcase
					if (PDR2O[6:5] == 2'b11) begin OUT2 <= 4'h1; TL2 <= 1; STATE2 <= 5'd0; end
				end
				
				PAD_DUALMISSION: begin
					case (STATE2)
						5'd00,
						5'd01: if (PDR2O[6:5] == 2'b01) begin OUT2 <= 4'h1;                          TL2 <= 1; STATE2 <= 5'd2; end
						5'd02: if (PDR2O[6:5] == 2'b00) begin OUT2 <= 4'h1;                          TL2 <= 0; STATE2 <= 5'd3; end
						5'd03: if (PDR2O[6:5] == 2'b01) begin OUT2 <= 4'h9;                          TL2 <= 1; STATE2 <= 5'd4; end
						5'd04: if (PDR2O[6:5] == 2'b00) begin OUT2 <= JOY2[15:12];                   TL2 <= 0; STATE2 <= 5'd5; end
						5'd05: if (PDR2O[6:5] == 2'b01) begin OUT2 <= JOY2[11: 8];                   TL2 <= 1; STATE2 <= 5'd6; end
						5'd06: if (PDR2O[6:5] == 2'b00) begin OUT2 <= JOY2[ 7: 4];                   TL2 <= 0; STATE2 <= 5'd7; end
						5'd07: if (PDR2O[6:5] == 2'b01) begin OUT2 <= JOY2[ 3: 0];                   TL2 <= 1; STATE2 <= 5'd8; end
						5'd08: if (PDR2O[6:5] == 2'b00) begin OUT2 <= JOY2_X1[7:4]^4'h8;             TL2 <= 0; STATE2 <= 5'd9; end
						5'd09: if (PDR2O[6:5] == 2'b01) begin OUT2 <= JOY2_X1[3:0];                  TL2 <= 1; STATE2 <= 5'd10; end
						5'd10: if (PDR2O[6:5] == 2'b00) begin OUT2 <= JOY2_Y1[7:4]^4'h8;             TL2 <= 0; STATE2 <= 5'd11; end
						5'd11: if (PDR2O[6:5] == 2'b01) begin OUT2 <= JOY2_Y1[3:0];                  TL2 <= 1; STATE2 <= 5'd12; end
						5'd12: if (PDR2O[6:5] == 2'b00) begin OUT2 <= 4'h0/*JOY2_Z1[7:4]^4'h8*/;     TL2 <= 0; STATE2 <= 5'd13; end
						5'd13: if (PDR2O[6:5] == 2'b01) begin OUT2 <= 4'h0/*JOY2_Z1[3:0]*/;          TL2 <= 1; STATE2 <= 5'd14; end
						5'd14: if (PDR2O[6:5] == 2'b00) begin OUT2 <= 4'hF;                          TL2 <= 0; STATE2 <= 5'd15; end
						5'd15: if (PDR2O[6:5] == 2'b01) begin OUT2 <= 4'hF;                          TL2 <= 1; STATE2 <= 5'd16; end
						5'd16: if (PDR2O[6:5] == 2'b00) begin OUT2 <= JOY2_X2[7:4]^4'h8;             TL2 <= 0; STATE2 <= 5'd17; end
						5'd17: if (PDR2O[6:5] == 2'b01) begin OUT2 <= JOY2_X2[3:0];                  TL2 <= 1; STATE2 <= 5'd18; end
						5'd18: if (PDR2O[6:5] == 2'b00) begin OUT2 <= JOY2_Y2[7:4]^4'h8;             TL2 <= 0; STATE2 <= 5'd19; end
						5'd19: if (PDR2O[6:5] == 2'b01) begin OUT2 <= JOY2_Y2[3:0];                  TL2 <= 1; STATE2 <= 5'd20; end
						5'd20: if (PDR2O[6:5] == 2'b00) begin OUT2 <= 4'h0/*JOY2_Z2[7:4]^4'h8*/;     TL2 <= 0; STATE2 <= 5'd21; end
						5'd21: if (PDR2O[6:5] == 2'b01) begin OUT2 <= 4'h0/*JOY2_Z2[3:0]*/;          TL2 <= 1; STATE2 <= 5'd22; end
					endcase
					if (PDR2O[6:5] == 2'b11) begin OUT2 <= 4'h1; TL2 <= 1; STATE2 <= 5'd0; end
				end
				
				default: ;
			endcase
		end
	end

	always_comb begin
		if(!kbd_in_packet) begin
			if(kbd_active) kbd_nibble = kbd_tr ? 4'h4 : 4'h3;
			else           kbd_nibble = 4'h1;
		end else begin
			case(kbd_nib_idx)
				4'd0:  kbd_nibble = 4'h3;
				4'd1:  kbd_nibble = 4'h4;
				4'd2:  kbd_nibble = kbd_nib_dpad;
				4'd3:  kbd_nibble = kbd_nib_start_abc;
				4'd4:  kbd_nibble = kbd_nib_rxyz;
				4'd5:  kbd_nibble = kbd_nib_lxxx;
				4'd6:  kbd_nibble = {1'b0, kbd_led[0], kbd_led[1], kbd_led[2]};
				4'd7:  kbd_nibble = {(kbd_pkt_ev_valid & kbd_pkt_ev_make), 1'b1, 1'b1, (kbd_pkt_ev_valid & ~kbd_pkt_ev_make)};
				4'd8:  kbd_nibble = kbd_pkt_ev_sc[7:4];
				4'd9:  kbd_nibble = kbd_pkt_ev_sc[3:0];
				4'd10: kbd_nibble = 4'h0;
				4'd11: kbd_nibble = 4'h1;
				default: kbd_nibble = 4'h0;
			endcase
		end
	end

	always_ff @(posedge CLK or negedge RST_N) begin
		if(!RST_N) begin
			kbd_tr_d         <= 1'b1;
			kbd_in_packet    <= 1'b0;
			kbd_id2_done     <= 1'b0;
			kbd_nib_idx      <= 4'd0;
			kbd_pkt_ev_valid <= 1'b0;
			kbd_pkt_ev_make  <= 1'b0;
			kbd_pkt_ev_sc    <= 8'h00;
			kbd_ev_pop       <= 1'b0;
		end else begin
			kbd_ev_pop <= 1'b0;

			if(!kbd_ena) begin
				kbd_tr_d         <= kbd_tr;
				kbd_in_packet    <= 1'b0;
				kbd_id2_done     <= 1'b0;
				kbd_nib_idx      <= 4'd0;
				kbd_pkt_ev_valid <= 1'b0;
				kbd_pkt_ev_make  <= 1'b0;
				kbd_pkt_ev_sc    <= 8'h00;
			end else if(!(kbd_active || kbd_id_active)) begin
				kbd_tr_d      <= kbd_tr;
				kbd_in_packet <= 1'b0;
				kbd_id2_done  <= 1'b0;
				kbd_nib_idx   <= 4'd0;
			end else begin
				if(kbd_idle_cmd) begin
					kbd_in_packet    <= 1'b0;
					kbd_id2_done     <= 1'b0;
					kbd_pkt_ev_valid <= 1'b0;
				end

				if(kbd_tr != kbd_tr_d) begin
					kbd_tr_d    <= kbd_tr;

					if(kbd_in_packet) begin
						if(kbd_nib_idx != 4'd11) kbd_nib_idx <= kbd_nib_idx + 1'd1;
					end else begin
						if(!kbd_id2_done && kbd_tr_d == 1'b0 && kbd_tr == 1'b1) kbd_id2_done <= 1'b1;

						if(kbd_tr_d == 1'b1 && kbd_tr == 1'b0 && !kbd_idle_cmd) begin
							kbd_in_packet <= 1'b1;
							kbd_nib_idx   <= kbd_id2_done ? 4'd2 : 4'd0;

							if(kbd_ev_valid) begin
								kbd_pkt_ev_valid <= 1'b1;
								kbd_pkt_ev_make  <= kbd_ev_make;
								kbd_pkt_ev_sc    <= kbd_ev_sc;
								kbd_ev_pop       <= 1'b1;
							end else begin
								kbd_pkt_ev_valid <= 1'b0;
								kbd_pkt_ev_make  <= 1'b0;
								kbd_pkt_ev_sc    <= 8'h00;
							end
						end
					end
				end
			end
		end
	end

	always_comb begin
		PDR1I = (PDR1O & DDR1) | ~DDR1;
		case (JOY1_TYPE)
			PAD_DIGITAL: begin
				if (DDR1[6:5] == 2'b10) begin
					case (PDR1O[6])
						1'b0:  PDR1I[3:0] = JOY1[15:12];
						1'b1:  PDR1I[3:0] = {JOY1[3],3'b100};
					endcase
				end else if (DDR1[6:5] == 2'b11) begin
					case (PDR1O[6:5])
						2'b00: PDR1I[3:0] = JOY1[ 7: 4];
						2'b01: PDR1I[3:0] = JOY1[15:12];
						2'b10: PDR1I[3:0] = JOY1[11: 8];
						2'b11: PDR1I[3:0] = {JOY1[3],3'b100};
					endcase
				end
			end
			
			// Stunner (LightGun) ID...
			// 
			// The "ID" value is calculated from two nibbles read from the Controller.
			//
			// The 1st nibble with the TH pin set High.
			// The 2nd nibble with the TH pin set Low.
			//
			// 1ST nib (TH Hi): [3:0] = b1100
			// 2ND nib (TH Lo): [3:0] = b1100
			//
			// For simpler controllers like the Light Gun, they simply tied some of the [3:0] pins High or Low,
			// so the state of the TH pin will be completely ignored...
			//
			// Bits [3:2] on the Stunner are tied High (or left floating, with pull-ups on the Saturn.)
			// Bits [1:0] on the Stunner are tied to Ground / Low.
			//
			// The SMPC then does a weird OR'ing of pairs of bits from each nibble, to get the final ID nibble value.
			// (this was probably done as a way to keep backwards-compatibility with simpler MD/Genesis joypads. I don't know?) ElectronAsh.
			//
			// ID[3] = 1ST nib [3 OR 2]
			// ID[2] = 1ST nib [1 OR 0]
			// ID[1] = 2ND nib [3 OR 2]
			// ID[0] = 2ND nib [1 OR 0]
			//
			// The resulting MD_ID nibble (in the SMPC) for the Stunner ends up as 0xA.
			//
			PAD_VIRT_LGUN: begin
				// PDRxI [6]=LGUN_LAT_N. [5]=Start_n. [4]=Trigger_n. [3:0]=ID Nibble?
				PDR1I[6:0] = {!LGUN_P1_SENSOR, !LGUN_P1_START, !LGUN_P1_TRIG ,4'b1100};
			end
			
			PAD_WHEEL,
			PAD_MOUSE,
			PAD_MISSION,
			PAD_3D,
			PAD_DUALMISSION: begin
				PDR1I[4:0] = {TL1,OUT1};
			end

			PAD_KEYBOARD: begin
				if (kbd_sel_p1) PDR1I[4:0] = kbd_port_i[4:0];
			end
			
			//TODO
			default: ;
		endcase
		
		PDR2I = (PDR2O & DDR2) | ~DDR2;
		case (JOY2_TYPE)
			PAD_DIGITAL: begin
				if (DDR2[6:5] == 2'b10) begin
					case (PDR2O[6])
						1'b0:  PDR2I[3:0] = JOY2[15:12];
						1'b1:  PDR2I[3:0] = {JOY2[3],3'b100};
					endcase
				end else if (DDR2[6:5] == 2'b11) begin
					case (PDR2O[6:5])
						2'b00: PDR2I[3:0] = JOY2[ 7: 4];
						2'b01: PDR2I[3:0] = JOY2[15:12];
						2'b10: PDR2I[3:0] = JOY2[11: 8];
						2'b11: PDR2I[3:0] = {JOY2[3],3'b100};
					endcase
				end
			end

			PAD_VIRT_LGUN: begin
				// PDRxI [6]=LGUN_LAT_N. [5]=Start_n. [4]=Trigger_n. [3:0]=ID Nibble (sort of, see above).
				PDR2I[6:0] = {!LGUN_P2_SENSOR, !LGUN_P2_START, !LGUN_P2_TRIG ,4'b1100};
			end
			
			PAD_WHEEL,
			PAD_MOUSE,
			PAD_MISSION,
			PAD_3D,
			PAD_DUALMISSION: begin
				PDR2I[4:0] = {TL2,OUT2};
			end

			PAD_KEYBOARD: begin
				if (kbd_sel_p2) PDR2I[4:0] = kbd_port_i[4:0];
			end
			
			//TODO
			default: ;
		endcase
	end
	
endmodule

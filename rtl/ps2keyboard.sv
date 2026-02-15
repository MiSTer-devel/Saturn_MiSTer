// Saturn Keyboard emulation
//
// Saturn keyboard packet (12 nibbles):
//   0: 0x3
//   1: 0x4
//   2: {Right, Left, Down, Up}
//   3: {Start, A, C, B}
//   4: {R, X, Y, Z}
//   5: {L, 0, 0, 0}
//   6: {0, Caps, Num, Scr}
//   7: {Make, 1, 1, Break}  (0xE make, 0x7 break, 0x6 none)
//   8: scancode[7:4]
//   9: scancode[3:0]
//  10: 0x0
//  11: 0x1
//
// Notes:
// - Many keys are identical to PS/2 set-2 scancodes.
// - Extended (E0) keys are remapped into the Saturn table "assigned new codes".

module ps2keyboard (
  input  logic        clk,
  input  logic        reset,
  input  logic        enable,

  // MiSTer ps2_key: [10]=toggle, [9]=pressed, [8]=E0, [7:0]=set2 code
  input  logic [10:0] ps2_key,
  // MiSTer ps2_led: [2]=scroll lock, [1]=num lock, [0]=caps lock
  output logic [2:0]  ps2_led,

  output logic [3:0]  nib_dpad,
  output logic [3:0]  nib_start_abc,
  output logic [3:0]  nib_rxyz,
  output logic [3:0]  nib_lxxx,

  output logic        ev_valid,
  output logic        ev_make,
  output logic [7:0]  ev_sc,
  input  logic        ev_pop
);

  // -----------------------------
  // PS/2 capture
  // -----------------------------
  logic ps2_tgl_d;
  wire  ps2_evt       = (ps2_tgl_d != ps2_key[10]);
  wire  ps2_pressed   = ps2_key[9];
  wire  ps2_ext       = ps2_key[8];
  wire  [7:0] ps2_code = ps2_key[7:0];

  logic caps_lock, num_lock, scr_lock;
  assign ps2_led = {scr_lock, num_lock, caps_lock};

  logic btn_up, btn_down, btn_left, btn_right;
  logic btn_start, btn_a, btn_b, btn_c;
  logic btn_x, btn_y, btn_z, btn_l, btn_r;

  // Single-entry queued event.
  logic       q_valid;
  logic       q_make;
  logic [7:0] q_sc;

  localparam logic [3:0] BTN_NONE  = 4'd0;
  localparam logic [3:0] BTN_START = 4'd1;
  localparam logic [3:0] BTN_L     = 4'd2;
  localparam logic [3:0] BTN_R     = 4'd3;
  localparam logic [3:0] BTN_X     = 4'd4;
  localparam logic [3:0] BTN_Y     = 4'd5;
  localparam logic [3:0] BTN_Z     = 4'd6;
  localparam logic [3:0] BTN_A     = 4'd7;
  localparam logic [3:0] BTN_B     = 4'd8;
  localparam logic [3:0] BTN_C     = 4'd9;
  localparam logic [3:0] BTN_LEFT  = 4'd10;
  localparam logic [3:0] BTN_RIGHT = 4'd11;
  localparam logic [3:0] BTN_UP    = 4'd12;
  localparam logic [3:0] BTN_DOWN  = 4'd13;

  logic       dec_sat_valid;
  logic [7:0] dec_sat_sc;
  logic [3:0] dec_btn;
  logic       dec_is_data;

  // Shared decode for both Saturn scancode queue and compatibility buttons.
  always_comb begin
    dec_sat_valid = 1'b0;
    dec_sat_sc    = ps2_code;
    dec_btn       = BTN_NONE;
    dec_is_data   = 1'b0;

    if(ps2_ext) begin
      unique case(ps2_code)
        8'h11: begin dec_sat_valid = 1'b1; dec_sat_sc = 8'h17; dec_is_data = 1'b1; end // RAlt
        8'h14: begin dec_sat_valid = 1'b1; dec_sat_sc = 8'h18; dec_is_data = 1'b1; end // RCtrl
        8'h5A: begin dec_sat_valid = 1'b1; dec_sat_sc = 8'h19; dec_is_data = 1'b1; end // KP Enter
        8'h1F: begin dec_sat_valid = 1'b1; dec_sat_sc = 8'h1F; dec_is_data = 1'b1; end // LWin
        8'h27: begin dec_sat_valid = 1'b1; dec_sat_sc = 8'h27; dec_is_data = 1'b1; end // RWin
        8'h2F: begin dec_sat_valid = 1'b1; dec_sat_sc = 8'h2F; dec_is_data = 1'b1; end // Menu
        8'h4A: begin dec_sat_valid = 1'b1; dec_sat_sc = 8'h80; dec_is_data = 1'b1; end // KP /
        8'h70: begin dec_sat_valid = 1'b1; dec_sat_sc = 8'h81; dec_is_data = 1'b1; end // Insert
        8'h7C: begin dec_sat_valid = 1'b1; dec_sat_sc = 8'h84; dec_is_data = 1'b1; end // PrtScr
        8'h71: begin dec_sat_valid = 1'b1; dec_sat_sc = 8'h85; dec_is_data = 1'b1; end // Delete
        8'h6B: begin dec_sat_valid = 1'b1; dec_sat_sc = 8'h86; dec_btn = BTN_LEFT;  dec_is_data = 1'b1; end // Left
        8'h6C: begin dec_sat_valid = 1'b1; dec_sat_sc = 8'h87; dec_is_data = 1'b1; end // Home
        8'h69: begin dec_sat_valid = 1'b1; dec_sat_sc = 8'h88; dec_is_data = 1'b1; end // End
        8'h75: begin dec_sat_valid = 1'b1; dec_sat_sc = 8'h89; dec_btn = BTN_UP;    dec_is_data = 1'b1; end // Up
        8'h72: begin dec_sat_valid = 1'b1; dec_sat_sc = 8'h8A; dec_btn = BTN_DOWN;  dec_is_data = 1'b1; end // Down
        8'h7D: begin dec_sat_valid = 1'b1; dec_sat_sc = 8'h8B; dec_is_data = 1'b1; end // PgUp
        8'h7A: begin dec_sat_valid = 1'b1; dec_sat_sc = 8'h8C; dec_is_data = 1'b1; end // PgDn
        8'h74: begin dec_sat_valid = 1'b1; dec_sat_sc = 8'h8D; dec_btn = BTN_RIGHT; dec_is_data = 1'b1; end // Right
        default: ;
      endcase
    end else begin
      // Ignore helper/meta bytes if they ever appear.
      dec_is_data = (ps2_code != 8'h00 && ps2_code != 8'hE0 && ps2_code != 8'hE1 && ps2_code != 8'hF0);
      if(dec_is_data) begin
        dec_sat_valid = 1'b1;

        unique case(ps2_code)
          8'h76: dec_btn = BTN_START; // Esc -> Start
          8'h15: dec_btn = BTN_L;     // Q -> L
          8'h24: dec_btn = BTN_R;     // E -> R
          8'h1C: dec_btn = BTN_X;     // A -> X
          8'h1B: dec_btn = BTN_Y;     // S -> Y
          8'h23: dec_btn = BTN_Z;     // D -> Z
          8'h1A: dec_btn = BTN_A;     // Z -> A
          8'h22: dec_btn = BTN_B;     // X -> B
          8'h21: dec_btn = BTN_C;     // C -> C
          default: ;
        endcase
      end
    end
  end

  // Saturn packet button fields use active-low button bits.
  always_comb begin
    nib_dpad      = {~btn_right, ~btn_left, ~btn_down, ~btn_up};      // Right Left Down Up
    nib_start_abc = {~btn_start, ~btn_a, ~btn_c, ~btn_b};             // Start A C B
    nib_rxyz      = {~btn_r, ~btn_x, ~btn_y, ~btn_z};                 // R X Y Z
    nib_lxxx      = {~btn_l, 3'b000};                                 // L 0 0 0
  end

  assign ev_valid = q_valid;
  assign ev_make  = q_make;
  assign ev_sc    = q_sc;

  always_ff @(posedge clk) begin
    if(reset) begin
      ps2_tgl_d   <= 1'b0;
      caps_lock   <= 1'b0;
      num_lock    <= 1'b0;
      scr_lock    <= 1'b0;

      btn_up      <= 1'b0;
      btn_down    <= 1'b0;
      btn_left    <= 1'b0;
      btn_right   <= 1'b0;
      btn_start   <= 1'b0;
      btn_a       <= 1'b0;
      btn_b       <= 1'b0;
      btn_c       <= 1'b0;
      btn_x       <= 1'b0;
      btn_y       <= 1'b0;
      btn_z       <= 1'b0;
      btn_l       <= 1'b0;
      btn_r       <= 1'b0;

      q_valid     <= 1'b0;
      q_make      <= 1'b0;
      q_sc        <= 8'h00;
    end else begin
      ps2_tgl_d <= ps2_key[10];

      // Drop stale queued event when keyboard mode is disabled.
      if(!enable) begin
        q_valid <= 1'b0;
      end else if(ev_pop) begin
        q_valid <= 1'b0;
      end

      // Buffer PS/2 events.
      if(ps2_evt) begin
        if(dec_is_data) begin
          // Keyboard packet held-button state fields (nibbles 3..6).
          unique case(dec_btn)
            BTN_START: btn_start <= ps2_pressed;
            BTN_L:     btn_l     <= ps2_pressed;
            BTN_R:     btn_r     <= ps2_pressed;
            BTN_X:     btn_x     <= ps2_pressed;
            BTN_Y:     btn_y     <= ps2_pressed;
            BTN_Z:     btn_z     <= ps2_pressed;
            BTN_A:     btn_a     <= ps2_pressed;
            BTN_B:     btn_b     <= ps2_pressed;
            BTN_C:     btn_c     <= ps2_pressed;
            BTN_LEFT:  btn_left  <= ps2_pressed;
            BTN_RIGHT: btn_right <= ps2_pressed;
            BTN_UP:    btn_up    <= ps2_pressed;
            BTN_DOWN:  btn_down  <= ps2_pressed;
            default: ;
          endcase

          // Lock toggles on MAKE.
          if(ps2_pressed && !ps2_ext) begin
            if(ps2_code == 8'h58) caps_lock <= ~caps_lock;
            if(ps2_code == 8'h77) num_lock  <= ~num_lock;
            if(ps2_code == 8'h7E) scr_lock  <= ~scr_lock;
          end

          if(dec_sat_valid && enable) begin
            // Keep only one pending event; do not overwrite older unconsumed data.
            if(!q_valid || ev_pop) begin
              q_valid <= 1'b1;
              q_make  <= ps2_pressed;
              q_sc    <= dec_sat_sc;
            end
          end
        end
      end
    end
  end

endmodule

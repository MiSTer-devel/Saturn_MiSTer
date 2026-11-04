derive_pll_clocks
derive_clock_uncertainty

set_multicycle_path -from [get_clocks { *|pll|pll_inst|altera_pll_i|*[1].*|divclk}] -to {ascal|*} -setup 4
set_multicycle_path -from [get_clocks { *|pll|pll_inst|altera_pll_i|*[1].*|divclk}] -to {ascal|*} -hold 3

set_false_path -from [get_keepers { emu|hps_io|status* }] 
set_false_path -from [get_keepers { emu|hps_io|ioctl_* }] 
set_false_path -to [get_keepers { emu|hps_io|ioctl_* }] 
set_false_path -from [get_keepers { emu|hps_io|img_* }] 
# Native trigger updates must meet timing into the 3D-pad poll snapshots.
set_false_path -from [get_keepers {
	emu|hps_io|joystick_0* emu|hps_io|joystick_1*
	emu|hps_io|joystick_2* emu|hps_io|joystick_3*
	emu|hps_io|joystick_4* emu|hps_io|joystick_5*
	emu|hps_io|joystick_l_analog_*
	emu|hps_io|joystick_r_analog_*
}]
set_false_path -from [get_keepers { emu|hps_io|sd_* }] 
set_false_path -from [get_registers { emu|hps_io|RTC* }]
set_false_path -from [get_registers { emu|cart_auto* emu|game_id* emu|cd_area_symbol* emu|dezaemon2_hack* }] 
set_false_path -from [get_registers { emu|en216p* emu|voff* emu|crop_size* }] 

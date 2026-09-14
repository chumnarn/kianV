current_design $::env(DESIGN_NAME)
set_units -time ns
create_clock -name sys_clk -period $::env(CLOCK_PERIOD) [get_pins clk_pad/p2c]
set clk [get_clocks sys_clk]
set_clock_uncertainty 0.25 $clk
set_clock_transition 0.15 $clk
set_input_delay -min 0.0 -clock $clk [get_ports {rst_n_PAD bidir_PAD[*]}]
set_input_delay -max 2.0 -clock $clk [get_ports {rst_n_PAD bidir_PAD[*]}]
set_output_delay -min 0.0 -clock $clk [get_ports {bidir_PAD[*]}]
set_output_delay -max 4.0 -clock $clk [get_ports {bidir_PAD[*]}]
set_load 0.033442 [get_ports {bidir_PAD[*]}]
set_false_path -from [get_ports rst_n_PAD]


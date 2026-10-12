# OpenSTA static timing analysis for the synthesized mult_array netlist
# (SKY130 sky130_fd_sc_hd, typical corner tt_025C_1v80 only).
# Run from the repository root:   sta sta/sta.tcl
# Clock period T (ns): defaults to Tmin = 2.60 ns (from the T = 10 ns run, WNS = 7.396 ns).
# First run, to find WNS:  T=10 sta sta/sta.tcl

set lib $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

if {[info exists ::env(T)]} {
    set T $::env(T)
} else {
    set T 2.60
}
puts "Clock period T = $T ns"

# 1. cell timing library
read_liberty $lib

# 2. read and link the netlist
read_verilog synth/mult_array_netlist.v
link_design mult_array

# 3. clock with period T on port clk
create_clock -name clk -period $T [get_ports clk]

# 4. input arrival time (all inputs except the clock)
set_input_delay 1.0 -clock clk [delete_from_list [all_inputs] [get_ports clk]]

# 5. output required time
set_output_delay 1.0 -clock clk [all_outputs]

# 6. worst setup slack
report_worst_slack -max

# 7. critical (max-delay) path report
report_checks -path_delay max -digits 3 > sta/mult_array_timing.rpt

exit

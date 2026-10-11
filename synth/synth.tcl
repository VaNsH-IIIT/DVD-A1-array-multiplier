# Yosys synthesis script for mult_array (SKY130 sky130_fd_sc_hd, typical corner)
# Run from the repository root:  yosys -c synth/synth.tcl

set lib $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# 1. read the design
yosys read_verilog rtl/full_adder.v rtl/mult_array.v

# 2. generic synthesis, flatten the full adders into one module
yosys synth -top mult_array -flatten

# 3. map flip-flops to SKY130 flip-flop cells
yosys dfflibmap -liberty $lib

# 4. map the combinational logic to SKY130 gate cells
yosys abc -liberty $lib

# 5. remove unused wires
yosys opt_clean -purge

# 6. cell and area report
yosys tee -o synth/mult_array_stat.rpt stat -liberty $lib

# 7. gate-level netlist
yosys write_verilog -noattr synth/mult_array_netlist.v

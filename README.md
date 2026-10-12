# 4-bit Array Multiplier: RTL to GDSII (SKY130, open-source flow)

Digital VLSI Design assignment. Team **Madhurbala_riders** (sub-team of 2).

| Name               | Roll number |
|--------------------|-------------|
| Vansh Jaiswal      | 2024102013  |
| Saarthak Sabbarwal | 2023102055  |

Design: 4-bit x 4-bit unsigned array multiplier (16 AND gates, 12 full adders),
registered inputs and output (16 flip-flops, 2-cycle latency), SkyWater SKY130
`sky130_fd_sc_hd` standard cells.

## Environment

All tools run inside the IIC-OSIC-TOOLS Docker image (`hpretl/iic-osic-tools:latest`,
Icarus Verilog 14.0, Yosys 0.69, OpenSTA 3.1.0, LibreLane, OpenROAD, KLayout, Magic, Netgen).
The container's default PDK is `ihp-sg13g2`, so SKY130 is selected explicitly.

```bash
# one-time: download the image
docker pull hpretl/iic-osic-tools:latest

# start a shell in the container with this repository mounted and SKY130 selected
docker run -it --rm \
    -e PDK=sky130A -e PDK_ROOT=/foss/pdks -e STD_CELL_LIBRARY=sky130_fd_sc_hd \
    -v "$PWD":/foss/designs/DVD-A1 -w /foss/designs/DVD-A1 \
    hpretl/iic-osic-tools:latest --skip bash

# inside the container: check the tools
iverilog -V | head -1
yosys -V
sta -version
echo $PDK_ROOT $PDK          # /foss/pdks sky130A
```

All commands below are run from the repository root inside the container.

## Part A: RTL design and verification

```bash
# RTL simulation (exhaustive, self-checking)
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim
#   -> PASS: 256 vectors checked, 0 errors

# error-injection check: temporarily edit rtl/full_adder.v to  assign sum = a ^ b;
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim
#   -> FAIL: 256 vectors checked, 95 errors
# then restore  assign sum = a ^ b ^ cin;  and re-run (PASS again)

# waveform (run on the host)
gtkwave mult.vcd
```

Example for task 5 uses Vansh's roll number (2024102013, last digit 3): A = 3 + 5 = 8, B = 7,
P = 56. See `report/partA_hand_example.md` and `report/figures/partA_waveform.png`.

## Part B: Logic synthesis with Yosys

```bash
# synthesis (writes synth/mult_array_netlist.v and synth/mult_array_stat.rpt)
yosys -c synth/synth.tcl

# gate-level simulation of the synthesized netlist with the same testbench
CELLS=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/verilog
iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY=#1 -o gls \
  tb/tb_mult.v $CELLS/primitives.v $CELLS/sky130_fd_sc_hd.v synth/mult_array_netlist.v
vvp gls
#   -> PASS: 256 vectors checked, 0 errors
```

Result: 63 cells (16 x `dfrtp_1` + 47 logic), 740.71 um^2, flip-flops 54.05 % of the area.
See `report/partB_results.md`.

## Part C: Static timing analysis with OpenSTA

```bash
# 1st run at T = 10 ns to find the worst slack (WNS)
T=10 sta sta/sta.tcl
#   -> worst slack max 7.40   (7.396 ns in the report)
# Tmin = 10 - 7.396 = 2.604 ns -> 2.60 ns;  Fmax = 1000 / 2.604 = 384.0 MHz

# 2nd run at T = Tmin = 2.60 ns (the script default); writes sta/mult_array_timing.rpt
sta sta/sta.tcl
#   -> worst slack max -0.00  (-0.004 ns, i.e. ~0)
```

Critical path: `a_r[1]` register -> 8 logic cells (7 full-adder stages) -> `p[6]` register.
The committed `sta/mult_array_timing.rpt` is the T = 2.60 ns run. See `report/partC_results.md`.

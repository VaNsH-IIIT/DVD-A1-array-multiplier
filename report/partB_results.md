# Part B: Logic synthesis results (Yosys 0.69, sky130_fd_sc_hd tt_025C_1v80)

Source: `synth/mult_array_stat.rpt`

| Metric                                      | Value |
|---------------------------------------------|-------|
| Total number of cells                       | 63 |
| Number of flip-flops                        | 16 (`sky130_fd_sc_hd__dfrtp_1`) |
| Total cell area (µm²)                       | 740.710 |
| Flip-flop area (µm²)                        | 16 × 25.024 = 400.384 |
| Flip-flop area (% of total)                 | 54.05 % |
| The 3 most-used cell types and their counts | `dfrtp_1` × 16, `nand2_1` × 8, `a21oi_1` × 6 |
| Netlist simulation result                   | `PASS: 256 vectors checked, 0 errors` |

Logic cells (total minus flip-flops): 63 − 16 = **47**, with area 740.710 − 400.384 = 340.326 µm².

## Full cell breakdown

| Cell | Count | Area (µm²) |
|------|------:|-----------:|
| dfrtp_1 (D flip-flop, async active-low reset) | 16 | 400.384 |
| nand2_1 | 8 | 30.029 |
| a21oi_1 | 6 | 30.029 |
| xnor2_1 | 4 | 35.034 |
| maj3_1 (majority, i.e. FA carry) | 3 | 30.029 |
| nand3_1 | 3 | 15.014 |
| xor2_1 | 3 | 26.275 |
| and2_0 | 2 | 12.512 |
| clkinv_1 | 2 | 7.507 |
| lpflow_isobufsrc_1 | 2 | 12.512 |
| xnor3_1 | 2 | 45.043 |
| a22oi_1, and3_1, and4_1, nand2b_1, nand4_1, nor2_1, nor2b_1, nor3_1, o2111ai_1, o21ai_0, o311ai_0, xor3_1 | 1 each | 96.342 |
| **Total** | **63** | **740.710** |

## Notes

* ABC did not map to the library full-adder cell (`fa_1`); it reports it as a multi-output
  cell it cannot use. Each full adder was instead broken into XOR/XNOR (sum) and
  MAJ3 / AOI / OAI / NAND (carry) gates, and gates were shared and merged across adder
  boundaries after flattening. That is why the logic count is 47, not 16 + 12 = 28.
* `lpflow_isobufsrc_1` is a power-isolation cell. Here ABC uses it as an ordinary
  `A AND NOT SLEEP` gate. The netlist simulation passes with it.
* The first netlist simulation printed mismatches with the product one vector late. The
  cause was the testbench, not the design: with `-DUNIT_DELAY=#1` the SKY130 flip-flop
  models have a 1 ns clk-to-q delay, and the testbench sampled `p` exactly 1 ns after the
  clock edge, a race with the flip-flop update. The testbench now samples 4 ns after
  edge 2. RTL simulation still passes, and the error-injection test still fails (95 errors).

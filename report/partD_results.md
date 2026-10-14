# Part D: Physical design results (LibreLane, SKY130 sky130_fd_sc_hd)

Config: `pnr/config.json`. Final run: `RUN_2026-10-14_17-38-20` (run 7), with `final/metrics.json` and
`final/gds/mult_array.gds` copied to `pnr/metrics.json` and `pnr/mult_array.gds`.

## Runs

Initial CLOCK_PERIOD = 1.2 × Tmin = 1.2 × 2.604 = 3.125 ns, rounded up to **3.5 ns**. The PDF's rule:
if timing fails, add 0.5 ns and run again.

| Run | CLOCK_PERIOD (ns) | Worst setup slack, all corners (ns) | Setup slack, typical corner (ns) | DRC | LVS | Result |
|----:|------:|-------:|------:|---:|---:|------|
| 1 | 3.5 | −2.132 | +0.547 | 0 | 0 | FAIL (setup, ss corner) |
| 2 | 4.0 | −1.632 | +1.047 | 0 | 0 | FAIL (setup, ss corner) |
| 3 | 4.5 | −1.142 | +1.551 | 0 | 0 | FAIL (setup, ss corner) |
| 4 | 5.0 | −0.642 | +2.052 | 0 | 0 | FAIL (setup, ss corner) |
| 5 | 5.5 | −0.142 | +2.552 | 0 | 0 | FAIL (setup, ss corner) |
| 6 | 6.0 | −0.064 | +2.943 | 0 | 0 | FAIL (setup, ss corner) |
| **7** | **6.5** | **+0.085** | **+3.293** | **0** | **0** | **PASS** |

* DRC and LVS were clean in every run. Only setup timing failed, and only in the slow corner.
* LibreLane's signoff STA checks 9 corners: ss (slow, 100 °C, 1.60 V), tt (typical, 25 °C, 1.80 V) and
  ff (fast, −40 °C, 1.95 V), each with min/nom/max wire parasitics. `setup__ws` is the worst of them, which
  is always `max_ss_100C_1v60`. The typical corner (the one used in Part C) passed from run 1 onwards.
* Runs 1–5 improve by almost exactly 0.5 ns per step. Run 6 improves by only 0.08 ns, because LibreLane
  re-synthesizes and re-sizes the design for each clock period. With a looser target, ABC and the resizer
  choose smaller, slower gates. At 6.0 ns the slow-corner path has about 5.5 ns of logic delay.

## Part D results table

| Metric | Value |
|---|---|
| CLOCK_PERIOD used (ns) | 6.5 |
| Number of runs needed | 7 |
| Core area (µm²) | 17 759.5 (die area 22 500 = 150 × 150) |
| Cells after synthesis (from Part B) | 63 |
| Cells after place and route | 1 901 (`design__instance__count`) |
| Kinds of cells added | decap (1 296), fill (270), tap (245), I/O buffers `buf_2` (17), clock-tree buffers `clkbuf_16` (3), fanout buffers `clkdlybuf4s50_1` (2) |
| Wirelength (µm) | 2 405 (detailed route; global route estimate 3 857) |
| Setup slack (ns) | +0.085 (worst corner `max_ss_100C_1v60`) |
| Post-route Fmax (MHz) | 1000 / (6.5 − 0.085) = **155.9** |
| Fmax from Part C (MHz) | 384.0 |
| DRC errors | 0 (Magic 0, KLayout 0, router 0) |
| LVS errors | 0 |

Other signoff results: hold slack +0.124 ns, antenna violations 0, power-grid violations 0,
Magic/KLayout GDS XOR difference 0. Cell utilisation 7.0 %.

## Cells after place and route (from `final/def/mult_array.def`)

| Kind | Cells | Count | Why the flow adds them |
|---|---|---:|---|
| Tap | `tapvpwrvgnd_1` | 245 | Connect the n-well to VPWR and the substrate to VGND at regular intervals in every row, to prevent latch-up |
| Decap | `decap_3/4/6/8/12` | 1 296 | Decoupling capacitors between VPWR and VGND. They supply charge locally when gates switch, reducing supply noise and IR drop |
| Fill | `fill_1`, `fill_2` | 270 | Fill the remaining gaps so every row has continuous wells, implants and power rails, as DRC requires |
| Clock-tree buffers | `clkbuf_16` | 3 | Clock tree synthesis: a root buffer and 2 leaf buffers so `clk` reaches all 16 flip-flops with low skew and sharp edges |
| I/O buffers | `buf_2` | 17 | One per input (`a`, `b`, `rst_n`: 9) and output (`p`: 8), isolating the pins from internal loads |
| Fanout buffers | `clkdlybuf4s50_1` | 2 | Split high-fanout nets (e.g. `rst_n` → 16 flip-flops) |
| Design | `dfrtp_1` 16, logic 49, `inv_1` 3 | 68 | The multiplier itself, from LibreLane's own synthesis (Part B's script gave 63) |
| **Total** | | **1 901** | 1 833 added by the flow, 68 from the design |

## Post-route Fmax vs Part C

Post-route Fmax (155.9 MHz) is about 41 % of Part C's 384.0 MHz. The main reasons:

1. **Process corner.** Part C used only the typical corner. The flow signs off at the slow corner
   (100 °C, 1.60 V), where cells are about 2× slower. In the typical corner alone, the routed design would
   reach 1000 / (6.5 − 3.293) = 311.8 MHz.
2. **Real wires.** Routed nets add RC delay and load, which raises gate delay and slew. Part C had no
   wire parasitics.
3. **Clock tree.** The clock now passes through 2 levels of `clkbuf_16` (about 0.5 ns of latency, with some
   skew between launch and capture). The flow also applies a 0.25 ns clock uncertainty. Part C used an
   ideal clock.
4. **Different netlist.** LibreLane re-synthesizes for each target period, and at 6.5 ns it uses smaller,
   slower gates than a timing-driven netlist would.

## Notes

* **Max-slew warnings:** 11, only in the slow corner, all on the reset net. Buffer `fanout18` drives
  10 `RESET_B` pins with a 0.761 ns transition against a 0.75 ns limit (1.5 % over). The reset is
  asynchronous and not timing-critical, the typical corner has none, and LibreLane's checker only
  warns (the flow exited successfully). Slew is not one of the PDF's pass conditions.
* **Screenshots:** `report/figures/partD_layout_die.png` (whole die) and `report/figures/partD_layout_zoom.png`
  (34 × 24 µm around the logic cluster), rendered with `report/figures/render_layout.py`
  (KLayout batch mode), with a caption strip added afterwards.

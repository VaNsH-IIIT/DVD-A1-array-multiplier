# Part C: Static timing analysis results (OpenSTA 3.1.0, tt_025C_1v80)

Script: `sta/sta.tcl`. The committed report `sta/mult_array_timing.rpt` is from the T = Tmin = 2.60 ns run.

## Finding Tmin and Fmax

| Run       | Command                  | Worst setup slack |
|-----------|--------------------------|-------------------|
| T = 10 ns | `T=10 sta sta/sta.tcl`   | **7.396 ns** (`report_worst_slack` prints 7.40, rounded to 2 digits) |
| T = 2.60 ns (Tmin) | `sta sta/sta.tcl` | **−0.004 ns ≈ 0** |
| T = 2.61 ns (check) | `T=2.61 sta sta/sta.tcl` | +0.006 ns |

* Tmin = T − WNS = 10 − 7.396 = **2.604 ns**, which is 2.60 ns rounded to 0.01 ns.
* Fmax = 1000 / Tmin = 1000 / 2.604 = **384.0 MHz**.
* With an ideal clock the path delay does not change with T, so slack = T − 2.604 exactly.
  The rerun at 2.60 ns therefore gives −0.004 ns (just below zero, from rounding Tmin down),
  and 2.61 ns gives +0.006 ns. Both are within 0.01 ns of zero, as expected.

## Part C results table

| Metric                                   | Value |
|------------------------------------------|-------|
| Worst slack at T = 10 ns (ns)            | 7.396 |
| Tmin (ns)                                | 2.604 (≈ 2.60) |
| Fmax (MHz)                               | 384.0 |
| Slack at T = Tmin = 2.60 ns (ns)         | −0.004 (≈ 0) |
| Critical path start point                | `a_r[1]` input register (`_095_`, dfrtp_1, CLK) |
| Critical path end point                  | `p[6]` output register (`_092_`, dfrtp_1, D) |
| Number of cells on the critical path     | 9: launch flip-flop + 8 logic gates (ending at the D pin of the `p[6]` flip-flop) |
| Latency (ns) = 2 × Tmin                  | 5.208 |
| Throughput (million results per second)  | 384.0 |

## Critical path, cell by cell (T = 10 ns report)

Each net was matched to an RTL signal by comparing truth tables over all 256 (a_r, b_r)
values, using the gate-level netlist and the equations of Section 2.

| # | Instance | Cell | Delay (ns) | Arrival (ns) | Signal computed | From |
|---|----------|------|-----------:|-------------:|-----------------|------|
| 0 | `_095_` | dfrtp_1 (CLK→Q) | 0.398 | 0.398 | `a_r[1]` | input register |
| 1 | `_039_` | clkinv_1  | 0.074 | 0.472 | NOT a_r[1] | AND gates (pp) |
| 2 | `_047_` | o311ai_0  | 0.348 | 0.820 | merged pp / row-1 logic | AND gates + fa1_1 |
| 3 | `_050_` | a21oi_1   | 0.172 | 0.992 | c2[1] | fa2_0 carry |
| 4 | `_063_` | maj3_1    | 0.381 | 1.373 | c2[2] | fa2_1 carry |
| 5 | `_064_` | xnor2_1   | 0.160 | 1.534 | NOT s2[2] | fa2_2 sum |
| 6 | `_066_` | maj3_1    | 0.385 | 1.918 | NOT c3[2] | fa3_1 carry |
| 7 | `_075_` | maj3_1    | 0.377 | 2.295 | NOT c3[3] | fa3_2 carry |
| 8 | `_079_` | xnor3_1   | 0.175 | 2.471 | s3[3] | fa3_3 sum → `p[6]` D |
|   |         | setup time of `_092_` | 0.134 | | | |

Path delay = 0.398 (clk→Q) + 2.073 (logic) + 0.134 (setup) = 2.605 ns ≈ Tmin.

## Comparison with the 2N estimate

* The path runs through **7 full-adder stages**: fa1_1 → fa2_0 → fa2_1 → fa2_2 → fa3_1 → fa3_2 → fa3_3.
  It travels along the row-2 carry chain, drops into row 3 through s2[2] = r2[1], then along
  the row-3 carry chain to the top sum bit. This is close to the estimate of about 2N = 8 full-adder delays.
* **6 of the 8 logic cells** compute a full-adder output directly: three `maj3` and one `a21oi`
  give carries, and one `xnor2` and one `xnor3` give sums. The other 2 cells (`clkinv`, `o311ai`) are
  partial-product AND logic merged with the first row-1 adder.
* Each full-adder stage costs only **one** cell on the path, because the path needs either the carry
  or the sum of each adder, not both. ABC builds each from a single complex gate (`maj3` for a carry,
  `xnor2`/`xnor3` for a sum).
* The average logic delay per full-adder stage is about 2.073 / 7 ≈ 0.30 ns.
* The path ends at `p[6]` (s3[3]), not `p[7]` (c3[4]). The final carry reaches the `p[7]` flip-flop at
  2.434 ns (slack 7.489 ns at T = 10 ns), 0.037 ns before the `xnor3` sum reaches `p[6]` at 2.471 ns.
  The next endpoint is `p[5]` at 2.215 ns.

## Other path groups

The asynchronous reset is checked separately (recovery check, `rst_n` → `RESET_B`). It has
9.228 ns slack at T = 10 ns and 1.828 ns at T = 2.60 ns, so it never limits the clock period.
Input paths (1 ns input delay → input flip-flops) have 8.895 ns slack, and output paths (clk→Q + 1 ns
output delay) have 8.688 ns slack at T = 10 ns. Both are larger than the 7.396 ns flip-flop-to-flip-flop slack.

## Carried forward to Part D

CLOCK_PERIOD = 1.2 × Tmin = 1.2 × 2.604 = 3.125 ns, rounded **up** to the next 0.5 ns = **3.5 ns**.

# Part A, Task 5: Hand-worked example

Roll number used: **Vansh Jaiswal, 2024102013**. Last digit = 3, so A = 3 + 5 = **8**, B = **7**.

## Shift-and-add (same layout as Section 2)

```
               1 0 0 0       A = 8
             x 0 1 1 1       B = 7
       ---------------
               1 0 0 0       pp0 = A AND b0 (b0 = 1)
             1 0 0 0         pp1 = A AND b1 (b1 = 1), shifted 1
           1 0 0 0           pp2 = A AND b2 (b2 = 1), shifted 2
         0 0 0 0             pp3 = A AND b3 (b3 = 0), shifted 3
       ---------------
       0 0 1 1 1 0 0 0       P = 56
```

## Trace through the array (Section 2 equations)

| Row | Adds                    | 4-bit sum s / carry c[4] | Product bit | Passed down r            |
|-----|-------------------------|--------------------------|-------------|--------------------------|
| 0   | pp0 = 1000              | none                     | p[0] = 0    | r0 = {0,1,0,0} = 0100    |
| 1   | pp1 1000 + r0 0100      | s1 = 1100, c1[4] = 0     | p[1] = 0    | r1 = {0,1,1,0} = 0110    |
| 2   | pp2 1000 + r1 0110      | s2 = 1110, c2[4] = 0     | p[2] = 0    | r2 = {0,1,1,1} = 0111    |
| 3   | pp3 0000 + r2 0111      | s3 = 0111, c3[4] = 0     | p[3] = 1    | p[7:4] = {0,0,1,1} = 0011|

P = p[7:0] = 0011_1000 = **56** = 8 x 7. ✓

## In the waveform (`report/figures/partA_waveform.png`)

* t = 2730 ns: the testbench applies a = 8, b = 7 (falling edge).
* t = 2735 ns (edge 1): input registers load, a_r = 8, b_r = 7.
* t = 2745 ns (edge 2): output register loads, p = 56.
* The latency is 2 clock cycles (20 ns at 10 ns period).

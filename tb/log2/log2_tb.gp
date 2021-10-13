set term pngcairo font 'Iosevka,11' size 640,480

# ------------------------------ PLOT FULL ------------------------------------
set output 'log2lin.png'
set title "Log2 linear interpolation"
plot \
     'log2_tb.csv' using 1:3 with lines lw 2 lc rgb '#109f10' title "linear",\
     'log2_tb.csv' using 1:2 with lines lw 1 lc rgb '#9f1010' title "reference"

set output 'log2lut1.png'
set title "Log2 LUT"
plot \
     'log2_tb.csv' using 1:4 with lines lw 2 lc rgb '#109f10' title "LUT",\
     'log2_tb.csv' using 1:2 with lines lw 1 lc rgb '#9f1010' title "reference"

set output 'log2lut2.png'
set title "Log2 LUT with interpolation"
plot \
     'log2_tb.csv' using 1:5 with lines lw 2 lc rgb '#109f10' title "LUT",\
     'log2_tb.csv' using 1:2 with lines lw 1 lc rgb '#9f1010' title "reference"

set output 'log2crd1.png'
set title "Log2 CORDIC V1"
plot \
     'log2_tb.csv' using 1:6 with lines lw 2 lc rgb '#109f10' title "CORDIC",\
     'log2_tb.csv' using 1:2 with lines lw 1 lc rgb '#9f1010' title "reference"

set output 'log2crd2.png'
set title "Log2 CORDIC V2"
plot \
     'log2_tb.csv' using 1:7 with lines lw 2 lc rgb '#109f10' title "CORDIC",\
     'log2_tb.csv' using 1:2 with lines lw 1 lc rgb '#9f1010' title "reference"

set output 'log2crd3.png'
set title "Log2 CORDIC V3"
plot \
     'log2_tb.csv' using 1:8 with lines lw 2 lc rgb '#109f10' title "CORDIC",\
     'log2_tb.csv' using 1:2 with lines lw 1 lc rgb '#9f1010' title "reference"

# ------------------------------ PLOT X = [1..2] ------------------------------------
set yr [0:1.1]
set xr [1:2]

set output 'log2lin_s.png'
set title "Log2 linear interpolation (fraction)"
plot \
     'log2_tb.csv' using 1:3 with lines lw 2 lc rgb '#109f10' title "linear",\
     'log2_tb.csv' using 1:2 with lines lw 1 lc rgb '#9f1010' title "reference"

set yr [0:1]

set output 'log2lut1_s.png'
set title "Log2 LUT (fraction)"
plot \
     'log2_tb.csv' using 1:4 with lines lw 2 lc rgb '#109f10' title "LUT",\
     'log2_tb.csv' using 1:2 with lines lw 1 lc rgb '#9f1010' title "reference"

set output 'log2lut2_s.png'
set title "Log2 LUT with interpolation (fraction)"
plot \
     'log2_tb.csv' using 1:5 with lines lw 2 lc rgb '#109f10' title "LUT",\
     'log2_tb.csv' using 1:2 with lines lw 1 lc rgb '#9f1010' title "reference"

set output 'log2crd1_s.png'
set title "Log2 CORDIC V1 (fraction)"
plot \
     'log2_tb.csv' using 1:6 with lines lw 2 lc rgb '#109f10' title "CORDIC",\
     'log2_tb.csv' using 1:2 with lines lw 1 lc rgb '#9f1010' title "reference"

set output 'log2crd2_s.png'
set title "Log2 CORDIC V2 (fraction)"
plot \
     'log2_tb.csv' using 1:7 with lines lw 2 lc rgb '#109f10' title "CORDIC",\
     'log2_tb.csv' using 1:2 with lines lw 1 lc rgb '#9f1010' title "reference"

set output 'log2crd3_s.png'
set title "Log2 CORDIC V3 (fraction)"
plot \
     'log2_tb.csv' using 1:8 with lines lw 2 lc rgb '#109f10' title "CORDIC",\
     'log2_tb.csv' using 1:2 with lines lw 1 lc rgb '#9f1010' title "reference"

# ------------------------------ PLOT ERROR LOG ------------------------------------
set yr [-15:-1]

set output 'log2lin_err.png'
set title "Log2 linear interpolation error (2^n)"
plot 'log2_tb.csv' using 1:(log10(abs($2-$3))/log10(2)) with lines lw 2 lc rgb '#9f1010' title ''

set output 'log2lut1_err.png'
set title "Log2 LUT error (2^n)"
plot 'log2_tb.csv' using 1:(log10(abs($2-$4))/log10(2)) with lines lw 2 lc rgb '#9f1010' title ''

set output 'log2lut2_err.png'
set title "Log2 LUT with interpolation error (2^n)"
plot 'log2_tb.csv' using 1:(log10(abs($2-$5))/log10(2)) with lines lw 2 lc rgb '#9f1010' title ''

set output 'log2crd1_err.png'
set title "Log2 CORDIC V1 error (2^n)"
plot 'log2_tb.csv' using 1:(log10(abs($2-$6))/log10(2)) with lines lw 2 lc rgb '#9f1010' title ''

set output 'log2crd2_err.png'
set title "Log2 CORDIC V2 error (2^n)"
plot 'log2_tb.csv' using 1:(log10(abs($2-$7))/log10(2)) with lines lw 2 lc rgb '#9f1010' title ''

set output 'log2crd3_err.png'
set title "Log2 CORDIC V3 error (2^n)"
plot 'log2_tb.csv' using 1:(log10(abs($2-$8))/log10(2)) with lines lw 2 lc rgb '#9f1010' title ''

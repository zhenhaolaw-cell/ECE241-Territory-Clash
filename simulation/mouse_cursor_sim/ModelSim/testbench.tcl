# stop any simulation that is currently running
quit -sim

# create the default "work" library
vlib work;

# compile the Verilog source code in the parent folder
vlog ../mouse_cursor.v
# compile the Verilog code of the testbench
vlog testbench.v
# start the Simulator, including some libraries that may be needed
vsim work.testbench -Lf 220model -Lf altera_mf_ver -Lf verilog
# show waveforms specified in wave.do
do wave.do
# advance the simulation the desired amount of time
# 25 packets x 420 ns = ~12 us, plus reset -> 14 us gives margin
run 14 us

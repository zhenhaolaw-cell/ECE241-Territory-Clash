# Stop any simulation that is currently running
quit -sim

# Create the default "work" library
vlib work;

# Compile the original LFSR source in the parent folder
vlog ../lfsr.v
# Compile the testbench
vlog testbench.v

# Start the simulator
vsim work.testbench -Lf 220model -Lf altera_mf_ver -Lf verilog

# Show waveforms and run the tests
do wave.do
run 440 ns

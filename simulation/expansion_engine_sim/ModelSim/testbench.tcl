# Run from the ModelSim folder.
quit -sim
vlib work;
vlog +incdir+.. ../expansion_engine.v
vlog ../lfsr.v
vlog testbench.v
vsim work.testbench -Lf 220model -Lf altera_mf_ver -Lf verilog
do wave.do
run 82 us

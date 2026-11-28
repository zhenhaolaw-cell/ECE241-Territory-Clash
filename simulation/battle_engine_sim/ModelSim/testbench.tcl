quit -sim
vlib work;
vlog +incdir+.. ../battle_engine.v
vlog testbench.v
vsim work.testbench -Lf 220model -Lf altera_mf_ver -Lf verilog
do wave.do
run 17.5 us

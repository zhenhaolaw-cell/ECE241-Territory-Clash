# stop any simulation that is currently running
quit -sim
# create the default work library
vlib work;
# compile the actual project module and include constants
vlog +incdir+.. ../expansion_request_buffer.v
# compile the testbench
vlog testbench.v
# start the simulator (same library options as the course example)
vsim work.testbench -Lf 220model -Lf altera_mf_ver -Lf verilog
# load wave layout
do wave.do
# run until the second clearing operation is complete
run 11 us

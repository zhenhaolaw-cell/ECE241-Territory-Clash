# stop any simulation that is currently running
quit -sim

# create the default "work" library
vlib work;

# compile the top-level and its own Verilog modules in the parent folder
vlog ../TerritoryClash.v
vlog ../grid_renderer.v
vlog ../cell_renderer.v
vlog ../highlight_renderer.v
vlog ../mouse_cursor.v

# compile the instructor-provided modules
vlog ../provided/PS2_Controller/*.v
vlog ../provided/vga_adapter/*.v

# compile the Verilog code of the testbench
vlog *.v
# start the Simulator, including some libraries that may be needed
vsim work.testbench -Lf 220model -Lf altera_mf_ver -Lf verilog
# show waveforms specified in wave.do
do wave.do
# advance the simulation the desired amount of time
run 530 us

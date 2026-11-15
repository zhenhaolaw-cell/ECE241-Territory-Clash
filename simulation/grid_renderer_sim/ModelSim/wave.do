onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -label CLOCK_50 -radix binary /testbench/CLOCK_50
add wave -noupdate -label resetn -radix binary /testbench/resetn
add wave -noupdate -label x -radix unsigned /testbench/x
add wave -noupdate -label y -radix unsigned /testbench/y
add wave -noupdate -label color -radix binary /testbench/color
add wave -noupdate -label write -radix binary /testbench/write
add wave -noupdate -label done -radix binary /testbench/done
add wave -noupdate -divider grid_renderer
add wave -noupdate -label local_x -radix unsigned /testbench/U1/local_x
add wave -noupdate -label local_y -radix unsigned /testbench/U1/local_y
add wave -noupdate -label in_cell_x -radix unsigned /testbench/U1/in_cell_x
add wave -noupdate -label in_cell_y -radix unsigned /testbench/U1/in_cell_y
add wave -noupdate -label drawing -radix binary /testbench/U1/drawing
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {10000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 80
configure wave -valuecolwidth 40
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {400 ns}

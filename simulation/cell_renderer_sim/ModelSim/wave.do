onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -label CLOCK_50 -radix binary /testbench/CLOCK_50
add wave -noupdate -label resetn -radix binary /testbench/resetn
add wave -noupdate -label start -radix binary /testbench/start
add wave -noupdate -label row -radix unsigned /testbench/row
add wave -noupdate -label col -radix unsigned /testbench/col
add wave -noupdate -label cell_color -radix binary /testbench/cell_color
add wave -noupdate -label x -radix unsigned /testbench/x
add wave -noupdate -label y -radix unsigned /testbench/y
add wave -noupdate -label color -radix binary /testbench/color
add wave -noupdate -label write -radix binary /testbench/write
add wave -noupdate -label busy -radix binary /testbench/busy
add wave -noupdate -label done -radix binary /testbench/done
add wave -noupdate -divider cell_renderer
add wave -noupdate -label state -radix unsigned /testbench/U1/state
add wave -noupdate -label saved_row -radix unsigned /testbench/U1/saved_row
add wave -noupdate -label saved_col -radix unsigned /testbench/U1/saved_col
add wave -noupdate -label saved_color -radix binary /testbench/U1/saved_color
add wave -noupdate -label offset_x -radix unsigned /testbench/U1/offset_x
add wave -noupdate -label offset_y -radix unsigned /testbench/U1/offset_y
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
WaveRestoreZoom {0 ps} {200 ns}

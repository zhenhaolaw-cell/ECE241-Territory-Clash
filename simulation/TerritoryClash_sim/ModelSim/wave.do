onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -label CLOCK_50 -radix binary /testbench/CLOCK_50
add wave -noupdate -label KEY -radix binary /testbench/KEY
add wave -noupdate -label SW -radix binary /testbench/SW
add wave -noupdate -divider Grid
add wave -noupdate -label grid_x -radix unsigned /testbench/U1/grid_x
add wave -noupdate -label grid_y -radix unsigned /testbench/U1/grid_y
add wave -noupdate -label grid_write -radix binary /testbench/U1/grid_write
add wave -noupdate -label grid_done -radix binary /testbench/U1/grid_done
add wave -noupdate -divider Mouse
add wave -noupdate -label mouse_row -radix unsigned /testbench/U1/mouse_row
add wave -noupdate -label mouse_col -radix unsigned /testbench/U1/mouse_col
add wave -noupdate -label mouse_click -radix binary /testbench/U1/mouse_click
add wave -noupdate -label cell_start -radix binary /testbench/U1/cell_start
add wave -noupdate -divider Renderers
add wave -noupdate -label hl_busy -radix binary /testbench/U1/hl_busy
add wave -noupdate -label hl_write -radix binary /testbench/U1/hl_write
add wave -noupdate -label cell_busy -radix binary /testbench/U1/cell_busy
add wave -noupdate -label cell_done -radix binary /testbench/U1/cell_done
add wave -noupdate -divider VGA_Selection
add wave -noupdate -label draw_x -radix unsigned /testbench/U1/draw_x
add wave -noupdate -label draw_y -radix unsigned /testbench/U1/draw_y
add wave -noupdate -label draw_color -radix binary /testbench/U1/draw_color
add wave -noupdate -label draw_write -radix binary /testbench/U1/draw_write
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

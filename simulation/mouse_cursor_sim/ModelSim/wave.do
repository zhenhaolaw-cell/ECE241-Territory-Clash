onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -label CLOCK_50 -radix binary /testbench/CLOCK_50
add wave -noupdate -label resetn -radix binary /testbench/resetn
add wave -noupdate -label received_data -radix hexadecimal /testbench/received_data
add wave -noupdate -label received_data_en -radix binary /testbench/received_data_en
add wave -noupdate -divider packet
add wave -noupdate -label byte_count -radix unsigned /testbench/U1/byte_count
add wave -noupdate -label byte0 -radix hexadecimal /testbench/U1/byte0
add wave -noupdate -label byte1 -radix hexadecimal /testbench/U1/byte1
add wave -noupdate -label byte2 -radix hexadecimal /testbench/U1/byte2
add wave -noupdate -label packet_ready -radix binary /testbench/packet_ready
add wave -noupdate -divider movement
add wave -noupdate -label dx -radix decimal /testbench/U1/dx
add wave -noupdate -label dy -radix decimal /testbench/U1/dy
add wave -noupdate -label sum_x -radix decimal /testbench/U1/sum_x
add wave -noupdate -label sum_y -radix decimal /testbench/U1/sum_y
add wave -noupdate -label pos_x -radix unsigned /testbench/U1/pos_x
add wave -noupdate -label pos_y -radix unsigned /testbench/U1/pos_y
add wave -noupdate -divider outputs
add wave -noupdate -label cur_col -radix unsigned /testbench/cur_col
add wave -noupdate -label cur_row -radix unsigned /testbench/cur_row
add wave -noupdate -label click -radix binary /testbench/click
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
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
WaveRestoreZoom {0 ps} {14 us}

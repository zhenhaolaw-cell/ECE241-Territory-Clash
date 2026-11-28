onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {Clock and Control}
add wave -noupdate -label CLOCK_50 -radix binary /testbench/CLOCK_50
add wave -noupdate -label resetn -radix binary /testbench/resetn
add wave -noupdate -label clear_start -radix binary /testbench/clear_start
add wave -noupdate -label clear_busy -radix binary /testbench/clear_busy
add wave -noupdate -label clear_done -radix binary /testbench/clear_done
add wave -noupdate -label clear_address -radix unsigned /testbench/U1/clear_address
add wave -noupdate -divider {Expansion Request Inputs}
add wave -noupdate -label request_valid -radix binary /testbench/request_valid
add wave -noupdate -label request_target -radix unsigned /testbench/request_target
add wave -noupdate -label request_player -radix binary /testbench/request_player
add wave -noupdate -label request_target_owner -radix binary /testbench/request_target_owner
add wave -noupdate -label blue_armour_start -radix unsigned /testbench/blue_armour_start
add wave -noupdate -label red_armour_start -radix unsigned /testbench/red_armour_start
add wave -noupdate -divider {Stored Results}
add wave -noupdate -label request_read_address -radix unsigned /testbench/request_read_address
add wave -noupdate -label request_flags -radix binary /testbench/request_flags
add wave -noupdate -label attacks_on_blue -radix unsigned /testbench/attacks_on_blue
add wave -noupdate -label attacks_on_red -radix unsigned /testbench/attacks_on_red
TreeUpdate [SetDefaultTree]
configure wave -namecolwidth 175
configure wave -valuecolwidth 95
configure wave -timelineunits ns
update
WaveRestoreZoom {5200000 ps} {5640000 ps}

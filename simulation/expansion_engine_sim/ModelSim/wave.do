onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {Clock and Start}
add wave -noupdate -label CLOCK_50 -radix binary /testbench/CLOCK_50
add wave -noupdate -label resetn -radix binary /testbench/resetn
add wave -noupdate -label expansion_start -radix binary /testbench/expansion_start
add wave -noupdate -label turn_count -radix unsigned /testbench/turn_count
add wave -noupdate -label blue_speed -radix unsigned /testbench/blue_speed
add wave -noupdate -label red_speed -radix unsigned /testbench/red_speed
add wave -noupdate -label blue_probability -radix unsigned /testbench/blue_probability
add wave -noupdate -label red_probability -radix unsigned /testbench/red_probability
add wave -noupdate -divider {Expansion FSM and Neighbor Checks}
add wave -noupdate -label state -radix unsigned /testbench/U1/state
add wave -noupdate -label source_address -radix unsigned /testbench/U1/source_address
add wave -noupdate -label source_owner -radix binary /testbench/U1/source_owner
add wave -noupdate -label direction -radix unsigned /testbench/U1/direction
add wave -noupdate -label target_address -radix unsigned /testbench/U1/target_address
add wave -noupdate -label target_valid -radix binary /testbench/U1/target_valid
add wave -noupdate -label snapshot_read_address -radix unsigned /testbench/snapshot_read_address
add wave -noupdate -label snapshot_read_owner -radix binary /testbench/snapshot_read_owner
add wave -noupdate -divider {Eligibility and LFSR}
add wave -noupdate -label blue_ready -radix binary /testbench/U1/blue_ready
add wave -noupdate -label red_ready -radix binary /testbench/U1/red_ready
add wave -noupdate -label can_attempt -radix binary /testbench/U1/can_attempt
add wave -noupdate -label current_probability -radix unsigned /testbench/U1/current_probability
add wave -noupdate -label random_value -radix hexadecimal /testbench/random_value
add wave -noupdate -label probability_success -radix binary /testbench/U1/probability_success
add wave -noupdate -label random_next -radix binary /testbench/random_next
add wave -noupdate -divider {Expansion Request Outputs}
add wave -noupdate -label request_valid -radix binary /testbench/request_valid
add wave -noupdate -label request_target -radix unsigned /testbench/request_target
add wave -noupdate -label request_player -radix binary /testbench/request_player
add wave -noupdate -label request_target_owner -radix binary /testbench/request_target_owner
add wave -noupdate -label expansion_busy -radix binary /testbench/expansion_busy
add wave -noupdate -label expansion_done -radix binary /testbench/expansion_done
TreeUpdate [SetDefaultTree]
configure wave -namecolwidth 200
configure wave -valuecolwidth 100
configure wave -timelineunits ns
update
WaveRestoreZoom {1750000 ps} {2000000 ps}

onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {Clock / Control}
add wave -noupdate -label CLOCK_50 -radix binary /testbench/CLOCK_50
add wave -noupdate -label resetn -radix binary /testbench/resetn
add wave -noupdate -label battle_start -radix binary /testbench/battle_start
add wave -noupdate -label battle_busy -radix binary /testbench/battle_busy
add wave -noupdate -label battle_done -radix binary /testbench/battle_done
add wave -noupdate -label state -radix unsigned /testbench/U1/state
add wave -noupdate -label resolve_address -radix unsigned /testbench/U1/resolve_address
add wave -noupdate -divider {Armour Calculation}
add wave -noupdate -label blue_armour_start -radix unsigned /testbench/blue_armour_start
add wave -noupdate -label red_armour_start -radix unsigned /testbench/red_armour_start
add wave -noupdate -label attacks_on_blue -radix unsigned /testbench/attacks_on_blue
add wave -noupdate -label attacks_on_red -radix unsigned /testbench/attacks_on_red
add wave -noupdate -label next_blue_armour -radix unsigned /testbench/next_blue_armour
add wave -noupdate -label next_red_armour -radix unsigned /testbench/next_red_armour
add wave -noupdate -label blue_zero_at_start -radix binary /testbench/U1/blue_zero_at_start
add wave -noupdate -label red_zero_at_start -radix binary /testbench/U1/red_zero_at_start
add wave -noupdate -divider {Snapshot / Request Buffer}
add wave -noupdate -label snapshot_read_address -radix unsigned /testbench/snapshot_read_address
add wave -noupdate -label snapshot_owner -radix binary /testbench/snapshot_owner
add wave -noupdate -label request_read_address -radix unsigned /testbench/request_read_address
add wave -noupdate -label request_flags -radix binary /testbench/request_flags
add wave -noupdate -label resolved_owner -radix binary /testbench/U1/resolved_owner
add wave -noupdate -divider {Results / Map Commit Read}
add wave -noupdate -label result_read_address -radix unsigned /testbench/result_read_address
add wave -noupdate -label result_owner -radix binary /testbench/result_owner
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
update
WaveRestoreZoom {0 ns} {17500 ns}

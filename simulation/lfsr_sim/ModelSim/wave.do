onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -label CLOCK_50 -radix binary /testbench/CLOCK_50
add wave -noupdate -label resetn -radix binary /testbench/resetn
add wave -noupdate -label random_next -radix binary /testbench/random_next
add wave -noupdate -label random_value -radix hexadecimal /testbench/random_value
add wave -noupdate -divider lfsr_internal
add wave -noupdate -label seed -radix hexadecimal /testbench/U1/seed
add wave -noupdate -label next_bit -radix binary /testbench/U1/next_bit
TreeUpdate [SetDefaultTree]
configure wave -namecolwidth 190
configure wave -valuecolwidth 90
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {440000 ps}

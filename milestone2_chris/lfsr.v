module lfsr (
    input CLOCK_50,
    input resetn,
    input random_next, // 1-cycle pulse: step once
    output [7:0] random_value
);
    reg [15:0] r; // 16-bit shift register
    wire feedback;

    // Taps 16, 14, 13, 11
    assign feedback = r[15] ^ r[13] ^ r[12] ^ r[10];

    always @(posedge CLOCK_50 or negedge resetn) begin
        if (!resetn)
            r <= 16'hECE1; // seed
        else if (random_next)
            r <= {r[14:0], feedback};// shift left, feedback enters bit 0
    end

    assign random_value = r[7:0]; 
endmodule
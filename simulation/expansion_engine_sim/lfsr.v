module lfsr #(
    parameter INITIAL_SEED = 16'hBEEF
)(
    input CLOCK_50,
    input resetn,
    input random_next,

    output [15:0] random_value
);

    // Stores the current 16-bit random value
    reg [15:0] seed;

    // Feedback bit used to generate the next value
    wire next_bit;

    // XOR selected bits to calculate the feedback
    assign next_bit = seed[15] ^ seed[13] ^
                      seed[12] ^ seed[10];

    // Send the current value to the expansion engine
    assign random_value = seed;

    // Update the random value on the clock rising edge
    always @(posedge CLOCK_50 or negedge resetn) begin
        if (!resetn) begin
            // Start from a nonzero value after reset
            seed <= INITIAL_SEED;
        end
        else if (random_next) begin
            // Shift left and insert the feedback bit
            seed <= {seed[14:0], next_bit};
        end
    end

endmodule

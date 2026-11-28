`timescale 1ns / 1ps

module testbench ( );

    parameter CLOCK_PERIOD = 20;

    reg CLOCK_50;
    reg resetn;
    reg random_next;
    wire [15:0] random_value;

    initial begin
        CLOCK_50 <= 1'b0;
    end // initial
    always @ (*)
    begin : Clock_Generator
        #((CLOCK_PERIOD) / 2) CLOCK_50 <= ~CLOCK_50;
    end

    // Test 1: Reset -> initial seed BEEF
    initial begin
        resetn <= 1'b0;
        #40 resetn <= 1'b1;

        // Test 4: Reset while the clock is running
        #220 resetn <= 1'b0;
        #40 resetn <= 1'b1;
    end // initial

    // Test 2: Enable updates for three rising edges
    // Test 3: Disable updates and check value is held
    // Test 5: Restart from the initial seed after reset
    initial begin
        random_next <= 1'b0;
        #80 random_next <= 1'b1;
        #60 random_next <= 1'b0;
        #60 random_next <= 1'b1;
        #40 random_next <= 1'b0;
        #100 random_next <= 1'b1;
        #40 random_next <= 1'b0;
    end // initial

    lfsr U1 (CLOCK_50, resetn, random_next, random_value);

endmodule

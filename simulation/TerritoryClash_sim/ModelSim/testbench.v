`timescale 1ns / 1ps

module testbench ( );

    parameter CLOCK_PERIOD = 20;

    reg CLOCK_50;
    reg [3:0] KEY;
    reg [9:0] SW;

    wire PS2_CLK;
    wire PS2_DAT;

    wire [7:0] VGA_R;
    wire [7:0] VGA_G;
    wire [7:0] VGA_B;
    wire VGA_HS;
    wire VGA_VS;
    wire VGA_BLANK_N;
    wire VGA_SYNC_N;
    wire VGA_CLK;

    initial begin
        CLOCK_50 <= 1'b0;
    end // initial
    always @ (*)
    begin : Clock_Generator
        #((CLOCK_PERIOD) / 2) CLOCK_50 <= ~CLOCK_50;
    end

    initial begin
        KEY <= 4'b1110;
        SW <= 10'b0100000000;
        #40 KEY[0] <= 1'b1;
    end // initial

    TerritoryClash U1 (
        CLOCK_50, KEY, SW,
        PS2_CLK, PS2_DAT,
        VGA_R, VGA_G, VGA_B,
        VGA_HS, VGA_VS,
        VGA_BLANK_N, VGA_SYNC_N, VGA_CLK
    );

endmodule

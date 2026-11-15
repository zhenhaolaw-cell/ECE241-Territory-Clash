`timescale 1ns / 1ps

module testbench ( );

    parameter CLOCK_PERIOD = 20;

    reg CLOCK_50;
    reg resetn;
    wire [8:0] x;
    wire [7:0] y;
    wire [8:0] color;
    wire write;
    wire done;

    initial begin
        CLOCK_50 <= 1'b0;
    end // initial
    always @ (*)
    begin : Clock_Generator
        #((CLOCK_PERIOD) / 2) CLOCK_50 <= ~CLOCK_50;
    end

    initial begin
        resetn <= 1'b0;
        #40 resetn <= 1'b1;
    end // initial

    grid_renderer U1 (CLOCK_50, resetn, x, y, color, write, done);

endmodule

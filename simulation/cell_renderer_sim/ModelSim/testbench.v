`timescale 1ns / 1ps

module testbench ( );

    parameter CLOCK_PERIOD = 20;

    reg CLOCK_50;
    reg resetn;
    reg start;
    reg [3:0] row;
    reg [3:0] col;
    reg [8:0] cell_color;

    wire [8:0] x;
    wire [7:0] y;
    wire [8:0] color;
    wire write;
    wire busy;
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
        start <= 1'b0;
        row <= 4'd3;
        col <= 4'd5;
        cell_color <= 9'b111_000_000;

        #40 resetn <= 1'b1;
        #20 start <= 1'b1;
        #20 start <= 1'b0;
    end // initial

    cell_renderer U1 (CLOCK_50, resetn, start, row, col, cell_color,
                      x, y, color, write, busy, done);

endmodule

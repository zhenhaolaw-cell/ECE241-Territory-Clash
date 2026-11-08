module TerritoryBattle (
    input CLOCK_50,
    input [3:0] KEY,
    output [9:0] LEDR
);

    assign LEDR = {6'b000000, ~KEY};

endmodule
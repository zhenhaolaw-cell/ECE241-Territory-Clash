module hex_count_display (
    input [8:0] blue_count,
    input [8:0] red_count,

    output [6:0] HEX0,
    output [6:0] HEX1,
    output [6:0] HEX2,
    output [6:0] HEX3,
    output [6:0] HEX4,
    output [6:0] HEX5
);

    // Each player can own up to 256 cells
    // Three decimal digits are needed for each player
    wire [3:0] blue_hundreds;
    wire [3:0] blue_tens;
    wire [3:0] blue_ones;

    wire [3:0] red_hundreds;
    wire [3:0] red_tens;
    wire [3:0] red_ones;

    // Convert Blue's cell count into decimal digits
    assign blue_hundreds = blue_count / 9'd100;
    assign blue_tens = (blue_count / 9'd10) % 9'd10;
    assign blue_ones = blue_count % 9'd10;

    // Convert Red's cell count into decimal digits
    assign red_hundreds = red_count / 9'd100;
    assign red_tens = (red_count / 9'd10) % 9'd10;
    assign red_ones = red_count % 9'd10;

    // Convert a decimal digit to seven-segment signals
    // DE1-SoC HEX displays are active-low
    // Bit order: gfedcba
    // 0 = segment ON, 1 = segment OFF
    function [6:0] seven_segment;
        input [3:0] digit;
        begin
            case (digit)
                4'd0: seven_segment = 7'b1000000;
                4'd1: seven_segment = 7'b1111001;
                4'd2: seven_segment = 7'b0100100;
                4'd3: seven_segment = 7'b0110000;
                4'd4: seven_segment = 7'b0011001;
                4'd5: seven_segment = 7'b0010010;
                4'd6: seven_segment = 7'b0000010;
                4'd7: seven_segment = 7'b1111000;
                4'd8: seven_segment = 7'b0000000;
                4'd9: seven_segment = 7'b0010000;
                default: seven_segment = 7'b1111111;
            endcase
        end
    endfunction

    // Display Blue's count on HEX5, HEX4, HEX3
    assign HEX5 = seven_segment(blue_hundreds);
    assign HEX4 = seven_segment(blue_tens);
    assign HEX3 = seven_segment(blue_ones);

    // Display Red's count on HEX2, HEX1, HEX0
    assign HEX2 = seven_segment(red_hundreds);
    assign HEX1 = seven_segment(red_tens);
    assign HEX0 = seven_segment(red_ones);

endmodule

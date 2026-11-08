module TerritoryClash (
    input CLOCK_50,
    input [3:0] KEY,

    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output VGA_HS,
    output VGA_VS,
    output VGA_BLANK_N,
    output VGA_SYNC_N,
    output VGA_CLK
);

    // Current pixel coordinates
    reg [8:0] x;
    reg [7:0] y;

    // Always draw blue pixels
    wire [2:0] colour;
    assign colour = 3'b001;

    // Move to the next pixel every clock cycle
    always @(posedge CLOCK_50 or negedge KEY[0])
    begin
        if (!KEY[0])
        begin
            x <= 9'd0;
            y <= 8'd0;
        end
        else
        begin
            if (x == 9'd319)
            begin
                x <= 9'd0;

                if (y == 8'd239)
                    y <= 8'd0;
                else
                    y <= y + 1'b1;
            end
            else
                x <= x + 1'b1;
        end
    end

    // Teacher-provided VGA Adapter
    vga_adapter VGA (
        .resetn(KEY[0]),
        .clock(CLOCK_50),
        .color(colour),
        .x(x),
        .y(y),
        .write(KEY[0]),

        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );

    defparam VGA.RESOLUTION = "320x240";
    defparam VGA.COLOR_DEPTH = 3;
    defparam VGA.BACKGROUND_IMAGE = "UNUSED";

endmodule
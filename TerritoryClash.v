
module TerritoryClash (
    input CLOCK_50,           // 50 MHz clock
    input [0:0] KEY,          // KEY[0]: active-low reset

    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output VGA_HS,
    output VGA_VS,
    output VGA_BLANK_N,
    output VGA_SYNC_N,
    output VGA_CLK
);

    // ==========================================
    // Part 1: Drawing signals
    // ==========================================

    // VGA coordinates for 640x480 resolution
    wire [9:0] draw_x;
    wire [8:0] draw_y;

    // RGB color: 3 bits per channel
    wire [8:0] draw_color;

    // Enable writing a pixel to VGA memory
    wire draw_write;

    // Indicates that the grid is finished
    wire draw_done;

    // ==========================================
    // Part 2: Grid Renderer
    // ==========================================

    // Our module generates the pixel coordinates
    // needed to draw the 16x16 game grid.

    grid_renderer grid (
        .CLOCK_50(CLOCK_50),
        .resetn(KEY[0]),

        .x(draw_x),
        .y(draw_y),
        .color(draw_color),
        .write(draw_write),
        .done(draw_done)
    );

    // ==========================================
    // Part 3: VGA Adapter
    // ==========================================

    // Instructor-provided VGA Adapter.
    // Stores pixel colors in VGA frame memory
    // and sends them to the monitor.

    vga_adapter VGA (
        .resetn(KEY[0]),
        .clock(CLOCK_50),

        .color(draw_color),
        .x(draw_x),
        .y(draw_y),
        .write(draw_write),

        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );

    // ==========================================
    // Part 4: VGA Configuration
    // ==========================================

    // Default resolution: 640x480
    defparam VGA.RESOLUTION = "640x480";

    // 9-bit RGB color
    defparam VGA.COLOR_DEPTH = 9;

    // Temporary background from instructor
    defparam VGA.BACKGROUND_IMAGE =
        "./MIF/territory_background_640_9.mif";

endmodule


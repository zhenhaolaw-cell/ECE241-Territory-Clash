

module TerritoryClash (
    input CLOCK_50,
    input [3:0] KEY,
    input [9:0] SW,

    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output VGA_HS,
    output VGA_VS,
    output VGA_BLANK_N,
    output VGA_SYNC_N,
    output VGA_CLK
);


    // Part 1: Grid Renderer


    wire [8:0] grid_x;
    wire [7:0] grid_y;
    wire [8:0] grid_color;
    wire grid_write;
    wire grid_done;

    grid_renderer grid (
        .CLOCK_50(CLOCK_50),
        .resetn(KEY[0]),

        .x(grid_x),
        .y(grid_y),
        .color(grid_color),
        .write(grid_write),
        .done(grid_done)
    );


    // Part 2: KEY[1] Press Detection


    // KEY is active-low on DE1-SoC.
    // Synchronize KEY[1] to CLOCK_50.

    reg key_sync1;
    reg key_sync2;
    reg key_previous;

    always @(posedge CLOCK_50)
    begin
        if (!KEY[0])
        begin
            key_sync1 <= 1'b1;
            key_sync2 <= 1'b1;
            key_previous <= 1'b1;
        end
        else
        begin
            key_sync1 <= KEY[1];
            key_sync2 <= key_sync1;
            key_previous <= key_sync2;
        end
    end

    // Detect one falling edge.
    // This makes a one-clock start pulse.
    wire key_pressed;

    assign key_pressed =
        key_previous && !key_sync2;

  
    // Part 3: Cell Drawing Request


    // These signals will later be driven
    // by PS/2 mouse logic instead of SW/KEY.

    wire [3:0] requested_row;
    wire [3:0] requested_col;
    wire [8:0] requested_color;

    wire cell_start;
    wire cell_busy;
    wire cell_done;

    assign requested_row = SW[7:4];
    assign requested_col = SW[3:0];

    // Choose blue or red using SW[8].
    reg [8:0] selected_color;

    always @(*)
    begin
        if (SW[8])
            selected_color = 9'b111_000_000;
        else
            selected_color = 9'b000_000_111;
    end

    assign requested_color = selected_color;

    // Do not accept a new command while
    // the grid or cell is being drawn.
    assign cell_start =
        grid_done && !cell_busy && key_pressed;

 
    // Part 4: Cell Renderer


    wire [8:0] cell_x;
    wire [7:0] cell_y;
    wire [8:0] cell_color_out;
    wire cell_write;

    cell_renderer cell_unit (
        .CLOCK_50(CLOCK_50),
        .resetn(KEY[0]),

        .start(cell_start),
        .row(requested_row),
        .col(requested_col),
        .cell_color(requested_color),

        .x(cell_x),
        .y(cell_y),
        .color(cell_color_out),
        .write(cell_write),

        .busy(cell_busy),
        .done(cell_done)
    );


    // Part 5: VGA Drawing Selection

    // Both drawing modules share the
    // same VGA Adapter.
    //
    // First: Draw the initial grid.
    // Then: Allow drawing selected cells.

    reg [8:0] draw_x;
    reg [7:0] draw_y;
    reg [8:0] draw_color;
    reg draw_write;

    always @(*)
    begin
        if (!grid_done)
        begin
            draw_x = grid_x;
            draw_y = grid_y;
            draw_color = grid_color;
            draw_write = grid_write;
        end
        else
        begin
            draw_x = cell_x;
            draw_y = cell_y;
            draw_color = cell_color_out;
            draw_write = cell_write;
        end
    end


    // Part 6: VGA Adapter


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


    // Part 7: VGA Configuration

    defparam VGA.RESOLUTION = "320x240";
    defparam VGA.COLOR_DEPTH = 9;

    defparam VGA.BACKGROUND_IMAGE =
        "./MIF/territory_background_320_9.mif";

endmodule

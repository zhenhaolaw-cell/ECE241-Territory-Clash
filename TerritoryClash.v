module TerritoryClash (
    input CLOCK_50,
    input [3:0] KEY,
    input [9:0] SW,

    inout PS2_CLK,
    inout PS2_DAT,

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

    // Draw the initial 16x16 grid.
    grid_renderer grid (
        .CLOCK_50(CLOCK_50),
        .resetn(KEY[0]),

        .x(grid_x),
        .y(grid_y),
        .color(grid_color),
        .write(grid_write),
        .done(grid_done)
    );


    // Part 2: PS/2 Mouse Controller

    // The PS2_Controller receive bytes from the physical PS/2 mouse.

    wire [7:0] mouse_data;
    wire mouse_data_valid;

    PS2_Controller #(
        .INITIALIZE_MOUSE(1)
    ) mouse_ps2 (
        .CLOCK_50(CLOCK_50),
        .reset(~KEY[0]),

        .the_command(8'h00),
        .send_command(1'b0),

        .PS2_CLK(PS2_CLK),
        .PS2_DAT(PS2_DAT),

        .received_data(mouse_data),
        .received_data_en(mouse_data_valid),

        .command_was_sent(),
        .error_communication_timed_out()
    );


    // Part 3: Mouse Position and Click Detection

    // Convert mouse movement packets into a selected row and column.
    // mouse_click becomes high when the left mouse button is pressed.

    wire [3:0] mouse_row;
    wire [3:0] mouse_col;
    wire mouse_click;
    wire mouse_packet_ready;

    mouse_cursor mouse_unit (
        .CLOCK_50(CLOCK_50),
        .resetn(KEY[0]),

        .received_data(mouse_data),
        .received_data_en(mouse_data_valid),

        .cur_row(mouse_row),
        .cur_col(mouse_col),
        .click(mouse_click),
        .packet_ready(mouse_packet_ready)
    );


    // Part 4: Cell Drawing Request

    // The mouse now selects row and column.
    // SW[8] still selects the drawing color.

    wire [3:0] requested_row;
    wire [3:0] requested_col;
    wire [8:0] requested_color;

    wire cell_start;
    wire cell_busy;
    wire cell_done;
    wire hl_busy;

    assign requested_row = mouse_row;
    assign requested_col = mouse_col;

    // Select blue or red.
    reg [8:0] selected_color;

    always @(*)
    begin
        if (SW[8])
            selected_color = 9'b111_000_000;
        else
            selected_color = 9'b000_000_111;
    end

    assign requested_color = selected_color;

    // Accept only when the grid is finished and the cell is not busy.
    assign cell_start =
        grid_done && !cell_busy && mouse_click && !hl_busy;


    // Part 5a: Cell Renderer

    // Draw the interior of the selected cell.
    // The 10x10 cell keeps its white grid lines.

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

    // Part 5b: Cell Highlight Renderer
    wire [8:0] hl_x;
    wire [7:0] hl_y;
    wire [8:0] hl_color;
    wire hl_write;

    highlight_renderer hl_unit (
        .CLOCK_50(CLOCK_50),
        .resetn(KEY[0]),
        .enable(grid_done && !mouse_click),
        .cell_busy(cell_busy),
        .cur_row(mouse_row), 
        .cur_col(mouse_col),
        .x(hl_x), .y(hl_y), .color(hl_color),
        .write(hl_write), .busy(hl_busy)
    );


    // Part 6: VGA Drawing Selection

    // Draw the grid first.
    // After grid_done, allow cell updates.

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
        else if (hl_busy)
        begin
            draw_x = hl_x;
            draw_y = hl_y;
            draw_color = hl_color;
            draw_write = hl_write;
        end
        else
        begin
            draw_x = cell_x;
            draw_y = cell_y;
            draw_color = cell_color_out;
            draw_write = cell_write;
        end
    end


    // Part 7: VGA Adapter

    // VGA Adapter writes pixels into video memory

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


    // Part 8: VGA Configuration

    // Use 320x240 logical resolution.
    defparam VGA.RESOLUTION = "320x240";

    // Use 9-bit RGB color.
    defparam VGA.COLOR_DEPTH = 9;

    // Load the TerritoryClash background.
    defparam VGA.BACKGROUND_IMAGE =
        "./MIF/territory_background_320_9.mif";

endmodule

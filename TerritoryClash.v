// ==========================================================================
// TerritoryClash top level - Milestone 2 placement demo
//
// CHANGES FROM MILESTONE 1 (every changed spot is tagged "M2 CHANGE"):
//   1. Ports: added LEDR[9:0] and `include "game_defs.vh".
//   2. Part 4 rewritten: the old SW[8] colour + direct click-to-paint is
//      replaced by character selection -> placement (5 cells each) ->
//      map memory -> display controller (text + all 256 cells).
//   3. Part 5a: cell_renderer is now driven by display_controller.
//   4. Part 5b: highlight pauses while the screen is redrawing.
//   5. Part 6: VGA selector gets a new input for the text (drawing_ui).
// Parts 1, 2, 3, 7 and 8 are unchanged.
// ==========================================================================
module TerritoryClash (
    input CLOCK_50,
    input [3:0] KEY,
    input [9:0] SW, // ** character ID (SW[8] no longer used)

    inout PS2_CLK,
    inout PS2_DAT,

    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output VGA_HS,
    output VGA_VS,
    output VGA_BLANK_N,
    output VGA_SYNC_N,
    output VGA_CLK,

    output [9:0] LEDR         // ** new port, 3:0 = game state, 9 = placement finished
);

    // EMPTY/BLUE/RED, game states, colours are shared constants

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


    // Part 4: Character Selection and Placement
    // "Cell Drawing Request" (SW[8] colour, cell_start = mouse_click).

    // KEY[1] edge detector: one-clock confirm pulse (KEY is active-low)
    reg key1_now, key1_last;
    always @(posedge CLOCK_50 or negedge KEY[0])
    begin
        if (!KEY[0])
        begin
            key1_now <= 1'b1;
            key1_last <= 1'b1;
        end
        else
        begin
            key1_now <= KEY[1];
            key1_last <= key1_now;
        end
    end
    wire confirm_pulse;
    assign confirm_pulse = key1_last && !key1_now;

    // Redraw the text when the switches change
    reg [3:0] sw_last;
    always @(posedge CLOCK_50 or negedge KEY[0])
    begin
        if (!KEY[0])
            sw_last <= 4'd0;
        else
            sw_last <= SW[3:0];
    end
    wire sw_changed;
    assign sw_changed = (sw_last != SW[3:0]);

    // Simple phase register for the demo: select -> place -> done
    // (stands in for game_fsm, which is not part of this demo)
    localparam P_INIT = 2'd0, P_SELECT = 2'd1, P_PLACE = 2'd2, P_DONE = 2'd3;
    reg [1:0] phase;
    wire map_ready, selection_done, placement_done, picking_red, placing_red;
    reg phase_refresh;

    always @(posedge CLOCK_50 or negedge KEY[0])
    begin
        if (!KEY[0])
        begin
            phase <= P_INIT;
            phase_refresh <= 1'b0;
        end
        else
        begin
            phase_refresh <= 1'b0;
            if (phase == P_INIT && map_ready && grid_done)
            begin
                phase <= P_SELECT;
                phase_refresh <= 1'b1;
            end
            else if (phase == P_SELECT && selection_done)
            begin
                phase <= P_PLACE;
                phase_refresh <= 1'b1;
            end
            else if (phase == P_PLACE && placement_done)
            begin
                phase <= P_DONE;
                phase_refresh <= 1'b1;
            end
        end
    end

    // game_state seen by my modules (codes from game_defs.vh)
    reg [3:0] game_state;
    always @(*)
    begin
        if (phase == P_SELECT)
        begin
            if (picking_red) game_state = SELECT_RED;
            else             game_state = SELECT_BLUE;
        end
        else if (phase == P_PLACE)
        begin
            if (placing_red) game_state = PLACE_RED;
            else             game_state = PLACE_BLUE;
        end
        else
            game_state = INIT;
    end
    assign LEDR[3:0] = game_state;
    assign LEDR[8:4] = 5'd0;
    assign LEDR[9] = (phase == P_DONE);

    // Character selection (SW[3:0] + KEY[1])
    wire [3:0] blue_character_id, red_character_id, preview_character_id;
    character_selection select_unit (
        .CLOCK_50(CLOCK_50), .resetn(KEY[0]),
        .selection_enable(phase == P_SELECT), .confirm_pulse(confirm_pulse),
        .switch_character_id(SW[3:0]),
        .blue_character_id(blue_character_id), .red_character_id(red_character_id),
        .preview_character_id(preview_character_id),
        .picking_red(picking_red), .selection_done(selection_done)
    );

    // Stats of the previewed character, for the text
    wire [6:0] preview_armour, preview_probability;
    wire [7:0] preview_speed;
    character_stats preview_stats (
        .character_id(preview_character_id),
        .base_armour(preview_armour), .expansion_speed(preview_speed),
        .expansion_probability(preview_probability)
    );

    // Placement: 5 cells each. Ignore clicks while the screen redraws.
    wire refresh_busy;
    wire [1:0] map_read_owner;
    wire [7:0] place_read_address, place_write_address;
    wire place_write_enable;
    wire [1:0] place_write_owner;
    wire [2:0] blue_placed_count, red_placed_count;

    placement_controller place_unit (
        .CLOCK_50(CLOCK_50), .resetn(KEY[0]),
        .placement_enable(phase == P_PLACE),
        .mouse_row(mouse_row), .mouse_col(mouse_col),
        .mouse_click(mouse_click && !refresh_busy),
        .map_read_owner(map_read_owner),
        .map_read_address(place_read_address),
        .map_write_enable(place_write_enable),
        .map_write_address(place_write_address),
        .map_write_owner(place_write_owner),
        .blue_placed_count(blue_placed_count), .red_placed_count(red_placed_count),
        .placing_red(placing_red), .placement_done(placement_done)
    );

    // Map memory and access. While the display redraws, it owns the read port.
    // (map_access gives placement priority in PLACE states; forcing INIT
    //  during a redraw lets the display read every cell correctly.)
    // Snapshot, winner and commit ports are tied to 0: not used in this demo.
    reg [3:0] access_state;
    always @(*)
    begin
        if (refresh_busy) access_state = INIT;
        else              access_state = game_state;
    end

    wire [7:0] display_read_address;
    wire [7:0] map_read_address, map_write_address;
    wire [1:0] map_write_owner;
    wire map_write_enable;

    map_access_controller access_unit (
        .game_state(access_state),
        .snapshot_busy(1'b0), .count_busy(1'b0),
        .placement_read_address(place_read_address),
        .snapshot_read_address(8'd0),
        .winner_read_address(8'd0),
        .display_read_address(display_read_address),
        .placement_write_enable(place_write_enable),
        .placement_write_address(place_write_address),
        .placement_write_owner(place_write_owner),
        .commit_write_enable(1'b0),
        .commit_write_address(8'd0),
        .commit_write_owner(2'b00),
        .map_read_address(map_read_address), .map_write_enable(map_write_enable),
        .map_write_address(map_write_address), .map_write_owner(map_write_owner)
    );

    map_memory map_unit (
        .CLOCK_50(CLOCK_50), .resetn(KEY[0]),
        .write_enable(map_write_enable), .write_address(map_write_address),
        .write_owner(map_write_owner), .read_address(map_read_address),
        .read_owner(map_read_owner), .clear_done(map_ready)
    );

    // Display controller: text first, then all 256 cells
    // Redraw when: the phase changes, a cell is placed, KEY[1] is pressed,
    // or the switches change (so the preview ID on screen updates).
    wire refresh_start;
    assign refresh_start = phase_refresh || place_write_enable || confirm_pulse || sw_changed;

    wire cell_start, cell_busy, cell_done, hl_busy;
    wire ui_start, ui_done, drawing_ui, refresh_done;
    wire [3:0] requested_row, requested_col;
    wire [8:0] owner_color;

    display_controller display_unit (
        .CLOCK_50(CLOCK_50), .resetn(KEY[0]),
        .refresh_start(refresh_start), .hl_busy(hl_busy),
        .map_read_owner(map_read_owner), .ui_done(ui_done), .cell_done(cell_done),
        .display_read_address(display_read_address),
        .ui_start(ui_start), .cell_start(cell_start),
        .cell_row(requested_row), .cell_col(requested_col), .cell_color(owner_color),
        .drawing_ui(drawing_ui), .refresh_busy(refresh_busy), .refresh_done(refresh_done)
    );

    // Empty cells use the navy of the background instead of black
    reg [8:0] selected_color;
    always @(*)
    begin
        if (owner_color == COLOR_EMPTY)
            selected_color = 9'b000_001_010;
        else
            selected_color = owner_color;
    end
    wire [8:0] requested_color;
    assign requested_color = selected_color;

    // Text renderer on the bottom bar (x = 96, y = 216)
    // turn_count and winner are 0 because battle is not in this demo.
    wire [8:0] ui_x;
    wire [7:0] ui_y;
    wire [8:0] ui_color;
    wire ui_write, ui_busy;

    ui_renderer #(.TEXT_X(9'd96), .TEXT_Y(8'd216)) ui_unit (
        .CLOCK_50(CLOCK_50), .resetn(KEY[0]), .ui_start(ui_start),
        .game_state(game_state), .preview_character_id(preview_character_id),
        .preview_armour(preview_armour), .preview_probability(preview_probability),
        .blue_placed_count(blue_placed_count), .red_placed_count(red_placed_count),
        .turn_count(8'd0), .winner(2'b00),
        .x(ui_x), .y(ui_y), .color(ui_color), .write(ui_write),
        .ui_busy(ui_busy), .ui_done(ui_done)
    );


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
        .enable(grid_done && !refresh_busy),   // !mouse_click; pause while redrawing
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
        else if (drawing_ui) //new input, text from ui_renderer
        begin
            draw_x = ui_x;
            draw_y = ui_y;
            draw_color = ui_color;
            draw_write = ui_write;
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

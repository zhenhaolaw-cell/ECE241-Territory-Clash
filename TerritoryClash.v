module TerritoryClash (
    input CLOCK_50,
    input [3:0] KEY,          // KEY[0] reset, KEY[1] confirm
    input [9:0] SW,           // SW[3:0] character ID
    inout PS2_CLK,
    inout PS2_DAT,
    output [9:0] LEDR,
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    output [7:0] VGA_R, VGA_G, VGA_B,
    output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK
);
    `include "game_defs.vh"

    wire resetn;
    assign resetn = KEY[0];

    // ================= Part 1: inputs =================
    // grid
    wire [8:0] grid_x; wire [7:0] grid_y; wire [8:0] grid_color;
    wire grid_write, grid_done;
    grid_renderer grid (.CLOCK_50(CLOCK_50), .resetn(resetn),
        .x(grid_x), .y(grid_y), .color(grid_color), .write(grid_write), .done(grid_done));

    // PS/2 mouse
    wire [7:0] mouse_data; wire mouse_data_valid;
    PS2_Controller #(.INITIALIZE_MOUSE(1)) mouse_ps2 (
        .CLOCK_50(CLOCK_50), .reset(~resetn),
        .the_command(8'h00), .send_command(1'b0),
        .PS2_CLK(PS2_CLK), .PS2_DAT(PS2_DAT),
        .received_data(mouse_data), .received_data_en(mouse_data_valid),
        .command_was_sent(), .error_communication_timed_out());

    wire [3:0] mouse_row, mouse_col; wire mouse_click, mouse_packet_ready;
    mouse_cursor mouse_unit (.CLOCK_50(CLOCK_50), .resetn(resetn),
        .received_data(mouse_data), .received_data_en(mouse_data_valid),
        .cur_row(mouse_row), .cur_col(mouse_col), .click(mouse_click),
        .packet_ready(mouse_packet_ready));

    // KEY[1] edge detector -> 1-clock confirm pulse (KEY is active-low)
    reg key1_now, key1_last;
    always @(posedge CLOCK_50 or negedge resetn) begin
        if (!resetn) begin key1_now <= 1'b1; key1_last <= 1'b1; end
        else begin key1_now <= KEY[1]; key1_last <= key1_now; end
    end
    wire confirm_pulse;
    assign confirm_pulse = key1_last && !key1_now;

    // SW[3:0] change detector -> redraw the preview text
    reg [3:0] sw_last;
    always @(posedge CLOCK_50 or negedge resetn) begin
        if (!resetn) sw_last <= 4'd0;
        else sw_last <= SW[3:0];
    end
    wire sw_changed;
    assign sw_changed = (sw_last != SW[3:0]);

    // ================= Part 2: main FSM =================
    wire [3:0] game_state; wire [7:0] turn_count;
    wire selection_enable, placement_enable, load_players;
    wire timer_start, snapshot_start, clear_start, expansion_start;
    wire battle_start, commit_start, update_armour, count_start, fsm_refresh;
    wire map_ready, picking_red, placing_red, selection_done, placement_done;
    wire timer_done, snapshot_done, clear_done, expansion_done, battle_done;
    wire commit_done, count_done, game_over, refresh_done;

    game_fsm fsm (.CLOCK_50(CLOCK_50), .resetn(resetn),
        .map_ready(map_ready), .grid_done(grid_done),
        .picking_red(picking_red), .placing_red(placing_red),
        .selection_done(selection_done), .placement_done(placement_done),
        .timer_done(timer_done), .snapshot_done(snapshot_done), .clear_done(clear_done),
        .expansion_done(expansion_done), .battle_done(battle_done), .commit_done(commit_done),
        .count_done(count_done), .game_over(game_over), .refresh_done(refresh_done),
        .game_state(game_state), .turn_count(turn_count),
        .selection_enable(selection_enable), .placement_enable(placement_enable),
        .load_players(load_players), .timer_start(timer_start),
        .snapshot_start(snapshot_start), .clear_start(clear_start),
        .expansion_start(expansion_start), .battle_start(battle_start),
        .commit_start(commit_start), .update_armour(update_armour),
        .count_start(count_start), .refresh_start(fsm_refresh));

    // ================= Part 3: setup modules =================
    wire [3:0] blue_character_id, red_character_id, preview_character_id;
    character_selection select_unit (.CLOCK_50(CLOCK_50), .resetn(resetn),
        .selection_enable(selection_enable), .confirm_pulse(confirm_pulse),
        .switch_character_id(SW[3:0]),
        .blue_character_id(blue_character_id), .red_character_id(red_character_id),
        .preview_character_id(preview_character_id),
        .picking_red(picking_red), .selection_done(selection_done));

    // stats of the character currently on the switches (for the text)
    wire [6:0] preview_armour, preview_probability; wire [7:0] preview_speed;
    character_stats preview_stats (.character_id(preview_character_id),
        .base_armour(preview_armour), .expansion_speed(preview_speed),
        .expansion_probability(preview_probability));

    wire [3:0] blue_selected_id, red_selected_id;
    wire [6:0] blue_armour, red_armour, blue_probability, red_probability;
    wire [7:0] blue_speed, red_speed;
    wire [6:0] next_blue_armour, next_red_armour;
    player_state players (.CLOCK_50(CLOCK_50), .resetn(resetn),
        .load_players(load_players),
        .blue_character_id(blue_character_id), .red_character_id(red_character_id),
        .update_armour(update_armour),
        .next_blue_armour(next_blue_armour), .next_red_armour(next_red_armour),
        .blue_selected_id(blue_selected_id), .red_selected_id(red_selected_id),
        .blue_armour(blue_armour), .red_armour(red_armour),
        .blue_speed(blue_speed), .red_speed(red_speed),
        .blue_probability(blue_probability), .red_probability(red_probability));

    // placement: ignore clicks while the screen is redrawing
    wire refresh_busy;
    wire place_click;
    assign place_click = mouse_click && !refresh_busy;

    wire [1:0] map_read_owner;
    wire [7:0] place_read_address, place_write_address;
    wire place_write_enable; wire [1:0] place_write_owner;
    wire [2:0] blue_placed_count, red_placed_count;
    placement_controller place_unit (.CLOCK_50(CLOCK_50), .resetn(resetn),
        .placement_enable(placement_enable),
        .mouse_row(mouse_row), .mouse_col(mouse_col), .mouse_click(place_click),
        .map_read_owner(map_read_owner),
        .map_read_address(place_read_address),
        .map_write_enable(place_write_enable), .map_write_address(place_write_address),
        .map_write_owner(place_write_owner),
        .blue_placed_count(blue_placed_count), .red_placed_count(red_placed_count),
        .placing_red(placing_red), .placement_done(placement_done));

    // ================= Part 4: map memory and its access =================
    wire [7:0] snap_map_address, count_map_address, display_read_address;
    wire [7:0] commit_write_address; wire [1:0] commit_write_owner; wire commit_write_enable;
    wire snapshot_busy, count_busy;
    wire [7:0] map_read_address, map_write_address; wire [1:0] map_write_owner; wire map_write_enable;

    // while the display redraws, pretend we are not placing,
    // so the display owns the read port
    reg [3:0] access_state;
    always @(*) begin
        if (refresh_busy) access_state = INIT;
        else access_state = game_state;
    end

    map_access_controller access_unit (.game_state(access_state),
        .snapshot_busy(snapshot_busy), .count_busy(count_busy),
        .placement_read_address(place_read_address),
        .snapshot_read_address(snap_map_address),
        .winner_read_address(count_map_address),
        .display_read_address(display_read_address),
        .placement_write_enable(place_write_enable),
        .placement_write_address(place_write_address),
        .placement_write_owner(place_write_owner),
        .commit_write_enable(commit_write_enable),
        .commit_write_address(commit_write_address),
        .commit_write_owner(commit_write_owner),
        .map_read_address(map_read_address), .map_write_enable(map_write_enable),
        .map_write_address(map_write_address), .map_write_owner(map_write_owner));

    map_memory map_unit (.CLOCK_50(CLOCK_50), .resetn(resetn),
        .write_enable(map_write_enable), .write_address(map_write_address),
        .write_owner(map_write_owner), .read_address(map_read_address),
        .read_owner(map_read_owner), .clear_done(map_ready));

    // ================= Part 5: one battle turn =================
    // snapshot read port is shared by expansion and battle
    wire [7:0] exp_snap_address, bat_snap_address;
    wire battle_busy;
    reg [7:0] snapshot_read_address;
    always @(*) begin
        if (battle_busy) snapshot_read_address = bat_snap_address;
        else snapshot_read_address = exp_snap_address;
    end
    wire [1:0] snapshot_read_owner;
    snapshot_memory snap_unit (.CLOCK_50(CLOCK_50), .resetn(resetn),
        .snapshot_start(snapshot_start), .map_read_owner(map_read_owner),
        .snapshot_read_address(snapshot_read_address),
        .map_read_address(snap_map_address), .snapshot_read_owner(snapshot_read_owner),
        .snapshot_busy(snapshot_busy), .snapshot_done(snapshot_done));

    wire random_next; wire [15:0] random_value;
    lfsr rng (.CLOCK_50(CLOCK_50), .resetn(resetn),
        .random_next(random_next), .random_value(random_value));

    wire request_valid; wire [7:0] request_target;
    wire [1:0] request_player, request_target_owner;
    wire expansion_busy;
    expansion_engine expand_unit (.CLOCK_50(CLOCK_50), .resetn(resetn),
        .expansion_start(expansion_start), .turn_count(turn_count),
        .blue_speed(blue_speed), .red_speed(red_speed),
        .blue_probability(blue_probability), .red_probability(red_probability),
        .snapshot_read_owner(snapshot_read_owner), .random_value(random_value),
        .snapshot_read_address(exp_snap_address), .random_next(random_next),
        .request_valid(request_valid), .request_target(request_target),
        .request_player(request_player), .request_target_owner(request_target_owner),
        .expansion_busy(expansion_busy), .expansion_done(expansion_done));

    wire [7:0] request_read_address; wire [1:0] request_flags;
    wire [10:0] attacks_on_blue, attacks_on_red; wire clear_busy;
    expansion_request_buffer request_unit (.CLOCK_50(CLOCK_50), .resetn(resetn),
        .clear_start(clear_start), .request_valid(request_valid),
        .request_target(request_target), .request_player(request_player),
        .request_target_owner(request_target_owner),
        .blue_armour_start(blue_armour), .red_armour_start(red_armour),
        .request_read_address(request_read_address), .request_flags(request_flags),
        .attacks_on_blue(attacks_on_blue), .attacks_on_red(attacks_on_red),
        .clear_busy(clear_busy), .clear_done(clear_done));

    wire [7:0] result_read_address; wire [1:0] result_owner;
    battle_engine battle_unit (.CLOCK_50(CLOCK_50), .resetn(resetn),
        .battle_start(battle_start), .snapshot_owner(snapshot_read_owner),
        .request_flags(request_flags),
        .blue_armour_start(blue_armour), .red_armour_start(red_armour),
        .attacks_on_blue(attacks_on_blue), .attacks_on_red(attacks_on_red),
        .result_read_address(result_read_address),
        .snapshot_read_address(bat_snap_address), .request_read_address(request_read_address),
        .result_owner(result_owner),
        .next_blue_armour(next_blue_armour), .next_red_armour(next_red_armour),
        .battle_busy(battle_busy), .battle_done(battle_done));

    wire commit_busy;
    map_commit_controller commit_unit (.CLOCK_50(CLOCK_50), .resetn(resetn),
        .commit_start(commit_start), .result_owner(result_owner),
        .result_read_address(result_read_address),
        .map_write_address(commit_write_address), .map_write_owner(commit_write_owner),
        .map_write_enable(commit_write_enable),
        .commit_busy(commit_busy), .commit_done(commit_done));

    wire [8:0] blue_count, red_count; wire [1:0] winner;
    winner_detector winner_unit (.CLOCK_50(CLOCK_50), .resetn(resetn),
        .count_start(count_start), .evaluate_winner(1'b1), .turn_count(turn_count),
        .map_read_owner(map_read_owner), .map_read_address(count_map_address),
        .blue_count(blue_count), .red_count(red_count),
        .game_over(game_over), .winner(winner),
        .count_busy(count_busy), .count_done(count_done));

    wire timer_busy;
    round_timer timer_unit (.CLOCK_50(CLOCK_50), .resetn(resetn),
        .timer_start(timer_start), .timer_busy(timer_busy), .timer_done(timer_done));

    hex_count_display hex_unit (.blue_count(blue_count), .red_count(red_count),
        .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5));

    assign LEDR[3:0] = game_state;
    assign LEDR[4] = picking_red | placing_red;
    assign LEDR[8:5] = 4'd0;
    assign LEDR[9] = game_over;

    // ================= Part 6: display =================
    // redraw when: the FSM asks, a cell is placed, a player confirms, or SW changes
    wire refresh_start;
    assign refresh_start = fsm_refresh || place_write_enable || confirm_pulse || sw_changed;

    wire hl_busy, cell_busy, cell_done, ui_done, ui_start, cell_start, drawing_ui;
    wire [3:0] cell_row, cell_col; wire [8:0] owner_color;
    display_controller display_unit (.CLOCK_50(CLOCK_50), .resetn(resetn),
        .refresh_start(refresh_start), .hl_busy(hl_busy),
        .map_read_owner(map_read_owner), .ui_done(ui_done), .cell_done(cell_done),
        .display_read_address(display_read_address),
        .ui_start(ui_start), .cell_start(cell_start),
        .cell_row(cell_row), .cell_col(cell_col), .cell_color(owner_color),
        .drawing_ui(drawing_ui), .refresh_busy(refresh_busy), .refresh_done(refresh_done));

    // empty cells use the navy of the background instead of black
    reg [8:0] draw_cell_color;
    always @(*) begin
        if (owner_color == COLOR_EMPTY) draw_cell_color = 9'b000_001_010;
        else draw_cell_color = owner_color;
    end

    wire [8:0] ui_x; wire [7:0] ui_y; wire [8:0] ui_color; wire ui_write, ui_busy;
    ui_renderer #(.TEXT_X(9'd96), .TEXT_Y(8'd216)) ui_unit (
        .CLOCK_50(CLOCK_50), .resetn(resetn), .ui_start(ui_start),
        .game_state(game_state), .preview_character_id(preview_character_id),
        .preview_armour(preview_armour), .preview_probability(preview_probability),
        .blue_placed_count(blue_placed_count), .red_placed_count(red_placed_count),
        .turn_count(turn_count), .winner(winner),
        .x(ui_x), .y(ui_y), .color(ui_color), .write(ui_write),
        .ui_busy(ui_busy), .ui_done(ui_done));

    wire [8:0] cell_x; wire [7:0] cell_y; wire [8:0] cell_color_out; wire cell_write;
    cell_renderer cell_unit (.CLOCK_50(CLOCK_50), .resetn(resetn),
        .start(cell_start), .row(cell_row), .col(cell_col), .cell_color(draw_cell_color),
        .x(cell_x), .y(cell_y), .color(cell_color_out), .write(cell_write),
        .busy(cell_busy), .done(cell_done));

    wire [8:0] hl_x; wire [7:0] hl_y; wire [8:0] hl_color; wire hl_write;
    highlight_renderer hl_unit (.CLOCK_50(CLOCK_50), .resetn(resetn),
        .enable(grid_done && !refresh_busy), .cell_busy(cell_busy),
        .cur_row(mouse_row), .cur_col(mouse_col),
        .x(hl_x), .y(hl_y), .color(hl_color), .write(hl_write), .busy(hl_busy));

    // VGA selector: grid -> text -> highlight -> cells
    reg [8:0] draw_x; reg [7:0] draw_y; reg [8:0] draw_color; reg draw_write;
    always @(*) begin
        if (!grid_done) begin
            draw_x = grid_x; draw_y = grid_y; draw_color = grid_color; draw_write = grid_write;
        end
        else if (drawing_ui) begin
            draw_x = ui_x; draw_y = ui_y; draw_color = ui_color; draw_write = ui_write;
        end
        else if (hl_busy) begin
            draw_x = hl_x; draw_y = hl_y; draw_color = hl_color; draw_write = hl_write;
        end
        else begin
            draw_x = cell_x; draw_y = cell_y; draw_color = cell_color_out; draw_write = cell_write;
        end
    end

    vga_adapter VGA (.resetn(resetn), .clock(CLOCK_50),
        .color(draw_color), .x(draw_x), .y(draw_y), .write(draw_write),
        .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B), .VGA_HS(VGA_HS), .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N), .VGA_SYNC_N(VGA_SYNC_N), .VGA_CLK(VGA_CLK));
    defparam VGA.RESOLUTION = "320x240";
    defparam VGA.COLOR_DEPTH = 9;
    defparam VGA.BACKGROUND_IMAGE = "./MIF/territory_background_320_9.mif";
endmodule

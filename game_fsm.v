module game_fsm (
    input CLOCK_50,
    input resetn,
    input map_ready,          // map_memory finished clearing
    input grid_done,          // grid_renderer finished
    input picking_red,        // from character_selection
    input placing_red,        // from placement_controller
    input selection_done,
    input placement_done,
    input timer_done,
    input snapshot_done,
    input clear_done,         // request buffer cleared
    input expansion_done,
    input battle_done,
    input commit_done,
    input count_done,
    input game_over,
    input refresh_done,

    output reg [3:0] game_state,
    output reg [7:0] turn_count,
    output selection_enable,
    output placement_enable,
    output reg load_players,
    output reg timer_start,
    output reg snapshot_start,
    output reg clear_start,
    output reg expansion_start,
    output reg battle_start,
    output reg commit_start,
    output reg update_armour,
    output reg count_start,
    output reg refresh_start
);
    `include "game_defs.vh"

    localparam S_INIT   = 4'd0;
    localparam S_SELECT = 4'd1;
    localparam S_PLACE  = 4'd2;
    localparam S_TIMER  = 4'd3;
    localparam S_SNAP   = 4'd4;
    localparam S_CLEAR  = 4'd5;
    localparam S_EXPAND = 4'd6;
    localparam S_BATTLE = 4'd7;
    localparam S_COMMIT = 4'd8;
    localparam S_COUNT  = 4'd9;
    localparam S_DRAW   = 4'd10;
    localparam S_OVER   = 4'd11;

    reg [3:0] state;

    assign selection_enable = (state == S_SELECT);
    assign placement_enable = (state == S_PLACE);

    // game_state seen by the other modules
    always @(*) begin
        if (state == S_INIT)
            game_state = INIT;
        else if (state == S_SELECT) begin
            if (picking_red) game_state = SELECT_RED;
            else             game_state = SELECT_BLUE;
        end
        else if (state == S_PLACE) begin
            if (placing_red) game_state = PLACE_RED;
            else             game_state = PLACE_BLUE;
        end
        else if (state == S_OVER)
            game_state = GAME_OVER;
        else
            game_state = BATTLE;
    end

    always @(posedge CLOCK_50 or negedge resetn) begin
        if (!resetn) begin
            state <= S_INIT;
            turn_count <= 8'd0;
            load_players <= 1'b0;
            timer_start <= 1'b0;
            snapshot_start <= 1'b0;
            clear_start <= 1'b0;
            expansion_start <= 1'b0;
            battle_start <= 1'b0;
            commit_start <= 1'b0;
            update_armour <= 1'b0;
            count_start <= 1'b0;
            refresh_start <= 1'b0;
        end
        else begin
            // all start signals are 1-clock pulses
            load_players <= 1'b0;
            timer_start <= 1'b0;
            snapshot_start <= 1'b0;
            clear_start <= 1'b0;
            expansion_start <= 1'b0;
            battle_start <= 1'b0;
            commit_start <= 1'b0;
            update_armour <= 1'b0;
            count_start <= 1'b0;
            refresh_start <= 1'b0;

            case (state)
                S_INIT: begin
                    if (map_ready && grid_done) begin
                        refresh_start <= 1'b1;
                        state <= S_SELECT;
                    end
                end
                S_SELECT: begin
                    if (selection_done) begin
                        load_players <= 1'b1;
                        refresh_start <= 1'b1;
                        state <= S_PLACE;
                    end
                end
                S_PLACE: begin
                    if (placement_done) begin
                        turn_count <= 8'd1;
                        timer_start <= 1'b1;
                        refresh_start <= 1'b1;
                        state <= S_TIMER;
                    end
                end
                S_TIMER: begin
                    if (timer_done) begin
                        snapshot_start <= 1'b1;
                        state <= S_SNAP;
                    end
                end
                S_SNAP: begin
                    if (snapshot_done) begin
                        clear_start <= 1'b1;
                        state <= S_CLEAR;
                    end
                end
                S_CLEAR: begin
                    if (clear_done) begin
                        expansion_start <= 1'b1;
                        state <= S_EXPAND;
                    end
                end
                S_EXPAND: begin
                    if (expansion_done) begin
                        battle_start <= 1'b1;
                        state <= S_BATTLE;
                    end
                end
                S_BATTLE: begin
                    if (battle_done) begin
                        commit_start <= 1'b1;
                        state <= S_COMMIT;
                    end
                end
                S_COMMIT: begin
                    if (commit_done) begin
                        update_armour <= 1'b1;
                        count_start <= 1'b1;
                        state <= S_COUNT;
                    end
                end
                S_COUNT: begin
                    if (count_done) begin
                        refresh_start <= 1'b1;
                        state <= S_DRAW;
                    end
                end
                S_DRAW: begin
                    if (refresh_done) begin
                        if (game_over) begin
                            refresh_start <= 1'b1;
                            state <= S_OVER;
                        end
                        else begin
                            turn_count <= turn_count + 8'd1;
                            timer_start <= 1'b1;
                            state <= S_TIMER;
                        end
                    end
                end
                S_OVER: begin
                    // stay here until KEY[0] reset
                end
                default: state <= S_INIT;
            endcase
        end
    end
endmodule

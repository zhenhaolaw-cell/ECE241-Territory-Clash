module battle_engine (
    input CLOCK_50,
    input resetn,
    input battle_start,

    // Original owner of the current cell from Snapshot Memory
    input [1:0] snapshot_owner,

    // Saved expansion requests for the current cell
    input [1:0] request_flags,

    // Both players' armour at the start of the turn
    input [6:0] blue_armour_start,
    input [6:0] red_armour_start,

    // Number of successful attacks received by each player
    input [10:0] attacks_on_blue,
    input [10:0] attacks_on_red,

    // Address requested by Map Commit Controller
    input [7:0] result_read_address,

    // Address used to read Snapshot Memory and Request Buffer
    output [7:0] snapshot_read_address,
    output [7:0] request_read_address,

    // Final owner of the cell requested by Map Commit
    output [1:0] result_owner,

    // Armour values after this battle round
    output reg [6:0] next_blue_armour,
    output reg [6:0] next_red_armour,

    // Battle engine status
    output reg battle_busy,
    output reg battle_done
);

    `include "game_defs.vh"

    // FSM states
    localparam IDLE_STATE = 2'd0;
    localparam RESOLVE = 2'd1;
    localparam FINISH = 2'd2;

    reg [1:0] state;

    // Address of the cell currently being resolved
    reg [7:0] resolve_address;

    // Store the final ownership of all 256 cells
    reg [1:0] results [0:255];

    // Remember whether each player's armour was zero
    // at the beginning of this battle round
    reg blue_zero_at_start;
    reg red_zero_at_start;

    // Calculated owner of the current cell
    reg [1:0] resolved_owner;

    // Read Snapshot Memory and Request Buffer
    // using the same cell address
    assign snapshot_read_address = resolve_address;
    assign request_read_address = resolve_address;

    // Allow Map Commit Controller to read saved results
    assign result_owner = results[result_read_address];

    // Decide the final owner of one cell
    always @(*) begin

        // Normally, keep the original owner
        resolved_owner = snapshot_owner;

        if (snapshot_owner == EMPTY) begin

            // Only Blue successfully requested this empty cell
            if (request_flags == 2'b01)
                resolved_owner = BLUE;

            // Only Red successfully requested this empty cell
            else if (request_flags == 2'b10)
                resolved_owner = RED;

            // 00: nobody requested the cell
            // 11: both players requested the cell
            // In both cases, the cell remains empty

        end
        else if (snapshot_owner == BLUE) begin

            // Red can capture this blue cell only if
            // Blue started this turn with zero armour
            if (blue_zero_at_start && request_flags[1])
                resolved_owner = RED;

        end
        else if (snapshot_owner == RED) begin

            // Blue can capture this red cell only if
            // Red started this turn with zero armour
            if (red_zero_at_start && request_flags[0])
                resolved_owner = BLUE;

        end
    end

    // Control armour calculation and map resolution
    always @(posedge CLOCK_50 or negedge resetn) begin
        if (!resetn) begin
            state <= IDLE_STATE;
            resolve_address <= 8'd0;

            blue_zero_at_start <= 1'b0;
            red_zero_at_start <= 1'b0;

            next_blue_armour <= 7'd0;
            next_red_armour <= 7'd0;

            battle_busy <= 1'b0;
            battle_done <= 1'b0;
        end
        else begin

            // Done is normally zero and becomes one
            // for one clock cycle after resolution finishes
            battle_done <= 1'b0;

            case (state)

                IDLE_STATE: begin
                    if (battle_start) begin

                        // Start resolving from cell address 0
                        resolve_address <= 8'd0;
                        battle_busy <= 1'b1;

                        // Save armour conditions before damage
                        // These values stay fixed for this round
                        blue_zero_at_start <=
                            (blue_armour_start == 7'd0);

                        red_zero_at_start <=
                            (red_armour_start == 7'd0);

                        // Calculate Blue's remaining armour
                        // Every successful attack removes one point
                        // Armour must never become negative
                        if (attacks_on_blue >=
                            {4'b0000, blue_armour_start}) begin
                            next_blue_armour <= 7'd0;
                        end
                        else begin
                            next_blue_armour <=
                                blue_armour_start -
                                attacks_on_blue[6:0];
                        end

                        // Calculate Red's remaining armour
                        if (attacks_on_red >=
                            {4'b0000, red_armour_start}) begin
                            next_red_armour <= 7'd0;
                        end
                        else begin
                            next_red_armour <=
                                red_armour_start -
                                attacks_on_red[6:0];
                        end

                        // Begin resolving the map
                        state <= RESOLVE;
                    end
                end

                RESOLVE: begin

                    // Save the calculated owner of this cell
                    results[resolve_address] <= resolved_owner;

                    // Check whether the last cell is finished
                    if (resolve_address == 8'd255) begin
                        state <= FINISH;
                    end
                    else begin

                        // Move to the next cell
                        resolve_address <= resolve_address + 1'b1;
                    end
                end

                FINISH: begin

                    // All 256 results have been saved
                    battle_busy <= 1'b0;
                    battle_done <= 1'b1;

                    // Return to IDLE for the next round
                    state <= IDLE_STATE;
                end

                default: begin
                    state <= IDLE_STATE;
                end

            endcase
        end
    end

endmodule
 
module winner_detector (
    input CLOCK_50,
    input resetn,

    // Start counting all 256 map cells
    input count_start,

    // 1: check the winner after a battle round
    // 0: only update cell counts during placement
    input evaluate_winner,

    // Current completed battle turn (1 to 200)
    input [7:0] turn_count,

    // Cell ownership returned by Map Memory
    input [1:0] map_read_owner,

    // Address sent to Map Memory for reading
    output [7:0] map_read_address,

    // Total cells owned by each player (0 to 256)
    output reg [8:0] blue_count,
    output reg [8:0] red_count,

    // Game result
    output reg game_over,
    output reg [1:0] winner,

    // Counting status
    output reg count_busy,
    output reg count_done
);

    // Cell ownership codes
    localparam BLUE = 2'b01;
    localparam RED = 2'b10;

    // Winner codes
    localparam WIN_NONE = 2'b00;
    localparam WIN_BLUE = 2'b01;
    localparam WIN_RED = 2'b10;
    localparam WIN_DRAW = 2'b11;

    // Maximum number of battle turns
    localparam MAX_TURNS = 8'd200;

    // FSM states
    localparam IDLE_STATE = 2'd0;
    localparam COUNT_STATE = 2'd1;
    localparam FINISH_STATE = 2'd2;

    reg [1:0] state;

    // Address of the cell currently being counted
    reg [7:0] count_address;

    // Save the evaluation mode and turn number
    // so they cannot change during the scan
    reg evaluate_saved;
    reg [7:0] turn_saved;

    // Map Memory reads the cell selected by this address
    assign map_read_address = count_address;

    always @(posedge CLOCK_50 or negedge resetn) begin
        if (!resetn) begin
            // Initialize the FSM and counters
            state <= IDLE_STATE;
            count_address <= 8'd0;

            blue_count <= 9'd0;
            red_count <= 9'd0;

            game_over <= 1'b0;
            winner <= WIN_NONE;

            count_busy <= 1'b0;
            count_done <= 1'b0;

            evaluate_saved <= 1'b0;
            turn_saved <= 8'd0;
        end
        else begin
            // count_done is normally zero
            // It becomes one for only one clock cycle
            count_done <= 1'b0;

            case (state)

                IDLE_STATE: begin
                    if (count_start) begin
                        // Start a new scan from cell 0
                        count_address <= 8'd0;

                        // Clear previous territory counts
                        blue_count <= 9'd0;
                        red_count <= 9'd0;

                        // Remember whether to check game over
                        evaluate_saved <= evaluate_winner;
                        turn_saved <= turn_count;

                        // Reset the previous game result
                        game_over <= 1'b0;
                        winner <= WIN_NONE;

                        count_busy <= 1'b1;
                        state <= COUNT_STATE;
                    end
                end

                COUNT_STATE: begin
                    // Read one cell from Map Memory
                    // and increase the matching player's count
                    if (map_read_owner == BLUE) begin
                        blue_count <= blue_count + 1'b1;
                    end
                    else if (map_read_owner == RED) begin
                        red_count <= red_count + 1'b1;
                    end

                    // After cell 255, all cells are counted
                    if (count_address == 8'd255) begin
                        state <= FINISH_STATE;
                    end
                    else begin
                        // Read the next cell on the next clock
                        count_address <= count_address + 1'b1;
                    end
                end

                FINISH_STATE: begin
                    // All 256 cells have been counted
                    count_busy <= 1'b0;
                    count_done <= 1'b1;

                    // Only evaluate the winner after battle
                    if (evaluate_saved) begin

                        // Both players have no territory
                        if (blue_count == 9'd0 &&
                            red_count == 9'd0) begin
                            game_over <= 1'b1;
                            winner <= WIN_DRAW;
                        end

                        // Blue has no territory: Red wins
                        else if (blue_count == 9'd0) begin
                            game_over <= 1'b1;
                            winner <= WIN_RED;
                        end

                        // Red has no territory: Blue wins
                        else if (red_count == 9'd0) begin
                            game_over <= 1'b1;
                            winner <= WIN_BLUE;
                        end

                        // Maximum number of turns reached
                        else if (turn_saved >= MAX_TURNS) begin
                            game_over <= 1'b1;

                            if (blue_count > red_count)
                                winner <= WIN_BLUE;

                            else if (red_count > blue_count)
                                winner <= WIN_RED;

                            else
                                winner <= WIN_DRAW;
                        end
                    end

                    // Wait for the next counting request
                    state <= IDLE_STATE;
                end

                default: begin
                    state <= IDLE_STATE;
                end

            endcase
        end
    end

endmodule

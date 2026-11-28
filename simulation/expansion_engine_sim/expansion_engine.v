module expansion_engine (
    input CLOCK_50,
    input resetn,
    input expansion_start,
    input [7:0] turn_count,
    input [7:0] blue_speed,
    input [7:0] red_speed,
    input [6:0] blue_probability,
    input [6:0] red_probability,
    input [1:0] snapshot_read_owner,
    input [15:0] random_value,

    output [7:0] snapshot_read_address,
    output reg random_next,
    output reg request_valid,
    output reg [7:0] request_target,
    output reg [1:0] request_player,
    output reg [1:0] request_target_owner,
    output reg expansion_busy,
    output reg expansion_done
);

    `include "game_defs.vh"

    localparam IDLE_STATE = 2'd0;
    localparam READ_SOURCE = 2'd1;
    localparam CHECK_TARGET = 2'd2;
    localparam FINISH = 2'd3;

    reg [1:0] state;
    reg [7:0] source_address;
    reg [1:0] direction;
    reg [1:0] source_owner;
    reg blue_ready;
    reg red_ready;

    reg [7:0] target_address;
    reg target_valid;
    reg can_attempt;
    reg [6:0] current_probability;
    reg probability_success;

    // Approximate a percentage as a threshold in the 16-bit LFSR range.
    wire [16:0] probability_threshold;
    assign probability_threshold = current_probability * 10'd655;

    // Read the source cell first, then its neighbour in CHECK_TARGET.
    assign snapshot_read_address = (state == CHECK_TARGET && target_valid)
                                 ? target_address : source_address;

    // Select a neighbour without wrapping across a map edge.
    always @(*) begin
        target_address = source_address;
        target_valid = 1'b1;

        case (direction)
            2'd0: begin
                if (source_address[7:4] == 4'd0)
                    target_valid = 1'b0;
                else
                    target_address = source_address - 8'd16;
            end
            2'd1: begin
                if (source_address[7:4] == 4'd15)
                    target_valid = 1'b0;
                else
                    target_address = source_address + 8'd16;
            end
            2'd2: begin
                if (source_address[3:0] == 4'd0)
                    target_valid = 1'b0;
                else
                    target_address = source_address - 8'd1;
            end
            2'd3: begin
                if (source_address[3:0] == 4'd15)
                    target_valid = 1'b0;
                else
                    target_address = source_address + 8'd1;
            end
        endcase
    end

    // Decide whether this source player can expand this round.
    always @(*) begin
        can_attempt = 1'b0;
        current_probability = 7'd0;

        if (source_owner == BLUE && blue_ready) begin
            can_attempt = 1'b1;
            current_probability = blue_probability;
        end
        else if (source_owner == RED && red_ready) begin
            can_attempt = 1'b1;
            current_probability = red_probability;
        end
    end

    // Zero percent always fails and 100 percent always succeeds.
    always @(*) begin
        probability_success = 1'b0;
        if (current_probability >= 7'd100)
            probability_success = 1'b1;
        else if (current_probability != 7'd0 &&
                 {1'b0, random_value} < probability_threshold)
            probability_success = 1'b1;
    end

    // The request is sampled by the buffer on the same edge
    // that advances the LFSR to the next random value.
    always @(*) begin
        random_next = 1'b0;
        request_valid = 1'b0;
        request_target = target_address;
        request_player = source_owner;
        request_target_owner = snapshot_read_owner;

        if (state == CHECK_TARGET && target_valid && can_attempt &&
            snapshot_read_owner != source_owner &&
            (snapshot_read_owner == EMPTY ||
             snapshot_read_owner == BLUE ||
             snapshot_read_owner == RED)) begin
            random_next = 1'b1;
            if (probability_success)
                request_valid = 1'b1;
        end
    end

    // Scan every source cell and all four directions.
    always @(posedge CLOCK_50 or negedge resetn) begin
        if (!resetn) begin
            state <= IDLE_STATE;
            source_address <= 8'd0;
            direction <= 2'd0;
            source_owner <= EMPTY;
            blue_ready <= 1'b0;
            red_ready <= 1'b0;
            expansion_busy <= 1'b0;
            expansion_done <= 1'b0;
        end
        else begin
            expansion_done <= 1'b0;

            case (state)
                IDLE_STATE: begin
                    if (expansion_start) begin
                        // Speed N means expanding on turns N, 2N, 3N, etc.
                        blue_ready <= (blue_speed != 8'd0) &&
                                      (turn_count % blue_speed == 8'd0);
                        red_ready <= (red_speed != 8'd0) &&
                                     (turn_count % red_speed == 8'd0);
                        source_address <= 8'd0;
                        direction <= 2'd0;
                        expansion_busy <= 1'b1;
                        state <= READ_SOURCE;
                    end
                end

                READ_SOURCE: begin
                    // Capture the original owner of this source cell.
                    source_owner <= snapshot_read_owner;
                    direction <= 2'd0;
                    state <= CHECK_TARGET;
                end

                CHECK_TARGET: begin
                    // The current neighbour is checked on this clock.
                    if (direction == 2'd3) begin
                        if (source_address == 8'd255) begin
                            state <= FINISH;
                        end
                        else begin
                            source_address <= source_address + 1'b1;
                            state <= READ_SOURCE;
                        end
                    end
                    else begin
                        direction <= direction + 1'b1;
                    end
                end

                FINISH: begin
                    expansion_busy <= 1'b0;
                    expansion_done <= 1'b1;
                    state <= IDLE_STATE;
                end

                default: state <= IDLE_STATE;
            endcase
        end
    end

endmodule

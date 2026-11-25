
module map_commit_controller (
    input CLOCK_50,
    input resetn,
    input commit_start,

    // Resolved cell owner read from battle_engine
    input [1:0] result_owner,

    // Address sent to battle_engine to select one result
    output [7:0] result_read_address,

    // Write signals sent to map_memory
    output [7:0] map_write_address,
    output [1:0] map_write_owner,
    output map_write_enable,

    // Status signals for the game controller
    output reg commit_busy,
    output reg commit_done
);

    // Three states: wait, write all cells, then report completion
    localparam IDLE_STATE   = 2'd0;
    localparam WRITE_STATE  = 2'd1;
    localparam FINISH_STATE = 2'd2;

    reg [1:0] state;

    // Current cell address, from 0 to 255
    reg [7:0] commit_address;

    // The battle result and map write use the same address
    assign result_read_address = commit_address;
    assign map_write_address = commit_address;

    // Pass the selected result directly to Map Memory
    assign map_write_owner = result_owner;

    // Only allow writes while the controller is in WRITE_STATE
    assign map_write_enable = (state == WRITE_STATE);

    always @(posedge CLOCK_50 or negedge resetn) begin
        if (!resetn) begin
            // Reset the controller; Map Memory is reset separately
            state <= IDLE_STATE;
            commit_address <= 8'd0;
            commit_busy <= 1'b0;
            commit_done <= 1'b0;
        end
        else begin
            // Make commit_done a one-clock-cycle pulse
            commit_done <= 1'b0;

            case (state)
                IDLE_STATE: begin
                    // Wait until Battle Engine has completed all results
                    if (commit_start) begin
                        commit_address <= 8'd0;
                        commit_busy <= 1'b1;
                        state <= WRITE_STATE;
                    end
                end

                WRITE_STATE: begin
                    // While in this state, map_write_enable is 1.
                    // Map Memory writes result_owner at commit_address
                    // on this clock edge.

                    if (commit_address == 8'd255) begin
                        // Cell 255 is written on this clock edge.
                        // Stop writes on the following cycle.
                        state <= FINISH_STATE;
                    end
                    else begin
                        // Select the next result for the next clock edge
                        commit_address <= commit_address + 1'b1;
                    end
                end

                FINISH_STATE: begin
                    // All 256 cells have been committed to Map Memory
                    commit_busy <= 1'b0;
                    commit_done <= 1'b1;
                    state <= IDLE_STATE;
                end

                default: begin
                    state <= IDLE_STATE;
                    commit_busy <= 1'b0;
                end
            endcase
        end
    end

endmodule

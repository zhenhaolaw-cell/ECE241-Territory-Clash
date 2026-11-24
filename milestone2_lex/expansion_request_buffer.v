module expansion_request_buffer (
    input CLOCK_50,
    input resetn,

    // Start clearing all requests before a new turn
    input clear_start,

    // One successful expansion attempt from expansion_engine
    input request_valid,
    input [7:0] request_target,
    input [1:0] request_player,
    input [1:0] request_target_owner,

    // Armour values at the beginning of the current turn
    input [6:0] blue_armour_start,
    input [6:0] red_armour_start,

    // Address used by battle_engine to read saved requests
    input [7:0] request_read_address,

    // Requests saved for the selected target cell
    output [1:0] request_flags,

    // Number of successful attacks received by each player
    output reg [10:0] attacks_on_blue,
    output reg [10:0] attacks_on_red,

    // Status signals for clearing the request buffer
    output reg clear_busy,
    output reg clear_done
);

    `include "game_defs.vh"

    // Each cell stores two request bits:
    // bit 0 = Blue request
    // bit 1 = Red request
    reg [1:0] requests [0:255];

    // Address of the cell currently being cleared
    reg [7:0] clear_address;

    // Allow battle_engine to read requests from any cell
    assign request_flags = requests[request_read_address];

    always @(posedge CLOCK_50 or negedge resetn) begin
        if (!resetn) begin
            // Reset control registers and attack counters
            clear_address <= 8'd0;
            clear_busy <= 1'b0;
            clear_done <= 1'b0;
            attacks_on_blue <= 11'd0;
            attacks_on_red <= 11'd0;
        end
        else begin
            // Clear_done is a one-clock-cycle pulse
            clear_done <= 1'b0;

            if (clear_busy) begin
                // Clear one cell's requests every clock cycle
                requests[clear_address] <= 2'b00;

                if (clear_address == 8'd255) begin
                    // All 256 request entries are now empty
                    clear_busy <= 1'b0;
                    clear_done <= 1'b1;
                end
                else begin
                    // Move to the next cell
                    clear_address <= clear_address + 1'b1;
                end
            end
            else if (clear_start) begin
                // Begin clearing requests for a new turn
                clear_address <= 8'd0;
                clear_busy <= 1'b1;

                // Reset both attack counters for the new turn
                attacks_on_blue <= 11'd0;
                attacks_on_red <= 11'd0;
            end
            else if (request_valid) begin
                // Process one successful expansion attempt

                if (request_player == BLUE) begin

                    if (request_target_owner == EMPTY) begin
                        // Blue successfully requests an empty cell
                        requests[request_target][0] <= 1'b1;
                    end
                    else if (request_target_owner == RED) begin

                        if (red_armour_start != 7'd0) begin
                            // Red had armour at the start of the turn
                            // Each successful hit deals one damage
                            attacks_on_red <= attacks_on_red + 1'b1;
                        end
                        else begin
                            // Red started the turn with zero armour
                            // Blue can request capture of this red cell
                            requests[request_target][0] <= 1'b1;
                        end
                    end

                    // Blue-owned targets are ignored
                end
                else if (request_player == RED) begin

                    if (request_target_owner == EMPTY) begin
                        // Red successfully requests an empty cell
                        requests[request_target][1] <= 1'b1;
                    end
                    else if (request_target_owner == BLUE) begin

                        if (blue_armour_start != 7'd0) begin
                            // Blue had armour at the start of the turn
                            // Count every successful attack separately
                            attacks_on_blue <= attacks_on_blue + 1'b1;
                        end
                        else begin
                            // Blue started the turn with zero armour
                            // Red can request capture of this blue cell
                            requests[request_target][1] <= 1'b1;
                        end
                    end

                    // Red-owned targets are ignored
                end
            end
        end
    end

endmodule

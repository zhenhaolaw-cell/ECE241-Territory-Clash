module map_access_controller (
    input [3:0] game_state,
    input snapshot_busy,
    input count_busy,

    // read requests
    input [7:0] placement_read_address,
    input [7:0] snapshot_read_address,
    input [7:0] winner_read_address,
    input [7:0] display_read_address,

    // write requests
    input       placement_write_enable,
    input [7:0] placement_write_address,
    input [1:0] placement_write_owner,
    input       commit_write_enable,
    input [7:0] commit_write_address,
    input [1:0] commit_write_owner,

    // to map_memory
    output reg [7:0] map_read_address,
    output reg       map_write_enable,
    output reg [7:0] map_write_address,
    output reg [1:0] map_write_owner
);
    `include "game_defs.vh"

    wire placing;
    assign placing = (game_state == 4'd3) || (game_state == 4'd4);

    // READ MUX
    always @(*) begin
        if (placing)
            map_read_address = placement_read_address;
        else if (snapshot_busy)
            map_read_address = snapshot_read_address;
        else if (count_busy)
            map_read_address = winner_read_address;
        else
            map_read_address = display_read_address;      // default: the display
    end

    // WRITE MUX
    always @(*) begin
        if (placing) begin
            map_write_enable  = placement_write_enable;
            map_write_address = placement_write_address;
            map_write_owner   = placement_write_owner;
        end
        else begin
            map_write_enable  = commit_write_enable;
            map_write_address = commit_write_address;
            map_write_owner   = commit_write_owner;
        end
    end
endmodule
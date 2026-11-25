module placement_controller (
    input CLOCK_50,
    input resetn,
    input placement_enable,          // 1 while game_fsm is in PLACE_BLUE/PLACE_RED
    input [3:0] mouse_row,
    input [3:0] mouse_col,
    input mouse_click,               // 1-clock pulse from mouse_cursor
    input [1:0] map_read_owner,      // owner of the cell under the mouse

    output [7:0] map_read_address,
    output reg map_write_enable,
    output reg [7:0] map_write_address,
    output reg [1:0] map_write_owner,
    output reg [2:0] blue_placed_count,  // 0..5
    output reg [2:0] red_placed_count,   // 0..5
    output reg placing_red,              // 0 = blue placing, 1 = red placing
    output reg placement_done            // 1-clock pulse after red's 5th
);

    wire [7:0] cell_address;
    wire cell_empty;
    wire red_full;

    assign cell_address     = {mouse_row, mouse_col};
    assign map_read_address = cell_address;
    assign cell_empty       = (map_read_owner == 0);
    assign red_full         = (red_placed_count == 3'd5);

    always @(posedge CLOCK_50 or negedge resetn) begin
        if (!resetn) begin
            map_write_enable  <= 1'b0;
            map_write_address <= 8'd0;
            map_write_owner   <= 2'b00;
            blue_placed_count <= 3'd0;
            red_placed_count  <= 3'd0;
            placing_red       <= 1'b0;
            placement_done    <= 1'b0;
        end
        else begin
            map_write_enable <= 1'b0;     // default: write is only a pulse
            placement_done   <= 1'b0;     // default: done is only a pulse

            if (!placement_enable) begin
                // not placing: clear everything for the next game
                blue_placed_count <= 0;
                red_placed_count  <= 0;
                placing_red       <= 0;
            end
            else if (mouse_click && cell_empty && !red_full) begin
                map_write_enable  <= 1'b1;
                map_write_address <= cell_address;

                if (placing_red == 1'b0) begin
                    map_write_owner   <= 2'b01;                 // blue code
                    blue_placed_count <= blue_placed_count + 1'b1;
                    if (blue_placed_count == 4)             // this click is the 5th
                        placing_red <= 1'b1;
                end
                else begin
                    map_write_owner  <= 2'b10;                  // red code
                    red_placed_count <= red_placed_count + 1'b1;
                    if (red_placed_count == 4)              // this click is the 5th
                        placement_done <= 1'b1;
                end
            end
        end
    end
endmodule
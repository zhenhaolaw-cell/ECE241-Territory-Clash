module map_memory (
    input CLOCK_50,
    input resetn,
    input write_enable,
    input [7:0] write_address,
    input [1:0] write_owner,
    input [7:0] read_address,

    output [1:0] read_owner,
    output reg clear_done
);

    reg [1:0] map [0:255];
    reg [7:0] clear_address;
    reg clearing;

    // Read the owner of the selected cell
    assign read_owner = map[read_address];

    // Clear the map after reset and handle normal writes
    always @(posedge CLOCK_50 or negedge resetn) begin
        if (!resetn) begin
            clear_address <= 8'd0;
            clearing <= 1'b1;
            clear_done <= 1'b0;
        end
        else if (clearing) begin
            map[clear_address] <= 2'b00;

            if (clear_address == 8'd255) begin
                clearing <= 1'b0;
                clear_done <= 1'b1;
            end
            else begin
                clear_address <= clear_address + 1'b1;
            end
        end
        else if (write_enable) begin
            map[write_address] <= write_owner;
        end
    end

endmodule

module snapshot_memory (
    input CLOCK_50,
    input resetn,
    input snapshot_start,
    input [1:0] map_read_owner,
    input [7:0] snapshot_read_address,

    output [7:0] map_read_address,
    output [1:0] snapshot_read_owner,
    output reg snapshot_busy,
    output reg snapshot_done
);

    reg [1:0] snapshot [0:255];
    reg [7:0] copy_address;

    // Read a saved cell without changing the snapshot
    assign snapshot_read_owner = snapshot[snapshot_read_address];

    // Request the current cell from Map Memory
    assign map_read_address = copy_address;

    // Copy one cell per clock while a snapshot is in progress
    always @(posedge CLOCK_50 or negedge resetn) begin
        if (!resetn) begin
            copy_address <= 8'd0;
            snapshot_busy <= 1'b0;
            snapshot_done <= 1'b0;
        end
        else begin
            snapshot_done <= 1'b0;

            if (!snapshot_busy) begin
                if (snapshot_start) begin
                    copy_address <= 8'd0;
                    snapshot_busy <= 1'b1;
                end
            end
            else begin
                snapshot[copy_address] <= map_read_owner;

                if (copy_address == 8'd255) begin
                    snapshot_busy <= 1'b0;
                    snapshot_done <= 1'b1;
                end
                else begin
                    copy_address <= copy_address + 1'b1;
                end
            end
        end
    end

endmodule

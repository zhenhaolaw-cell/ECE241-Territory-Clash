
module grid_renderer (
    input CLOCK_50,
    input resetn,

    output [8:0] x,
    output [7:0] y,
    output [8:0] color,
    output write,
    output reg done
);

    // Current position inside the entire map.
    // Range: 0 to 160, including the outer border.
    reg [7:0] local_x;
    reg [7:0] local_y;

    // Position inside a 10x10 grid cell.
    // Range: 0 to 9.
    reg [3:0] in_cell_x;
    reg [3:0] in_cell_y;

    // Indicates whether the grid is being drawn.
    reg drawing;

    // Convert local map coordinates to VGA coordinates.
    // The map starts at (80, 40).
    assign x = 9'd80 + {1'b0, local_x};
    assign y = 8'd40 + local_y;

    // Draw white grid lines using 9-bit RGB.
    assign color = 9'b111_111_111;

    // Draw only the vertical and horizontal grid lines.
    // Offset 0 represents the beginning of each cell.
    assign write = drawing &&
                   ((in_cell_x == 4'd0) ||
                    (in_cell_y == 4'd0));

    always @(posedge CLOCK_50)
    begin
        if (!resetn)
        begin
            // Reset all counters to the first pixel.
            local_x <= 8'd0;
            local_y <= 8'd0;

            in_cell_x <= 4'd0;
            in_cell_y <= 4'd0;

            drawing <= 1'b1;
            done <= 1'b0;
        end
        else if (drawing)
        begin
            // Update the horizontal position inside a cell.
            if (in_cell_x == 4'd9)
                in_cell_x <= 4'd0;
            else
                in_cell_x <= in_cell_x + 1'b1;

            // Check whether the current row is finished.
            if (local_x == 8'd160)
            begin
                // Return to the beginning of the next row.
                local_x <= 8'd0;
                in_cell_x <= 4'd0;

                // Check whether the entire map is finished.
                if (local_y == 8'd160)
                begin
                    drawing <= 1'b0;
                    done <= 1'b1;
                end
                else
                begin
                    // Move to the next row of pixels.
                    local_y <= local_y + 1'b1;

                    // Update the vertical position inside a cell.
                    if (in_cell_y == 4'd9)
                        in_cell_y <= 4'd0;
                    else
                        in_cell_y <= in_cell_y + 1'b1;
                end
            end
            else
            begin
                // Move to the next pixel in the current row.
                local_x <= local_x + 1'b1;
            end
        end
    end

endmodule

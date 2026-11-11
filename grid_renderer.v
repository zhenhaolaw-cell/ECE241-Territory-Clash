
module grid_renderer (
    input CLOCK_50,
    input resetn,

    output [9:0] x,
    output [8:0] y,
    output [8:0] color,
    output write,
    output reg done
);

    // ==========================================
    // Part 1: Pixel counters
    // ==========================================

    // Position inside the entire grid.
    // Range: 0 to 320 (including outer borders).
    reg [8:0] local_x;
    reg [8:0] local_y;

    // Position inside a 20x20 cell.
    // Range: 0 to 19.
    reg [4:0] in_cell_x;
    reg [4:0] in_cell_y;

    // 1 means the module is drawing.
    reg drawing;

    // ==========================================
    // Part 2: VGA coordinates
    // ==========================================

    // The grid starts at (160, 100).
    // Each cell is 20x20 pixels.
    // Total grid size: 320x320 pixels,
    // plus the final border.

    assign x = 10'd160 + {1'b0, local_x};
    assign y = 9'd100 + local_y;

    // White grid lines
    assign color = 9'b111_111_111;

    // ==========================================
    // Part 3: Grid line detection
    // ==========================================

    // Draw when X or Y is at the start
    // of a cell.
    //
    // For example:
    // X = 0, 20, 40, 60, ... 320
    // Y = 0, 20, 40, 60, ... 320
    //
    // Otherwise, keep the background pixel.

    assign write = drawing &&
                   ((in_cell_x == 5'd0) ||
                    (in_cell_y == 5'd0));

    // ==========================================
    // Part 4: Drawing counter logic
    // ==========================================

    always @(posedge CLOCK_50)
    begin
        // Reset all counters
        if (!resetn)
        begin
            local_x <= 9'd0;
            local_y <= 9'd0;

            in_cell_x <= 5'd0;
            in_cell_y <= 5'd0;

            drawing <= 1'b1;
            done <= 1'b0;
        end

        // Draw the grid one pixel position
        // at a time.
        else if (drawing)
        begin
            // Move to the next X position
            // inside a cell.
            if (in_cell_x == 5'd19)
                in_cell_x <= 5'd0;
            else
                in_cell_x <= in_cell_x + 1'b1;

            // Reached the rightmost border
            if (local_x == 9'd320)
            begin
                // Return to the start of the row
                local_x <= 9'd0;
                in_cell_x <= 5'd0;

                // Reached the bottom border
                if (local_y == 9'd320)
                begin
                    drawing <= 1'b0;
                    done <= 1'b1;
                end
                else
                begin
                    // Move down one row
                    local_y <= local_y + 1'b1;

                    // Update position inside cell
                    if (in_cell_y == 5'd19)
                        in_cell_y <= 5'd0;
                    else
                        in_cell_y <= in_cell_y + 1'b1;
                end
            end
            else
            begin
                // Continue horizontally
                local_x <= local_x + 1'b1;
            end
        end
    end

endmodule

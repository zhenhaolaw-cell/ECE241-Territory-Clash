
module cell_renderer (
    input CLOCK_50,
    input resetn,

    input start,
    input [3:0] row,
    input [3:0] col,
    input [8:0] cell_color,

    output [8:0] x,
    output [7:0] y,
    output [8:0] color,
    output write,

    output busy,
    output reg done
);

    
    // Part 1: FSM States

    // IDLE: Wait for a drawing request.
    // DRAW: Write the 9x9 interior pixels.
    // FINISH: Send a one-clock done pulse.

    localparam IDLE   = 2'd0;
    localparam DRAW   = 2'd1;
    localparam FINISH = 2'd2;

    reg [1:0] state;


    // Part 2: Save the drawing request

    // Store row, column, and color when
    // a new drawing request is received.
    // This prevents input changes from
    // affecting a drawing in progress.

    reg [3:0] saved_row;
    reg [3:0] saved_col;
    reg [8:0] saved_color;
	 
    // Position inside the selected cell.
    // Range: 1 to 9.
    // Offset 0 is reserved for grid lines.

    reg [3:0] offset_x;
    reg [3:0] offset_y;

    // Part 3: Calculate VGA coordinates

    // Map starts at (80, 40).
    // Each cell is 10x10 pixels.
    // The first interior pixel is offset (1,1).

    assign x = 9'd80
             + (saved_col * 9'd10)
             + {5'd0, offset_x};

    assign y = 8'd40
             + (saved_row * 8'd10)
             + {4'd0, offset_y};

    // Use the color saved at start.
    assign color = saved_color;

    // Write pixels only during DRAW.
    assign write = (state == DRAW);

    // Renderer is busy except during IDLE.
    assign busy = (state != IDLE);

    // Part 4: FSM and pixel counters


    always @(posedge CLOCK_50)
    begin
        if (!resetn)
        begin
            state <= IDLE;

            saved_row <= 4'd0;
            saved_col <= 4'd0;
            saved_color <= 9'd0;

            offset_x <= 4'd1;
            offset_y <= 4'd1;

            done <= 1'b0;
        end
        else
        begin
            // Default: done is low.
            // It becomes high for one clock
            // when a drawing finishes.
            done <= 1'b0;

            case (state)

               
                // State 1: IDLE

                IDLE:
                begin
                    if (start)
                    begin
                        // Save drawing inputs.
                        saved_row <= row;
                        saved_col <= col;
                        saved_color <= cell_color;

                        // Start at the first
                        // interior pixel.
                        offset_x <= 4'd1;
                        offset_y <= 4'd1;

                        state <= DRAW;
                    end
                end


                // State 2: DRAW


                DRAW:
                begin
                    // One pixel is written
                    // during each clock cycle.

                    if (offset_x == 4'd9)
                    begin
                        // End of current row.
                        offset_x <= 4'd1;

                        if (offset_y == 4'd9)
                        begin
                            // All 9 rows finished.
                            state <= FINISH;
                        end
                        else
                        begin
                            // Move to next row.
                            offset_y <= offset_y + 1'b1;
                        end
                    end
                    else
                    begin
                        // Move to next pixel.
                        offset_x <= offset_x + 1'b1;
                    end
                end

              
                // State 3: FINISH
                

                FINISH:
                begin
                    done <= 1'b1;
                    state <= IDLE;
                end

                default:
                    state <= IDLE;

            endcase
        end
    end

endmodule

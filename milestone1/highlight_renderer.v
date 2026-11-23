module highlight_renderer (
    input CLOCK_50,
    input resetn, // active-low (KEY[0])

    input enable, // connect to grid_done: don't draw before the grid exists
    input cell_busy, // from cell_renderer: wait while it is drawing

    input [3:0] cur_row, // from mouse_cursor
    input [3:0] cur_col,

    output [8:0] x, // to the VGA selector (same as the other renderers)
    output [7:0] y,
    output [8:0] color,
    output write,

    output busy // 1 while erasing or drawing
);

    // Section 1: FSM states and colours
    parameter IDLE  = 2'd0;
    parameter ERASE = 2'd1;
    parameter DRAW  = 2'd2;

    parameter WHITE  = 9'b111111111; // grid-line colour {RRR,GGG,BBB}
    parameter YELLOW = 9'b111111000; // red + green, no blue

    reg [1:0] state;

    // Section 2: Registers (what the module remembers)
    reg [3:0] drawn_row; // cell that currently HAS the yellow outline
    reg [3:0] drawn_col;
    reg [3:0] new_row; // cell we are moving the outline TO (saved at start)
    reg [3:0] new_col;
    reg has_outline; // 0 until the first outline has been drawn

    reg [3:0] offset_x; // position on the 11x11 box, 0..10
    reg [3:0] offset_y;

    // Section 3: Pixel position, colour and write (combinational)
    reg [3:0] box_row;
    reg [3:0] box_col;
    reg [8:0] box_color;

    always @(*)
    begin
        if (state == ERASE)
        begin
            box_row = drawn_row;
            box_col = drawn_col;
            box_color = WHITE;
        end
        else
        begin
            box_row = new_row;
            box_col = new_col;
            box_color = YELLOW;
        end
    end

    // Top-left corner of a cell is (80 + 10*col, 40 + 10*row),
    assign x = 9'd80 + (box_col * 9'd10) + {5'd0, offset_x};
    assign y = 8'd40 + (box_row * 8'd10) + {4'd0, offset_y};

    assign color = box_color;

    // A pixel is on the border if it is on the first/last column or row of the box
    wire on_edge;
    assign on_edge = (offset_x == 4'd0) | (offset_x == 4'd10) |
                     (offset_y == 4'd0) | (offset_y == 4'd10);

    // Write only while ERASE or DRAW, and only on the border
    assign write = ((state == ERASE) | (state == DRAW)) & on_edge;

    assign busy = (state != IDLE);

    // Section 4: FSM and the box counters
    always @(posedge CLOCK_50)
    begin
        if (!resetn)
        begin
            state <= IDLE;
            drawn_row <= 4'd8; // centre, same as mouse_cursor's start
            drawn_col <= 4'd8;
            new_row <= 4'd8;
            new_col <= 4'd8;
            has_outline <= 1'b0;
            offset_x <= 4'd0;
            offset_y <= 4'd0;
        end
        else
        begin
            case (state)

                IDLE:
                begin
                    // Start when: enabled, cell_renderer not busy, AND
                    if (enable && !cell_busy &&
                        ( !has_outline || (cur_row != drawn_row) || (cur_col != drawn_col) ))
                    begin
                        new_row <= cur_row; // save the target cell
                        new_col <= cur_col;
                        offset_x <= 4'd0;
                        offset_y <= 4'd0;
                        state <= ERASE;
                    end
                end

                ERASE: // walk the OLD box, writing white
                begin
                    if (offset_x == 4'd10)
                    begin
                        offset_x <= 4'd0; // back to the left edge
                        if (offset_y == 4'd10)
                        begin
                            offset_y <= 4'd0; // old box erased
                            state <= DRAW; // now draw the new one
                        end
                        else
                            offset_y <= offset_y + 4'd1;
                    end
                    else
                        offset_x <= offset_x + 4'd1;
                end

                DRAW: // walk the NEW box, writing yellow
                begin
                    if (offset_x == 4'd10)
                    begin
                        offset_x <= 4'd0; // back to the left edge
                        if (offset_y == 4'd10)
                        begin
                            offset_y <= 4'd0; // new box finished
                            drawn_row <= new_row; // outline is now here
                            drawn_col <= new_col;
                            has_outline <= 1;
                            state <= IDLE;
                        end
                        else
                            offset_y <= offset_y + 4'd1; // next row of the box
                    end
                    else
                        offset_x <= offset_x + 4'd1; // next pixel in this row
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule

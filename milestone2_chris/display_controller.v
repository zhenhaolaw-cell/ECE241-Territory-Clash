module display_controller (
    input CLOCK_50,
    input resetn,
    input refresh_start,            // 1-clock pulse: "redraw everything"
    input hl_busy,                  // highlight is drawing: don't interrupt it
    input [1:0] map_read_owner,     // owner of display_read_address
    input ui_done,
    input cell_done,

    output [7:0] display_read_address,
    output reg ui_start,
    output reg cell_start,
    output [3:0] cell_row,
    output [3:0] cell_col,
    output reg [8:0] cell_color,
    output reg drawing_ui,          // 1 = VGA should take ui_renderer's pixels
    output refresh_busy,            // 1 = pause the highlight
    output reg refresh_done
);
    `include "game_defs.vh"

    localparam D_IDLE       = 2'd0;
    localparam D_UI_WAIT    = 2'd1;
    localparam D_CELL_START = 2'd2;
    localparam D_CELL_WAIT  = 2'd3;

    reg [1:0] state;
    reg [7:0] cell_addr;
    reg pending;                    // remembers a refresh request

    // ---- the current cell: address, row, col ----
    assign display_read_address = cell_addr;
    assign cell_row = cell_addr[____:____];
    assign cell_col = cell_addr[____:____];
    assign refresh_busy = (state != ____);

    // ---- owner -> colour ----
    always @(*) begin
        if (map_read_owner == BLUE)      cell_color = ____;
        else if (map_read_owner == RED)  cell_color = ____;
        else                             cell_color = ____;
    end

    // ---- the sequence ----
    always @(posedge CLOCK_50 or negedge resetn) begin
        if (!resetn) begin
            state        <= D_IDLE;
            cell_addr    <= 8'd0;
            pending      <= 1'b0;
            ui_start     <= 1'b0;
            cell_start   <= 1'b0;
            drawing_ui   <= 1'b0;
            refresh_done <= 1'b0;
        end
        else begin
            ui_start     <= 1'b0;       // pulses by default
            cell_start   <= 1'b0;
            refresh_done <= 1'b0;

            if (refresh_start)
                pending <= ____;        // remember the request

            case (state)
                D_IDLE: begin
                    if (pending && !hl_busy) begin
                        pending    <= ____;
                        ui_start   <= ____;
                        drawing_ui <= ____;
                        state      <= D_UI_WAIT;
                    end
                end

                D_UI_WAIT: begin
                    if (ui_done) begin
                        drawing_ui <= ____;
                        cell_addr  <= ____;     // start at cell 0
                        state      <= ____;
                    end
                end

                D_CELL_START: begin
                    cell_start <= ____;          // colour and row/col are ready now
                    state      <= ____;
                end

                D_CELL_WAIT: begin
                    if (cell_done) begin
                        if (cell_addr == ____) begin      // last cell
                            refresh_done <= ____;
                            state        <= ____;
                        end
                        else begin
                            cell_addr <= ____;
                            state     <= ____;            // next cell
                        end
                    end
                end
            endcase
        end
    end
endmodule
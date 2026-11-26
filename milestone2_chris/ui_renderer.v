module ui_renderer #(
    parameter TEXT_X = 9'd8,      // top-left of the text box (pick later)
    parameter TEXT_Y = 8'd4
)(
    input CLOCK_50,
    input resetn,
    input ui_start,
    input [3:0] game_state,
    input [3:0] preview_character_id,
    input [6:0] preview_armour,
    input [6:0] preview_probability,
    input [2:0] blue_placed_count,
    input [2:0] red_placed_count,
    input [7:0] turn_count,
    input [1:0] winner,

    output [8:0] x,
    output [7:0] y,
    output reg [8:0] color,
    output write,
    output reg ui_busy,
    output reg ui_done
);
    `include "game_defs.vh"

    // ---------- 1) counter split ----------
    reg  [10:0] pixel_count;
    wire [4:0]  char_index = pixel_count[10:6];
    wire [2:0]  font_row   = pixel_count[5:3];
    wire [2:0]  font_col   = pixel_count[2:0];

    // ---------- 2) decimal digits of numbers ----------
    wire [3:0] id_t   = preview_character_id / 10; 
    wire [3:0] id_o   = preview_character_id % 10;
    wire [3:0] arm_h  = preview_armour / 100;
    wire [3:0] arm_t  = (preview_armour / 10) % 10;
    wire [3:0] arm_o  = preview_armour % 10;
    wire [3:0] turn_h = turn_count / 100;
    wire [3:0] turn_t = (turn_count/10) % 10;
    wire [3:0] turn_o = turn_count % 10;
    //

    // ---------- 3) the text for each screen (exactly 16 chars per line!) ----------
    reg [127:0] line0, line1;
    always @(*) begin
        line0 = "                ";   // 16 spaces = default
        line1 = "                ";
        case (game_state)
            SELECT_BLUE: begin
                line0 = {"BLUE PICK ID ", 4'h3, id_t, 4'h3, id_o, " "};               // 13+2+1 = 16
                line1 = {"ARMOUR ", 4'h3, arm_h, 4'h3, arm_t, 4'h3, arm_o, "      "};  // 7+3+6 = 16
            end
            SELECT_RED: begin
                line0 = {"RED PICK ID ", 4'h3, id_t, 4'h3, id_o, "  "};               // 13+2+1 = 16
                line1 = {"ARMOUR ", 4'h3, arm_h, 4'h3, arm_t, 4'h3, arm_o, "      "};
            end
            PLACE_BLUE: begin
                line0 = {"BLUE PLACE ", 4'h3, 1'b0, blue_placed_count, "/5  "};       // 11+1+4 = 16
            end
            PLACE_RED: begin
                line0 = {"RED PLACE ", 4'h3, 1'b0, red_placed_count, "/5   "};
            end
            BATTLE: begin
                line0 = {"TURN ", 4'h3, turn_h, 4'h3, turn_t, 4'h3, turn_o, "        "};                                  // 5+3+8 = 16
            end
            GAME_OVER: begin
                if (winner == WIN_BLUE)      line0 = "BLUE WINS       ";
                else if (winner == WIN_RED)               line0 = "RED WINS        ";
                else                         line0 = "DRAW            ";
            end
        endcase
    end

    // ---------- 4) pick this character's code ----------
    reg [127:0] cur_line;
    reg [7:0]   character_code;
    always @(*) begin
        if (char_index[4] == 1'b0) cur_line = line0;
        else cur_line = line1;

            case (char_index[3:0])
                4'd0:  character_code = cur_line[127:120];
                4'd1:  character_code = cur_line[119:112];
                4'd2:  character_code = cur_line[111:104];
                4'd3:  character_code = cur_line[103:96];
                4'd4:  character_code = cur_line[95:88];
                4'd5:  character_code = cur_line[87:80];
                4'd6:  character_code = cur_line[79:72];
                4'd7:  character_code = cur_line[71:64];
                4'd8:  character_code = cur_line[63:56];
                4'd9:  character_code = cur_line[55:48];
                4'd10: character_code = cur_line[47:40];
                4'd11: character_code = cur_line[39:32];
                4'd12: character_code = cur_line[31:24];
                4'd13: character_code = cur_line[23:16];
                4'd14: character_code = cur_line[15:8];
                4'd15: character_code = cur_line[7:0];
            default: character_code = 8'h20;   // space
        endcase
    end

    // ---------- 5) font lookup + colour ----------
    wire pixel_on;
    font_rom font (
        .character_code(character_code),
        .font_row(font_row),
        .font_col(font_col),
        .pixel_on(pixel_on)
    );

    always @(*) begin
        if (pixel_on) color = COLOR_WHITE;     // text colour
        else          color = COLOR_EMPTY;     // background
    end

    // ---------- 6) screen position ----------
    assign x = TEXT_X + {char_index[3:0], font_col};             // pos*8 + col
    assign y = TEXT_Y + {char_index[4], 1'b0, font_row};         // line*16 + row
    assign write = ui_busy;

    // ---------- 7) start / busy / done ----------
    always @(posedge CLOCK_50 or negedge resetn) begin
        if (!resetn) begin
            pixel_count <= 11'd0;
            ui_busy     <= 1'b0;
            ui_done     <= 1'b0;
        end
        else begin
            ui_done <= 1'b0;
            if (!ui_busy) begin
                if (ui_start) begin
                    pixel_count <= 11'd0;
                    ui_busy     <= 1;
                end
            end
            else if (pixel_count == 11'd2047) begin    // last pixel
                ui_busy <= 0;
                ui_done <= 1;
            end
            else
                pixel_count <= pixel_count + 1;
        end
    end
endmodule
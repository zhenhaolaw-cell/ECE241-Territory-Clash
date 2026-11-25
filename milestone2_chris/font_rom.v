module font_rom (
    input [7:0] character_code,   // ASCII: 'A' = 8'h41, '0' = 8'h30, ' ' = 8'h20
    input [2:0] font_row,         // 0 = top
    input [2:0] font_col,         // 0 = left
    output pixel_on
);
    reg [63:0] glyph;     // whole 8x8 picture, row 0 in the top byte
    reg [7:0]  row_bits;  // the one row we want

    // 1) pick the picture for this character
    always @(*) begin
        case (character_code)
            8'h41: glyph = 64'h3C66667E66666600;   // A
            8'h30: glyph = 64'h3C66666666663C00;   // 0  (draw it!)
            // ... B-Z, 1-9, ':', '/', '%'
            default: glyph = 64'h0;                 // space / unknown = blank
        endcase
    end

    // 2) pick one row out of the picture
    always @(*) begin
        case (font_row)
            3'd0: row_bits = glyph[63:56];
            3'd1: row_bits = glyph[55:48];
            3'd2: row_bits = glyph[47:40];
            3'd3: row_bits = glyph[39:32];
            3'd4: row_bits = glyph[31:24];
            3'd5: row_bits = glyph[23:16];
            3'd6: row_bits = glyph[15:8];
            3'd7: row_bits = glyph[7:0];
            default: row_bits = 8'h00;
        endcase
    end

    // 3) pick one pixel out of the row (col 0 is the LEFT = bit 7)
    assign pixel_on = row_bits[3'd7 - font_col];
endmodule
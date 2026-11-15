// ============================================================================
// mouse_cursor.v  -  Territory Clash (ECE 241 term project)
// Author: Chris Zhou
//
// PURPOSE
//   Turns the bytes coming out of the course PS2_Controller (mouse mode) into
//   a cursor cell position (row, col 0-15) and a one-clock "click" pulse.
//
// INPUT FROM PS2_Controller (provided IP, INITIALIZE_MOUSE = 1)
//   received_data[7:0] : last byte received from the mouse
//   received_data_en   : 1 for ONE clock when a new byte arrives
//
// MOUSE PACKET = 3 bytes, one at a time
//   Byte 0 : bit7 Y ovf | bit6 X ovf | bit5 Y sign | bit4 X sign |
//            bit3 ALWAYS 1 | bit2 middle | bit1 right | bit0 left
//   Byte 1 : X movement (low 8 bits)       dx = {X sign, byte1}  (9-bit 2's comp)
//   Byte 2 : Y movement (low 8 bits)       dy = {Y sign, byte2}  (9-bit 2's comp)
//   NOTE: after reset the mouse answers the enable command with FA (ack).
//         FA is NOT part of a packet -> ignore it when waiting for byte 0.
//   NOTE: mouse +Y = moving UP, but screen rows grow DOWN -> subtract dy.
//
// CURSOR POSITION
//   pos_x, pos_y are 8-bit (0-255) "fine" positions, clamped at 0 and 255.
//   cell = top 4 bits:  cur_col = pos_x[7:4],  cur_row = pos_y[7:4]
//   (16 mouse counts per cell, about 4 mm of mouse movement)
// ============================================================================

module mouse_cursor (
    input            CLOCK_50,
    input            resetn,            // active-low (KEY[0])

    input      [7:0] received_data,     // from PS2_Controller
    input            received_data_en,  // from PS2_Controller

    output     [3:0] cur_row,           // cursor cell row,    0-15
    output     [3:0] cur_col,           // cursor cell column, 0-15
    output reg       click,             // 1 for one clock on left-button press
    output reg       packet_ready       // 1 for one clock after byte 2 (handy for testing)
);

    // ---------------- internal signals ----------------
    reg  [1:0] byte_count;              // which byte we expect next: 0, 1, 2
    reg  [7:0] byte0, byte1;            // saved bytes 0 and 1
    reg  [7:0] byte2;                   // saved byte 2

    wire signed [8:0] dx;               // X movement, 9-bit two's complement
    wire signed [8:0] dy;               // Y movement, 9-bit two's complement

    reg  [7:0] pos_x;                   // fine position, 0-255
    reg  [7:0] pos_y;                   // fine position, 0-255

    reg        left_prev;               // left button from the previous packet

    // ========================================================================
    // 1) Packet assembler
    // TODO: on posedge CLOCK_50:
    //   - reset: byte_count <= 0, packet_ready <= 0
    //   - default each clock: packet_ready <= 0
    //   - when received_data_en:
    //       byte_count 0: if the byte is a real byte 0 (bit 3 = 1 AND not 8'hFA)
    //                     save it in byte0, go to 1.  Otherwise stay at 0.
    //       byte_count 1: save byte1, go to 2
    //       byte_count 2: save byte2, go to 0, packet_ready <= 1
    // ========================================================================
    always @(posedge CLOCK_50) begin
    if (!resetn)
    begin //Reset section
        byte_count <= 0;
        packet_ready <= 1'b0;
        byte0 <= 8'd0;  byte1 <= 8'd0;  byte2 <= 8'd0;
    end
    else
    begin //Cases
        packet_ready <= 1'b0;

        if (received_data_en)
        begin
            case (byte_count)
                2'd0: if ( (received_data[3] == 1'b1) && (received_data != 8'hFA) )   // real byte 0?
                      begin
                          byte0 <= received_data;
                          byte_count <= 1;
                      end

                2'd1: begin
                          byte1 <= received_data;
                          byte_count <= 2;
                      end

                2'd2: begin
                          byte2 <= received_data;
                          byte_count <= 0;
                          packet_ready <= 1;
                      end

                default: byte_count <= 2'd0;
            endcase
        end
    end
    end

    // ========================================================================
    // 2) Movement values
    // TODO: dx = {byte0[4], byte1}
    //       dy = {byte0[5], byte2}
    //   Byte 1 : X movement (low 8 bits)       dx = {X sign, byte1}  (9-bit 2's comp)
    //   Byte 2 : Y movement (low 8 bits)       dy = {Y sign, byte2}  (9-bit 2's comp)
    // ========================================================================
    assign dx = {byte0[4], byte1};
    assign dy = {byte0[5], byte2};

    // ========================================================================
    // 3) Position update with clamping (only when packet_ready)
    // TODO: on posedge CLOCK_50:
    //   - reset: start in the middle of the board, e.g. pos_x = pos_y = 8'd128
    //   - when packet_ready:
    //       new_x = pos_x + dx      -> if below 0 use 0, if above 255 use 255
    //       new_y = pos_y - dy      -> same clamping   (note the MINUS)
    //   HINT: do the maths in a wider signed number (e.g. 11 bits) so you can
    //         SEE that it went below 0 or above 255 before clamping.
    //         Example:  wire signed [10:0] sum_x = $signed({3'b000, pos_x}) + dx;
    //   CAREFUL: packet_ready is a register, so it is high the clock AFTER
    //            byte 2 was saved - byte2 is already valid by then. Good.
    // ========================================================================
    wire [10:0] wide_x; //x
    assign wide_x[7:0]  = pos_x;
    assign wide_x[10:8] = 3'b000;

    wire [10:0] wide_dx;
    assign wide_dx[8:0] = dx;
    assign wide_dx[9]   = dx[8];
    assign wide_dx[10]  = dx[8];

    wire [10:0] sum_x;
    assign sum_x = wide_x + wide_dx;

    wire [10:0] wide_y; //y
    assign wide_y[7:0]  = pos_y;
    assign wide_y[10:8] = 3'b000;

    wire [10:0] wide_dy;
    assign wide_dy[8:0] = dy;
    assign wide_dy[9]   = dy[8];
    assign wide_dy[10]  = dy[8];

    wire [10:0] sum_y;
    assign sum_y = wide_y - wide_dy; //minus cause the mouse y movement

    always @(posedge CLOCK_50)
    begin
    if (!resetn)
    begin
        pos_x <= 8'd128;     // middle of the board
        pos_y <= 8'd128;
    end
    else if (packet_ready)
    begin //clamping
        if(sum_x[10] == 1'b1) //if its negative
        pos_x <= 8'd0;
        else if((sum_x[9] | sum_x[8]) == 1'b1) //if it overflow
        pos_x <= 8'd255;
        else   
        pos_x <= sum_x[7:0];

        if(sum_y[10] == 1'b1) //if its negative
        pos_y <= 8'd0;
        else if((sum_y[9] | sum_y[8]) == 1'b1) //if it overflow
        pos_y <= 8'd255;
        else   
        pos_y <= sum_y[7:0];
    end
    end

    // ========================================================================
    // 4) Cell outputs
    // TODO: cur_col = pos_x[7:4]
    //       cur_row = pos_y[7:4]
    // ========================================================================
    assign cur_col = pos_x[7:4];
    assign cur_row = pos_y[7:4];

    always @(posedge CLOCK_50)
    begin
    if (!resetn)
    begin
        click <= 1'b0;
        left_prev <= 1'b0;
    end
    else
    begin
        click <= 1'b0; // default
        if (packet_ready)
        begin
            if ((byte0[0] == 1) && (left_prev == 0))
                click <= 1;
            left_prev <= byte0[0]; //memory
        end
    end
    end

    // ========================================================================
    // 5) Click = rising edge of the left button (byte0[0]) between packets
    // TODO: on posedge CLOCK_50:
    //   - reset: click <= 0, left_prev <= 0
    //   - default: click <= 0
    //   - when packet_ready:
    //       if (left button now == 1 and left_prev == 0) click <= 1
    //       left_prev <= left button now
    // ========================================================================


endmodule

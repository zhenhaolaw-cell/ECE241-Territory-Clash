`timescale 1ns / 1ps

// ============================================================================
// testbench.v  -  testbench for mouse_cursor.v
//
// Pretends to be the PS2_Controller: sends mouse bytes one at a time, each
// with a one-clock received_data_en pulse. After every packet it prints the
// cursor cell (cur_col, cur_row) and whether a click pulse happened.
// Cursor starts at pos 128,128  ->  cur_col = 8, cur_row = 8.
// ============================================================================

module testbench ( );

    parameter CLOCK_PERIOD = 20;        // 50 MHz

    reg        CLOCK_50;
    reg        resetn;
    reg  [7:0] received_data;
    reg        received_data_en;

    wire [3:0] cur_row;
    wire [3:0] cur_col;
    wire       click;
    wire       packet_ready;

    integer    clicks_seen;             // click pulses since the last print
    integer    total_clicks;
    integer    i;
    integer    hold_start_clicks;

    // ---------------- clock ----------------
    initial begin
        CLOCK_50 <= 1'b0;
    end // initial
    always @ (*)
    begin : Clock_Generator
        #((CLOCK_PERIOD) / 2) CLOCK_50 <= ~CLOCK_50;
    end

    // ---------------- device under test ----------------
    mouse_cursor U1 (
        .CLOCK_50         (CLOCK_50),
        .resetn           (resetn),
        .received_data    (received_data),
        .received_data_en (received_data_en),
        .cur_row          (cur_row),
        .cur_col          (cur_col),
        .click            (click),
        .packet_ready     (packet_ready)
    );

    // count click pulses so we can print them after each packet
    always @(posedge CLOCK_50)
        if (click) begin
            clicks_seen  = clicks_seen + 1;
            total_clicks = total_clicks + 1;
        end

    // ---------------- send one byte ----------------
    // Like the PS2_Controller: put the byte on received_data and raise
    // received_data_en for exactly one clock (inputs change on negedge),
    // then wait 5 clocks before the next byte.
    task send_byte;
        input [7:0] b;
        begin
            @(negedge CLOCK_50);
            received_data    <= b;
            received_data_en <= 1'b1;
            @(negedge CLOCK_50);
            received_data_en <= 1'b0;
            repeat (5) @(negedge CLOCK_50);
        end
    endtask

    // ---------------- send one 3-byte packet and print the result ----------------
    task send_packet;
        input [7:0] b0, b1, b2;
        begin
            send_byte(b0);
            send_byte(b1);
            send_byte(b2);
            $display("t=%0d ns  packet %h %h %h  ->  cur_col=%0d cur_row=%0d  pos_x=%0d pos_y=%0d  click=%0d",
                     $time, b0, b1, b2, cur_col, cur_row, U1.pos_x, U1.pos_y, clicks_seen);
            clicks_seen = 0;
        end
    endtask

    // ---------------- test sequence ----------------
    initial begin
        clicks_seen      = 0;
        total_clicks     = 0;
        received_data    <= 8'h00;
        received_data_en <= 1'b0;

        // reset: low for 2 clocks, then high
        resetn <= 1'b0;
        repeat (2) @(negedge CLOCK_50);
        resetn <= 1'b1;
        $display("t=%0d ns  after reset  ->  cur_col=%0d cur_row=%0d  (expect 8, 8)",
                 $time, cur_col, cur_row);

        // FA = acknowledge from the mouse after reset. NOT part of a packet,
        // must be ignored (cursor must not move, framing must not shift).
        send_byte(8'hFA);
        $display("t=%0d ns  sent FA (ack) ->  cur_col=%0d cur_row=%0d  (expect 8, 8)",
                 $time, cur_col, cur_row);

        // Move right: byte0 = 08 (bit3 always 1, no signs), X = +16, Y = 0
        // expect cur_col 8 -> 9
        send_packet(8'h08, 8'h10, 8'h00);

        // Move down: byte0 = 28 (Y sign set), Y = F0 = -16
        // mouse -Y is DOWN on screen, so pos_y goes UP -> cur_row 8 -> 9
        send_packet(8'h28, 8'h00, 8'hF0);

        // Move left: byte0 = 18 (X sign set), X = F0 = -16
        // expect cur_col back to 8
        send_packet(8'h18, 8'hF0, 8'h00);

        // Left button pressed (byte0 bit0 = 1) -> exactly ONE click pulse
        send_packet(8'h09, 8'h00, 8'h00);

        // Left button still held -> NO new click
        send_packet(8'h09, 8'h00, 8'h00);

        // Left button released -> no click
        send_packet(8'h08, 8'h00, 8'h00);

        // New press -> one click pulse
        send_packet(8'h09, 8'h00, 8'h00);

        // 10 packets of X = +127: pos_x must stop (clamp) at 255 -> cur_col 15
        for (i = 0; i < 10; i = i + 1)
            send_packet(8'h08, 8'h7F, 8'h00);

        // ---------------- boundary tests ----------------
        // Each packet below would push the cursor PAST an edge, so the
        // sum goes outside 0-255 and the clamp must hold it at the edge.

        // LEFT edge: X = -256 (byte0 = 18, X sign set). 255 - 256 = -1 -> clamp to 0, cur_col 0
        send_packet(8'h18, 8'h00, 8'h00);

        // BOTTOM edge: Y = -256 (byte0 = 28, Y sign set) = mouse down.
        // pos_y = 144 + 256 = 400 -> clamp to 255, cur_row 15
        send_packet(8'h28, 8'h00, 8'h00);

        // TOP edge: Y = +255 (mouse up). pos_y = 255 - 255 = 0 (exactly the edge)
        send_packet(8'h08, 8'h00, 8'hFF);
        // Y = +64 more: 0 - 64 = -64 -> clamp to 0, cur_row stays 0
        send_packet(8'h08, 8'h00, 8'h40);

        // ---------------- long hold test ----------------
        // Press the left button and KEEP holding it for 6 packets while
        // also moving right by 16 each packet (like dragging).
        // Expect: exactly ONE click (on the first packet), none while held,
        // none on release - even though the cursor keeps moving.
        $display("--- hold test: press + hold for 6 packets, then release ---");
        hold_start_clicks = total_clicks;
        send_packet(8'h09, 8'h10, 8'h00);     // press      -> click = 1
        for (i = 0; i < 5; i = i + 1)
            send_packet(8'h09, 8'h10, 8'h00); // still held -> click = 0
        send_packet(8'h08, 8'h00, 8'h00);     // release    -> click = 0
        $display("hold test: clicks during hold test = %0d (expect 1)",
                 total_clicks - hold_start_clicks);

        $display("------------------------------------------------");
        $display("END: cur_col=%0d cur_row=%0d pos_x=%0d pos_y=%0d  total clicks=%0d  (expect col 6, row 0, pos_x 96, pos_y 0, 3 clicks)",
                 cur_col, cur_row, U1.pos_x, U1.pos_y, total_clicks);
        $display("------------------------------------------------");
    end

endmodule

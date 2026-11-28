`timescale 1ns / 1ps

module testbench ( );

    parameter CLOCK_PERIOD = 20;

    reg CLOCK_50;
    reg resetn;
    reg clear_start;
    reg request_valid;
    reg [7:0] request_target;
    reg [1:0] request_player;
    reg [1:0] request_target_owner;
    reg [6:0] blue_armour_start;
    reg [6:0] red_armour_start;
    reg [7:0] request_read_address;

    wire [1:0] request_flags;
    wire [10:0] attacks_on_blue;
    wire [10:0] attacks_on_red;
    wire clear_busy;
    wire clear_done;

    initial begin
        CLOCK_50 <= 1'b0;
    end

    always @ (*)
    begin : Clock_Generator
        #((CLOCK_PERIOD) / 2) CLOCK_50 <= ~CLOCK_50;
    end

    expansion_request_buffer U1 (
        CLOCK_50, resetn, clear_start,
        request_valid, request_target, request_player,
        request_target_owner, blue_armour_start,
        red_armour_start, request_read_address,
        request_flags, attacks_on_blue, attacks_on_red,
        clear_busy, clear_done
    );

    // Only simple timed stimulus; no tasks, loops, force, or assertions.
    initial begin
        resetn <= 1'b0;
        clear_start <= 1'b0;
        request_valid <= 1'b0;
        request_target <= 8'd0;
        request_player <= 2'b00;
        request_target_owner <= 2'b00;
        blue_armour_start <= 7'd50;
        red_armour_start <= 7'd50;
        request_read_address <= 8'd35;

        // 0-40 ns: reset; request memory itself is not reset.
        #40 resetn <= 1'b1;

        // 60 ns: start full 256-entry clear.
        #20 clear_start <= 1'b1;
        #20 clear_start <= 1'b0;

        // Clear starts at 70 ns; writes addresses 0..255 at
        // 90, 110, ... 5190 ns. clear_done is high 5190-5210 ns.
        #5160;

        // 5240 ns: Blue requests empty cell 35 (bit 0).
        request_valid <= 1'b1;
        request_target <= 8'd35;
        request_read_address <= 8'd35;
        request_player <= 2'b01;
        request_target_owner <= 2'b00;
        #20 request_valid <= 1'b0;
        #20;

        // 5280 ns: Red requests the same empty cell 35 (bit 1).
        request_valid <= 1'b1;
        request_target <= 8'd35;
        request_player <= 2'b10;
        request_target_owner <= 2'b00;
        #20 request_valid <= 1'b0;
        #20;

        // 5320 ns: Blue attacks Red with armour > 0.
        request_valid <= 1'b1;
        request_target <= 8'd36;
        request_player <= 2'b01;
        request_target_owner <= 2'b10;
        red_armour_start <= 7'd50;
        #20 request_valid <= 1'b0;
        #20;

        // 5360 ns: Second Blue attack -> attacks_on_red = 2.
        request_valid <= 1'b1;
        #20 request_valid <= 1'b0;
        #20;

        // 5400 ns: Red attacks Blue with armour > 0.
        request_valid <= 1'b1;
        request_target <= 8'd37;
        request_player <= 2'b10;
        request_target_owner <= 2'b01;
        blue_armour_start <= 7'd40;
        #20 request_valid <= 1'b0;
        #20;

        // 5440 ns: Blue captures Red-owned cell with zero armour.
        request_valid <= 1'b1;
        request_target <= 8'd36;
        request_read_address <= 8'd36;
        request_player <= 2'b01;
        request_target_owner <= 2'b10;
        red_armour_start <= 7'd0;
        #20 request_valid <= 1'b0;
        #20;

        // 5480 ns: Red captures Blue-owned cell with zero armour.
        request_valid <= 1'b1;
        request_target <= 8'd37;
        request_read_address <= 8'd37;
        request_player <= 2'b10;
        request_target_owner <= 2'b01;
        blue_armour_start <= 7'd0;
        #20 request_valid <= 1'b0;
        #20;

        // 5520 ns: Same-owner target must be ignored.
        request_valid <= 1'b1;
        request_target <= 8'd38;
        request_read_address <= 8'd38;
        request_player <= 2'b01;
        request_target_owner <= 2'b01;
        #20 request_valid <= 1'b0;
        #20;

        // 5560 ns: Invalid request must be ignored.
        request_valid <= 1'b0;
        request_target <= 8'd39;
        request_read_address <= 8'd39;
        request_player <= 2'b10;
        request_target_owner <= 2'b00;
        #40;

        // 5600 ns: start second clear; counters reset at 5610 ns.
        clear_start <= 1'b1;
        request_read_address <= 8'd35;
        #20 clear_start <= 1'b0;

        // 5620 ns: request_valid is asserted while clearing.
        // At 5630 ns the request is ignored because clear_busy=1.
        request_valid <= 1'b1;
        request_target <= 8'd40;
        request_player <= 2'b01;
        request_target_owner <= 2'b00;
        #20 request_valid <= 1'b0;

        // During clear, read addresses 35, 36, 37, then 40.
        // When each is cleared, request_flags goes to 00.
        #800 request_read_address <= 8'd36;
        #20 request_read_address <= 8'd37;
        #20 request_read_address <= 8'd40;

        // Final clear: 5630 + 255*20 = 10730 ns.
        #4300 request_read_address <= 8'd35;
        #80 request_read_address <= 8'd36;
        #40 request_read_address <= 8'd37;
    end

endmodule

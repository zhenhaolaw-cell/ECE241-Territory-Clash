`timescale 1ns / 1ps

module testbench ( );

    parameter CLOCK_PERIOD = 20;

    reg CLOCK_50;
    reg resetn;
    reg battle_start;

    reg [6:0] blue_armour_start;
    reg [6:0] red_armour_start;
    reg [10:0] attacks_on_blue;
    reg [10:0] attacks_on_red;
    reg [7:0] result_read_address;

    // Simulated outputs of Snapshot Memory and Expansion Request Buffer.
    reg [1:0] snapshot_owner;
    reg [1:0] request_flags;

    wire [7:0] snapshot_read_address;
    wire [7:0] request_read_address;
    wire [1:0] result_owner;
    wire [6:0] next_blue_armour;
    wire [6:0] next_red_armour;
    wire battle_busy;
    wire battle_done;

    // Exact DUT port order from milestone2_lex/battle_engine.v.
    battle_engine U1 (
        CLOCK_50, resetn, battle_start,
        snapshot_owner, request_flags,
        blue_armour_start, red_armour_start,
        attacks_on_blue, attacks_on_red,
        result_read_address,
        snapshot_read_address, request_read_address,
        result_owner,
        next_blue_armour, next_red_armour,
        battle_busy, battle_done
    );

    initial begin
        CLOCK_50 <= 1'b0;
    end

    always @ (*)
    begin : Clock_Generator
        #((CLOCK_PERIOD) / 2) CLOCK_50 <= ~CLOCK_50;
    end

    // Mock asynchronous Snapshot Memory and Request Buffer reads.
    // All unspecified cells are EMPTY, with no capture requests.
    always @ (*) begin
        snapshot_owner = 2'b00;
        case (snapshot_read_address)
            8'd13: snapshot_owner = 2'b01; // Blue-owned cell
            8'd14: snapshot_owner = 2'b10; // Red-owned cell
            8'd16: snapshot_owner = 2'b01; // Blue-owned cell, no request
            default: snapshot_owner = 2'b00;
        endcase

        request_flags = 2'b00;
        case (request_read_address)
            8'd10: request_flags = 2'b01; // Blue requests EMPTY
            8'd11: request_flags = 2'b10; // Red requests EMPTY
            8'd12: request_flags = 2'b11; // Both request EMPTY -> EMPTY
            8'd13: request_flags = 2'b10; // Red requests Blue cell
            8'd14: request_flags = 2'b01; // Blue requests Red cell
            default: request_flags = 2'b00;
        endcase
    end

    // Three battles: normal armour; zero armour at start;
    // and armour reduced to zero only in the current battle.
    initial begin
        resetn <= 1'b0;
        battle_start <= 1'b0;
        blue_armour_start <= 7'd50;
        red_armour_start <= 7'd40;
        attacks_on_blue <= 11'd3;
        attacks_on_red <= 11'd5;

        #40 resetn <= 1'b1;
        #20 battle_start <= 1'b1;  // t=60 ns, sampled at 70 ns
        #20 battle_start <= 1'b0;

        #5580;                     // t=5660 ns
        blue_armour_start <= 7'd0;
        red_armour_start <= 7'd0;
        attacks_on_blue <= 11'd2;
        attacks_on_red <= 11'd4;
        #40 battle_start <= 1'b1;  // t=5700 ns, sampled at 5710 ns
        #20 battle_start <= 1'b0;

        #5740;                     // t=11460 ns
        blue_armour_start <= 7'd4;
        red_armour_start <= 7'd2;
        attacks_on_blue <= 11'd9;
        attacks_on_red <= 11'd15;
        #40 battle_start <= 1'b1;  // t=11500 ns, sampled at 11510 ns
        #20 battle_start <= 1'b0;
    end

    // Emulate a Map Commit Controller reading saved results after each battle.
    initial begin
        result_read_address <= 8'd10;

        #5260 result_read_address <= 8'd10;
        #40 result_read_address <= 8'd11;
        #40 result_read_address <= 8'd12;
        #40 result_read_address <= 8'd13;
        #40 result_read_address <= 8'd14;
        #40 result_read_address <= 8'd15;
        #40 result_read_address <= 8'd16;

        #5360 result_read_address <= 8'd10; // t=10860 ns
        #40 result_read_address <= 8'd11;
        #40 result_read_address <= 8'd12;
        #40 result_read_address <= 8'd13;
        #40 result_read_address <= 8'd14;
        #40 result_read_address <= 8'd15;
        #40 result_read_address <= 8'd16;

        #5600 result_read_address <= 8'd10; // t=16700 ns
        #40 result_read_address <= 8'd11;
        #40 result_read_address <= 8'd12;
        #40 result_read_address <= 8'd13;
        #40 result_read_address <= 8'd14;
        #40 result_read_address <= 8'd15;
        #40 result_read_address <= 8'd16;
    end

endmodule

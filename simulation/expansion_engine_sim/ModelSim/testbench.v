`timescale 1ns / 1ps

module testbench ( );

    parameter CLOCK_PERIOD = 20;

    reg CLOCK_50;
    reg resetn;
    reg expansion_start;
    reg [7:0] turn_count;
    reg [7:0] blue_speed;
    reg [7:0] red_speed;
    reg [6:0] blue_probability;
    reg [6:0] red_probability;

    wire [7:0] snapshot_read_address;
    reg [1:0] snapshot_read_owner;
    wire [15:0] random_value;
    wire random_next;
    wire request_valid;
    wire [7:0] request_target;
    wire [1:0] request_player;
    wire [1:0] request_target_owner;
    wire expansion_busy;
    wire expansion_done;

    // Clock generator: 20 ns period (50 MHz).
    initial begin
        CLOCK_50 <= 1'b0;
    end

    always @ (*) begin : Clock_Generator
        #((CLOCK_PERIOD) / 2) CLOCK_50 <= ~CLOCK_50;
    end

    // Model the asynchronous Snapshot Memory read port.
    // Four occupied cells; all other cells are empty.
    // 0 = Blue (top-left corner)
    // 17 = Blue (interior cell)
    // 18 = Red (right neighbour of Blue 17)
    // 255 = Red (bottom-right corner)
    always @ (*) begin
        case (snapshot_read_address)
            8'd0:   snapshot_read_owner = 2'b01;
            8'd17:  snapshot_read_owner = 2'b01;
            8'd18:  snapshot_read_owner = 2'b10;
            8'd255: snapshot_read_owner = 2'b10;
            default: snapshot_read_owner = 2'b00;
        endcase
    end

    // Start with reset, then run three independent expansion scans.
    // Test 1: Turn 2, Blue speed=2 is ready; Red speed=3 is not.
    //         Blue probability=100, so eligible requests succeed.
    // Test 2: Turn 3, Red is ready; Blue is not.
    //         Red probability=100, so eligible requests succeed.
    // Test 3: Turn 2, Blue is ready, but Blue probability=0.
    //         random_next still pulses, request_valid stays low.
    initial begin
        resetn <= 1'b0;
        expansion_start <= 1'b0;
        turn_count <= 8'd2;
        blue_speed <= 8'd2;
        red_speed <= 8'd3;
        blue_probability <= 7'd100;
        red_probability <= 7'd100;

        #40 resetn <= 1'b1;
        #20 expansion_start <= 1'b1;   // 60 ns
        #20 expansion_start <= 1'b0;   // 80 ns

        #27320 turn_count <= 8'd3;      // 27400 ns
        expansion_start <= 1'b1;
        #20 expansion_start <= 1'b0;   // 27420 ns

        #27180 turn_count <= 8'd2;      // 54600 ns
        blue_probability <= 7'd0;
        expansion_start <= 1'b1;
        #20 expansion_start <= 1'b0;   // 54620 ns
    end

    // Unit under test: exact port order from expansion_engine.v.
    expansion_engine U1 (
        CLOCK_50,
        resetn,
        expansion_start,
        turn_count,
        blue_speed,
        red_speed,
        blue_probability,
        red_probability,
        snapshot_read_owner,
        random_value,
        snapshot_read_address,
        random_next,
        request_valid,
        request_target,
        request_player,
        request_target_owner,
        expansion_busy,
        expansion_done
    );

    // Real project LFSR: advances with each eligible attempt.
    lfsr U2 (
        CLOCK_50,
        resetn,
        random_next,
        random_value
    );

endmodule

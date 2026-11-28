module round_timer #(
    parameter ROUND_TICKS = 25'd25000000   // 0.5 s at 50 MHz
)(
    input CLOCK_50,
    input resetn,
    input timer_start,          // 1-clock pulse from game_fsm
    output reg timer_busy,
    output reg timer_done       // 1-clock pulse when the wait is over
);
    reg [24:0] count;           // 25 bits: up to ~33.5 million

    always @(posedge CLOCK_50 or negedge resetn) begin
        if (!resetn) begin
            count      <= 25'b0;
            timer_busy <= 0;
            timer_done <= 0;
        end
        else begin
            timer_done <= 0;                   // default: pulse only

            if (!timer_busy) begin
                if (timer_start) begin
                    count      <= 0;           // start from zero
                    timer_busy <= 1;
                end
            end
            else if (count == ROUND_TICKS - 1) begin
                timer_busy <= 0;               // finished
                timer_done <= 1;
            end
            else begin
                count <= count + 1;                    // keep counting
            end
        end
    end
endmodule
module character_selection (
    input CLOCK_50,
    input resetn,
    input selection_enable,            // 1 while game_fsm is in SELECT_BLUE/SELECT_RED
    input confirm_pulse,               // 1-clock pulse when KEY is pressed
    input [3:0] switch_character_id,   // SW[3:0]

    output reg [3:0] blue_character_id,
    output reg [3:0] red_character_id,
    output [3:0] preview_character_id, // what SW shows right now (for the UI)
    output reg picking_red,            // 0 = blue's turn, 1 = red's turn
    output reg selection_done          // 1-clock pulse after red confirms
);

    // The UI always previews whatever the switches show
    assign preview_character_id = switch_character_id;

    always @(posedge CLOCK_50 or negedge resetn) begin
        if (!resetn) begin
            blue_character_id <= 4'd0;
            red_character_id  <= 4'd0;
            picking_red       <= 0;
            selection_done    <= 0;
        end
        else begin
            selection_done <= 1'b0; 

            if (!selection_enable) begin
                picking_red <= 0; // get ready for blue
            end
            else if (confirm_pulse) begin
                if (picking_red == 1'b0) begin
                    blue_character_id <= switch_character_id;   // save blue's choice
                    picking_red <= 1;           // now red's turn
                end
                else begin
                    red_character_id <= switch_character_id;   // save red's choice
                    picking_red <= 0;           // reset for next game
                    selection_done <= 1;        // tell game_fsm
                end
            end
        end
    end
endmodule
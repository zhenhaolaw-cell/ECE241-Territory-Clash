
module player_state (
    input CLOCK_50,
    input resetn,
    input load_players,
    input [3:0] blue_character_id,
    input [3:0] red_character_id,
    input update_armour,
    input [6:0] next_blue_armour,
    input [6:0] next_red_armour,

    output reg [3:0] blue_selected_id,
    output reg [3:0] red_selected_id,
    output reg [6:0] blue_armour,
    output reg [6:0] red_armour,
    output reg [7:0] blue_speed,
    output reg [7:0] red_speed,
    output reg [6:0] blue_probability,
    output reg [6:0] red_probability
);

    wire [6:0] blue_base_armour;
    wire [6:0] red_base_armour;
    wire [7:0] blue_base_speed;
    wire [7:0] red_base_speed;
    wire [6:0] blue_base_probability;
    wire [6:0] red_base_probability;

    // Look up the attributes of the selected blue character
    character_stats blue_stats (
        .character_id(blue_character_id),
        .base_armour(blue_base_armour),
        .expansion_speed(blue_base_speed),
        .expansion_probability(blue_base_probability)
    );

    // Look up the attributes of the selected red character
    character_stats red_stats (
        .character_id(red_character_id),
        .base_armour(red_base_armour),
        .expansion_speed(red_base_speed),
        .expansion_probability(red_base_probability)
    );

    // Store player attributes and update current armour
    always @(posedge CLOCK_50 or negedge resetn) begin
        if (!resetn) begin
            blue_selected_id <= 4'd0;
            red_selected_id <= 4'd0;

            blue_armour <= 7'd0;
            red_armour <= 7'd0;

            blue_speed <= 8'd0;
            red_speed <= 8'd0;

            blue_probability <= 7'd0;
            red_probability <= 7'd0;
        end
        else if (load_players) begin
            blue_selected_id <= blue_character_id;
            red_selected_id <= red_character_id;

            blue_armour <= blue_base_armour;
            red_armour <= red_base_armour;

            blue_speed <= blue_base_speed;
            red_speed <= red_base_speed;

            blue_probability <= blue_base_probability;
            red_probability <= red_base_probability;
        end
        else if (update_armour) begin
            blue_armour <= next_blue_armour;
            red_armour <= next_red_armour;
        end
    end

endmodule

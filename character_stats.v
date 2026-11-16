
module character_stats (
    input [3:0] character_id,

    output reg [6:0] base_armour,
    output reg [7:0] expansion_speed,
    output reg [6:0] expansion_probability
);

    // Character attributes are determined by character_id.
    // Lower expansion_speed means faster expansion.
    // expansion_probability is represented as 0 to 100.

    always @(*) begin

        case (character_id)

            // Character 0: Spark
            // Very fast, high probability, low armour
            4'd0: begin
                base_armour = 7'd45;
                expansion_speed = 8'd2;
                expansion_probability = 7'd65;
            end

            // Character 1: Swift
            // Fast expansion with moderate probability
            4'd1: begin
                base_armour = 7'd55;
                expansion_speed = 8'd2;
                expansion_probability = 7'd55;
            end

            // Character 2: Dash
            // Fast expansion with better defence
            4'd2: begin
                base_armour = 7'd65;
                expansion_speed = 8'd2;
                expansion_probability = 7'd45;
            end

            // Character 3: Scout
            // Fast but less reliable expansion
            4'd3: begin
                base_armour = 7'd80;
                expansion_speed = 8'd2;
                expansion_probability = 7'd35;
            end

            // Character 4: Flare
            // High probability with moderate speed
            4'd4: begin
                base_armour = 7'd55;
                expansion_speed = 8'd3;
                expansion_probability = 7'd80;
            end

            // Character 5: Viper
            // Aggressive and moderately fast
            4'd5: begin
                base_armour = 7'd65;
                expansion_speed = 8'd3;
                expansion_probability = 7'd70;
            end

            // Character 6: Ranger
            // Balanced attributes
            4'd6: begin
                base_armour = 7'd75;
                expansion_speed = 8'd3;
                expansion_probability = 7'd60;
            end

            // Character 7: Wolf
            // Balanced with additional defence
            4'd7: begin
                base_armour = 7'd85;
                expansion_speed = 8'd3;
                expansion_probability = 7'd50;
            end

            // Character 8: Guard
            // Strong defence, lower probability
            4'd8: begin
                base_armour = 7'd100;
                expansion_speed = 8'd3;
                expansion_probability = 7'd40;
            end

            // Character 9: Storm
            // Very high probability, slower expansion
            4'd9: begin
                base_armour = 7'd70;
                expansion_speed = 8'd4;
                expansion_probability = 7'd90;
            end

            // Character 10: Falcon
            // Reliable expansion and moderate defence
            4'd10: begin
                base_armour = 7'd80;
                expansion_speed = 8'd4;
                expansion_probability = 7'd80;
            end

            // Character 11: Knight
            // Reliable expansion with strong defence
            4'd11: begin
                base_armour = 7'd90;
                expansion_speed = 8'd4;
                expansion_probability = 7'd70;
            end

            // Character 12: Titan
            // High armour with slower expansion
            4'd12: begin
                base_armour = 7'd100;
                expansion_speed = 8'd4;
                expansion_probability = 7'd60;
            end

            // Character 13: Boulder
            // Very high probability but slow
            4'd13: begin
                base_armour = 7'd85;
                expansion_speed = 8'd5;
                expansion_probability = 7'd95;
            end

            // Character 14: Fortress
            // Strong defence and reliable expansion
            4'd14: begin
                base_armour = 7'd100;
                expansion_speed = 8'd5;
                expansion_probability = 7'd85;
            end

            // Character 15: Turtle
            // Highest armour, slow expansion
            4'd15: begin
                base_armour = 7'd115;
                expansion_speed = 8'd5;
                expansion_probability = 7'd75;
            end

            default: begin
                base_armour = 7'd75;
                expansion_speed = 8'd3;
                expansion_probability = 7'd60;
            end

        endcase
    end

endmodule

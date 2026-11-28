localparam EMPTY = 2'b00;
localparam BLUE  = 2'b01;
localparam RED   = 2'b10;

localparam INIT        = 4'd0;
localparam SELECT_BLUE = 4'd1;
localparam SELECT_RED  = 4'd2;
localparam PLACE_BLUE  = 4'd3;
localparam PLACE_RED   = 4'd4;
localparam BATTLE      = 4'd5;
localparam GAME_OVER   = 4'd6;

localparam WIN_NONE = 2'b00;
localparam WIN_BLUE = 2'b01;
localparam WIN_RED  = 2'b10;
localparam WIN_DRAW = 2'b11;

localparam INITIAL_CELLS = 3'd5;
localparam MAX_TURNS = 8'd200;

localparam COLOR_EMPTY  = 9'b000_000_000;
localparam COLOR_BLUE   = 9'b000_000_111;
localparam COLOR_RED    = 9'b111_000_000;
localparam COLOR_WHITE  = 9'b111_111_111;
localparam COLOR_YELLOW = 9'b111_111_000;

module wack_a_mole(
    input wire clk,               // 50 MHz clock
    input wire start_btn,         // Start button (debounced)
    input wire reset_btn,
    input wire [6:0] switches,    // Mole switches
    output reg [6:0] leds,        // Mole LEDs
    output reg [7:0] seg,         // 7-segment segments
    output reg [3:0] en,          // Digit enables
    output wire game_over_led     // Lights up when game ends
);

    // Game state
    reg game_started = 0;
    reg game_over = 0;
    reg start_btn_prev;
    reg reset_btn_prev;
    reg reset_signal;

    // Debounce logic for start button
    // Button debouncing and edge detection
    always @(posedge clk) begin
        start_btn_prev <= start_btn;
        reset_btn_prev <= reset_btn;
       
        // Generate reset signal on rising edge of reset button
        if (reset_btn && !reset_btn_prev)
            reset_signal <= 1;
        else
            reset_signal <= 0;
    end

    // --------------------------------------
    // Game start logic
    // --------------------------------------
    always @(posedge clk or posedge reset_signal) begin
        if (reset_signal) begin
            game_started <= 0;
        end else if (start_btn && !start_btn_prev) begin
            game_started <= 1;
        end else if (game_over) begin
            game_started <= 0;
        end
    end
    assign game_over_led = game_over;

    // Timer and logic
    reg [25:0] counter;
    reg one_sec_pulse;
    reg [4:0] time_counter = 0;

    always @(posedge clk) begin
        if (!game_started || game_over) begin
            counter <= 0;
            one_sec_pulse <= 0;
        end else if (counter >= 50_000_000 - 1) begin
            counter <= 0;
            one_sec_pulse <= 1;
        end else begin
            counter <= counter + 1;
            one_sec_pulse <= 0;
        end
    end

    always @(posedge clk or posedge reset_signal) begin
        if (reset_signal)
            time_counter <= 0;
        else if (game_started && !game_over) begin
            if (one_sec_pulse && time_counter < 30)
                time_counter <= time_counter + 1;
        end
    end
       
    always @(posedge clk or posedge reset_signal) begin
        if (reset_signal)
            game_over <= 0;
        else if (time_counter >= 30)
            game_over <= 1;
    end

    // Score tracking
    reg [6:0] score = 0;

    // LFSR for pseudo-random mole selection
    reg [3:0] lfsr = 4'b1010;
    wire feedback = lfsr[3] ^ lfsr[2];

    always @(posedge clk or posedge reset_signal) begin
        if (reset_signal)
            lfsr <= 4'b1010;
        else if (one_sec_pulse && game_started && !game_over)
            lfsr <= {lfsr[2:0], feedback};
    end

    reg [2:0] mole_pos;
    always @(*) begin
        mole_pos = lfsr % 7;
    end

    // Mole LED control
    reg mole_active;
    reg whack_detected;
    reg [6:0] prev_switches;

    always @(posedge clk or posedge reset_signal) begin
        if (reset_signal) begin
            leds <= 7'b0;
            mole_active <= 0;
        end else if (game_started && !game_over) begin
            if (one_sec_pulse)
                mole_active <= 1;

            if (mole_active) begin
                leds <= 7'b0;
                leds[mole_pos] <= 1;
                if (whack_detected) begin
                    leds[mole_pos] <= 0;
                    mole_active <= 0;
                end
            end else begin
                leds <= 7'b0;
            end
        end else begin
            leds <= 7'b0;
        end
    end

    // Switch whack detection
    always @(posedge clk or posedge reset_signal) begin
        if (reset_signal) begin
            prev_switches <= 7'b0;
        end else begin      
            prev_switches <= switches;
        end
    end
         
    always @(posedge clk or posedge reset_signal) begin
        if (reset_signal) begin
            whack_detected <= 0;
        end else if (game_started && !game_over && mole_active &&
            (switches[mole_pos] != prev_switches[mole_pos])) begin
            whack_detected <= 1;
        end else
            whack_detected <= 0;
    end

    always @(posedge clk or posedge reset_signal) begin
        if (reset_signal)
            score <= 0;
        else if (game_started && !game_over && whack_detected && score < 99)
            score <= score + 1;
    end
     
    // Display BCD values
    reg [3:0] time_ones;
    reg [3:0] time_tens;
    wire [3:0] score_ones = score % 10;
    wire [3:0] score_tens = score / 10;

    always @(*) begin
        time_tens = (30 - time_counter) / 10;
        time_ones = (30 - time_counter) % 10;
    end

    // Display refresh logic
    reg [15:0] mux_counter;
    reg mux_clk;
    reg [1:0] digit_sel;

    always @(posedge clk or posedge reset_signal) begin
        if (reset_signal) begin
            mux_counter <= 0;
            mux_clk <= 0;
        end else if (mux_counter >= 25_000 - 1) begin
            mux_counter <= 0;
            mux_clk <= ~mux_clk;
        end else begin
            mux_counter <= mux_counter + 1;
        end
    end

    always @(posedge mux_clk or posedge reset_signal) begin
        if (reset_signal) begin
            digit_sel <= 0;
            en <= 4'b0000;
            seg <= 8'b11111111;
        end else begin
            case (digit_sel)
                2'd0: begin
                    en <= 4'b0001;
                    case (score_ones)
                        0: seg <= 8'b00000001;
                        1: seg <= 8'b01001111;
                        2: seg <= 8'b00010010;
                        3: seg <= 8'b00000110;
                        4: seg <= 8'b01001100;
                        5: seg <= 8'b00100100;
                        6: seg <= 8'b00100000;
                        7: seg <= 8'b00001110;
                        8: seg <= 8'b00000000;
                        9: seg <= 8'b00000100;
                        default: seg <= 8'b11111111;
                    endcase
                end
                2'd1: begin
                    en <= 4'b0010;
                    case (score_tens)
                        0: seg <= 8'b00000001;
                        1: seg <= 8'b01001111;
                        2: seg <= 8'b00010010;
                        3: seg <= 8'b00000110;
                        4: seg <= 8'b01001100;
                        5: seg <= 8'b00100100;
                        6: seg <= 8'b00100000;
                        7: seg <= 8'b00001110;
                        8: seg <= 8'b00000000;
                        9: seg <= 8'b00000100;
                        default: seg <= 8'b11111111;
                    endcase
                end
                2'd2: begin
                    en <= 4'b0100;
                    case (time_ones)
                        0: seg <= 8'b00000001;
                        1: seg <= 8'b01001111;
                        2: seg <= 8'b00010010;
                        3: seg <= 8'b00000110;
                        4: seg <= 8'b01001100;
                        5: seg <= 8'b00100100;
                        6: seg <= 8'b00100000;
                        7: seg <= 8'b00001110;
                        8: seg <= 8'b00000000;
                        9: seg <= 8'b00000100;
                        default: seg <= 8'b11111111;
                    endcase
                end
                2'd3: begin
                    en <= 4'b1000;
                    case (time_tens)
                        0: seg <= 8'b00000001;
                        1: seg <= 8'b01001111;
                        2: seg <= 8'b00010010;
                        3: seg <= 8'b00000110;
                        default: seg <= 8'b11111111;
                    endcase
                end
            endcase
            digit_sel <= digit_sel + 1;
        end
    end
endmodule
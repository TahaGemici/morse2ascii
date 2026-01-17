module morse_rx (
    input clk,
    input arst_n,

    input morse_in,

    input read_en,
    output[7:0] ascii_out
);
    wire morse;
    cdc_sync #(1) cdc_sync_inst (.clk_out(clk), .arst_n(arst_n), .d(morse_in), .q(morse));
    
    reg[1:0] state, state_nxt;
    reg[31:0] counter, counter_nxt;
    always @(posedge clk or negedge arst_n) begin
        if(~arst_n) begin
            state <= 0;
            counter <= 0;
        end else begin
            state <= state_nxt;
            counter <= counter_nxt;
        end
    end

    reg data_valid;
    wire[31:0] mean;
    mean #( .WIDTH(32), .DEPTH(3) ) mean_inst (
        .clk(clk),
        .arst_n(arst_n),
        .data_valid(data_valid),
        .data_in(counter),
        .mean_out(mean)
    );

    localparam STATE_IDLE = 2'b00,
               STATE_CDR  = 2'b01,
               STATE_WAIT = 2'b10;
    
    always @* begin
        state_nxt = state;
        counter_nxt = counter;
        data_valid = 0;
        
        case(state)
            STATE_IDLE: begin
                if(morse) begin
                    counter_nxt = counter + 1;
                end
                else if(counter != 0) begin
                    counter_nxt = 0;
                    data_valid = 1;
                    state_nxt = STATE_CDR;
                end
            end
            STATE_CDR: begin
                if(morse) begin
                    counter_nxt = counter + 1;
                end
                else if(counter != 0) begin
                    counter_nxt = 0;
                    state_nxt = STATE_IDLE;
                end
            end
            STATE_WAIT: begin
                if(~morse) begin
                    state_nxt = STATE_IDLE;
                    counter_nxt = 0;
                end
            end
        endcase
    end
    


endmodule
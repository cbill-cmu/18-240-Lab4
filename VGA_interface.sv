`default_nettype none // Required in every sv file 
`include "library.sv"

module vga
    ( input logic clock_40MHz , reset ,
      output logic HS , VS , blank ,
      output logic [9:0] row , col );
      
    logic HS_count_en, VS_count_en, col_count_en, row_count_en;
    logic HS_count_clear, VS_count_clear, col_count_clear, row_count_clear;
    logic row_count_en_temp; 
    logic [10:0] HS_count;
    logic [9:0] VS_count;
    logic HS_Tpw, VS_Tpw;
    logic HS_Done, VS_Done;
    
    //FSM Control initialzation
    fsm control (.*);
    
    //Counter initialzations
    Counter #(11) HS_Counter (HS_count_en, HS_count_clear,
                    1'b0, 1'b1, clock_40MHz, 11'd0, HS_count);

    Counter #(10) VS_Counter (VS_count_en, VS_count_clear,
                    1'b0, 1'b1, clock_40MHz, 10'd0, VS_count);

    Counter #(10) Col_Counter (.en(col_count_en), .clear(col_count_clear), 
                    .load(1'b0), .up(1'b1), .clock(clock_40MHz), 
                    .D(10'd0), .Q(col));
                    
    Counter #(10) Row_Counter (row_count_en, row_count_clear,
                    1'b0, 1'b1, clock_40MHz, 10'd0, row);
    
    //Logic for HS_Counter Counting up in cols
    RangeCheck #(11) HS_Tpw_check (11'd127, 11'd0, HS_count, HS_Tpw);
    RangeCheck #(11) HS_Tdisp (11'd1016, 11'd217, HS_count, col_count_en);
    Comparator #(11) HS_Complete (11'd1055, HS_count, HS_Done);
    
    //Logic for VS_Counter counting up in rows
    RangeCheck #(10) VS_Tpw_check (10'd3, 10'd0, VS_count, VS_Tpw);
    RangeCheck #(10) VS_Tdisp (10'd603, 10'd4, VS_count, row_count_en_temp);
    Comparator #(10) VS_Complete (10'd627, VS_count, VS_Done);

    assign blank = (HS_Tpw | VS_Tpw);
    assign row_count_en = row_count_en_temp & HS_Done; 
    assign HS = ~(HS_Tpw);
    assign VS = ~(VS_Tpw);

endmodule: vga

module fsm 
    (input logic HS_Done, VS_Done, clock_40MHz, reset,
     output logic HS_count_clear, VS_count_clear,
     output logic col_count_clear, row_count_clear,
     output logic HS_count_en, VS_count_en);

    enum logic {start = 1'b0, loop = 1'b1} currState, nextState;

    always_comb begin
        case (currState)
            start: begin
                HS_count_clear = 1'b1;
                col_count_clear = 1'b1;
                VS_count_clear = 1'b1;
                row_count_clear = 1'b1; 

                VS_count_en = 1'b0;
                HS_count_en = 1'b0;

                nextState = loop;
            end 
            loop: begin
                //Take priority over HS_Done & ~HS_Done
                if (VS_Done) begin
                    HS_count_clear = 1'b1;
                    col_count_clear = 1'b1;
                    VS_count_clear = 1'b1;
                    row_count_clear = 1'b1; 

                    HS_count_en = 1'b0;
                    VS_count_en = 1'b0;

                    nextState = start;
                end
                else begin 
                    //For HS_Done and ~HS_Done State
                    HS_count_clear = (HS_Done) ? 1'b1 : 1'b0;
                    VS_count_clear = 1'b0 ;
                    col_count_clear = (HS_Done) ? 1'b1 : 1'b0; 
                    row_count_clear = 1'b0; 

                    HS_count_en = (HS_Done) ? 1'b0 : 1'b1;
                    VS_count_en = (HS_Done) ? 1'b1 : 1'b0;
                    nextState = loop;
                end 
            end
        endcase
    end

    always_ff @(posedge clock_40MHz) begin
        if (reset) begin
            currState <= start;
        end
        else begin
            currState <= nextState;
        end
    end
endmodule: fsm

module VGA_test();
    logic clock_40MHz , reset;
    logic HS , VS , blank;
    logic [9:0] row , col;

    vga DUT (.*); 

    initial begin
        clock_40MHz = 0;
        forever #5 clock_40MHz = ~ clock_40MHz ;
    end

    initial begin
        reset <= 1'b1;
        @(posedge clock_40MHz);
        reset <= 1'b0;
        @(posedge clock_40MHz);

        #40000000 $finish; 
    end

endmodule : VGA_test

    

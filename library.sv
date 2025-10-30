`default_nettype none // Required in every sv file 

module Comparator
    #(parameter WIDTH = 8)
    ( input logic [WIDTH-1:0] A, B,
      output logic AeqB);

    assign AeqB = (A == B);

endmodule : Comparator

module MagComp
    #(parameter WIDTH = 8)
    ( input logic [WIDTH-1:0] A, B,
      output logic AltB, AeqB, AgtB);

    assign AltB = (A < B);
    assign AeqB = (A == B);
    assign AgtB = (A > B);

endmodule : MagComp

module Adder
    #(parameter WIDTH = 8)
    ( input logic [WIDTH-1:0] A, B,
      input logic cin, 
      output logic [WIDTH-1:0] sum,
      output logic cout);

    logic [WIDTH:0] overflow;

    assign overflow = A + B + cin;
    assign sum = overflow[WIDTH-1:0];
    assign cout = overflow[WIDTH];
    
endmodule: Adder

//bin: if we need to take away becuase previous bit
//was too small (for A-B, A < B)
//bout: requires a more significant bit to subtract 
//(for A-B, B > A)
module Subtracter
    #(parameter WIDTH = 8)
    ( input logic [WIDTH-1:0] A, B,
      input logic bin,
      output logic [WIDTH-1:0] diff,
      output logic bout);

    logic [WIDTH:0] underflow;
    assign underflow = A - B - bin;
    assign diff = underflow[WIDTH-1:0];
    assign bout = ((A - bin) < B);
    
endmodule: Subtracter

module Multiplexer
    #(parameter WIDTH = 8)
    ( input logic [WIDTH-1:0] I,
      input logic [$clog2(WIDTH)-1:0] S,
      output logic Y);

    assign Y = I[S];

endmodule : Multiplexer

module Mux2to1
    #(parameter WIDTH = 8)
    ( input logic [WIDTH-1:0] I1, I0,
      input logic S,
      output logic [WIDTH-1:0] Y);

    assign Y = (S) ? I1 : I0;

endmodule : Mux2to1

module Decoder
    #(parameter WIDTH = 8)
    ( input logic [$clog2(WIDTH-1)-1:0] I, 
      input logic en,
      output logic [WIDTH-1:0] D);

    always_comb begin
        D = '0; 
        if (en) D[I] = 1'b1;    
    end

endmodule: Decoder

module DFlipFlop
    ( input logic D, clock,
      input logic preset_L, reset_L,
      output logic Q);

    always_ff @ ( posedge clock, negedge reset_L, negedge preset_L) begin
        if (~preset_L) Q = 1'b1;
        else if (~reset_L) Q = 1'b0;
        else Q <= D;
    end

endmodule: DFlipFlop

module Register
    #(parameter WIDTH = 8)
    ( input logic en, clear, 
      input logic clock,
      input logic [WIDTH-1:0] D,
      output logic [WIDTH-1:0] Q);

    always_ff @(posedge clock) begin
        if (en) Q <= D;
        else if (clear) Q <= '0;
        else Q <= D;
    end

endmodule: Register

module Counter
    #(parameter WIDTH = 8)
    ( input logic en, clear, load, up,
      input logic clock,
      input logic [WIDTH-1:0] D,
      output logic [WIDTH-1:0] Q);
    
    always_ff @(posedge clock) begin
        if (clear) Q = '0;
        else if (load) Q <= D;
        else if (en) begin
            Q <= Q - 1'b1;
            if (up) Q <= Q + 1'b1;
        end
    end

endmodule: Counter

module ShiftRegisterSIPO
    #(parameter WIDTH = 8)
    ( input logic en, left, serial, 
      input logic clock,
      output logic [WIDTH-1:0] Q);
    
    always_ff @(posedge clock) begin
        if (en) begin
            Q <= {serial, Q[WIDTH-1:1]}; 
            if (left) Q <= {Q[WIDTH-2:0], serial};
        end
    end

endmodule: ShiftRegisterSIPO

module ShiftRegisterPIPO
    #(parameter WIDTH = 8)
    ( input logic en, left, load, 
      input logic clock,
      input logic [WIDTH-1:0] D,
      output logic [WIDTH-1:0] Q);
    
    always_ff @(posedge clock) begin
        if (load) Q <= D; 
        else if (en) begin
            Q <= {1'b0, Q[WIDTH-1:1]};
            if (left) Q <= {Q[WIDTH-2:0], 1'b0};
        end
    end

endmodule: ShiftRegisterPIPO

module BarrelShiftRegister
    #(parameter WIDTH = 8)
    ( input logic en, load,
      input logic clock,
      input logic [1:0] by, 
      input logic [WIDTH-1:0] D,
      output logic [WIDTH-1:0] Q);

    always_ff @(posedge clock) begin
        if (load) Q <= D; 
        else if (en) Q <= (Q << by); 
    end

endmodule: BarrelShiftRegister

module Synchronizer
    ( input logic async,
      input logic clock,
      output logic sync);

    logic async_temp;

    always_ff @(posedge clock) begin
        async_temp <= async;
        sync <= async_temp;
    end

endmodule: Synchronizer

module BusDriver
    #(parameter WIDTH = 8)
    ( input logic en,
      input logic [WIDTH-1:0] data,
      inout tri [WIDTH-1:0] bus, 
      output logic [WIDTH-1:0] buff);

    assign bus = (en) ? data : 'z;
    assign buff = (~en) ? bus : 'z; 

endmodule: BusDriver

module Memory
    #(parameter DW = 16,
                W = 256,
                AW = $clog2(W))
    ( input logic re, we,
      input logic clock, 
      input logic [AW-1:0] addr, 
      output logic [DW-1:0] data);
    
    logic [DW-1:0] M[W];
    logic [DW-1:0] rData;

    assign data = (re) ? rData : 'z;

    always_ff @(posedge clock) begin
        if (we) M[addr] <= data;
    end

    always_comb begin
        rData = M[addr];
    end

endmodule: Memory

module RangeCheck
    #(parameter WIDTH = 8)
    (input logic [WIDTH-1:0] high, low, val,
     output logic is_between);
     

    always_comb begin
        is_between = 0;
        if ((val <= high) && (val >= low)) begin
            is_between = 1;
        end
    end
endmodule: RangeCheck

module OffsetCheck
    #(parameter WIDTH = 8)
    (input logic [WIDTH-1:0] val, delta, low,
     output logic is_between);
    
    logic Cin, Cout;
    logic [WIDTH-1:0] sum;
    assign Cin = 0;
    Adder #(WIDTH) add (.A(low), .B(delta), .cin(Cin), .cout(Cout), .sum(sum));

    always_comb begin
        is_between = 0;
        if ((val <= sum) && (val >= low)) begin
            is_between = 1;
        end
    end
endmodule: OffsetCheck

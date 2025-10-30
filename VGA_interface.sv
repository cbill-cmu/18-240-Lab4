`default_nettype none // Required in every sv file 
`include "library.sv"

module vga
    ( input logic clock_40MHz , reset ,
      output logic HS , VS , blank ,
      output logic [9:0] row , col );

endmodule: vga

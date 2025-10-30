module ChipInterface
    ( input logic CLOCK_100 ,
      input logic [ 3:0] BTN ,
      input logic [15:0] SW ,
      output logic [ 3:0] D2_AN , D1_AN ,
      output logic [ 7:0] D2_SEG , D1_SEG ,
      output logic hdmi_clk_n , hdmi_clk_p ,
      output logic [ 2:0] hdmi_tx_p , hdmi_tx_n );

endmodule: ChipInterface
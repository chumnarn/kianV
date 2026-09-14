`timescale 1ns/1ps
module tb_sram;
  reg clk=0, we=0; reg [8:0] addr=0; reg [55:0] din=0; wire [55:0] dout;
  always #5 clk = ~clk;
  sram_sp_ihp_512x56 dut(.clk(clk),.we(we),.addr(addr),.din(din),.dout(dout));
  initial begin
    repeat (2) @(posedge clk); addr<=9'd7; din<=56'h123456789abcde; we<=1;
    @(posedge clk); we<=0; addr<=9'd7;
    @(posedge clk); #1;
    if (dout !== 56'h123456789abcde) $fatal(1,"SRAM mismatch: %h",dout);
    $display("PASS: IHP 512x56 wrapper behavioral contract"); $finish;
  end
endmodule


// SPDX-License-Identifier: Apache-2.0
`default_nettype none
module sram_sp_ihp_512x56 (
    input wire clk, we,
`ifdef USE_POWER_PINS
    inout wire VDD, VSS,
`endif
    input wire [8:0] addr, input wire [55:0] din, output wire [55:0] dout
);
`ifdef FUNCTIONAL
  reg [55:0] mem [0:511]; reg [55:0] q;
  always @(posedge clk) begin if (we) mem[addr] <= din; q <= we ? din : mem[addr]; end
  assign dout = q;
`else
  wire [31:0] q_lo, q_hi;
  (* keep *) RM_IHPSG13_1P_1024x32_c2_bm_bist sram_lo (
      .A_CLK(clk), .A_MEN(1'b1), .A_WEN(we), .A_REN(~we),
      .A_ADDR({1'b0,addr}), .A_DIN(din[31:0]), .A_DLY(1'b1), .A_DOUT(q_lo), .A_BM(32'b0),
      .A_BIST_CLK(1'b0), .A_BIST_EN(1'b0), .A_BIST_MEN(1'b0), .A_BIST_WEN(1'b0),
      .A_BIST_REN(1'b0), .A_BIST_ADDR(10'b0), .A_BIST_DIN(32'b0), .A_BIST_BM(32'b0)
  );
  (* keep *) RM_IHPSG13_1P_1024x32_c2_bm_bist sram_hi (
      .A_CLK(clk), .A_MEN(1'b1), .A_WEN(we), .A_REN(~we),
      .A_ADDR({1'b0,addr}), .A_DIN({8'b0,din[55:32]}), .A_DLY(1'b1), .A_DOUT(q_hi), .A_BM(32'b0),
      .A_BIST_CLK(1'b0), .A_BIST_EN(1'b0), .A_BIST_MEN(1'b0), .A_BIST_WEN(1'b0),
      .A_BIST_REN(1'b0), .A_BIST_ADDR(10'b0), .A_BIST_DIN(32'b0), .A_BIST_BM(32'b0)
  );
  assign dout = {q_hi[23:0],q_lo};
`endif
endmodule
`default_nettype wire


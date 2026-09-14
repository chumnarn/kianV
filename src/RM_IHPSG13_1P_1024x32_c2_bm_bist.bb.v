// SPDX-License-Identifier: Apache-2.0
(* blackbox *)
module RM_IHPSG13_1P_1024x32_c2_bm_bist (
    input wire A_CLK, A_MEN, A_WEN, A_REN,
    input wire [9:0] A_ADDR,
    input wire [31:0] A_DIN,
    input wire A_DLY,
    output wire [31:0] A_DOUT,
    input wire [31:0] A_BM,
    input wire A_BIST_CLK, A_BIST_EN, A_BIST_MEN,
    input wire A_BIST_WEN, A_BIST_REN,
    input wire [9:0] A_BIST_ADDR,
    input wire [31:0] A_BIST_DIN,
    input wire [31:0] A_BIST_BM
);
endmodule

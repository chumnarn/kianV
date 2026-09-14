// SPDX-License-Identifier: Apache-2.0
`default_nettype none
module chip_top #(parameter integer NUM_BIDIR_PADS = 54) (
`ifdef USE_POWER_PINS
    inout wire IOVDD, IOVSS, VDD, VSS,
`endif
    inout wire clk_PAD, rst_n_PAD,
    inout wire [NUM_BIDIR_PADS-1:0] bidir_PAD
);
  wire clk_core, rst_n_async, rst_n_core;
  wire [NUM_BIDIR_PADS-1:0] pad_in, pad_out, pad_oe_raw;
  wire [NUM_BIDIR_PADS-1:0] pad_oe = pad_oe_raw & {NUM_BIDIR_PADS{rst_n_core}};

  (* keep *) sg13g2_IOPadIOVdd iovdd_pad (
`ifdef USE_POWER_PINS
      .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS)
`endif
  );
  (* keep *) sg13g2_IOPadIOVss iovss_pad (
`ifdef USE_POWER_PINS
      .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS)
`endif
  );
  (* keep *) sg13g2_IOPadVdd vdd_pad (
`ifdef USE_POWER_PINS
      .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS)
`endif
  );
  (* keep *) sg13g2_IOPadVss vss_pad (
`ifdef USE_POWER_PINS
      .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS)
`endif
  );
  sg13g2_IOPadIn clk_pad (
`ifdef USE_POWER_PINS
      .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS),
`endif
      .p2c(clk_core), .pad(clk_PAD)
  );
  sg13g2_IOPadIn rst_n_pad (
`ifdef USE_POWER_PINS
      .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS),
`endif
      .p2c(rst_n_async), .pad(rst_n_PAD)
  );
  async_reset_sync u_pad_reset_sync (
      .clk(clk_core), .rst_n_async(rst_n_async), .rst_n_sync(rst_n_core)
  );
  generate
    for (genvar i = 0; i < NUM_BIDIR_PADS; i++) begin : bidirs
      sg13g2_IOPadInOut30mA bidir_pad (
`ifdef USE_POWER_PINS
          .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS),
`endif
          .c2p(pad_out[i]), .c2p_en(pad_oe[i]),
          .p2c(pad_in[i]), .pad(bidir_PAD[i])
      );
    end
  endgenerate
  (* keep *) chip_core #(.NUM_BIDIR_PADS(NUM_BIDIR_PADS)) i_chip_core (
      .clk(clk_core), .rst_n(rst_n_core),
`ifdef USE_POWER_PINS
      .VDD(VDD), .VSS(VSS),
`endif
      .bidir_in(pad_in), .bidir_out(pad_out), .bidir_oe(pad_oe_raw),
      .bidir_cs(), .bidir_sl(), .bidir_ie(), .bidir_pu(), .bidir_pd()
  );
endmodule
`default_nettype wire


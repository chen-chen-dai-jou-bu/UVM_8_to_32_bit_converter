//-----------------------------------------------------------------------------
// File Name : testbench/tb_env/uvmtb_rx.sv
// Function  : Top-level UVM testbench for RX Engine
// Steps     :
//   1) Generate clk / rst_n
//   2) Instantiate rx_intf rx_if(clk, rst_n)
//   3) Instantiate DUT and connect to rx_if (including last port)
//   4) Register interface into uvm_config_db with key "rx_vif"
//   5) run_test()
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

module uvmtb_rx;

  // Clock / Reset
  logic clk;
  logic rst_n;

  // Drive clock: 50 MHz (period = 20ns, half-period = 10ns)
  initial begin
    clk = 1'b0;
    forever #10 clk = ~clk;
  end

  // Drive reset: assert low for two 50 MHz clock cycles (40 ns)
  initial begin
    rst_n = 1'b0;
    #40 rst_n = 1'b1;
  end

  // --------------------------------------------------------------------------
  // Instantiate RX interface
  // --------------------------------------------------------------------------
  rx_intf rx_if(.clk(clk), .rst_n(rst_n));

  // --------------------------------------------------------------------------
  // Instantiate DUT
  // NOTE:
  // - If your DUT module name is not rx_eng, replace "rx_eng" below.
  // - Key update: connect DUT's last port to rx_if.last
  // --------------------------------------------------------------------------
  rx_eng dut (
    .clk       (clk),
    .rst_n     (rst_n),

    // Inputs (from driver)
    .conv_en   (rx_if.conv_en),
    .rxdv      (rx_if.rxdv),
    .rxd       (rx_if.rxd),

    // Outputs (to monitors)
    .valid_out (rx_if.valid_out),
    .data_out  (rx_if.data_out),
    .byte_cnt  (rx_if.byte_cnt),

    // Key update for top-level: last port connection
    .last      (rx_if.last)
  );

  // --------------------------------------------------------------------------
  // Register virtual interface into UVM config DB, then run test
  // --------------------------------------------------------------------------
  initial begin
    uvm_config_db#(virtual rx_intf)::set(null, "*", "rx_vif", rx_if);
    run_test();
  end

endmodule
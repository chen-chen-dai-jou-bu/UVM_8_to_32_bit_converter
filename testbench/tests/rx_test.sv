//-----------------------------------------------------------------------------
// File Name : testbench/tests/rx_test.sv
// Function  : UVM test for RX Engine (HW1)
// NOTE      : test class is NOT included in rx_vip_pkg, so we must
//             include/import here.
//-----------------------------------------------------------------------------

`include "uvm_macros.svh"
import uvm_pkg::*;
import rxeng_vip_pkg::*;

class rx_test extends uvm_test;
  `uvm_component_utils(rx_test)

  // Environment handle (follow naming convention)
  rx_env_c m_rx_env;

  // Coverage numbers
  int  covered_bins, total_bins;
  real coverage_percent = 0.00;

  function new(string name = "", uvm_component parent);
    super.new(name, parent);
  endfunction

  // ------------------------------------------------------------
  // build_phase:
  // - Create env only
  // - DO NOT create sequence here (per spec)
  // ------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_rx_env = rx_env_c::type_id::create("m_rx_env", this);
  endfunction

  // ------------------------------------------------------------
  // end_of_elaboration_phase:
  // - Print topology for homework submit purpose
  // - Limit report hierarchy depth to 3 layers
  // ------------------------------------------------------------
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_default_printer.knobs.depth = 3;
    uvm_top.print_topology();
  endfunction

  // ------------------------------------------------------------
  // main_phase:
  // - Replace while loop with for loop (50 independent sequences)
  // - Create a new sequence every iteration (create new handle policy)
  // ------------------------------------------------------------
  virtual task main_phase(uvm_phase phase);
    rx_sequence_c m_rx_seq;

    phase.raise_objection(this);

    for (int i = 0; i < 50; i++) begin
      `uvm_info("MAIN",
                $sformatf("Start RX sequence #%0d", i),
                UVM_NONE)

      // Create a NEW sequence for every loop
      m_rx_seq = rx_sequence_c::type_id::create($sformatf("m_rx_seq_%0d", i));

      // Start sequence on RX agent sequencer
      m_rx_seq.start(m_rx_env.m_rx_agt.m_sqr);

      // small gap (optional, keep similar style as EX1)
      #10;
    end

    phase.drop_objection(this);
  endtask

  // ------------------------------------------------------------
  // shutdown_phase:
  // - Report coverage with required naming convention
  //   "INST Coverage", "LEN_CP Coverage", "VLD_CP Coverage", "LENXVLD Coverage"
  // ------------------------------------------------------------
  virtual task shutdown_phase(uvm_phase phase);

    // Overall instance coverage
    coverage_percent =
      m_rx_env.m_rx_cov.covgrp.get_inst_coverage(covered_bins, total_bins);

    `uvm_info("TEST",
              $sformatf("INST Coverage = %0.2f %% --> Covered = %0d, Total = %0d",
                        coverage_percent, covered_bins, total_bins),
              UVM_NONE)

    // Coverpoint coverage (names should match rx_coverage.sv)
    `uvm_info("TEST",
              $sformatf("LEN_CP Coverage = %0.2f %%",
                        m_rx_env.m_rx_cov.covgrp.len_cp.get_coverage()),
              UVM_NONE)

    `uvm_info("TEST",
              $sformatf("VLD_CP Coverage = %0.2f %%",
                        m_rx_env.m_rx_cov.covgrp.vld_cp.get_coverage()),
              UVM_NONE)

    `uvm_info("TEST",
              $sformatf("LENXVLD Coverage = %0.2f %%",
                        m_rx_env.m_rx_cov.covgrp.lenXvld.get_coverage()),
              UVM_NONE)

  endtask

  // ------------------------------------------------------------
  // report_phase:
  // - Keep report_phase from EX1 (print scoreboard convert2string)
  // ------------------------------------------------------------
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("TEST", m_rx_env.m_rx_sb.convert2string(), UVM_NONE)
  endfunction

endclass


XXXXXXXXXXXXXXXXXXXXXX
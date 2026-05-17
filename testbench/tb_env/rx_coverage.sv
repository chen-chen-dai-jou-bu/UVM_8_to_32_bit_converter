/*************************************************************************** 
  * Design Name     : CoverGroup for RX Engine
  * Function        : Define the cover groups for RX Interface
  * File Name       : testbench/tb_env/rx_coverage.sv
  * Author          : Michael Su
  * Version         : 1.00
  * Date            : 2025-10-11
  ***************************************************************************/

class rx_coverage_c extends uvm_subscriber #(rx_req_trans_c);
  `uvm_component_utils(rx_coverage_c)

  rx_req_trans_c m_req;
  integer trans_cnt = 0;
  integer remainder;

  covergroup covgrp;
    option.per_instance = 1;

    // NOTE:
    // ?ôË£°??m_req.index ?∂‰? "len" ?∂ÂØ¶‰ª?°® byte Â∫èË?/?∑Â∫¶Ë≥áË?
    // ÔºàË?‰Ω†Á? rx_in_monitor Â¶Ç‰?Ë®≠Â? index ?âÈ?Ôº?
    len_cp: coverpoint m_req.index {
      bins len_1 = {[1:127]};
      bins len_2 = {[128:255]};
      bins len_3 = {[256:383]};
      bins len_4 = {[384:511]};
      bins len_5 = {[512:639]};
      bins len_6 = {[640:767]};
      bins len_7 = {[768:895]};
      bins len_8 = {[896:1023]};
    }

    // remainder = m_req.rxd.size()%4;  // not used

    vld_cp: coverpoint (m_req.index % 4) {
      bins full = {0};
      bins p1   = {1};
      bins p2   = {2};
      bins p3   = {3};
    }

    lenXvld: cross len_cp, vld_cp;

  endgroup

  function new(string name = "", uvm_component parent);
    super.new(name, parent);
    covgrp = new();
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_req = rx_req_trans_c::type_id::create("m_req", this);
  endfunction

  virtual function void write(rx_req_trans_c t);
    // assign received transaction to m_req
    if (t.rxdv) begin
      // deep copy:
      // clone() returns uvm_object, must cast back to rx_req_trans_c
      if (!$cast(m_req, t.clone())) begin
        `uvm_fatal("COV_RX", "clone() cast to rx_req_trans_c failed")
      end
    end

    // Response sample, record coverage
    if (t.last) begin
      `uvm_info("COV_RX",
                $sformatf("Sample rxdv=%0d, rx_byte_cnt=%0d",
                          t.rxdv, t.index),
                UVM_NONE)
    end

    // use rxdv instead of conv_en to sample coverage
    if (t.rxdv) begin
      covgrp.sample();
    end
  endfunction

endclass
/*************************************************************************** 
  * Design Name     : Input Monitor for RX Engine (HW1)
  * Function        : Capture input signals of RX_ENG and broadcast
  * File Name       : testbench/agent_rx/rx_in_monitor.sv
  ***************************************************************************/


class rx_in_monitor_c extends uvm_monitor;
  `uvm_component_utils(rx_in_monitor_c)

  virtual rx_intf vif;
  uvm_analysis_port#(rx_req_trans_c) m_ap;

  function new(string name = "", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual rx_intf)::get(this, "", "rx_vif", vif)) begin
      `uvm_fatal("iMON_RX", "Failed to get rx_vif from config_db")
    end

    m_ap = new("m_ap", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    rx_req_trans_c tr_cur;
    rx_req_trans_c tr_prev;

    bit prev_rxdv;
    bit prev_conv_en;
    int unsigned byte_index;

    prev_rxdv   = 1'b0;
    prev_conv_en= 1'b0;
    byte_index  = 0;
    tr_prev     = null;

    wait (vif.rst_n === 1'b1);

    forever begin
      @(posedge vif.clk);

      // --------------------------------------------------------
      // ??conv_en å¾?1->0ï¼Œè???frame çµæ?ï¼šæ? tr_prev flush ??last
      // --------------------------------------------------------
      if (prev_conv_en && !vif.conv_en) begin
        if (tr_prev != null) begin
          tr_prev.last = 1'b1;
          `uvm_info("iMON_RX",
                    $sformatf("FLUSH by conv_en deassert (LAST byte): %s",
                              tr_prev.convert2string()),
                    UVM_LOW)
          m_ap.write(tr_prev);
          tr_prev = null;
        end
        prev_rxdv = vif.rxdv;
        prev_conv_en = vif.conv_en;
        continue;
      end

      // --------------------------------------------------------
      // æ­?¸¸??§ï¼šåª??conv_en=1 ?‚è???input byte
      // --------------------------------------------------------
      if (vif.conv_en) begin

        if (vif.rxdv) begin
          tr_cur = rx_req_trans_c::type_id::create("tr_cur", this);

          tr_cur.conv_en = vif.conv_en;
          tr_cur.rxdv    = vif.rxdv;
          tr_cur.rxd     = vif.rxd;

          tr_cur.cmd     = rx_req_trans_c::T_DATA;
          tr_cur.index   = byte_index;
          byte_index++;

          tr_cur.last    = 1'b0;

          // ?ˆé€ä?ä¸€ç­†ï??¯ç¢ºå®šä???lastï¼?
          if (tr_prev != null) begin
            `uvm_info("iMON_RX",
                      $sformatf("SEND (not-last): %s", tr_prev.convert2string()),
                      UVM_LOW)
            m_ap.write(tr_prev);
          end

          tr_prev = tr_cur;
        end
        else begin
          // RXDV falling edgeï¼šä?ä¸€ç­†å°±?¯æ?å¾Œä???byte
          if (prev_rxdv && (tr_prev != null)) begin
            tr_prev.last = 1'b1;

            `uvm_info("iMON_RX",
                      $sformatf("SEND (LAST byte): %s", tr_prev.convert2string()),
                      UVM_LOW)

            m_ap.write(tr_prev);
            tr_prev = null;
          end
        end

        prev_rxdv = vif.rxdv;
      end
      else begin
        // conv_en=0 ?‚åª?´æ–°?€?‹é¿?èª¤??
        prev_rxdv = vif.rxdv;
      end

      prev_conv_en = vif.conv_en;
    end
  endtask

endclass
/***************************************************************************
  * Design Name     : output Monitor for RX Engine
  * Function        : Capture RX output signals and Broadcast
  * File Name       : testbench/agent_rx/rx_out_monitor.sv
  ***************************************************************************/

class rx_out_monitor_c extends uvm_monitor;
  `uvm_component_utils(rx_out_monitor_c)

  // Virtual interface for RX
  virtual rx_intf vif;

  // Analysis port
  uvm_analysis_port#(rx_rsp_trans_c) m_ap;

  function new(string name = "", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual rx_intf)::get(this, "", "rx_vif", vif)) begin
      `uvm_fatal("RX_oMON", "Failed to get rx_vif from config_db")
    end

    m_ap = new("m_ap", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    int index;

    index = 0;

    // Wait until reset de-asserts
    wait (vif.rst_n === 1'b1);
    @(posedge vif.clk);

    forever begin
      @(posedge vif.clk);

      // ?ªåœ¨ output valid ?‚å?æ¨???•å½±?‡é€šå¸¸å°±æ˜¯ valid_out ä½œç‚º qualifierï¼?
      if (vif.valid_out && vif.conv_en) begin
        rx_rsp_trans_c tr;

        tr = rx_rsp_trans_c::type_id::create("tr", this);

        tr.valid_out = vif.valid_out;
        tr.data_out  = vif.data_out;
        tr.byte_cnt  = vif.byte_cnt;
        tr.last      = vif.last;      // ???œéµï¼šä?å®šè???last
        tr.index     = index;

        `uvm_info("RX_oMON",
                  $sformatf("DUT out#[%0d]: data_out=0x%08h valid_out=%0b byte_cnt=%0d last=%0b",
                            tr.index, tr.data_out, tr.valid_out, tr.byte_cnt, tr.last),
                  UVM_LOW)

        m_ap.write(tr);
        index++;
      end
    end
  endtask

endclass
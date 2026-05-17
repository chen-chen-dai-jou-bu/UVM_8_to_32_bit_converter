class rx_driver_c extends uvm_driver #(rx_req_trans_c);
  `uvm_component_utils(rx_driver_c)

  // Transaction handle (from sequencer)
  rx_req_trans_c m_req;

  // Virtual interface for RX engine
  virtual rx_intf vif;

  function new(string name = "", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Retrieve rx_intf from config DB
    if (!uvm_config_db#(virtual rx_intf)::get(this, "", "rx_vif", vif)) begin
      `uvm_error("DRV_RX", "Unable to get rx_vif from config_db")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);

    // Wait until reset de-asserts (rst_n = 1)
    wait (vif.rst_n === 1);

    forever begin
      // Get next item from sequencer
      seq_item_port.get_next_item(m_req);

      // Default safe drive (optionalï¼Œä?å¾ˆå¸¸?¨é¿??X)
      // ä¸è??¨é€™è£¡ç­?clockï¼Œå???wait è¡Œç‚º?±å? cmd æ±ºå?
      vif.conv_en <= m_req.conv_en;

      case (m_req.cmd)

        // ------------------------------------------------------------
        // DATA: drive (rxdv=1, rxd valid) for repeat_cycles cycles
        // ------------------------------------------------------------
        rx_req_trans_c::T_DATA: begin
          // ??sequence æ²’ç‰¹?¥çµ¦ repeat_cyclesï¼Œé¿??0 è®Šæ?æ²’é€åˆ°
          int unsigned n = (m_req.repeat_cycles == 0) ? 1 : m_req.repeat_cycles;

          repeat (n) begin
            vif.conv_en <= m_req.conv_en;
            vif.rxdv    <= 1'b1;        // DATA ä¸€å®šè???1
            vif.rxd     <= m_req.rxd;   // ?™ç? atomic byte
            @(posedge vif.clk);
          end
        end

        // ------------------------------------------------------------
        // IFG: keep rxdv low for repeat_cycles cycles (suggest >=10)
        // ------------------------------------------------------------
        rx_req_trans_c::T_IFG: begin
          int unsigned n = (m_req.repeat_cycles == 0) ? 1 : m_req.repeat_cycles;

          repeat (n) begin
            vif.conv_en <= m_req.conv_en;
            vif.rxdv    <= 1'b0;
            vif.rxd     <= 8'h00;
            @(posedge vif.clk);
          end
        end

        // ------------------------------------------------------------
        // FRAME_END: de-assert rxdv to indicate end of a reception
        // Usually 1 cycle, but allow repeat_cycles
        // ------------------------------------------------------------
        rx_req_trans_c::T_FRAME_END: begin
          int unsigned n = (m_req.repeat_cycles == 0) ? 1 : m_req.repeat_cycles;

          repeat (n) begin
            vif.conv_en <= m_req.conv_en;
            vif.rxdv    <= 1'b0;
            vif.rxd     <= 8'h00;
            @(posedge vif.clk);
          end
        end

        default: begin
          `uvm_warning("DRV_RX",
                       $sformatf("Unknown cmd=%0d, drive safe values for 1 cycle", m_req.cmd))
          vif.conv_en <= m_req.conv_en;
          vif.rxdv    <= 1'b0;
          vif.rxd     <= 8'h00;
          @(posedge vif.clk);
        end

      endcase

      // IMPORTANT: item_done right after driven onto interface
      seq_item_port.item_done();

      // Debug
      `uvm_info("DRV_RX",
                $sformatf("Drive to DUT: %0s", m_req.convert2string()),
                UVM_NONE)

    end
  endtask

endclass
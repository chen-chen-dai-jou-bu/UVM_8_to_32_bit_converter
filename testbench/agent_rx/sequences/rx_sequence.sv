class rx_sequence_c extends uvm_sequence #(rx_req_trans_c);
  `uvm_object_utils(rx_sequence_c)

  // Transaction object to hold item data
  rx_req_trans_c     m_req;

  // Payload object (new to HW1)
  rx_payload_body_c  m_payload;

  function new(string name = "");
    super.new(name);
  endfunction

  virtual task body();
    int byte_index;

    // ============================================================
    // 1st step: generate control transaction to enable conv_en
    // ============================================================
    m_req = rx_req_trans_c::type_id::create("m_req");

    // ??control transaction ?ˆæ? conv_en ?‰é?
    m_req.cmd           = rx_req_trans_c::T_FRAME_END; // ?™è£¡?¨ä??Œæ§?¶ã€ç”¨??
    m_req.repeat_cycles = 1;
    m_req.conv_en       = 1'b1;
    m_req.rxdv          = 1'b0;
    m_req.rxd           = 8'h00;
    m_req.index         = 0;

    start_item(m_req);
    finish_item(m_req);

    // ============================================================
    // 2nd step: generate data transactions from payload
    // ============================================================
    // Create handle for m_payload (follow "create new handle for new transaction" policy)
    m_payload = rx_payload_body_c::type_id::create("m_payload");

    if (!m_payload.randomize()) begin
      `uvm_error("SEQ_RX", "RXD Payload Randomization Failed")
    end
    else begin
      `uvm_info("SEQ_RX",
                $sformatf("Total %0d Bytes Data Generated", m_payload.rxd_payload.size()),
                UVM_MEDIUM)
      // å¦‚é??´è©³ç´?debugï¼Œå¯?¹æ?ï¼?
      // `uvm_info("SEQ_RX", m_payload.convert2string(), UVM_MEDIUM)
    end

    // Reset byte_index to 0 before foreach loop
    byte_index = 0;

    // Practice foreach loop to generate atomic (1 data per time) transaction
    foreach (m_payload.rxd_payload[i]) begin
      // Create a new transaction each time (atomic transaction)
      m_req = rx_req_trans_c::type_id::create("m_req");

      // Indicate this is DATA
      m_req.cmd           = rx_req_trans_c::T_DATA;
      m_req.repeat_cycles = 1;                 // æ¯å€?byte ??1 ??cycleï¼ˆdriver ç«¯é€šå¸¸??repeat_cycles ?§åˆ¶ holdï¼?
      m_req.conv_en       = 1'b1;
      m_req.rxdv          = 1'b1;
      m_req.rxd           = m_payload.rxd_payload[i];
      m_req.index         = byte_index;

      // Advance byte_index
      byte_index++;

      start_item(m_req);
      finish_item(m_req);
    end

    // ============================================================
    // 3rd step: generate control transaction to de-assert RXDV
    // ============================================================
    m_req = rx_req_trans_c::type_id::create("m_req");

    // è®?rxdv ?‰ä?ï¼Œä¸¦çµ?IFG gapï¼ˆspec å¸¸è?æ±?>=10 cyclesï¼?
    m_req.cmd           = rx_req_trans_c::T_IFG;
    m_req.repeat_cycles = 10;        // ä½ ä??¯ä»¥?¹æ? 10~20ï¼Œä?ä½œæ¥­/driver?€æ±?
    m_req.conv_en       = 1'b1;      // ?¯å¦ä¿æ? enableï¼šé€šå¸¸ä¿æ? 1ï¼Œæ?è¼ƒç¬¦?ˆé€?? reception
    m_req.rxdv          = 1'b0;
    m_req.rxd           = 8'h00;
    m_req.index         = 0;

    start_item(m_req);
    finish_item(m_req);

  endtask

endclass
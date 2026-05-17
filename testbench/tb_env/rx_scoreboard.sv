/***************************************************************************
  * Design Name     : Scoreboard for RX Engine (HW1)
  * Function        : Receive input/output transactions via TLM FIFOs,
  *                   run two parallel tasks:
  *                     1) process_input : get rx_req_trans_c from input_fifo,
  *                        call ref_model to predict expected rx_rsp_trans_c,
  *                        put into expect_fifo (ONLY when exp != null)
  *                     2) process_output: get rx_rsp_trans_c from omon_fifo,
  *                        get rx_rsp_trans_c from expect_fifo,
  *                        compare and update statistics
  * File Name       : testbench/tb_env/rx_scoreboard.sv
  ***************************************************************************/

class rx_scoreboard_c extends uvm_scoreboard;
  `uvm_component_utils(rx_scoreboard_c)

  // Receive from monitors
  uvm_tlm_analysis_fifo#(rx_req_trans_c) input_fifo;
  uvm_tlm_analysis_fifo#(rx_rsp_trans_c) omon_fifo;

  // Expected FIFO (depth = 16)
  uvm_tlm_fifo#(rx_rsp_trans_c) expect_fifo;

  // Reference model
  rx_ref_model_c m_refmod;

  // Statistics
  int total_trans;
  int total_match;
  int total_mismatch;

  // HW1 counters
  int process_input_cnt;   // count of EXPECTED WORD generated (not bytes)
  int process_output_cnt;  // count of OUTPUT WORD observed

  function new(string name = "", uvm_component parent);
    super.new(name, parent);
    total_trans        = 0;
    total_match        = 0;
    total_mismatch     = 0;
    process_input_cnt  = 0;
    process_output_cnt = 0;
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    input_fifo  = new("input_fifo", this);
    omon_fifo   = new("omon_fifo",  this);
    expect_fifo = new("expect_fifo", this, 16);

    m_refmod = rx_ref_model_c::type_id::create("m_refmod", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);

    fork
      process_input();
      process_output();
    join
  endtask

  // ------------------------------------------------------------
  // process_input: byte stream -> expected word stream
  // - predict() may or may not generate exp in each call
  // - ONLY put into expect_fifo when exp != null
  // ------------------------------------------------------------
  virtual task process_input();
    rx_req_trans_c m_req;
    rx_rsp_trans_c m_exp;
    bit flag_4bytes;

    flag_4bytes = 0;

    do begin
      input_fifo.get(m_req);

      `uvm_info("SCR_RX",
                $sformatf("IN  : %s", m_req.convert2string()),
                UVM_LOW)

      // predict() requires 3 args
      m_refmod.predict(m_req, m_exp, flag_4bytes);

      // ??FIX: only enqueue when ref model produced a word
      if (m_exp != null) begin
        expect_fifo.put(m_exp);
        process_input_cnt++;

        `uvm_info("SCR_RX",
                  $sformatf("EXP : %s (process_input_cnt=%0d)",
                            m_exp.convert2string(), process_input_cnt),
                  UVM_LOW)
      end

    end while (!(m_req.last));
  endtask

  // ------------------------------------------------------------
  // process_output: actual word stream vs expected word stream
  // ------------------------------------------------------------
  virtual task process_output();
    rx_rsp_trans_c m_rsp;
    rx_rsp_trans_c m_exp;

    do begin
      omon_fifo.get(m_rsp);
      if (m_rsp == null) begin
        `uvm_warning("SCR_RX", "Got NULL m_rsp from omon_fifo (unexpected), skip")
        continue;
      end

      expect_fifo.get(m_exp);
      if (m_exp == null) begin
        `uvm_warning("SCR_RX", "Got NULL m_exp from expect_fifo (unexpected), skip")
        continue;
      end

      `uvm_info("SCR_RX",
                $sformatf("OUT : %s", m_rsp.convert2string()),
                UVM_LOW)

      check_result(m_rsp, m_exp);

      process_output_cnt++;

      `uvm_info("SCR_RX",
                $sformatf("process_output_cnt=%0d", process_output_cnt),
                UVM_LOW)

    end while (!(m_rsp.last));
  endtask

  // ------------------------------------------------------------
  // check_result
  // ------------------------------------------------------------
  virtual task check_result(rx_rsp_trans_c got, rx_rsp_trans_c exp);
    if ((got == null) || (exp == null)) begin
      `uvm_error("SCR_RX", "check_result got NULL handle(s)")
      return;
    end

    total_trans++;

    if ((got.data_out == exp.data_out) &&
        (got.byte_cnt == exp.byte_cnt) &&
        (got.last     == exp.last)) begin
      total_match++;
      `uvm_info("SCR_RX",
                $sformatf("PASS: GOT=%s | EXP=%s",
                          got.convert2string(), exp.convert2string()),
                UVM_LOW)
    end
    else begin
      total_mismatch++;
      `uvm_error("SCR_RX",
                 $sformatf("FAIL: GOT=%s | EXP=%s",
                           got.convert2string(), exp.convert2string()))
    end
  endtask

  // ------------------------------------------------------------
  // check_phase: compare generated expected words vs observed output words
  // ------------------------------------------------------------
  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);

    if (process_input_cnt < process_output_cnt) begin
      `uvm_warning("SCR_RX",
                   $sformatf("process_input_cnt(%0d) < process_output_cnt(%0d)",
                             process_input_cnt, process_output_cnt))
    end
  endfunction

  // ------------------------------------------------------------
  // report_phase: print "Process # MATCH ..." like the screenshot
  // ------------------------------------------------------------
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    if ((process_input_cnt == process_output_cnt) && (total_mismatch == 0)) begin
      `uvm_info("SCB_RX",
                $sformatf("Process # MATCH : input[%0d], output[%0d]",
                          process_input_cnt, process_output_cnt),
                UVM_NONE)
    end
    else begin
      `uvm_info("SCB_RX",
                $sformatf("Process # MISMATCH : input[%0d], output[%0d], mismatch=%0d",
                          process_input_cnt, process_output_cnt, total_mismatch),
                UVM_NONE)
    end
  endfunction

  virtual function string convert2string();
    real   match_rate;
    string s;

    match_rate = total_trans ? (total_match * 100.0 / total_trans) : 0;

    s = super.convert2string();
    s = {s, "\n"};
    s = {s, "============================================================\n"};
    s = {s, $sformatf("%0s Scoreboard Report\n", get_full_name())};
    s = {s, "============================================================\n"};
    s = {s, "Transaction Summary\n"};
    s = {s, $sformatf("Total      : %0d\n", total_trans)};
    s = {s, $sformatf("Match      : %0d(%0.2f%%)\n", total_match, match_rate)};
    s = {s, $sformatf("MisMatch   : %0d\n", total_mismatch)};
    s = {s, "------------------------------------------------------------\n"};
    s = {s, $sformatf("process_input_cnt  : %0d\n", process_input_cnt)};
    s = {s, $sformatf("process_output_cnt : %0d\n", process_output_cnt)};
    s = {s, "============================================================\n"};
    return s;
  endfunction

endclass
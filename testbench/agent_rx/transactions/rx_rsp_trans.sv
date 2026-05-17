class rx_rsp_trans_c extends packet_base_trans_c;

  function new(string name = "");
    super.new(name);
  endfunction

  // ============================================================
  // Data Declaration according to RX_ENG output interface
  //   - valid_out : output valid pulse
  //   - data_out  : 32-bit output data (valid when valid_out=1)
  //   - byte_cnt  : total received byte count (valid when valid_out=1)
  //   - last      : indicate last output word (assert with valid_out)
  // ============================================================
  rand bit        valid_out;
  rand bit [31:0] data_out;
  rand bit [9:0]  byte_cnt;
  rand bit        last;

  // ------------------------------------------------------------
  // Print Out All Fields (index is defined in packet_base_trans_c)
  // ------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("data_out[%0d]=%0h, valid_out=%0b, byte_cnt=%0d, last=%0b",
                     index, data_out, valid_out, byte_cnt, last);
  endfunction

  // ------------------------------------------------------------
  // Factory registration + field automation
  // ------------------------------------------------------------
  `uvm_object_utils_begin(rx_rsp_trans_c)
    `uvm_field_int(valid_out, UVM_DEFAULT)
    `uvm_field_int(data_out,  UVM_DEFAULT)
    `uvm_field_int(byte_cnt,  UVM_DEFAULT)
    `uvm_field_int(last,      UVM_DEFAULT)
  `uvm_object_utils_end

endclass
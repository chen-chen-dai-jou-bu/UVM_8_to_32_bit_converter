class rx_req_trans_c extends packet_base_trans_c;

    function new(string name = "");
        super.new(name);
    endfunction

    // ============================================================
    // Data Declaration according to RX_ENG input interface
    //   - conv_en : enable (active high)
    //   - rxdv    : receive data valid (active high)
    //   - rxd     : 8-bit input data
    // ============================================================
    rand bit        conv_en;
    rand bit        rxdv;
    rand bit [7:0]  rxd;

    // ============================================================
    // Flow Control Flag (reflect new DUT input behavior)
    //   RX ?ÄË¶ÅÊ??åÈÄÅË??ô„Äç„ÄÅ„ÄåÁ??ü‰?Ê¨?reception?ç„ÄÅ„ÄåIFG Á©∫Ê???
    // ============================================================
    typedef enum {T_DATA, T_FRAME_END, T_IFG} cmd_t;

    rand cmd_t cmd;

    // repeat_cycles ?®‰??ßÂà∂Ôº?
    //   - T_DATA:   ????ÅÂπæ??cycle ??(rxdv=1, rxd valid)
    //   - T_IFG:    rxdv=0 ?ÑÁ©∫Ê™îÂπæ??cycle (Âª∫Ë≠∞ >= 10)
    //   - T_FRAME_END: ?öÂ∏∏??1 cycle Ë°®Á§∫ÁµêÊ?‰∫ã‰ª∂ (rxdv=0)
    rand int unsigned repeat_cycles;

    // ------------------------------------------------------------
    // convert2string(): show all input signals + flow control
    // ------------------------------------------------------------
    virtual function string convert2string();
        string s;
        s = super.convert2string();
        s = {s,
             $sformatf(" cmd=%s repeat_cycles=%0d | conv_en=%0b rxdv=%0b rxd=0x%02h",
                       cmd.name(), repeat_cycles, conv_en, rxdv, rxd)};
        return s;
    endfunction

    // ------------------------------------------------------------
    // Factory registration + field automation
    // ------------------------------------------------------------
    `uvm_object_utils_begin(rx_req_trans_c)
        `uvm_field_int(conv_en,       UVM_DEFAULT)
        `uvm_field_int(rxdv,          UVM_DEFAULT)
        `uvm_field_int(rxd,           UVM_DEFAULT)
        `uvm_field_enum(cmd_t, cmd,   UVM_DEFAULT)
        `uvm_field_int(repeat_cycles, UVM_DEFAULT)
    `uvm_object_utils_end

endclass
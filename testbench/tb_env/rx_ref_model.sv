/***************************************************************************
  * Design Name     : RX Reference Model (HW1)
  * Function        : Predict 32-bit output words from 8-bit RXD stream
  * File Name       : testbench/tb_env/rx_ref_model.sv
  ***************************************************************************/

class rx_ref_model_c extends uvm_component;
  `uvm_component_utils(rx_ref_model_c)

  // ?¶é? 4 bytes ?„æš«å­˜å™¨
  logic [7:0] rxd_captured [4] = '{default:'0};

  function new(string name = "", uvm_component parent);
    super.new(name, parent);
  endfunction

  // ------------------------------------------------------------
  // predict():
  //   src_in      : input transaction from input monitor (byte stream)
  //   exp_out     : output transaction (word stream); may be null if not ready
  //   flag_4bytes : pulse when a full 4-byte word boundary generated
  //
  // IMPORTANT (??DUT è¦æ ¼ä¸€??:
  // - byte_cnt ?¯ã€Œç´¯ç©æ”¶?°ç?ç¸?byte ?¸ã€?total received byte count)
  // - ?ªæ??¶æ»¿ 4 bytes ??src_in.last=1 ?ç”¢??exp_out
  // - ?¥ä?è¶?4 bytes ä¸?last=1ï¼Œå‰©é¤?byte ä»?0 padding
  // ------------------------------------------------------------
  task predict(input  rx_req_trans_c src_in,
               output rx_rsp_trans_c exp_out,
               inout  bit           flag_4bytes);

    // static to keep value across calls
    static int word_index   = 0;   // word åºè?ï¼ˆå¯?¨æ–¼ debugï¼?
    static int byte_pos     = 0;   // 0~3
    static int total_bytes  = 0;   // ??ç´¯ç??¶åˆ°?„ç¸½ byte ??(?™æ˜¯ byte_cnt ?„æ­£ç¢ºæ?ç¾?

    // default outputs
    exp_out     = null;
    flag_4bytes = 0;

    // ?ªè??†ã€Œè??™æ??ˆã€ç? input byte
    if (!(src_in.conv_en && src_in.rxdv)) begin
      return;
    end

    // å¦‚æ?ä½ ç? sequence æ¯å€?frame ?„ç¬¬ä¸€??byte index ?½å? 0 ?‹å?ï¼?
    // ?¯ä»¥?¨é€™å€‹æ?ä»¶åœ¨??frame ?‹å???reset ç´¯ç?è¨ˆæ•¸??word_index
    if ((src_in.index == 0) && (byte_pos == 0)) begin
      total_bytes = 0;
      word_index  = 0;
      rxd_captured = '{default:'0};
    end

    // collect byte
    if (byte_pos < 4) begin
      rxd_captured[byte_pos] = src_in.rxd;
      byte_pos++;
      total_bytes++; // ??æ¯æ”¶?°ä??‹æ???byteï¼Œç´¯ç©ç¸½??+1
    end

    // ?¢ç? output ?„æ?ä»¶ï??¶æ»¿ 4 bytes ??last byte
    if ((byte_pos == 4) || (src_in.last)) begin
      exp_out = rx_rsp_trans_c::type_id::create("exp_out", this);

      exp_out.valid_out = 1'b1;

      // ??byte_cnt å¿…é??¯ã€Œç´¯ç©æ”¶?°ç?ç¸?bytes??
      exp_out.byte_cnt  = total_bytes;

      // word indexï¼ˆdebug ?¨ï?ä¸å??‡ä? scoreboard ??compareï¼?
      exp_out.index     = word_index;

      // last word indication
      exp_out.last      = src_in.last ? 1'b1 : 1'b0;

      // Pack bytes into 32-bit word (little-endian):
      // first byte -> [7:0], second -> [15:8], ...
      // ä¸è¶³ 4 bytes ?„ä?ç½®æ???0 (padding)
      exp_out.data_out  = {rxd_captured[3], rxd_captured[2], rxd_captured[1], rxd_captured[0]};

      `uvm_info("RX_REF",
                $sformatf("PRED word#[%0d] data_out=0x%08h byte_cnt(total)=%0d last=%0b",
                          exp_out.index, exp_out.data_out, exp_out.byte_cnt, exp_out.last),
                UVM_MEDIUM)

      word_index++;

      // boundary flag pulse
      if (byte_pos == 4) flag_4bytes = 1;

      // reset collector for next word
      byte_pos = 0;
      rxd_captured = '{default:'0};
    end

  endtask

endclass
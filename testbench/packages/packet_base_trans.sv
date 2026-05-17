/******************************************************************************** 
  * Design Name     : Base Transaction used by All REQ/RSP Transaction
  * Function        : Include fundamental fields
  *   - packet_length : Length of this packet
  *   - batch_id      : indicate current batch, in case any
  *   - index         : current transaction serial number
  *   - last          : Last Transaction Indication
  * File Name       : testbench/packages/packet_base_trans.sv
  * Author          : Michael Su
  * Version         : 1.00
  * Date            : 2025-10-02
  ********************************************************************************/

class packet_base_trans_c extends uvm_sequence_item;

  // Constructor
  function new(string name = "");
    super.new(name);
    index = 0;
    last  = 0;
  endfunction

  // Transaction ID Control, used by Scoreboard in case necessary
  rand int packet_length;  // total number of transactions
  rand int batch_id;       // Assigned by Sequence
       int index;          // serial number (not rand)
       bit last;           // Final-work marker

  // ------------------------------------------------------------
  // do_copy(): MUST copy all base fields
  // ------------------------------------------------------------
  virtual function void do_copy(uvm_object rhs);
    packet_base_trans_c rhs_copied;

    super.do_copy(rhs);

    if (!$cast(rhs_copied, rhs)) begin
      `uvm_fatal("PKT_BASE", "Can't cast rhs to packet_base_trans_c")
    end

    this.packet_length = rhs_copied.packet_length;
    this.batch_id      = rhs_copied.batch_id;
    this.index         = rhs_copied.index;
    this.last          = rhs_copied.last;
  endfunction

  // Register fields for automatic record/print/compare
  `uvm_object_utils_begin(packet_base_trans_c)
    `uvm_field_int(packet_length, UVM_ALL_ON)
    `uvm_field_int(batch_id,      UVM_ALL_ON)
    `uvm_field_int(index,         UVM_ALL_ON)
    `uvm_field_int(last,          UVM_ALL_ON)
  `uvm_object_utils_end

endclass
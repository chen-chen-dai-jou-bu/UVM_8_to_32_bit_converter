class rx_env_c extends uvm_env;

  `uvm_component_utils(rx_env_c)

  // Follow naming convention: ipname_ + _agt/_sb/_cov
  rx_agent_c      m_rx_agt;
  rx_scoreboard_c m_rx_sb;
  rx_coverage_c   m_rx_cov;

  function new(string name = "", uvm_component parent);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    m_rx_agt = rx_agent_c::type_id::create("m_rx_agt", this);
    m_rx_sb  = rx_scoreboard_c::type_id::create("m_rx_sb", this);
    m_rx_cov = rx_coverage_c::type_id::create("m_rx_cov", this);
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // ------------------------------------------------------------
    // Input Monitor connections
    //   1) input monitor -> scoreboard input_fifo.analysis_export
    //   2) input monitor -> coverage (only input signals needed)
    // ------------------------------------------------------------
    m_rx_agt.m_imon.m_ap.connect(m_rx_sb.input_fifo.analysis_export);
    m_rx_agt.m_imon.m_ap.connect(m_rx_cov.analysis_export);

    // ------------------------------------------------------------
    // Output Monitor connections
    //   output monitor -> scoreboard omon_fifo.analysis_export
    //   (Remove output monitor -> coverage connection)
    // ------------------------------------------------------------
    m_rx_agt.m_omon.m_ap.connect(m_rx_sb.omon_fifo.analysis_export);

  endfunction : connect_phase

endclass
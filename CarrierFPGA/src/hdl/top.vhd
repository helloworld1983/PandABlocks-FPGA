--------------------------------------------------------------------------------
-- File: panda_top.vhd
-- Desc: PandA top-level design
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.support.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_top is
generic (
    AXI_BURST_LEN : integer := 16;
    AXI_ADDR_WIDTH : integer := 32;
    AXI_DATA_WIDTH : integer := 32
);
port (
    DDR_addr : inout std_logic_vector (14 downto 0);
    DDR_ba : inout std_logic_vector (2 downto 0);
    DDR_cas_n : inout std_logic;
    DDR_ck_n : inout std_logic;
    DDR_ck_p : inout std_logic;
    DDR_cke : inout std_logic;
    DDR_cs_n : inout std_logic;
    DDR_dm : inout std_logic_vector (3 downto 0);
    DDR_dq : inout std_logic_vector (31 downto 0);
    DDR_dqs_n : inout std_logic_vector (3 downto 0);
    DDR_dqs_p : inout std_logic_vector (3 downto 0);
    DDR_odt : inout std_logic;
    DDR_ras_n : inout std_logic;
    DDR_reset_n : inout std_logic;
    DDR_we_n : inout std_logic;
    FIXED_IO_ddr_vrn : inout std_logic;
    FIXED_IO_ddr_vrp : inout std_logic;
    FIXED_IO_mio : inout std_logic_vector (53 downto 0);
    FIXED_IO_ps_clk : inout std_logic;
    FIXED_IO_ps_porb : inout std_logic;
    FIXED_IO_ps_srstb : inout std_logic;

    -- Slow Controller Serial interface
    spi_sclk_o : out std_logic;
    spi_dat_o : out std_logic;
    spi_sclk_i : in std_logic;
    spi_dat_i : in std_logic;

    -- RS485 Channel 0 Encoder I/O
    Am0_pad_io : inout std_logic_vector(ENC_NUM-1 downto 0);
    Bm0_pad_io : inout std_logic_vector(ENC_NUM-1 downto 0);
    Zm0_pad_io : inout std_logic_vector(ENC_NUM-1 downto 0);
    As0_pad_io : inout std_logic_vector(ENC_NUM-1 downto 0);
    Bs0_pad_io : inout std_logic_vector(ENC_NUM-1 downto 0);
    Zs0_pad_io : inout std_logic_vector(ENC_NUM-1 downto 0);

    -- Status I/O
    enc0_ctrl_pad_i : in std_logic_vector(3 downto 0);
    enc0_ctrl_pad_o : out std_logic_vector(11 downto 0);

    -- Discrete I/O
    ttlin_pad_i : in std_logic_vector(TTLIN_NUM-1 downto 0);
    ttlout_pad_o : out std_logic_vector(TTLOUT_NUM-1 downto 0);
    lvdsin_pad_i : in std_logic_vector(LVDSIN_NUM-1 downto 0);
    lvdsout_pad_o : out std_logic_vector(LVDSOUT_NUM-1 downto 0)
);
end panda_top;

architecture rtl of panda_top is

component ila_32x8K
port (
    clk : in std_logic;
    probe0 : in std_logic_vector(31 downto 0)
);
end component;

signal probe0 : std_logic_vector(31 downto 0);

-- Signal declarations
signal FCLK_CLK0 : std_logic;
signal FCLK_RESET0_N : std_logic_vector(0 downto 0);
signal FCLK_RESET0 : std_logic;

signal M00_AXI_awaddr : std_logic_vector ( 31 downto 0 );
signal M00_AXI_awprot : std_logic_vector ( 2 downto 0 );
signal M00_AXI_awvalid : std_logic;
signal M00_AXI_awready : std_logic;
signal M00_AXI_wdata : std_logic_vector ( 31 downto 0 );
signal M00_AXI_wstrb : std_logic_vector ( 3 downto 0 );
signal M00_AXI_wvalid : std_logic;
signal M00_AXI_wready : std_logic;
signal M00_AXI_bresp : std_logic_vector ( 1 downto 0 );
signal M00_AXI_bvalid : std_logic;
signal M00_AXI_bready : std_logic;
signal M00_AXI_araddr : std_logic_vector ( 31 downto 0 );
signal M00_AXI_arprot : std_logic_vector ( 2 downto 0 );
signal M00_AXI_arvalid : std_logic;
signal M00_AXI_arready : std_logic;
signal M00_AXI_rdata : std_logic_vector ( 31 downto 0 );
signal M00_AXI_rresp : std_logic_vector ( 1 downto 0 );
signal M00_AXI_rvalid : std_logic;
signal M00_AXI_rready : std_logic;

signal S_AXI_HP0_awready : std_logic := '1';
signal S_AXI_HP0_awregion : std_logic_vector(3 downto 0);
signal S_AXI_HP0_bid : std_logic_vector(5 downto 0) := (others => '0');
signal S_AXI_HP0_bresp : std_logic_vector(1 downto 0) := (others => '0');
signal S_AXI_HP0_bvalid : std_logic := '1';
signal S_AXI_HP0_wready : std_logic := '1';
signal S_AXI_HP0_awaddr : std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
signal S_AXI_HP0_awburst : std_logic_vector(1 downto 0);
signal S_AXI_HP0_awcache : std_logic_vector(3 downto 0);
signal S_AXI_HP0_awid : std_logic_vector(5 downto 0);
signal S_AXI_HP0_awlen : std_logic_vector(3 downto 0);
signal S_AXI_HP0_awlock : std_logic_vector(1 downto 0);
signal S_AXI_HP0_awprot : std_logic_vector(2 downto 0);
signal S_AXI_HP0_awqos : std_logic_vector(3 downto 0);
signal S_AXI_HP0_awsize : std_logic_vector(2 downto 0);
signal S_AXI_HP0_awvalid : std_logic;
signal S_AXI_HP0_bready : std_logic;
signal S_AXI_HP0_wdata : std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
signal S_AXI_HP0_wlast : std_logic;
signal S_AXI_HP0_wstrb : std_logic_vector(AXI_DATA_WIDTH/8-1 downto 0);
signal S_AXI_HP0_wvalid : std_logic;

signal S_AXI_HP1_araddr : STD_LOGIC_VECTOR ( 31 downto 0 );
signal S_AXI_HP1_arburst : STD_LOGIC_VECTOR ( 1 downto 0 );
signal S_AXI_HP1_arcache : STD_LOGIC_VECTOR ( 3 downto 0 );
signal S_AXI_HP1_arid : STD_LOGIC_VECTOR ( 5 downto 0 );
signal S_AXI_HP1_arlen : STD_LOGIC_VECTOR ( 7 downto 0 );
signal S_AXI_HP1_arlock : STD_LOGIC_VECTOR ( 0 to 0 );
signal S_AXI_HP1_arprot : STD_LOGIC_VECTOR ( 2 downto 0 );
signal S_AXI_HP1_arqos : STD_LOGIC_VECTOR ( 3 downto 0 );
signal S_AXI_HP1_arready : STD_LOGIC;
signal S_AXI_HP1_arregion : STD_LOGIC_VECTOR ( 3 downto 0 );
signal S_AXI_HP1_arsize : STD_LOGIC_VECTOR ( 2 downto 0 );
signal S_AXI_HP1_arvalid : STD_LOGIC;
signal S_AXI_HP1_rdata : STD_LOGIC_VECTOR ( 31 downto 0 );
signal S_AXI_HP1_rid : STD_LOGIC_VECTOR ( 5 downto 0 );
signal S_AXI_HP1_rlast : STD_LOGIC;
signal S_AXI_HP1_rready : STD_LOGIC;
signal S_AXI_HP1_rresp : STD_LOGIC_VECTOR ( 1 downto 0 );
signal S_AXI_HP1_rvalid : STD_LOGIC;

signal mem_cs : std_logic_vector(2**PAGE_NUM-1 downto 0);
signal mem_addr : std_logic_vector(PAGE_AW-1 downto 0);
signal mem_odat : std_logic_vector(31 downto 0);
signal mem_wstb : std_logic;
signal mem_rstb : std_logic;
signal mem_read_data : std32_array(2**PAGE_NUM-1 downto 0) :=
                                (others => (others => '0'));
signal mem_addr_reg : natural range 0 to (2**mem_addr'length - 1);
signal inenc_buf_ctrl : std_logic_vector(5 downto 0);
signal outenc_buf_ctrl : std_logic_vector(5 downto 0);

signal IRQ_F2P : std_logic_vector(0 downto 0);

-- Design Level Busses :
signal sysbus : sysbus_t := (others => '0');
signal posbus : posbus_t := (others => (others => '0'));
signal extbus : std32_array(ENC_NUM-1 downto 0);

-- Input Encoder
signal inenc_val : std32_array(ENC_NUM-1 downto 0);
signal inenc_val_upper : std32_array(ENC_NUM-1 downto 0);
signal inenc_a : std_logic_vector(ENC_NUM-1 downto 0);
signal inenc_b : std_logic_vector(ENC_NUM-1 downto 0);
signal inenc_z : std_logic_vector(ENC_NUM-1 downto 0);
signal inenc_conn : std_logic_vector(ENC_NUM-1 downto 0);

-- Output Encoder
signal outenc_conn : std_logic_vector(ENC_NUM-1 downto 0);

-- Discrete Block Outputs :
signal ttlin_val : std_logic_vector(TTLIN_NUM-1 downto 0);
signal ttlout_val : std_logic_vector(TTLOUT_NUM-1 downto 0);
signal lvdsin_val : std_logic_vector(LVDSIN_NUM-1 downto 0);
signal lut_val : std_logic_vector(LUT_NUM-1 downto 0);
signal srgate_out : std_logic_vector(SRGATE_NUM-1 downto 0);
signal div_outd : std_logic_vector(DIV_NUM-1 downto 0);
signal div_outn : std_logic_vector(DIV_NUM-1 downto 0);
signal pulse_out : std_logic_vector(PULSE_NUM-1 downto 0);
signal pulse_perr : std_logic_vector(PULSE_NUM-1 downto 0);
signal seq_outa : std_logic_vector(SEQ_NUM-1 downto 0);
signal seq_outb : std_logic_vector(SEQ_NUM-1 downto 0);
signal seq_outc : std_logic_vector(SEQ_NUM-1 downto 0);
signal seq_outd : std_logic_vector(SEQ_NUM-1 downto 0);
signal seq_oute : std_logic_vector(SEQ_NUM-1 downto 0);
signal seq_outf : std_logic_vector(SEQ_NUM-1 downto 0);
signal seq_active : std_logic_vector(SEQ_NUM-1 downto 0);

signal counter_carry : std_logic_vector(COUNTER_NUM-1 downto 0);
signal adder_out : std32_array(ADDER_NUM-1 downto 0);

signal pcomp_active : std_logic_vector(PCOMP_NUM-1 downto 0);
signal pcomp_out : std_logic_vector(PCOMP_NUM-1 downto 0);

signal panda_spbram_wea : std_logic := '0';

signal pcap_act : std_logic_vector(0 downto 0);

signal clocks_a : std_logic_vector(0 downto 0);
signal clocks_b : std_logic_vector(0 downto 0);
signal clocks_c : std_logic_vector(0 downto 0);
signal clocks_d : std_logic_vector(0 downto 0);

signal bits_zero : std_logic_vector(0 downto 0);
signal bits_one : std_logic_vector(0 downto 0);

signal bits_a : std_logic_vector(0 downto 0);
signal bits_b : std_logic_vector(0 downto 0);
signal bits_c : std_logic_vector(0 downto 0);
signal bits_d : std_logic_vector(0 downto 0);

signal qdec_out : std32_array(QDEC_NUM-1 downto 0);
signal counter_out : std32_array(COUNTER_NUM-1 downto 0);
signal posenc_a : std_logic_vector(POSENC_NUM-1 downto 0);
signal posenc_b : std_logic_vector(POSENC_NUM-1 downto 0);

signal adc_out : std32_array(7 downto 0) := (others => (others => '0'));

signal pgen_out : std32_array(PGEN_NUM-1 downto 0);

signal slowctrl_busy : std_logic;

signal enc0_ctrl_pad : std_logic_vector(11 downto 0);

signal slow_tlp_registers : slow_packet;
signal slow_tlp_leds : slow_packet;

signal rdma_req : std_logic_vector(5 downto 0);
signal rdma_ack : std_logic_vector(5 downto 0);
signal rdma_done : std_logic;
signal rdma_addr : std32_array(5 downto 0);
signal rdma_len : std8_array(5 downto 0);
signal rdma_data : std_logic_vector(31 downto 0);
signal rdma_valid : std_logic_vector(5 downto 0);

signal A_IN : std_logic_vector(ENC_NUM-1 downto 0);
signal B_IN : std_logic_vector(ENC_NUM-1 downto 0);
signal Z_IN : std_logic_vector(ENC_NUM-1 downto 0);
signal CLK_OUT : std_logic_vector(ENC_NUM-1 downto 0);
signal DATA_IN : std_logic_vector(ENC_NUM-1 downto 0);
signal A_OUT : std_logic_vector(ENC_NUM-1 downto 0);
signal B_OUT : std_logic_vector(ENC_NUM-1 downto 0);
signal Z_OUT : std_logic_vector(ENC_NUM-1 downto 0);
signal CLK_IN : std_logic_vector(ENC_NUM-1 downto 0);
signal DATA_OUT : std_logic_vector(ENC_NUM-1 downto 0);
signal OUTPROT : std3_array(ENC_NUM-1 downto 0);
signal INPROT : std3_array(ENC_NUM-1 downto 0);

signal SLOW_FPGA_VERSION : std_logic_vector(31 downto 0);
signal DCARD_MODE : std32_array(ENC_NUM-1 downto 0);

attribute keep : string;
attribute keep of sysbus : signal is "true";
attribute keep of posbus : signal is "true";

begin

-- Internal clocks and resets
FCLK_RESET0 <= not FCLK_RESET0_N(0);

--
-- Panda Processor System Block design instantiation
--
ps : entity work.panda_ps
port map (
    FCLK_CLK0 => FCLK_CLK0,
    FCLK_RESET0_N => FCLK_RESET0_N,

    DDR_addr(14 downto 0) => DDR_addr(14 downto 0),
    DDR_ba(2 downto 0) => DDR_ba(2 downto 0),
    DDR_cas_n => DDR_cas_n,
    DDR_ck_n => DDR_ck_n,
    DDR_ck_p => DDR_ck_p,
    DDR_cke => DDR_cke,
    DDR_cs_n => DDR_cs_n,
    DDR_dm(3 downto 0) => DDR_dm(3 downto 0),
    DDR_dq(31 downto 0) => DDR_dq(31 downto 0),
    DDR_dqs_n(3 downto 0) => DDR_dqs_n(3 downto 0),
    DDR_dqs_p(3 downto 0) => DDR_dqs_p(3 downto 0),
    DDR_odt => DDR_odt,
    DDR_ras_n => DDR_ras_n,
    DDR_reset_n => DDR_reset_n,
    DDR_we_n => DDR_we_n,

    FIXED_IO_ddr_vrn => FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp => FIXED_IO_ddr_vrp,
    FIXED_IO_mio(53 downto 0) => FIXED_IO_mio(53 downto 0),
    FIXED_IO_ps_clk => FIXED_IO_ps_clk,
    FIXED_IO_ps_porb => FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,
    IRQ_F2P => IRQ_F2P,

    M00_AXI_araddr(31 downto 0) => M00_AXI_araddr(31 downto 0),
    M00_AXI_arprot(2 downto 0) => M00_AXI_arprot(2 downto 0),
    M00_AXI_arready => M00_AXI_arready,
    M00_AXI_arvalid => M00_AXI_arvalid,
    M00_AXI_awaddr(31 downto 0) => M00_AXI_awaddr(31 downto 0),
    M00_AXI_awprot(2 downto 0) => M00_AXI_awprot(2 downto 0),
    M00_AXI_awready => M00_AXI_awready,
    M00_AXI_awvalid => M00_AXI_awvalid,
    M00_AXI_bready => M00_AXI_bready,
    M00_AXI_bresp(1 downto 0) => M00_AXI_bresp(1 downto 0),
    M00_AXI_bvalid => M00_AXI_bvalid,
    M00_AXI_rdata(31 downto 0) => M00_AXI_rdata(31 downto 0),
    M00_AXI_rready => M00_AXI_rready,
    M00_AXI_rresp(1 downto 0) => M00_AXI_rresp(1 downto 0),
    M00_AXI_rvalid => M00_AXI_rvalid,
    M00_AXI_wdata(31 downto 0) => M00_AXI_wdata(31 downto 0),
    M00_AXI_wready => M00_AXI_wready,
    M00_AXI_wstrb(3 downto 0) => M00_AXI_wstrb(3 downto 0),
    M00_AXI_wvalid => M00_AXI_wvalid,

    S_AXI_HP0_awaddr => S_AXI_HP0_awaddr ,
    S_AXI_HP0_awburst => S_AXI_HP0_awburst,
    S_AXI_HP0_awcache => S_AXI_HP0_awcache,
    S_AXI_HP0_awid => S_AXI_HP0_awid,
    S_AXI_HP0_awlen => S_AXI_HP0_awlen,
    S_AXI_HP0_awlock => S_AXI_HP0_awlock,
    S_AXI_HP0_awprot => S_AXI_HP0_awprot,
    S_AXI_HP0_awqos => S_AXI_HP0_awqos,
    S_AXI_HP0_awready => S_AXI_HP0_awready,
    S_AXI_HP0_awsize => S_AXI_HP0_awsize,
    S_AXI_HP0_awvalid => S_AXI_HP0_awvalid,
    S_AXI_HP0_bid => S_AXI_HP0_bid,
    S_AXI_HP0_bready => S_AXI_HP0_bready,
    S_AXI_HP0_bresp => S_AXI_HP0_bresp,
    S_AXI_HP0_bvalid => S_AXI_HP0_bvalid,
    S_AXI_HP0_wdata => S_AXI_HP0_wdata,
    S_AXI_HP0_wlast => S_AXI_HP0_wlast,
    S_AXI_HP0_wready => S_AXI_HP0_wready,
    S_AXI_HP0_wstrb => S_AXI_HP0_wstrb,
    S_AXI_HP0_wvalid => S_AXI_HP0_wvalid,

    S_AXI_HP1_araddr => S_AXI_HP1_araddr,
    S_AXI_HP1_arburst => S_AXI_HP1_arburst,
    S_AXI_HP1_arcache => S_AXI_HP1_arcache,
    S_AXI_HP1_arid => S_AXI_HP1_arid,
    S_AXI_HP1_arlen => S_AXI_HP1_arlen,
    S_AXI_HP1_arlock => S_AXI_HP1_arlock,
    S_AXI_HP1_arprot => S_AXI_HP1_arprot,
    S_AXI_HP1_arqos => S_AXI_HP1_arqos,
    S_AXI_HP1_arready => S_AXI_HP1_arready,
    S_AXI_HP1_arregion => S_AXI_HP1_arregion,
    S_AXI_HP1_arsize => S_AXI_HP1_arsize,
    S_AXI_HP1_arvalid => S_AXI_HP1_arvalid,
    S_AXI_HP1_rdata => S_AXI_HP1_rdata,
    S_AXI_HP1_rid => S_AXI_HP1_rid,
    S_AXI_HP1_rlast => S_AXI_HP1_rlast,
    S_AXI_HP1_rready => S_AXI_HP1_rready,
    S_AXI_HP1_rresp => S_AXI_HP1_rresp,
    S_AXI_HP1_rvalid => S_AXI_HP1_rvalid
);

--
-- Control and Status Memory Interface
--
-- 0x43c00000
panda_csr_if_inst : entity work.panda_csr_if
generic map (
    MEM_CSWIDTH => PAGE_NUM,
    MEM_AWIDTH => PAGE_AW
)
port map (
    S_AXI_CLK => FCLK_CLK0,
    S_AXI_RST => FCLK_RESET0,
    S_AXI_AWADDR => M00_AXI_awaddr,
    S_AXI_AWVALID => M00_AXI_awvalid,
    S_AXI_AWREADY => M00_AXI_awready,
    S_AXI_WDATA => M00_AXI_wdata,
    S_AXI_WSTRB => M00_AXI_wstrb,
    S_AXI_WVALID => M00_AXI_wvalid,
    S_AXI_WREADY => M00_AXI_wready,
    S_AXI_BRESP => M00_AXI_bresp,
    S_AXI_BVALID => M00_AXI_bvalid,
    S_AXI_BREADY => M00_AXI_bready,
    S_AXI_ARADDR => M00_AXI_araddr,
    S_AXI_ARVALID => M00_AXI_arvalid,
    S_AXI_ARREADY => M00_AXI_arready,
    S_AXI_RDATA => M00_AXI_rdata,
    S_AXI_RRESP => M00_AXI_rresp,
    S_AXI_RVALID => M00_AXI_rvalid,
    S_AXI_RREADY => M00_AXI_rready,
    mem_addr_o => mem_addr,
    mem_dat_i => mem_read_data,
    mem_dat_o => mem_odat,
    mem_cs_o => mem_cs,
    mem_rstb_o => mem_rstb,
    mem_wstb_o => mem_wstb
);

---------------------------------------------------------------------------
-- TTL
---------------------------------------------------------------------------
ttlin_inst : entity work.ttlin_top
port map (
    clk_i => FCLK_CLK0,
    reset_i => FCLK_RESET0,
    mem_addr_i => mem_addr,
    mem_cs_i => mem_cs(TTLIN_CS),
    mem_wstb_i => mem_wstb,
    mem_rstb_i => mem_rstb,
    mem_dat_i => mem_odat,
    pad_i => ttlin_pad_i,
    val_o => ttlin_val
);

ttlout_inst : entity work.ttlout_top
port map (
    clk_i => FCLK_CLK0,
    reset_i => FCLK_RESET0,
    mem_addr_i => mem_addr,
    mem_cs_i => mem_cs(TTLOUT_CS),
    mem_wstb_i => mem_wstb,
    mem_rstb_i => mem_rstb,
    mem_dat_i => mem_odat,
    sysbus_i => sysbus,
    pad_o => ttlout_val
);

ttlout_pad_o <= ttlout_val;

---------------------------------------------------------------------------
-- LVDS
---------------------------------------------------------------------------
lvdsin_inst : entity work.lvdsin_top
port map (
    clk_i => FCLK_CLK0,
    pad_i => lvdsin_pad_i,
    val_o => lvdsin_val
);

lvdsout_inst : entity work.lvdsout_top
port map (
    clk_i => FCLK_CLK0,
    reset_i => FCLK_RESET0,
    mem_addr_i => mem_addr,
    mem_cs_i => mem_cs(LVDSOUT_CS),
    mem_wstb_i => mem_wstb,
    mem_rstb_i => mem_rstb,
    mem_dat_i => mem_odat,
    sysbus_i => sysbus,
    pad_o => lvdsout_pad_o
);

---------------------------------------------------------------------------
-- 5-Input LUT
---------------------------------------------------------------------------
lut_inst : entity work.lut_top
port map (
    clk_i => FCLK_CLK0,
    reset_i => FCLK_RESET0,
    mem_addr_i => mem_addr,
    mem_cs_i => mem_cs(LUT_CS),
    mem_wstb_i => mem_wstb,
    mem_rstb_i => mem_rstb,
    mem_dat_i => mem_odat,
    sysbus_i => sysbus,
    out_o => lut_val
);

---------------------------------------------------------------------------
-- SRGATE
---------------------------------------------------------------------------
srgate_inst : entity work.srgate_top
port map (
    clk_i => FCLK_CLK0,
    reset_i => FCLK_RESET0,
    mem_addr_i => mem_addr,
    mem_cs_i => mem_cs(SRGATE_CS),
    mem_wstb_i => mem_wstb,
    mem_rstb_i => mem_rstb,
    mem_dat_i => mem_odat,
    sysbus_i => sysbus,
    out_o => srgate_out
);

---------------------------------------------------------------------------
-- DIVIDER
---------------------------------------------------------------------------
div_inst : entity work.div_top
port map (
    clk_i => FCLK_CLK0,
    reset_i => FCLK_RESET0,
    mem_addr_i => mem_addr,
    mem_cs_i => mem_cs(DIV_CS),
    mem_wstb_i => mem_wstb,
    mem_rstb_i => mem_rstb,
    mem_dat_i => mem_odat,
    mem_dat_o => mem_read_data(DIV_CS),
    sysbus_i => sysbus,
    outd_o => div_outd,
    outn_o => div_outn
);

---------------------------------------------------------------------------
-- PULSE GENERATOR
---------------------------------------------------------------------------
pulse_inst : entity work.pulse_top
port map (
    clk_i => FCLK_CLK0,
    reset_i => FCLK_RESET0,
    mem_addr_i => mem_addr,
    mem_cs_i => mem_cs(PULSE_CS),
    mem_wstb_i => mem_wstb,
    mem_dat_i => mem_odat,
    mem_dat_o => mem_read_data(PULSE_CS),
    sysbus_i => sysbus,
    out_o => pulse_out,
    perr_o => pulse_perr
);

---------------------------------------------------------------------------
-- SEQEUENCER
---------------------------------------------------------------------------
seq_inst : entity work.sequencer_top
port map (
    clk_i => FCLK_CLK0,
    reset_i => FCLK_RESET0,
    mem_addr_i => mem_addr,
    mem_cs_i => mem_cs(SEQ_CS),
    mem_wstb_i => mem_wstb,
    mem_dat_i => mem_odat,
    mem_dat_o => mem_read_data(SEQ_CS),
    sysbus_i => sysbus,
    outa_o => seq_outa,
    outb_o => seq_outb,
    outc_o => seq_outc,
    outd_o => seq_outd,
    oute_o => seq_oute,
    outf_o => seq_outf,
    active_o => seq_active
);

---------------------------------------------------------------------------
-- INENC (Encoder Inputs)
---------------------------------------------------------------------------
inenc_inst : entity work.inenc_top
port map (
    clk_i => FCLK_CLK0,
    reset_i => FCLK_RESET0,
    mem_addr_i => mem_addr,
    mem_cs_i => mem_cs(INENC_CS),
    mem_wstb_i => mem_wstb,
    mem_dat_i => mem_odat,
    mem_dat_o => mem_read_data(INENC_CS),
    A_IN => A_IN,
    B_IN => B_IN,
    Z_IN => Z_IN,
    CLK_OUT => CLK_OUT,
    DATA_IN => DATA_IN,
    CLK_IN => CLK_IN,
    CONN_OUT => inenc_conn,
    DCARD_MODE => DCARD_MODE,
    PROTOCOL => INPROT,
    posn_o => inenc_val,
    posn_upper_o => inenc_val_upper
);

---------------------------------------------------------------------------
-- QDEC
---------------------------------------------------------------------------
qdec_inst : entity work.qdec_top
port map (
    clk_i => FCLK_CLK0,
    reset_i => FCLK_RESET0,
    mem_addr_i => mem_addr,
    mem_cs_i => mem_cs(QDEC_CS),
    mem_wstb_i => mem_wstb,
    mem_dat_i => mem_odat,
    mem_dat_o => mem_read_data(QDEC_CS),
    sysbus_i => sysbus,
    out_o => qdec_out
);

---------------------------------------------------------------------------
-- OUTENC (Encoder Inputs)
---------------------------------------------------------------------------
outenc_inst : entity work.outenc_top
port map (
    clk_i => FCLK_CLK0,
    reset_i => FCLK_RESET0,
    mem_addr_i => mem_addr,
    mem_cs_i => mem_cs(OUTENC_CS),
    mem_wstb_i => mem_wstb,
    mem_rstb_i => mem_rstb,
    mem_dat_i => mem_odat,
    mem_dat_o => mem_read_data(OUTENC_CS),
    A_OUT => A_OUT,
    B_OUT => B_OUT,
    Z_OUT => Z_OUT,
    CLK_IN => CLK_IN,
    DATA_OUT => DATA_OUT,
    CONN_OUT => outenc_conn,
    sysbus_i => sysbus,
    posbus_i => posbus,
    PROTOCOL => OUTPROT
);

---------------------------------------------------------------------------
-- OUTENC (Encoder Inputs)
---------------------------------------------------------------------------
posenc_inst : entity work.posenc_top
port map (
    clk_i => FCLK_CLK0,
    reset_i => FCLK_RESET0,
    mem_addr_i => mem_addr,
    mem_cs_i => mem_cs(POSENC_CS),
    mem_wstb_i => mem_wstb,
    mem_rstb_i => mem_rstb,
    mem_dat_i => mem_odat,
    mem_dat_o => mem_read_data(POSENC_CS),
    a_o => posenc_a,
    b_o => posenc_b,
    sysbus_i => sysbus,
    posbus_i => posbus
);

---------------------------------------------------------------------------
-- COUNTER/TIMER
---------------------------------------------------------------------------
counter_inst : entity work.counter_top
port map (
    clk_i => FCLK_CLK0,
    reset_i => FCLK_RESET0,
    mem_addr_i => mem_addr,
    mem_cs_i => mem_cs(COUNTER_CS),
    mem_wstb_i => mem_wstb,
    mem_rstb_i => mem_rstb,
    mem_dat_i => mem_odat,
    mem_dat_o => mem_read_data(COUNTER_CS),
    sysbus_i => sysbus,
    carry_o => counter_carry,
    out_o => counter_out
);

---------------------------------------------------------------------------
-- ADDER
---------------------------------------------------------------------------
adder_inst : entity work.adder_top
port map (
    clk_i => FCLK_CLK0,
    reset_i => FCLK_RESET0,
    mem_addr_i => mem_addr,
    mem_cs_i => mem_cs(ADDER_CS),
    mem_wstb_i => mem_wstb,
    mem_rstb_i => mem_rstb,
    mem_dat_i => mem_odat,
    posbus_i => posbus,
    out_o => adder_out
);

---------------------------------------------------------------------------
-- POSITION COMPARE
---------------------------------------------------------------------------
pcomp_inst : entity work.pcomp_top
port map (
    clk_i => FCLK_CLK0,
    reset_i => FCLK_RESET0,
    mem_addr_i => mem_addr,
    mem_cs_i => mem_cs(PCOMP_CS),
    mem_wstb_i => mem_wstb,
    mem_rstb_i => mem_rstb,
    mem_dat_i => mem_odat,
    mem_dat_o => mem_read_data(PCOMP_CS),
    dma_req_o => rdma_req(5 downto 2),
    dma_ack_i => rdma_ack(5 downto 2),
    dma_done_i => rdma_done,
    dma_addr_o => rdma_addr(5 downto 2),
    dma_len_o => rdma_len(5 downto 2),
    dma_data_i => rdma_data,
    dma_valid_i => rdma_valid(5 downto 2),
    sysbus_i => sysbus,
    posbus_i => posbus,
    act_o => pcomp_active,
    out_o => pcomp_out
);

---------------------------------------------------------------------------
-- POSITION CAPTURE
---------------------------------------------------------------------------
pcap_inst : entity work.pcap_top
port map (
    clk_i => FCLK_CLK0,
    reset_i => FCLK_RESET0,
    m_axi_awaddr => S_AXI_HP0_awaddr,
    m_axi_awburst => S_AXI_HP0_awburst,
    m_axi_awcache => S_AXI_HP0_awcache,
    m_axi_awid => S_AXI_HP0_awid,
    m_axi_awlen => S_AXI_HP0_awlen,
    m_axi_awlock => S_AXI_HP0_awlock,
    m_axi_awprot => S_AXI_HP0_awprot,
    m_axi_awqos => S_AXI_HP0_awqos,
    m_axi_awready => S_AXI_HP0_awready,
    m_axi_awregion => S_AXI_HP0_awregion,
    m_axi_awsize => S_AXI_HP0_awsize,
    m_axi_awvalid => S_AXI_HP0_awvalid,
    m_axi_bid => S_AXI_HP0_bid,
    m_axi_bready => S_AXI_HP0_bready,
    m_axi_bresp => S_AXI_HP0_bresp,
    m_axi_bvalid => S_AXI_HP0_bvalid,
    m_axi_wdata => S_AXI_HP0_wdata,
    m_axi_wlast => S_AXI_HP0_wlast,
    m_axi_wready => S_AXI_HP0_wready,
    m_axi_wstrb => S_AXI_HP0_wstrb,
    m_axi_wvalid => S_AXI_HP0_wvalid,
    mem_addr_i => mem_addr,
    mem_cs_i => mem_cs,
    mem_wstb_i => mem_wstb,
    mem_dat_i => mem_odat,
    mem_dat_0_o => mem_read_data(PCAP_CS),
    mem_dat_1_o => mem_read_data(DRV_CS),
    sysbus_i => sysbus,
    posbus_i => posbus,
    extbus_i => extbus,
    pcap_actv_o => pcap_act(0),
    pcap_irq_o => IRQ_F2P(0)
);

---------------------------------------------------------------------------
-- POSITION GENERATION
---------------------------------------------------------------------------
pgen_inst : entity work.pgen_top
port map (
    clk_i => FCLK_CLK0,
    reset_i => FCLK_RESET0,
    mem_addr_i => mem_addr,
    mem_cs_i => mem_cs(PGEN_CS),
    mem_wstb_i => mem_wstb,
    mem_dat_i => mem_odat,
    mem_dat_o => mem_read_data(PGEN_CS),
    dma_req_o => rdma_req(1 downto 0),
    dma_ack_i => rdma_ack(1 downto 0),
    dma_done_i => rdma_done,
    dma_addr_o => rdma_addr(1 downto 0),
    dma_len_o => rdma_len(1 downto 0),
    dma_data_i => rdma_data,
    dma_valid_i => rdma_valid(1 downto 0),
    sysbus_i => sysbus,
    out_o => pgen_out
);


---------------------------------------------------------------------------
-- TABLE DMA ENGINE
---------------------------------------------------------------------------
table_engine : entity work.table_read_engine
port map (
    clk_i => FCLK_CLK0,
    reset_i => FCLK_RESET0,
    -- Zynq HP1 Bus
    m_axi_araddr => S_AXI_HP1_araddr,
    m_axi_arburst => S_AXI_HP1_arburst,
    m_axi_arcache => S_AXI_HP1_arcache,
    m_axi_arid => S_AXI_HP1_arid,
    m_axi_arlen => S_AXI_HP1_arlen,
    m_axi_arlock => S_AXI_HP1_arlock,
    m_axi_arprot => S_AXI_HP1_arprot,
    m_axi_arqos => S_AXI_HP1_arqos,
    m_axi_arready => S_AXI_HP1_arready,
    m_axi_arregion => S_AXI_HP1_arregion,
    m_axi_arsize => S_AXI_HP1_arsize,
    m_axi_arvalid => S_AXI_HP1_arvalid,
    m_axi_rdata => S_AXI_HP1_rdata,
    m_axi_rid => S_AXI_HP1_rid,
    m_axi_rlast => S_AXI_HP1_rlast,
    m_axi_rready => S_AXI_HP1_rready,
    m_axi_rresp => S_AXI_HP1_rresp,
    m_axi_rvalid => S_AXI_HP1_rvalid,
    -- Slaves' DMA Engine Interface
    dma_req_i => rdma_req,
    dma_ack_o => rdma_ack,
    dma_done_o => rdma_done,
    dma_addr_i => rdma_addr,
    dma_len_i => rdma_len,
    dma_data_o => rdma_data,
    dma_valid_o => rdma_valid
);

---------------------------------------------------------------------------
-- REG (System, Position Bus and Special Register Readbacks)
---------------------------------------------------------------------------
reg_inst : entity work.reg_top
port map (
    clk_i => FCLK_CLK0,
    reset_i => FCLK_RESET0,
    mem_addr_i => mem_addr,
    mem_cs_i => mem_cs(REG_CS),
    mem_wstb_i => mem_wstb,
    mem_rstb_i => mem_rstb,
    mem_dat_i => mem_odat,
    mem_dat_o => mem_read_data(REG_CS),
    sysbus_i => sysbus,
    posbus_i => posbus,
    SLOW_FPGA_VERSION => SLOW_FPGA_VERSION,
    slowctrl_busy_i => slowctrl_busy
);

---------------------------------------------------------------------------
-- CLOCKS
---------------------------------------------------------------------------
clocks_inst : entity work.clocks_top
port map (
    clk_i => FCLK_CLK0,
    reset_i => FCLK_RESET0,
    mem_addr_i => mem_addr,
    mem_cs_i => mem_cs(CLOCKS_CS),
    mem_wstb_i => mem_wstb,
    mem_rstb_i => mem_rstb,
    mem_dat_i => mem_odat,
    mem_dat_o => mem_read_data(CLOCKS_CS),
    clocks_a_o => clocks_a(0),
    clocks_b_o => clocks_b(0),
    clocks_c_o => clocks_c(0),
    clocks_d_o => clocks_d(0)
);

---------------------------------------------------------------------------
-- BITS
---------------------------------------------------------------------------
bits_inst : entity work.bits_top
port map (
    clk_i => FCLK_CLK0,
    reset_i => FCLK_RESET0,
    mem_addr_i => mem_addr,
    mem_cs_i => mem_cs(BITS_CS),
    mem_wstb_i => mem_wstb,
    mem_rstb_i => mem_rstb,
    mem_dat_i => mem_odat,
    zero_o => bits_zero(0),
    one_o => bits_one(0),
    bits_a_o => bits_a(0),
    bits_b_o => bits_b(0),
    bits_c_o => bits_c(0),
    bits_d_o => bits_d(0)
);

---------------------------------------------------------------------------
-- SLOW CONTROLLER FPGA
---------------------------------------------------------------------------
slow_registers_inst : entity work.slow_registers
port map (
    clk_i => FCLK_CLK0,
    reset_i => FCLK_RESET0,
    mem_addr_i => mem_addr,
    mem_cs_i => mem_cs,
    mem_wstb_i => mem_wstb,
    mem_dat_i => mem_odat,
    slow_tlp_o => slow_tlp_registers
);

slowctrl_inst : entity work.slowctrl_top
port map (
    clk_i => FCLK_CLK0,
    reset_i => FCLK_RESET0,
    mem_addr_i => mem_addr,
    mem_cs_i => mem_cs(SLOW_CS),
    mem_wstb_i => mem_wstb,
    mem_dat_i => mem_odat,
    mem_dat_o => mem_read_data(SLOW_CS),
    spi_sclk_o => spi_sclk_o,
    spi_dat_o => spi_dat_o,
    spi_sclk_i => spi_sclk_i,
    spi_dat_i => spi_dat_i,
    registers_tlp_i => slow_tlp_registers,
    leds_tlp_i => slow_tlp_leds,
    busy_o => slowctrl_busy,
    SLOW_FPGA_VERSION => SLOW_FPGA_VERSION,

    DCARD_MODE => open



);

---------------------------------------------------------------------------
-- BUS ASSIGNMENTS
---------------------------------------------------------------------------
busses_inst : entity work.panda_busses
port map (
    TTLIN_VAL => ttlin_val,
    LVDSIN_VAL => lvdsin_val,
    LUT_OUT => lut_val,
    SRGATE_OUT => srgate_out,
    DIV_OUTD => div_outd,
    DIV_OUTN => div_outn,
    PULSE_OUT => pulse_out,
    PULSE_PERR => pulse_perr,
    SEQ_OUTA => seq_outa,
    SEQ_OUTB => seq_outb,
    SEQ_OUTC => seq_outc,
    SEQ_OUTD => seq_outd,
    SEQ_OUTE => seq_oute,
    SEQ_OUTF => seq_outf,
    SEQ_ACTIVE => seq_active,
    INENC_A => A_IN,
    INENC_B => B_IN,
    INENC_Z => Z_IN,
    INENC_CONN => inenc_conn,
    INENC_VAL => inenc_val,
    QDEC_OUT => qdec_out,
    POSENC_A => posenc_a,
    POSENC_B => posenc_b,
    ADDER_OUT => adder_out,
    COUNTER_CARRY => counter_carry,
    COUNTER_OUT => counter_out,
    PGEN_OUT => pgen_out,
    PCOMP_ACTIVE => pcomp_active,
    PCOMP_OUT => pcomp_out,
    ADC_OUT => (others => (others => '0')),
    PCAP_ACTIVE => pcap_act,
    -- System Bus Signals
    BITS_OUTA => bits_a,
    BITS_OUTB => bits_b,
    BITS_OUTC => bits_c,
    BITS_OUTD => bits_d,
    BITS_ZERO => bits_zero,
    BITS_ONE => bits_one,
    -- CLOCKS Block
    CLOCKS_OUTA => clocks_a,
    CLOCKS_OUTB => clocks_b,
    CLOCKS_OUTC => clocks_c,
    CLOCKS_OUTD => clocks_d,
    -- Position Bus Signals
    POSITIONS_ZERO => (others => (others => '0')),
    -- Bus Outputs
    bitbus_o => sysbus,
    posbus_o => posbus
);

---------------------------------------------------------------------------
-- SLOW FPGA Misc Communication (LED, Custom)
---------------------------------------------------------------------------
led_management_inst : entity work.led_management
port map (
    clk_i => FCLK_CLK0,
    reset_i => FCLK_RESET0,
    -- Block Input and Outputs
    ttlin_i => ttlin_val,
    ttlout_i => ttlout_val,
    outenc_conn_i => outenc_conn,
    slow_tlp_o => slow_tlp_leds
);

---------------------------------------------------------------------------
-- Extended Bus : Assignments
---------------------------------------------------------------------------
extbus(3 downto 0) <= inenc_val_upper;

---------------------------------------------------------------------------
-- On-Chip IOBIF Control for Daughter Card Interfacing
---------------------------------------------------------------------------
dcard_interface_inst : entity work.dcard_interface
port map (
    clk_i => FCLK_CLK0,
    reset_i => FCLK_RESET0,

    Am0_pad_io => Am0_pad_io,
    Bm0_pad_io => Bm0_pad_io,
    Zm0_pad_io => Zm0_pad_io,
    As0_pad_io => As0_pad_io,
    Bs0_pad_io => Bs0_pad_io,
    Zs0_pad_io => Zs0_pad_io,

    INPROT => INPROT,
    OUTPROT => OUTPROT,

    A_IN => A_IN,
    B_IN => B_IN,
    Z_IN => Z_IN,
    A_OUT => A_OUT,
    B_OUT => B_OUT,
    Z_OUT => Z_OUT,
    CLK_OUT => CLK_OUT,
    DATA_IN => DATA_IN,
    CLK_IN => CLK_IN,
    DATA_OUT => DATA_OUT
);


-- Direct interface to Daughter Card via FMC on the dev board.
enc0_ctrl_pad_o <= enc0_ctrl_pad;

DCARD_MODE(0) <= ZEROS(28) & enc0_ctrl_pad_i;
DCARD_MODE(1) <= ZEROS(32);
DCARD_MODE(2) <= ZEROS(32);
DCARD_MODE(3) <= ZEROS(32);

-- Integer conversion for address.
mem_addr_reg <= to_integer(unsigned(mem_addr));

--
-- Catch PROTOCOL write to INENC0 and OUTENC0 modules.
--
REG_WRITE : process(FCLK_CLK0)
begin
    if rising_edge(FCLK_CLK0) then
        if (FCLK_RESET0 = '1') then
            inenc_buf_ctrl <= (others => '0');
            outenc_buf_ctrl <= (others => '0');
        else
            -- DCard Input Channel Buffer Ctrl
            -- Inc : 0x03
            -- SSI : 0x0C
            -- BiSS : 0x0C
            -- Endat : 0x14
            case (INPROT(0)) is
                when "000" => -- INC
                    inenc_buf_ctrl <= "00" & X"3";
                when "001" => -- SSI
                    inenc_buf_ctrl <= "00" & X"C";
                when "010" => -- BiSS
                    inenc_buf_ctrl <= "00" & X"C";
                when "011" => -- EnDat
                    inenc_buf_ctrl <= "01" & X"4";
                when others =>
                    inenc_buf_ctrl <= (others => '0');
            end case;

            -- DCard Output Channel Buffer Ctrl
            -- Inc : 0x07
            -- SSI : 0x28
            -- BiSS : 0x28
            -- Endat : 0x10
            -- Pass : 0x07
            -- DCard Output Channel Buffer Ctrl
            case (OUTPROT(0)) is
                when "000" => -- INC
                    outenc_buf_ctrl <= "00" & X"7";
                when "001" => -- SSI
                    outenc_buf_ctrl <= "10" & X"8";
                when "010" => -- BiSS
                    outenc_buf_ctrl <= "10" & X"8";
                when "011" => -- EnDat
                    outenc_buf_ctrl <= "01" & X"0";
                when "100" => -- Pass
                    outenc_buf_ctrl <= "00" & X"7";
                when others =>
                    outenc_buf_ctrl <= (others => '0');
            end case;
        end if;
    end if;
end process;

-- Daughter Card Buffer Control Signals
enc0_ctrl_pad(1 downto 0) <= inenc_buf_ctrl(1 downto 0);
enc0_ctrl_pad(3 downto 2) <= outenc_buf_ctrl(1 downto 0);
enc0_ctrl_pad(4) <= inenc_buf_ctrl(2);
enc0_ctrl_pad(5) <= outenc_buf_ctrl(2);
enc0_ctrl_pad(7 downto 6) <= inenc_buf_ctrl(4 downto 3);
enc0_ctrl_pad(9 downto 8) <= outenc_buf_ctrl(4 downto 3);
enc0_ctrl_pad(10) <= inenc_buf_ctrl(5);
enc0_ctrl_pad(11) <= outenc_buf_ctrl(5);

--
-- >>>>>>>>>>>>> 1 BOARD - ENDS
--




end rtl;

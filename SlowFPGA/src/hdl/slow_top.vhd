--------------------------------------------------------------------------------
-- PandA Motion Project - 2016
-- Diamond Light Source, Oxford, UK
-- SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
-- Author : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
-- Description : Serial Interface core is used to handle communication between
-- Zynq and Slow Control FPGA.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;
use work.slow_defines.all;

library unisim;
use unisim.vcomponents.all;

entity slow_top is
port (
    -- 50MHz system clock
    clk50_i : in std_logic;
    -- Zynq Tx/Rx Serial Interface
    spi_sclk_i : in std_logic;
    spi_dat_i : in std_logic;
    spi_sclk_o : out std_logic;
    spi_dat_o : out std_logic;
    -- Encoder Daughter Card Control Interface
    dcard_ctrl1_io : inout std_logic_vector(15 downto 0);





    -- Front Panel Shift Register Interface
    shift_reg_sdata_o : out std_logic;
    shift_reg_sclk_o : out std_logic;
    shift_reg_latch_o : out std_logic;
    shift_reg_oe_n_o : out std_logic
);
end slow_top;

architecture rtl of slow_top is

component icon
port (
    CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0)
);
end component;

signal CONTROL0 : STD_LOGIC_VECTOR(35 DOWNTO 0);

component ila
port (
    CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CLK : IN STD_LOGIC;
    DATA : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    TRIG0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0)
);
end component;

signal DATA : STD_LOGIC_VECTOR(63 DOWNTO 0);
signal TRIG0 : STD_LOGIC_VECTOR(7 DOWNTO 0);

signal OUTENC_CONN : std_logic_vector(3 downto 0);
signal INENC_PROTOCOL : std3_array(3 downto 0);
signal OUTENC_PROTOCOL : std3_array(3 downto 0);
signal DCARD_MODE : std4_array(3 downto 0);

signal reset_n : std_logic;
signal reset : std_logic;

signal ttlin_term : std_logic_vector(5 downto 0);
signal ttl_leds : std_logic_vector(15 downto 0);
signal status_leds : std_logic_vector(3 downto 0);

begin

--
-- Startup Reset
--
reset_inst : SRL16
port map (
    Q => reset_n,
    A0 => '1',
    A1 => '1',
    A2 => '1',
    A3 => '1',
    CLK => clk50_i,
    D => '1'
);

reset <= not reset_n;

--
-- Data Send/Receive Engine to Zynq
--
zynq_interface_inst : entity work.zynq_interface
port map (
    clk_i => clk50_i,
    reset_i => reset,

    spi_sclk_i => spi_sclk_i,
    spi_dat_i => spi_dat_i,
    spi_sclk_o => spi_sclk_o,
    spi_dat_o => spi_dat_o,

    ttlin_term_o => ttlin_term,
    ttl_leds_o => ttl_leds,
    status_leds_o => status_leds,
    outenc_conn_o => OUTENC_CONN,

    INENC_PROTOCOL => INENC_PROTOCOL,
    OUTENC_PROTOCOL => OUTENC_PROTOCOL,
    DCARD_MODE => DCARD_MODE
);

--
-- Daughter Card Control Interface
--
dcard_ctrl_inst : entity work.dcard_ctrl
port map (
    clk_i => clk50_i,
    reset_i => reset,
    -- Encoder Daughter Card Control Interface
    dcard_ctrl1_io => dcard_ctrl1_io,

    dcard_ctrl2_io => open,
    dcard_ctrl3_io => open,
    dcard_ctrl4_io => open,





    -- Front Panel Shift Register Interface
    OUTENC_CONN => OUTENC_CONN,
    INENC_PROTOCOL => INENC_PROTOCOL,
    OUTENC_PROTOCOL => OUTENC_PROTOCOL,
    DCARD_MODE => DCARD_MODE
);

--
-- Front Panel Shift Register Interface
--
fpanel_if_inst : entity work.fpanel_if
port map (
    clk_i => clk50_i,
    reset_i => reset,

    ttlin_term_i => ttlin_term,
    ttl_leds_i => ttl_leds,
    status_leds_i => status_leds,

    shift_reg_sdata_o => shift_reg_sdata_o,
    shift_reg_sclk_o => shift_reg_sclk_o,
    shift_reg_latch_o => shift_reg_latch_o,
    shift_reg_oe_n_o => shift_reg_oe_n_o
);


--
-- Chipscope
--
icon_inst : icon
port map (
    CONTROL0 => CONTROL0
);

ila_inst : ila
port map (
    CONTROL => CONTROL0,
    CLK => clk50_i,
    DATA => DATA,
    TRIG0 => TRIG0
);

TRIG0(0) <= spi_sclk_i;
TRIG0(1) <= spi_dat_i;
TRIG0(7 downto 2) <= (others => '0');

DATA(0) <= spi_sclk_i;
DATA(1) <= spi_dat_i;
DATA(4 downto 2) <= INENC_PROTOCOL(0);
DATA(7 downto 5) <= OUTENC_PROTOCOL(0);
DATA(63 downto 8) <= (others => '0');

end rtl;

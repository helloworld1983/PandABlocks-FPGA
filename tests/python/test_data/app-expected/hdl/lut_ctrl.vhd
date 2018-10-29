library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.addr_defines.all;
use work.top_defines.all;

entity lut_ctrl is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    bit_bus_i           : in  sysbus_t;
    pos_bus_i           : in  posbus_t;
    -- Block Parameters
    INPA_from_bus       : out std_logic;
    INPB_from_bus       : out std_logic;
    INPC_from_bus       : out std_logic;
    INPD_from_bus       : out std_logic;
    INPE_from_bus       : out std_logic;
    A                   : out std_logic_vector(31 downto 0);
    A_wstb              : out std_logic;
    B                   : out std_logic_vector(31 downto 0);
    B_wstb              : out std_logic;
    C                   : out std_logic_vector(31 downto 0);
    C_wstb              : out std_logic;
    D                   : out std_logic_vector(31 downto 0);
    D_wstb              : out std_logic;
    E                   : out std_logic_vector(31 downto 0);
    E_wstb              : out std_logic;
    FUNC                : out std_logic_vector(31 downto 0);
    FUNC_wstb           : out std_logic;
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(BLK_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(BLK_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic
);
end lut_ctrl;

architecture rtl of lut_ctrl is

signal INPA      : std_logic_vector(31 downto 0);
signal INPA_wstb : std_logic;

signal INPA_dly      : std_logic_vector(31 downto 0);
signal INPA_dly_wstb : std_logic;

signal INPB      : std_logic_vector(31 downto 0);
signal INPB_wstb : std_logic;

signal INPB_dly      : std_logic_vector(31 downto 0);
signal INPB_dly_wstb : std_logic;

signal INPC      : std_logic_vector(31 downto 0);
signal INPC_wstb : std_logic;

signal INPC_dly      : std_logic_vector(31 downto 0);
signal INPC_dly_wstb : std_logic;

signal INPD      : std_logic_vector(31 downto 0);
signal INPD_wstb : std_logic;

signal INPD_dly      : std_logic_vector(31 downto 0);
signal INPD_dly_wstb : std_logic;

signal INPE      : std_logic_vector(31 downto 0);
signal INPE_wstb : std_logic;

signal INPE_dly      : std_logic_vector(31 downto 0);
signal INPE_dly_wstb : std_logic;


-- Register interface common

signal read_addr        : natural range 0 to (2**read_address_i'length - 1);
signal write_addr       : natural range 0 to (2**write_address_i'length - 1);

begin

    -- Sub-module address decoding
    read_addr <= to_integer(unsigned(read_address_i));
    write_addr <= to_integer(unsigned(write_address_i));

    -- Control System Register Interface
    REG_WRITE : process(clk_i)
    begin
        if rising_edge(clk_i) then
            -- Zero all the write strobe arrays, we set them below
            INPA_wstb <= '0';
            INPA_dly_wstb <= '0';
            INPB_wstb <= '0';
            INPB_dly_wstb <= '0';
            INPC_wstb <= '0';
            INPC_dly_wstb <= '0';
            INPD_wstb <= '0';
            INPD_dly_wstb <= '0';
            INPE_wstb <= '0';
            INPE_dly_wstb <= '0';
            A_wstb <= '0';
            B_wstb <= '0';
            C_wstb <= '0';
            D_wstb <= '0';
            E_wstb <= '0';
            FUNC_wstb <= '0';
            if (write_strobe_i = '1') then
                -- Set the specific write strobe that has come in
                case write_addr is
                    when LUT_INPA_addr =>
                        INPA <= write_data_i;
                        INPA_wstb <= '1';
                    when LUT_INPA_dly_addr =>
                        INPA_dly <= write_data_i;
                        INPA_dly_wstb <= '1';
                    when LUT_INPB_addr =>
                        INPB <= write_data_i;
                        INPB_wstb <= '1';
                    when LUT_INPB_dly_addr =>
                        INPB_dly <= write_data_i;
                        INPB_dly_wstb <= '1';
                    when LUT_INPC_addr =>
                        INPC <= write_data_i;
                        INPC_wstb <= '1';
                    when LUT_INPC_dly_addr =>
                        INPC_dly <= write_data_i;
                        INPC_dly_wstb <= '1';
                    when LUT_INPD_addr =>
                        INPD <= write_data_i;
                        INPD_wstb <= '1';
                    when LUT_INPD_dly_addr =>
                        INPD_dly <= write_data_i;
                        INPD_dly_wstb <= '1';
                    when LUT_INPE_addr =>
                        INPE <= write_data_i;
                        INPE_wstb <= '1';
                    when LUT_INPE_dly_addr =>
                        INPE_dly <= write_data_i;
                        INPE_dly_wstb <= '1';
                    when LUT_A_addr =>
                        A <= write_data_i;
                        A_wstb <= '1';
                    when LUT_B_addr =>
                        B <= write_data_i;
                        B_wstb <= '1';
                    when LUT_C_addr =>
                        C <= write_data_i;
                        C_wstb <= '1';
                    when LUT_D_addr =>
                        D <= write_data_i;
                        D_wstb <= '1';
                    when LUT_E_addr =>
                        E <= write_data_i;
                        E_wstb <= '1';
                    when LUT_FUNC_addr =>
                        FUNC <= write_data_i;
                        FUNC_wstb <= '1';
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    --
    -- Status Register Read     // NOT dealt with yet!      -- Need MUX for read_data(I)
                                                            -- find examples that actually have register reads...
                                                            -- Current implementation taken from old panda_block_ctrl_template
    --
    REG_READ : process(clk_i)
    begin
        if rising_edge(clk_i) then
            case (read_addr) is
                when others =>
                    read_data_o <= (others => '0');
            end case;
        end if;
    end process;

    --
    -- Instantiate Delay Blocks for Bit and Position Bus Fields
    --
    bitmux_INPA : entity work.bitmux
    port map (
        clk_i       => clk_i,
        sysbus_i    => bit_bus_i,
        bit_o       => INPA_from_bus,
        bitmux_sel  => INPA,
        bit_dly     => INPA_DLY
    );

    bitmux_INPB : entity work.bitmux
    port map (
        clk_i       => clk_i,
        sysbus_i    => bit_bus_i,
        bit_o       => INPB_from_bus,
        bitmux_sel  => INPB,
        bit_dly     => INPB_DLY
    );

    bitmux_INPC : entity work.bitmux
    port map (
        clk_i       => clk_i,
        sysbus_i    => bit_bus_i,
        bit_o       => INPC_from_bus,
        bitmux_sel  => INPC,
        bit_dly     => INPC_DLY
    );

    bitmux_INPD : entity work.bitmux
    port map (
        clk_i       => clk_i,
        sysbus_i    => bit_bus_i,
        bit_o       => INPD_from_bus,
        bitmux_sel  => INPD,
        bit_dly     => INPD_DLY
    );

    bitmux_INPE : entity work.bitmux
    port map (
        clk_i       => clk_i,
        sysbus_i    => bit_bus_i,
        bit_o       => INPE_from_bus,
        bitmux_sel  => INPE,
        bit_dly     => INPE_DLY
    );


end rtl;
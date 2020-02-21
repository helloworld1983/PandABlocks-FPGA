--------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor: Xilinx
-- \   \   \/     Version : 3.5
--  \   \         Application : 7 Series FPGAs Transceivers Wizard
--  /   /         Filename : amcgtx_common_reset.vhd
-- /___/   /\
-- \   \  /  \
--  \___\/\___\
--
--
--  Description :     This module performs TX reset and initialization.
--
--
--
-- Module amcgtx_common_reset
-- Generated by Xilinx 7 Series FPGAs Transceivers Wizard
--
--
-- (c) Copyright 2010-2012 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.


--*****************************************************************************
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use ieee.std_logic_textio.all;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity amcgtx_common_reset is
generic
(
      STABLE_CLOCK_PERIOD      : integer := 8        -- Period of the stable clock driving this state-machine, unit is [ns]
   );
port
   (
      STABLE_CLOCK             : in std_logic;             --Stable Clock, either a stable clock from the PCB
      SOFT_RESET               : in std_logic;               --User Reset, can be pulled any time
      COMMON_RESET             : out std_logic:= '0'  --Reset QPLL
   );
end amcgtx_common_reset;

architecture RTL of amcgtx_common_reset is


  constant STARTUP_DELAY        : integer := 500;--AR43482: Transceiver needs to wait for 500 ns after configuration
  constant WAIT_CYCLES          : integer := STARTUP_DELAY / STABLE_CLOCK_PERIOD; -- Number of Clock-Cycles to wait after configuration
  constant WAIT_MAX             : integer := WAIT_CYCLES + 10;                    -- 500 ns plus some additional margin


  signal init_wait_count  : std_logic_vector(7 downto 0) :=(others => '0');
  signal init_wait_done   : std_logic :='0';
  signal common_reset_asserted   : std_logic :='0';
  signal common_reset_i   : std_logic ;

  type rst_type is(
    INIT, ASSERT_COMMON_RESET);

  signal state : rst_type := INIT;

begin
  process(STABLE_CLOCK)
  begin
    if rising_edge(STABLE_CLOCK) then
      -- The counter starts running when configuration has finished and
      -- the clock is stable. When its maximum count-value has been reached,
      -- the 500 ns from Answer Record 43482 have been passed.
      if init_wait_count = WAIT_MAX then
        init_wait_done <= '1';
      else
        init_wait_count <= init_wait_count + 1;
      end if;
    end if;
  end process;

  process(STABLE_CLOCK)
  begin
    if rising_edge(STABLE_CLOCK) then
      if(SOFT_RESET = '1') then
        state                <= INIT;
        common_reset_asserted   <= '0';
        COMMON_RESET   <= '0';
      else

        case state is
          when INIT =>
            if init_wait_done = '1' then
              state        <= ASSERT_COMMON_RESET;
            end if;

          when ASSERT_COMMON_RESET =>
             if common_reset_asserted = '0' then
                COMMON_RESET          <= '1';
                common_reset_asserted  <= '1';
              else
                COMMON_RESET          <= '0';
              end if;
           when OTHERS =>
            state   <= INIT;
         end case;
       end if;
    end if;
  end process;


end RTL;

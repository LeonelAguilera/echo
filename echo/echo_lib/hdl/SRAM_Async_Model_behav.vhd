--
-- VHDL Architecture echo_lib.SRAM_Async_Model.behav
--
-- Created:
--          by - antmo328.student-liu.se (muxen2-112.ad.liu.se)
--          at - 12:55:13 10/10/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SRAM_Async_Model is
  port(
    ADDR  : in  std_logic_vector(19 downto 0);  -- 19-bit address = 512K words
    DQ    : inout std_logic_vector(15 downto 0);
    CE_N  : in  std_logic;
    OE_N  : in  std_logic;
    WE_N  : in  std_logic;
    UB_N  : in  std_logic;
    LB_N  : in  std_logic
  );
end entity;

architecture behav of SRAM_Async_Model is
  type ram_t is array (0 to 2**20 - 1) of std_logic_vector(15 downto 0);
  signal mem    : ram_t := (others => (others => '0'));
  signal dq_out : std_logic_vector(15 downto 0);
begin
  --------------------------------------------------------------------
  -- WRITE  (CE_N='0' and WE_N='0')
  --------------------------------------------------------------------
  process(CE_N, WE_N, ADDR, DQ, UB_N, LB_N)
    variable w : std_logic_vector(15 downto 0);
  begin
    if CE_N = '0' and WE_N = '0' then
      w := mem(to_integer(unsigned(ADDR)));
      if LB_N = '0' then
        w(7 downto 0) := DQ(7 downto 0);
      end if;
      if UB_N = '0' then
        w(15 downto 8) := DQ(15 downto 8);
      end if;
      mem(to_integer(unsigned(ADDR))) <= w;
    end if;
  end process;

  --------------------------------------------------------------------
  -- READ (OE_N='0' and WE_N='1' and CE_N='0')
  --------------------------------------------------------------------
  dq_out <= mem(to_integer(unsigned(ADDR)))
            when (CE_N='0' and OE_N='0' and WE_N='1')
            else (others => 'Z');

  DQ <= dq_out after 10 ns;  -- tACC modelling
end architecture;

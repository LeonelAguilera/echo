--
-- VHDL Architecture echo_lib.sram16_asyn.behav
--
-- Created:
--          by - antmo328.student-liu.se (muxen2-111.ad.liu.se)
--          at - 18:58:46 10/20/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
-- sram16_asyn.vhd: sehr simples Verhaltensmodell 16-bit Asynch.-SRAM
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sram16_asyn is
  generic (
    G_ADDR_WIDTH : natural := 20
  );
  port (
    A       : in  std_logic_vector(G_ADDR_WIDTH-1 downto 0);
    DQ      : inout std_logic_vector(15 downto 0);
    CE_N    : in  std_logic;
    OE_N    : in  std_logic;
    WE_N    : in  std_logic;
    UB_N    : in  std_logic;
    LB_N    : in  std_logic
  );
end entity;

architecture behav of sram16_asyn is
  subtype word_t is std_logic_vector(15 downto 0);
  type mem_t is array (0 to (2**G_ADDR_WIDTH)-1) of word_t;
  signal mem : mem_t := (others => (others => '0'));

  -- interner Treiber
  signal dq_drv : std_logic_vector(15 downto 0);
  signal dq_ena : std_logic;
begin
  -- Lese-Treiber: aktiv wenn CE#=0 und OE#=0 und WE#=1
  dq_ena <= '1' when (CE_N='0' and OE_N='0' and WE_N='1') else '0';

  -- Nur aktivierte Byte-Lanes treiben
  dq_drv(7 downto 0)  <= mem(to_integer(unsigned(A)))(7 downto 0)  when (dq_ena='1' and LB_N='0') else (others => 'Z');
  dq_drv(15 downto 8) <= mem(to_integer(unsigned(A)))(15 downto 8) when (dq_ena='1' and UB_N='0') else (others => 'Z');

  -- Zusammenführen beider Teiltreiber
  DQ <= dq_drv when dq_ena='1' else (others => 'Z');

  -- Schreiben (asynchron modelliert ? auf Flanken von WE#)
  proc_write: process(CE_N, WE_N, A, DQ, UB_N, LB_N)
    variable w : word_t;
  begin
    if (CE_N='0' and WE_N='0') then
      w := mem(to_integer(unsigned(A)));
      if LB_N='0' then
        w(7 downto 0)  := DQ(7 downto 0);
      end if;
      if UB_N='0' then
        w(15 downto 8) := DQ(15 downto 8);
      end if;
      mem(to_integer(unsigned(A))) <= w;
    end if;
  end process;

end architecture;



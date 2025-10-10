--
-- VHDL Architecture echo_lib.SRAM_Async_Model.behav
--
-- Created:
--          by - antmo328.student-liu.se (muxen2-112.ad.liu.se)
--          at - 12:55:13 10/10/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

ENTITY SRAM_Async_Model IS
  generic(
    G_ADDR_WIDTH : natural := 19;   -- 19 ? 512K Wörter
    G_DATA_WIDTH : natural := 16    -- 16 Bit Daten
  );
  port(
    ADDR  : in    std_logic_vector(G_ADDR_WIDTH-1 downto 0);
    DQ    : inout std_logic_vector(G_DATA_WIDTH-1 downto 0);
    CE_N  : in    std_logic;  -- Chip Enable (aktiv Low)
    OE_N  : in    std_logic;  -- Output Enable (aktiv Low)
    WE_N  : in    std_logic;  -- Write Enable (aktiv Low)
    UB_N  : in    std_logic;  -- Upper Byte Enable (aktiv Low)
    LB_N  : in    std_logic   -- Lower Byte Enable (aktiv Low)
  );
END ENTITY;

--
ARCHITECTURE behav OF SRAM_Async_Model IS
BEGIN
  -----------------------------------------------------------------------------
  -- WRITE-Zugriff: bei aktivem CE_N='0' und WE_N='0'
  -----------------------------------------------------------------------------
  process(CE_N, WE_N, ADDR, DQ, UB_N, LB_N)
    variable w : std_logic_vector(G_DATA_WIDTH-1 downto 0);
  begin
    if CE_N = '0' and WE_N = '0' then
      -- aktuelles Wort lesen (Read-Modify-Write für Byte-Enables)
      w := mem(to_integer(unsigned(ADDR)));

      -- Byte-Enables prüfen
      if LB_N = '0' then
        w(7 downto 0) := DQ(7 downto 0);
      end if;
      if UB_N = '0' then
        w(15 downto 8) := DQ(15 downto 8);
      end if;

      mem(to_integer(unsigned(ADDR))) <= w;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- READ-Zugriff: bei OE_N='0' und WE_N='1' (und CE_N='0')
  -- Ausgabe mit kleiner Verzögerung (z. B. tACC = 10 ns)
  -----------------------------------------------------------------------------
  dq_out <= mem(to_integer(unsigned(ADDR))) 
             when (CE_N='0' and OE_N='0' and WE_N='1')
             else (others => 'Z');

  DQ <= dq_out after 10 ns;
  
END ARCHITECTURE behav;


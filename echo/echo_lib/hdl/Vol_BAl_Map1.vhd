--
-- VHDL Architecture echo_lib.Vol_BAl.Map1
--
-- Created:
--          by - alfth698.student-liu.se (muxen2-116.ad.liu.se)
--          at - 16:27:20 10/16/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Vol_BAl IS
   PORT( 
      DAC_en       : IN     std_logic;
      PLL          : IN     std_logic;
      Reset        : IN     std_logic;
      bal_count    : IN     unsigned (3 DOWNTO 0);
      lrsel        : IN     std_logic;
      vol_count    : IN     unsigned (3 DOWNTO 0);
      DAC          : OUT    signed (15 DOWNTO 0);
      overflow     : OUT    std_logic;
      signal_ready : OUT    std_logic
   );

-- Declarations

END Vol_BAl ;

--
ARCHITECTURE Map1 OF Vol_BAl IS
BEGIN
END ARCHITECTURE Map1;


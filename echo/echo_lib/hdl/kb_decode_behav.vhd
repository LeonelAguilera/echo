--
-- VHDL Architecture echo_lib.kb_decode.behav
--
-- Created:
--          by - antmo328.student-liu.se (muxen2-112.ad.liu.se)
--          at - 23:11:10 10/12/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY kb_decode IS
   PORT(
      clk       : IN     std_logic;
      RESET_N   : IN     std_logic; 
      KB_SCAN_VALID : IN     std_logic;
      KB_SCAN_CODE  : IN     std_logic_vector (7 DOWNTO 0);
      KB_DECODE     : OUT    std_logic_vector (24 DOWNTO 0)
   );

-- Declarations

END kb_decode ;

--
ARCHITECTURE behav OF kb_decode IS
BEGIN
END ARCHITECTURE behav;


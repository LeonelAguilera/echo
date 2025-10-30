--
-- VHDL Architecture echo_lib.color_forcer.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-116.ad.liu.se)
--          at - 12:15:21 10/30/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE IEEE.MATH_REAL.ALL;
LIBRARY echo_lib;
USE echo_lib.color_t.ALL;

ENTITY color_forcer IS
   PORT( 
      anular_display_color : OUT    rgb_color_t
   );

-- Declarations

END color_forcer ;

--
ARCHITECTURE behav OF color_forcer IS
BEGIN
  anular_display_color <= ("00000000", "00000000", "00000000");
END ARCHITECTURE behav;


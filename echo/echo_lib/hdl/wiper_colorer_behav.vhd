--
-- VHDL Architecture echo_lib.wiper_colorer.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-109.ad.liu.se)
--          at - 13:05:58 10/13/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
LIBRARY echo_lib;
USE echo_lib.color_t.ALL;

ENTITY wiper_colorer IS
   PORT( 
      wiper_color : OUT    rgb_color_t
   );

-- Declarations

END wiper_colorer ;

--
ARCHITECTURE behav OF wiper_colorer IS
BEGIN
  wiper_color(0) <= "11100110";
  wiper_color(1) <= "10001110";
  wiper_color(2) <= "00110101";
END ARCHITECTURE behav;


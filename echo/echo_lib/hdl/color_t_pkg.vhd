--
-- VHDL Package Header echo_lib.color_t
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-109.ad.liu.se)
--          at - 12:46:18 10/13/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
PACKAGE color_t IS
  TYPE rgb_color_t IS ARRAY(2 DOWNTO 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
END color_t;

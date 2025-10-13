--
-- VHDL Architecture echo_lib.color_register.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-109.ad.liu.se)
--          at - 15:06:19 10/13/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
LIBRARY echo_lib;
USE echo_lib.color_t.ALL;

ENTITY color_register IS
   PORT( 
      c0               : IN     std_logic;
      fpga_reset_n     : IN     std_logic;
      prev_pixel_color : IN     rgb_color_t;
      curr_pixel_color : OUT    rgb_color_t
   );

-- Declarations

END color_register ;

--
ARCHITECTURE behav OF color_register IS
  SIGNAL stored_color : rgb_color_t;
BEGIN
  PROCESS(c0, fpga_reset_n)
  BEGIN
    IF fpga_reset_n = '0' THEN
      stored_color <= ("10101010", "10011100", "11001001");
    ELSIF RISING_EDGE(c0) THEN
      stored_color <= prev_pixel_color;
    END IF;
  END PROCESS;
  curr_pixel_color <= stored_color;
END ARCHITECTURE behav;


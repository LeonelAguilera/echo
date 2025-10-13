--
-- VHDL Architecture echo_lib.color_channel_separator.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-109.ad.liu.se)
--          at - 13:13:54 10/13/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
LIBRARY echo_lib;
USE echo_lib.color_t.ALL;

ENTITY color_channel_separator IS
   PORT( 
      c0               : IN     std_logic;
      curr_pixel_color : IN     rgb_color_t;
      reset_n          : IN     std_logic;
      vga_b            : OUT    std_logic_vector (7 DOWNTO 0);
      vga_g            : OUT    std_logic_vector (7 DOWNTO 0);
      vga_r            : OUT    std_logic_vector (7 DOWNTO 0)
   );

-- Declarations

END color_channel_separator ;

--
ARCHITECTURE behav OF color_channel_separator IS
BEGIN
  vga_r <= curr_pixel_color(0);
  vga_g <= curr_pixel_color(1);
  vga_b <= curr_pixel_color(2);
END ARCHITECTURE behav;


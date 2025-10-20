--
-- VHDL Architecture echo_lib.hbar_rasterizer.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-112.ad.liu.se)
--          at - 08:30:50 10/10/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE IEEE.MATH_REAL.all;
LIBRARY echo_lib;
USE echo_lib.color_t.ALL;

ENTITY hbar_rasterizer IS
   GENERIC( 
      position_x : INTEGER := 25;
      position_y : INTEGER := 432;
      width      : INTEGER := 340;
      heigth     : INTEGER := 48
   );
   PORT( 
      h_count               : IN     unsigned (10 DOWNTO 0);
      v_count               : IN     unsigned (9 DOWNTO 0);
      bar_mask              : OUT    std_logic;
      wiper_center_position : IN     unsigned (10 DOWNTO 0);
      bar_color             : OUT    rgb_color_t
   );

-- Declarations

END hbar_rasterizer ;

--
ARCHITECTURE behav OF hbar_rasterizer IS
BEGIN
  bar_mask <= '1' WHEN h_count >= position_x AND
                       h_count < position_x + width AND
                       v_count >= position_y - heigth AND
                       v_count < position_y ELSE
              '0';
  bar_color(0) <= "01000110" WHEN h_count > wiper_center_position ELSE
                  "00011110";
  bar_color(1) <= "00011110" WHEN h_count > wiper_center_position ELSE
                  "01010001";
  bar_color(2) <= "01010010" WHEN h_count > wiper_center_position ELSE
                  "01111110";
END ARCHITECTURE behav;


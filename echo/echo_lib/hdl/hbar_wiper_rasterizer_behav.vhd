--
-- VHDL Architecture echo_lib.hbar_wiper_rasterizer.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-112.ad.liu.se)
--          at - 09:01:26 10/10/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE IEEE.MATH_REAL.all;

ENTITY hbar_wiper_rasterizer IS
   GENERIC( 
      position_x   : INTEGER := 25;
      position_y   : INTEGER := 432;
      wiper_width  : INTEGER := 12;
      wiper_heigth : INTEGER := 96
   );
   PORT( 
      h_count               : IN     unsigned (10 DOWNTO 0);
      v_count               : IN     unsigned (9 DOWNTO 0);
      wiper_center_position : IN     unsigned (10 DOWNTO 0);
      b_in_1                : OUT    std_logic_vector (7 DOWNTO 0);
      g_in_1                : OUT    std_logic_vector (7 DOWNTO 0);
      r_in_1                : OUT    std_logic_vector (7 DOWNTO 0);
      wiper_mask            : OUT    std_logic
   );

-- Declarations

END hbar_wiper_rasterizer ;

--
ARCHITECTURE behav OF hbar_wiper_rasterizer IS
  SIGNAL wiper_center_position_signed : SIGNED(11 DOWNTO 0);
  SIGNAL h_count_signed : SIGNED(11 DOWNTO 0);
BEGIN
  wiper_center_position_signed <= SIGNED('0' & wiper_center_position);
  h_count_signed <= SIGNED('0' & h_count);
  
  wiper_mask <= '1' WHEN ABS(h_count_signed - wiper_center_position_signed) < TO_SIGNED(wiper_width / 2, h_count_signed'LENGTH) AND
                         v_count >= position_y - (3 * wiper_heigth / 4) AND
                         v_count < position_y + (wiper_heigth / 4) ELSE
                '0';
  
  r_in_1 <= "11100110";
  g_in_1 <= "10001110";
  b_in_1 <= "00110101";
END ARCHITECTURE behav;


--
-- VHDL Architecture echo_lib.vertical_bar_display_generator.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-112.ad.liu.se)
--          at - 17:43:33 10/02/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE IEEE.MATH_REAL.ALL;
LIBRARY echo_lib;
USE echo_lib.color_t.ALL;

ENTITY vertical_bar_display_generator IS
   GENERIC( 
      position_x          : POSITIVE := 30;
      position_y          : POSITIVE := 280;
      width               : POSITIVE := 48;
      number_of_segments  : POSITIVE := 16;
      segment_height_log2 : POSITIVE := 3;
      segment_thickness   : POSITIVE := 4
   );
   PORT(
      h_count         : IN     unsigned (10 DOWNTO 0);
      v_count         : IN     unsigned ( 9 DOWNTO 0);
      active_segments : IN     UNSIGNED(INTEGER(CEIL(LOG2(REAL(number_of_segments + 1))))-1 DOWNTO 0);
      vga_color       : OUT    rgb_color_t;
      mask_f          : OUT    std_logic
   );

-- Declarations

END vertical_bar_display_generator ;

--
ARCHITECTURE behav OF vertical_bar_display_generator IS
  SIGNAL height : POSITIVE := number_of_segments * (2 ** segment_height_log2);
  SIGNAL shifted_y_position : UNSIGNED(9 DOWNTO 0); -- := h_count - position_y - height;
  SIGNAL v_count_modulo : UNSIGNED(segment_height_log2 - 1 DOWNTO 0);
BEGIN
  shifted_y_position <= v_count - position_y - height;
  v_count_modulo <= shifted_y_position(segment_height_log2 - 1 DOWNTO 0);
  mask_f <= '1' WHEN (h_count >= TO_UNSIGNED(position_x, 10)) AND
                     (h_count < TO_UNSIGNED(position_x + width, 10)) AND
                     (v_count >= TO_UNSIGNED(position_y - height, 9)) AND
                     (v_count < TO_UNSIGNED(position_y, 9)) AND
                     (v_count_modulo < segment_thickness) ELSE
            '0';
  vga_color(0) <= "01000110" WHEN v_count < position_y - (active_segments * (2 ** segment_height_log2)) ELSE
                  (OTHERS => '1') WHEN v_count < position_y - (height/2) ELSE
                  (OTHERS => '0');
  vga_color(1) <= "00011110" WHEN v_count < position_y - (active_segments * (2 ** segment_height_log2)) ELSE
                  (OTHERS => '1') WHEN v_count > position_y - (3 * height/4) ELSE
                  (OTHERS => '0');
  vga_color(2) <= "01010010" WHEN v_count < position_y - (active_segments * (2 ** segment_height_log2)) ELSE
                  (OTHERS => '0');
END ARCHITECTURE behav;


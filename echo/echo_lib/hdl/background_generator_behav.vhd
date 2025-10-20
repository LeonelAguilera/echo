--
-- VHDL Architecture echo_lib.background_generator.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-112.ad.liu.se)
--          at - 11:34:32 10/19/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE IEEE.MATH_REAL.ALL;
LIBRARY echo_lib;
USE echo_lib.color_t.ALL;

ENTITY background_generator IS
   GENERIC(
     background_color       : rgb_color_t := ("01111010", "10011000", "11101110");
     divisor_line_color     : rgb_color_t := ("01000110", "00011110", "01010010");
     position_x             : INTEGER := 368;
     position_y             : INTEGER := 16;
     log2_block_size        : INTEGER := 6;
     h_block_number         : INTEGER := 10;
     v_block_number         : INTEGER := 8;
     divisor_line_thickness : INTEGER := 2
   );
   PORT( 
      h_count  : IN     unsigned (10 DOWNTO 0);
      v_count  : IN     unsigned (9 DOWNTO 0);
      bg_image : OUT    rgb_color_t
   );

-- Declarations

END background_generator ;

--
ARCHITECTURE behav OF background_generator IS
  CONSTANT center_x : INTEGER := position_x + (2**(log2_block_size - 1));
  CONSTANT center_y : INTEGER := position_y + (2**(log2_block_size - 1));
  SIGNAL offset_x : UNSIGNED(h_count'LENGTH DOWNTO 0);
  SIGNAL offset_y : UNSIGNED(v_count'LENGTH DOWNTO 0);
BEGIN
  offset_x <= UNSIGNED(ABS(SIGNED('0' & h_count) - center_x));
  offset_y <= UNSIGNED(ABS(SIGNED('0' & v_count) - center_y));
  
  bg_image <= divisor_line_color WHEN offset_x(log2_block_size - 1 DOWNTO 0) < divisor_line_thickness OR
                                      offset_y(log2_block_size - 1 DOWNTO 0) < divisor_line_thickness ELSE
              background_color;
END ARCHITECTURE behav;


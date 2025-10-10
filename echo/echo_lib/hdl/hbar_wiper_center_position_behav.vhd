--
-- VHDL Architecture echo_lib.hbar_wiper_center_position.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-112.ad.liu.se)
--          at - 08:53:09 10/10/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE IEEE.MATH_REAL.all;

ENTITY hbar_wiper_center_position IS
   GENERIC( 
      position_x    : INTEGER := 25;
      width         : INTEGER := 340;
      fixed_comma_p : INTEGER := 3
   );
   PORT( 
      h_count               : IN     unsigned (10 DOWNTO 0);
      v_count               : IN     unsigned (9 DOWNTO 0);
      wiper_position        : IN     unsigned (7 DOWNTO 0);
      wiper_center_position : OUT    unsigned (10 DOWNTO 0)
   );

-- Declarations

END hbar_wiper_center_position ;

--
ARCHITECTURE behav OF hbar_wiper_center_position IS
  CONSTANT step_size : INTEGER := INTEGER(FLOOR(REAL(width) * (2.0 ** REAL(fixed_comma_p)) / 255.0));
  CONSTANT step_size_u : UNSIGNED(INTEGER(CEIL(LOG2(REAL(step_size)))) - 1 DOWNTO 0) := TO_UNSIGNED(step_size, INTEGER(CEIL(LOG2(REAL(step_size)))));
  SIGNAL wiper_offset : UNSIGNED(7 + step_size_u'LENGTH DOWNTO 0);
BEGIN
  wiper_offset <= SHIFT_RIGHT(step_size_u * wiper_position, fixed_comma_p);
  wiper_center_position <= position_x + wiper_offset(10 DOWNTO 0);
END ARCHITECTURE behav;


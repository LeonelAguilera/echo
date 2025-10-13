--
-- VHDL Architecture echo_lib.ring_generator.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-112.ad.liu.se)
--          at - 21:13:59 10/04/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
LIBRARY echo_lib;
USE echo_lib.color_t.ALL;

ENTITY ring_generator IS
   GENERIC( 
      minor_radius    : INTEGER := 44;
      major_radius    : INTEGER := 84;
      angle_amplitude : INTEGER := 270;
      center_angle    : INTEGER := 90;
      center_x        : INTEGER := 195;
      center_y        : INTEGER := 197
   );
   PORT( 
      h_count    : IN     unsigned (10 DOWNTO 0);
      v_count    : IN     unsigned (9 DOWNTO 0);
      ring_mask  : OUT    std_logic;
      ring_color : OUT    rgb_color_t
   );

-- Declarations

END ring_generator ;

--
ARCHITECTURE behav OF ring_generator IS
  -- CONSTANT m_l : REAL := TAN((REAL(center_angle) - (REAL(angle_amplitude) / 2.0)) * MATH_PI / 180.0); -- I'll... I'll just haardcode this part...
  -- CONSTANT m_r : REAL := TAN((REAL(center_angle) + (REAL(angle_amplitude) / 2.0)) * MATH_PI / 180.0);
  
  SIGNAL shifted_x: SIGNED(11 DOWNTO 0);
  SIGNAL shifted_y: SIGNED(10 DOWNTO 0);
  SIGNAL squared_shifted_x : UNSIGNED(23 DOWNTO 0);
  SIGNAL squared_shifted_y : UNSIGNED(21 DOWNTO 0);
  SIGNAL distance : UNSIGNED(21 DOWNTO 0);
BEGIN
  shifted_x <= SIGNED('0' & h_count) - TO_SIGNED(center_x, shifted_x'LENGTH);
  shifted_y <= SIGNED('0' & v_count) - TO_SIGNED(center_y, shifted_y'LENGTH);
  squared_shifted_x <= UNSIGNED(shifted_x * shifted_x);
  squared_shifted_y <= UNSIGNED(shifted_y * shifted_y);
  distance <= squared_shifted_x(21 DOWNTO 0) + squared_shifted_y(21 DOWNTO 0);
  
  ring_mask <= '1' WHEN distance > (minor_radius * minor_radius) AND
                        distance < (major_radius * major_radius) AND (
                        (shifted_x < (-shifted_y)) OR (shifted_x < shifted_y)) ELSE -- I feel dirty...
               '0';
  
  ring_color(0) <= "01000110";
  ring_color(1) <= "00011110";
  ring_color(2) <= "01010010";
END ARCHITECTURE behav;


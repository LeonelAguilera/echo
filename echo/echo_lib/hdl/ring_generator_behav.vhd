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

ENTITY ring_generator IS
   GENERIC(
      minor_radius    :	INTEGER :=	44;
      major_radius	   :	INTEGER :=	84;
      angle_amplitude :	INTEGER :=	270;
      center_angle    :	INTEGER :=	90;
      center_x        :	INTEGER :=	195;
      center_y        :	INTEGER :=	197
   );
   PORT( 
      h_count   : IN     unsigned (11 DOWNTO 0);
      v_count   : IN     unsigned (10 DOWNTO 0);
      ring_b    : OUT    std_logic_vector (7 DOWNTO 0);
      ring_g    : OUT    std_logic_vector (7 DOWNTO 0);
      ring_mask : OUT    std_logic;
      ring_r    : OUT    std_logic_vector (7 DOWNTO 0)
   );

-- Declarations

END ring_generator ;

--
ARCHITECTURE behav OF ring_generator IS
  SIGNAL shifted_x: SIGNED(12 DOWNTO 0);
  SIGNAL shifted_y: SIGNED(11 DOWNTO 0);
  SIGNAL squared_shifted_x : UNSIGNED(25 DOWNTO 0);
  SIGNAL squared_shifted_y : UNSIGNED(23 DOWNTO 0);
  SIGNAL distance : UNSIGNED(23 DOWNTO 0);
BEGIN
  shifted_x <= SIGNED('0' & h_count) - TO_SIGNED(center_x, 12);
  shifted_y <= SIGNED('0' & v_count) - TO_SIGNED(center_y, 11);
  squared_shifted_x <= UNSIGNED(shifted_x * shifted_x);
  squared_shifted_y <= UNSIGNED(shifted_y * shifted_y);
  distance <= squared_shifted_x(23 DOWNTO 0) + squared_shifted_y(23 DOWNTO 0);
  
  ring_mask <= '1' WHEN distance > (minor_radius * minor_radius) AND
                        distance < (major_radius * major_radius) ELSE
               '0';
  
  ring_r <= "01000110";
  ring_g <= "00011110";
  ring_b <= "01010010";
END ARCHITECTURE behav;


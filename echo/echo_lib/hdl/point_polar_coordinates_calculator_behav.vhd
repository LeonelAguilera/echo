--
-- VHDL Architecture echo_lib.point_polar_coordinates_calculator.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-112.ad.liu.se)
--          at - 12:00:29 10/05/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE IEEE.math_real.all;
LIBRARY work;
USE work.codric_aux.all;

ENTITY point_polar_coordinates_calculator IS
   GENERIC( 
      minor_radius    : INTEGER := 44;
      major_radius    : INTEGER := 84;
      angle_amplitude : INTEGER := 270;
      center_angle    : INTEGER := 90;
      tap_width       : INTEGER := 24;
      tap_height      : INTEGER := 48
   );
   PORT( 
      angle          : IN     unsigned (7 DOWNTO 0);
      point_selector : IN     BIT_VECTOR (1 DOWNTO 0);
      radius         : OUT    UNSIGNED (7 DOWNTO 0);
      theta          : OUT    angle_t
   );

-- Declarations

END point_polar_coordinates_calculator ;

--
ARCHITECTURE behav OF point_polar_coordinates_calculator IS
  CONSTANT average_radius     : INTEGER := (minor_radius + major_radius)/2;
  CONSTANT tap_minor_radius   : INTEGER := average_radius - (tap_height/2);
  CONSTANT tap_major_radius   : INTEGER := average_radius + (tap_height/2);
  
  CONSTANT zero_bias_angle    : REAL := REAL(center_angle - (angle_amplitude / 2)) / 360.0;
  CONSTANT minor_bias_angle   : REAL := ARCTAN(REAL(tap_width) / (2.0 * REAL(tap_minor_radius))) / MATH_2_PI;
  CONSTANT major_bias_angle   : REAL := ARCTAN(REAL(tap_width) / (2.0 * REAL(tap_major_radius))) / MATH_2_PI;
  
  CONSTANT point_a_bias_angle : INTEGER := INTEGER((255.0 * 360.0 / REAL(angle_amplitude)) * (zero_bias_angle + major_bias_angle));
  CONSTANT point_b_bias_angle : INTEGER := INTEGER((255.0 * 360.0 / REAL(angle_amplitude)) * (zero_bias_angle - major_bias_angle));
  CONSTANT point_c_bias_angle : INTEGER := INTEGER((255.0 * 360.0 / REAL(angle_amplitude)) * (zero_bias_angle - minor_bias_angle));
  CONSTANT point_d_bias_angle : INTEGER := INTEGER((255.0 * 360.0 / REAL(angle_amplitude)) * (zero_bias_angle + minor_bias_angle));
  
  CONSTANT angle_padding : STD_LOGIC_VECTOR(INTEGER(REALMAX(CEIL(LOG2(360.0*255.0/REAL(angle_amplitude))), 8.0)) - 8 DOWNTO 0) := (OTHERS => '0');
BEGIN
  radius <= TO_UNSIGNED(tap_major_radius, radius'length) WHEN point_selector(1) = '0' ELSE
            TO_UNSIGNED(tap_minor_radius, radius'length);
            
  theta <= SIGNED(angle_padding & STD_LOGIC_VECTOR(angle)) + TO_SIGNED(point_a_bias_angle, theta'length) WHEN point_selector = "00" ELSE -- Point A: Top left
           SIGNED(angle_padding & STD_LOGIC_VECTOR(angle)) + TO_SIGNED(point_b_bias_angle, theta'length) WHEN point_selector = "01" ELSE -- Point B: Top right
           SIGNED(angle_padding & STD_LOGIC_VECTOR(angle)) + TO_SIGNED(point_c_bias_angle, theta'length) WHEN point_selector = "10" ELSE -- Point C: Bottom right
           SIGNED(angle_padding & STD_LOGIC_VECTOR(angle)) + TO_SIGNED(point_d_bias_angle, theta'length);               -- Point D: Bottom left
END ARCHITECTURE behav;


--
-- VHDL Architecture echo_lib.CODRIC.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-112.ad.liu.se)
--          at - 10:14:48 10/07/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
-- Formula extracted from https://www.youtube.com/watch?v=bre7MVlxq7o
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE IEEE.math_real.all;

ENTITY CODRIC IS
   GENERIC( 
      number_of_iterations : INTEGER := 10;
	    angle_amplitude  : INTEGER	:= 270
   );
   PORT(
      c0          : IN     std_logic;
      start       : IN     std_logic;
      radius      : IN     UNSIGNED (7 DOWNTO 0);
      theta       : IN     SIGNED (INTEGER(REALMAX(CEIL(LOG2(360.0*255.0/REAL(angle_amplitude))), 8.0)) DOWNTO 0);
      done        : OUT    std_logic;
      x_component : OUT    SIGNED (11 DOWNTO 0);
      y_component : OUT    SIGNED (11 DOWNTO 0)
   );

-- Declarations

END CODRIC ;

--
ARCHITECTURE behav OF CODRIC IS
  CONSTANT Z : INTEGER := 39;
  SIGNAL counter : INTEGER RANGE 0 TO number_of_iterations;
  SIGNAL calc_x : SIGNED(11 DOWNTO 0);
  SIGNAL calc_y : SIGNED(11 DOWNTO 0);
  SIGNAL is_done : STD_LOGIC;
  SIGNAL angle : SIGNED (INTEGER(REALMAX(CEIL(LOG2(360.0*255.0/REAL(angle_amplitude))), 8.0)) DOWNTO 0);
  SIGNAL precomputed_angle_aproximator : SIGNED (INTEGER(REALMAX(CEIL(LOG2(360.0*255.0/REAL(angle_amplitude))), 8.0)) DOWNTO 0);
BEGIN
  PROCESS(c0)
  BEGIN
    IF FALLING_EDGE(c0) THEN
      IF start = '1' THEN
        counter <= 0;
        calc_x <= "0000" & SIGNED(radius);--(7 DOWNTO 0 => STD_LOGIC_VECTOR(radius), OTHERS => '0');
        calc_y <= (OTHERS => '0');
        angle <= (OTHERS => '0');
        precomputed_angle_aproximator <= TO_SIGNED(INTEGER(360.0 * 255.0 * ARCTAN(1.0 / (2.0 ** REAL(0)))/(MATH_2_PI * REAL(angle_amplitude))), precomputed_angle_aproximator'LENGTH);
      ELSIF counter /= number_of_iterations THEN
        precomputed_angle_aproximator <= TO_SIGNED(INTEGER(360.0 * 255.0 * ARCTAN(1.0 / (2.0 ** REAL(counter + 1)))/(MATH_2_PI * REAL(angle_amplitude))), precomputed_angle_aproximator'LENGTH);
        IF angle < theta THEN
          angle <= angle + precomputed_angle_aproximator;
          calc_x <= calc_x - SHIFT_RIGHT(calc_y, counter);
          calc_y <= calc_y + SHIFT_RIGHT(calc_x, counter);
        ELSE
          angle <= angle - precomputed_angle_aproximator;
          calc_x <= calc_x + SHIFT_RIGHT(calc_y, counter);
          calc_y <= calc_y - SHIFT_RIGHT(calc_x, counter);
        END IF;
      ELSE
        is_done <= '1';
        x_component <= SHIFT_RIGHT(calc_x * 39, 6)(11 DOWNTO 0);
        y_component <= SHIFT_RIGHT(calc_y * 39, 6)(11 DOWNTO 0);
      END IF;
      IF is_done = '1' THEN
        is_done <= '0';
      END IF;
    END IF;
    IF RISING_EDGE(c0) THEN
      IF counter /= number_of_iterations AND start = '0' THEN
        counter <= counter + 1;
      END IF;
    END IF;
  END PROCESS;
  done <= is_done;
END ARCHITECTURE behav;
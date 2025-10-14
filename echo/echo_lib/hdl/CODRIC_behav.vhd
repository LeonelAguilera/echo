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
LIBRARY work;
USE work.codric_aux.all;

ENTITY CODRIC IS
   GENERIC( 
      number_of_iterations : INTEGER := 10;
      angle_amplitude      : INTEGER := 270
   );
   PORT( 
      c0          : IN     std_logic;
      start       : IN     std_logic;
      done        : OUT    std_logic;
      x_component : OUT    SIGNED (11 DOWNTO 0);
      y_component : OUT    SIGNED (11 DOWNTO 0);
      radius_t    : IN     UNSIGNED (7 DOWNTO 0);
      theta_t     : IN     angle_t
   );

-- Declarations

END CODRIC ;

--
ARCHITECTURE behav OF CODRIC IS
  CONSTANT Z : INTEGER := 39;
  CONSTANT precomputed_angle_aproximator : angle_array := precompute_angles(number_of_iterations);
  
  SIGNAL counter : INTEGER RANGE 0 TO number_of_iterations;
  SIGNAL calc_x : SIGNED(11 DOWNTO 0);
  SIGNAL calc_y : SIGNED(11 DOWNTO 0);
  SIGNAL is_done : STD_LOGIC;
  SIGNAL angle : SIGNED (INTEGER(REALMAX(CEIL(LOG2(360.0*255.0/REAL(angle_amplitude))), 8.0)) DOWNTO 0);
  SIGNAL quadrant : BIT_VECTOR(1 DOWNTO 0);
  SIGNAL target_angle : angle_t;
BEGIN
  PROCESS(c0)
  BEGIN
    IF FALLING_EDGE(c0) THEN
      IF start = '1' THEN
        counter <= 0;
        calc_x <= "0000" & SIGNED(radius_t);--(7 DOWNTO 0 => STD_LOGIC_VECTOR(radius_t), OTHERS => '0');
        calc_y <= (OTHERS => '0');
        angle <= (OTHERS => '0');
        is_done <= '0';
        
        IF theta_t < 0 THEN
          quadrant <= "11";
          target_angle <= -theta_t;
        ELSIF theta_t >= 0 AND theta_t < (90 * 255 / angle_amplitude) THEN
          quadrant <= "00";
          target_angle <= theta_t;
        ELSIF theta_t >= (90 * 255 / angle_amplitude) AND theta_t < (180 * 255 / angle_amplitude) THEN
          quadrant <= "01";
          target_angle <= (180 * 255 / angle_amplitude) - theta_t;
        ELSIF theta_t >= (180 * 255 / angle_amplitude) AND theta_t < (270 * 255 / angle_amplitude) THEN
          quadrant <= "10";
          target_angle <= theta_t - (180 * 255 / angle_amplitude);
        ELSE
          quadrant <= "11";
          target_angle <= (360 * 255 / angle_amplitude) - theta_t;
        END IF;          
      ELSIF counter /= number_of_iterations THEN
        counter <= counter + 1;
        IF angle < target_angle THEN
          angle <= angle + precomputed_angle_aproximator(counter);
          calc_x <= calc_x - SHIFT_RIGHT(calc_y, counter);
          calc_y <= calc_y + SHIFT_RIGHT(calc_x, counter);
        ELSE
          angle <= angle - precomputed_angle_aproximator(counter);
          calc_x <= calc_x + SHIFT_RIGHT(calc_y, counter);
          calc_y <= calc_y - SHIFT_RIGHT(calc_x, counter);
        END IF;
      ELSE
        is_done <= '1';
        CASE quadrant IS
        WHEN "00" =>
          x_component <= SHIFT_RIGHT(calc_x * 39, 6)(11 DOWNTO 0);
          y_component <= SHIFT_RIGHT(calc_y * 39, 6)(11 DOWNTO 0);
        WHEN "01" =>
          x_component <= -SHIFT_RIGHT(calc_x * 39, 6)(11 DOWNTO 0);
          y_component <= SHIFT_RIGHT(calc_y * 39, 6)(11 DOWNTO 0);
        WHEN "10" =>
          x_component <= -SHIFT_RIGHT(calc_x * 39, 6)(11 DOWNTO 0);
          y_component <= -SHIFT_RIGHT(calc_y * 39, 6)(11 DOWNTO 0);
        WHEN "11" =>
          x_component <= SHIFT_RIGHT(calc_x * 39, 6)(11 DOWNTO 0);
          y_component <= -SHIFT_RIGHT(calc_y * 39, 6)(11 DOWNTO 0);
        END CASE;
      END IF;
    END IF;
  END PROCESS;
  done <= is_done;
END ARCHITECTURE behav;

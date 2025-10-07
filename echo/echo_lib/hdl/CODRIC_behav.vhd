--
-- VHDL Architecture echo_lib.CODRIC.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-112.ad.liu.se)
--          at - 10:14:48 10/07/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE IEEE.math_real.all;

ENTITY CODRIC IS
   GENERIC( 
      number_of_iterations : INTEGER := 10
   );
   PORT( 
      radius      : IN     UNSIGNED (7 DOWNTO 0);
      theta       : IN     SIGNED (INTEGER(REALMAX(CEIL(LOG2(360.0*255.0/REAL(angle_amplitude))), 8.0)) DOWNTO 0);
      done        : OUT    std_logic;
      x_component : OUT    SIGNED (11 DOWNTO 0);
      y_component : OUT    SIGNED (10 DOWNTO 0);
      start       : IN     std_logic;
      c0          : IN     std_logic
   );

-- Declarations

END CODRIC ;

--
ARCHITECTURE behav OF CODRIC IS
  CONSTANT Z : INTEGER := 39;
  SIGNAL counter : INTEGER RANGE 0 TO number_of_iterations;
  SIGNAL last_x : SIGNED(11 DOWNTO 0);
  SIGNAL last_y : SIGNED(10 DOWNTO 0);
  SIGNAL next_x : SIGNED(11 DOWNTO 0);
  SIGNAL next_y : SIGNED(10 DOWNTO 0);
  SIGNAL angle : INTEGER;
  SIGNAL is_done : STD_LOGIC;
BEGIN
  PROCESS(c0)
  BEGIN
    IF FALLING_EDGE(c0) THEN
      IF start = '1' THEN
        counter <= 0;
        angle <= 0;
        last_x <= (OTHERS => '0', 0 => '1');
        last_y <= (OTHERS => '0');
      ELSIF counter /= number_of_iterations THEN
        next_x <= last_x - SHIFT_RIGHT(last_y, counter);
        next_y <= last_y + SHIFT_RIGHT(last_x, counter);
      ELSE 
      END IF;
    END IF;
  END PROCESS;
END ARCHITECTURE behav;
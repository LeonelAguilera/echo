--
-- VHDL Architecture echo_lib.basic_counter.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-112.ad.liu.se)
--          at - 10:15:59 10/11/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE IEEE.MATH_REAL.ALL;

ENTITY basic_counter IS
   PORT( 
      c0               : IN     std_logic;
      finished_drawing : IN     std_logic;
      in_image_window  : IN     std_logic;
      read_address     : OUT    std_logic_vector (18 DOWNTO 0)
   );

-- Declarations

END basic_counter ;

--
ARCHITECTURE behav OF basic_counter IS
  SIGNAL counter : UNSIGNED(read_address'LENGTH - 1 DOWNTO 0);
BEGIN
  PROCESS(c0)
  BEGIN
    IF RISING_EDGE(c0) THEN
      IF finished_drawing = '1' THEN
        counter <= (OTHERS => '0');
      ELSIF in_image_window = '1' THEN
        counter <= counter + 1;
      END IF;
    END IF;
  END PROCESS;
  read_address <= STD_LOGIC_VECTOR(counter);
END ARCHITECTURE behav;


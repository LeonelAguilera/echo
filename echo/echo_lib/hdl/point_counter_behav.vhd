--
-- VHDL Architecture echo_lib.point_counter.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-112.ad.liu.se)
--          at - 11:38:49 10/05/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE IEEE.math_real.all;
LIBRARY work;
USE work.codric_aux.all;

ENTITY point_counter IS
   PORT( 
      c0             : IN     std_logic;
      next_point     : IN     std_logic;
      reset          : IN     std_logic;
      point_selector : OUT    BIT_VECTOR (1 DOWNTO 0);
      start          : OUT    std_logic
   );

-- Declarations

END point_counter ;

--
ARCHITECTURE behav OF point_counter IS
  SIGNAL counter : UNSIGNED(1 DOWNTO 0);
BEGIN
  PROCESS(c0)
  BEGIN
    IF RISING_EDGE(c0) THEN
      IF reset = '1' THEN
        counter <= (OTHERS => '0');
        start <= '1';
      ELSIF next_point = '1' THEN
        counter <= counter + 1;
        start <= '1';
      ELSE
        start <= '0';
      END IF;
    END IF;
  END PROCESS;
  point_selector <= TO_BITVECTOR(STD_LOGIC_VECTOR(counter));
END ARCHITECTURE behav;


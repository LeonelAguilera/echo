--
-- VHDL Architecture echo_lib.clock_view.behav
--
-- Created:
--          by - alfth698.student-liu.se (muxen2-109.ad.liu.se)
--          at - 18:35:51 10/28/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY clock_view IS
   PORT( 
      c0            : IN     STD_LOGIC;
      reduced_clock : OUT    std_logic
   );

-- Declarations

END clock_view ;

--
ARCHITECTURE behav OF clock_view IS
  SIGNAL counter : INTEGER RANGE 0 TO 65000000;
  SIGNAL rc : STD_LOGIC;
BEGIN
  PROCESS(c0)
  BEGIN
    IF RISING_EDGE(c0) THEN
      IF counter = 65000000 - 1 THEN
        counter <= 0;
        rc <= NOT rc;
      ELSE
        counter <= counter + 1;
      END IF;
    END IF;
  END PROCESS;
  reduced_clock <= rc;
END ARCHITECTURE behav;

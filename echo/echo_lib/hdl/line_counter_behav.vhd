--
-- VHDL Architecture echo_lib.line_counter.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-112.ad.liu.se)
--          at - 10:42:00 10/04/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY line_counter IS
   PORT( 
      c0      : IN     std_logic;
      h_count : IN     unsigned (11 DOWNTO 0);
      reset_n : IN     std_logic;
      v_count : OUT    unsigned (10 DOWNTO 0)
   );

-- Declarations

END line_counter ;

--
ARCHITECTURE behav OF line_counter IS
  SIGNAL counter : UNSIGNED(10 DOWNTO 0);
BEGIN
  PROCESS(c0)
  BEGIN
    IF reset_n = '0' THEN
      counter <= (OTHERS => '0');
    ELSIF c0'EVENT AND c0 = '1' THEN
      IF h_count = 1342 THEN
        IF counter >= 805 THEN
          counter <= (OTHERS => '0');
        ELSE
          counter <= counter + 1;
        END IF;
      END IF;
    END IF;      
  END PROCESS;
  v_count <= counter;
END ARCHITECTURE behav;


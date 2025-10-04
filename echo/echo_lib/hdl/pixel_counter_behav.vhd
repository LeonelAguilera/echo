--
-- VHDL Architecture echo_lib.pixel_counter.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-112.ad.liu.se)
--          at - 10:39:34 10/04/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY pixel_counter IS
   PORT( 
      c0      : IN     std_logic;
      reset_n : IN     std_logic;
      h_count : OUT    unsigned (11 DOWNTO 0)
   );

-- Declarations

END pixel_counter ;

--
ARCHITECTURE behav OF pixel_counter IS
  SIGNAL counter : UNSIGNED(11 DOWNTO 0);
BEGIN
  PROCESS(c0)
  BEGIN
    IF reset_n = '0' THEN
      counter <= (OTHERS => '0');
    ELSIF c0'EVENT AND c0 = '1' THEN
      IF counter >= 1343 THEN
        counter <= (OTHERS => '0');
      ELSE
        counter <= counter + 1;
      END IF;
    END IF;      
  END PROCESS;
  h_count <= counter;
END ARCHITECTURE behav;


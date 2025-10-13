--
-- VHDL Architecture echo_lib.pll_tester.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-109.ad.liu.se)
--          at - 08:50:30 10/13/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY pll_tester IS
   PORT( 
      c0            : IN     std_logic;
      fpga_reset_n  : IN     std_logic;
      visible_clock : OUT    std_logic
   );

-- Declarations

END pll_tester ;

--
ARCHITECTURE behav OF pll_tester IS
  SIGNAL counter : INTEGER RANGE 0 TO 65000000;
  SIGNAL clock_signal : STD_LOGIC;
BEGIN
  PROCESS(c0, fpga_reset_n)
  BEGIN
    IF fpga_reset_n = '0' THEN
      counter <= 64999999;
      clock_signal <= '0';
    ELSIF RISING_EDGE(c0) THEN
      IF counter = 0 THEN
        clock_signal <= NOT clock_signal;
        counter <= 64999999;
      ELSE
        counter <= counter - 1;
      END IF;
    END IF;
  END PROCESS;
  visible_clock <= clock_signal;
END ARCHITECTURE behav;


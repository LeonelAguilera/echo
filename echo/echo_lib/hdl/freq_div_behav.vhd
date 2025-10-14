--
-- VHDL Architecture echo_lib.freq_div.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-112.ad.liu.se)
--          at - 11:48:59 10/10/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE IEEE.MATH_REAL.ALL;

ENTITY freq_div IS
   PORT( 
      c0           : IN     std_logic;
      fpga_reset_n : IN     std_logic;
      c1           : OUT    std_logic
   );

-- Declarations

END freq_div ;

--
ARCHITECTURE behav OF freq_div IS
  SIGNAL counter : UNSIGNED(2 DOWNTO 0);
  SIGNAL output_clk : STD_LOGIC;
BEGIN
  PROCESS(c0, fpga_reset_n)
  BEGIN
    IF fpga_reset_n = '1' THEN
      counter <= "000";
      output_clk <= '0';
    ELSIF RISING_EDGE(c0) THEN
      counter <= counter + 1;
      IF counter = "000" THEN
        output_clk <= NOT output_clk;
      END IF;
    END IF;
  END PROCESS;
  c1 <= output_clk;
END ARCHITECTURE behav;


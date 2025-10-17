--
-- VHDL Architecture echo_lib.overcomplicated_conmutator.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-113.ad.liu.se)
--          at - 10:12:49 10/17/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE IEEE.MATH_REAL.ALL;

ENTITY overcomplicated_conmutator IS
   PORT( 
      buffer_selector : IN     std_logic;
      color_data      : IN     std_logic_vector (5 DOWNTO 0);
      read_address    : IN     std_logic_vector (18 DOWNTO 0);
      write_address   : IN     std_logic_vector (18 DOWNTO 0);
      addr0           : OUT    std_logic_vector (18 DOWNTO 0);
      addr1           : OUT    std_logic_vector (18 DOWNTO 0);
      din0            : OUT    std_logic_vector (5 DOWNTO 0);
      din1            : OUT    std_logic_vector (5 DOWNTO 0)
   );

-- Declarations

END overcomplicated_conmutator ;

--
ARCHITECTURE behav OF overcomplicated_conmutator IS
BEGIN
  din_0 <= color_data;
  din_1 <= color_data;
  addr0 <= read_address WHEN buffer_selector = '0' ELSE
           write_address;
  addr1 <= read_address WHEN buffer_selector = '1' ELSE
           write_address;
END ARCHITECTURE behav;


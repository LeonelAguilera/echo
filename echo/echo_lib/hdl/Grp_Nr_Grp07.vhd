LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Grp_Nr IS
   PORT( 
      HEX7 : OUT    std_logic_vector (0 TO 6);
      HEX6 : OUT    std_logic_vector (0 TO 6)
   );

-- Declarations

END Grp_Nr ;

--
ARCHITECTURE Grp07 OF Grp_Nr IS
  
BEGIN
  
   HEX7 <= "0000001"; --0
   HEX6 <= "0001111"; --7

END ARCHITECTURE Grp07;


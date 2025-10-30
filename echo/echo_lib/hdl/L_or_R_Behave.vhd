LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
LIBRARY echo_lib;
USE echo_lib.keyboard_package.ALL;

ENTITY L_or_R IS
   PORT( 
      DAC       : In     signed (15 DOWNTO 0);
      lrsel     : In     std_logic;
      c0        : In     std_logic; 
      Left_Dac  : Out std_logic_vector(15 downto 0);
      Right_Dac : Out std_logic_vector(15 downto 0) 
    );


END L_or_R ;

ARCHITECTURE Behave OF L_or_R IS
BEGIN
  
  process(c0)
  begin
  If lrsel = '0' then 
    Left_Dac <= std_logic_vector(DAC);
  else 
    Right_Dac <= std_logic_vector(DAC);  
  end if;
  end process; 
END ARCHITECTURE Behave;


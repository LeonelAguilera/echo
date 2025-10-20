LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Left_Right IS
   PORT( 
      Left_Audio  : IN     std_logic_vector (15 DOWNTO 0);
      Enable      : IN     std_logic;
      DAC_en      : OUT    std_logic;
      TXReg       : OUT    signed (15 DOWNTO 0);
      lrsel       : OUT    std_logic;
      Right_Audio : IN     std_logic_vector (15 DOWNTO 0)
   );

-- Declarations

END Left_Right ;


ARCHITECTURE Choice OF Left_Right IS
BEGIN
END ARCHITECTURE Choice;


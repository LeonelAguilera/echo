LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY i2c IS
   PORT( 
      PLL   : IN     std_logic;
      SDA   : OUT    std_logic;
      SCL   : OUT    std_logic;
      Reset : IN     std_logic
   );

-- Declarations

END i2c ;


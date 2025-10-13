LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Mode IS
   PORT( 
      Mode : OUT    std_logic;
      CSB  : OUT    std_logic
   );

-- Declarations

END Mode ;

ARCHITECTURE Mode_i2c OF Mode IS
BEGIN
  
  Mode <= 0; -- sets Audio Codec to 2-wire communication(I2C)
  
  CSB <= 0; -- selects one of the 2 available slave addresses(0=0011010)
  
END ARCHITECTURE Mode_i2c;


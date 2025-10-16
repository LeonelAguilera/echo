--
-- VHDL Architecture echo_lib.i2c.sdfsd
--
-- Created:
--          by - alfth698.student-liu.se (muxen2-116.ad.liu.se)
--          at - 14:21:05 10/16/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
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

--
ARCHITECTURE sdfsd OF i2c IS
BEGIN
END ARCHITECTURE sdfsd;


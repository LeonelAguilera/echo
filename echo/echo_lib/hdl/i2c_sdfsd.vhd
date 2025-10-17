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
      Reset : IN     std_logic;
      HEX6  : OUT    std_logic_vector (0 TO 6);
      HEX7  : OUT    std_logic_vector (0 TO 6)
   );

-- Declarations

type exemplar_string_array is array (natural range <>, natural range <>) of character;
attribute pin_number : string;
attribute array_pin_number : exemplar_string_array;
attribute array_pin_number of hex6 : signal is ("AC17","AA15","AB15","AB17","AA16","AB16","AA17");
attribute array_pin_number of hex7 : signal is ("AA14","AG18","AF17","AH17","AG17","AE17","AD17");
attribute pin_number of SDA: signal is "A8";
attribute pin_number of SCL: signal is "B7";
attribute pin_number of Reset: signal is "AE14";
attribute pin_number of PLL : signal is "AF14";

END i2c ;

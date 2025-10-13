LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY i2c IS
   PORT( 
      Balance  : IN     std_logic_vector (7 DOWNTO 0);
      FPGA_clk : IN     std_logic;
      Volum    : IN     std_logic_vector (7 DOWNTO 0);
      Reset    : IN     std_logic;
      SDIN     : OUT    std_logic;
      SCLK     : OUT    std_logic;
      Mode     : OUt    std_logic
   );

END i2c ;


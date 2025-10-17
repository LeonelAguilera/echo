LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY i2c_init IS
   PORT( 
      Reset : IN     std_logic;
      CLK   : IN     std_logic;
      SDA   : OUT    std_logic;
      SCL   : OUT    std_logic
   );

-- Declarations

END i2c_init ;

ARCHITECTURE init OF i2c_init IS
  
    constant Bits1    : integer := 28;       -- osäker hur många bitar
    constant Bits2    : integer := 58;       -- osäker hur många bitar
                                            -- bits for the slave, and all the adresses + data   
    signal SDA_rom   : std_logic_vector(Bits1-1 downto 0) := "1000110100100000111111001101"; 
                                            -- clk sequence so that we can send bits
    signal SCL_rom   : std_logic_vector(Bits2-1 downto 0) := "1101010101010101010101010101010101010101010101010101010101";
    signal Bit_count : integer := 0; 
BEGIN
  
  
  process(CLK, RESET)
  begin 
    if Reset = '1' then
    Bit_count <= 0; 
    -- OK <= '0';
  elsif rising_edge(CLK)then
    if Bit_count < Bits1 then 
      SDA       <= SDA_rom(Bits1-1-Bit_count);
      SCL       <= SCL_rom(Bits2-1-Bit_count);
      Bit_count <= Bit_count + 1;
  -- else OK <= '1'; 
    end if;
    end if; 
  end process; 
  

END ARCHITECTURE init;

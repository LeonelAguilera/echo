LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
LIBRARY echo_lib;
USE echo_lib.keyboard_package.ALL;


ENTITY Left_Right IS
   PORT( 
      c0          : IN     std_logic;
      Reset       : IN     std_logic;
      Left_Audio  : IN     std_logic_vector (15 DOWNTO 0);
      Right_Audio : IN     std_logic_vector (15 DOWNTO 0);
      lrsel       : IN     std_logic;
      Enable      : IN     std_logic;
      DAC_en      : OUT    std_logic;
      TXReg       : OUT    signed (15 DOWNTO 0)
   );

-- Declarations

END Left_Right ;


ARCHITECTURE Choice OF Left_Right IS
  
BEGIN
  process(c0, Reset)
  begin
    if Reset = '0' then
      TXReg  <= (others => '0');
      DAC_en <= '0';
    elsif rising_edge(c0) then
      if Enable = '1' then
        if lrsel = '0' then
          TXReg <= signed(Left_Audio);   -- vänster kanal
        else
          TXReg <= signed(Right_Audio);  -- höger kanal
        end if;
        DAC_en <= '1';
      else
        DAC_en <= '0';
      end if;
    end if;
  end process;
  
END ARCHITECTURE Choice;


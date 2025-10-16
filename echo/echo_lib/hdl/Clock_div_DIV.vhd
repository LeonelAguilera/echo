LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Clock_div IS
   PORT( 
      CLK   : OUT    std_logic;
      Reset : IN     std_logic;
      PLL   : IN     std_logic
   );

-- Declarations

END Clock_div ;


ARCHITECTURE DIV OF Clock_div IS
  
  signal count     : integer  :=  0; -- counts to 500 and starts over
  signal clk_int   : std_logic := '0'; -- internal clock , which should be switching from 0 > 1 100k/per s (100kHz)
  
BEGIN
  
   process(PLL)   
   begin    
  If Reset = '1' then 
    count <= 0; 
    clk_int <= '0';
  elsif rising_edge(PLL) then 
    count <= count+1;              
   If count = 325 then                    -- couting to 500 on a 50Mhz clock takes 1/100k second = 100kHz clock
    clk_int <= not clk_int;                          
    count <= 0; 
  end if; 
   end if;
   CLK <= clk_int;
  end process;
END ARCHITECTURE DIV;


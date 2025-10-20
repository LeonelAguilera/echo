LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Key_Data IS
   PORT( 
      Vector_Value : IN     std_logic_vector (5 DOWNTO 0);
      WPressed     : OUT    std_logic;
      SPressed     : OUT    std_logic;
      DPressed     : OUT    std_logic;
      APressed     : OUT    std_logic
   );

-- Declarations

END Key_Data ;

ARCHITECTURE Data OF Key_Data IS
  
begin
    -- Koppla utgångarna till valfria positioner i vektorn
    WPressed <= Vector_Value(1);
    SPressed <= Vector_Value(2);
    DPressed <= Vector_Value(3);
    APressed <= Vector_Value(4);    
  
END ARCHITECTURE Data;


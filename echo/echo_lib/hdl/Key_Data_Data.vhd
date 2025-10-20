LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Key_Data IS
   PORT( 
      Vector_Value : IN     std_logic_vector;
      WPressed     : OUT    std_logic;
      SPressed     : OUT    std_logic;
      DPressed     : OUT    std_logic;
      APressed     : OUT    std_logic;
      overflow     : OUT    std_logic
   );

-- Declarations

END Key_Data ;

ARCHITECTURE Data OF Key_Data IS
BEGIN
END ARCHITECTURE Data;


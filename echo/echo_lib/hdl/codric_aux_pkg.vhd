--
-- VHDL Package Header echo_lib.codric_aux
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-112.ad.liu.se)
--          at - 14:14:36 10/09/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE IEEE.math_real.all;

PACKAGE codric_aux IS
  --GENERIC( 
  --  number_of_iterations_p : INTEGER := 10;
  --  angle_amplitude_p  : INTEGER	:= 270
  --);
  SUBTYPE angle_t IS SIGNED(INTEGER(REALMAX(CEIL(LOG2(360.0*255.0/REAL(270))), 8.0)) DOWNTO 0);
  TYPE angle_array IS ARRAY(0 TO 9) OF angle_t;
  FUNCTION precompute_angles(n: INTEGER) RETURN angle_array;
END codric_aux;

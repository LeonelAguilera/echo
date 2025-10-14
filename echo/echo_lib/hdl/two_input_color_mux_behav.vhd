--
-- VHDL Architecture echo_lib.two_input_color_mux.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-109.ad.liu.se)
--          at - 14:35:49 10/13/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE IEEE.MATH_REAL.all;
LIBRARY echo_lib;
USE echo_lib.color_t.ALL;

ENTITY two_input_color_mux IS
   PORT(
     in0 : IN rgb_color_t;
     in1 : IN rgb_color_t;
     sel : IN STD_LOGIC;
     out_c : OUT rgb_color_t
   );

-- Declarations

END two_input_color_mux ;

--
ARCHITECTURE behav OF two_input_color_mux IS
BEGIN
  out_c <= in0 WHEN sel = '0' ELSE
           in1;
END ARCHITECTURE behav;


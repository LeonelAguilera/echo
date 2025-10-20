--
-- VHDL Architecture echo_lib.one_hot_mux.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-109.ad.liu.se)
--          at - 14:21:14 10/13/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE IEEE.MATH_REAL.ALL;
LIBRARY work;
USE work.color_t.ALL;

ENTITY one_hot_mux IS
   PORT( 
      sel       : IN     std_logic_vector (6 DOWNTO 0);
      in0       : IN     rgb_color_t;
      in1       : IN     rgb_color_t;
      in2       : IN     rgb_color_t;
      in3       : IN     rgb_color_t;
      in4       : IN     rgb_color_t;
      in5       : IN     rgb_color_t;
      in6       : IN     rgb_color_t;
      out_color : OUT    rgb_color_t
   );

-- Declarations

END one_hot_mux ;

--
ARCHITECTURE behav OF one_hot_mux IS
  CONSTANT background_color : rgb_color_t := ("11001001", "01101100", "01010101");
BEGIN
  WITH sel SELECT out_color <=
    in0 WHEN "0000001",
    in1 WHEN "0000010",
    in2 WHEN "0000100",
    in3 WHEN "0001000",
    in4 WHEN "0010000",
    in5 WHEN "0100000",
    in6 WHEN "1000000",
    background_color WHEN OTHERS;
END ARCHITECTURE behav;
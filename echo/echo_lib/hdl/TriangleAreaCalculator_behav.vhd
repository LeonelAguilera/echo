--
-- VHDL Architecture echo_lib.TriangleAreaCalculator.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-112.ad.liu.se)
--          at - 10:20:55 10/05/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY TriangleAreaCalculator IS
  PORT(
    x1 : IN UNSIGNED(10 DOWNTO 0);
    y1 : IN UNSIGNED(9 DOWNTO 0);
    x2 : IN UNSIGNED(10 DOWNTO 0);
    y2 : IN UNSIGNED(9 DOWNTO 0);
    x3 : IN UNSIGNED(10 DOWNTO 0);
    y3 : IN UNSIGNED(9 DOWNTO 0);
    area : OUT UNSIGNED(20 DOWNTO 0)
  );
-- Declarations

END TriangleAreaCalculator ;

--
ARCHITECTURE behav OF TriangleAreaCalculator IS
BEGIN
  area <= shift_right(abs(x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2)), 1);
END ARCHITECTURE behav;


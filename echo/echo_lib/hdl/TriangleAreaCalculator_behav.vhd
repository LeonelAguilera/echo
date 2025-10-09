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
    area : OUT UNSIGNED(19 DOWNTO 0)
  );
-- Declarations

END TriangleAreaCalculator ;

--
ARCHITECTURE behav OF TriangleAreaCalculator IS
  SIGNAL temp_x1 : SIGNED(11 DOWNTO 0);
  SIGNAL temp_x2 : SIGNED(11 DOWNTO 0);
  SIGNAL temp_x3 : SIGNED(11 DOWNTO 0);
  SIGNAL temp_y1 : SIGNED(10 DOWNTO 0);
  SIGNAL temp_y2 : SIGNED(10 DOWNTO 0);
  SIGNAL temp_y3 : SIGNED(10 DOWNTO 0);
  
  SIGNAL operation_result : SIGNED(22 DOWNTO 0);
BEGIN
  temp_x1 <= SIGNED('0' & x1);
  temp_x2 <= SIGNED('0' & x2);
  temp_x3 <= SIGNED('0' & x3);
  temp_y1 <= SIGNED('0' & y1);
  temp_y2 <= SIGNED('0' & y2);
  temp_y3 <= SIGNED('0' & y3);
  
  operation_result <= ABS((temp_x1 * (temp_y2 - temp_y3)) + (temp_x2 * (temp_y3 - temp_y1)) + (temp_x3 * (temp_y1 - temp_y2)));
  area <= UNSIGNED(operation_result(20 DOWNTO 1));
END ARCHITECTURE behav;


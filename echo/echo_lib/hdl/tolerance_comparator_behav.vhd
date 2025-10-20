--
-- VHDL Architecture echo_lib.tolerance_comparator.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-112.ad.liu.se)
--          at - 13:30:24 10/09/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY tolerance_comparator IS
   GENERIC(
     tolerance : INTEGER := 3
   );
   PORT( 
      point_area : IN     UNSIGNED (19 DOWNTO 0);
      wiper_area : IN     UNSIGNED (19 DOWNTO 0);
      wiper_mask : OUT    std_logic
   );

-- Declarations

END tolerance_comparator ;

--
ARCHITECTURE behav OF tolerance_comparator IS
  SIGNAL temp_wiper_area : SIGNED(20 DOWNTO 0);
  SIGNAL temp_point_area : SIGNED(20 DOWNTO 0);
BEGIN
  temp_wiper_area <= SIGNED('0' & wiper_area);
  temp_point_area <= SIGNED('0' & point_area);
  wiper_mask <= '1' WHEN ABS(temp_wiper_area - temp_point_area) < TO_SIGNED(tolerance, temp_wiper_area'LENGTH) ELSE
                '0';
END ARCHITECTURE behav;


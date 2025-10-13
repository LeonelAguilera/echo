--
-- VHDL Architecture echo_lib.wiper_rasterizer.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-109.ad.liu.se)
--          at - 15:25:31 10/13/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
LIBRARY echo_lib;
USE echo_lib.color_t.ALL;

ENTITY wiper_rasterizer IS
   PORT( 
      Ax          : IN     unsigned (10 DOWNTO 0);
      Ay          : IN     unsigned (9 DOWNTO 0);
      Bx          : IN     unsigned (10 DOWNTO 0);
      By          : IN     unsigned (9 DOWNTO 0);
      Cx          : IN     unsigned (10 DOWNTO 0);
      Cy          : IN     unsigned (9 DOWNTO 0);
      Dx          : IN     unsigned (10 DOWNTO 0);
      Dy          : IN     unsigned (9 DOWNTO 0);
      h_count     : IN     unsigned (10 DOWNTO 0);
      v_count     : IN     unsigned (9 DOWNTO 0);
      wiper_color : OUT    rgb_color_t;
      wiper_mask  : OUT    std_logic
   );

-- Declarations

END wiper_rasterizer ;

--
ARCHITECTURE behav OF wiper_rasterizer IS
BEGIN
END ARCHITECTURE behav;


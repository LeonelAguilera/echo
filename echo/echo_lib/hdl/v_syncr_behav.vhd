--
-- VHDL Architecture echo_lib.v_syncr.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-112.ad.liu.se)
--          at - 10:46:36 10/04/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
LIBRARY echo_lib;
USE echo_lib.color_t.ALL;


ENTITY v_syncr IS
   PORT( 
      c0          : IN     std_logic;
      reset_n     : IN     std_logic;
      v_count     : IN     unsigned (9 DOWNTO 0);
      vblank      : OUT    std_logic;
      vga_vsync_n : OUT    std_logic
   );

-- Declarations

END v_syncr ;

--
ARCHITECTURE behav OF v_syncr IS
BEGIN
  vga_vsync_n <= '0' WHEN v_count >= (768 + 3) AND
                          v_count <= (768 + 3 + 6) ELSE
                 '1';
  vblank <= '1' WHEN v_count >= (768 + 0) AND
                     v_count <= (768 + 3 + 6 + 29) ELSE
            '0';
END ARCHITECTURE behav;


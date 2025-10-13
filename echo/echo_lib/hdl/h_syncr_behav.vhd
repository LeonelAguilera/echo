--
-- VHDL Architecture echo_lib.h_syncr.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-112.ad.liu.se)
--          at - 10:44:53 10/04/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
LIBRARY echo_lib;
USE echo_lib.color_t.ALL;


ENTITY h_syncr IS
   PORT( 
      c0           : IN     std_logic;
      fpga_reset_n : IN     std_logic;
      h_count      : IN     unsigned (10 DOWNTO 0);
      hblank       : OUT    std_logic;
      vga_hsync_n  : OUT    std_logic
   );

-- Declarations

END h_syncr ;

--
ARCHITECTURE behav OF h_syncr IS
BEGIN
  vga_hsync_n <= '0' WHEN h_count > (1024 + 24) AND
                          h_count <= (1024 + 24 + 136) ELSE
                 '1';
  hblank <= '1' WHEN h_count >= (1024 + 0) AND
                     h_count <= (1024 + 24 + 136 + 160) ELSE
            '0';
END ARCHITECTURE behav;


--
-- VHDL Architecture echo_lib.pixel_color_generator.dummy_test
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-112.ad.liu.se)
--          at - 10:30:39 10/04/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY pixel_color_generator IS
   PORT( 
      balance          : IN     unsigned (7 DOWNTO 0);
      c0               : IN     std_logic;
      echo_duration    : IN     unsigned (7 DOWNTO 0);
      echo_intensity   : IN     unsigned (7 DOWNTO 0);
      fpga_reset_n     : IN     std_logic;
      h_count          : IN     unsigned (10 DOWNTO 0);
      left_ear_volume  : IN     unsigned (7 DOWNTO 0);
      master_volume    : IN     unsigned (7 DOWNTO 0);
      right_ear_volume : IN     unsigned (7 DOWNTO 0);
      v_count          : IN     unsigned (9 DOWNTO 0);
      vga_b_d          : OUT    std_logic_vector (7 DOWNTO 0);
      vga_g_d          : OUT    std_logic_vector (7 DOWNTO 0);
      vga_r_d          : OUT    std_logic_vector (7 DOWNTO 0)
   );

-- Declarations

END pixel_color_generator ;

--
ARCHITECTURE dummy_test OF pixel_color_generator IS
BEGIN
  vga_r_d <= STD_LOGIC_VECTOR(h_count(7 DOWNTO 0));
  vga_g_d <= STD_LOGIC_VECTOR(v_count(7 DOWNTO 0));
  vga_b_d <= (OTHERS => '0');
END ARCHITECTURE dummy_test;


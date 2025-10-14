--
-- VHDL Architecture echo_lib.switch_economizer.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-112.ad.liu.se)
--          at - 00:09:13 10/10/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY switch_economizer IS
   PORT( 
      balance_d          : IN     unsigned (2 DOWNTO 0);
      c0                 : IN     std_logic;
      echo_duration_d    : IN     unsigned (2 DOWNTO 0);
      echo_intensity_d   : IN     unsigned (2 DOWNTO 0);
      fpga_reset_n       : IN     std_logic;
      left_ear_volume_d  : IN     unsigned (2 DOWNTO 0);
      master_volume_d    : IN     unsigned (2 DOWNTO 0);
      right_ear_volume_d : IN     unsigned (2 DOWNTO 0);
      balance            : OUT    unsigned (7 DOWNTO 0);
      echo_duration      : OUT    unsigned (7 DOWNTO 0);
      echo_intensity     : OUT    unsigned (7 DOWNTO 0);
      left_ear_volume    : OUT    unsigned (7 DOWNTO 0);
      master_volume      : OUT    unsigned (7 DOWNTO 0);
      right_ear_volume   : OUT    unsigned (7 DOWNTO 0)
   );

-- Declarations

END switch_economizer ;
-- Example of change
--
ARCHITECTURE behav OF switch_economizer IS
BEGIN
  master_volume(7 DOWNTO 5) <= master_volume_d;
  master_volume(4 DOWNTO 0) <= (OTHERS => '0');
  
  balance(7 DOWNTO 5) <= balance_d;
  balance(4 DOWNTO 0) <= (OTHERS => '0');
  
  left_ear_volume(7 DOWNTO 5) <= left_ear_volume_d;
  left_ear_volume(4 DOWNTO 0) <= (OTHERS => '0');
  
  right_ear_volume(7 DOWNTO 5) <= right_ear_volume_d;
  right_ear_volume(4 DOWNTO 0) <= (OTHERS => '0');
  
  echo_duration(7 DOWNTO 5) <= echo_duration_d;
  echo_duration(4 DOWNTO 0) <= (OTHERS => '0');
  
  echo_intensity(7 DOWNTO 5) <= echo_intensity_d;
  echo_intensity(4 DOWNTO 0) <= (OTHERS => '0');
END ARCHITECTURE behav;


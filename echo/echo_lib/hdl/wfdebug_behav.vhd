--
-- VHDL Architecture echo_lib.wfdebug.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-116.ad.liu.se)
--          at - 17:01:03 10/30/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY wfdebug IS
   PORT( 
      c0                : IN     STD_LOGIC;
      data_valid        : OUT    std_logic;
      left_channel_out  : OUT    std_logic_vector (15 DOWNTO 0);
      right_channel_out : OUT    std_logic_vector (15 DOWNTO 0)
   );

-- Declarations

END wfdebug ;

--
ARCHITECTURE behav OF wfdebug IS
  SIGNAL wave_val : SIGNED(15 DOWNTO 0) := (OTHERS => '0');
  SIGNAL direction : std_logic := '0';
  SIGNAL counter : INTEGER RANGE 0 TO 32 := 0;
  SIGNAL dv : STD_LOGIC := '0';
BEGIN
  
  PROCESS(c0)
  BEGIN
    IF RISING_EDGE(c0) THEN
      IF direction = '0' THEN
        wave_val <= wave_val + 2;
        IF wave_val > 32000 THEN
          direction <= '1';
        END IF;
      ELSE
        wave_val <= wave_val - 2;
        IF wave_val < -32000 THEN
          direction <= '1';
        END IF;
      END IF;
      IF counter = 32 THEN
        dv <= not dv;
        counter <= 0;
      ELSE
        counter <= counter + 1;
      END IF;
    END IF;
  END PROCESS;
  
  left_channel_out <= STD_LOGIC_VECTOR(wave_val);
  right_channel_out <= STD_LOGIC_VECTOR(wave_val);
  data_valid <= dv;
END ARCHITECTURE behav;


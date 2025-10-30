--
-- VHDL Architecture echo_lib.i2s_debug.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-116.ad.liu.se)
--          at - 16:00:48 10/30/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY i2s_debug IS
   PORT( 
      AUD_ADCDAT    : IN     std_logic;
      AUD_BCLK      : IN     std_logic;
      AUD_DACLRCK   : IN     std_logic;
      reduced_clock : IN     std_logic;
      audio_debug_1 : OUT    std_logic_vector (7 DOWNTO 0);
      audio_debug_2 : OUT    std_logic_vector (7 DOWNTO 0)
   );

-- Declarations

END i2s_debug ;

--
ARCHITECTURE behav OF i2s_debug IS
  SIGNAL shift_register : std_logic_vector(15 DOWNTO 0);
  SIGNAL active : std_logic;
  SIGNAL bit_counter : INTEGER RANGE 0 TO 16;
  SIGNAL prev_lrclk : std_logic;
BEGIN
  audio_debug_1 <= shift_register(15 DOWNTO 8);
  audio_debug_2 <= shift_register(7 DOWNTO 0);
  
  PROCESS(AUD_BCLK)
  BEGIN
    IF RISING_EDGE(AUD_BCLK) THEN
      IF reduced_clock = '1' AND active = '0' AND AUD_DACLRCK /= prev_lrclk THEN
        prev_lrclk <= AUD_DACLRCK;
        active <= '1';
        bit_counter <= 0;
      END IF;
      IF active = '1' THEN
        IF bit_counter = 16 THEN
          active <= '0';
        ELSE
          shift_register <= shift_register(14 DOWNTO 0) & AUD_ADCDAT;
          bit_counter <= bit_counter + 1;
        END IF;
      END IF;
    END IF;
  END PROCESS;
END ARCHITECTURE behav;


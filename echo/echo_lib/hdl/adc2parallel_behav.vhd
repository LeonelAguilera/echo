--
-- VHDL Architecture echo_lib.adc2parallel.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-116.ad.liu.se)
--          at - 18:28:04 10/30/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY adc2parallel IS
   PORT( 
      AUD_ADCDAT     : IN     std_logic;
      c0             : IN     STD_LOGIC;
      fpga_reset     : IN     std_logic;
      audio_in_left  : OUT    std_logic_vector (15 DOWNTO 0);
      audio_in_right : OUT    std_logic_vector (15 DOWNTO 0);
      in_valid       : OUT    std_logic;
      AUD_XCK        : IN     std_logic;
      AUD_BCLK       : IN     std_logic;
      AUD_ADCLRCK    : OUT    std_logic
   );

-- Declarations

END adc2parallel ;

--
ARCHITECTURE behav OF adc2parallel IS
  
  TYPE dps_state IS (lrc, left_channel, right_channel, waiting);
  --TYPE dps_state IS (left_channel, right_channel, waiting);
  SIGNAL curr_state : dps_state;
  
  SIGNAL shift_register : STD_LOGIC_VECTOR(15 DOWNTO 0);
  
  SIGNAL last_aud_bclk : STD_LOGIC;
  SIGNAL last_aud_xck : STD_LOGIC;
  
  SIGNAL sampling_frequency_counter : INTEGER RANGE 0 TO 255;
BEGIN
  PROCESS(c0, fpga_reset)
    VARIABLE bit_counter : INTEGER RANGE 0 TO 15;
  BEGIN
    IF fpga_reset = '0' THEN
      shift_register <= (OTHERS => '0');
      audio_in_left  <= (OTHERS => '0');
      audio_in_right <= (OTHERS => '0');
      last_aud_bclk <= '0';
      AUD_ADCLRCK <= '0';
      bit_counter := 15;
      curr_state <= lrc;
      sampling_frequency_counter <= 255;
      
    ELSIF RISING_EDGE(c0) THEN
      last_aud_bclk <= AUD_BCLK;
      last_aud_xck <= AUD_XCK;
      
      IF AUD_BCLK = '0' AND last_aud_bclk = '1' THEN
        CASE curr_state IS
          WHEN lrc =>
            AUD_ADCLRCK <= '1';
            curr_state <= left_channel;
            in_valid <= '0';
          WHEN left_channel =>
            AUD_ADCLRCK <= '0';
            shift_register(bit_counter) <= AUD_ADCDAT;
            IF bit_counter = 0 THEN
              bit_counter := 15;
              curr_state <= right_channel;
            ELSE
              bit_counter := bit_counter - 1;
            END IF;
          WHEN right_channel =>
            AUD_ADCLRCK <= '0';
            shift_register(bit_counter) <= AUD_ADCDAT;
            IF bit_counter = 0 THEN
              bit_counter := 15;
              curr_state <= waiting;
            ELSE
              IF bit_counter = 15 THEN
                audio_in_left <= shift_register;
              END IF;
              bit_counter := bit_counter - 1;
            END IF;
          WHEN waiting =>
            audio_in_right <= shift_register;
            in_valid <= '1';
--            IF AUD_ADCLRCK = '1' THEN
--              curr_state <= left_channel;
--            END IF;
        END CASE;
      END IF;
      
      IF AUD_XCK = '1' AND last_aud_xck = '0' THEN
        IF sampling_frequency_counter = 0 THEN
          sampling_frequency_counter <= 255;
          curr_state <= lrc;
        ELSE
          sampling_frequency_counter <= sampling_frequency_counter - 1;
        END IF;
      END IF;
    END IF;
  END PROCESS;
END ARCHITECTURE behav;


--
-- VHDL Architecture echo_lib.parallel2dac.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-116.ad.liu.se)
--          at - 18:45:52 10/30/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY parallel2dac IS
   PORT( 
      AUD_BCLK          : IN     std_logic;
      AUD_XCK           : IN     std_logic;
      c0                : IN     STD_LOGIC;
      data_valid        : IN     std_logic;
      fpga_reset        : IN     std_logic;
      left_channel_out  : IN     std_logic_vector (15 DOWNTO 0);
      right_channel_out : IN     std_logic_vector (15 DOWNTO 0);
      AUD_DACDAT        : OUT    std_logic;
      AUD_DACLRCK       : OUT    std_logic
   );

-- Declarations

END parallel2dac ;

--
ARCHITECTURE behav OF parallel2dac IS
  
  TYPE dps_state IS (lrc, left_channel, right_channel, waiting);
--  TYPE dps_state IS (left_channel, right_channel, waiting);
  SIGNAL curr_state : dps_state;
  
  SIGNAL shift_register : STD_LOGIC_VECTOR(15 DOWNTO 0);
  
  SIGNAL last_aud_bclk : STD_LOGIC;
  SIGNAL last_aud_xck : STD_LOGIC;
  SIGNAL last_data_valid : STD_LOGIC;
  
  SIGNAL sampling_frequency_counter : INTEGER RANGE 0 TO 255;
  
  SIGNAL left_channel_out_s : STD_LOGIC_VECTOR(15 DOWNTO 0);
  SIGNAL right_channel_out_s : STD_LOGIC_VECTOR(15 DOWNTO 0);
  
BEGIN
  PROCESS(c0, fpga_reset)
    VARIABLE bit_counter : INTEGER RANGE 0 TO 15;
  BEGIN
    IF fpga_reset = '0' THEN
      shift_register <= (OTHERS => '0');
      last_aud_bclk <= '0';
      AUD_DACLRCK <= '0';
      bit_counter := 15;
      curr_state <= lrc;
      sampling_frequency_counter <= 255;
      
    ELSIF RISING_EDGE(c0) THEN
      last_aud_bclk <= AUD_BCLK;
      last_aud_xck <= AUD_XCK;
      last_data_valid <= data_valid;
      
      IF AUD_BCLK = '0' AND last_aud_bclk = '1' THEN
        CASE curr_state IS
          WHEN lrc =>
            AUD_DACLRCK <= '1';
            curr_state <= left_channel;
            shift_register <= left_channel_out_s;
          WHEN left_channel =>
            AUD_DACLRCK <= '0';
            AUD_DACDAT <= shift_register(bit_counter);
            IF bit_counter = 0 THEN
              bit_counter := 15;
              shift_register <= right_channel_out_s;
              curr_state <= right_channel;
            ELSE
              bit_counter := bit_counter - 1;
            END IF;
          WHEN right_channel =>
            AUD_DACLRCK <= '0';
            AUD_DACDAT <= shift_register(bit_counter);
            IF bit_counter = 0 THEN
              bit_counter := 15;
              curr_state <= waiting;
            ELSE
              bit_counter := bit_counter - 1;
            END IF;
          WHEN waiting =>
            bit_counter := 15;
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
    
      IF data_valid = '1' AND last_data_valid = '0' THEN
        left_channel_out_s <= left_channel_out;
        right_channel_out_s <= right_channel_out;      
      END IF;
    END IF;
  END PROCESS;
END ARCHITECTURE behav;




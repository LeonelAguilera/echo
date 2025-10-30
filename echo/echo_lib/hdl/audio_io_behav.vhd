--
-- VHDL Architecture echo_lib.audio_io.behav
--
-- Created:
--          by - ramku837.student-liu.se (muxen1-101.ad.liu.se)
--          at - 10:10:15 10/13/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--


--------------------------------------------------------------------------------
-- Audio In/Out Module with I2S Interface for WM8731 Codec
-- Description: Converts serial I2S audio data to/from parallel format
-- WM8731 Configuration: MASTER MODE (codec generates BCLK and LRCLK)
-- Sample Rate: 44.1 kHz
-- FPGA Clock: 65 MHz
-- Data Width: 16 bits per channel
-- MCLK: Provided externally from PLL
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity audio_io is
    Port (
        -- System Clock and Reset
        clk         : in  std_logic;        -- Main system clock (e.g., 12.288MHz)
        reset_n     : in  std_logic;        -- Active low reset
        
        -- WM8731 Audio Interface (I2S)
        bclk        : in  std_logic;        -- Bit clock (64*fs)
        adc_lrc     : in  std_logic;        -- ADC left/right clock (fs)
        dac_lrc     : in  std_logic;        -- DAC left/right clock (fs)
        adc_dat     : in  std_logic;        -- ADC serial data input from codec
        dac_dat     : out std_logic;        -- DAC serial data output to codec
        
        -- Audio Data Interface
        left_channel_out  : in  std_logic_vector(15 downto 0);  -- Parallel data to DAC
        right_channel_out : in  std_logic_vector(15 downto 0);  -- Parallel data to DAC
        left_channel_in   : out std_logic_vector(15 downto 0);  -- Parallel data from ADC
        right_channel_in  : out std_logic_vector(15 downto 0);  -- Parallel data from ADC
        data_ready        : out std_logic   -- New ADC data available
    );
end audio_io;

architecture Behavioral of audio_io is

    -- DAC Transmission signals
    signal dac_shift_reg      : std_logic_vector(15 downto 0) := (others => '0');
    signal dac_bit_counter    : integer range 0 to 16 := 0;
    signal prev_dac_lrc       : std_logic := '0';
    
    -- ADC Reception signals  
    signal adc_shift_reg      : std_logic_vector(15 downto 0) := (others => '0');
    signal adc_bit_counter    : integer range 0 to 16 := 0;
    signal prev_adc_lrc       : std_logic := '0';

begin

    -- DAC Parallel-to-Serial Conversion Process
    -- Converts parallel audio data to I2S serial format for transmission to codec
    dac_parallel_to_serial : process(bclk, reset_n)
    begin
        if reset_n = '0' then
            dac_dat <= '0';
            dac_shift_reg <= (others => '0');
            dac_bit_counter <= 0;
            prev_dac_lrc <= '0';
            
        elsif falling_edge(bclk) then
            -- Detect DAC LRC (frame sync) transition
            if dac_lrc /= prev_dac_lrc then
                prev_dac_lrc <= dac_lrc;
                dac_bit_counter <= 0;
                
                -- Load new parallel data based on channel
                if dac_lrc = '0' then
                    dac_shift_reg <= left_channel_out;
                    dac_dat <= left_channel_out(15);  -- Output MSB of NEW data
                else
                    dac_shift_reg <= right_channel_out;
                    dac_dat <= right_channel_out(15);  -- Output MSB of NEW data
                end if;
                
            else
                -- Continue shifting out data
                if dac_bit_counter < 15 then
                    dac_bit_counter <= dac_bit_counter + 1;
                    -- Shift and output next bit
                    dac_shift_reg <= dac_shift_reg(14 downto 0) & '0';
                    dac_dat <= dac_shift_reg(15);  -- Output MSB after shift
                else
                    -- All 16 bits transmitted
                    dac_bit_counter <= dac_bit_counter + 1;
                    dac_dat <= '0';
                end if;
            end if;
        end if;
    end process;

    -- ADC Serial-to-Parallel Conversion Process
    -- Converts I2S serial data from codec to parallel audio data
    adc_serial_to_parallel : process(bclk, reset_n)
    begin
        if reset_n = '0' then
            left_channel_in <= (others => '0');
            right_channel_in <= (others => '0');
            adc_shift_reg <= (others => '0');
            adc_bit_counter <= 0;
            prev_adc_lrc <= '0';
            data_ready <= '0';
            
        elsif rising_edge(bclk) then
            data_ready <= '0';  -- Default: clear pulse
            
            -- Detect ADC LRC (frame sync) transition
            if adc_lrc /= prev_adc_lrc then
                prev_adc_lrc <= adc_lrc;
                
                -- Store completed word from previous frame
                if adc_bit_counter = 16 then
                    if prev_adc_lrc = '0' then
                        -- Just finished left channel
                        left_channel_in <= adc_shift_reg;
                    else
                        -- Just finished right channel
                        right_channel_in <= adc_shift_reg;
                        data_ready <= '1';  -- Both channels complete
                    end if;
                end if;
                
                -- Start new channel
                adc_bit_counter <= 0;
                adc_shift_reg <= (others => '0');
                
            else
                -- Shift in data bits
                if adc_bit_counter < 16 then
                    adc_bit_counter <= adc_bit_counter + 1;
                    adc_shift_reg <= adc_shift_reg(14 downto 0) & adc_dat;
                end if;
            end if;
        end if;
    end process;

end Behavioral;




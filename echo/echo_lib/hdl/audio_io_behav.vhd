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
-- Audio In/Out Module with I2S Interface
-- Description: Converts serial I2S audio data to/from parallel format
-- Sample Rate: 44.1 kHz
-- FPGA Clock: 65 MHz
-- Data Width: 16 bits per channel
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity audio_io is
    Port (
        -- System Clock and Reset
        clk         : in  std_logic;        -- 65 MHz FPGA clock
        reset_n     : in  std_logic;        -- Active low reset
        
        -- WM8731 Audio Interface (I2S)
        bclk        : in  std_logic;        -- Bit clock (64*fs)
        adc_lrc     : in  std_logic;        -- ADC left/right clock (fs)
        dac_lrc     : in  std_logic;        -- DAC left/right clock (fs)
        adc_dat     : in  std_logic;        -- Serial data input from WM8731 (ADC)
        dac_dat     : out std_logic;        -- Serial data output to WM8731 (DAC)
        
        -- Master Clock output to WM8731
        mclk        : out std_logic;        -- Generated master clock ~12.288 MHz
        
        -- Audio Data Interface
        left_channel_out  : in  std_logic_vector(15 downto 0);  -- Parallel data to DAC
        right_channel_out : in  std_logic_vector(15 downto 0);  -- Parallel data to DAC
        left_channel_in   : out std_logic_vector(15 downto 0);  -- Parallel data from ADC
        right_channel_in  : out std_logic_vector(15 downto 0);  -- Parallel data from ADC
        data_ready        : out std_logic;                      -- New ADC data available
        data_valid        : in  std_logic                       -- New DAC data available
    );
end audio_io;

architecture Behavioral of audio_io is

    --------------------------------------------------------------------
    -- Internal MCLK Generator (Fractional Counter Method)
    -- Produces ~12.288 MHz from 65 MHz input by alternating /5 and /6
    --------------------------------------------------------------------
    signal mclk_reg     : std_logic := '0';
    signal counter      : integer range 0 to 6 := 0;
    signal divider_sel  : integer := 5;
    signal pattern_pos  : integer range 0 to 5 := 0;
    constant pattern    : integer_vector := (5,6,5,6,5,5);  -- repeating pattern

    --------------------------------------------------------------------
    -- DAC Transmission signals
    --------------------------------------------------------------------
    signal dac_shift_reg   : std_logic_vector(15 downto 0) := (others => '0');
    signal dac_bit_counter : integer range 0 to 31 := 0;
    signal prev_dac_lrc    : std_logic := '0';
    signal dac_data_active : std_logic := '0';  -- indicates ongoing transmission

    --------------------------------------------------------------------
    -- ADC Reception signals
    --------------------------------------------------------------------
    signal adc_shift_reg   : std_logic_vector(15 downto 0) := (others => '0');
    signal adc_bit_counter : integer range 0 to 31 := 0;
    signal prev_adc_lrc    : std_logic := '0';
    signal adc_data_active : std_logic := '0';  -- indicates ongoing reception

begin

    --------------------------------------------------------------------
    -- Master Clock Generation: fractional divider using counters
    --------------------------------------------------------------------
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            counter     <= 0;
            divider_sel <= 5;
            mclk_reg    <= '0';
            pattern_pos <= 0;
        elsif rising_edge(clk) then
            if counter = divider_sel then
                counter <= 0;
                mclk_reg <= not mclk_reg;
                pattern_pos <= (pattern_pos + 1) mod pattern'length;
                divider_sel <= pattern(pattern_pos);
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    mclk <= mclk_reg;

    --------------------------------------------------------------------
    -- DAC: Parallel-to-Serial Conversion (I2S compliant)
    --------------------------------------------------------------------
    dac_parallel_to_serial : process(bclk, reset_n)
    begin
        if reset_n = '0' then
            dac_dat <= '0';
            dac_shift_reg <= (others => '0');
            dac_bit_counter <= 0;
            prev_dac_lrc <= '0';
            dac_data_active <= '0';
            
        elsif falling_edge(bclk) then
            -- Detect LRC transition (frame sync)
            if dac_lrc /= prev_dac_lrc then
                prev_dac_lrc <= dac_lrc;
                dac_bit_counter <= 0;
                dac_data_active <= '1';
                
                -- Load new data on LRC edge (with 1-bit delay)
                if data_valid = '1' then
                    if dac_lrc = '0' then
                        dac_shift_reg <= left_channel_out;
                    else
                        dac_shift_reg <= right_channel_out;
                    end if;
                --else
                    --dac_shift_reg <= (others => '0');
                end if;
                
            elsif dac_data_active = '1' then
                -- Output MSB first, with one-bit delay after LRC
                if dac_bit_counter = 0 then
                    dac_dat <= '0';  -- 1-bit delay (I2S spec)
                else
                    dac_dat <= dac_shift_reg(15);
                    dac_shift_reg <= dac_shift_reg(14 downto 0) & '0';
                end if;

                dac_bit_counter <= dac_bit_counter + 1;
                if dac_bit_counter = 16 then
                    dac_data_active <= '0';
                    --dac_dat <= '0';
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- ADC: Serial-to-Parallel Conversion (I2S compliant)
    --------------------------------------------------------------------
    adc_serial_to_parallel : process(bclk, reset_n)
    begin
        if reset_n = '0' then
            left_channel_in  <= (others => '0');
            right_channel_in <= (others => '0');
            adc_shift_reg    <= (others => '0');
            adc_bit_counter  <= 0;
            prev_adc_lrc     <= '0';
            data_ready       <= '0';
            adc_data_active  <= '0';
            
        elsif rising_edge(bclk) then
            data_ready <= '0';

            -- Detect LRC transition
            if adc_lrc /= prev_adc_lrc then
                prev_adc_lrc <= adc_lrc;
                adc_bit_counter <= 0;
                adc_data_active <= '1';

            elsif adc_data_active = '1' then
                -- Ignore first bit (1-bit delay)
                if adc_bit_counter > 0 then
                    adc_shift_reg <= adc_shift_reg(14 downto 0) & adc_dat;
                end if;

                adc_bit_counter <= adc_bit_counter + 1;

                -- Store received data after 16 bits
                if adc_bit_counter = 16 then
                    if adc_lrc = '0' then
                        left_channel_in <= adc_shift_reg;
                    else
                        right_channel_in <= adc_shift_reg;
                        data_ready <= '1';
                    end if;
                    adc_data_active <= '0';
                end if;
            end if;
        end if;
    end process;

end Behavioral;





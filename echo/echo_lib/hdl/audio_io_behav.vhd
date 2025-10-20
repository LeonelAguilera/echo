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
        clk         : in  std_logic;  -- 65 MHz FPGA clock
        rst         : in  std_logic;  -- Active high reset
        
                                                                                                           -- I2S Interface (WM8731 as Master)
        i2s_bclk    : in  std_logic;  -- Bit clock from WM8731 (~1.4 MHz)
        i2s_lrclk   : in  std_logic;  -- Left/Right clock from WM8731 (44.1 kHz)
        i2s_adcdat  : in  std_logic;  -- ADC serial data input (from codec ADC)
        i2s_dacdat  : out std_logic;  -- DAC serial data output (to codec DAC)
        
                                                                                                               -- Master Clock Output (to WM8731)
        mclk        : out std_logic;  -- Master clock output (~12.288 MHz or 11.2896 MHz)
          
                                                                                                                   -- Parallel Interface to Echo Module
        left_in     : out std_logic_vector(15 downto 0);  -- Left channel input from ADC
        right_in    : out std_logic_vector(15 downto 0);  -- Right channel input from ADC
        data_valid  : out std_logic;  -- New data available
        
        left_out    : in  std_logic_vector(15 downto 0);  -- Left channel output to DAC
        right_out   : in  std_logic_vector(15 downto 0);  -- Right channel output to DAC
        data_ready  : in  std_logic   -- Data ready from echo module
    );
end audio_io;

architecture Behavioral of audio_io is
    
                                                                                                        -- I2S Clock Synchronization
    signal bclk_sync    : std_logic_vector(2 downto 0) := (others => '0');
    signal lrclk_sync   : std_logic_vector(2 downto 0) := (others => '0');
    signal bclk_rise    : std_logic := '0';
    signal bclk_fall    : std_logic := '0';
    signal lrclk_prev   : std_logic := '0';
    signal lrclk_edge   : std_logic := '0';
    
                                                                                               -- ADC Receiver Signals (from codec ADC -> FPGA)
    signal adc_sr       : std_logic_vector(15 downto 0) := (others => '0');
    signal adc_cnt      : integer range 0 to 31 := 0;
    signal adc_left     : std_logic_vector(15 downto 0) := (others => '0');
    signal adc_right    : std_logic_vector(15 downto 0) := (others => '0');
    signal adc_ch       : std_logic := '0';  -- 0=Left, 1=Right
    signal adc_valid    : std_logic := '0';
    
                                                                                              -- DAC Transmitter Signals (from FPGA -> codec DAC)
    signal dac_sr       : std_logic_vector(15 downto 0) := (others => '0');
    signal dac_cnt      : integer range 0 to 31 := 0;
    signal dac_left     : std_logic_vector(15 downto 0) := (others => '0');
    signal dac_right    : std_logic_vector(15 downto 0) := (others => '0');
    signal dac_ch       : std_logic := '0';
    
                                                                                                  -- MCLK Generation
    constant MCLK_DIV   : integer := 3;  -- Divider for MCLK generation
    signal mclk_cnt     : integer range 0 to MCLK_DIV := 0;
    signal mclk_out     : std_logic := '0';
    
begin

                                                                                                           -- Output Master Clock
    mclk <= mclk_out;
    
                                                                                                  -- Output parallel data to echo module
    left_in <= adc_left;
    right_in <= adc_right;
    data_valid <= adc_valid;
    
    
    -- MCLK Generator Process
    
    process(clk, rst)
    begin
        if rst = '1' then
            mclk_cnt <= 0;
            mclk_out <= '0';
        elsif rising_edge(clk) then
            if mclk_cnt = MCLK_DIV then
                mclk_cnt <= 0;
                mclk_out <= not mclk_out;
            else
                mclk_cnt <= mclk_cnt + 1;
            end if;
        end if;
    end process;
    
    
    -- Clock Synchronization and Edge Detection
    
    process(clk, rst)
    begin
        if rst = '1' then
            bclk_sync <= (others => '0');
            lrclk_sync <= (others => '0');
            bclk_rise <= '0';
            bclk_fall <= '0';
            lrclk_prev <= '0';
            lrclk_edge <= '0';
        elsif rising_edge(clk) then
                                                                                        -- Synchronize BCLK from WM8731
            bclk_sync <= bclk_sync(1 downto 0) & i2s_bclk;
            
                                                                                       -- Synchronize LRCLK from WM8731
            lrclk_sync <= lrclk_sync(1 downto 0) & i2s_lrclk;
            
            bclk_rise <= '0';
            bclk_fall <= '0';
            if bclk_sync(2) = '0' and bclk_sync(1) = '1' then
                bclk_rise <= '1';
            elsif bclk_sync(2) = '1' and bclk_sync(1) = '0' then
                bclk_fall <= '1';
            end if;
            
                                                                                         -- Detect LRCLK edge (channel change)
            lrclk_prev <= lrclk_sync(2);
            if lrclk_sync(2) /= lrclk_prev then
                lrclk_edge <= '1';
            else
                lrclk_edge <= '0';
            end if;
        end if;
    end process;
    
    
                                                                                -- Deserializes incoming I2S ADC data into 16-bit left and right channels
    
    process(clk, rst)
    begin
        if rst = '1' then
            adc_sr <= (others => '0');
            adc_cnt <= 0;
            adc_left <= (others => '0');
            adc_right <= (others => '0');
            adc_ch <= '0';
            adc_valid <= '0';
        elsif rising_edge(clk) then
            adc_valid <= '0';
            
            if lrclk_edge = '1' then
                adc_cnt <= 0;
                adc_ch <= lrclk_sync(2);
                
                if adc_ch = '0' then
                    adc_left <= adc_sr;
                else
                    adc_right <= adc_sr;
                    adc_valid <= '1';  -- Both channels received
                end if;
                
                adc_sr <= (others => '0');
            end if;
            
            if bclk_fall = '1' then
                if adc_cnt < 16 then
                    adc_sr <= adc_sr(14 downto 0) & i2s_adcdat;
                    adc_cnt <= adc_cnt + 1;
                end if;
            end if;
        end if;
    end process;
    
    -- Captures processed audio data from echo module
    process(clk, rst)
    begin
        if rst = '1' then
            dac_left <= (others => '0');
            dac_right <= (others => '0');
        elsif rising_edge(clk) then
                                                                                                -- Update buffers when echo module has new data
            if data_ready = '1' then
                dac_left <= left_out;
                dac_right <= right_out;
            end if;
        end if;
    end process;
    
    -- Serializes 16-bit left and right channels to I2S DAC output
    process(clk, rst)
    begin
        if rst = '1' then
            dac_sr <= (others => '0');
            dac_cnt <= 0;
            dac_ch <= '0';
            i2s_dacdat <= '0';
        elsif rising_edge(clk) then
            
                                                                                       -- Detect LRCLK edge for channel change
            if lrclk_edge = '1' then
                dac_cnt <= 0;
                dac_ch <= lrclk_sync(2);
                
                                                                                         -- Load new data based on channel
                if lrclk_sync(2) = '0' then
                    dac_sr <= dac_left;
                else
                    dac_sr <= dac_right;
                end if;
            end if;
            
                                                                                          -- Shift out data on rising edge of BCLK
            if bclk_rise = '1' then
                if dac_cnt < 16 then
                    i2s_dacdat <= dac_sr(15);
                    dac_sr <= dac_sr(14 downto 0) & '0';
                    dac_cnt <= dac_cnt + 1;
                else
                    i2s_dacdat <= '0';
                end if;
            end if;
        end if;
    end process;

end Behavioral;
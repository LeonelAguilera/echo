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
-- I2S Transceiver Module (Clock Generator and Data Router)
-- For WM8731 Audio Codec
-- FPGA Clock: 65 MHz (generates all I2S clocks internally)
-- Sample Rate: 48 kHz, 16-bit stereo
--
-- WARNING: 65 MHz cannot divide evenly to standard audio clocks
-- This will generate approximate frequencies with small error
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity audio_io is
    Generic (
        FPGA_CLK_FREQ : integer := 65_000_000;  -- FPGA master clock (Hz)
        SAMPLE_RATE   : integer := 48_000;      -- Audio sample rate (Hz)
        BIT_DEPTH     : integer := 16           -- Bits per sample
    );
    Port (
        -- System Clock and Reset
        mclk          : in  STD_LOGIC;           -- 65 MHz FPGA clock
        reset_n       : in  STD_LOGIC;           -- Active low reset
        
        -- I2S Clock Outputs
        sclk          : out STD_LOGIC;           -- Serial clock (bit clock)
        ws            : out STD_LOGIC;           -- Word select (L/R clock)
        
        -- Parallel Data Interface (from User Logic)
        l_data_tx     : in  STD_LOGIC_VECTOR(BIT_DEPTH-1 downto 0);  -- Left channel TX
        r_data_tx     : in  STD_LOGIC_VECTOR(BIT_DEPTH-1 downto 0);  -- Right channel TX
        l_data_rx     : out STD_LOGIC_VECTOR(BIT_DEPTH-1 downto 0);  -- Left channel RX
        r_data_rx     : out STD_LOGIC_VECTOR(BIT_DEPTH-1 downto 0);  -- Right channel RX
        
        -- Serial Data Interface (to/from codec)
        sd_tx         : out STD_LOGIC;           -- Serial data transmit
        sd_rx         : in  STD_LOGIC            -- Serial data receive
    );
end audio_io;

architecture Behav of audio_io is

    -- Clock divider calculations
    -- Target SCLK = 48000 Hz × 16 bits × 2 channels = 1.536 MHz
    -- SCLK_DIV = 65 MHz / 1.536 MHz ? 42.3 (use 42)
    -- Actual SCLK = 65 MHz / 42 = 1.5476 MHz (0.5% error)
    -- Actual Sample Rate = 1.5476 MHz / 32 = 48.36 kHz (0.75% error)
    
    constant SCLK_TARGET  : integer := SAMPLE_RATE * BIT_DEPTH * 2;
    constant SCLK_DIV     : integer := FPGA_CLK_FREQ / SCLK_TARGET;  -- = 42
    constant WS_DIV       : integer := BIT_DEPTH * 2;  -- 32 for 16-bit stereo
    
    -- Internal clock signals
    signal sclk_int       : STD_LOGIC := '0';
    signal ws_int         : STD_LOGIC := '0';
    signal sclk_rising    : STD_LOGIC := '0';
    signal sclk_falling   : STD_LOGIC := '0';
    
    -- Clock generation counters
    signal sclk_counter   : integer range 0 to SCLK_DIV-1 := 0;
    signal ws_counter     : integer range 0 to WS_DIV-1 := 0;
    signal bit_counter    : integer range 0 to BIT_DEPTH-1 := 0;
    
    -- Transmit path registers
    signal tx_shift_reg   : STD_LOGIC_VECTOR(BIT_DEPTH-1 downto 0) := (others => '0');
    signal tx_left_buf    : STD_LOGIC_VECTOR(BIT_DEPTH-1 downto 0) := (others => '0');
    signal tx_right_buf   : STD_LOGIC_VECTOR(BIT_DEPTH-1 downto 0) := (others => '0');
    
    -- Receive path registers
    signal rx_shift_reg   : STD_LOGIC_VECTOR(BIT_DEPTH-1 downto 0) := (others => '0');
    signal rx_left_buf    : STD_LOGIC_VECTOR(BIT_DEPTH-1 downto 0) := (others => '0');
    signal rx_right_buf   : STD_LOGIC_VECTOR(BIT_DEPTH-1 downto 0) := (others => '0');
    
    -- Edge detection
    signal ws_prev        : STD_LOGIC := '0';

begin

    -- Output assignments
    sclk <= sclk_int;
    ws   <= ws_int;

    --------------------------------------------------------------------------------
    -- Serial Clock (SCLK/BCLK) Generation from 65 MHz
    -- Target SCLK = 1.536 MHz (for 48 kHz, 16-bit stereo)
    -- SCLK_DIV = 65 MHz / 1.536 MHz ? 42
    -- Actual SCLK = 65 MHz / 42 = 1.5476 MHz (small 0.5% error)
    --------------------------------------------------------------------------------
    process(mclk, reset_n)
    begin
        if reset_n = '0' then
            sclk_counter <= 0;
            sclk_int     <= '0';
            sclk_rising  <= '0';
            sclk_falling <= '0';
        elsif rising_edge(mclk) then
            sclk_rising  <= '0';
            sclk_falling <= '0';
            
            if sclk_counter = SCLK_DIV-1 then
                sclk_counter <= 0;
                sclk_int     <= not sclk_int;
                
                if sclk_int = '0' then
                    sclk_rising <= '1';
                else
                    sclk_falling <= '1';
                end if;
            else
                sclk_counter <= sclk_counter + 1;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------------
    -- Word Select (WS) Generation
    -- WS = SCLK / (BIT_DEPTH × 2)
    -- WS = 0 for Left channel, WS = 1 for Right channel
    -- WS frequency ? Sample Rate (48 kHz with small error)
    --------------------------------------------------------------------------------
    process(mclk, reset_n)
    begin
        if reset_n = '0' then
            ws_counter  <= 0;
            ws_int      <= '0';
            bit_counter <= 0;
        elsif rising_edge(mclk) then
            if sclk_rising = '1' then
                if ws_counter = WS_DIV-1 then
                    ws_counter <= 0;
                    ws_int     <= not ws_int;
                else
                    ws_counter <= ws_counter + 1;
                end if;
                
                -- Bit position counter within each channel
                if bit_counter = BIT_DEPTH-1 then
                    bit_counter <= 0;
                else
                    bit_counter <= bit_counter + 1;
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------------
    -- Transmit Path (Parallel to Serial Conversion)
    -- Load parallel data when WS changes
    -- Shift out serial data on SCLK falling edge (MSB first)
    --------------------------------------------------------------------------------
    process(mclk, reset_n)
    begin
        if reset_n = '0' then
            tx_shift_reg <= (others => '0');
            tx_left_buf  <= (others => '0');
            tx_right_buf <= (others => '0');
            sd_tx        <= '0';
            ws_prev      <= '0';
        elsif rising_edge(mclk) then
            ws_prev <= ws_int;
            
            -- Detect WS edge to load new data
            if ws_int /= ws_prev then
                if ws_int = '0' then
                    -- Load left channel data
                    tx_shift_reg <= tx_left_buf;
                    tx_left_buf  <= l_data_tx;
                else
                    -- Load right channel data
                    tx_shift_reg <= tx_right_buf;
                    tx_right_buf <= r_data_tx;
                end if;
            elsif sclk_falling = '1' then
                -- Shift out MSB on SCLK falling edge
                sd_tx <= tx_shift_reg(BIT_DEPTH-1);
                tx_shift_reg <= tx_shift_reg(BIT_DEPTH-2 downto 0) & '0';
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------------
    -- Receive Path (Serial to Parallel Conversion)
    -- Sample serial data on SCLK rising edge
    -- Output complete samples when full word received
    --------------------------------------------------------------------------------
    process(mclk, reset_n)
    begin
        if reset_n = '0' then
            rx_shift_reg <= (others => '0');
            rx_left_buf  <= (others => '0');
            rx_right_buf <= (others => '0');
            l_data_rx    <= (others => '0');
            r_data_rx    <= (others => '0');
        elsif rising_edge(mclk) then
            if sclk_rising = '1' then
                -- Shift in data on SCLK rising edge (MSB first)
                rx_shift_reg <= rx_shift_reg(BIT_DEPTH-2 downto 0) & sd_rx;
                
                -- When all bits received, store complete sample
                if bit_counter = BIT_DEPTH-1 then
                    if ws_int = '0' then
                        -- Left channel complete
                        rx_left_buf <= rx_shift_reg(BIT_DEPTH-2 downto 0) & sd_rx;
                        l_data_rx   <= rx_left_buf;
                    else
                        -- Right channel complete
                        rx_right_buf <= rx_shift_reg(BIT_DEPTH-2 downto 0) & sd_rx;
                        r_data_rx    <= rx_right_buf;
                    end if;
                end if;
            end if;
        end if;
    end process;

end architecture Behav;


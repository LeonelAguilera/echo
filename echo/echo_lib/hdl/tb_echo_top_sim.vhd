--
-- VHDL Architecture echo_lib.tb_echo_top.sim
--
-- Created:
--          by - antmo328.student-liu.se (muxen2-112.ad.liu.se)
--          at - 13:02:49 10/10/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_echo_top is
end entity;

architecture sim of tb_echo_top is
  constant CLK_PERIOD : time := 22.6757 us / 1000.0;  -- ~44.1 kHz

  -- Clock / Reset
  signal clk, reset_n : std_logic := '0';

  -- Audio I/O
  signal in_valid, in_ready, out_valid : std_logic := '0';
  signal in_L, in_R, out_L, out_R : std_logic_vector(15 downto 0);

  -- Steuerung
  signal delay_samples  : unsigned(18 downto 0) := to_unsigned(22050, 19); -- 0.5 s delay
  signal g_feedback_q15 : std_logic_vector(15 downto 0) := x"4000";       -- 0.5 gain

  -- SRAM-Interface (zwischen Echo und Controller)
  signal wr_en, rd_en : std_logic;
  signal wr_addr, rd_addr : std_logic_vector(19 downto 0);
  signal wr_data, rd_data : std_logic_vector(15 downto 0);
  signal rd_valid : std_logic;

  -- Physikalische SRAM-Pins
  signal SRAM_ADDR  : std_logic_vector(19 downto 0);  -- 20 Bit Bus intern
  signal SRAM_DQ    : std_logic_vector(15 downto 0);
  signal SRAM_CE_N  : std_logic;
  signal SRAM_OE_N  : std_logic;
  signal SRAM_WE_N  : std_logic;
  signal SRAM_UB_N  : std_logic;
  signal SRAM_LB_N  : std_logic;

begin
  -------------------------------------------------------------------------
  -- Clock
  -------------------------------------------------------------------------
  clk <= not clk after CLK_PERIOD/2;

  -------------------------------------------------------------------------
  -- DUT 1: Echo Logic
  -------------------------------------------------------------------------
  u_echo: entity work.echo_logic
    port map (
      clk             => clk,
      RESET_N         => reset_n,
      audio_in_L      => in_L,
      audio_in_R      => in_R,
      audio_in_valid  => in_valid,
      audio_in_ready  => in_ready,
      audio_out_L     => out_L,
      audio_out_R     => out_R,
      audio_out_valid => out_valid,
      delay_samples   => delay_samples,
      g_feedback_q15  => g_feedback_q15,
      wr_en           => wr_en,
      wr_addr         => wr_addr,
      wr_data         => wr_data,
      rd_en           => rd_en,
      rd_addr         => rd_addr,
      rd_data         => rd_data,
      rd_valid        => rd_valid
    );

  -------------------------------------------------------------------------
  -- DUT 2: SRAM-Controller
  -------------------------------------------------------------------------
  u_ctrl: entity work.sram_ctrl
    port map (
      clk        => clk,
      RESET_N    => reset_n,
      wr_en      => wr_en,
      wr_addr    => wr_addr,
      wr_data    => wr_data,
      rd_en      => rd_en,
      rd_addr    => rd_addr,
      rd_data    => rd_data,
      rd_valid   => rd_valid,
      SRAM_ADDR  => SRAM_ADDR,
      SRAM_DQ    => SRAM_DQ,
      SRAM_CE_N  => SRAM_CE_N,
      SRAM_OE_N  => SRAM_OE_N,
      SRAM_WE_N  => SRAM_WE_N,
      SRAM_UB_N  => SRAM_UB_N,
      SRAM_LB_N  => SRAM_LB_N
    );

  -------------------------------------------------------------------------
  -- DUT 3: Asynchrones SRAM-Model (19 Bit Adress)
  -------------------------------------------------------------------------
  u_sram: entity work.SRAM_Async_Model
    port map (
      ADDR  => SRAM_ADDR(19 downto 0),  -- truncate to 19 Bit
      DQ    => SRAM_DQ,
      CE_N  => SRAM_CE_N,
      OE_N  => SRAM_OE_N,
      WE_N  => SRAM_WE_N,
      UB_N  => SRAM_UB_N,
      LB_N  => SRAM_LB_N
    );

  -------------------------------------------------------------------------
  -- Stimulus: einfacher Impulstest
  -------------------------------------------------------------------------
 
stim : process
  constant SAMPLE_RATE_HZ : integer := 44100;
  constant DURATION_S     : real := 0.5;  -- 500 ms Testsignal
  constant TOTAL_SAMPLES  : integer := 22050;
  constant AMP            : integer := 30000;  -- Amplitude für Testsignal (max. 32767)
  variable sample_val     : integer := 0;
begin
  -- Resetphase
  reset_n <= '0';
  in_valid <= '0';
  in_L <= (others => '0');
  in_R <= (others => '0');
  wait for 200 ns;
  reset_n <= '1';
  wait for 200 ns;

  report "Start ECHO Langzeit-Test (500 ms Muster)" severity note;

  ---------------------------------------------------------------------
  -- Phase 1: 500 ms Pseudo-Testsignal (z. B. Rampenform)
  ---------------------------------------------------------------------
  for i in 0 to TOTAL_SAMPLES-1 loop
    if in_ready = '1' then
      in_valid <= '1';

      -- einfache Pseudo-Wellenform: Sägezahn / Rampenform
      if (i mod 200) < 100 then
        sample_val := ( (i * AMP) / 100 ) mod (2 * AMP) - AMP;
      else
        sample_val := AMP - ( (i * AMP) / 100 ) mod (2 * AMP);
      end if;

      -- Linker & rechter Kanal leicht unterschiedlich
      in_L <= std_logic_vector(to_signed(sample_val, 16));
      in_R <= std_logic_vector(to_signed(-sample_val / 2, 16));
    else
      in_valid <= '0';
    end if;

    wait until rising_edge(clk);
  end loop;

  ---------------------------------------------------------------------
  -- Phase 2: 0.5 s Stille (Echoausklang sichtbar)
  ---------------------------------------------------------------------
  report "Testsignal beendet ? jetzt Stille (Echoausklang)" severity note;
  for i in 0 to SAMPLE_RATE_HZ / 2 loop
    if in_ready = '1' then
      in_valid <= '1';
      in_L <= (others => '0');
      in_R <= (others => '0');
    else
      in_valid <= '0';
    end if;
    wait until rising_edge(clk);
  end loop;

  ---------------------------------------------------------------------
  -- Simulation Ende
  ---------------------------------------------------------------------
  in_valid <= '0';
  report "Echo-Logic Test vollständig beendet" severity note;
   -- std.env.stop;
end process;


end architecture;

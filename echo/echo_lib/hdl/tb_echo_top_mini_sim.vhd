library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_echo_top_mini is end;
architecture sim of tb_echo_top_mini is
  constant C_ADDR_W : natural := 19;             -- 512K x 16
  constant C_DATA_W : natural := 16;
  constant TCLK     : time    := 15.3846 ns;     -- 65 MHz

  signal clk, reset_n : std_logic := '0';

  -- Echo I/F
  signal audio_in_L, audio_in_R   : std_logic_vector(15 downto 0) := (others=>'0');
  signal audio_out_L, audio_out_R : std_logic_vector(15 downto 0);
  signal audio_in_ready           : std_logic;
  signal audio_in_valid           : std_logic := '0';
  signal audio_out_valid          : std_logic;

  signal echo_disable             : std_logic := '0';
  signal g_feedback_q15           : std_logic_vector(15 downto 0) := x"2000"; -- ~0.25
  signal delay_samples            : std_logic_vector(18 downto 0);

  -- Echo?SRAM Ctrl
  signal wr_en, rd_en             : std_logic;
  signal wr_addr, rd_addr         : std_logic_vector(C_ADDR_W-1 downto 0);
  signal wr_data, rd_data         : std_logic_vector(15 downto 0);
  signal rd_valid                 : std_logic;

  -- SRAM Pins
  signal SRAM_ADDR                : std_logic_vector(C_ADDR_W-1 downto 0);
  signal SRAM_DQ                  : std_logic_vector(15 downto 0);
  signal SRAM_CE_N, SRAM_OE_N     : std_logic;
  signal SRAM_WE_N, SRAM_UB_N     : std_logic;
  signal SRAM_LB_N                : std_logic;

  -- Debug-Helfer
  signal any_read_seen  : boolean := false;
  signal any_write_seen : boolean := false;
begin
  -- 65 MHz
  clk <= not clk after TCLK/2;

  -- Reset
  process
  begin
    reset_n <= '0';
    wait for 8*TCLK;
    reset_n <= '1';
    wait;
  end process;

  -- DUTs
  u_echo : entity work.echo_logic
    generic map ( G_ADDR_WIDTH => C_ADDR_W, G_DATA_WIDTH => C_DATA_W )
    port map (
      clk             => clk,
      reset_n         => reset_n,
      audio_in_L      => audio_in_L,
      audio_in_R      => audio_in_R,
      audio_out_L     => audio_out_L,
      audio_out_R     => audio_out_R,
      audio_in_ready  => audio_in_ready,
      audio_in_valid  => audio_in_valid,
      audio_out_valid => audio_out_valid,
      wr_en           => wr_en,
      wr_addr         => wr_addr,
      wr_data         => wr_data,
      rd_en           => rd_en,
      rd_addr         => rd_addr,
      rd_valid        => rd_valid,
      rd_data         => rd_data,
      echo_disable    => echo_disable,
      g_feedback_q15  => g_feedback_q15,
      delay_samples   => delay_samples
    );

  u_ctrl : entity work.sram_ctrl
    generic map ( G_ADDR_WIDTH => C_ADDR_W, G_DATA_WIDTH => C_DATA_W )
    port map (
      rd_valid  => rd_valid,
      SRAM_ADDR => SRAM_ADDR,
      SRAM_DQ   => SRAM_DQ,
      SRAM_CE_N => SRAM_CE_N,
      SRAM_OE_N => SRAM_OE_N,
      SRAM_WE_N => SRAM_WE_N,
      SRAM_UB_N => SRAM_UB_N,
      SRAM_LB_N => SRAM_LB_N,
      rd_addr   => rd_addr,
      rd_en     => rd_en,
      wr_en     => wr_en,
      clk       => clk,
      wr_data   => wr_data,
      wr_addr   => wr_addr,
      rd_data   => rd_data,
      RESET_N   => reset_n
    );

  u_mem : entity work.sram16_asyn
    generic map ( G_ADDR_WIDTH => C_ADDR_W )
    port map (
      A    => SRAM_ADDR,
      DQ   => SRAM_DQ,
      CE_N => SRAM_CE_N,
      OE_N => SRAM_OE_N,
      WE_N => SRAM_WE_N,
      UB_N => SRAM_UB_N,
      LB_N => SRAM_LB_N
    );

  --------------------------------------------------------------------
  -- Stimuli: viele Frames, sauberer Handshake, kleine Delay
  --------------------------------------------------------------------
  process
    variable sample : integer := 0;
  begin
    wait until reset_n='1';
    wait for 3*TCLK;

    -- *** WICHTIG: Kleine, aber >0 Delay -> liest frühere, bereits geschriebene Frames
    delay_samples <= std_logic_vector(to_unsigned(2, delay_samples'length)); -- 2 Samples -> 4 Worte

    -- 128 Frames einspeisen (genug, damit Reads != 0 werden)
    for n in 0 to 400000 loop
      -- Warte bis echo bereit ist
      wait until rising_edge(clk) and audio_in_ready='1';

      sample := n * 100; -- einfaches Rampen-Signal
      audio_in_L <= std_logic_vector(to_signed( sample, 16));
      audio_in_R <= std_logic_vector(to_signed(-sample, 16));

      -- Gültigkeit exakt 1 Takt (während ready='1')
      audio_in_valid <= '1';
      wait until rising_edge(clk);
      audio_in_valid <= '0';

      -- optional etwas Luft
      wait for 1*TCLK;
    end loop;

    wait for 50*TCLK;

    -- Sanity-Checks
    assert any_write_seen report "Kein WRITE-Zyklus gesehen (SRAM_WE_N nie 0)!" severity failure;
    assert any_read_seen  report "Kein READ-Zyklus gesehen (SRAM_OE_N nie 0)!" severity failure;

    report "TB done." severity note;
    std.env.stop;
    wait;
  end process;

  --------------------------------------------------------------------
  -- Debug-Monitore: zeigen dir in Transcript an, was auf dem Bus passiert
  --------------------------------------------------------------------
  monitor_we: process(clk)
  begin
    if rising_edge(clk) then
      if SRAM_WE_N = '0' then
        any_write_seen <= true;
        report "WRITE  @A=" & integer'image(to_integer(unsigned(SRAM_ADDR)))
             & " D=" & to_hstring(SRAM_DQ);
      end if;
    end if;
  end process;

  monitor_oe: process(clk)
  begin
    if rising_edge(clk) then
      if SRAM_OE_N = '0' then
        any_read_seen <= true;
        report "READ   @A=" & integer'image(to_integer(unsigned(SRAM_ADDR)))
             & " D=" & to_hstring(SRAM_DQ)
             & " (rd_valid=" & std_logic'image(rd_valid) & ")";
      end if;
      if rd_valid = '1' then
        report "RD_OK  data=" & to_hstring(rd_data);
      end if;
    end if;
  end process;

end architecture;

-- ============================================================================
-- Testbench: tb_echo_system
-- - 65 MHz
-- - Impuls1: 2000 ns an @ t=0
-- - Pause bis t=450000 ns (nur 0-Frames)
-- - Impuls2: 2000 ns an @ t=450000 ns
-- - Delay = 2000 ns, Gain = 0.5
-- - Kompatibel zu: echo_logic, sram_ctrl, sram16_asyn, kb_block
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_echo_system is
end entity;

architecture sim of tb_echo_system is
  -- ===== Designbreiten (ggf. anpassen) =====
  constant C_ADDR_W : natural := 20;
  constant C_DATA_W : natural := 16;

  -- ===== Zeit-/Stimulus-Parameter =====
  constant TCLK            : time := 15.3846 ns;  -- 65 MHz
  constant ON_NS           : time := 2000 ns;     -- Impulsbreite
  constant SECOND_START_NS : time := 45000 ns;   -- Startzeit Impuls 2
  constant TAIL_NS         : time := 2 ms;        -- Nachlauf für Echos

  -- Echo-Parameter
  constant DELAY_NS        : time := 2000 ns;     -- Delay-Zeit
  constant G_Q15           : std_logic_vector(15 downto 0) := x"4000"; -- 0.5

  -- ===== Takt/Reset =====
  signal clk     : std_logic := '0';
  signal reset_n : std_logic := '0';

  -- ===== Audio I/F =====
  signal audio_in_L,  audio_in_R  : std_logic_vector(15 downto 0) := (others => '0');
  signal audio_out_L, audio_out_R : std_logic_vector(15 downto 0);
  signal audio_in_ready           : std_logic;
  signal audio_in_valid           : std_logic := '0';
  signal audio_out_valid          : std_logic;

  -- ===== Echo-Parameter (aus TB gesetzt) =====
  signal echo_disable   : std_logic := '0';
  signal g_feedback_q15 : std_logic_vector(15 downto 0) := G_Q15;
  signal delay_samples  : std_logic_vector(18 downto 0);

  -- ===== Echo <-> SRAM Ctrl =====
  signal wr_en, rd_en     : std_logic;
  signal wr_addr, rd_addr : std_logic_vector(C_ADDR_W-1 downto 0);
  signal wr_data, rd_data : std_logic_vector(15 downto 0);
  signal rd_valid         : std_logic;

  -- ===== Externes SRAM-IF =====
  signal SRAM_ADDR : std_logic_vector(C_ADDR_W-1 downto 0);
  signal SRAM_DQ   : std_logic_vector(15 downto 0);
  signal SRAM_CE_N, SRAM_OE_N, SRAM_WE_N, SRAM_UB_N, SRAM_LB_N : std_logic;

  -- ===== Keyboard-Block (Eingänge = 0) =====
  signal KB_SCAN_VALID : std_logic := '0';
  signal KB_SCAN_CODE  : std_logic := '0';
  signal ctrl_sig      : std_logic_vector(5 downto 0);

  -- ===== Helper: Zeiten ? Frames (runden) =====
  function time_to_frames(t : time; Tclk : time) return natural is
  begin
    return integer( (t + Tclk/2) / Tclk );
  end function;

  -- ===== 1 Frame mit Handshake pushen =====
  procedure push_one_frame(
    signal clk_i            : in  std_logic;
    signal audio_in_ready_i : in  std_logic;
    signal audio_in_L_i     : out std_logic_vector(15 downto 0);
    signal audio_in_R_i     : out std_logic_vector(15 downto 0);
    signal audio_in_valid_i : out std_logic;
    constant valL, valR     : in  signed(15 downto 0)
  ) is
  begin
    wait until rising_edge(clk_i) and audio_in_ready_i='1';
    audio_in_L_i     <= std_logic_vector(valL);
    audio_in_R_i     <= std_logic_vector(valR);
    audio_in_valid_i <= '1';
    wait until rising_edge(clk_i);
    audio_in_valid_i <= '0';
  end procedure;

  -- ===== N Frames gleichen Werts pushen =====
  procedure push_n_frames(
    signal clk_i            : in  std_logic;
    signal audio_in_ready_i : in  std_logic;
    signal audio_in_L_i     : out std_logic_vector(15 downto 0);
    signal audio_in_R_i     : out std_logic_vector(15 downto 0);
    signal audio_in_valid_i : out std_logic;
    constant valL, valR     : in  signed(15 downto 0);
    constant nframes        : in  natural
  ) is
  begin
    for i in 0 to integer(nframes)-1 loop
      push_one_frame(clk_i, audio_in_ready_i, audio_in_L_i, audio_in_R_i, audio_in_valid_i, valL, valR);
    end loop;
  end procedure;

  -- ===== Debugflags (optional) =====
  signal any_read_seen  : boolean := false;
  signal any_write_seen : boolean := false;

begin
  -- ===== Clock 65 MHz =====
  clk <= not clk after TCLK/2;

  -- ===== Reset =====
  process
  begin
    reset_n <= '0';
    wait for 8*TCLK;
    reset_n <= '1';
    wait;
  end process;

  -- ================= DUTs =================

  -- Echo-Logik
  u_echo : entity work.echo_logic
    generic map (
      G_ADDR_WIDTH => C_ADDR_W,
      G_DATA_WIDTH => C_DATA_W
    )
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

  -- SRAM-Controller
  u_ctrl : entity work.sram_ctrl
    generic map (
      G_ADDR_WIDTH => C_ADDR_W,
      G_DATA_WIDTH => C_DATA_W
    )
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

  -- Asynchrones 16-bit-SRAM-Modell
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

  -- Keyboard-Block (Eingänge 0)
  u_kb : entity work.kb_block
    port map (
      KB_SCAN_CODE  => KB_SCAN_CODE,
      KB_SCAN_VALID => KB_SCAN_VALID,
      RESET_N       => reset_n,
      clk           => clk,
      ctrl_sig      => ctrl_sig
    );

  -- ================= Stimuli: Impuls @0 ns & @450000 ns, je 2000 ns =================
  stim : process
    constant AMP0  : signed(15 downto 0) := to_signed(10000, 16);
    constant AMP  : signed(15 downto 0) := to_signed(80000, 16);  -- Impulsamplitude
    constant ZERO : signed(15 downto 0) := to_signed(0, 16);

    -- laufende Frames seit Start
    variable cur_frames  : natural := 0;

    -- vorkalkulierte Frame-Zahlen
    variable frames_on   : natural;
    variable gap1_frames : natural;
    variable tail_frames : natural;
  begin
    wait until reset_n = '1';
    wait for 5*TCLK;

    -- Delay (in Frames) + Gain setzen
    delay_samples  <= std_logic_vector(to_unsigned(time_to_frames(DELAY_NS, TCLK), delay_samples'length));
    g_feedback_q15 <= G_Q15;
    echo_disable   <= '0';

    -- in Frames umrechnen
    frames_on   := time_to_frames(ON_NS, TCLK);                     -- ~2000 ns
    gap1_frames := time_to_frames(SECOND_START_NS - ON_NS, TCLK);   -- bis 450 µs Marke
    tail_frames := time_to_frames(TAIL_NS, TCLK);                   -- Nachlauf

    -- ===== Impuls 1 =====
    push_n_frames(clk, audio_in_ready, audio_in_L, audio_in_R, audio_in_valid, AMP,  AMP0,  frames_on);
    cur_frames := cur_frames + frames_on;

    -- ===== Pause bis 450000 ns (Null-Frames) =====
    push_n_frames(clk, audio_in_ready, audio_in_L, audio_in_R, audio_in_valid, ZERO, ZERO, gap1_frames);
    cur_frames := cur_frames + gap1_frames;

    -- ===== Impuls 2 @ 450000 ns =====
    push_n_frames(clk, audio_in_ready, audio_in_L, audio_in_R, audio_in_valid, AMP,  AMP0,  frames_on);
    cur_frames := cur_frames + frames_on;

    -- ===== Nachlauf (Null-Frames) =====
    push_n_frames(clk, audio_in_ready, audio_in_L, audio_in_R, audio_in_valid, ZERO, ZERO, tail_frames);
    report "TB done." severity note;

    wait for 1 ms;
    std.env.stop;
    wait;
  end process;

  -- ===== Optional: kleine Monitore =====
  mon_we: process(clk)
  begin
    if rising_edge(clk) then
      if SRAM_WE_N='0' then any_write_seen <= true; end if;
    end if;
  end process;

  mon_oe: process(clk)
  begin
    if rising_edge(clk) then
      if SRAM_OE_N='0' then any_read_seen <= true; end if;
    end if;
  end process;

end architecture;

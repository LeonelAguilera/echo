-- tb_echo_top.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_echo_top is
end entity;

architecture sim of tb_echo_top is
  constant G_DATA_WIDTH : natural := 16;
  constant G_ADDR_WIDTH : natural := 19;

  signal clk              : std_logic := '0';
  signal RESET_N          : std_logic := '0';

  -- Keyboard (seriell LSB-first)
  signal KB_SCAN_CODE     : std_logic := '0';
  signal KB_SCAN_VALID    : std_logic := '0';

  -- Audio I/F
  signal audio_in_L       : std_logic_vector(G_DATA_WIDTH-1 downto 0) := (others => '0');
  signal audio_in_R       : std_logic_vector(G_DATA_WIDTH-1 downto 0) := (others => '0');
  signal audio_in_valid   : std_logic := '0';
  signal audio_in_ready   : std_logic;

  signal audio_out_L      : std_logic_vector(G_DATA_WIDTH-1 downto 0);
  signal audio_out_R      : std_logic_vector(G_DATA_WIDTH-1 downto 0);
  signal audio_out_valid  : std_logic;

  signal delay_samples    : std_logic_vector(18 downto 0);
  signal g_feedback_q15   : std_logic_vector(15 downto 0);

  -- SRAM Bus (beidseitig!)
  signal SRAM_ADDR        : std_logic_vector(G_ADDR_WIDTH-1 downto 0);
  signal SRAM_CE_N        : std_logic;
  signal SRAM_DQ          : std_logic_vector(G_DATA_WIDTH-1 downto 0);
  signal SRAM_LB_N        : std_logic;
  signal SRAM_OE_N        : std_logic;
  signal SRAM_UB_N        : std_logic;
  signal SRAM_WE_N        : std_logic;

  constant CLK_PERIOD : time := 20 ns;

  -- Scan-Set-2 MAKE-Codes
  constant SC_H : std_logic_vector(7 downto 0) := x"33";
  constant SC_J : std_logic_vector(7 downto 0) := x"3B";
  constant SC_K : std_logic_vector(7 downto 0) := x"42";
  constant SC_L : std_logic_vector(7 downto 0) := x"4B";
  constant SC_E : std_logic_vector(7 downto 0) := x"24";
begin
  -- Clock
  clk <= not clk after CLK_PERIOD/2;

  -- ========== DUT ==========
  dut: entity work.echo
    generic map(
      G_DATA_WIDTH => G_DATA_WIDTH,
      G_ADDR_WIDTH => G_ADDR_WIDTH
    )
    port map(
      audio_in_L      => audio_in_L,
      audio_in_R      => audio_in_R,
      audio_in_ready  => audio_in_ready,
      audio_in_valid  => audio_in_valid,
      audio_out_L     => audio_out_L,
      audio_out_R     => audio_out_R,
      audio_out_valid => audio_out_valid,
      clk             => clk,
      delay_samples   => delay_samples,
      g_feedback_q15  => g_feedback_q15,
      KB_SCAN_CODE    => KB_SCAN_CODE,
      KB_SCAN_VALID   => KB_SCAN_VALID,
      RESET_N         => RESET_N,
      SRAM_ADDR       => SRAM_ADDR,
      SRAM_CE_N       => SRAM_CE_N,
      SRAM_DQ         => SRAM_DQ,       -- ? INOUT am DUT empfohlen
      SRAM_LB_N       => SRAM_LB_N,
      SRAM_OE_N       => SRAM_OE_N,
      SRAM_UB_N       => SRAM_UB_N,
      SRAM_WE_N       => SRAM_WE_N
    );

  -- ========== SRAM-Modell ==========
  u_sram: entity work.sram_async_model
    generic map (
      DATA_WIDTH => G_DATA_WIDTH,
      ADDR_WIDTH => G_ADDR_WIDTH
    )
    port map (
      CE_N => SRAM_CE_N,
      OE_N => SRAM_OE_N,
      WE_N => SRAM_WE_N,
      LB_N => SRAM_LB_N,
      UB_N => SRAM_UB_N,
      A    => SRAM_ADDR,
      DQ   => SRAM_DQ
    );

  --------------------------------------------------------------------
  -- Stimulus
  --------------------------------------------------------------------
  stim: process
    procedure reset_dut is
    begin
      RESET_N <= '0';
      KB_SCAN_VALID <= '0';
      KB_SCAN_CODE  <= '0';
      audio_in_valid <= '0';
      wait for 200 ns;
      RESET_N <= '1';
      wait for 200 ns;
    end procedure;

    -- 8 serielle Bits (LSB-first) einspeisen
    procedure send_scancode(code : std_logic_vector(7 downto 0)) is
    begin
      for i in 0 to 7 loop
        KB_SCAN_CODE  <= code(i);
        KB_SCAN_VALID <= '1';
        wait until rising_edge(clk);
        KB_SCAN_VALID <= '0';
        wait until rising_edge(clk);
      end loop;
      wait for 5*CLK_PERIOD;
    end procedure;

    procedure push_sample(l, r : integer) is
      variable lv, rv : std_logic_vector(G_DATA_WIDTH-1 downto 0);
    begin
      lv := std_logic_vector(to_signed(l, G_DATA_WIDTH));
      rv := std_logic_vector(to_signed(r, G_DATA_WIDTH));
      wait until rising_edge(clk);
      audio_in_L <= lv;  audio_in_R <= rv;
      audio_in_valid <= '1';
      if audio_in_ready = '1' then
        wait until rising_edge(clk);
        audio_in_valid <= '0';
      else
        while audio_in_ready = '0' loop
          wait until rising_edge(clk);
        end loop;
        wait until rising_edge(clk);
        audio_in_valid <= '0';
      end if;
    end procedure;

  begin
    reset_dut;

    -- ein paar Writes/Reads provozieren durch DUT-Workflow (Audio & Keys)
    for i in 0 to 200 loop
      push_sample(i*64 - 6400, i*64 - 6400);
    end loop;

    send_scancode(SC_H);
    send_scancode(SC_J);
    send_scancode(SC_K);
    send_scancode(SC_L);
    send_scancode(SC_E);

    for i in 0 to 40000 loop
      push_sample( (i mod 200)*128 - 12000, (i mod 200)*128 - 12000 );
      if audio_out_valid = '1' then
        report "OUT L="
          & integer'image(to_integer(signed(audio_out_L)))
          & "  R="
          & integer'image(to_integer(signed(audio_out_R)))
          & "  delay="
          & integer'image(to_integer(unsigned(delay_samples)))
          & "  g_q15="
          & integer'image(to_integer(signed(g_feedback_q15)))
          severity note;
      end if;
    end loop;

    report "TB: Fertig." severity note;
    wait;
  end process;

end architecture;


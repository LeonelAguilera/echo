--
-- VHDL Architecture echo_lib.tb_sram_ctrl.sim
--
-- Created:
--          by - antmo328.student-liu.se (muxen2-111.ad.liu.se)
--          at - 18:59:31 10/20/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_sram_ctrl is
end entity;

architecture sim of tb_sram_ctrl is
  -- Kleinere Tiefe für Simulation
  constant C_ADDR_W : natural := 12; -- 4K x 16
  constant C_DATA_W : natural := 16;

  signal clk      : std_logic := '0';
  signal reset_n  : std_logic := '0';

  -- User IF
  signal rd_en    : std_logic := '0';
  signal wr_en    : std_logic := '0';
  signal rd_addr  : std_logic_vector(C_ADDR_W-1 downto 0) := (others => '0');
  signal wr_addr  : std_logic_vector(C_ADDR_W-1 downto 0) := (others => '0');
  signal wr_data  : std_logic_vector(C_DATA_W-1 downto 0) := (others => '0');
  signal rd_data  : std_logic_vector(C_DATA_W-1 downto 0);
  signal rd_valid : std_logic;

  -- SRAM IF
  signal SRAM_ADDR : std_logic_vector(C_ADDR_W-1 downto 0);
  signal SRAM_DQ   : std_logic_vector(15 downto 0);
  signal SRAM_CE_N : std_logic;
  signal SRAM_OE_N : std_logic;
  signal SRAM_WE_N : std_logic;
  signal SRAM_UB_N : std_logic;
  signal SRAM_LB_N : std_logic;

  -- Test-Helfer
  type vec_arr is array (natural range <>) of std_logic_vector(15 downto 0);

begin
  -- 50 MHz
  clk <= not clk after 10 ns;

  -- Reset
  process
  begin
    reset_n <= '0';
    wait for 100 ns;
    reset_n <= '1';
    wait;
  end process;

  -- DUT
  u_dut : entity work.sram_ctrl
    generic map (
      G_ADDR_WIDTH => C_ADDR_W,
      G_DATA_WIDTH => 16
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

  -- SRAM Modell
  u_mem : entity work.sram16_asyn
    generic map (
      G_ADDR_WIDTH => C_ADDR_W
    )
    port map (
      A    => SRAM_ADDR,
      DQ   => SRAM_DQ,
      CE_N => SRAM_CE_N,
      OE_N => SRAM_OE_N,
      WE_N => SRAM_WE_N,
      UB_N => SRAM_UB_N,
      LB_N => SRAM_LB_N
    );

  -- Stimuli
  stim : process
    variable exp : std_logic_vector(15 downto 0);
  begin
    wait until reset_n = '1';
    wait for 50 ns;

    -- Schreibe 16 Worte, dann lies zurück
    for i in 0 to 15 loop
      wr_addr <= std_logic_vector(to_unsigned(i, C_ADDR_W));
      wr_data <= std_logic_vector(to_unsigned(i*257, 16)); -- Muster
      wr_en   <= '1';
      wait until rising_edge(clk);
      -- Controller nimmt in IDLE, danach läuft FSM ~3 Takte
      wr_en   <= '0';
      -- Warte auf IDLE-Rückkehr: konservativ 3 weitere Takte
      wait for 3*20 ns;
    end loop;

    -- Lesen & prüfen
    for i in 0 to 15 loop
      rd_addr <= std_logic_vector(to_unsigned(i, C_ADDR_W));
      rd_en   <= '1';
      wait until rising_edge(clk);
      rd_en   <= '0';

      -- Auf rd_valid warten
      wait until rising_edge(clk) and rd_valid='1';
      exp := std_logic_vector(to_unsigned(i*257, 16));
      assert rd_data = exp
        report "READ MISMATCH at addr " & integer'image(i) &
               " got=" & to_hstring(rd_data) &
               " exp=" & to_hstring(exp)
        severity failure;
    end loop;

    report "All tests passed." severity note;
    wait for 100 ns;
    std.env.stop;
    wait;
  end process;

end architecture;

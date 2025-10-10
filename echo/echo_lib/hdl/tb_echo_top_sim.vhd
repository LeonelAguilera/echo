--
-- VHDL Architecture echo_lib.tb_echo_top.sim
--
-- Created:
--          by - antmo328.student-liu.se (muxen2-112.ad.liu.se)
--          at - 13:02:49 10/10/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

ENTITY tb_echo_top IS
END ENTITY tb_echo_top;

--
ARCHITECTURE sim OF tb_echo_top IS
constant CLK_PERIOD : time := 22.6757 us / 1000.0; -- ?22.67 µs ? 44.1 kHz

  -- Clock / Reset
  signal clk, reset_n : std_logic := '0';

  -- Audio I/O
  signal in_valid, in_ready, out_valid : std_logic := '0';
  signal in_L, in_R, out_L, out_R : std_logic_vector(15 downto 0);

  -- Steuerung
  signal delay_samples  : unsigned(17 downto 0) := to_unsigned(22050, 18); -- 0.5s Delay
  signal g_feedback_q15 : std_logic_vector(15 downto 0) := x"4000";       -- 0.5 Gain

  -- SRAM-IF
  signal wr_en, rd_en : std_logic;
  signal wr_addr, rd_addr : std_logic_vector(19 downto 0);
  signal wr_data, rd_data : std_logic_vector(15 downto 0);
  signal rd_valid : std_logic;

  -- SRAM-Pins (physikalisch)
  signal SRAM_ADDR  : std_logic_vector(18 downto 0);
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
  -- DUT 1: Echo_Logic
  -------------------------------------------------------------------------
  u_echo: entity work.Echo_Logic
    port map (
      clk => clk,
      reset_n => reset_n,
      in_L => in_L,
      in_R => in_R,
      in_valid => in_valid,
      in_ready => in_ready,
      out_L => out_L,
      out_R => out_R,
      out_valid => out_valid,
      delay_samples => delay_samples,
      g_feedback_q15 => g_feedback_q15,
      wr_en => wr_en,
      wr_addr => wr_addr,
      wr_data => wr_data,
      rd_en => rd_en,
      rd_addr => rd_addr,
      rd_data => rd_data,
      rd_valid => rd_valid
    );

  -------------------------------------------------------------------------
  -- DUT 2: SRAM_Control
  -------------------------------------------------------------------------
  u_ctrl: entity work.sram_ctrl
    generic map (
      G_ADDR_WIDTH => 19,
      G_DATA_WIDTH => 16
    )
    port map (
      clk => clk,
      RESET_N => reset_n,
      wr_en => wr_en,
      wr_addr => wr_addr(18 downto 0),
      wr_data => wr_data,
      rd_en => rd_en,
      rd_addr => rd_addr(18 downto 0),
      rd_data => rd_data,
      rd_valid => rd_valid,
      SRAM_ADDR => SRAM_ADDR,
      SRAM_DQ => SRAM_DQ,
      SRAM_CE_N => SRAM_CE_N,
      SRAM_OE_N => SRAM_OE_N,
      SRAM_WE_N => SRAM_WE_N,
      SRAM_UB_N => SRAM_UB_N,
      SRAM_LB_N => SRAM_LB_N
    );

  -------------------------------------------------------------------------
  -- DUT 3: SRAM-Modell (Simulation)
  -------------------------------------------------------------------------
  u_sram: entity work.SRAM_Async_Model
    port map (
      ADDR  => SRAM_ADDR,
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
  stim: process
  begin
    reset_n <= '0';
    wait for 200 ns;
    reset_n <= '1';
    wait for 200 ns;

    report "Start ECHO Impuls-Test" severity note;

    -- Einfaches Testsignal (Impuls)
    for i in 0 to 50000 loop
      if in_ready = '1' then
        in_valid <= '1';
        if i = 0 then
          in_L <= x"4000";  -- Impuls links/rechts
          in_R <= x"4000";
        else
          in_L <= (others => '0');
          in_R <= (others => '0');
        end if;
      else
        in_valid <= '0';
      end if;
      wait until rising_edge(clk);
    end loop;

    report "Echo-Logic Test beendet" severity note;
    std.env.stop;
  end process;
END ARCHITECTURE sim;


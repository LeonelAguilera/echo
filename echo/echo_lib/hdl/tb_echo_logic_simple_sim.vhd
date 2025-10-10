--
-- VHDL Architecture echo_lib.tb_echo_logic_simple.sim
--
-- Created:
--          by - antmo328.student-liu.se (muxen2-112.ad.liu.se)
--          at - 12:58:43 10/10/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

ENTITY tb_echo_logic_simple IS
END ENTITY tb_echo_logic_simple;

--
ARCHITECTURE sim OF tb_echo_logic_simple IS
constant CLK_PERIOD : time := 22.6757 us / 1000.0;  -- 44.1 kHz Sample-Rate ? 22.67 µs pro Sample

  signal clk, reset_n : std_logic := '0';
  signal in_valid, out_valid : std_logic := '0';
  signal in_ready : std_logic;
  signal in_L, in_R : std_logic_vector(15 downto 0) := (others => '0');
  signal out_L, out_R : std_logic_vector(15 downto 0);

  -- Steuerung
  signal delay_samples  : unsigned(17 downto 0) := to_unsigned(22050, 18);  -- 0.5s bei 44.1kHz
  signal g_feedback_q15 : std_logic_vector(15 downto 0) := x"4000"; -- ?0.5 Gain

  -- SRAM-Control Signale
  signal wr_en, rd_en  : std_logic;
  signal wr_addr, rd_addr : std_logic_vector(19 downto 0);
  signal wr_data, rd_data : std_logic_vector(15 downto 0);
  signal rd_valid : std_logic;

begin
  -- Clock
  clk <= not clk after CLK_PERIOD/2;

  -- DUT
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

  u_sram: entity work.SRAM_Async_Model
    port map (
      ADDR  => rd_addr(18 downto 0),
      DQ    => open,  -- für Simulation ggf. internes Speicherarray benutzen
      CE_N  => '0', OE_N => '0', WE_N => '1', UB_N => '0', LB_N => '0'
    );

  -- Stimulus
  stim: process
  begin
    -- Reset
    reset_n <= '0';
    wait for 100 ns;
    reset_n <= '1';
    wait for 100 ns;

    -- 1) Impuls-Test
    for n in 0 to 5000 loop
      if in_ready = '1' then
        in_valid <= '1';
        if n = 0 then
          in_L <= x"4000";  -- Impuls links
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

    report "Echo Logic Impuls-Test beendet." severity note;
    wait;
  end process;
END ARCHITECTURE sim;


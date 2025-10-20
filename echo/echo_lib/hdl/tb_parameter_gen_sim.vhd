--
-- VHDL Architecture echo_lib.tb_parameter_gen.sim
--
-- Created:
--          by - antmo328.student-liu.se (muxen2-112.ad.liu.se)
--          at - 22:26:03 10/16/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_parameter_gen is
end entity;

architecture sim of tb_parameter_gen is
  -- DUT Ports
  signal clk            : std_logic := '0';
  signal RESET_N        : std_logic := '0';
  signal KB_DECODE      : std_logic_vector(5 downto 0) := (others => '0');
  signal echo_disable   : std_logic;
  signal g_feedback_q15 : std_logic_vector(15 downto 0);
  signal delay_samples  : std_logic_vector(18 downto 0);

  -- 65 MHz Takt
  constant clk_period : time := 15.384615 ns;

  -- kleine Hilfsprozedur: Taste "kurz drücken" (1 Takt lang)
  procedure press_key(
  signal kb  : out std_logic_vector;   -- unconstrained ok
  constant idx : natural
) is
  variable tmp : std_logic_vector(kb'range);
begin
  assert (idx >= kb'low and idx <= kb'high)
    report "press_key: idx out of range" severity failure;

  tmp := (kb'range => '0');
  tmp(idx) := '1';
  kb <= tmp;

  -- genau ein Takt lang aktiv
  wait for clk_period;

  tmp := (kb'range => '0');
  kb <= tmp;
end procedure;

begin
  -- DUT-Instanz (Generics bleiben auf Default)
  dut: entity work.parameter_gen
    port map (
      clk            => clk,
      RESET_N        => RESET_N,
      KB_DECODE      => KB_DECODE,
      echo_disable   => echo_disable,
      g_feedback_q15 => g_feedback_q15,
      delay_samples  => delay_samples
    );

  -- Clock-Generator (50% Duty)
  clk_proc : process
  begin
    clk <= '0';
    wait for clk_period/2;
    clk <= '1';
    wait for clk_period/2;
  end process;

  -- Reset-Sequenz
  rst_proc : process
  begin
    RESET_N <= '0';
    KB_DECODE <= (others => '0');
    wait for 10*clk_period;  -- 10 Takte reset
    RESET_N <= '1';
    wait for 2*clk_period;
    wait;  -- Prozess beendet
  end process;

  -- Stimuli: nacheinander alle Funktionen testen
  stim_proc : process
    variable d_old : integer;
    variable g_old : integer;
  begin
    -- warte, bis Reset weg ist
    wait until RESET_N = '1';
    wait for 3*clk_period;

    -- Startwerte loggen
    d_old := to_integer(unsigned(delay_samples));
    g_old := to_integer(unsigned(g_feedback_q15));
    report "Start: delay=" & integer'image(d_old) &
           "  gain(Q15)=" & integer'image(g_old);

    --------------------------------------------------------------------------
    -- Echo disable (KB_DECODE(5)='1'), enable (KB_DECODE(4)='1')
    --------------------------------------------------------------------------
    press_key(KB_DECODE, 5);  -- disable
    wait for clk_period;
    assert echo_disable = '1' report "Echo disable hat nicht gegriffen!" severity warning;

    press_key(KB_DECODE, 4);  -- enable
    wait for clk_period;
    assert echo_disable = '0' report "Echo enable hat nicht gegriffen!" severity warning;

    --------------------------------------------------------------------------
    -- Delay + (KB_DECODE(3)), Delay - (KB_DECODE(2))
    --------------------------------------------------------------------------
    d_old := to_integer(unsigned(delay_samples));
    press_key(KB_DECODE, 3);  -- Delay +
    wait for clk_period;
    report "Delay+ : " & integer'image(d_old) & " -> " &
           integer'image(to_integer(unsigned(delay_samples)));

    d_old := to_integer(unsigned(delay_samples));
    press_key(KB_DECODE, 2);  -- Delay -
    wait for clk_period;
    report "Delay- : " & integer'image(d_old) & " -> " &
           integer'image(to_integer(unsigned(delay_samples)));

    --------------------------------------------------------------------------
    -- Gain + (KB_DECODE(1)), Gain - (KB_DECODE(0))
    --------------------------------------------------------------------------
    g_old := to_integer(unsigned(g_feedback_q15));
    press_key(KB_DECODE, 1);  -- Gain +
    wait for clk_period;
    report "Gain+  : " & integer'image(g_old) & " -> " &
           integer'image(to_integer(unsigned(g_feedback_q15)));

    g_old := to_integer(unsigned(g_feedback_q15));
    press_key(KB_DECODE, 0);  -- Gain -
    wait for clk_period;
    report "Gain-  : " & integer'image(g_old) & " -> " &
           integer'image(to_integer(unsigned(g_feedback_q15)));

    --------------------------------------------------------------------------
    -- Optional: ein paar schnelle Mehrfachklicks
    --------------------------------------------------------------------------
    for i in 1 to 3 loop
      press_key(KB_DECODE, 3);  -- dreimal Delay +
      wait for clk_period;
    end loop;

    for i in 1 to 2 loop
      press_key(KB_DECODE, 1);  -- zweimal Gain +
      wait for clk_period;
    end loop;

    -- Simulationsende
    wait for 20*clk_period;
    -- Falls dein Simulator VHDL-2008 unterstützt:
    -- std.env.stop;  -- Simulation sauber beenden
    wait;             -- ansonsten einfach laufen lassen
  end process;

  -- Einfacher Monitor: bei Änderungen kurz ausgeben
  monitor : process(delay_samples, g_feedback_q15, echo_disable)
  begin
    report "MON: delay=" & integer'image(to_integer(unsigned(delay_samples))) &
           "  gain(Q15)=" & integer'image(to_integer(unsigned(g_feedback_q15))) &
           "  echo_disable=" & std_logic'image(echo_disable);
  end process;

end architecture sim;


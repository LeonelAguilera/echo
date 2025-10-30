-- tb_echo_fileio_kb.vhd
-- Liest Stereo-INT16 (L R) aus Textdatei, füttert echo-DUT und schreibt Output zurück.
-- Features:
--  * SYNC_TO_OUT_VALID=false: eigener Sampletick via Integer-NCO (empfohlen)
--  * SYNC_TO_OUT_VALID=true : Einspeisen synchron zu audio_out_valid
--  * VALID_STRETCH: audio_in_valid mehrere Takte aktiv halten
--  * REPEAT_PASSES: gleiche Datei n-mal hintereinander abspielen
--  * Robustes file_open + Auto-Stop am Ende

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use std.env.all;

library echo_lib;  -- DUT sitzt in echo_lib

entity tb_echo_fileio_kb is
  generic (
    IN_FILE           : string  := "/home/antmo328/echo/wav_txt/test1234_in.txt";
    OUT_FILE          : string  := "/home/antmo328/echo/wav_txt/test1234_out.txt";
    CLK_HZ            : integer := 65_000_000;
    RST_CYC           : integer := 10;

    -- Einspeisemodus:
    SYNC_TO_OUT_VALID : boolean := false;   -- false = NCO-Tick (empfohlen)
    SAMPLE_RATE       : integer := 44_100;  -- nur genutzt, wenn SYNC_TO_OUT_VALID=false

    VALID_STRETCH     : natural := 8;       -- #CLK-Takte mit audio_in_valid='1' je Sample (>=1)
    REPEAT_PASSES     : natural := 1;       -- Datei so oft abspielen
    TAIL_CYCLES       : natural := 200000;  -- Nachlauf-Zyklen
    STOP_ON_FINISH    : boolean := true     -- run -all stoppt automatisch
  );
end entity;

architecture sim of tb_echo_fileio_kb is
  constant CLK_PERIOD : time := 1 sec / CLK_HZ;

  -- System
  signal clk     : std_logic := '0';
  signal reset_n : std_logic := '0';

  -- DUT I/O (kein in_ready/out_ready)
  signal audio_in_L      : std_logic_vector(15 downto 0) := (others => '0');
  signal audio_in_R      : std_logic_vector(15 downto 0) := (others => '0');
  signal audio_in_valid  : std_logic := '0';

  signal audio_out_L     : std_logic_vector(15 downto 0);
  signal audio_out_R     : std_logic_vector(15 downto 0);
  signal audio_out_valid : std_logic;
  
  -- TB-Signale für den ?externen? SRAM-Bus
  signal sram_addr : std_logic_vector(19 downto 0);  -- G_ADDR_WIDTH der DUT
  signal sram_dq   : std_logic_vector(15 downto 0);
  signal sram_ce_n : std_logic;
  signal sram_oe_n : std_logic;
  signal sram_we_n : std_logic;
  signal sram_ub_n : std_logic;
  signal sram_lb_n : std_logic;
  

  -- Zusatzports (Default '0' ? bei Bedarf ergänzen)
  signal KB_SCAN_CODE  : std_logic := '0';
  signal KB_SCAN_VALID : std_logic := '0';

  -- TEXTIO
  file fin  : text;
  file fout : text;

  -- Timing (nur für NCO-Modus relevant)
  signal sample_tick    : std_logic := '0';  -- 1 CLK breiter Tick je Sample
  signal stretch_active : std_logic := '0';
  signal stretch_cnt    : natural   := 0;

  -- Helpers
  impure function to_s16(x : integer) return std_logic_vector is
    variable s : signed(15 downto 0);
  begin
    if x > 32767 then s := to_signed(32767,16);
    elsif x < -32768 then s := to_signed(-32768,16);
    else s := to_signed(x,16);
    end if;
    return std_logic_vector(s);
  end function;

  impure function to_int16(v : std_logic_vector(15 downto 0)) return integer is
  begin
    return to_integer(signed(v));
  end function;

begin
  --------------------------------------------------------------------------
  -- Clock & Reset
  --------------------------------------------------------------------------
  clk <= not clk after CLK_PERIOD/2;

  p_reset : process
  begin
    reset_n <= '0';
    for i in 1 to RST_CYC loop
      wait until rising_edge(clk);
    end loop;
    reset_n <= '1';
    wait;
  end process;

  --------------------------------------------------------------------------
  -- DUT-Instanz (in echo_lib)
  --------------------------------------------------------------------------
  u_dut : entity echo_lib.echo
    port map (
      clk             => clk,
      reset_n         => reset_n,
      audio_in_L      => audio_in_L,
      audio_in_R      => audio_in_R,
      audio_in_valid  => audio_in_valid,
      audio_out_L     => audio_out_L,
      audio_out_R     => audio_out_R,
      audio_out_valid => audio_out_valid,
      KB_SCAN_CODE    => KB_SCAN_CODE,
      KB_SCAN_VALID   => KB_SCAN_VALID,
      -- weitere Ports (Schalter/LEDs/Parameter) hier bei Bedarf mappen
      -- >>> SRAM-Pins nach außen führen <<<
      SRAM_ADDR => sram_addr,
      SRAM_DQ   => sram_dq,
      SRAM_CE_N => sram_ce_n,
      SRAM_OE_N => sram_oe_n,
      SRAM_WE_N => sram_we_n,
      SRAM_UB_N => sram_ub_n,
      SRAM_LB_N => sram_lb_n
    );
  u_sram : entity work.sram_model
  generic map (
    G_ADDR_WIDTH => 20,  -- passend zu echo/sram_ctrl
    G_DATA_WIDTH => 16
  )
  port map (
    SRAM_ADDR => sram_addr,
    SRAM_DQ   => sram_dq,
    SRAM_CE_N => sram_ce_n,
    SRAM_OE_N => sram_oe_n,
    SRAM_WE_N => sram_we_n,
    SRAM_UB_N => sram_ub_n,
    SRAM_LB_N => sram_lb_n
  );
  --------------------------------------------------------------------------
  -- Integer-NCO für Sampletick + VALID-Stretch (aktiv wenn SYNC_TO_OUT_VALID=false)
  -- Bresenham-Teiler: acc += SAMPLE_RATE; wenn acc >= CLK_HZ => Tick, acc -= CLK_HZ
  --------------------------------------------------------------------------
  gen_nco : if (not SYNC_TO_OUT_VALID) generate
    signal acc : integer := 0;  -- Akkumulator in Hz-Einheiten (passt für 65MHz/48kHz)
  begin
    p_nco : process(clk)
      variable acc_next : integer;
      variable tick     : std_logic;
    begin
      if rising_edge(clk) then
        acc_next := acc + SAMPLE_RATE;
        if acc_next >= CLK_HZ then
          acc_next := acc_next - CLK_HZ;
          tick := '1';
        else
          tick := '0';
        end if;

        acc         <= acc_next;
        sample_tick <= tick;

        -- VALID-Stretch steuern
        if tick = '1' then
          stretch_active <= '1';
          stretch_cnt    <= 1;  -- erster Takt zählt mit
        elsif stretch_active = '1' then
          if VALID_STRETCH <= 1 then
            stretch_active <= '0';
            stretch_cnt    <= 0;
          elsif stretch_cnt + 1 >= VALID_STRETCH then
            stretch_active <= '0';
            stretch_cnt    <= 0;
          else
            stretch_cnt    <= stretch_cnt + 1;
          end if;
        end if;
      end if;
    end process;
  end generate;

  --------------------------------------------------------------------------
  -- Feeder & Logger
  --------------------------------------------------------------------------
  p_driver : process
    variable L     : line;
    variable O     : line;
    variable il    : integer;
    variable ir    : integer;
    variable st    : file_open_status;
    variable sent  : natural := 0;
    variable wrote : natural := 0;
    variable out_zero_run  : natural := 0;
    variable out_last_tick : natural := 0;
    variable cyc           : natural := 0;
    
    procedure watch_output is
begin
  cyc := cyc + 1;

  -- 1) Lange Null-Sequenz erkennen (beide Kanäle = 0 mit gültig)
  if audio_out_valid = '1' and
     signed(audio_out_L) = 0 and signed(audio_out_R) = 0 then
    out_zero_run := out_zero_run + 1;
    if out_zero_run = 1024 then
      report "WARN: 1024 aufeinanderfolgende Nullen ab Zyklus " &
             integer'image(cyc-1023) severity warning;
    end if;
  elsif audio_out_valid = '1' then
    out_zero_run := 0;
  end if;

  -- 2) Langer Abstand zwischen valid-Pulsen (Stillstand)
  if audio_out_valid = '1' then
    if (cyc - out_last_tick) > 200000 then
      report "WARN: >200000 Takte ohne audio_out_valid; letzter bei Zyklus " &
             integer'image(out_last_tick) severity warning;
    end if;
    out_last_tick := cyc;
  end if;
end procedure;
    
    procedure maybe_log_output is
    begin
      if audio_out_valid = '1' then
        write(O, to_int16(audio_out_L));
        write(O, ' ');
        write(O, to_int16(audio_out_R));
        writeline(fout, O);
        wrote := wrote + 1;
        if (wrote mod 20000) = 0 then
          report "geschrieben: " & integer'image(wrote) severity note;
        end if;
      end if;
    end procedure;

    -- 1 Sample ausgeben, VALID über VALID_STRETCH Takte halten (>=1)
    procedure emit_input(Li, Ri : integer) is
      variable stretch_n : natural;
    begin
      if VALID_STRETCH < 1 then
        stretch_n := 1;
      else
        stretch_n := VALID_STRETCH;
      end if;

      audio_in_L     <= to_s16(Li);
      audio_in_R     <= to_s16(Ri);
      audio_in_valid <= '1';

      -- restliche Stretch-Takte (erster Takt im Aufrufer-Kontext)
      for i in 1 to integer(stretch_n - 1) loop
        wait until rising_edge(clk);
        maybe_log_output;
      end loop;

      audio_in_valid <= '0';
      sent := sent + 1;
      if (sent mod 20000) = 0 then
        report "eingespeist: " & integer'image(sent) severity note;
      end if;
    end procedure;

  begin
    wait until reset_n = '1';
    wait until rising_edge(clk);

    file_open(st, fout, OUT_FILE, write_mode);
    assert st = open_ok
      report "Konnte OUT_FILE nicht öffnen: " & OUT_FILE
      severity failure;

    for pass in 1 to REPEAT_PASSES loop
      file_open(st, fin, IN_FILE, read_mode);
      assert st = open_ok
        report "Konnte IN_FILE nicht öffnen: " & IN_FILE
        severity failure;

      if SYNC_TO_OUT_VALID then
        -- Modus A: an audio_out_valid koppeln (mit VALID-Stretch)
        if not endfile(fin) then
          readline(fin, L); read(L, il); read(L, ir);
          wait until rising_edge(clk);
          emit_input(il, ir);
          maybe_log_output;
        end if;

        while not endfile(fin) loop
          -- warten bis nächster audio_out_valid-Puls
          loop
            wait until rising_edge(clk);
            exit when audio_out_valid = '1';
            maybe_log_output;
          end loop;
          maybe_log_output;

          -- neues Sample
          readline(fin, L); read(L, il); read(L, ir);
          wait until rising_edge(clk);
          emit_input(il, ir);
        end loop;

      else
        -- Modus B: NCO-Tick (empfohlen)
        while not endfile(fin) loop
          wait until rising_edge(clk);
          maybe_log_output;

          if sample_tick = '1' then
            readline(fin, L); read(L, il); read(L, ir);
            -- erster Takt der Stretch-Phase ist jetzt
            emit_input(il, ir);
          end if;
        end loop;
      end if;

      file_close(fin);
    end loop;

    -- Nachlauf: restliche Outputs einsammeln
    for k in 0 to TAIL_CYCLES loop
      wait until rising_edge(clk);
      maybe_log_output;
      exit when k > 1000 and audio_out_valid = '0';
    end loop;

    file_close(fout);

    report "Samples eingespeist: " & integer'image(sent);
    report "Samples geschrieben: " & integer'image(wrote);
    report "Fertig." severity note;

    if STOP_ON_FINISH then
      std.env.stop(0);
    end if;

    wait;
  end process;

end architecture;

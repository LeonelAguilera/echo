--
-- VHDL Architecture echo_lib.echo_logic.behav
--
-- Created:
--          by - antmo328.student-liu.se (muxen2-104.ad.liu.se)
--          at - 14:31:37 10/07/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY echo_logic IS
   GENERIC( 
      G_ADDR_WIDTH : natural := 20;      -- Wortadressbreite
      G_DATA_WIDTH : natural := 16       -- Audio: 16 Bit
   );
   PORT( 
      audio_out_L     : OUT    std_logic_vector (G_DATA_WIDTH-1 DOWNTO 0);
      audio_out_R     : OUT    std_logic_vector (G_DATA_WIDTH-1 DOWNTO 0);
      delay_samples   : IN     unsigned (G_ADDR_WIDTH-2 DOWNTO 0);
      g_feedback_q15  : IN     std_logic_vector (15 DOWNTO 0);
      wr_en           : OUT    std_logic;
      wr_addr         : OUT    std_logic_vector (G_ADDR_WIDTH-1 DOWNTO 0);
      wr_data         : OUT    std_logic_vector (G_DATA_WIDTH-1 DOWNTO 0);
      rd_en           : OUT    std_logic;
      rd_addr         : OUT    std_logic_vector (G_ADDR_WIDTH-1 DOWNTO 0);
      RESET_N         : IN     std_logic;
      audio_in_ready  : OUT    std_logic;
      audio_out_valid : OUT    std_logic;
      rd_valid        : IN     std_logic;
      rd_data         : IN     std_logic_vector (G_DATA_WIDTH-1 DOWNTO 0);
      audio_in_L      : IN     std_logic_vector (G_DATA_WIDTH-1 DOWNTO 0);
      audio_in_R      : IN     std_logic_vector (G_DATA_WIDTH-1 DOWNTO 0);
      audio_in_valid  : IN     std_logic;
      clk             : IN     std_logic
   );

-- Declarations

END echo_logic ;


ARCHITECTURE behav OF echo_eogic IS
  -- ==========================================================================
  -- Hilfsfunktionen
  -- ==========================================================================

  -- 16-bit saturating add: a + b -> signed 16-bit with clip
  function sat_add_s16(a, b : signed(15 downto 0)) return signed is
    variable tmp : signed(16 downto 0); -- +1 Bit Headroom
    variable res : signed(15 downto 0);
  begin
    tmp := resize(a, 17) + resize(b, 17);
    if tmp > to_signed( 32767, 17) then
      res := to_signed( 32767, 16);
    elsif tmp < to_signed(-32768, 17) then
      res := to_signed(-32768, 16);
    else
      res := signed(tmp(15 downto 0));
    end if;
    return res;
  end function;

  -- Q1.15 multiply: x (s16) * g (q1.15) -> s16 (saturierend, rundend)
  -- Rundung: für prod >= 0 wird +0x4000 addiert (Round-to-nearest),
  --          für prod < 0 "round toward zero" (einfach & robust).
  function mul_q15_s16(x : signed(15 downto 0); g : signed(15 downto 0)) return signed is
    variable prod  : signed(31 downto 0);
    variable round : signed(31 downto 0);
    variable shr   : signed(31 downto 0);
    variable y     : signed(15 downto 0);
  begin
    prod  := resize(x, 32) * resize(g, 32);     -- 16x16 -> 32 (Q2.30)
    round := to_signed(16#00004000#, 32);
    if prod >= 0 then
      shr := shift_right(prod + round, 15);     -- -> Q1.15
    else
      shr := shift_right(prod, 15);             -- toward zero
    end if;

    -- Clip auf 16 Bit
    if    shr > to_signed( 32767, 32) then y := to_signed( 32767, 16);
    elsif shr < to_signed(-32768, 32) then y := to_signed(-32768, 16);
    else  y := signed(shr(15 downto 0));
    end if;

    return y;
  end function;

  -- Modularer Subtrahierer für Ringpuffer-Adressen: (a - b) mod 2^N
  function mod_sub(a, b : unsigned) return unsigned is
    variable aa  : unsigned(a'range) := a;
    variable bb  : unsigned(a'range) := resize(b, a'length);
  begin
    return aa - bb;  -- wrappt automatisch mod 2^N
  end function;

  -- ==========================================================================
  -- Interne Typen/Signale
  -- ==========================================================================

  -- FSM: Read L -> Read R -> Calc -> Write L -> Write R
  type state_t is (S_IDLE,
                   S_RD_L, S_WAIT_L,
                   S_RD_R, S_WAIT_R,
                   S_CALC,
                   S_WR_L, S_WR_L_HOLD,
                   S_WR_R, S_WR_R_HOLD);

  signal s, s_next : state_t := S_IDLE;

  -- Eingangslatch pro Stereo-Frame
  signal inL_reg, inR_reg : signed(15 downto 0) := (others => '0');

  -- Gain als signed (Q1.15)
  signal g_q15 : signed(15 downto 0);

  -- Delay in WÖRTERN (Stereo interleaved \u2192 *2)
  signal delay_words : unsigned(G_ADDR_WIDTH-1 downto 0);

  -- Ringpuffer-Schreibzeiger (zeigt aufs L-Wort; R = L+1)
  signal wr_ptr      : unsigned(G_ADDR_WIDTH-1 downto 0) := (others => '0');

  -- Leseadressen
  signal rd_ptr_L    : unsigned(G_ADDR_WIDTH-1 downto 0);
  signal rd_ptr_R    : unsigned(G_ADDR_WIDTH-1 downto 0);

  -- Verzögerte Werte aus dem Puffer
  signal delayed_L   : signed(15 downto 0) := (others => '0');
  signal delayed_R   : signed(15 downto 0) := (others => '0');

  -- Effektiv genutzte verzögerte Werte (Priming: ggf. 0)
  signal delayed_eff_L : signed(15 downto 0) := (others => '0');
  signal delayed_eff_R : signed(15 downto 0) := (others => '0');

  -- Ergebnis (wird auch zurückgeschrieben)
  signal yL, yR      : signed(15 downto 0) := (others => '0');

  -- Flow Control / Handshakes
  signal in_ready_i  : std_logic := '1';
  signal out_valid_i : std_logic := '0';

  -- SRAM-Control Interface (Puls-Signale)
  signal wr_en_i     : std_logic := '0';
  signal rd_en_i     : std_logic := '0';
  signal wr_addr_i   : unsigned(G_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal rd_addr_i   : unsigned(G_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal wr_data_i   : std_logic_vector(G_DATA_WIDTH-1 downto 0) := (others => '0');

  -- Priming: Wie viele Wörter seit Reset in den Ring geschrieben wurden (saturierend)
  signal filled_words : unsigned(G_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal primed       : std_logic := '0';

begin
  -----------------------------------------------------------------------------
  -- I/O-Zuweisungen
  -----------------------------------------------------------------------------
  in_ready  <= in_ready_i;
  out_valid <= out_valid_i;

  wr_en   <= wr_en_i;
  rd_en   <= rd_en_i;
  wr_addr <= std_logic_vector(wr_addr_i);
  rd_addr <= std_logic_vector(rd_addr_i);
  wr_data <= wr_data_i;

  audio_out_L   <= std_logic_vector(yL);
  audio_out_R   <= std_logic_vector(yR);

  -- Steuerparameter intern
  g_q15 <= signed(g_feedback_q15);

  -- delay_words = delay_samples * 2 (Stereo interleaved \u2192 zwei Wörter pro Sample)
  delay_words <= resize(shift_left(delay_samples, 1), delay_words'length);

  -- Priming: effektive delayed-Werte (vor Calc, kombinatorisch)
  delayed_eff_L <= delayed_L when primed = '1' else (others => '0');
  delayed_eff_R <= delayed_R when primed = '1' else (others => '0');

  -----------------------------------------------------------------------------
  -- Nächster Zustand (kombinatorisch)
  -----------------------------------------------------------------------------
  process(s, in_valid, in_ready_i, rd_valid)
  begin
    s_next <= s;

    case s is
      when S_IDLE =>
        if in_valid = '1' and in_ready_i = '1' then
          s_next <= S_RD_L;
        end if;

      when S_RD_L =>
        s_next <= S_WAIT_L;

      when S_WAIT_L =>
        if rd_valid = '1' then
          s_next <= S_RD_R;
        end if;

      when S_RD_R =>
        s_next <= S_WAIT_R;

      when S_WAIT_R =>
        if rd_valid = '1' then
          s_next <= S_CALC;
        end if;

      when S_CALC =>
        s_next <= S_WR_L;

      when S_WR_L =>
        s_next <= S_WR_L_HOLD;

      when S_WR_L_HOLD =>
        s_next <= S_WR_R;

      when S_WR_R =>
        s_next <= S_WR_R_HOLD;

      when S_WR_R_HOLD =>
        s_next <= S_IDLE;

      when others =>
        s_next <= S_IDLE;
    end case;
  end process;

  -----------------------------------------------------------------------------
  -- Sequentielle Logik: Zustandsregister, Datenpfad, Handshakes, Pointer
  -----------------------------------------------------------------------------
  process(clk, reset_n)
    variable rd_base : unsigned(G_ADDR_WIDTH-1 downto 0);
    variable fw_next : unsigned(G_ADDR_WIDTH-1 downto 0);
  begin
    if reset_n = '0' then
      s            <= S_IDLE;
      in_ready_i   <= '1';
      out_valid_i  <= '0';

      wr_en_i      <= '0';
      rd_en_i      <= '0';

      wr_ptr       <= (others => '0');
      wr_addr_i    <= (others => '0');
      rd_addr_i    <= (others => '0');

      inL_reg      <= (others => '0');
      inR_reg      <= (others => '0');
      delayed_L    <= (others => '0');
      delayed_R    <= (others => '0');
      yL           <= (others => '0');
      yR           <= (others => '0');

      wr_data_i    <= (others => '0');

      filled_words <= (others => '0');
      primed       <= '0';

    elsif rising_edge(clk) then
      -- Defaults für Ein-Takt-Steuersignale
      wr_en_i     <= '0';
      rd_en_i     <= '0';
      out_valid_i <= '0';

      s <= s_next;

      case s is

        -- ---------------------------------------------------------------
        -- S_IDLE: Warten auf neues Stereo-Frame
        -- ---------------------------------------------------------------
        when S_IDLE =>
          in_ready_i <= '1';
          -- Priming-Status zyklisch aktualisieren (robust gegenüber laufender Änderung von delay)
          if filled_words >= delay_words then
            primed <= '1';
          else
            primed <= '0';
          end if;

          if in_valid = '1' and in_ready_i = '1' then
            -- Eingang registrieren
            inL_reg <= signed(in_L);
            inR_reg <= signed(in_R);

            -- Lesebasisadresse: wr_ptr - delay_words (mod 2^W) \u2192 zeigt auf verzögertes L
            rd_base   := mod_sub(wr_ptr, delay_words);
            rd_addr_i <= rd_base;             -- L-Adresse
            rd_ptr_L  <= rd_base;
            rd_ptr_R  <= rd_base + 1;         -- R ist +1

            -- ersten Read starten
            rd_en_i    <= '1';
            in_ready_i <= '0';
          end if;

        -- ---------------------------------------------------------------
        -- S_RD_L: Puls wurde bereits in IDLE gesetzt
        -- ---------------------------------------------------------------
        when S_RD_L =>
          null;

        -- ---------------------------------------------------------------
        -- S_WAIT_L: auf L-Daten warten
        -- ---------------------------------------------------------------
        when S_WAIT_L =>
          if rd_valid = '1' then
            delayed_L <= signed(rd_data);
            -- direkt R-Read anstoßen
            rd_addr_i <= rd_ptr_R;
            rd_en_i   <= '1';
          end if;

        -- ---------------------------------------------------------------
        -- S_RD_R: Puls gesetzt \u2192 weiter zu WAIT_R
        -- ---------------------------------------------------------------
        when S_RD_R =>
          null;

        -- ---------------------------------------------------------------
        -- S_WAIT_R: auf R-Daten warten
        -- ---------------------------------------------------------------
        when S_WAIT_R =>
          if rd_valid = '1' then
            delayed_R <= signed(rd_data);
          end if;

        -- ---------------------------------------------------------------
        -- S_CALC: y = x + g * delayed (pro Kanal, saturierend)
        -- ---------------------------------------------------------------
        when S_CALC =>
          yL <= sat_add_s16(inL_reg, mul_q15_s16(delayed_eff_L, g_q15));
          yR <= sat_add_s16(inR_reg, mul_q15_s16(delayed_eff_R, g_q15));

        -- ---------------------------------------------------------------
        -- S_WR_L: L-Wort schreiben
        -- ---------------------------------------------------------------
        when S_WR_L =>
          wr_addr_i <= wr_ptr;                           -- L an wr_ptr
          wr_data_i <= std_logic_vector(yL);
          wr_en_i   <= '1';

        -- ---------------------------------------------------------------
        -- S_WR_L_HOLD: 1 Takt halten (für einfachen SRAM_Control)
        -- ---------------------------------------------------------------
        when S_WR_L_HOLD =>
          null;

        -- ---------------------------------------------------------------
        -- S_WR_R: R-Wort schreiben
        -- ---------------------------------------------------------------
        when S_WR_R =>
          wr_addr_i <= wr_ptr + 1;                       -- R an wr_ptr+1
          wr_data_i <= std_logic_vector(yR);
          wr_en_i   <= '1';

        -- ---------------------------------------------------------------
        -- S_WR_R_HOLD: Abschluss, Pointer/Priming updaten, out_valid pulsen
        -- ---------------------------------------------------------------
        when S_WR_R_HOLD =>
          -- Schreibzeiger um 2 Wörter (ein Stereo-Frame) weiter (mod 2^W)
          wr_ptr      <= wr_ptr + 2;

          -- Priming: geschriebenen Umfang (in WÖRTERN) saturierend hochzählen
          fw_next := filled_words + 2;
          if fw_next < filled_words then
            -- Überlauf (theoretisch bei voller Runde) \u2192 auf max saturieren
            filled_words <= (others => '1');
          else
            filled_words <= fw_next;
          end if;

          out_valid_i <= '1';
          in_ready_i  <= '1';

        when others =>
          null;
      end case;
    end if;
  end process;

  -- Hinweise:
  --  * Beim ersten Start sind SRAM-Inhalte undefiniert. Priming sorgt dafür, dass
  --    bis zur Pufferfüllung das delayed-Signal 0 ist \u2192 kein Startknacksen.
  --  * Änderung von 'delay_samples' wirkt sofort; Priming vergleicht laufend
  --    'filled_words' mit 'delay_words'.
  --  * Für 44,1 kHz hast du >1e6 Takte zwischen Frames (bei 50 MHz) \u2192 reichlich Luft.
  --  * Wenn deine Quelle kein Back-pressure (in_ready) kann, setze einen kleinen FIFO vor.
end architecture;


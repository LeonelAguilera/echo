--
-- VHDL Architecture echo_lib.echo_logic.behav
--
-- Created:
--          by - antmo328.student-liu.se (muxen2-104.ad.liu.se)
--          at - 14:31:37 10/07/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--

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
      clk             : IN     std_logic;
      audio_in_L      : IN     std_logic_vector (G_DATA_WIDTH-1 DOWNTO 0);
      audio_in_R      : IN     std_logic_vector (G_DATA_WIDTH-1 DOWNTO 0);
      audio_out_L     : OUT    std_logic_vector (G_DATA_WIDTH-1 DOWNTO 0);
      audio_out_R     : OUT    std_logic_vector (G_DATA_WIDTH-1 DOWNTO 0);
      audio_in_ready  : OUT    std_logic;
      audio_in_valid  : IN     std_logic;
      audio_out_valid : OUT    std_logic;
      wr_en           : OUT    std_logic;
      wr_addr         : OUT    std_logic_vector (G_ADDR_WIDTH-1 DOWNTO 0);
      wr_data         : OUT    std_logic_vector (G_DATA_WIDTH-1 DOWNTO 0);
      rd_en           : OUT    std_logic;
      rd_addr         : OUT    std_logic_vector (G_ADDR_WIDTH-1 DOWNTO 0);
      rd_valid        : IN     std_logic;
      rd_data         : IN     std_logic_vector (G_DATA_WIDTH-1 DOWNTO 0);
      echo_disable    : IN     std_logic;
      g_feedback_q15  : IN     std_logic_vector (15 DOWNTO 0);
      delay_samples   : IN     std_logic_vector (18 DOWNTO 0);
      RESET_N         : OUT    std_logic
   );

-- Declarations

END echo_logic ;


ARCHITECTURE behav OF echo_logic IS
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

-- Multipliziert signed Audio (Q1.15) mit unsigned Dämpfungsfaktor (0..1)
  function mul_q15u_s16(x : signed(15 downto 0); g : unsigned(15 downto 0)) return signed is
    variable x32  : signed(31 downto 0);
    variable g32  : signed(31 downto 0);
    variable prod : signed(31 downto 0);
    variable shr  : signed(31 downto 0);
    variable y    : signed(15 downto 0);
  begin
    x32 := resize(x, 32);
    g32 := signed(resize(g, 32));
    prod := resize(x32 * g32, 32);  
    shr := shift_right(prod + to_signed(16384, 32), 15);
  
    if shr > to_signed( 32767, 32) then
      y := to_signed( 32767, 16);
    elsif shr < to_signed(-32768, 32) then
      y := to_signed(-32768, 16);
    else
      y := signed(shr(15 downto 0));
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
  type state_t is (S_IDLE, S_RD_L, S_WAIT_L, S_RD_R, S_WAIT_R, S_CALC, S_WR_L, S_WR_L_HOLD, S_WR_R, S_WR_R_HOLD);

  signal s, s_next : state_t := S_IDLE;

  signal inL_reg, inR_reg : signed(15 downto 0) := (others => '0'); -- Eingangslatch pro Stereo-Frame
  signal g_q15         : unsigned(15 downto 0);                               -- Gain als signed (Q1.15)
  signal delay_words   : unsigned(G_ADDR_WIDTH-1 downto 0);           -- Delay in Wörtern (Stereo interleaved -> *2)
  signal wr_ptr        : unsigned(G_ADDR_WIDTH-1 downto 0) := (others => '0');-- Ringpuffer-Schreibzeiger (zeigt aufs L-Wort; R = L+1)
  signal rd_ptr_L      : unsigned(G_ADDR_WIDTH-1 downto 0);           -- Leseadresse L
  signal rd_ptr_R      : unsigned(G_ADDR_WIDTH-1 downto 0);           -- Leseadresse L
  signal delayed_L     : signed(15 downto 0) := (others => '0');
  signal delayed_R     : signed(15 downto 0) := (others => '0');
  signal delayed_eff_L : signed(15 downto 0) := (others => '0');
  signal delayed_eff_R : signed(15 downto 0) := (others => '0');
  signal yL, yR        : signed(15 downto 0) := (others => '0');
  signal in_ready_i    : std_logic := '1';                            -- Flow Control / Handshakes
  signal out_valid_i   : std_logic := '0';                            -- Flow Control / Handshakes
  signal wr_en_i       : std_logic := '0';
  signal rd_en_i       : std_logic := '0';
  signal wr_addr_i     : unsigned(G_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal rd_addr_i     : unsigned(G_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal wr_data_i     : std_logic_vector(G_DATA_WIDTH-1 downto 0) := (others => '0');
  signal filled_words  : unsigned(G_ADDR_WIDTH-1 downto 0) := (others => '0'); -- words in SRAM
  signal primed        : std_logic := '0';                                     -- flag for filled SRAM

begin
-----------------------------------------------------------------------------
-- I/O-Zuweisungen
-----------------------------------------------------------------------------
  audio_in_ready  <= in_ready_i;
  audio_out_valid <= out_valid_i;

  wr_en   <= wr_en_i;
  rd_en   <= rd_en_i;
  wr_addr <= std_logic_vector(wr_addr_i);
  rd_addr <= std_logic_vector(rd_addr_i);
  wr_data <= wr_data_i;

  audio_out_L   <= std_logic_vector(yL);
  audio_out_R   <= std_logic_vector(yR);

  -- Steuerparameter intern
  g_q15 <= unsigned(g_feedback_q15);

  -- delay_words = delay_samples * 2 (Stereo interleaved - zwei Wörter pro Sample)
  delay_words <= resize(shift_left(delay_samples, 1), delay_words'length);

  -- Priming: effektive delayed-Werte (vor Calc, kombinatorisch)
  delayed_eff_L <= delayed_L when primed = '1' else (others => '0');
  delayed_eff_R <= delayed_R when primed = '1' else (others => '0');

-----------------------------------------------------------------------------
-- Nächster Zustand (kombinatorisch)
-----------------------------------------------------------------------------
  process(s, audio_in_valid, in_ready_i, rd_valid, echo_disable)
  begin
    s_next <= s;

    case s is
      when S_IDLE =>
        if audio_in_valid = '1' and in_ready_i = '1' then
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
      -- Defaults f? Ein-Takt-Steuersignale
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
          if filled_words >= delay_words then
            primed <= '1';
          else
            primed <= '0';
          end if;

          if audio_in_valid = '1' and in_ready_i = '1' then
            inL_reg <= signed(audio_in_L);
            inR_reg <= signed(audio_in_R);
            rd_base   := mod_sub(wr_ptr, delay_words);
            rd_addr_i <= rd_base;             -- L-Adresse
            rd_ptr_L  <= rd_base;
            rd_ptr_R  <= rd_base + 1;         -- R ist +1
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
            -- direkt R-Read ansto?n
            rd_addr_i <= rd_ptr_R;
            rd_en_i   <= '1';
          end if;
-- ---------------------------------------------------------------
-- S_RD_R: Puls gesetzt -> weiter zu WAIT_R
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
          if echo_disable = '1' then
            yL <= inL_reg;
            yR <= inR_reg;
          else
            yL <= sat_add_s16(inL_reg, mul_q15u_s16(delayed_eff_L, g_q15));
            yR <= sat_add_s16(inR_reg, mul_q15u_s16(delayed_eff_R, g_q15));
          end if;
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
          wr_ptr      <= wr_ptr + 2;
          fw_next := filled_words + 2;
          if fw_next < filled_words then
            filled_words <= (others => '1'); 
          else
            filled_words <= fw_next;
          end if;
          out_valid_i <= '1';
          in_ready_i  <= '1';

        when others => null;
      end case;
    end if;
  end process;
end architecture;

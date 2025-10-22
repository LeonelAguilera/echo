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
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity echo_logic is
  generic(
    G_ADDR_WIDTH : natural := 20;  -- physische Adressbreite
    G_DATA_WIDTH : natural := 16
  );
  port(
    clk             : in  std_logic;
    reset_n         : in  std_logic;

    audio_in_L      : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);
    audio_in_R      : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);
    audio_out_L     : out std_logic_vector(G_DATA_WIDTH-1 downto 0);
    audio_out_R     : out std_logic_vector(G_DATA_WIDTH-1 downto 0);
    audio_in_ready  : out std_logic;
    audio_in_valid  : in  std_logic;
    audio_out_valid : out std_logic;

    -- Interface zum SRAM-Controller (physische Adressen!)
    wr_en   : out std_logic;
    wr_addr : out std_logic_vector(G_ADDR_WIDTH-1 downto 0);
    wr_data : out std_logic_vector(G_DATA_WIDTH-1 downto 0);
    rd_en   : out std_logic;
    rd_addr : out std_logic_vector(G_ADDR_WIDTH-1 downto 0);
    rd_valid: in  std_logic;
    rd_data : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);

    -- Echo-Parameter
    echo_disable   : in  std_logic;
    g_feedback_q15 : in  std_logic_vector(15 downto 0);  -- 0..0x7FFF ~ 0..~1.0
    delay_samples  : in  std_logic_vector(18 downto 0)   -- Anzahl Stereo-Samples Delay
  );
end entity;

architecture behav of echo_logic is

  -- ===== Helpers =====
  function sat_add_s16(a, b : signed(15 downto 0)) return signed is
    variable tmp : signed(16 downto 0);
    variable res : signed(15 downto 0);
  begin
    tmp := resize(a, 17) + resize(b, 17);
    if    tmp > to_signed( 32767, 17) then res := to_signed( 32767, 16);
    elsif tmp < to_signed(-32768, 17) then res := to_signed(-32768, 16);
    else res := signed(tmp(15 downto 0));
    end if;
    return res;
  end function;

  function mul_q15u_s16(x : signed(15 downto 0); g : unsigned(15 downto 0)) return signed is
    constant W_X  : natural := 32;
    constant W_G  : natural := 17;
    constant FRAC : natural := 15;
    variable x32  : signed(W_X-1 downto 0);
    variable g17  : signed(W_G-1 downto 0);
    variable prod : signed(W_X+W_G-2 downto 0);
    variable acc  : signed(prod'range);
    variable shf  : signed(prod'range);
    variable y    : signed(15 downto 0);
  begin
    x32 := resize(x, W_X);
    g17 := signed('0' & g);
    prod := resize(x32 * g17, prod'length);
    acc  := prod + to_signed(2**(FRAC-1), prod'length);
    shf  := shift_right(acc, FRAC);
    if    shf > to_signed( 32767, shf'length) then y := to_signed( 32767, 16);
    elsif shf < to_signed(-32768, shf'length) then y := to_signed(-32768, 16);
    else y := resize(shf, 16);
    end if;
    return y;
  end function;

  -- (a - b) mod 2^N (unsigned wrap)
  function mod_sub(a, b : unsigned) return unsigned is
    variable aa : unsigned(a'range) := a;
    variable bb : unsigned(a'range) := resize(b, a'length);
  begin
    return aa - bb;
  end function;

  -- ===== FSM =====
  type state_t is (
    S_IDLE, S_RD_L, S_WAIT_L, S_RD_R, S_WAIT_R,
    S_CALC, S_WR_L, S_WR_L_HOLD, S_WR_R, S_WR_R_HOLD
  );
  signal s, s_next : state_t := S_IDLE;

  -- ===== Datenpfad / Register =====
  signal inL_reg, inR_reg : signed(15 downto 0) := (others => '0');
  signal yL, yR           : signed(15 downto 0) := (others => '0');

  signal delayed_L, delayed_R     : signed(15 downto 0) := (others => '0');
  signal delayed_eff_L, delayed_eff_R : signed(15 downto 0);

  signal wr_ptr   : unsigned(G_ADDR_WIDTH-1 downto 0) := (others => '0');  -- Basisadresse pro Frame (physisch, gerade)
  signal rd_ptr_L : unsigned(G_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal rd_ptr_R : unsigned(G_ADDR_WIDTH-1 downto 0) := (others => '0');

  signal delay_words : unsigned(G_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal g_q15       : unsigned(15 downto 0);

  signal in_ready_i  : std_logic := '1';
  signal out_valid_i : std_logic := '0';
  signal wr_en_i     : std_logic := '0';
  signal rd_en_i     : std_logic := '0';
  signal wr_addr_i   : unsigned(G_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal rd_addr_i   : unsigned(G_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal wr_data_i   : std_logic_vector(G_DATA_WIDTH-1 downto 0) := (others => '0');

  signal filled_words: unsigned(G_ADDR_WIDTH-1 downto 0) := (others => '0'); -- Anzahl geschriebener Worte
  signal primed      : std_logic := '0';
  
  
  -- neue ptr für even =================================================================================
  --signal wr_ptr_even : unsigned(G_ADDR_WIDTH-1 downto 0);
  
begin
  -- ===== I/O =====
  audio_in_ready  <= in_ready_i;
  audio_out_valid <= out_valid_i;

  wr_en   <= wr_en_i;
  rd_en   <= rd_en_i;
  wr_addr <= std_logic_vector(wr_addr_i);
  rd_addr <= std_logic_vector(rd_addr_i);
  wr_data <= wr_data_i;

  audio_out_L <= std_logic_vector(yL);
  audio_out_R <= std_logic_vector(yR);

  g_q15 <= unsigned(g_feedback_q15);

  -- *** WICHTIG: physische Adressierung (A0 benutzt) ? *4 Worte pro Stereo-Sample ***
  delay_words <= shift_left(resize(unsigned(delay_samples), delay_words'length), 1);  -- *4

  -- effektive delayed-Werte erst nach ?Priming?
  delayed_eff_L <= delayed_L when primed = '1' else (others => '0');
  delayed_eff_R <= delayed_R when primed = '1' else (others => '0');

  --------------------------------------------------------------------
  -- Next state
  --------------------------------------------------------------------
  process (s, audio_in_valid, in_ready_i, rd_valid)
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

  --------------------------------------------------------------------
  -- Sequentiell: Zustände / Handshakes / Adressen
  --------------------------------------------------------------------
  process (clk, reset_n)
    variable rd_base : unsigned(G_ADDR_WIDTH-1 downto 0);
    variable fw_next : unsigned(G_ADDR_WIDTH-1 downto 0);
    variable base_even: unsigned(G_ADDR_WIDTH-1 downto 0);  -- NEU
    variable w_even   : unsigned(G_ADDR_WIDTH-1 downto 0);
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
      -- Defaults pro Takt
      wr_en_i     <= '0';
      rd_en_i     <= '0';
      out_valid_i <= '0';

      s <= s_next;

      case s is
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

            -- Frame-Basis EVEN (A0 = 0)
            base_even := wr_ptr;
            base_even(0) := '0';

          -- Delay-Read-Basis (ebenfalls even)
            rd_base := mod_sub(base_even, delay_words);
            rd_base(0) := '0';

          -- Read L starten
            rd_ptr_L  <= rd_base;       -- L @ base
            rd_ptr_R  <= rd_base + 1;   -- R @ base+1
            rd_addr_i <= rd_base;
            rd_en_i   <= '1';

            in_ready_i <= '0';
          end if;

        -- ===== neues Stereo-Frame annehmen, L-Read starten =====
        --  when S_IDLE =>
        --    in_ready_i <= '1';
        --    if filled_words >= delay_words then
        --     primed <= '1';
        --    else
        --      primed <= '0';
        --    end if;

        --    if audio_in_valid = '1' and in_ready_i = '1' then
        --      inL_reg <= signed(audio_in_L);
        --      inR_reg <= signed(audio_in_R);

            -- Basisadresse für den Delay-Read (physische Worte!)
        --      rd_base  := mod_sub(wr_ptr, delay_words);
        --      rd_ptr_L <= rd_base;          -- L liest @ base
        --      rd_ptr_R <= rd_base + 1;      -- R liest @ base+2 (A0 benutzt ? nächstes Wort = +2)

        --      rd_addr_i <= rd_base;
        --      rd_en_i   <= '1';

        --      in_ready_i <= '0';
        --    end if;

        when S_RD_L =>
          null;

        -- ===== L-Daten übernehmen =====
        when S_WAIT_L =>
          if rd_valid = '1' then
            delayed_L <= signed(rd_data);
          end if;

        -- ===== R-Read jetzt pulsen =====
        when S_RD_R =>
          rd_addr_i <= rd_ptr_R;
          rd_en_i   <= '1';

        -- ===== R-Daten übernehmen =====
        when S_WAIT_R =>
          if rd_valid = '1' then
            delayed_R <= signed(rd_data);
          end if;

        -- ===== Ausgabe berechnen =====
        when S_CALC =>
          if echo_disable = '1' then
            yL <= inL_reg;
            yR <= inR_reg;
          else
            yL <= sat_add_s16(inL_reg, mul_q15u_s16(delayed_eff_L, g_q15));
            yR <= sat_add_s16(inR_reg, mul_q15u_s16(delayed_eff_R, g_q15));
          end if;

        -- ===== Schreiben L @ wr_ptr =====
        when S_WR_L =>
          --  wr_addr_i <= wr_ptr;
          --  wr_data_i <= std_logic_vector(yL);
          --  wr_en_i   <= '1';
          w_even := wr_ptr;
          w_even(0) := '0';

          wr_addr_i <= w_even;                  -- L @ base
          wr_data_i <= std_logic_vector(yL);
          wr_en_i   <= '1';
        when S_WR_L_HOLD =>
          null;

        -- ===== Schreiben R @ wr_ptr+2 =====
        when S_WR_R =>
          -- wr_addr_i <= wr_ptr + 1;
          -- wr_data_i <= std_logic_vector(yR);
          -- wr_en_i   <= '1';

          w_even := wr_ptr;
          w_even(0) := '0';

          wr_addr_i <= w_even + 1;              -- R @ base+1
          wr_data_i <= std_logic_vector(yR);
          wr_en_i   <= '1';

        -- ===== Abschluss, Pointer/Füllstand/Nächster Frame =====
        when S_WR_R_HOLD =>
          --  wr_ptr <= wr_ptr + 2;   -- nächstes Stereo-Frame (L@+0, R@+2)
          --  fw_next := filled_words + 2;
          --  if fw_next < filled_words then
          --    filled_words <= (others => '1'); -- Wrap erkannt
          --  else
          --    filled_words <= fw_next;
          --  end if;
          --  out_valid_i <= '1';
          --  in_ready_i  <= '1';

          w_even := wr_ptr;
          w_even(0) := '0';
          wr_ptr <= w_even + 2;

          fw_next := filled_words + 2;          -- +2 Worte pro Stereo-Frame
          if fw_next < filled_words then
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

end architecture;


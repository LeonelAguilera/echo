LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
LIBRARY echo_lib;
USE echo_lib.keyboard_package.ALL;


ENTITY sram_ctrl IS
   GENERIC( 
      G_ADDR_WIDTH : natural := 20;
      G_DATA_WIDTH : natural := 16
   );
   PORT( 
      rd_valid  : OUT    std_logic;
      SRAM_ADDR : OUT    std_logic_vector (G_ADDR_WIDTH-1 DOWNTO 0);
      SRAM_DQ   : INOUT  std_logic_vector (G_DATA_WIDTH-1 DOWNTO 0);
      SRAM_CE_N : OUT    std_logic;
      SRAM_OE_N : OUT    std_logic;
      SRAM_WE_N : OUT    std_logic;
      SRAM_UB_N : OUT    std_logic;
      SRAM_LB_N : OUT    std_logic;
      rd_addr   : IN     std_logic_vector (G_ADDR_WIDTH-1 DOWNTO 0);
      rd_en     : IN     std_logic;
      wr_en     : IN     std_logic;
      clk       : IN     std_logic;
      wr_data   : IN     std_logic_vector (G_DATA_WIDTH-1 DOWNTO 0);
      wr_addr   : IN     std_logic_vector (G_ADDR_WIDTH-1 DOWNTO 0);
      rd_data   : OUT    std_logic_vector (G_DATA_WIDTH-1 DOWNTO 0);
      RESET_N   : IN     std_logic
   );

-- Declarations

END sram_ctrl ;

architecture behav of sram_ctrl is
  type state_t is (IDLE, W_SETUP, WRITE, W_HOLD, R_SETUP, READ, R_HOLD);
  signal s, s_n : state_t;

  -- Tri-State Treiber
  signal dq_out      : std_logic_vector(G_DATA_WIDTH-1 downto 0);
  signal dq_dir      : std_logic;  -- '1' = treibt (Write)
  signal rd_data_reg : std_logic_vector(G_DATA_WIDTH-1 downto 0);

  -- ===== Write-Queue (Tiefe 2) =====
  signal wr_v0, wr_v1 : std_logic := '0';
  signal wr_a0, wr_a1 : std_logic_vector(G_ADDR_WIDTH-1 downto 0);
  signal wr_d0, wr_d1 : std_logic_vector(G_DATA_WIDTH-1 downto 0);

  -- aktueller Write-Datensatz (wird in W_SETUP -> WRITE benutzt)
  signal wr_a_cur     : std_logic_vector(G_ADDR_WIDTH-1 downto 0);
  signal wr_d_cur     : std_logic_vector(G_DATA_WIDTH-1 downto 0);

  -- ===== Read-Pending (ein Slot) =====
  signal rd_addr_l    : std_logic_vector(G_ADDR_WIDTH-1 downto 0);
  signal rd_pend      : std_logic := '0';

  -- Pending-ORs für Next-State
  signal pending_wr   : std_logic;
  signal pending_rd   : std_logic;
begin
  -- Statische Pins
  SRAM_CE_N <= '0';  -- immer selektiert
  SRAM_UB_N <= '0';  -- Upper/Lower Byte immer aktiv (16-bit Wort)
  SRAM_LB_N <= '0';

  -- Tri-State Daten
  SRAM_DQ  <= dq_out when dq_dir='1' else (others => 'Z');
  rd_data  <= rd_data_reg;

  -- Pending-Aggregate
  pending_wr <= wr_v0 or wr_v1;
  pending_rd <= rd_pend;

  -- ===================== Next-State-Logik (auf Pendings) ====================
  process(s, pending_wr, pending_rd)
  begin
    s_n <= s;
    case s is
      when IDLE =>
        if    pending_wr='1' then s_n <= W_SETUP;
        elsif pending_rd='1' then s_n <= R_SETUP;
        end if;

      when W_SETUP => s_n <= WRITE;
      when WRITE   => s_n <= W_HOLD;

      when W_HOLD =>
        if    pending_wr='1' then s_n <= W_SETUP;
        elsif pending_rd='1' then s_n <= R_SETUP;
        else                     s_n <= IDLE;
        end if;

      when R_SETUP => s_n <= READ;
      when READ    => s_n <= R_HOLD;

      when R_HOLD  =>
        if    pending_wr='1' then s_n <= W_SETUP;
        elsif pending_rd='1' then s_n <= R_SETUP;
        else                     s_n <= IDLE;
        end if;
    end case;
  end process;

  -- ===================== Sequentielle Logik ================================
  process(clk, RESET_N)
  begin
    if RESET_N='0' then
      s           <= IDLE;
      dq_dir      <= '0';
      dq_out      <= (others => '0');
      SRAM_ADDR   <= (others => '0');
      SRAM_WE_N   <= '1';
      SRAM_OE_N   <= '1';
      rd_data_reg <= (others => '0');
      rd_valid    <= '0';

      wr_v0       <= '0';
      wr_v1       <= '0';
      wr_a0       <= (others => '0');
      wr_a1       <= (others => '0');
      wr_d0       <= (others => '0');
      wr_d1       <= (others => '0');
      wr_a_cur    <= (others => '0');
      wr_d_cur    <= (others => '0');

      rd_addr_l   <= (others => '0');
      rd_pend     <= '0';

    elsif rising_edge(clk) then
      s        <= s_n;
      rd_valid <= '0';     -- default in jedem Takt

      -- ====== ENQUEUE: Write-Requests (Tiefe 2) ======
      if wr_en = '1' then
        if wr_v0 = '0' then
          wr_a0 <= wr_addr;
          wr_d0 <= wr_data;
          wr_v0 <= '1';
        elsif wr_v1 = '0' then
          wr_a1 <= wr_addr;
          wr_d1 <= wr_data;
          wr_v1 <= '1';
        else
          -- Overflow (sollte bei L/R nicht passieren) -> letzte überdeckt
          wr_a1 <= wr_addr;
          wr_d1 <= wr_data;
          wr_v1 <= '1';
        end if;
      end if;

      -- ====== ENQUEUE: Read-Request ======
      if rd_en = '1' then
        rd_addr_l <= rd_addr;
        rd_pend   <= '1';
      end if;

      -- ====== Ausgänge / Dequeue je Zustand ======
      case s is
        when IDLE =>
          dq_dir    <= '0';
          SRAM_WE_N <= '1';
          SRAM_OE_N <= '1';

        -- ---- WRITE ----
        when W_SETUP =>
          -- sicherstellen: Slot0 befüllt (falls nur Slot1 voll -> nach vorne ziehen)
          if (wr_v0 = '0') and (wr_v1 = '1') then
            wr_a0 <= wr_a1; wr_d0 <= wr_d1; wr_v0 <= '1';
            wr_v1 <= '0';
          end if;

          if wr_v0 = '1' then
            -- aktuellen Datensatz abholen
            wr_a_cur <= wr_a0;
            wr_d_cur <= wr_d0;
            wr_v0    <= '0';        -- Slot0 verbraucht
          end if;

          dq_dir     <= '1';
          dq_out     <= wr_d_cur;
          SRAM_ADDR  <= wr_a_cur;
          SRAM_WE_N  <= '1';
          SRAM_OE_N  <= '1';

        when WRITE =>
          dq_dir     <= '1';
          dq_out     <= wr_d_cur;
          SRAM_ADDR  <= wr_a_cur;
          SRAM_WE_N  <= '0';  -- schreiben
          SRAM_OE_N  <= '1';

        when W_HOLD =>
          dq_dir     <= '0';
          SRAM_WE_N  <= '1';
          SRAM_OE_N  <= '1';

        -- ---- READ ----
        when R_SETUP =>
          rd_pend    <= '0';        -- diesen Read jetzt bedienen
          dq_dir     <= '0';
          SRAM_ADDR  <= rd_addr_l;
          SRAM_WE_N  <= '1';
          SRAM_OE_N  <= '1';

        when READ =>
          dq_dir     <= '0';
          SRAM_ADDR  <= rd_addr_l;
          SRAM_WE_N  <= '1';
          SRAM_OE_N  <= '0';  -- erster OE-Low-Takt

        when R_HOLD =>
          dq_dir      <= '0';
          SRAM_WE_N   <= '1';
          SRAM_OE_N   <= '0';         -- zweiter OE-Low-Takt
          rd_data_reg <= SRAM_DQ;     -- jetzt stabil
          rd_valid    <= '1';
      end case;
    end if;
  end process;
end architecture;

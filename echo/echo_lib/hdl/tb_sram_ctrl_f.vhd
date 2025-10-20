library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_sram_ctrl_min is
end entity;

architecture sim of tb_sram_ctrl_min is
  ---------------------------------------------------------------------------
  -- SIM-Parameter
  ---------------------------------------------------------------------------
  constant AW     : natural := 12;     -- 4096 Worte fÃ¼r schnelle Sim
  constant DW     : natural := 16;
  constant TCLK   : time    := 20 ns;  -- 50 MHz
  constant T_ACC  : time    := 10 ns;  -- Read access time
  constant T_HZ   : time    := 5 ns;   -- Bus-Release

  ---------------------------------------------------------------------------
  -- DUT <-> TB Signale
  ---------------------------------------------------------------------------
  signal clk       : std_logic := '0';
  signal reset_n   : std_logic := '0';

  -- User-IF
  signal wr_en     : std_logic := '0';
  signal wr_addr   : std_logic_vector(AW-1 downto 0) := (others=>'0');
  signal wr_data   : std_logic_vector(DW-1 downto 0) := (others=>'0');
  signal rd_en     : std_logic := '0';
  signal rd_addr   : std_logic_vector(AW-1 downto 0) := (others=>'0');
  signal rd_data   : std_logic_vector(DW-1 downto 0);
  signal rd_valid  : std_logic;

  -- Physische SRAM-Leitungen (vom DUT getrieben)
  signal SRAM_ADDR : std_logic_vector(AW-1 downto 0);
  signal SRAM_DQ   : std_logic_vector(DW-1 downto 0);
  signal SRAM_CE_N : std_logic;
  signal SRAM_OE_N : std_logic;
  signal SRAM_WE_N : std_logic;
  signal SRAM_UB_N : std_logic;
  signal SRAM_LB_N : std_logic;

  ---------------------------------------------------------------------------
  -- Internes SRAM-VERHALTENSMODELL (in dieser TB, keine Extradatei!)
  --  * Write auf WE_N fallende Flanke (wenn CE aktiv)
  --  * Read treibt DQ nach T_ACC (wenn CE=0, OE=0, WE=1), sonst Z nach T_HZ
  --  * UB/LB (nur bei 16 Bit) werden beachtet
  ---------------------------------------------------------------------------
  type ram_t is array (0 to 2**AW - 1) of std_logic_vector(DW-1 downto 0);
  signal mem         : ram_t := (others => (others => '0'));
  signal dq_from_mem : std_logic_vector(DW-1 downto 0) := (others => 'Z');

  -- Hilfsfunktion
  function a2i(a : std_logic_vector) return integer is
  begin
    return to_integer(unsigned(a));
  end function;

    ---------------------------------------------------------------------------
  -- Stimulus-Hilfsprozeduren (mit signal-Parametern!)
  ---------------------------------------------------------------------------
  procedure do_write(
    signal wr_addr : out std_logic_vector;
    signal wr_data : out std_logic_vector;
    signal wr_en   : out std_logic;
    signal clk     : in  std_logic;
    addr           : in  integer;
    data           : in  std_logic_vector(DW-1 downto 0)
  ) is
  begin
    wr_addr <= std_logic_vector(to_unsigned(addr, wr_addr'length));
    wr_data <= data;
    wr_en   <= '1';
    wait until rising_edge(clk);
    wr_en   <= '0';
    wait until rising_edge(clk);
  end procedure;


  procedure do_read_check(
    signal rd_addr  : out std_logic_vector;
    signal rd_en    : out std_logic;
    signal rd_data  : in  std_logic_vector;
    signal rd_valid : in  std_logic;
    signal clk      : in  std_logic;
    addr            : in  integer;
    exp             : in  std_logic_vector(DW-1 downto 0)
  ) is
  begin
    rd_addr <= std_logic_vector(to_unsigned(addr, rd_addr'length));
    rd_en   <= '1';
    wait until rising_edge(clk);
    rd_en   <= '0';
    loop
      wait until rising_edge(clk);
      exit when rd_valid = '1';
    end loop;
    assert rd_data = exp
      report "READ MISMATCH @addr=" & integer'image(addr)
           & " exp=" & to_hstring(exp)
           & " got=" & to_hstring(rd_data)
      severity error;
  end procedure;


begin
  ---------------------------------------------------------------------------
  -- Takt & Reset
  ---------------------------------------------------------------------------
  clk <= not clk after TCLK/2;

  process
  begin
    reset_n <= '0';
    wait for 200 ns;
    reset_n <= '1';
    wait;
  end process;

  ---------------------------------------------------------------------------
  -- DUT: dein sram_ctrl (GENERIC!)
  ---------------------------------------------------------------------------
  uut: entity work.sram_ctrl
    generic map(
      G_ADDR_WIDTH => AW,
      G_DATA_WIDTH => DW
    )
    port map(
      rd_data   => rd_data,
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
      RESET_N   => reset_n,
      wr_data   => wr_data,
      wr_addr   => wr_addr
    );

  ---------------------------------------------------------------------------
  -- **In-TB SRAM-Modell**: treibt/liest den inout-Bus SRAM_DQ
  ---------------------------------------------------------------------------

  -- Schreiben: WE_N fallende Flanke bei CE_N='0'
  sram_write: process(SRAM_WE_N, SRAM_CE_N)
    variable w  : std_logic_vector(DW-1 downto 0);
    variable da : integer;
  begin
    if (SRAM_CE_N = '0') and (SRAM_WE_N'event and SRAM_WE_N = '0') then
      da := a2i(SRAM_ADDR);
      w  := mem(da);

      if DW = 16 then
        if SRAM_LB_N = '0' then
          w(7 downto 0) := SRAM_DQ(7 downto 0);
        end if;
        if SRAM_UB_N = '0' then
          w(15 downto 8) := SRAM_DQ(15 downto 8);
        end if;
      else
        w := SRAM_DQ;
      end if;

      mem(da) <= w;
    end if;
  end process;

  -- Lesen: Bus treiben, wenn CE=0, OE=0, WE=1; sonst High-Z
  sram_read: process(SRAM_CE_N, SRAM_OE_N, SRAM_WE_N, SRAM_ADDR, SRAM_UB_N, SRAM_LB_N, mem)
    variable rd : std_logic_vector(DW-1 downto 0);
  begin
    dq_from_mem <= (others => 'Z') after T_HZ;

    if (SRAM_CE_N = '0') and (SRAM_OE_N = '0') and (SRAM_WE_N = '1') then
      rd := mem(a2i(SRAM_ADDR));

      if DW = 16 then
        if SRAM_LB_N = '1' then rd(7 downto 0)  := (others => 'Z'); end if;
        if SRAM_UB_N = '1' then rd(15 downto 8) := (others => 'Z'); end if;
      end if;

      dq_from_mem <= rd after T_ACC;
    end if;
  end process;

  -- DQ-Bus treiben (TB-Seite). Der DUT treibt den Bus nur beim WRITE.
  SRAM_DQ <= dq_from_mem;


  ---------------------------------------------------------------------------
  -- STIMULUS & CHECKS
  ---------------------------------------------------------------------------
  stim: process
    variable i : integer;
    variable data_in  : std_logic_vector(DW-1 downto 0);
    variable data_exp : std_logic_vector(DW-1 downto 0);
  begin
    -- Warten auf Reset-Ende
    wait until reset_n = '1';
    wait until rising_edge(clk);

    -------------------------------------------------------------------------
    -- 1) Einfache Einzelzugriffe
    -------------------------------------------------------------------------
    do_write(wr_addr, wr_data, wr_en, clk, 16#0010#, x"1234");
    do_write(wr_addr, wr_data, wr_en, clk, 16#0011#, x"ABCD");
    do_read_check(rd_addr, rd_en, rd_data, rd_valid, clk, 16#0010#, x"1234");
    do_read_check(rd_addr, rd_en, rd_data, rd_valid, clk, 16#0011#, x"ABCD");

    -------------------------------------------------------------------------
    -- 2) Erweiterter Mehrfach-Test (Schreiben ? Lesen ? Neues Schreiben ? Lesen)
    -------------------------------------------------------------------------
    report ">>> STARTE Mehrfachen Schreib/Lese-Test ..." severity note;

    for i in 0 to 31 loop  -- z. B. 32 Adressen testen
      -- Muster 1: z. B. 0x0000, 0x1111, 0x2222, ...
      data_in  := std_logic_vector(to_unsigned(i * 4369, DW)); -- 4369 = 0x1111
      data_exp := data_in;

      -- Schreiben
      do_write(wr_addr, wr_data, wr_en, clk, i, data_in);
      wait until rising_edge(clk);

      -- Lesen & prüfen
      do_read_check(rd_addr, rd_en, rd_data, rd_valid, clk, i, data_exp);

      -- Muster 2: invertierte Daten
      data_in  := not data_in;
      data_exp := data_in;

      -- Wieder schreiben
      do_write(wr_addr, wr_data, wr_en, clk, i, data_in);
      wait until rising_edge(clk);

      -- Wieder lesen & prüfen
      do_read_check(rd_addr, rd_en, rd_data, rd_valid, clk, i, data_exp);
    end loop;

    report ">>> Mehrfach-Test abgeschlossen ? OK" severity note;

    -------------------------------------------------------------------------
    -- Optional: alte Tests wieder aktivieren, falls gewünscht
    -------------------------------------------------------------------------
    -- Checkerboard, Walking Ones, Linear Block etc.
    -- einfach wieder einkommentieren

    -------------------------------------------------------------------------
    -- Testende
    -------------------------------------------------------------------------
    report "sram_ctrl TB PASSED." severity note;
    wait;
  end process;

end architecture;


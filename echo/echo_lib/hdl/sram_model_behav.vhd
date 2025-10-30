library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sram_model is
  generic (
    G_ADDR_WIDTH : natural := 20;   -- Worte
    G_DATA_WIDTH : natural := 16    -- 16-bit
  );
  port (
    SRAM_ADDR : in    std_logic_vector(G_ADDR_WIDTH-1 downto 0);
    SRAM_DQ   : inout std_logic_vector(G_DATA_WIDTH-1 downto 0);
    SRAM_CE_N : in    std_logic;
    SRAM_OE_N : in    std_logic;
    SRAM_WE_N : in    std_logic;
    SRAM_UB_N : in    std_logic;
    SRAM_LB_N : in    std_logic
  );
end entity;

architecture behav of sram_model is
  constant DEPTH  : natural := 2**G_ADDR_WIDTH;
  constant tACC   : time    := 3 ns;   -- Access time
  constant tDIS   : time    := 1 ns;   -- Disable time

  type ram_t is array (0 to DEPTH-1) of std_logic_vector(G_DATA_WIDTH-1 downto 0);
  signal ram : ram_t := (others => (others => '0'));

  signal dq_drv   : std_logic_vector(G_DATA_WIDTH-1 downto 0) := (others => 'Z');
begin
  -- Tri-state: das Modell treibt den Bus, wenn CE=0, WE=1, OE=0
  SRAM_DQ <= dq_drv;

  -- READ: mit kleinem Delay aus RAM auf den Bus
  process(SRAM_ADDR, SRAM_CE_N, SRAM_OE_N, SRAM_WE_N, SRAM_UB_N, SRAM_LB_N)
    variable a : natural;
    variable d : std_logic_vector(G_DATA_WIDTH-1 downto 0);
  begin
    a := to_integer(unsigned(SRAM_ADDR));

    if SRAM_CE_N='0' and SRAM_WE_N='1' and SRAM_OE_N='0' then
      d := ram(a);
      -- Byte-Enables (falls genutzt)
      if SRAM_LB_N='1' then d(7 downto 0)  := (others => 'Z'); end if;
      if SRAM_UB_N='1' then d(15 downto 8) := (others => 'Z'); end if;
      dq_drv <= d after tACC;
    else
      dq_drv <= (others => 'Z') after tDIS;
    end if;
  end process;

  -- WRITE: wenn CE=0 und WE=0, schreibe DQ in RAM
  process(SRAM_ADDR, SRAM_CE_N, SRAM_WE_N, SRAM_DQ, SRAM_UB_N, SRAM_LB_N)
    variable a : natural;
    variable d : std_logic_vector(G_DATA_WIDTH-1 downto 0);
  begin
    if SRAM_CE_N='0' and SRAM_WE_N='0' then
      a := to_integer(unsigned(SRAM_ADDR));
      d := ram(a);
      if SRAM_LB_N='0' then d(7  downto 0)  := SRAM_DQ(7  downto 0);  end if;
      if SRAM_UB_N='0' then d(15 downto 8)  := SRAM_DQ(15 downto 8);  end if;
      ram(a) <= d;
    end if;
  end process;
end architecture;

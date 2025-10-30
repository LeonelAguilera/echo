LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Clock_div IS
   PORT( 
      CLK_100k : OUT std_logic;
      CLK_200k : OUT std_logic;
      Reset    : IN  std_logic;
      c0       : IN  std_logic  -- 65 MHz
   );
END Clock_div;

ARCHITECTURE DIV OF Clock_div IS

  -------------------------------------------------------------------
  -- Signaler för 100 kHz
  -------------------------------------------------------------------
  signal count_100k   : integer := 0;
  signal clk_100k_int : std_logic := '0';

  -------------------------------------------------------------------
  -- Signaler för 200 kHz
  -------------------------------------------------------------------
  signal count_200k   : integer := 0;
  signal clk_200k_int : std_logic := '0';
  signal toggle_sel   : std_logic := '0';  -- växla mellan 162 och 163

BEGIN
  -------------------------------------------------------------------
  -- Generera 100 kHz
  -------------------------------------------------------------------
  process(c0)
  begin
    if rising_edge(c0) then
      if Reset = '0' then
        count_100k   <= 0;
        clk_100k_int <= '0';
      else
        if count_100k = 324 then        -- toggle var 325:e cykel \u2192 650 totalt \u2192 100kHz
          count_100k   <= 0;
          clk_100k_int <= not clk_100k_int;
        else
          count_100k <= count_100k + 1;
        end if;
      end if;
    end if;
  end process;

  -------------------------------------------------------------------
  -- Generera exakt 200 kHz (växla 162 \u2194 163 cykler)
  -------------------------------------------------------------------
  process(c0)
  begin
    if rising_edge(c0) then
      if Reset = '0' then
        count_200k   <= 0;
        clk_200k_int <= '0';
        toggle_sel   <= '0';
      else
        if (toggle_sel = '0' and count_200k = 161) or
           (toggle_sel = '1' and count_200k = 162) then
          count_200k   <= 0;
          clk_200k_int <= not clk_200k_int;
          toggle_sel   <= not toggle_sel;  -- växla nästa gång
        else
          count_200k <= count_200k + 1;
        end if;
      end if;
    end if;
  end process;

  -------------------------------------------------------------------
  -- Utgångar
  -------------------------------------------------------------------
  CLK_100k <= clk_100k_int;
  CLK_200k <= clk_200k_int;

END ARCHITECTURE DIV;

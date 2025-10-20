--
-- VHDL Architecture echo_lib.kb_block.behav
--
-- Created:
--          by - antmo328.student-liu.se (muxen2-102.ad.liu.se)
--          at - 15:52:04 10/17/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY kb_block IS
   PORT(
      KB_SCAN_CODE  : IN  std_logic;              -- serielles Datenbit (LSB first)
      KB_SCAN_VALID : IN  std_logic;              -- 1 Takt lang: dieses Bit ist gültig
      RESET_N       : IN  std_logic;
      clk           : IN  std_logic;
      ctrl_sig      : OUT std_logic_vector (5 DOWNTO 0)  -- [0]=H, [1]=J, [2]=K, [3]=L, [4]=E, [5]=unused
   );
END kb_block;

ARCHITECTURE behav OF kb_block IS
  -- Scan-Set-2 (MAKE) Codes:
  constant SC_H : std_logic_vector(7 downto 0) := x"33";
  constant SC_J : std_logic_vector(7 downto 0) := x"3B";
  constant SC_K : std_logic_vector(7 downto 0) := x"42";
  constant SC_L : std_logic_vector(7 downto 0) := x"4B";
  constant SC_E : std_logic_vector(7 downto 0) := x"24";

  signal ctrl_r     : std_logic_vector(5 downto 0) := (others => '0');
  signal shift_reg  : std_logic_vector(7 downto 0) := (others => '0'); -- sammelt LSB->MSB
  signal bit_count  : unsigned(2 downto 0) := (others => '0');         -- 0..7
BEGIN
  ctrl_sig <= ctrl_r;

  process(clk, RESET_N)
    variable byte_now : std_logic_vector(7 downto 0);
  begin
    if RESET_N = '0' then
      ctrl_r    <= (others => '0');
      shift_reg <= (others => '0');
      bit_count <= (others => '0');

    elsif rising_edge(clk) then
      -- Standard: Ausgänge sind 1-Takt-Pulse
      ctrl_r <= (others => '0');

      if KB_SCAN_VALID = '1' then
        -- LSB-first einsammeln: neues Bit an MSB-Position? => nein, ans LSB-Ende!
        -- Wir schieben nach links und hängen das neue Bit an das MSB ODER
        -- schieben nach rechts und hängen an LSB. Für LSB-first ist es sauber,
        -- das neue Bit ans MSB zu setzen und später zu drehen ? hier einfacher:
        -- shift_reg <= shift_reg(6 downto 0) & KB_SCAN_CODE;  -- neues Bit an MSB-Seite? -> NEIN!
        -- Korrekt (LSB-first): neues Bit kommt an die Stelle 'bit_count'
        shift_reg(to_integer(bit_count)) <= KB_SCAN_CODE;

        if bit_count = 7 then
          -- Byte komplett
          byte_now := shift_reg;  -- enthält LSB->MSB korrekt
          -- one-hot Pulse setzen
          if    byte_now = SC_H then ctrl_r(0) <= '1';
          elsif byte_now = SC_J then ctrl_r(1) <= '1';
          elsif byte_now = SC_K then ctrl_r(2) <= '1';
          elsif byte_now = SC_L then ctrl_r(3) <= '1';
          elsif byte_now = SC_E then ctrl_r(4) <= '1';
          end if;

          -- zurücksetzen für nächstes Byte
          bit_count <= (others => '0');
          -- (shift_reg wird beim Einsammeln überschrieben)

        else
          bit_count <= bit_count + 1;
        end if;
      end if;
    end if;
  end process;
END ARCHITECTURE behav;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity i2c_init is
   port(
      Reset : in  std_logic;
      c0    : in  std_logic;  -- 65 MHz system clock
      CLK   : in  std_logic;  -- 100 kHz bit clock (dividerad)
      SDA   : out std_logic;
      SCL   : out std_logic
   );
end i2c_init;

architecture init of i2c_init is

    ----------------------------------------------------------------
    -- 1) ROM för SDA och SCL
    --    Här kan du ändra bitmönsterna precis som du vill.
    ----------------------------------------------------------------
    constant Bits_SDA : integer := 28;
    signal SDA_rom : std_logic_vector(Bits_SDA-1 downto 0) :=
        "1000110100100000111111001101";  -- Exempeldata (du kan ändra)

    constant Bits_SCL : integer := 33;
    signal SCL_rom : std_logic_vector(Bits_SCL-1 downto 0) :=
        "111010101010101010101010101010101"; -- Exempel på 4 pulser

    ----------------------------------------------------------------
    -- 2) Parametrar
    ----------------------------------------------------------------
    -- Hur länge varje SDA-bit ska gälla (styrt av CLK)
    -- (Denna styrs indirekt av din 100 kHz klocka)
    --
    -- Hur länge varje SCL-bit ska hållas i c0-cykler
    constant SCL_STRETCH : integer := 170;  -- 325 * 15.38ns ? 5 µs per bit ? 100 kHz SCL

    ----------------------------------------------------------------
    -- 3) Signaler
    ----------------------------------------------------------------
    signal bit_index       : integer range 0 to Bits_SDA := 0;
    signal SDA_reg         : std_logic := '1';

    signal enable_scl      : std_logic := '0';
    signal SCL_reg         : std_logic := '1';

    signal scl_index       : integer range 0 to Bits_SCL := 0;
    signal scl_hold_count  : integer range 0 to SCL_STRETCH := 0;

begin

    SDA <= SDA_reg;
    SCL <= SCL_reg;

    ----------------------------------------------------------------
    -- 4) SDA-process (styrs av 100 kHz-CLK)
    ----------------------------------------------------------------
    process(CLK, Reset)
    begin
        if Reset = '1' then
            bit_index  <= 0;
            SDA_reg    <= '1';
            enable_scl <= '0';
        elsif rising_edge(CLK) then
            if bit_index < Bits_SDA then
                SDA_reg <= SDA_rom(Bits_SDA-1 - bit_index);
                enable_scl <= '1'; -- tillåt SCL att börja gå
                bit_index <= bit_index + 1;
            else
                enable_scl <= '0';
                SDA_reg <= '1'; -- återställ SDA till idle (1)
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- 5) SCL-process (styrd av 65 MHz systemklocka c0)
    --    Varje ROM-bit hålls i SCL_STRETCH cykler
    ----------------------------------------------------------------
    process(c0, Reset)
    begin
        if Reset = '1' then
            scl_index       <= 0;
            scl_hold_count  <= 0;
            SCL_reg         <= '1';
        elsif rising_edge(c0) then
            if enable_scl = '1' then
                if scl_hold_count = 0 then
                    -- Läs nytt värde från ROM
                    SCL_reg <= SCL_rom(Bits_SCL-1 - scl_index);
                end if;

                -- Håll kvar biten i SCL_STRETCH cykler
                if scl_hold_count = SCL_STRETCH-1 then
                    scl_hold_count <= 0;
                    if scl_index = Bits_SCL-1 then
                        scl_index <= 0;  -- loopa eller stoppa beroende på behov
                    else
                        scl_index <= scl_index + 1;
                    end if;
                else
                    scl_hold_count <= scl_hold_count + 1;
                end if;
            else
                -- Ingen överföring: håll SCL hög
                SCL_reg         <= '1';
                scl_index       <= 0;
                scl_hold_count  <= 0;
            end if;
        end if;
    end process;

end architecture;

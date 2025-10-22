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

    constant Bits_SDA : integer := 28;
    signal SDA_rom : std_logic_vector(Bits_SDA-1 downto 0) :=
        "1000110100100000111111001101"; 

    constant Bits_SCL : integer := 105;
    signal SCL_rom : std_logic_vector(Bits_SCL-1 downto 0) :=
        "111110101010101010101000100010001000100010001000101010101010101010100010001000100010001000100010001010111"; -- Exempel på 4 pulser

    constant SCL_STRETCH : integer := 170;

    signal bit_index       : integer range 0 to Bits_SDA := 0;
    signal SDA_reg         : std_logic := '1';

    signal enable_scl      : std_logic := '0';
    signal SCL_reg         : std_logic := '1';

    signal scl_index       : integer range 0 to Bits_SCL := 0;
    signal scl_hold_count  : integer range 0 to SCL_STRETCH := 0;

begin

    SDA <= SDA_reg;
    SCL <= SCL_reg;

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
                scl_index <= 0; 
                  else
                  scl_index <= scl_index + 1;
                  end if;
                  else
                  scl_hold_count <= scl_hold_count + 1;
                end if;
            else
                
                SCL_reg         <= '1';
                scl_index       <= 0;
                scl_hold_count  <= 0;
            end if;
        end if;
    end process;

end architecture;

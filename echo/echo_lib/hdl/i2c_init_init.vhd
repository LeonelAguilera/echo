library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity i2c_init is
   port(
      Reset     : in  std_logic;
      CLK_100k  : in  std_logic;  -- 100 kHz (data clock)
      CLK_200k  : in  std_logic;  -- 200 kHz (SCL clock)
      SDA       : out std_logic;
      SCL       : out std_logic
   );
end i2c_init;

architecture init of i2c_init is

    constant Bits_SDA : integer := 310;
    signal SDA_rom : std_logic_vector(Bits_SDA-1 downto 0) :=
    
    -- R0
 -- START    Slave      W    ACK    Register   ACK      DATA       ACK   STOP
    "Z0" & "00ZZ0Z0" & "0" & "Z" & "0000000" & "Z" & "0000Z0ZZZ" & "Z" & "0Z" &
    -- RZ
    "Z0" & "00ZZ0Z0" & "0" & "Z" & "000000Z" & "Z" & "00ZZZZ00Z" & "Z" & "0Z" &
    -- R2
    "Z0" & "00ZZ0Z0" & "0" & "Z" & "00000Z0" & "Z" & "00ZZZZ00Z" & "Z" & "0Z" &
    -- R3
    "Z0" & "00ZZ0Z0" & "0" & "Z" & "00000ZZ" & "Z" & "0000Z0000" & "Z" & "0Z" &
    -- R4
    "Z0" & "00ZZ0Z0" & "0" & "Z" & "0000Z00" & "Z" & "000000000" & "Z" & "0Z" &
    -- R5
    "Z0" & "00ZZ0Z0" & "0" & "Z" & "0000Z0Z" & "Z" & "000000000" & "Z" & "0Z" &
    -- R6
    "Z0" & "00ZZ0Z0" & "0" & "Z" & "0000ZZ0" & "Z" & "000000000" & "Z" & "0Z" &
    -- R7
    "Z0" & "00ZZ0Z0" & "0" & "Z" & "0000ZZZ" & "Z" & "Z0Z0000Z0" & "Z" & "0Z" &
    -- R8
    "Z0" & "00ZZ0Z0" & "0" & "Z" & "000Z000" & "Z" & "0000Z0000" & "Z" & "0Z" &
    -- R9
    "Z0" & "00ZZ0Z0" & "0" & "Z" & "000Z00Z" & "Z" & "00000000Z" & "Z" & "0Z";
 

    constant Bits_SCL : integer := 61;
    signal SCL_rom : std_logic_vector(Bits_SCL-1 downto 0) :=
    
        "1110101010101010101010101010101010101010101010101010101010111";

    signal bit_index : integer range 0 to Bits_SDA := 0;
    signal scl_index : integer range 0 to Bits_SCL := 0;

    signal SDA_reg   : std_logic := '1';
    signal SCL_reg   : std_logic := '1';
    signal enable_scl : std_logic := '0';

begin

    SDA <= SDA_reg;
    SCL <= SCL_reg;


    process(CLK_100k, Reset)
    begin
        if Reset = '1' then
            bit_index  <= 0;
            SDA_reg    <= '1';
            enable_scl <= '0';
        elsif rising_edge(CLK_100k) then
            if bit_index < Bits_SDA then
                SDA_reg <= SDA_rom(Bits_SDA-1 - bit_index);
                enable_scl <= '1';  -- Starta SCL
                bit_index <= bit_index + 1;
            else
                enable_scl <= '0';  -- SCL stoppas
                SDA_reg <= '1';     -- Idle
            end if;
        end if;
    end process;

    process(CLK_200k, Reset)
    begin
        if Reset = '1' then
            scl_index <= 0;
            SCL_reg   <= '1';
        elsif rising_edge(CLK_200k) then
            if enable_scl = '1' then
                if scl_index < Bits_SCL then
                    SCL_reg <= SCL_rom(Bits_SCL-1 - scl_index);
                    scl_index <= scl_index + 1;
                else
                    scl_index <= 0;
                    SCL_reg   <= '1';
                end if;
            else
                SCL_reg   <= '1';
                scl_index <= 0;
            end if;
        end if;
    end process;

end architecture;



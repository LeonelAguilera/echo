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
    "10" & "0011010" & "0" & "1" & "0000000" & "1" & "000010111" & "1" & "01" &
    -- R1
    "10" & "0011010" & "0" & "1" & "0000001" & "1" & "001111001" & "1" & "01" &
    -- R2
    "10" & "0011010" & "0" & "1" & "0000010" & "1" & "001111001" & "1" & "01" &
    -- R3
    "10" & "0011010" & "0" & "1" & "0000011" & "1" & "000010000" & "1" & "01" &
    -- R4
    "10" & "0011010" & "0" & "1" & "0000100" & "1" & "000000000" & "1" & "01" &
    -- R5
    "10" & "0011010" & "0" & "1" & "0000101" & "1" & "000000000" & "1" & "01" &
    -- R6
    "10" & "0011010" & "0" & "1" & "0000110" & "1" & "000000000" & "1" & "01" &
    -- R7
    "10" & "0011010" & "0" & "1" & "0000111" & "1" & "101000010" & "1" & "01" &
    -- R8
    "10" & "0011010" & "0" & "1" & "0001000" & "1" & "000010000" & "1" & "01" &
    -- R9
    "10" & "0011010" & "0" & "1" & "0001001" & "1" & "000000001" & "1" & "01";
 

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



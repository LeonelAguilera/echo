--
-- VHDL Architecture echo_lib.kb_decoder.behav
--
-- Created:
--          by - shaha038.student-liu.se (muxen2-108.ad.liu.se)
--          at - 19:05:00 10/17/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY kb_decoder IS
  port (
  sys_clk     : in std_logic;
  kb_clk      : in std_logic;
  kb_data     : in std_logic;
  scan_code   : out std_logic_vector (7 downto 0);
  scan_ready  : out std_logic
  );
  
 --Declarations
type exemplar_string_array is array (natural range <>, natural range <>) of character;
attribute pin_number : string;
attribute array_pin_number : exemplar_string_array;
attribute pin_number of sys_clk : signal is "Y2";
attribute pin_number of kb_clk : signal is "G6";
attribute pin_number of kb_data : signal is "H5";
attribute array_pin_number of scan_code : signal is ("G21","G22","G20","H21","E24","E25","E22","E21");
attribute pin_number of scan_ready : signal is "G19";



END kb_decoder ;

--
ARCHITECTURE behav OF kb_decoder IS
  
  signal clk_sync   : std_logic_vector (2 downto 0) := (others => '1');
  signal clk_fall   : std_logic := '0';
  signal bit_count  : integer range 0 to 12 := 0;
  signal shift_reg  : std_logic_vector(10 downto 0) := (others => '1');
  signal data_reg   : std_logic_vector(7 downto 0) := (others => '0');
  signal ready_reg  : std_logic := '0';
  
    
BEGIN
  
  process(sys_clk)
  begin
    if rising_edge(sys_clk) then
      clk_sync <= clk_sync(1 downto 0) & kb_clk;
      clk_fall <= (clk_sync(2) and not clk_sync(1));
    end if;
  end process;
  
  
  process(sys_clk)
  begin
    if rising_edge(sys_clk) then
      ready_reg <= '0';
      if clk_fall = '1' then
        shift_reg <= kb_data & shift_reg(10 downto 1);
        bit_count <= bit_count+1;
        if bit_count = 11 then
          bit_count <= 0;
          if (shift_reg(0) = '0') and (shift_reg(10) = '1') then
            data_reg <= shift_reg(8 downto 1);
            ready_reg <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;
  
  
  scan_code <= data_reg;
  
  scan_ready <= ready_reg;
  
END ARCHITECTURE behav;


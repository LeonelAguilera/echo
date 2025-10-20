--
-- VHDL Architecture echo_lib.gen_kb_dec.behav
--
-- Created:
--          by - erosa204.student-liu.se (muxen2-106.ad.liu.se)
--          at - 13:11:03 10/20/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.keyboard_package.all;

ENTITY gen_kb_dec IS
  
 generic (
    N       : integer := 18;   -- Number of functions
    key_map : key_array(N-1 downto 0)   -- Key map provided by user
  );
  port (
    clk        : in  std_logic;
    scancode   : in  std_logic_vector(6 downto 0);
    output_signal : out std_logic_vector(N-1 downto 0);
    invalid_led : out std_logic   -- LED for invalid keys
  );
  
END gen_kb_dec ;

ARCHITECTURE behav OF gen_kb_dec IS
  
  signal output_reg : std_logic_vector(N-1 downto 0) := (others => '0');
  signal invalid_key : std_logic := '0';   -- High when invalid key pressed
  signal blink_counter : unsigned(23 downto 0) := (others => '0');   -- Blink timing counter
  
begin
  process(clk)
  variable match : std_logic := '0';
  begin
    if rising_edge(clk) then
      output_reg <= (others => '0');   -- Clear outputs
      match := '0';
      
      for i in 0 to N-1 loop
        if scancode = key_map(i) then
          output_reg(i) <= '1';
          match := '1';
        end if;
      end loop;
      if match = '0' then
        invalid_key <= '1';
      else
        invalid_key <= '0';
      end if;
    end if;
  end process;

  output_signal <= output_reg;
  
  process(clk)   -- Blinking process
  begin
    if rising_edge(clk) then
      blink_counter <= blink_counter + 1;
    end if;
  end process;
  
  invalid_led <= blink_counter(blink_counter'high) when invalid_key = '1' else '0';
  
END ARCHITECTURE behav;
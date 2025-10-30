--
-- VHDL Architecture echo_lib.dithered_clk_divider.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-116.ad.liu.se)
--          at - 22:07:27 10/30/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY dithered_clk_divider IS
   PORT( 
      c0         : IN     STD_LOGIC;
      fpga_reset : IN     std_logic;
      AUD_XCK    : OUT    std_logic
   );

-- Declarations

END dithered_clk_divider ;

--
ARCHITECTURE behav OF dithered_clk_divider IS
  TYPE myarray_t IS ARRAY (3 DOWNTO 0) OF INTEGER;
  CONSTANT counter_vals : myarray_t := (6, 6, 6, 5);
  SIGNAL divider_counter : INTEGER;
  SIGNAL position_counter : INTEGER;
  SIGNAL out_value : STD_LOGIC;
BEGIN
  PROCESS(fpga_reset, c0)
  BEGIN
    IF fpga_reset = '0' THEN
      divider_counter <= counter_vals(counter_vals'LENGTH - 1);
      position_counter <= counter_vals'LENGTH - 2;
      out_value <= '0';
    ELSIF c0'EVENT THEN
      IF divider_counter = 0 THEN
        IF position_counter = 0 THEN
          position_counter <= counter_vals'LENGTH - 1;
        ELSE
          position_counter <= position_counter - 1;
        END IF;
        divider_counter <= counter_vals(position_counter);
        out_value <= NOT out_value;
      ELSE
        divider_counter <= divider_counter - 1;
      END IF;
    END IF;
  END PROCESS;
  AUD_XCK <= out_value;
END ARCHITECTURE behav;


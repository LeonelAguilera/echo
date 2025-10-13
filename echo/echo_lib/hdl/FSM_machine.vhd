--
-- VHDL Architecture echo_lib.FSM.machine
--
-- Created:
--          by - alfth698.student-liu.se (muxen2-111.ad.liu.se)
--          at - 18:25:39 10/03/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY FSM IS
   PORT( 
      Reset : IN     std_logic;
      SCLK  : IN     std_logic;
      sig0  : IN     std_logic;
      SDIN  : OUT    std_logic
   );

-- Declarations

END FSM ;

ARCHITECTURE machine OF FSM IS
    -- konstant slav-adress (CSB=0)
    constant CODEC_ADDR : std_logic_vector(6 downto 0) := "0011010";
BEGIN
  addr <= CODEC_ADDR;
END ARCHITECTURE machine;


--
-- VHDL Package Header echo_lib.keyboard_package
--
-- Created:
--          by - erosa204.student-liu.se (muxen2-106.ad.liu.se)
--          at - 13:08:14 10/20/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;

PACKAGE keyboard_package IS
  type key_array is array (natural range<>) of std_logic_vector(7 downto 0);
END keyboard_package;

package body keyboard_package is
end package body keyboard_package;
library ieee;
use ieee.std_logic_1164.all;

entity Grp_Nr is
  port(HEX7 : out std_logic_vector(0 to 6);
       HEX6 : out std_logic_vector(0 to 6));
end entity;

architecture Grp07 of Grp_Nr is
begin
  HEX7 <= "1000000"; --0
  HEX6 <= "1111000"; --7
  
end architecture;

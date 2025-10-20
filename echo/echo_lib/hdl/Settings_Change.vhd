LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Settings IS
   PORT( 
      Reset     : IN     std_logic;
      DPressed  : IN     std_logic;
      WPressed  : IN     std_logic;
      SPressed  : IN     std_logic;
      overflow  : IN     std_logic;
      vol_count : OUT    unsigned (3 DOWNTO 0);
      c0        : IN     std_logic;
      bal_count : OUT    unsigned (3 DOWNTO 0);
      APressed  : IN     std_logic
   );

-- Declarations

END Settings ;

architecture change of Settings is 
	signal tmp_vol : unsigned(3 downto 0) := "0110"; 
	signal tmp_bal : unsigned(3 downto 0) := "0100";
	signal old_APressed, old_DPressed, 
	       old_WPressed, old_SPressed  : std_logic;
	signal old_overflow : std_logic;
	
begin
	process (c0, Reset) 
	begin
		if Reset = '0' then
			--tmp_vol <= "0110"; -- set initial volume  to 6
			--tmp_bal <= "0100"; -- set initial balance to 4
		elsif rising_edge(c0) then
		old_APressed  <= APressed;
		old_DPressed <= DPressed;
		old_WPressed    <= WPressed;
		old_SPressed  <= SPressed;
	   old_overflow          <= overflow;
		
			if overflow = '0' then
				if (APressed  = '1') and (tmp_bal > "0000") and old_APressed = '0' then     -- if left arrow pressed 
					tmp_bal <= tmp_bal - 1;
				elsif (DPressed = '1') and (tmp_bal < "1000") and old_DPressed = '0' then -- if right arrow pressed
					tmp_bal <= tmp_bal + 1;
				elsif (WPressed = '1') and (tmp_vol < "1100") and old_WPressed = '0' then       -- if up arrow pressed
					tmp_vol <= tmp_vol + 1;
				elsif (SPressed = '1') and (tmp_vol > "0000") and old_SPressed = '0' then   -- if down arrow pressed
					tmp_vol <= tmp_vol - 1;
				end if; -- Vol_count & Bal_count (0 - 10)
			elsif  overflow = '1' and old_overflow = '0' then
				tmp_vol <= tmp_vol - 1;
			end if; -- overflow
		end if; -- rising clock
	end process;
	
	
	bal_count <= tmp_bal; -- output balance					 
	vol_count <= tmp_vol; -- output volume
					 
end architecture;

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY V_B IS
   PORT( 
      lrsel        : IN     std_logic;
      TXReg        : IN     signed (15 DOWNTO 0);
      DAC_en       : IN     std_logic;
      DAC          : OUT    signed (15 DOWNTO 0);
      overflow     : OUT    std_logic;
      signal_ready : OUT    std_logic;
      Reset        : IN     std_logic;
      PLL          : IN     std_logic;
      bal_count    : IN     unsigned (3 DOWNTO 0);
      vol_count    : IN     unsigned (3 DOWNTO 0)
   );

-- Declarations

END V_B ;

architecture change of V_B is
  
	signal tmp_DAC               : signed(19 downto 0);
	signal old_lrsel             : std_logic;
	signal volume_increase1, volume_increase2, volume_increase3, volume_increase4, volume_increase5, volume_increase6 : signed(19 downto 0); 
	signal volume_decrease1, volume_decrease2, volume_decrease3, volume_decrease4, volume_decrease5                   : signed(19 downto 0); 	 
	signal volume_shift0         : signed(19 downto 0);
	signal volume_shift1,  volume_shift2,  volume_shift3,  volume_shift4,  volume_shift5,  volume_shift6 : signed(19 downto 0);
	signal balance_shift1, balance_shift2, balance_shift3, balance_shift4, balance_shift5, balance_shift6 : signed(19 downto 0);
	signal balance_shift0        : signed(15 downto 0);
	signal data_sent             : std_logic;
	
begin
			
			volume_shift1 <= shift_right(resize(TXReg,20), 1); -- 1/2
			volume_shift2 <= shift_right(resize(TXReg,20), 2); -- 1/4
			volume_shift3 <= shift_right(resize(TXReg,20), 3); -- 1/8
			volume_shift4 <= shift_right(resize(TXReg,20), 4); -- 1/16
			volume_shift5 <= shift_right(resize(TXReg,20), 5); -- 1/32
			volume_shift6 <= shift_right(resize(TXReg,20), 6); -- 1/64

			balance_shift0 <= (others => '0');
			
			balance_shift1 <= shift_right(tmp_DAC, 2);         -- 25%
			balance_shift2 <= shift_right(tmp_DAC, 1);         -- 50%
			balance_shift3 <= tmp_DAC - balance_shift1;        -- 75%
			balance_shift4 <= tmp_DAC + balance_shift1;        -- 125%
			balance_shift5 <= balance_shift4 + balance_shift1; -- 150%
			balance_shift6 <= balance_shift5 + balance_shift1; -- 175%	
			
     	volume_ctrl : process (clk, rstn) -- Adjust volume and balance
	
	    begin
	  
		if rstn = '0' then
			--tmp_DAC  <= (others => '0');
			--overflow <= '0';
		elsif rising_edge(PLL) then
			old_lrsel <= lrsel;
			------- Increase in steps of +2.5 dB ------------------------------------
			volume_shift0 <= resize(TXReg,20); -- 1
			volume_increase1 <= resize(TXReg,20) + volume_shift2 + volume_shift4 + volume_shift6;    -- Increase approx. 1.33
			volume_increase2 <= resize(TXReg,20) + volume_shift1 + volume_shift2 + volume_shift6;    -- Increase 1.765625
			volume_increase3 <= resize(TXReg,20) + resize(TXReg,20) + volume_shift4 + volume_shift5 + volume_shift2;    -- Increase 2.34375
			volume_increase4 <= shift_left(resize(TXReg,20), 1) + resize(TXReg,20) + volume_shift3;    -- Increase 3.125
			volume_increase5 <= shift_left(resize(TXReg,20), 2) + volume_shift3 + volume_shift5;       -- Increase 4.15625
			volume_increase6 <= shift_left(resize(TXReg,20), 2) + resize(TXReg,20) + volume_shift1 + volume_shift5; -- Increase 5.53125
			------- Decrease in steps of -2.5 dB ------------------------------------
			volume_decrease1 <= resize(TXReg,20) - volume_shift2;                                 -- Decrease 0.75
			volume_decrease2 <= volume_shift1 + volume_shift4;                                    -- Decrease 0.5625
			volume_decrease3 <= volume_shift1 - volume_shift4 - volume_shift6;                    -- Decrease 0.421875
			volume_decrease4 <= resize(TXReg,20) - volume_shift1 - volume_shift2 + volume_shift4; -- Decrease 0.3125
			volume_decrease5 <= resize(TXReg,20) - volume_shift1 - volume_shift2 - volume_shift6; -- Decrease 0.234375
			
			------- Check for overflow ----------------------------------------------
			if tmp_DAC(19 downto 16) /= "0000" and tmp_DAC(19 downto 16) /= "1111" then -- Check overflow for volume
				overflow <= '1';
			elsif lrsel = '0' and old_lrsel = '1'  then  -- Overflow for left channel
					if bal_count = "0000" and (tmp_DAC > 16383 or tmp_DAC < -16383) then
						overflow <= '1';
					elsif bal_count = "0001" and (tmp_DAC > 18724 or tmp_DAC < -18724) then
						overflow <= '1';
					elsif bal_count = "0010" and (tmp_DAC > 21844 or tmp_DAC < -21844) then
						overflow <= '1';
					elsif bal_count = "0011" and (tmp_DAC > 26213 or tmp_DAC < -26213) then
						overflow <= '1';
					else
						overflow <= '0';
					end if;
			elsif lrsel = '0' and old_lrsel = '1' then  -- Overflow for right channel
					if bal_count = "1000" and (tmp_DAC > 16383 or tmp_DAC < -16383) then
						overflow <= '1';
					elsif bal_count = "0111" and (tmp_DAC > 18724 or tmp_DAC < -18724) then
						overflow <= '1';
					elsif  bal_count = "0110" and (tmp_DAC > 21844 or tmp_DAC < -21844) then
						overflow <= '1';
					elsif  bal_count = "0101" and (tmp_DAC > 26213 or tmp_DAC < -26213) then
						overflow <= '1';
					else	
						overflow <= '0';
					end if;
			end if;
			------- Adjust balance linear (0-8) -------------------------------------
			case bal_count is 
				when "0000" => -- 0
					if lrsel = '0' and DAC_en = '1' then -- Left channel
						DAC <= tmp_DAC(15 downto 0) + tmp_DAC(15 downto 0); -- 200%
						data_sent <= '1';
					elsif lrsel = '1' and DAC_en = '1'  then -- Right channel
						DAC <= (others => '0');   -- 0%
						data_sent <= '1';
					end if;
				when "0001" => -- 1
					if lrsel = '0' and DAC_en = '1' then
						DAC <= balance_shift6(15 downto 0);
						data_sent <= '1';
					elsif lrsel = '1' and DAC_en = '1' then
						DAC <= balance_shift1(15 downto 0);
						data_sent <= '1';
					end if;
				when "0010" => -- 2
					if lrsel = '0' and DAC_en = '1' then
						DAC <= balance_shift5(15 downto 0);
						data_sent <= '1';
					elsif lrsel = '1' and DAC_en = '1' then
						DAC <= balance_shift2(15 downto 0);
						data_sent <= '1';
					end if;
				when "0011" => -- 3
					if lrsel = '0' and DAC_en = '1' then
						DAC <= balance_shift4(15 downto 0);
						data_sent <= '1';
					elsif lrsel = '1' and DAC_en = '1' then
						DAC <= balance_shift3(15 downto 0);
						data_sent <= '1';
					end if;				
				when "0101" => -- 5
					if lrsel = '1' and DAC_en = '1' then -- Right channel
						DAC <= balance_shift4(15 downto 0);
						data_sent <= '1';
					elsif lrsel = '0' and DAC_en = '1'  then -- Left channel
						DAC <= balance_shift3(15 downto 0);
						data_sent <= '1';
					end if;
				when "0110" => -- 6
					if lrsel = '1' and DAC_en = '1' then
						DAC <=  balance_shift5(15 downto 0);
						data_sent <= '1';
					elsif lrsel = '0' and DAC_en = '1' then
						DAC <= balance_shift2(15 downto 0);
						data_sent <= '1';
					end if;
				when "0111" => -- 7
					if lrsel = '1' and DAC_en = '1' then
						DAC <= balance_shift6(15 downto 0);
						data_sent <= '1';
					elsif lrsel = '0' and DAC_en = '1' then
						DAC <= balance_shift1(15 downto 0);
						data_sent <= '1';
					end if;
				when "1000" => -- 8
					if lrsel = '1' and DAC_en = '1' then 
						 DAC <= tmp_DAC(15 downto 0) + tmp_DAC(15 downto 0); -- 200%
						data_sent <= '1';
					elsif lrsel = '0' and DAC_en = '1' then
						 DAC <= (others => '0'); -- 0%
						data_sent <= '1';
					end if;
				when others => 
				if DAC_en = '1' then
					DAC <= tmp_DAC(15 downto 0);
					data_sent <= '1';-- Output volume increase/ decrease by 2.5dB/step
				end if;
			end case; -- bal_count
			
			if(data_sent = '1') then 
				signal_ready <= '1';
				data_sent <= '0';
			else
				signal_ready <= '0';
			end if;
		
		
		end if; -- rising clock
	end process;	-- volume_ctrl
	
--	overflow <= '1' when tmp_DAC(19 downto 16) /= "0000" and tmp_DAC(19 downto 16) /= "1111" else 
--	'0';
	
	
	tmp_DAC <= 
		 (others => '0')  when vol_count = "0000" else 	
		 volume_decrease5 when vol_count = "0001" else 
		 volume_decrease4 when vol_count = "0010" else 
		 volume_decrease3 when vol_count = "0011" else 
		 volume_decrease2 when vol_count = "0100" else 
		 volume_decrease1 when vol_count = "0101" else
		 
		 volume_shift0 	when vol_count = "0110" else
		 
		 volume_increase1 when vol_count = "0111" else 
		 volume_increase2 when vol_count = "1000" else 
		 volume_increase3 when vol_count = "1001" else 
		 volume_increase4 when vol_count = "1010" else 
		 volume_increase5 when vol_count = "1011" else 
		 volume_increase6 when vol_count = "1100" else
		 (others => '0');
		 	
end architecture;

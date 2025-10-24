--
-- VHDL Architecture echo_lib.gen_para.behav
--
-- Created:
--          by - antmo328.student-liu.se (muxen2-102.ad.liu.se)
--          at - 15:47:52 10/17/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
LIBRARY echo_lib;
USE echo_lib.keyboard_package.ALL;


ENTITY gen_para IS
   GENERIC( 
      fs_hz         : positive := 44100;      -- Sampling frequency
      step_delay_ms : natural  := 250;        -- 0,25 s
      step_gain_q15 : natural  := 1638        -- ?0,05
   );
   PORT( 
      RESET_N        : IN     std_logic;
      clk            : IN     std_logic;
      ctrl_sig       : IN     std_logic_vector (5 DOWNTO 0);
      delay_samples  : OUT    std_logic_vector (18 DOWNTO 0);
      echo_disable   : OUT    std_logic;
      g_feedback_q15 : OUT    std_logic_vector (15 DOWNTO 0)
   );

-- Declarations

END gen_para ;

--
ARCHITECTURE behav OF gen_para IS
  
  function ms_to_samples(fs, ms : natural) return natural is
    begin
        -- rundet zur nächsten Ganzzahl:
        return (fs * ms + 500) / 1000;
    end function;

    constant step_delay : natural := ms_to_samples(fs_hz, step_delay_ms);
    constant step_gain  : natural := step_gain_q15;
    constant DELAY_MAX : natural := 330750;  -- 524287
    constant GAIN_MAX  : natural := 2**16 - 1;  -- 65535

BEGIN
  
  process(clk, RESET_N)
    variable delay_samples_v  : natural range 0 to DELAY_MAX := 11025;  -- 0,25 s @ 44.1kHz
    variable g_feedback_q15_v : natural range 0 to GAIN_MAX  := 16#4000#;  -- 0.5 in Q1.15
begin
    if RESET_N = '0' then
        delay_samples_v  := 33075;
        g_feedback_q15_v := 16#4000#;
        echo_disable     <= '0';
    elsif rising_edge(clk) then
	
	-- (5) -> disable
	-- (4) -> enable
        if ctrl_sig(5) = '1' then
            echo_disable <= '1';
        elsif ctrl_sig(4) = '1' then
            echo_disable <= '0';
        end if;

 	-- (3) -> increase delay
	-- (2) -> decrease delay
        if ctrl_sig(3) = '1' then
            if delay_samples_v > DELAY_MAX - step_delay then
                delay_samples_v := DELAY_MAX;
            else
            delay_samples_v := delay_samples_v + step_delay;
            end if;
        elsif ctrl_sig(2) = '1' then
            if delay_samples_v < step_delay then
                delay_samples_v := 0;
            else
                delay_samples_v := delay_samples_v - step_delay;
            end if;
        end if;

        if ctrl_sig(1) = '1' then
            if g_feedback_q15_v > GAIN_MAX - step_gain then
                g_feedback_q15_v := GAIN_MAX;
            else
                g_feedback_q15_v := g_feedback_q15_v + step_gain;
            end if;
        elsif ctrl_sig(0) = '1' then
            if g_feedback_q15_v < step_gain then
                g_feedback_q15_v := 0;
            else
                g_feedback_q15_v := g_feedback_q15_v - step_gain;
            end if;
        end if;
    end if;
    
    delay_samples  <= std_logic_vector(to_unsigned(delay_samples_v, 19));
    g_feedback_q15 <= std_logic_vector(to_unsigned(g_feedback_q15_v, 16));
end process;
  
END ARCHITECTURE behav;


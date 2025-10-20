--
-- VHDL Architecture echo_lib.color_mapper.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-112.ad.liu.se)
--          at - 11:05:19 10/11/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE IEEE.MATH_REAL.ALL;
LIBRARY echo_lib;
USE echo_lib.color_t.ALL;

ENTITY color_mapper IS
   GENERIC( 
      background_color : rgb_color_t := ("01111010", "10011000", "11101110");
      oscil_line_color : rgb_color_t := ("11100110", "10001110", "00110101")
   );
   PORT( 
      display_color_data : IN     std_logic_vector (1 DOWNTO 0);
      in_image_window    : IN     std_logic;
      mask_f             : OUT    std_logic;
      bg_image           : IN     rgb_color_t;
      oscilloscope_color : OUT    rgb_color_t
   );

-- Declarations

END color_mapper ;

--
ARCHITECTURE behav OF color_mapper IS
  CONSTANT s_background_color_r : SIGNED(8 DOWNTO 0) := SIGNED('0' & background_color(0));
  CONSTANT s_background_color_g : SIGNED(8 DOWNTO 0) := SIGNED('0' & background_color(1));
  CONSTANT s_background_color_b : SIGNED(8 DOWNTO 0) := SIGNED('0' & background_color(2));
  
  CONSTANT s_oscil_line_color_r : SIGNED(8 DOWNTO 0) := SIGNED('0' & background_color(0));
  CONSTANT s_oscil_line_color_g : SIGNED(8 DOWNTO 0) := SIGNED('0' & background_color(1));
  CONSTANT s_oscil_line_color_b : SIGNED(8 DOWNTO 0) := SIGNED('0' & background_color(2));
  
  SIGNAL s_display_color_data : SIGNED(display_color_data'LENGTH DOWNTO 0);
  
  SIGNAL mul_r : SIGNED(display_color_data'LENGTH + 9 DOWNTO 0);
  SIGNAL mul_g : SIGNED(display_color_data'LENGTH + 9 DOWNTO 0);
  SIGNAL mul_b : SIGNED(display_color_data'LENGTH + 9 DOWNTO 0);
  SIGNAL sum_r : UNSIGNED(8 DOWNTO 0);
  SIGNAL sum_g : UNSIGNED(8 DOWNTO 0);
  SIGNAL sum_b : UNSIGNED(8 DOWNTO 0);
BEGIN
  s_display_color_data <= SIGNED('0' & display_color_data);
  
  mul_r <= s_display_color_data * (s_oscil_line_color_r - s_background_color_r);
  sum_r <= UNSIGNED(mul_r(mul_r'LENGTH - 1 DOWNTO s_display_color_data'LENGTH) + s_background_color_r);
  oscilloscope_color(0) <= bg_image(0) WHEN s_display_color_data = 0 ELSE
           STD_LOGIC_VECTOR(sum_r(7 DOWNTO 0));
  
  mul_g <= s_display_color_data * (s_oscil_line_color_g - s_background_color_g);
  sum_g <= UNSIGNED(mul_g(mul_g'LENGTH - 1 DOWNTO s_display_color_data'LENGTH) + s_background_color_g);
  oscilloscope_color(1) <= bg_image(1) WHEN s_display_color_data = 0 ELSE
           STD_LOGIC_VECTOR(sum_g(7 DOWNTO 0));
  
  mul_b <= s_display_color_data * (s_oscil_line_color_b - s_background_color_b);
  sum_b <= UNSIGNED(mul_b(mul_b'LENGTH - 1 DOWNTO s_display_color_data'LENGTH) + s_background_color_b);
  oscilloscope_color(2) <= bg_image(2) WHEN s_display_color_data = 0 ELSE
           STD_LOGIC_VECTOR(sum_b(7 DOWNTO 0));
  
  mask_f <= in_image_window;
  --oscilloscope_color <= bg_image;
END ARCHITECTURE behav;


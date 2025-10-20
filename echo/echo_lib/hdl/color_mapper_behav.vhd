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
      background_color_r : UNSIGNED(7 DOWNTO 0) := "01111010";
      background_color_g : UNSIGNED(7 DOWNTO 0) := "10011000";
      background_color_b : UNSIGNED(7 DOWNTO 0) := "11101110";
      oscil_line_color_r : UNSIGNED(7 DOWNTO 0) := "11100110";
      oscil_line_color_g : UNSIGNED(7 DOWNTO 0) := "10001110";
      oscil_line_color_b : UNSIGNED(7 DOWNTO 0) := "00110101"
   );
   PORT( 
      mask_f             : OUT    std_logic;
      vga_b              : OUT    std_logic_vector (7 DOWNTO 0);
      vga_g              : OUT    std_logic_vector (7 DOWNTO 0);
      vga_r              : OUT    std_logic_vector (7 DOWNTO 0);
      display_color_data : IN     std_logic_vector (1 DOWNTO 0);
      in_image_window    : IN     std_logic;
      bg_image           : IN     rgb_color_t
   );

-- Declarations

END color_mapper ;

--
ARCHITECTURE behav OF color_mapper IS
  CONSTANT s_background_color_r : SIGNED(8 DOWNTO 0) := SIGNED('0' & background_color_r);
  CONSTANT s_background_color_g : SIGNED(8 DOWNTO 0) := SIGNED('0' & background_color_g);
  CONSTANT s_background_color_b : SIGNED(8 DOWNTO 0) := SIGNED('0' & background_color_b);
  
  CONSTANT s_oscil_line_color_r : SIGNED(8 DOWNTO 0) := SIGNED('0' & background_color_r);
  CONSTANT s_oscil_line_color_g : SIGNED(8 DOWNTO 0) := SIGNED('0' & background_color_g);
  CONSTANT s_oscil_line_color_b : SIGNED(8 DOWNTO 0) := SIGNED('0' & background_color_b);
  
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
  vga_r <= bg_image(0) WHEN s_display_color_data = 0 ELSE
           STD_LOGIC_VECTOR(sum_r(7 DOWNTO 0));
  
  mul_g <= s_display_color_data * (s_oscil_line_color_g - s_background_color_g);
  sum_g <= UNSIGNED(mul_g(mul_g'LENGTH - 1 DOWNTO s_display_color_data'LENGTH) + s_background_color_g);
  vga_g <= bg_image(1) WHEN s_display_color_data = 0 ELSE
           STD_LOGIC_VECTOR(sum_g(7 DOWNTO 0));
  
  mul_b <= s_display_color_data * (s_oscil_line_color_b - s_background_color_b);
  sum_b <= UNSIGNED(mul_b(mul_b'LENGTH - 1 DOWNTO s_display_color_data'LENGTH) + s_background_color_b);
  vga_b <= bg_image(2) WHEN s_display_color_data = 0 ELSE
           STD_LOGIC_VECTOR(sum_b(7 DOWNTO 0));
  
  mask_f <= in_image_window;
END ARCHITECTURE behav;


--
-- VHDL Architecture echo_lib.intermediate_registers.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-112.ad.liu.se)
--          at - 11:47:24 10/05/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY intermediate_registers IS
   GENERIC(
      center_x	: INTEGER :=	195;
      center_y	: INTEGER	:= 197
   );
   PORT( 
      c0             : IN     std_logic;
      done           : IN     std_logic;
      point_selector : IN     BIT_VECTOR (1 DOWNTO 0);
      x_component    : IN     SIGNED (11 DOWNTO 0);
      y_component    : IN     SIGNED (11 DOWNTO 0);
      Ax             : OUT    unsigned (10 DOWNTO 0);
      Ay             : OUT    unsigned (9 DOWNTO 0);
      Bx             : OUT    unsigned (10 DOWNTO 0);
      By             : OUT    unsigned (9 DOWNTO 0);
      Cx             : OUT    unsigned (10 DOWNTO 0);
      Cy             : OUT    unsigned (9 DOWNTO 0);
      Dx             : OUT    unsigned (10 DOWNTO 0);
      Dy             : OUT    unsigned (9 DOWNTO 0);
      next_point     : OUT    std_logic
   );

-- Declarations

END intermediate_registers ;

--
ARCHITECTURE behav OF intermediate_registers IS
  SIGNAL Ax_reg : unsigned (10 DOWNTO 0);
  SIGNAL Ay_reg : unsigned (9 DOWNTO 0);
  SIGNAL Bx_reg : unsigned (10 DOWNTO 0);
  SIGNAL By_reg : unsigned (9 DOWNTO 0);
  SIGNAL Cx_reg : unsigned (10 DOWNTO 0);
  SIGNAL Cy_reg : unsigned (9 DOWNTO 0);
  SIGNAL Dx_reg : unsigned (10 DOWNTO 0);
  SIGNAL Dy_reg : unsigned (9 DOWNTO 0);
  
  SIGNAL pixel_coordinate_x : SIGNED(11 DOWNTO 0);
  SIGNAL pixel_coordinate_y : SIGNED(11 DOWNTO 0);
  
  SIGNAL last_done_value : STD_LOGIC;
BEGIN
  pixel_coordinate_x <= TO_SIGNED(center_x, pixel_coordinate_x'LENGTH) + x_component;
  pixel_coordinate_y <= TO_SIGNED(center_y, pixel_coordinate_y'LENGTH) - y_component;
  PROCESS(c0)
  BEGIN
    IF RISING_EDGE(c0) THEN
      last_done_value <= done;
      IF done = '1' AND last_done_value = '0' THEN
        CASE point_selector IS
        WHEN "00" =>
          Ax_reg <= UNSIGNED(pixel_coordinate_x(10 DOWNTO 0));
          Ay_reg <= UNSIGNED(pixel_coordinate_y(9 DOWNTO 0));
          next_point <= '1';
        WHEN "01" =>
          Bx_reg <= UNSIGNED(pixel_coordinate_x(10 DOWNTO 0));
          By_reg <= UNSIGNED(pixel_coordinate_y(9 DOWNTO 0));
          next_point <= '1';
        WHEN "10" =>
          Cx_reg <= UNSIGNED(pixel_coordinate_x(10 DOWNTO 0));
          Cy_reg <= UNSIGNED(pixel_coordinate_y(9 DOWNTO 0));
          next_point <= '1';
        WHEN "11" =>
          Dx_reg <= UNSIGNED(pixel_coordinate_x(10 DOWNTO 0));
          Dy_reg <= UNSIGNED(pixel_coordinate_y(9 DOWNTO 0));
          next_point <= '0';
        END CASE;
      ELSE
        next_point <= '0';
      END IF;
    END IF;
  END PROCESS;
  Ax <= Ax_reg;
  Ay <= Ay_reg;
  Bx <= Bx_reg;
  By <= By_reg;
  Cx <= Cx_reg;
  Cy <= Cy_reg;
  Dx <= Dx_reg;
  Dy <= Dy_reg;
END ARCHITECTURE behav;


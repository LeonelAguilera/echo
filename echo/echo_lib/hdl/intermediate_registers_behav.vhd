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
   PORT( 
      c0             : IN     std_logic;
      done           : IN     std_logic;
      point_selector : IN     std_logic_vector (1 DOWNTO 0);
      x_component    : IN     UNSIGNED (10 DOWNTO 0);
      y_component    : IN     UNSIGNED (9 DOWNTO 0);
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
BEGIN
  PROCESS(c0)
  BEGIN
    IF RISING_EDGE(c0) THEN
      IF done = '1' THEN
        CASE point_selector IS
        WHEN "00" =>
          Ax_reg <= x_component;
          Ay_reg <= y_component;
          next_point <= '1';
        WHEN "01" =>
          Bx_reg <= x_component;
          By_reg <= y_component;
          next_point <= '1';
        WHEN "10" =>
          Cx_reg <= x_component;
          Cy_reg <= y_component;
          next_point <= '1';
        WHEN "11" =>
          Dx_reg <= x_component;
          Dy_reg <= y_component;
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


--
-- VHDL Architecture echo_lib.pipelined_wiper_rasterizer.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-107.ad.liu.se)
--          at - 16:17:49 10/14/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
LIBRARY echo_lib;
USE echo_lib.color_t.ALL;

ENTITY pipelined_wiper_rasterizer IS
   PORT( 
      c0          : IN     STD_LOGIC;
      Ax          : IN     unsigned (10 DOWNTO 0);
      Ay          : IN     unsigned (9 DOWNTO 0);
      Bx          : IN     unsigned (10 DOWNTO 0);
      By          : IN     unsigned (9 DOWNTO 0);
      Cx          : IN     unsigned (10 DOWNTO 0);
      Cy          : IN     unsigned (9 DOWNTO 0);
      Dx          : IN     unsigned (10 DOWNTO 0);
      Dy          : IN     unsigned (9 DOWNTO 0);
      h_count     : IN     unsigned (10 DOWNTO 0);
      v_count     : IN     unsigned (9 DOWNTO 0);
      wiper_color : OUT    rgb_color_t;
      wiper_mask  : OUT    std_logic
   );

-- Declarations

END pipelined_wiper_rasterizer ;

--
ARCHITECTURE behav OF pipelined_wiper_rasterizer IS
  CONSTANT tolerance : SIGNED(20 DOWNTO 0) := "000000000000000111111";
  SIGNAL Ax_s : SIGNED(11 DOWNTO 0);
  SIGNAL Ay_s : SIGNED(10 DOWNTO 0);
  SIGNAL Bx_s : SIGNED(11 DOWNTO 0);
  SIGNAL By_s : SIGNED(10 DOWNTO 0);
  SIGNAL Cx_s : SIGNED(11 DOWNTO 0);
  SIGNAL Cy_s : SIGNED(10 DOWNTO 0);
  SIGNAL Dx_s : SIGNED(11 DOWNTO 0);
  SIGNAL Dy_s : SIGNED(10 DOWNTO 0);
  SIGNAL Px_s : SIGNED(11 DOWNTO 0);
  SIGNAL Py_s : SIGNED(10 DOWNTO 0);
  
  SIGNAL area_ABC : SIGNED(20 DOWNTO 0);
  SIGNAL area_DBC : SIGNED(20 DOWNTO 0);
  SIGNAL area_PBC : SIGNED(20 DOWNTO 0);
  SIGNAL area_PBD : SIGNED(20 DOWNTO 0);
  SIGNAL area_PAD : SIGNED(20 DOWNTO 0);
  SIGNAL area_PAC : SIGNED(20 DOWNTO 0);
  
  SIGNAL area_ABC_doubled : SIGNED(22 DOWNTO 0);
  SIGNAL area_DBC_doubled : SIGNED(22 DOWNTO 0);
  SIGNAL area_PBC_doubled : SIGNED(22 DOWNTO 0);
  SIGNAL area_PBD_doubled : SIGNED(22 DOWNTO 0);
  SIGNAL area_PAD_doubled : SIGNED(22 DOWNTO 0);
  SIGNAL area_PAC_doubled : SIGNED(22 DOWNTO 0);
  
  SIGNAL product_00 : SIGNED(22 DOWNTO 0);
  SIGNAL product_01 : SIGNED(22 DOWNTO 0);
  SIGNAL product_02 : SIGNED(22 DOWNTO 0);
  SIGNAL product_03 : SIGNED(22 DOWNTO 0);
  SIGNAL product_04 : SIGNED(22 DOWNTO 0);
  SIGNAL product_05 : SIGNED(22 DOWNTO 0);
  SIGNAL product_06 : SIGNED(22 DOWNTO 0);
  SIGNAL product_07 : SIGNED(22 DOWNTO 0);
  SIGNAL product_08 : SIGNED(22 DOWNTO 0);
  SIGNAL product_09 : SIGNED(22 DOWNTO 0);
  SIGNAL product_10 : SIGNED(22 DOWNTO 0);
  SIGNAL product_11 : SIGNED(22 DOWNTO 0);
  SIGNAL product_12 : SIGNED(22 DOWNTO 0);
  SIGNAL product_13 : SIGNED(22 DOWNTO 0);
  SIGNAL product_14 : SIGNED(22 DOWNTO 0);
  SIGNAL product_15 : SIGNED(22 DOWNTO 0);
  SIGNAL product_16 : SIGNED(22 DOWNTO 0);
  SIGNAL product_17 : SIGNED(22 DOWNTO 0);
  
  SIGNAL total_point_area : SIGNED(20 DOWNTO 0);
  SIGNAL total_wiper_area : SIGNED(20 DOWNTO 0);
BEGIN
  Ax_s <= SIGNED('0' & Ax);
  Ay_s <= SIGNED('0' & Ay);
  Bx_s <= SIGNED('0' & Bx);
  By_s <= SIGNED('0' & By);
  Cx_s <= SIGNED('0' & Cx);
  Cy_s <= SIGNED('0' & Cy);
  Dx_s <= SIGNED('0' & Dx);
  Dy_s <= SIGNED('0' & Dy);
  Px_s <= SIGNED('0' & h_count);
  Py_s <= SIGNED('0' & v_count);
  
  area_ABC_doubled <= ABS( product_00 + product_01 + product_02);
  area_DBC_doubled <= ABS( product_03 + product_04 + product_05);
  area_PBC_doubled <= ABS( product_06 + product_07 + product_08);
  area_PBD_doubled <= ABS( product_09 + product_10 + product_11);
  area_PAD_doubled <= ABS( product_12 + product_13 + product_14);
  area_PAC_doubled <= ABS( product_15 + product_16 + product_17);
  
  PROCESS(c0)
  BEGIN
    IF RISING_EDGE(c0) THEN
      ------------------------------------------
      product_00 <= (Ax_s*(By_s-Cy_s));
      product_01 <= (Bx_s*(Cy_s-Ay_s));
      product_02 <= (Cx_s*(Ay_s-By_s));
      product_03 <= (Dx_s*(By_s-Cy_s));
      product_04 <= (Bx_s*(Cy_s-Dy_s));
      product_05 <= (Cx_s*(Dy_s-By_s));
      product_06 <= (Px_s*(By_s-Cy_s));
      product_07 <= (Bx_s*(Cy_s-Py_s));
      product_08 <= (Cx_s*(Py_s-By_s));
      product_09 <= (Px_s*(By_s-Dy_s));
      product_10 <= (Bx_s*(Dy_s-Py_s));
      product_11 <= (Dx_s*(Py_s-By_s));
      product_12 <= (Px_s*(Ay_s-Dy_s));
      product_13 <= (Ax_s*(Dy_s-Py_s));
      product_14 <= (Dx_s*(Py_s-Ay_s));
      product_15 <= (Px_s*(Ay_s-Cy_s));
      product_16 <= (Ax_s*(Cy_s-Py_s));
      product_17 <= (Cx_s*(Py_s-Ay_s));
      ------------------------------------------
      area_ABC <= area_ABC_doubled(21 DOWNTO 1);
      area_DBC <= area_DBC_doubled(21 DOWNTO 1);
      area_PBC <= area_PBC_doubled(21 DOWNTO 1);
      area_PBD <= area_PBD_doubled(21 DOWNTO 1);
      area_PAD <= area_PAD_doubled(21 DOWNTO 1);
      area_PAC <= area_PAC_doubled(21 DOWNTO 1);
      ------------------------------------------
      wiper_mask <= '1' WHEN (ABS(total_wiper_area - total_point_area) <= tolerance) ELSE
                    '0';
    END IF;
  END PROCESS;
  
  total_wiper_area <= area_ABC + area_DBC;
  total_point_area <= area_PBC + area_PBD + area_PAD + area_PAC;
  
  wiper_color(0) <= "11100110";
  wiper_color(1) <= "10001110";
  wiper_color(2) <= "00110101";
END ARCHITECTURE behav;
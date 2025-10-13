--
-- VHDL Architecture echo_lib.wiper_rasterizer.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-109.ad.liu.se)
--          at - 15:25:31 10/13/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
LIBRARY echo_lib;
USE echo_lib.color_t.ALL;

ENTITY wiper_rasterizer IS
   PORT( 
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

END wiper_rasterizer ;

--
ARCHITECTURE behav OF wiper_rasterizer IS
  CONSTANT tolerance : SIGNED(20 DOWNTO 0) := "000000000000000000011";
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
  
  area_ABC_doubled <= ABS((Ax_s*(By_s-Cy_s)) + (Bx_s*(Cy_s-Ay_s)) + (Cx_s*(Ay_s-By_s)));
  area_DBC_doubled <= ABS((Dx_s*(By_s-Cy_s)) + (Bx_s*(Cy_s-Dy_s)) + (Cx_s*(Dy_s-By_s)));
  area_PBC_doubled <= ABS((Px_s*(By_s-Cy_s)) + (Bx_s*(Cy_s-Py_s)) + (Cx_s*(Py_s-By_s)));
  area_PBD_doubled <= ABS((Px_s*(By_s-Dy_s)) + (Bx_s*(Dy_s-Py_s)) + (Dx_s*(Py_s-By_s)));
  area_PAD_doubled <= ABS((Px_s*(Ay_s-Dy_s)) + (Ax_s*(Dy_s-Py_s)) + (Dx_s*(Py_s-Ay_s)));
  area_PAC_doubled <= ABS((Px_s*(Ay_s-Cy_s)) + (Ax_s*(Cy_s-Py_s)) + (Cx_s*(Py_s-Ay_s)));
  
  area_ABC <= area_ABC_doubled(21 DOWNTO 1);
  area_DBC <= area_DBC_doubled(21 DOWNTO 1);
  area_PBC <= area_PBC_doubled(21 DOWNTO 1);
  area_PBD <= area_PBD_doubled(21 DOWNTO 1);
  area_PAD <= area_PAD_doubled(21 DOWNTO 1);
  area_PAC <= area_PAC_doubled(21 DOWNTO 1);
  
  total_wiper_area <= area_ABC + area_DBC;
  total_point_area <= area_PBC + area_PBD + area_PAD + area_PAC;
  
  wiper_mask <= '1' WHEN (total_wiper_area >= total_point_area + tolerance) OR
                         (total_point_area >= total_wiper_area + tolerance) ELSE
                '0';
  
  wiper_color(0) <= "11100110";
  wiper_color(1) <= "10001110";
  wiper_color(2) <= "00110101";
END ARCHITECTURE behav;


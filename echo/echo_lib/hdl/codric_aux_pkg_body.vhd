--
-- VHDL Package Body echo_lib.codric_aux
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-112.ad.liu.se)
--          at - 14:25:21 10/09/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
PACKAGE BODY codric_aux IS
  FUNCTION precompute_angles(n: INTEGER) RETURN angle_array IS
    VARIABLE precomputed_angles : angle_array;
  BEGIN
    FOR i IN 0 TO 10 - 1 LOOP
      precomputed_angles(i) := TO_SIGNED(INTEGER(360.0 * 255.0 * ARCTAN(1.0 / (2.0 ** REAL(i)))/(MATH_2_PI * REAL(270))), angle_t'LENGTH);
    END LOOP;
    RETURN precomputed_angles;
  END FUNCTION precompute_angles;
END codric_aux;

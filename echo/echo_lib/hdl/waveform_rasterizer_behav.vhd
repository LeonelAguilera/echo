--
-- VHDL Architecture echo_lib.waveform_rasterizer.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-112.ad.liu.se)
--          at - 09:09:32 10/18/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE IEEE.MATH_REAL.ALL;

ENTITY waveform_rasterizer IS
  GENERIC( 
    log2_block_size      : INTEGER := 6;
    h_block_number       : INTEGER := 10;
    v_block_number       : INTEGER := 8;
    line_thickness       : INTEGER := 4;
    fixed_point_decimals : INTEGER := 4
  );
  PORT( 
    data_available : IN     std_logic;
    x_coordinate   : IN     std_logic_vector (7 DOWNTO 0);
    y_coordinate   : IN     std_logic_vector (7 DOWNTO 0);
    buffer_ready   : OUT    std_logic;
    color_data     : OUT    std_logic_vector (5 DOWNTO 0);
    next_data      : OUT    std_logic;
    write_address  : OUT    std_logic_vector (18 DOWNTO 0);
    c0             : IN     std_logic;
    fpga_reset_n   : IN     std_logic
  );
  
  -- Declarations
  
END waveform_rasterizer ;

--
ARCHITECTURE behav OF waveform_rasterizer IS
  CONSTANT block_size : INTEGER := 2**log2_block_size;
  CONSTANT pixels_per_h_delta_fxp : INTEGER := (2**fixed_point_decimals) * (h_block_number * block_size) / 160;
  CONSTANT pixels_per_v_delta_fxp : INTEGER := (2**fixed_point_decimals) * (v_block_number * block_size) / 256;
  CONSTANT max_slope : INTEGER := INTEGER(CEIL( REAL(v_block_number*block_size*(2**fixed_point_decimals)) / REAL(pixels_per_h_delta_fxp) ));
  SIGNAL x_counter : SIGNED(INTEGER(CEIL(LOG2(REAL(h_block_number * block_size)))) DOWNTO 0);
  SIGNAL y_counter : SIGNED(INTEGER(CEIL(LOG2(REAL(v_block_number * block_size)))) DOWNTO 0);
  SIGNAL busy : STD_LOGIC;
BEGIN
  PROCESS(c0, fpga_reset_n)
    VARIABLE last_x_fxp : SIGNED(x_counter'LENGTH + fixed_point_decimals - 1 DOWNTO 0);
    VARIABLE last_y_fxp : SIGNED(y_counter'LENGTH + fixed_point_decimals - 1 DOWNTO 0);
    VARIABLE curr_x_fxp : SIGNED(x_counter'LENGTH + fixed_point_decimals - 1 DOWNTO 0);
    VARIABLE curr_y_fxp : SIGNED(y_counter'LENGTH + fixed_point_decimals - 1 DOWNTO 0);
    VARIABLE target_x : SIGNED(x_counter'LENGTH -1 DOWNTO 0);
    VARIABLE target_y : SIGNED(y_counter'LENGTH -1 DOWNTO 0);
    VARIABLE slope_fxp : SIGNED(INTEGER(CEIL(LOG2(REAL(max_slope)))) + fixed_point_decimals DOWNTO 0);
    VARIABLE line_height_fxp : SIGNED(slope_fxp'LENGTH + INTEGER(CEIL(LOG2(REAL(line_thickness)))) - 1 DOWNTO 0);
    VARIABLE temp_y_counter : SIGNED(last_y_fxp'LENGTH - 1 DOWNTO 0);
    VARIABLE temp_target_y  : SIGNED(last_y_fxp'LENGTH - 1 DOWNTO 0);
    VARIABLE delta_y : SIGNED(y_counter'LENGTH - 1 DOWNTO 0);
  BEGIN
    IF fpga_reset_n = '1' THEN
      busy <= '0';
      curr_x_fxp := (OTHERS => '0');
      curr_y_fxp := (OTHERS => '0');
    ELSIF RISING_EDGE(c0) THEN
      IF busy = '0' THEN
        next_data <= '1';
        IF data_available = '1' THEN
          next_data <= '0';
          busy <= '1';
          last_x_fxp := curr_x_fxp;
          last_y_fxp := curr_y_fxp;
          curr_x_fxp := RESIZE(SIGNED('0' & x_coordinate) * pixels_per_h_delta_fxp, curr_x_fxp'LENGTH);
          curr_y_fxp := RESIZE(SIGNED('0' & y_coordinate) * pixels_per_v_delta_fxp, curr_y_fxp'LENGTH);
          
          slope_fxp := RESIZE((curr_y_fxp - last_y_fxp) * (2**fixed_point_decimals) / (curr_x_fxp - last_x_fxp), slope_fxp);
          line_height_fxp := RESIZE((ABS(slope_fxp) + (2**fixed_point_decimals)) * line_thickness, line_height_fxp'LENGTH);
          
          x_counter <= last_x_fxp(last_x_fxp'LENGTH - 1 DOWNTO fixed_point_decimals);
          target_x  := curr_x_fxp(curr_x_fxp'LENGTH - 1 DOWNTO fixed_point_decimals);
          
          temp_y_counter := last_y_fxp + RESIZE(SHIFT_RIGHT(line_height_fxp, 1), last_y_fxp'LENGTH);
          temp_target_y  := last_y_fxp - RESIZE(SHIFT_RIGHT(line_height_fxp, 1), last_y_fxp'LENGTH);
          y_counter <= MAXIMUM(0, MINIMUM(temp_y_counter(temp_y_counter'LENGTH - 1 DOWNTO fixed_point_decimals), (2**(y_counter'LENGTH - 1)) - 1));
          target_y  := MAXIMUM(0, MINIMUM(temp_target_y(temp_target_y'LENGTH - 1 DOWNTO fixed_point_decimals), (2**(target_y'LENGTH - 1)) - 1));
        END IF;
      ELSE
        IF x_counter /= target_x AND y_counter /= target_y THEN
          write_address <= STD_LOGIC_VECTOR(x_counter(x_counter'LENGTH -2 DOWNTO 0) & y_counter(y_counter'LENGTH -2 DOWNTO 0));
          color_data <= (OTHERS => '1');
          y_counter <= y_counter - 1;
        ELSIF x_counter /= target_x THEN
          delta_y := RESIZE(SHIFT_RIGHT(slope_fxp * (x_counter + 1 - last_x_fxp(last_x_fxp'LENGTH - 1 DOWNTO fixed_point_decimals)), fixed_point_decimals), delta_y'LENGTH);
          
          y_counter <= MAXIMUM(0, MINIMUM(temp_y_counter(y_counter'LENGTH - 1 DOWNTO fixed_point_decimals) + delta_y, (2**(y_counter'LENGTH - 1)) - 1));
          target_y  := MAXIMUM(0, MINIMUM(temp_target_y(y_counter'LENGTH - 1 DOWNTO fixed_point_decimals) + delta_y, (2**(target_y'LENGTH - 1)) - 1));
          
          x_counter <= x_counter + 1;
        ELSE
          busy <= '0';
          next_data <= '1';
        END IF;
      END IF;
    END IF;
  END PROCESS;
END ARCHITECTURE behav;




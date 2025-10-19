--
-- VHDL Architecture echo_lib.coordinate_fifo.behav
--
-- Created:
--          by - leoag319.student-liu.se (muxen2-113.ad.liu.se)
--          at - 10:20:54 10/17/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE IEEE.MATH_REAL.ALL;

ENTITY coordinate_fifo IS
  GENERIC( 
    fifo_size : INTEGER := 8
  );
  PORT( 
    load_new         : IN     std_logic;
    new_x_coordinate : IN     STD_LOGIC_VECTOR (7 DOWNTO 0);
    new_y_coordinate : IN     STD_LOGIC_VECTOR (7 DOWNTO 0);
    next_data        : IN     std_logic;
    data_available   : OUT    std_logic;
    x_coordinate     : OUT    std_logic_vector (7 DOWNTO 0);
    y_coordinate     : OUT    std_logic_vector (7 DOWNTO 0);
    c0               : IN     std_logic;
    fpga_reset_n     : IN     std_logic
  );
  
  -- Declarations
  
END coordinate_fifo ;

--
ARCHITECTURE behav OF coordinate_fifo IS
  TYPE coord_info IS ARRAY(1 DOWNTO 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
  TYPE fifo_t IS ARRAY(fifo_size - 1 DOWNTO 0) OF coord_info;
  SIGNAL coord_memory : fifo_t;
  SIGNAL last_load : STD_LOGIC;
  SIGNAL last_nd : STD_LOGIC;
  SIGNAL pending : STD_LOGIC;
  
  FUNCTION increment_pointer(pointer_in : INTEGER) RETURN INTEGER IS
  BEGIN
    IF pointer_in + 1 = fifo_size THEN
      RETURN 0;
    ELSE
      RETURN pointer_in + 1;
    END IF;
  END FUNCTION;
BEGIN
  PROCESS(c0, fpga_reset_n)
    VARIABLE write_pointer : INTEGER RANGE 0 TO fifo_size;
    VARIABLE read_pointer : INTEGER RANGE 0 TO fifo_size;
  BEGIN
    IF fpga_reset_n = '1' THEN
      write_pointer := 0;
      read_pointer := 0;
      pending <= '0';
      last_load <= '0';
      last_nd <= '0';
    ELSIF RISING_EDGE(c0) THEN
      last_load <= load_new;
      last_nd <= next_data;
      
      IF load_new = '1' AND last_load = '0' THEN
        IF increment_pointer(write_pointer) /= read_pointer THEN
          write_pointer := increment_pointer(write_pointer);
        END IF;
        coord_memory(write_pointer) <= (new_x_coordinate, new_y_coordinate);
        
        IF pending = '1' THEN
          read_pointer := increment_pointer(read_pointer);
          x_coordinate <= new_x_coordinate;
          y_coordinate <= new_y_coordinate;
          data_available <= '1';
          pending <= '0';
        END IF;
      END IF;
      
      IF next_data = '1' AND last_nd = '0' AND pending = '0' THEN
        IF read_pointer = write_pointer THEN
          pending <= '1';
        ELSE
          read_pointer := increment_pointer(read_pointer);
          (x_coordinate, y_coordinate) <= coord_memory(read_pointer);
          data_available <= '1';
        END IF;
      ELSIF pending = '0' THEN
        data_available <= '0';              
      END IF;
    END IF;
  END PROCESS;
END ARCHITECTURE behav;
  
  
  
  
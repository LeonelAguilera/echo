--
-- VHDL Architecture echo_lib.sram_ctrl.behav
--
-- Created:
--          by - antmo328.student-liu.se (muxen2-112.ad.liu.se)
--          at - 18:20:32 10/08/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY sram_ctrl IS
   GENERIC( 
      G_ADDR_WIDTH : natural := 20;
      G_DATA_WIDTH : natural := 16
   );
   PORT( 
      rd_valid  : OUT    std_logic;
      SRAM_ADDR : OUT    std_logic_vector (G_ADDR_WIDTH-1 DOWNTO 0);
      SRAM_DQ   : INOUT  std_logic_vector (G_DATA_WIDTH-1 DOWNTO 0);
      SRAM_CE_N : OUT    std_logic;
      SRAM_OE_N : OUT    std_logic;
      SRAM_WE_N : OUT    std_logic;
      SRAM_UB_N : OUT    std_logic;
      SRAM_LB_N : OUT    std_logic;
      rd_addr   : IN     std_logic_vector (G_ADDR_WIDTH-1 DOWNTO 0);
      rd_en     : IN     std_logic;
      wr_en     : IN     std_logic;
      clk       : IN     std_logic;
      RESET_N   : IN     std_logic;
      wr_data   : IN     std_logic_vector (G_DATA_WIDTH-1 DOWNTO 0);
      wr_addr   : IN     std_logic_vector (G_ADDR_WIDTH-1 DOWNTO 0);
      rd_data   : OUT    std_logic_vector (G_DATA_WIDTH-1 DOWNTO 0)
   );

-- Declarations

END sram_ctrl ;

architecture behav of sram_ctrl is
  type state_type is (IDLE, WRITE, WRITE_HOLD, READ, READ_HOLD);
  signal state, next_state : state_type;

  signal dq_out      : std_logic_vector(G_DATA_WIDTH-1 downto 0);
  signal dq_dir      : std_logic;  -- '1' = write drives bus
  signal rd_data_reg : std_logic_vector(G_DATA_WIDTH-1 downto 0);
begin
--------------------------------------------------------------------
-- Bidirectional Data Bus
--------------------------------------------------------------------
  SRAM_DQ <= dq_out when dq_dir = '1' else (others => 'Z');
  rd_data <= rd_data_reg;

--------------------------------------------------------------------
-- FSM: Next state
--------------------------------------------------------------------
  process (state, wr_en, rd_en)
  begin
    next_state <= state;
    case state is
      when IDLE =>
        if wr_en = '1' then
          next_state <= WRITE;
        elsif rd_en = '1' then
          next_state <= READ;
        end if;
      when WRITE       => next_state <= WRITE_HOLD;
      when WRITE_HOLD  => next_state <= IDLE;
      when READ        => next_state <= READ_HOLD;
      when READ_HOLD   => next_state <= IDLE;
    end case;
  end process;

--------------------------------------------------------------------
-- FSM: Sequential part
--------------------------------------------------------------------
  process (clk, RESET_N)
  begin
    if RESET_N = '0' then
      state       <= IDLE;
      rd_valid    <= '0';
      dq_dir      <= '0';
      dq_out      <= (others => '0');
      SRAM_ADDR   <= (others => '0');
      SRAM_CE_N   <= '0';  -- permanently enabled
      SRAM_WE_N   <= '1';
      SRAM_OE_N   <= '1';
      SRAM_UB_N   <= '0';
      SRAM_LB_N   <= '0';
    elsif rising_edge(clk) then
      state    <= next_state;
      rd_valid <= '0';  -- default each cycle

      case next_state is
        when IDLE =>
          dq_dir    <= '0';
          SRAM_WE_N <= '1';
          SRAM_OE_N <= '1';

        when WRITE =>
          dq_dir    <= '1';
          dq_out    <= wr_data;
          SRAM_ADDR <= wr_addr;
          SRAM_WE_N <= '0';
          SRAM_OE_N <= '1';

        when WRITE_HOLD =>
          SRAM_WE_N <= '1';
          dq_dir    <= '0';

        when READ =>
          dq_dir    <= '0';
          SRAM_ADDR <= rd_addr;
          SRAM_WE_N <= '1';
          SRAM_OE_N <= '0';

        when READ_HOLD =>
          rd_data_reg <= SRAM_DQ;
          rd_valid    <= '1';
          SRAM_OE_N   <= '1';
      end case;
    end if;
  end process;
end architecture;

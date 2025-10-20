--
-- VHDL Architecture echo_lib.SRAM_Async_Model.behav
--
-- Created:
--          by - antmo328.student-liu.se (muxen2-112.ad.liu.se)
--          at - 12:55:13 10/10/25
--
-- using Siemens HDL Designer(TM) 2024.1 Built on 24 Jan 2024 at 18:06:06
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sram_async_model is
  generic (
    DATA_WIDTH : positive := 16;
    ADDR_WIDTH : positive := 19
  );
  port (
    CE_N  : in  std_logic;
    OE_N  : in  std_logic;
    WE_N  : in  std_logic;
    LB_N  : in  std_logic;                                  -- low byte enable (D[7:0])
    UB_N  : in  std_logic;                                  -- high byte enable (D[15:8])
    A     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    DQ    : inout std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end entity;

architecture behav of sram_async_model is
  subtype word_t is std_logic_vector(DATA_WIDTH-1 downto 0);
  type mem_t is array (0 to (2**ADDR_WIDTH)-1) of word_t;
  signal mem : mem_t := (others => (others => '0'));

  -- interner Tri-State Treiber
  signal dq_out : word_t := (others => 'Z');
  signal drive  : std_logic := '0';
begin
  -- Tri-State auf den Bus
  gen_bus: for i in 0 to DATA_WIDTH-1 generate
    DQ(i) <= dq_out(i) when drive='1' else 'Z';
  end generate;

  process(CE_N, OE_N, WE_N, LB_N, UB_N, A, DQ)
    variable rd_word : word_t;
    variable wr_word : word_t;
  begin
    drive  <= '0';
    dq_out <= (others => 'Z');

    -- WRITE: CE=0, WE=0 (OE egal). DUT treibt DQ, wir übernehmen in mem.
    if (CE_N='0' and WE_N='0') then
      wr_word := mem(to_integer(unsigned(A)));

      if DATA_WIDTH = 16 then
        -- Byte-Enables beachten
        if LB_N = '0' then
          wr_word(7 downto 0) := DQ(7 downto 0);
        end if;
        if UB_N = '0' then
          wr_word(15 downto 8) := DQ(15 downto 8);
        end if;
      else
        wr_word := DQ; -- generisch, ohne BYTES
      end if;

      mem(to_integer(unsigned(A))) <= wr_word;

    -- READ: CE=0, WE=1, OE=0 -> wir treiben DQ
    elsif (CE_N='0' and WE_N='1' and OE_N='0') then
      rd_word := mem(to_integer(unsigned(A)));

      if DATA_WIDTH = 16 then
        -- Wenn Byte deaktiviert ist, treibe 'Z' auf dessen Bits
        dq_out(7 downto 0)  <= rd_word(7 downto 0)  when LB_N='0' else (others => 'Z');
        dq_out(15 downto 8) <= rd_word(15 downto 8) when UB_N='0' else (others => 'Z');
        drive <= '1' when ( (LB_N='0') or (UB_N='0') ) else '0';
      else
        dq_out <= rd_word;
        drive  <= '1';
      end if;
    end if;
  end process;
end architecture;

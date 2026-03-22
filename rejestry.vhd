library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rejestry is
   port (
        clk   : in  std_logic;
        DI    : in  signed(15 downto 0);
        BA    : in  signed(15 downto 0);    
        Sbb   : in  unsigned(3 downto 0);
        Sbc   : in  unsigned(3 downto 0);
        Sba   : in  unsigned(4 downto 0);
        Sid   : in  unsigned(3 downto 0);
        Sa    : in  unsigned(1 downto 0);
        RegWR_en: in std_logic;
        BB    : out signed(15 downto 0);
        BC    : out signed(15 downto 0);
        ADR   : out signed(31 downto 0);
        IRout : out signed(15 downto 0)
   );
end entity;

architecture rtl of rejestry is
    signal IR, TMP                             : signed(15 downto 0) := (others => '0');
    signal R0, R1, R2, R3, R4, R5, R6, R7      : signed(15 downto 0) := (others => '0');
    signal R8, R9, R10, R11, R12, R13          : signed(15 downto 0) := (others => '0');
    signal AD, PC, SP, ATMP                    : signed(31 downto 0) := (others => '0');
begin

    sync_process: process (clk)
    begin
        if (rising_edge(clk)) then
            case to_integer(Sid) is
                when 1 => PC <= PC + 1;
                when 2 => SP <= SP + 1;
                when 3 => SP <= SP - 1;
                when 4 => AD <= AD + 1;
                when 5 => AD <= AD - 1;
                when others => null;
            end case;
 		if RegWR_en = '1' then
            case to_integer(Sba) is
               
                when 0  => R0 <= BA; --rotate and shift for 2 registers
                when 1  => R1 <= BA;
                when 2  => R2 <= BA;
                when 3  => R3 <= BA;
                when 4  => R4 <= BA;
                when 5  => R5 <= BA;
                when 6  => R6 <= BA;
                when 7  => R7 <= BA;
                when 8 => R8 <= BA;
                when 9 => R9 <= BA;
                when 10 => R10 <= BA;
                when 11 => R11 <= BA;
                when 12 => R12 <= BA;
                when 13 => R13 <= BA;
				when 14  => TMP <= BA;
                when 15  => IR <= BA;
                when 16 => AD   <= resize(BA, 32);
                when 17 => PC   <= resize(BA, 32);
                when 18 => SP   <= resize(BA, 32);
                when 19 => ATMP <= resize(BA, 32);
                when others => null;
            end case;
            
 		elsif to_integer(Sid) >= 6 and to_integer(Sid) <= 9 then
         case to_integer(Sid) is
          when 6 => -- SHL
          	case to_integer(Sba) is
          		when 0 => R0   <= shift_left(R0, 1);
                when 1 => R1   <= shift_left(R1, 1);
                when 2 => R2   <= shift_left(R2, 1);
                when 3 => R3   <= shift_left(R3, 1);
                when 4 => R4   <= shift_left(R4, 1);
                when 5 => R5   <= shift_left(R5, 1);
                when 6 => R6   <= shift_left(R6, 1);
                when 7 => R7   <= shift_left(R7, 1);
                when 8 => R8   <= shift_left(R8, 1);
                when 9 => R9   <= shift_left(R9, 1);
                when 10 => R10 <= shift_left(R10, 1);
                when 11 => R11 <= shift_left(R11, 1);
                when 12 => R12 <= shift_left(R12, 1);
                when 13 => R13 <= shift_left(R13, 1);
 				when others => null;
			end case; 

			when 7 => -- SHR
              case to_integer(Sba) is
                when 0 => R0   <= shift_right(R0, 1);
                when 1 => R1   <= shift_right(R1, 1);
                when 2 => R2   <= shift_right(R2, 1);
                when 3 => R3   <= shift_right(R3, 1);
                when 4 => R4   <= shift_right(R4, 1);
                when 5 => R5   <= shift_right(R5, 1);
                when 6 => R6   <= shift_right(R6, 1);
                when 7 => R7   <= shift_right(R7, 1);
                when 8 => R8   <= shift_right(R8, 1);
                when 9 => R9   <= shift_right(R9, 1);
                when 10 => R10 <= shift_right(R10, 1);
                when 11 => R11 <= shift_right(R11, 1);
                when 12 => R12 <= shift_right(R12, 1);
                when 13 => R13 <= shift_right(R13, 1);
				when others => null;
              end case;

			when 8 => -- ROL
              case to_integer(Sba) is
                when 0 => R0   <= signed(std_logic_vector(rotate_left(unsigned(R0), 1)));
                when 1 => R1   <= signed(std_logic_vector(rotate_left(unsigned(R1), 1)));
                when 2 => R2   <= signed(std_logic_vector(rotate_left(unsigned(R2), 1)));
                when 3 => R3   <= signed(std_logic_vector(rotate_left(unsigned(R3), 1)));
                when 4 => R4   <= signed(std_logic_vector(rotate_left(unsigned(R4), 1)));
                when 5 => R5   <= signed(std_logic_vector(rotate_left(unsigned(R5), 1)));
                when 6 => R6   <= signed(std_logic_vector(rotate_left(unsigned(R6), 1)));
                when 7 => R7   <= signed(std_logic_vector(rotate_left(unsigned(R7), 1)));
                when 8 => R8   <= signed(std_logic_vector(rotate_left(unsigned(R8), 1)));
                when 9 => R9   <= signed(std_logic_vector(rotate_left(unsigned(R9), 1)));
                when 10 => R10 <= signed(std_logic_vector(rotate_left(unsigned(R10), 1)));
                when 11 => R11 <= signed(std_logic_vector(rotate_left(unsigned(R11), 1)));
                when 12 => R12 <= signed(std_logic_vector(rotate_left(unsigned(R12), 1)));
                when 13 => R13 <= signed(std_logic_vector(rotate_left(unsigned(R13), 1)));
				when others => null;
			  end case;

			when 9 => -- ROR
              case to_integer(Sba) is
              	when 0 => R0   <= signed(std_logic_vector(rotate_right(unsigned(R0), 1)));
                when 1 => R1   <= signed(std_logic_vector(rotate_right(unsigned(R1), 1)));
                when 2 => R2   <= signed(std_logic_vector(rotate_right(unsigned(R2), 1)));
                when 3 => R3   <= signed(std_logic_vector(rotate_right(unsigned(R3), 1)));
                when 4 => R4   <= signed(std_logic_vector(rotate_right(unsigned(R4), 1)));
                when 5 => R5   <= signed(std_logic_vector(rotate_right(unsigned(R5), 1)));
                when 6 => R6   <= signed(std_logic_vector(rotate_right(unsigned(R6), 1)));
                when 7 => R7   <= signed(std_logic_vector(rotate_right(unsigned(R7), 1)));
                when 8 => R8   <= signed(std_logic_vector(rotate_right(unsigned(R8), 1)));
                when 9 => R9   <= signed(std_logic_vector(rotate_right(unsigned(R9), 1)));
                when 10 => R10 <= signed(std_logic_vector(rotate_right(unsigned(R10), 1)));
                when 11 => R11 <= signed(std_logic_vector(rotate_right(unsigned(R11), 1)));
                when 12 => R12 <= signed(std_logic_vector(rotate_right(unsigned(R12), 1)));
                when 13 => R13 <= signed(std_logic_vector(rotate_right(unsigned(R13), 1)));
				when others => null;
			  end case;
              
                    when others => null;
                end case; 
            end if;
        end if;
    end process;

    with to_integer(Sbb) select
        BB <= R0  when 0,
              R1  when 1,
              R2  when 2,
              R3  when 3,
              R4  when 4,
              R5  when 5,
              R6  when 6,
              R7  when 7,
              R8  when 8,
              R9  when 9,
              R10 when 10,
              R11 when 11,
              R12 when 12,
              R13 when 13,
              TMP when 14,
              DI  when 15,
              
              (others => 'X') when others;
              with to_integer(Sbc) select
        BC <= R0  when 0,
              R1  when 1,
              R2  when 2,
              R3  when 3,
              R4  when 4,
              R5  when 5,
              R6  when 6,
              R7  when 7,
              R8  when 8,
              R9  when 9,
              R10 when 10,
              R11 when 11,
              R12 when 12,
              R13 when 13,
              TMP when 14,
              DI  when 15,
              
              (others => 'X') when others;
              
              with to_integer(Sa) select
             ADR <= AD   when 0,
               PC   when 1,
               SP   when 2,
               ATMP when 3,
               (others => 'X') when others;

    IRout <= IR;
end rtl;
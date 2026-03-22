library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu_core is
    generic (
        DATA_WIDTH : integer := 16
    );
    Port (
        A        : in  STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
        B        : in  STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
        OPCODE   : in  STD_LOGIC_VECTOR (4 downto 0);
        RESULT   : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
        FLAGS    : out STD_LOGIC_VECTOR (3 downto 0)  -- (3 downto 0) => V, C, N, Z
    );
end alu_core;

architecture Behavioral of alu_core is
begin
    process(A, B, OPCODE)
        variable a_s_v    : signed(DATA_WIDTH - 1 downto 0);
        variable b_s_v    : signed(DATA_WIDTH - 1 downto 0);
        variable a_u_v    : unsigned(DATA_WIDTH - 1 downto 0);
        variable b_u_v    : unsigned(DATA_WIDTH - 1 downto 0);
        
        variable add_sub_res_v : signed(DATA_WIDTH downto 0);
        variable mult_res_v    : signed(2 * DATA_WIDTH - 1 downto 0);
        
        variable result_v : signed(DATA_WIDTH - 1 downto 0);
        variable flags_v  : std_logic_vector(3 downto 0);
        
    begin
        a_s_v := signed(A);
        b_s_v := signed(B);
        a_u_v := unsigned(A);
        b_u_v := unsigned(B);
        
        result_v := (others => '0');
        flags_v  := "0000";

        case OPCODE is
            -- === Group 1: Arithmetic operations ===
            when "00000" => -- ADD: Addition
                add_sub_res_v := resize(a_s_v, DATA_WIDTH + 1) + resize(b_s_v, DATA_WIDTH + 1);
                result_v      := add_sub_res_v(DATA_WIDTH - 1 downto 0);

            when "00001" => -- SUB: Subtraction
                add_sub_res_v := resize(a_s_v, DATA_WIDTH + 1) - resize(b_s_v, DATA_WIDTH + 1);
                result_v      := add_sub_res_v(DATA_WIDTH - 1 downto 0);

            when "00010" => -- MUL: Multiplication
                mult_res_v := a_s_v * b_s_v;
                result_v   := mult_res_v(DATA_WIDTH - 1 downto 0);

            when "00011" => -- DIV: Division
                if b_u_v = 0 then
                    flags_v(3) := '1'; -- V-flag used as error flag
                    result_v   := (others => 'X');
                else
                    result_v := a_s_v / b_s_v;
                end if;

            when "00100" => -- INC: Increment
                result_v := a_s_v + 1;

            when "00101" => -- DEC: Decrement
                result_v := a_s_v - 1;

            when "00110" => -- ABS: Absolute value
                if a_s_v < 0 then
                    result_v := -a_s_v;
                else
                    result_v := a_s_v;
                end if;

            -- === Group 2: Logical operations ===
            when "00111" => -- NOT: Logical NOT
                result_v := not a_s_v;

            when "01000" => -- OR: Logical OR
                result_v := signed(std_logic_vector(a_u_v or b_u_v));

            when "01001" => -- AND: Logical AND
                result_v := signed(std_logic_vector(a_u_v and b_u_v));

            when "01010" => -- XOR: Logical exclusive OR
                result_v := signed(std_logic_vector(a_u_v xor b_u_v));

            -- === Group 3: Shift and rotate operations ===
            when "01011" => -- SRA_1: Arithmetic shift right by 1
                result_v := shift_right(a_s_v, 1);

            when "01100" => -- SLL_1: Logical shift left by 1
                result_v := shift_left(a_s_v, 1);

            when "01101" => -- SRAV: Arithmetic shift right by B
                result_v := shift_right(a_s_v, to_integer(b_u_v));

            when "01110" => -- SLLV: Logical shift left by B
                result_v := shift_left(a_s_v, to_integer(b_u_v));

            when "01111" => -- ROR: Rotate right by B
                result_v := signed(std_logic_vector(rotate_right(a_u_v, to_integer(b_u_v))));

            when "10000" => -- ROL: Rotate left by B
                result_v := signed(std_logic_vector(rotate_left(a_u_v, to_integer(b_u_v))));

            when "10001" => -- REV: Bit reversal
                for i in 0 to DATA_WIDTH - 1 loop
                    result_v(i) := a_s_v(DATA_WIDTH - 1 - i);
                end loop;

            -- === Group 4: Comparison operations ===
            when "10010" => -- SGT: Set if greater (A > B)
                if a_s_v > b_s_v then
                    result_v := to_signed(1, DATA_WIDTH);
                else
                    result_v := to_signed(0, DATA_WIDTH);
                end if;

            when "10011" => -- SLT: Set if less (A < B)
                if a_s_v < b_s_v then
                    result_v := to_signed(1, DATA_WIDTH);
                else
                    result_v := to_signed(0, DATA_WIDTH);
                end if;

            when "10100" => -- SEQ: Set if equal (A = B)
                if a_s_v = b_s_v then
                    result_v := to_signed(1, DATA_WIDTH);
                else
                    result_v := to_signed(0, DATA_WIDTH);
                end if;

            when "10101" => -- SNE: Set if not equal (A /= B)
                if a_s_v /= b_s_v then
                    result_v := to_signed(1, DATA_WIDTH);
                else
                    result_v := to_signed(0, DATA_WIDTH);
                end if;

            when "10110" => -- MAX: Return the larger value
                if a_s_v > b_s_v then
                    result_v := a_s_v;
                else
                    result_v := b_s_v;
                end if;

            when "10111" => -- MIN: Return the smaller value
                if a_s_v < b_s_v then
                    result_v := a_s_v;
                else
                    result_v := b_s_v;
                end if;
            
            when others =>
                result_v := (others => '0');
        end case;
        
        -- Flag calculation
        if unsigned(result_v) = 0 then
            flags_v(0) := '1'; -- Z = 1
        end if;
        flags_v(1) := result_v(DATA_WIDTH - 1); -- N = MSB
        
        -- C and V flags are calculated only for ADD and SUB
        -- !!! WARNING: Operation codes updated !!!
        if OPCODE = "00000" or OPCODE = "00001" then
            if (OPCODE = "00000" and a_u_v + b_u_v > 2**DATA_WIDTH - 1) or
               (OPCODE = "00001" and a_u_v >= b_u_v) then
                flags_v(2) := '1'; -- C = 1
            end if;

            if (a_s_v(DATA_WIDTH-1) = b_s_v(DATA_WIDTH-1)) and
               (a_s_v(DATA_WIDTH-1) /= result_v(DATA_WIDTH-1)) then
                flags_v(3) := '1'; -- V = 1
            end if;
        end if;

        RESULT <= std_logic_vector(result_v);
        FLAGS  <= flags_v;
    end process;
end Behavioral;

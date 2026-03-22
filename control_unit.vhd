library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_unit is
port(
    clk      : in std_logic;
    reset    : in std_logic;
    IR       : in signed(15 downto 0);
    flags_in : in std_logic_vector(3 downto 0);

    -- OUTS
    Sbb : out unsigned(3 downto 0);
    Sbc : out unsigned(3 downto 0);
    Sba : out unsigned(4 downto 0);
    Sid : out unsigned(3 downto 0);
    Sa  : out unsigned(1 downto 0);
    
    CTL_Smar : out std_logic;
    CTL_Smbr : out std_logic; 
    CTL_WR   : out std_logic; 
    CTL_RD   : out std_logic;
    
    ALU_opcode : out std_logic_vector(4 downto 0);
    
    -- Memory address source multiplexer (Address Source Selector)
    -- Answers the question: "Which address should be sent to memory_interface?"
    -- '0' = Select address from PC (instruction fetch, FETCH stage)
    -- '1' = Select address just computed by the ALU (LOAD/STORE)
    Addr_src_sel  : out std_logic;

    -- ALU second operand source multiplexer (ALU Source B Selector)
    -- Answers the question: "What should be connected to the second ALU input?"
    -- '0' = Select data from the second register read port (BC bus)
    --       (For instructions like ADD R1, R2)
    -- '1' = Select immediate constant extracted from the IR instruction
    --       (For instructions like ADDI R1, R2, 100 or LOAD R1, 16(R2))
    ALU_src_B_sel : out std_logic;
    
    -- Register write data source multiplexer (Register Write Source Selector)
    -- Answers the question: "What data should be written into the register file?"
    -- '0' = Select result just computed by the ALU
    --       (For instructions like ADD, SUB, AND, ...)
    -- '1' = Select data just read from memory (from memory_interface)
    --       (For LOAD instruction)
    RegWR_src_sel : out std_logic;
    
    -- Global register file write enable (Register Write Enable)
    -- Answers the question: "Should anything be written to registers in this cycle?"
    -- '1' = Yes, write enabled (active only in WRITEBACK states)
    -- '0' = No, write disabled (all other states)
    RegWR_en     : out std_logic
);
end entity;

architecture rtl of control_unit is
    type T_STATE is (
        S_FETCH_1, S_FETCH_2, S_DECODE,
        S_EXECUTE_ALU, S_WRITEBACK_ALU,
        S_EXECUTE_MEM_ADDR, S_MEM_READ, S_MEM_WRITE, S_WRITEBACK_MEM,
        S_SWAP_1, S_SWAP_2, S_SWAP_3,
        S_EXECUTE_REG_SHIFT
    );
    signal state : T_STATE;
begin

state_transition: process(clk, reset)
begin
    if reset = '1' then
        state <= S_FETCH_1; -- On reset, return to the very first state
    elsif rising_edge(clk) then
        case state is
            -- --- Start of execution of any instruction ---
            when S_FETCH_1 =>
                -- PC has just been sent to MAR, now wait for memory
                state <= S_FETCH_2;
                
            when S_FETCH_2 =>
                -- Instruction has just been read, now decode it
                state <= S_DECODE;
                
            when S_DECODE =>
                -- This is the most important "crossroad"
                -- We inspect IR and decide where to go next
                if IR(15 downto 13) = "000" then
                    state <= S_EXECUTE_ALU; -- ADD/SUB → ALU
                elsif IR(15 downto 13) = "001" or
                      IR(15 downto 13) = "010" or
                      IR(15 downto 13) = "011" then
                    state <= S_EXECUTE_MEM_ADDR; -- LOAD/STORE → address calculation
                elsif IR(15 downto 13) = "100" then
                    state <= S_SWAP_1;
                elsif IR(15 downto 13) = "101" then
                    state <= S_EXECUTE_REG_SHIFT;
                else
                    state <= S_FETCH_1; -- Unknown instruction → restart
                end if;
                
            -- --- Arithmetic instruction path (e.g. ADD) ---
            when S_EXECUTE_ALU =>
                -- ALU operation just executed, now write back the result
                state <= S_WRITEBACK_ALU;

            when S_WRITEBACK_ALU =>
                -- Result written, instruction completed
                state <= S_FETCH_1;
                
            -- --- Memory instruction path (LOAD/STORE) ---
            when S_EXECUTE_MEM_ADDR =>
                -- Address computed by ALU, now access memory
                if IR(15 downto 13) = "001" then
                    state <= S_MEM_READ;  -- LOAD → read
                elsif IR(15 downto 13) = "010" then
                    state <= S_MEM_WRITE; -- STORE → write
                else 
                    state <= S_WRITEBACK_ALU;
                end if;
                
            when S_MEM_READ =>
                -- Data just read from memory, now write it to register
                state <= S_WRITEBACK_MEM;

            when S_WRITEBACK_MEM =>
                -- LOAD completed
                state <= S_FETCH_1;
                
            when S_MEM_WRITE =>
                -- STORE completed
                state <= S_FETCH_1;

            when S_SWAP_1 =>
                state <= S_SWAP_2;

            when S_SWAP_2 =>
                state <= S_SWAP_3;

            when S_SWAP_3 =>
                state <= S_FETCH_1;

            when S_EXECUTE_REG_SHIFT =>
                state <= S_FETCH_1;
        end case;
    end if;
end process;

output_logic: process(state, IR, FLAGS_IN)
begin
    Sbb <= (others => '0');
    Sbc <= (others => '0');
    Sba <= "11111"; -- "Do not write" command
    Sid <= "0000";  -- No special operations
    Sa  <= "00";

    -- memory_interface control
    CTL_Smar <= '0';
    CTL_Smbr <= '0';
    CTL_WR   <= '0';
    CTL_RD   <= '0';

    -- ALU control
    ALU_Opcode    <= "00000"; 
    Addr_src_sel  <= '0'; 
    ALU_src_B_sel <= '0'; 
    RegWR_src_sel <= '0'; 
    RegWR_en      <= '0';
    
    case state is
        when S_FETCH_1 =>
            Addr_src_sel <= '0';
            Sa <= "01";
            CTL_Smar <= '1';

        when S_FETCH_2 =>
            CTL_RD <= '1';
            RegWR_src_sel <= '1'; -- Source for write is memory
            Sba <= "01111";       -- FIX: IR address in register file
            RegWR_en <= '1';      -- FIX: Allow instruction write into IR
            Sid <= "0001"; 

        when S_DECODE =>
            Sbb <= unsigned(IR(12 downto 9));
            Sbc <= unsigned(IR(8 downto 5));

        when S_EXECUTE_ALU =>
            ALU_opcode <= std_logic_vector(IR(4 downto 0));
            ALU_src_B_sel <= '0';
            Sbb <= unsigned(IR(12 downto 9));
            Sbc <= unsigned(IR(8 downto 5));

        when S_WRITEBACK_ALU =>
            RegWR_en <= '1';
            RegWR_src_sel <= '0';
            Sba <= '0' & unsigned(IR(12 downto 9));

            -- FIX: Keep correct ALU settings during writeback
            if IR(15 downto 13) = "011" then -- ADDI
                ALU_opcode <= "00000"; -- Continue addition
                ALU_src_B_sel <= '1';  -- Continue using immediate
            else
                ALU_opcode <= std_logic_vector(IR(4 downto 0));
                ALU_src_B_sel <= '0';
                Sbb <= unsigned(IR(12 downto 9));
                Sbc <= unsigned(IR(8 downto 5));
            end if;
            
        when S_EXECUTE_MEM_ADDR =>
            ALU_opcode <= "00000"; -- ADD
            ALU_src_B_sel <= '1';  -- Immediate
            Sbb <= unsigned(IR(8 downto 5)); -- Base register is always RegB

            CTL_Smar <= '1';
            Addr_src_sel <= '1';

            if IR(15 downto 13) = "010" then -- STORE
                Sbc <= unsigned(IR(12 downto 9)); -- Data from RegA
                CTL_Smbr <= '1';
            end if;

        when S_MEM_READ =>
            CTL_RD <= '1'; 
            Addr_src_sel <= '1';
            -- Hold address
            Sbb <= unsigned(IR(8 downto 5));
            ALU_src_B_sel <= '1';
            ALU_opcode <= "00000";

        when S_WRITEBACK_MEM =>
            RegWR_en <= '1';
            RegWR_src_sel <= '1'; 
            Sba <= '0' & unsigned(IR(12 downto 9)); -- Write LOAD result into RegA
            -- Hold signals
            CTL_RD <= '1';
            Addr_src_sel <= '1';
            Sbb <= unsigned(IR(8 downto 5));
            ALU_src_B_sel <= '1';
            ALU_opcode <= "00000";

        when S_MEM_WRITE =>
            CTL_WR <= '1'; 
            Addr_src_sel <= '1';
            -- Hold address and data
            Sbb <= unsigned(IR(8 downto 5));
            ALU_src_B_sel <= '1';
            ALU_opcode <= "00000";
            Sbc <= unsigned(IR(12 downto 9)); -- Hold RegA data
            
        when S_SWAP_1 =>
            ALU_opcode <= "01000";
            RegWR_en <= '1';
            Sbb <= unsigned(IR(12 downto 9));
            Sbc <= unsigned(IR(12 downto 9));
            Sba <= "01110";

        when S_SWAP_2 =>
            ALU_opcode <= "01000";
            RegWR_en <= '1';
            Sbb <= unsigned(IR(8 downto 5));
            Sbc <= unsigned(IR(8 downto 5));
            Sba <= '0' & unsigned(IR(12 downto 9));

        when S_SWAP_3 =>
            ALU_opcode <= "01000";
            RegWR_en <= '1';
            Sbb <= "1110";
            Sbc <= "1110";
            Sba <= '0' & unsigned(IR(8 downto 5));

        when S_EXECUTE_REG_SHIFT =>
            Sba <= '0' & unsigned(IR(12 downto 9));
            Sid <= unsigned(IR(3 downto 0));
            RegWR_en <= '0'; 

        when others => null;
    end case;
end process;

process(state)
begin
    case state is
        when S_FETCH_1 => report "STATE: S_FETCH_1";
        when S_FETCH_2 => report "STATE: S_FETCH_2";
        when S_DECODE  => report "STATE: S_DECODE";
        when S_EXECUTE_ALU => report "STATE: S_EXECUTE_ALU";
        when S_WRITEBACK_ALU => report "STATE: S_WRITEBACK_ALU";
        when S_EXECUTE_MEM_ADDR => report "STATE: EXECUTE_MEM_ADDR";
        when S_MEM_READ => report "STATE: S_MEM_READ";
        when S_MEM_WRITE => report "STATE: S_MEM_WRITE";
        when S_WRITEBACK_MEM => report "STATE: S_WRITEBACK_MEM";
        when S_SWAP_1 => report "STATE: S_SWAP_1";
        when S_SWAP_2 => report "STATE: S_SWAP_2";
        when S_SWAP_3 => report "STATE: S_SWAP_3";
        when S_EXECUTE_REG_SHIFT => report "STATE: S_EXECUTE_REG_SHIFT";
        when others => report "STATE: OTHER";
    end case;
end process;

end rtl;

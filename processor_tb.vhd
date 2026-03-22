library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_processor_top is
end entity;

architecture sim of tb_processor_top is
    signal clk      : std_logic := '0';
    signal reset    : std_logic := '0';
    signal mem_addr : signed(31 downto 0);
    signal mem_data : signed(15 downto 0);
    signal mem_wr   : std_logic;
    signal mem_rd   : std_logic;
    signal sim_end  : boolean := false;

    constant CLK_PERIOD : time := 20 ns;

    type ram_type is array (0 to 63) of signed(15 downto 0);
    signal ram : ram_type := (
        -- === INITIALIZATION (ADDI) ===
        0 => b"011_0000_0000_00000", -- 0: ADDI R0, R0, 0   (R0 = 0, ensure base is zero)
        1 => b"011_0001_0000_01010", -- 1: ADDI R1, R0, 10  (R1 = 10)
        2 => b"011_0010_0000_10100", -- 2: ADDI R2, R0, 20  (R2 = 20)
        3 => b"011_0011_0000_00101", -- 3: ADDI R3, R0, 5   (R3 = 5)

        -- === ALU OPERATIONS (2-address: RegA = RegA op RegB) ===
        4 => b"000_0001_0010_00000", -- 4: ADD R1, R2       (R1 = 10 + 20 = 30)
        5 => b"000_0010_0011_01010", -- 5: XOR R2, R3       (R2 = 20 XOR 5 = 17)
        6 => b"000_0011_0011_10001", -- 6: REV R3           (R3 = reverse bits of 5)
        7 => b"000_0001_0010_10111", -- 7: MIN R1, R2       (R1 = min(30, 17) = 17)
        
		-- === DATA MOVEMENT ===        
		8 => b"010_0001_0000_11011", -- 8: STORE [R0+27], R1 (Write 17 to RAM[27])
        9 => b"001_0100_0000_11011", -- 9: LOAD R4, [R0+27] (R4 = 17)
        
        -- === SWAP ===
        10 => b"100_0010_0011_00000", -- 10: SWAP R2, R3      (R2 = rev(5) R3 = 17)

        -- === REGISTER SPECIAL OPERATIONS (Sid) ===
        11=> b"101_0100_0000_00110", -- 11:SHL R4           (17 << 1 = 34)
        12=> b"101_0100_0000_01001", -- 12:ROR R4           (34 rotate right 1 = 17)

        others => (others => '0')
    );

begin
    -- Component under test
    uut: entity work.processor_top
        port map (
            CLK => clk, RESET => reset,
            MEM_ADDR => mem_addr, MEM_DATA => mem_data,
            MEM_WR => mem_wr, MEM_RD => mem_rd
        );

    -- Clock generation with simulation stop support
    clk_process: process
    begin
        while not sim_end loop
            clk <= '0'; wait for CLK_PERIOD / 2;
            clk <= '1'; wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    -- RAM Behavioral Model
    memory_sim: process(clk)
        variable addr_int : integer;
    begin 
        if rising_edge(clk) then
            -- We use 6 bits for addressing our 64-word array
            addr_int := to_integer(unsigned(mem_addr(5 downto 0)));
            if mem_wr = '1' then
                ram(addr_int) <= mem_data;
            end if;
        end if;
    end process;

    -- Memory Data Bus 
    mem_data <= ram(to_integer(unsigned(mem_addr(5 downto 0)))) when mem_rd = '1' else (others => 'Z');

    -- Main Test Sequence
    stim_proc: process
    begin
        -- System Reset
        reset <= '1';
        wait for CLK_PERIOD * 3;
        reset <= '0';
        
        wait for CLK_PERIOD * 120;

        -- 1. Check if STORE [27] = 30 worked
        assert ram(27) = to_signed(17, 16)
            report "Test Failed: RAM(27) should be 17" severity error;
        
        if ram(27) = to_signed(17, 16) then
            report "--- SUCCESS: Processor passed test! ---";
        end if;
        
        sim_end <= true; 
        wait;
    end process;
end architecture;
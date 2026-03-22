library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory_interface is
    port (
        -- === Global signals ===
        CLK : in  std_logic;
        RST : in  std_logic;

        -- === Inputs from the "brain" (Control Unit) ===
        CTL_Smar : in  std_logic; -- '1' = Load address into MAR
        CTL_Smbr : in  std_logic; -- '1' = Load data into MBR for write
        CTL_WR   : in  std_logic; -- '1' = Activate memory write signal
        CTL_RD   : in  std_logic; -- '1' = Activate memory read signal

        -- === Data buses from/to Datapath ===
        DP_ADR_IN   : in  signed(31 downto 0); -- Address from PC/ALU
        DP_DATA_OUT : in  signed(15 downto 0); -- Data from registers for write
        DP_DATA_IN  : out signed(15 downto 0); -- Data going to registers after read

        -- === Buses to external memory ===
        MEM_ADDR     : out   signed(31 downto 0);
        MEM_DATA     : inout signed(15 downto 0);
        MEM_WR_OUT   : out   std_logic;
        MEM_RD_OUT   : out   std_logic
    );
end entity;

architecture rtl of memory_interface is
    -- Internal registers: MAR (address) and MBR (data)
    signal MAR : signed(31 downto 0) := (others => '0');
    signal MBR : signed(15 downto 0) := (others => '0');
begin

    -- 1. SYNCHRONOUS PROCESS: responsible for writing into internal MAR and MBR registers
    sync_process: process(CLK, RST)
    begin
        if RST = '1' then
            MAR <= (others => '0');
            MBR <= (others => '0');
        elsif rising_edge(CLK) then
            -- Capture address into MAR
            if CTL_Smar = '1' then
                MAR <= DP_ADR_IN;
            end if;

            -- Capture data for write into MBR
            if CTL_Smbr = '1' then
                MBR <= DP_DATA_OUT;
            end if;
        end if;
    end process;

    -- 2. COMBINATIONAL LOGIC: responsible for driving external buses

    -- Address on the memory bus is ALWAYS equal to MAR
    MEM_ADDR <= MAR;
    
    -- Control signals are simply forwarded outside
    MEM_WR_OUT <= CTL_WR;
    MEM_RD_OUT <= CTL_RD;

    -- Control of the bidirectional data bus MEM_DATA
    MEM_DATA <= MBR when CTL_WR = '1' else (others => 'Z');

    -- Data returned to the Datapath is taken from MEM_DATA during read
    DP_DATA_IN <= MEM_DATA when CTL_RD = '1' else (others => 'X');

end rtl;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity processor_top is
    port (
        -- Global inputs
        CLK   : in  std_logic;
        RESET : in  std_logic;
        
        -- External memory interface
        MEM_ADDR : out signed(31 downto 0);
        MEM_DATA : inout signed(15 downto 0);
        MEM_WR   : out std_logic;
        MEM_RD   : out std_logic
    );
end entity;

architecture structural of processor_top is

component alu_core is port ( 
    A      : in  STD_LOGIC_VECTOR(15 downto 0);
    B      : in  STD_LOGIC_VECTOR(15 downto 0); 
    OPCODE : in  STD_LOGIC_VECTOR(4 downto 0); 
    RESULT : out STD_LOGIC_VECTOR(15 downto 0); 
    FLAGS  : out STD_LOGIC_VECTOR(3 downto 0)
); 
end component;

component rejestry is port ( 
    clk      : in  std_logic; 
    DI       : in  signed(15 downto 0);
    BA       : in  signed(15 downto 0); 
    Sbb      : in  unsigned(3 downto 0); 
    Sbc      : in  unsigned(3 downto 0); 
    Sba      : in  unsigned(4 downto 0); 
    Sid      : in  unsigned(3 downto 0); 
    Sa       : in  unsigned(1 downto 0); 
    RegWR_en : in  std_logic; -- ADDED
    BB       : out signed(15 downto 0); 
    BC       : out signed(15 downto 0); 
    ADR      : out signed(31 downto 0); 
    IRout    : out signed(15 downto 0) 
); 
end component;

component memory_interface is port ( 
    CLK          : in std_logic; 
    RST          : in std_logic; 
    CTL_Smar     : in std_logic; 
    CTL_Smbr     : in std_logic; 
    CTL_WR       : in std_logic; 
    CTL_RD       : in std_logic; 
    DP_ADR_IN    : in signed(31 downto 0); 
    DP_DATA_OUT  : in signed(15 downto 0); 
    DP_DATA_IN   : out signed(15 downto 0); 
    MEM_ADDR     : out signed(31 downto 0); 
    MEM_DATA     : inout signed(15 downto 0);
    MEM_WR_OUT   : out std_logic; 
    MEM_RD_OUT   : out std_logic 
); 
end component;

component control_unit is port ( 
    clk            : in std_logic; 
    reset          : in std_logic; 
    IR             : in signed(15 downto 0); 
    flags_in       : in std_logic_vector(3 downto 0); 
    Sbb            : out unsigned(3 downto 0); 
    Sbc            : out unsigned(3 downto 0); 
    Sba            : out unsigned(4 downto 0); 
    Sid            : out unsigned(3 downto 0); 
    Sa             : out unsigned(1 downto 0); 
    CTL_Smar       : out std_logic; 
    CTL_Smbr       : out std_logic; 
    CTL_WR         : out std_logic; 
    CTL_RD         : out std_logic; 
    ALU_Opcode     : out std_logic_vector(4 downto 0); 
    Addr_src_sel   : out std_logic; 
    ALU_src_B_sel  : out std_logic; 
    RegWR_src_sel  : out std_logic; 
    RegWR_en       : out std_logic 
); 
end component;

    signal s_Sbb, s_Sbc       : unsigned(3 downto 0);
    signal s_Sba              : unsigned(4 downto 0);
    signal s_Sid              : unsigned(3 downto 0);
    signal s_Sa               : unsigned(1 downto 0);
    signal s_CTL_Smar, s_CTL_Smbr, s_CTL_WR, s_CTL_RD : std_logic;
    signal s_ALU_Opcode       : std_logic_vector(4 downto 0);
    signal s_Addr_src_sel, s_ALU_src_B_sel, s_RegWR_src_sel, s_RegWR_en : std_logic;
    
    -- Data buses between components
    signal s_IR               : signed(15 downto 0); -- IR output from register file -> control unit input
    signal s_FLAGS            : std_logic_vector(3 downto 0); -- FLAGS output from ALU -> control unit input
    signal s_BB, s_BC         : signed(15 downto 0); -- Register outputs -> ALU inputs
    signal s_ALU_Result       : std_logic_vector(15 downto 0); -- ALU output
    signal s_Data_from_Mem    : signed(15 downto 0); -- Data received from memory
    signal s_ADR_from_regs    : signed(31 downto 0); -- 32-bit address from register block (PC/SP)
    
    -- Signals for "glue logic" (multiplexer outputs)
    signal s_ALU_in_B          : signed(15 downto 0); -- Final value for ALU second input
    signal s_RegFile_WriteData : signed(15 downto 0); -- Final data to be written into registers (BA bus)
    signal s_Addr_to_Mem_IF    : signed(31 downto 0); -- Final address for memory interface
    
begin

UUT_ALU: alu_core port map ( 
    A      => std_logic_vector(s_BB), 
    B      => std_logic_vector(s_ALU_in_B), 
    OPCODE => s_ALU_Opcode, 
    RESULT => s_ALU_Result, 
    FLAGS  => s_FLAGS 
);
        
UUT_Rejestry: rejestry port map ( 
    clk      => CLK, 
    DI       => s_Data_from_Mem, 
    BA       => s_RegFile_WriteData, 
    Sbb      => s_Sbb, 
    Sbc      => s_Sbc, 
    Sba      => s_Sba, 
    Sid      => s_Sid, 
    Sa       => s_Sa, 
    RegWR_en => s_RegWR_en, -- CONNECTED
    BB       => s_BB, 
    BC       => s_BC, 
    ADR      => s_ADR_from_regs, 
    IRout    => s_IR 
);
        
UUT_Mem_Interface: memory_interface port map ( 
    CLK         => CLK, 
    RST         => RESET, 
    CTL_Smar    => s_CTL_Smar, 
    CTL_Smbr    => s_CTL_Smbr, 
    CTL_WR      => s_CTL_WR, 
    CTL_RD      => s_CTL_RD, 
    DP_ADR_IN   => s_Addr_to_Mem_IF, 
    DP_DATA_OUT => s_BC, 
    DP_DATA_IN  => s_Data_from_Mem, 
    MEM_ADDR    => MEM_ADDR, 
    MEM_DATA    => MEM_DATA, 
    MEM_WR_OUT  => MEM_WR, 
    MEM_RD_OUT  => MEM_RD 
);

UUT_Control_Unit: control_unit port map ( 
    clk           => CLK, 
    reset         => RESET, 
    IR            => s_IR, 
    flags_in      => s_FLAGS, 
    Sbb           => s_Sbb, 
    Sbc           => s_Sbc, 
    Sba           => s_Sba, 
    Sid           => s_Sid, 
    Sa            => s_Sa, 
    CTL_Smar      => s_CTL_Smar, 
    CTL_Smbr      => s_CTL_Smbr, 
    CTL_WR        => s_CTL_WR, 
    CTL_RD        => s_CTL_RD, 
    ALU_Opcode    => s_ALU_Opcode, 
    Addr_src_sel  => s_Addr_src_sel, 
    ALU_src_B_sel => s_ALU_src_B_sel,
    RegWR_src_sel => s_RegWR_src_sel,
    RegWR_en      => s_RegWR_en 
);

-- MUX: Select memory address source, controlled by s_Addr_src_sel
s_Addr_to_Mem_IF <= s_ADR_from_regs
                    when s_Addr_src_sel = '0'
                    else resize(signed(s_ALU_Result), 32);
    
-- MUX: Select second ALU operand, controlled by s_ALU_src_B_sel
s_ALU_in_B <= s_BC
              when s_ALU_src_B_sel = '0'
              else signed(resize(unsigned(s_IR(4 downto 0)), 16)); -- Take 5-bit immediate from IR and extend to 16 bits
    
-- MUX: Select data to be written into register file (connected to BA input),
-- controlled by s_RegWR_src_sel and s_RegWR_en
s_RegFile_WriteData <= s_Data_from_Mem
                       when (s_RegWR_src_sel = '1')
                       else signed(s_ALU_Result);
   
end structural;

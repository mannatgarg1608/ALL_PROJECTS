library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity inv_sub_bytes is
  Port ( 
        input8 : in std_logic_vector(7 downto 0);
        output8 : out std_logic_vector(7 downto 0);
        clk      : in std_logic;
        rst    : in  std_logic
        );
end inv_sub_bytes;

architecture Behavioral of inv_sub_bytes is

component blk_mem_gen_2
    port (
        addra  : in std_logic_vector(7 downto 0);
        clka   : in std_logic;
        rsta :   in std_logic;
        douta  : out std_logic_vector(7 downto 0)
    ); 
end component;

signal intermediate_address : std_logic_vector(7 downto 0);


begin

 intermediate_address <= input8;

sub_byte_lookup : blk_mem_gen_2 
    port map(
        addra  =>  intermediate_address,
        clka   => clk,
        rsta   =>rst,
        douta  => output8
    );

end Behavioral;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity add_round_key is
    Port (
        input1  : in STD_LOGIC_VECTOR(31 downto 0);  -- 32-bit input1
        input2  : in STD_LOGIC_VECTOR(31 downto 0);  -- 32-bit input2
        output  : out STD_LOGIC_VECTOR(31 downto 0)  -- 32-bit output
    );
end add_round_key;

architecture Behavioral of add_round_key is
begin

    -- Perform XOR on each 8-bit chunk
    output(7 downto 0)   <= input1(7 downto 0)   xor input2(7 downto 0);
    output(15 downto 8)  <= input1(15 downto 8)  xor input2(15 downto 8);
    output(23 downto 16) <= input1(23 downto 16) xor input2(23 downto 16);
    output(31 downto 24) <= input1(31 downto 24) xor input2(31 downto 24);

end Behavioral;
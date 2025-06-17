library IEEE;
use IEEE.STD_LOGIC_1164.ALL;




entity mux_4x1 is

    Port ( A : in STD_LOGIC_VECTOR(7 downto 0); 
           B : in STD_LOGIC_VECTOR(7 downto 0);
           C : in STD_LOGIC_VECTOR(7 downto 0);
           D : in STD_LOGIC_VECTOR(7 downto 0);
           S : in STD_LOGIC_VECTOR(1 downto 0);
           Y : out STD_LOGIC_VECTOR(7 downto 0));
end mux_4x1;

architecture Behavioral of mux_4x1 is
begin
    process(A,B,C,D,S)
    --implemented mux through if else statements,selected which digit to display using value of selector
    begin
        if(S ="00") then
            Y<= A;
        elsif(S ="01") then
            Y<= B;
        elsif(S="10") then
            Y<= C;
        elsif(S ="11") then
            Y<= D;
        else Y <="00000000";
        end if;
    end process;
   
    
end Behavioral;
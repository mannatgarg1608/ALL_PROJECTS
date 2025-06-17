library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Timing_block is
    Port (
        clk_in : in STD_LOGIC; -- 100 MHz input clock
        reset :  in STD_LOGIC:='0';--Reset signal
        anodes : out STD_LOGIC_VECTOR (3 downto 0); -- Anodes signal for display
        mux : out STD_LOGIC_VECTOR (1 downto 0)--Signal for the mux
       );
end Timing_block;

architecture Behavioral of Timing_block is
    signal new_clk : STD_LOGIC :='0';
    constant N : integer := 8;-- <need to select correct value>, decided the value bases on persistence of vision
    signal count : integer := 0;
    signal counter: integer := 0;


begin
--Process 1 for dividing the clock from 100 Mhz to 1Khz - 60hz
    NEW_CLK2: process(clk_in, reset)
    begin
        if (reset = '1') then
            new_clk <= '0';
            counter <=  0;
        elsif rising_edge(clk_in) then
            if (counter = N-1) then
                counter <= 0;
                new_clk <= not new_clk;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;
--Process 2 for mux select signal
    MUX_SELECT1: process(new_clk,reset)
    begin
        if (reset ='1') then
            count<=0;
        elsif rising_edge(new_clk) then
             count<=count+1;
        end if;
    end process;
--Process 3 for anode signal
    ANODE_select: process(count)
    begin
        if(count mod 4 = 0) then
            mux <="00";
            anodes <="0111";
        elsif(count mod 4 = 1) then
            mux <= "01";
            anodes <="1011";
        elsif(count mod 4 = 2) then
            mux <= "10";
            anodes <="1101";
        elsif(count mod 4 = 3) then
            mux<="11";
            anodes <="1110";
        else mux <="00";
        end if;

    end process;
end behavioral;
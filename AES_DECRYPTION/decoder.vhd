library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Entity for 7-segment display decoder
entity decoder is
    Port (
        bns  : in  std_logic_vector(7 downto 0);  -- 4-bit binary input (0-15)
        cathode_display : out std_logic_vector(6 downto 0)   -- 7-segment display output (active low)
    );
end decoder;

architecture Behavioral of decoder is

begin
    -- 7-segment display decoder logic
    process(bns)
    begin
        case bns is
            -- we have represented every ascii character corresponding to the matrix hexadecimal value
            -- 0 means a led is on and 1 means it is off
            when "00110000" => cathode_display <= "0000001"; -- 0
            when "00110001" => cathode_display <= "1001111"; -- 1
            when "00110010" => cathode_display <= "0010010"; -- 2
            when "00110011" => cathode_display <= "0000110"; -- 3
            when "00110100" => cathode_display <= "1001100"; -- 4
            when "00110101" => cathode_display <= "0100100"; -- 5
            when "00110110" => cathode_display <= "0100000"; -- 6
            when "00110111" => cathode_display <= "0001111"; -- 7
            when "00111000" => cathode_display <= "0000000"; -- 8
            when "00111001" => cathode_display <= "0000100"; -- 9
            when "01000001" => cathode_display <= "0000010"; -- a
            when "01000010" => cathode_display <= "1100000"; -- b
            when "01000011" => cathode_display <= "0110001"; -- C
            when "01000100" => cathode_display <= "1000010"; -- d
            when "01000101" => cathode_display <= "0110000"; -- E
            when "01000110" => cathode_display <= "0111000"; -- F
            when "01100001" => cathode_display <= "0000010"; -- a
            when "01100010" => cathode_display <= "1100000"; -- b
            when "01100011" => cathode_display <= "0110001"; -- C
            when "01100100" => cathode_display <= "1000010"; -- d
            when "01100101" => cathode_display <= "0110000"; -- E
            when "01100110" => cathode_display <= "0111000"; -- F
            when "00100000" => cathode_display <= "1111111";-- space
            when others => cathode_display <= "1111110"; -- Default: putting a bar
        end case;
    end process;

end Behavioral;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity inv_shift_row is
    Port (
        row_number : in integer range 0 to 3;        -- Row number to determine the shift pattern
        state_in   : in std_logic_vector(31 downto 0); -- 32-bit input row
        state_out  : out std_logic_vector(31 downto 0) -- 32-bit output row after InvShiftRows
    );
end inv_shift_row;

architecture Behavioral of inv_shift_row is
begin
    process(row_number, state_in)
    begin
        if row_number = 0 then
            -- No shift for row 0
            state_out(31 downto 24) <= state_in(31 downto 24);
            state_out(23 downto 16) <= state_in(23 downto 16);
            state_out(15 downto 8)  <= state_in(15 downto 8);
            state_out(7 downto 0)   <= state_in(7 downto 0);

        elsif row_number = 1 then
            -- Shift row 1 by 1 position to the right
            state_out(31 downto 24) <= state_in(7 downto 0);
            state_out(23 downto 16) <= state_in(31 downto 24);
            state_out(15 downto 8)  <= state_in(23 downto 16);
            state_out(7 downto 0)   <= state_in(15 downto 8);

        elsif row_number = 2 then
            -- Shift row 2 by 2 positions to the right
            state_out(31 downto 24) <= state_in(15 downto 8);
            state_out(23 downto 16) <= state_in(7 downto 0);
            state_out(15 downto 8)  <= state_in(31 downto 24);
            state_out(7 downto 0)   <= state_in(23 downto 16);

        elsif row_number = 3 then
            -- Shift row 3 by 3 positions to the right
            state_out(31 downto 24) <= state_in(23 downto 16);
            state_out(23 downto 16) <= state_in(15 downto 8);
            state_out(15 downto 8)  <= state_in(7 downto 0);
            state_out(7 downto 0)   <= state_in(31 downto 24);

        else
            -- Default case if row_number is out of range (should not occur)
            state_out <= (others => '0');
        end if;
    end process;

end Behavioral;
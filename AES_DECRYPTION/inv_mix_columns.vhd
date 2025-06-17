library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity inv_mix_columns is
    Port (
        input_col : in STD_LOGIC_VECTOR(31 downto 0);   -- 4 x 8-bit input column
        output_col : out STD_LOGIC_VECTOR(31 downto 0)  -- 4 x 8-bit output column
    );
end inv_mix_columns;

architecture Behavioral of inv_mix_columns is
    -- Function to perform GF(2^8) multiplication
    -- Polynomial used in GF(2^8) multiplication (0x11B)
    constant gf_poly : std_logic_vector(7 downto 0) := "00011011";

    -- Function to perform GF(2^8) multiplication
    function multiplier_of_two(input1, input2: STD_LOGIC_VECTOR(7 downto 0)) return STD_LOGIC_VECTOR is
        variable var_input1 : STD_LOGIC_VECTOR(7 downto 0) := input1;
        variable product : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    begin
        for i in 0 to 7 loop
            if input2(i) = '1' then
                product := product XOR var_input1;
            end if;
            if var_input1(7) = '1' then
                var_input1 := (var_input1(6 downto 0) & '0') XOR gf_poly;
            else
                var_input1 := var_input1(6 downto 0) & '0';
            end if;
        end loop;
        return product;
    end function;
    -- names of intermediate rows and column
    signal col_0, col_1, col_2, col_3 : STD_LOGIC_VECTOR(7 downto 0);
    signal row_0, row_1, row_2, row_3 : STD_LOGIC_VECTOR(7 downto 0);

begin
    -- Split the input column into 4 bytes
    col_0 <= input_col(31 downto 24);
    col_1 <= input_col(23 downto 16);
    col_2 <= input_col(15 downto 8);
    col_3 <= input_col(7 downto 0);

    -- Perform the matrix multiplication for each row
    row_0 <= multiplier_of_two(X"0E", col_0) XOR multiplier_of_two(X"0B", col_1) XOR multiplier_of_two(X"0D", col_2) XOR multiplier_of_two(X"09", col_3);
    row_1 <= multiplier_of_two(X"09", col_0) XOR multiplier_of_two(X"0E", col_1) XOR multiplier_of_two(X"0B", col_2) XOR multiplier_of_two(X"0D", col_3);
    row_2 <= multiplier_of_two(X"0D", col_0) XOR multiplier_of_two(X"09", col_1) XOR multiplier_of_two(X"0E", col_2) XOR multiplier_of_two(X"0B", col_3);
    row_3 <= multiplier_of_two(X"0B", col_0) XOR multiplier_of_two(X"0D", col_1) XOR multiplier_of_two(X"09", col_2) XOR multiplier_of_two(X"0E", col_3);

    -- Combine the rows into the output column
    output_col <= row_0 & row_1 & row_2 & row_3;

end Behavioral;
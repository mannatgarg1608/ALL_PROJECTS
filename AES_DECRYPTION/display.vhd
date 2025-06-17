library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity display is
    Port (
        clk_in    : in  STD_LOGIC;                     -- 100 MHz clock
        reset     : in  STD_LOGIC;                     -- Reset signal
        --data_in   : in  STD_LOGIC_VECTOR(127 downto 0); -- 128-bit input data
        anodes    : out STD_LOGIC_VECTOR(3 downto 0);   -- Anode signals for the display
        cathode   : out STD_LOGIC_VECTOR(6 downto 0)    -- Cathode signals for the 7-segment display
    );
end display;

architecture Behavioral of display is
    signal data_in: std_logic_vector(127 downto 0):=x"30313233343536373839404142434445";
    -- Component declaration for main
    component main
        Port (
            clk_in  : in  STD_LOGIC;
            reset   : in  STD_LOGIC;
            number  : in  STD_LOGIC_VECTOR(31 downto 0);
            anodes  : out STD_LOGIC_VECTOR(3 downto 0);
            cathode : out STD_LOGIC_VECTOR(6 downto 0)
        );
    end component;

    -- Internal signals
    -- 100000000
    constant N: integer :=100 ;
    signal cycle_count : integer range 0 to 15 := 0;
    signal scroll_count : integer range 0 to 11 := 0;
    signal clk_divider : integer range 0 to N := 0;
    signal current_number : STD_LOGIC_VECTOR(31 downto 0);
    signal shift_position : integer range 0 to 96 := 0;
    -- Register to store the last 4 digits being displayed
    signal digit1 : STD_LOGIC_VECTOR(7 downto 0);
    signal digit2 : STD_LOGIC_VECTOR(7 downto 0);
    signal digit3 : STD_LOGIC_VECTOR(7 downto 0);
    signal digit4 : STD_LOGIC_VECTOR(7 downto 0);

begin
    -- Instantiate main component
    main_inst: main
        Port map (
            clk_in  => clk_in,
            reset   => reset,
            number  => current_number,
            anodes  => anodes,
            cathode => cathode
        );

    -- Combine digits into current_number
    

    -- Process for controlling display timing and data shifting
    process(clk_in, reset)
    begin
        if reset = '1' then
            clk_divider <= 0;
            
        elsif rising_edge(clk_in) then
            -- Clock divider for slower updates
            if clk_divider = N-1 then  -- Adjust this value to control scroll speed
                clk_divider <= 0;
--                digit1 <= data_in((127-shift_position) downto (120-shift_position));
--                digit2 <= data_in((119-shift_position) downto (112-shift_position));
--                digit3 <= data_in((111-shift_position) downto (104-shift_position));
--                digit4 <= data_in((103-shift_position) downto (96-shift_position));
                current_number <= data_in((127-shift_position) downto (96-shift_position));
                if scroll_count = 11 then  -- Reset after 12 shifts
                    scroll_count <= 0;
                    shift_position <= 0;
                
                else
                    
                    scroll_count <= scroll_count + 1;
                    shift_position <= shift_position + 8;
                 
                end if;
            
            else
                clk_divider <= clk_divider + 1;
            end if;
        end if;
    end process;

end Behavioral;
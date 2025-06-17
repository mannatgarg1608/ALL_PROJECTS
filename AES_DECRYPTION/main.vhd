library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity main is
    Port (
        clk_in  : in  STD_LOGIC;                  -- 100 MHz clock
        reset   : in  STD_LOGIC:='0';                  -- Reset signal
        number  : in  STD_LOGIC_VECTOR(31 downto 0);  -- 4-digit input number
        anodes  : out STD_LOGIC_VECTOR(3 downto 0);   -- Anode signals for the display
        cathode : out STD_LOGIC_VECTOR(6 downto 0)    -- Cathode signals for the 7-segment display
    );
end main;

architecture Behavioral of main is
    --Imported component mux_4x1
    component mux_4x1
        Port (
            A : in  STD_LOGIC_VECTOR(7 downto 0);
            B : in  STD_LOGIC_VECTOR(7 downto 0);
            C : in  STD_LOGIC_VECTOR(7 downto 0);
            D : in  STD_LOGIC_VECTOR(7 downto 0);
            S : in  STD_LOGIC_VECTOR(1 downto 0);
            Y : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;
    --Imported component decoder
    component decoder
        Port (
            bns    : in  STD_LOGIC_VECTOR(7 downto 0);
            cathode_display : out STD_LOGIC_VECTOR(6 downto 0)
        );
    end component;
    --Imported component Timing_block
    component Timing_block
        Port (
            clk_in : in  STD_LOGIC;
            reset  : in  STD_LOGIC;
            mux    : out STD_LOGIC_VECTOR(1 downto 0);
            anodes : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

    -- Internal signals
    signal mux_sel : STD_LOGIC_VECTOR(1 downto 0);
    signal digit   : STD_LOGIC_VECTOR(7 downto 0);

begin
    --Port mapping of Timing_block, decoder, mux_4x1
    UUT1: Timing_block
        Port map (
            clk_in => clk_in,
            reset  => reset,
            mux    => mux_sel,
            anodes => anodes
        );

      
    UUT2: decoder
        Port map (
            bns    => digit,
            cathode_display => cathode
        );
     UUT3: mux_4x1
        Port map (
            A => number(31 downto 24),
            B => number(23 downto 16),
            C => number(15 downto 8),
            D => number(7 downto 0),
            S => mux_sel,
            Y => digit
        );

end Behavioral;
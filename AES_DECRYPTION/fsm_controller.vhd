library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
entity fsm_controller is
--  Port ( );
Port (
        clk          : in STD_LOGIC;
        rst        : in STD_LOGIC;
        start        : in STD_LOGIC;
        plaintext_out : out STD_LOGIC_VECTOR(127 downto 0) ;
        done : out    STD_LOGIC     -- 128-bit final output
    );
end fsm_controller;

architecture Behavioral of fsm_controller is
    signal input1 :  STD_LOGIC_VECTOR(31 downto 0);
    signal input2 :  STD_LOGIC_VECTOR(31 downto 0);
    signal output : STD_LOGIC_VECTOR(31 downto 0);
    
    -- declaring signals for inverse shift row operation
    signal state_in :  STD_LOGIC_VECTOR(31 downto 0);
    signal state_out :  STD_LOGIC_VECTOR(31 downto 0);
    signal row_number :integer range 0 to 3 := 0;
    
    -- decalring signals for inv sub bytes
    signal input8 :  STD_LOGIC_VECTOR(7 downto 0);
    signal output8 :  STD_LOGIC_VECTOR(7 downto 0);
    
    
    -- Intermediate signals for inverse mix column
    signal input_col     : STD_LOGIC_VECTOR(31 downto 0);
    signal output_col    : STD_LOGIC_VECTOR(31 downto 0);
    
    
    -- Signals and Registers
    signal cur_round     : INTEGER range 0 to 10 := 0;
    signal round_done    : STD_LOGIC := '0';
    signal next_step     : INTEGER range 0 to 8:=1;
    signal do_step     : INTEGER range 0 to 8;
    type data_array      is array (0 to 3) of STD_LOGIC_VECTOR(31 downto 0);
    signal data_regs     : data_array; -- Four 32-bit registers for storing rows of data
    signal round_regs    : data_array; -- Four 32-bit registers for storing round keys
    signal col_data      : data_array; -- Transposed data for InvMixColumns


    -- ROM and BRAM signals
    signal rom1_data     : STD_LOGIC_VECTOR(7 downto 0);
    signal rom2_data     : STD_LOGIC_VECTOR(7 downto 0);
   
   --address of round key 
   signal addr_round_key     : STD_LOGIC_VECTOR(7 downto 0);
   
   --address for data regs
   signal addr_data_regs     : STD_LOGIC_VECTOR(7 downto 0);
   
   
--    signal enable_rom1, enable_rom2 : STD_LOGIC;
    signal a1: STD_LOGIC:='0';
    
    shared variable clk_counter : INTEGER := 0;
    shared variable rema: INTEGER:= 0;
    shared variable quo: INTEGER  := 0;
    signal var_i: INTEGER range 0 to 6;
    
    type state_type is (
        IDLE,
        INIT_READ,
        INITIAL_XOR,
        INV_MIX_COLST,
        INV_SUB_BYTEST,
        INV_SHIFT_ROWST,  -- Added missing comma
        ROUND_KEY_XOR,
        CHECK_ROUND,    -- Added missing state
        FINAL_XOR,
        INTIAL_INV_SHIFT_ROWST,
        INITIAL_INV_SUB_BYTEST
        
    );
    
    signal cur_state, next_state : state_type:=IDLE;
    signal done_sig : STD_LOGIC;  -- Added internal signal for done
    
    
    
   component inv_mix_columns
        Port (
            input_col : in STD_LOGIC_VECTOR(31 downto 0);
            output_col : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;
    
    component inv_shift_row 
        Port (
            row_number : in integer range 0 to 3;
            state_in   : in STD_LOGIC_VECTOR(31 downto 0);
            state_out  : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;
    
    component add_round_key 
        Port (
            input1  : in STD_LOGIC_VECTOR(31 downto 0);
            input2  : in STD_LOGIC_VECTOR(31 downto 0);
            output  : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;
    
    component inv_sub_bytes
        Port (
            clk      : in STD_LOGIC;
            rst      : in STD_LOGIC;
            input8  : in STD_LOGIC_VECTOR(7 downto 0);
            output8 : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;
    
    component blk_mem_gen_1
        Port (
            clka   : in STD_LOGIC;
            rsta   : in STD_LOGIC;
            addra  : in STD_LOGIC_VECTOR(7 downto 0);
            douta  : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;
     component blk_mem_gen_0
        Port (
            clka   : in STD_LOGIC;
            rsta   : in STD_LOGIC;
           
            addra  : in STD_LOGIC_VECTOR(7 downto 0);
            douta  : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;
    

begin
      u_inv_mix_columns: inv_mix_columns
        Port map (
            input_col => input_col,
            output_col => output_col
        );
   
    
    u_inv_shift_row:  inv_shift_row 
        Port map (
            row_number =>row_number,
            state_in   => state_in ,
            state_out  => state_out
        );
  
    
    u_add_round_key: add_round_key 
        Port map (
            input1  => input1,
            input2  => input2,
            output  => output
        );
     
    
     u_inv_sub_bytes: inv_sub_bytes
        Port map(
            clk      => clk,
            rst      => rst,
            input8  => input8,
            output8 => output8
        );
    
    -- Instantiate ROM and BRAM modules
    rom1 : blk_mem_gen_1
        port map (
            clka   => clk,
            rsta   => rst,
            addra  => addr_round_key,
            douta  => rom1_data
        );

    rom2 : blk_mem_gen_0
        port map (
            clka   => clk,
            rsta   => rst,
            addra  =>  addr_data_regs,
            douta  => rom2_data
        );


process(clk, rst)
    begin
        
        if rst = '1' then
            data_regs <= (others => (others => '0'));
            done_sig<='0';
            cur_round <= 0;
            clk_counter := 0;
        elsif rising_edge(clk) then
            -- Increment clk_counter each clock cycle
            clk_counter := clk_counter+1;
            
            
    
            case next_state is
                when IDLE =>
                    if start = '1' then
                        next_state <= INIT_READ;
                        next_step <= 1;
                    end if;
                    
                when INIT_READ =>
                    if (a1='0') and (clk_counter <= 64) then 
                            clk_counter:=0;
                            a1<='1';
                        end if;
                        if (clk_counter>=4)and (clk_counter <=64)then
                            rema:=(clk_counter-4)mod 16;
                            quo:=(clk_counter-4-rema)/16;
                        end if;
                        if (clk_counter = 0) and (clk_counter <=64) then
    --                        enable_rom2 <= '1';  -- Enable ROM for the first 32-bit read
                            addr_data_regs<=std_logic_vector(to_unsigned(0,8));
    
                        elsif rema=0 and clk_counter>=4 and clk_counter <= 64 then
                            data_regs(quo)(31 downto 24)<= rom2_data;
                            addr_data_regs<=std_logic_vector(to_unsigned(4*quo+1,8));
                        elsif (rema = 4) and (clk_counter <= 64) then
                            data_regs(quo)(23 downto 16)<= rom2_data; 
                            addr_data_regs<=std_logic_vector(to_unsigned(4*quo+2,8));
    
                        elsif (rema = 8)and (clk_counter <=64)  then
                            data_regs(quo)(15 downto 8)<= rom2_data;  
                            addr_data_regs<=std_logic_vector(to_unsigned(4*quo+3,8));                -- Store the 2nd chunk in data_regs(1)
                        elsif (rema = 12) and (clk_counter <=64) then
                            data_regs(quo)(7 downto 0)<= rom2_data;  -- Store the 3rd chunk in data_regs(2)
                                                                                                               
                            if (clk_counter <64) then
                                addr_data_regs<=std_logic_vector(to_unsigned(4*quo+4,8)); 
                            end if;   
                        elsif clk_counter>=68 then
                            next_state <= INITIAL_XOR;
                            
                        elsif(clk_counter >=64) and clk_counter<68 then
                            a1<='0';
                            rema := 0;
                            quo := 0;
                        end if;
                    
                  
                when INITIAL_XOR =>
                        if a1 = '0' then 
                            a1 <= '1';
                            clk_counter := 0;
                        end if;
                        if clk_counter <= 80 then 
                            rema:=(clk_counter)mod 20;
                            quo:=(clk_counter-rema)/20;
                        end if;
                        if (clk_counter = 0) then
    --                        enable_rom1 <= '1';  -- Enable ROM for the first 32-bit read
                            addr_round_key <= std_logic_vector(to_unsigned(16*(9-cur_round),8));
    
                        elsif (rema=4) and clk_counter <= 80 then
                            round_regs(quo)(31 downto 24)<= rom1_data;
                            addr_round_key<= std_logic_vector(TO_UNSIGNED(16*(9-cur_round)+4*quo+1,8));
                            
                        elsif (rema = 8)and clk_counter <= 80 then
                            round_regs(quo)(23 downto 16)<= rom1_data; 
                            addr_round_key<= std_logic_vector(TO_UNSIGNED(16*(9-cur_round)+4*quo+2,8));
                        
                        elsif (rema = 12)and clk_counter <= 80 then
                            round_regs(quo)(15 downto 8)<= rom1_data;  -- Store the 2nd chunk in data_regs(1)
                            addr_round_key<= std_logic_vector(TO_UNSIGNED(16*(9-cur_round)+4*quo+3,8));
                            
                        elsif (rema = 16 or rema =18)and clk_counter <= 80 then
                            if rema =16 then 
                                round_regs(quo)(7 downto 0)<= rom1_data;
                              -- Store the 3rd chunk in data_regs(2)
                            elsif rema =18 then 
                                input1<= data_regs(quo);
                                input2<= round_regs(quo);
                            end if;
                        elsif (rema=19) and clk_counter <= 80 then 
                            data_regs(quo) <= output ;
                            if quo<3 then
                                addr_round_key<= std_logic_vector(TO_UNSIGNED(16*(9-cur_round)+4*quo+4,8));
                            end if;
                        end if;
                        
                        if (clk_counter = 80) then
                             clk_counter := 0;  
                              a1 <= '0';
                              rema := 0;
                              quo := 0;  
                            next_state <= INTIAL_INV_SHIFT_ROWST;
                            cur_round <= 1;
--                        elsif  (clk_counter = 81) then 
                                                       -- Update round number from FSM output
                        end if;        -- Mark round as done after last chunk
                    
               when INTIAL_INV_SHIFT_ROWST =>
                        if a1 = '0' then 
                            a1 <= '1';
                            clk_counter := 0;
                        end if;
                        if clk_counter>=0 and clk_counter<=15 then
                            if clk_counter mod 4 = 0 then 
                                     row_number <= clk_counter/4;
                                     state_in <= data_regs(clk_counter/4);
                            elsif clk_counter mod 4 = 3 then
                                  data_regs((clk_counter-3)/4) <= state_out; 
                                             
                            end if;
                       end if;
                       if clk_counter = 15 then
                                        clk_counter := 0;
                                        a1 <= '0';
                                        next_state <= INITIAL_INV_SUB_BYTEST;
                                       
                       end if; 
                    
                when INITIAL_INV_SUB_BYTEST =>
                    if a1 = '0' and clk_counter <=66 then 
                            a1 <= '1';
                            clk_counter := 0;
                    end if;                
                     if clk_counter = 0 then 
                           input8 <= data_regs(0)(31 downto 24);
                     elsif clk_counter = 4 then 
                           data_regs(0)(31 downto 24) <= output8;
                           input8 <= data_regs(0)(23 downto 16);
                     elsif clk_counter = 8 then 
                           data_regs(0)(23 downto 16) <= output8;
                           input8 <= data_regs(0)(15 downto 8);    
                     elsif clk_counter = 12 then 
                           data_regs(0)(15 downto 8) <= output8;
                           input8 <= data_regs(0)(7 downto 0) ; 
                     elsif clk_counter = 16 then 
                           data_regs(0)(7 downto 0) <= output8;
                           input8 <= data_regs(1)(31 downto 24);
                     elsif clk_counter = 20 then 
                           data_regs(1)(31 downto 24) <= output8;
                           input8 <= data_regs(1)(23 downto 16);    
                     elsif clk_counter = 24 then 
                          data_regs(1)(23 downto 16) <= output8;
                          input8 <= data_regs(1)(15 downto 8) ;
                     elsif clk_counter = 28 then 
                           data_regs(1)(15 downto 8) <= output8;
                           input8 <= data_regs(1)(7 downto 0);    
                     elsif clk_counter = 32 then 
                          data_regs(1)(7 downto 0) <= output8;
                           input8 <= data_regs(2)(31 downto 24);
                     elsif clk_counter = 36 then 
                           data_regs(2)(31 downto 24) <= output8;
                           input8 <= data_regs(2)(23 downto 16);    
                     elsif clk_counter = 40 then 
                          data_regs(2)(23 downto 16) <= output8;
                          input8 <= data_regs(2)(15 downto 8) ;
                     elsif clk_counter = 44 then 
                           data_regs(2)(15 downto 8) <= output8;
                           input8 <= data_regs(2)(7 downto 0);    
                     elsif clk_counter = 48 then 
                          data_regs(2)(7 downto 0) <= output8;
                          input8 <= data_regs(3)(31 downto 24); 
                     elsif clk_counter = 52 then 
                           data_regs(3)(31 downto 24) <= output8;
                           input8 <= data_regs(3)(23 downto 16);    
                     elsif clk_counter = 56 then 
                          data_regs(3)(23 downto 16) <= output8;
                          input8 <= data_regs(3)(15 downto 8) ;
                     elsif clk_counter = 60 then 
                           data_regs(3)(15 downto 8) <= output8;
                           input8 <= data_regs(3)(7 downto 0);    
                     elsif clk_counter = 64 then 
                          data_regs(3)(7 downto 0) <= output8;
                     elsif clk_counter = 66 then 
                          next_state <= ROUND_KEY_XOR;
                          a1 <= '0';
                     elsif clk_counter = 67 then
                          clk_counter := 0;        
                     end if ;
                     
                         
                 when ROUND_KEY_XOR =>
                        if a1 = '0' then 
                            a1 <= '1';
                            clk_counter := 0;
                        end if;
                        if clk_counter <= 80 then 
                            rema:=(clk_counter)mod 20;
                            quo:=(clk_counter-rema)/20;
                        end if;
                        if (clk_counter = 0) then
    --                        enable_rom1 <= '1';  -- Enable ROM for the first 32-bit read
                            addr_round_key <= std_logic_vector(to_unsigned(16*(9-cur_round),8));
    
                        elsif (rema=4) and clk_counter <= 80 then
                            round_regs(quo)(31 downto 24)<= rom1_data;
                            addr_round_key<= std_logic_vector(TO_UNSIGNED(16*(9-cur_round)+4*quo+1,8));
                            
                        elsif (rema = 8)and clk_counter <= 80 then
                            round_regs(quo)(23 downto 16)<= rom1_data; 
                            addr_round_key<= std_logic_vector(TO_UNSIGNED(16*(9-cur_round)+4*quo+2,8));
                        
                        elsif (rema = 12)and clk_counter <= 80 then
                            round_regs(quo)(15 downto 8)<= rom1_data;  -- Store the 2nd chunk in data_regs(1)
                            addr_round_key<= std_logic_vector(TO_UNSIGNED(16*(9-cur_round)+4*quo+3,8));
                            
                        elsif (rema = 16 or rema =18)and clk_counter <= 80 then
                            if rema =16 then 
                                round_regs(quo)(7 downto 0)<= rom1_data;
                              -- Store the 3rd chunk in data_regs(2)
                            elsif rema =18 then 
                                input1<= data_regs(quo);
                                input2<= round_regs(quo);
                            end if;
                        elsif (rema=19) and clk_counter <= 80 then 
                            data_regs(quo) <= output ;
                            if quo<3 then
                                addr_round_key<= std_logic_vector(TO_UNSIGNED(16*(9-cur_round)+4*quo+4,8));
                            end if;
                        end if;
                        
                        if (clk_counter = 80) then
                             clk_counter := 0;  
                              a1 <= '0';
                              rema := 0;
                              quo := 0;  
                            next_state <= INV_MIX_COLST;
                         
--                        elsif  (clk_counter = 81) then 
                                                       -- Update round number from FSM output
                        end if;        -- Mark round as done after last chunk
                          
                 when INV_MIX_COLST =>
                        if a1 = '0' then 
                            a1 <= '1';
                            clk_counter := 0;
                        end if;
                        if (clk_counter = 0) then
                            -- Extract columns for InvMixColumns
                            input_col <= data_regs(0)(31 downto 24) & data_regs(1)(31 downto 24) &
                                         data_regs(2)(31 downto 24) & data_regs(3)(31 downto 24);
                        elsif (clk_counter = 4) then
                            data_regs(0)(31 downto 24) <= output_col(31 downto 24);
                            data_regs(1)(31 downto 24) <= output_col(23 downto 16);
                            data_regs(2)(31 downto 24) <= output_col(15 downto 8);
                            data_regs(3)(31 downto 24) <= output_col(7 downto 0);
                            input_col <= data_regs(0)(23 downto 16) & data_regs(1)(23 downto 16) &
                                         data_regs(2)(23 downto 16) & data_regs(3)(23 downto 16);
                           
                        elsif (clk_counter = 8) then
                            data_regs(0)(23 downto 16) <= output_col(31 downto 24);
                            data_regs(1)(23 downto 16) <= output_col(23 downto 16);
                            data_regs(2)(23 downto 16) <= output_col(15 downto 8);
                            data_regs(3)(23 downto 16) <= output_col(7 downto 0);
                            input_col <= data_regs(0)(15 downto 8) & data_regs(1)(15 downto 8) &
                                         data_regs(2)(15 downto 8) & data_regs(3)(15 downto 8);
                           
                        elsif (clk_counter = 12) then
                            data_regs(0)(15 downto 8) <= output_col(31 downto 24);
                            data_regs(1)(15 downto 8) <= output_col(23 downto 16);
                            data_regs(2)(15 downto 8) <= output_col(15 downto 8);
                            data_regs(3)(15 downto 8) <= output_col(7 downto 0);
                            input_col <= data_regs(0)(7 downto 0) & data_regs(1)(7 downto 0) &
                                         data_regs(2)(7 downto 0) & data_regs(3)(7 downto 0);
                        elsif (clk_counter = 16) then
                            data_regs(0)(7 downto 0) <= output_col(31 downto 24);
                            data_regs(1)(7 downto 0) <= output_col(23 downto 16);
                            data_regs(2)(7 downto 0) <= output_col(15 downto 8);
                            data_regs(3)(7 downto 0) <= output_col(7 downto 0);
                        elsif clk_counter=19 then 
                           
                            clk_counter := 0;
                            a1 <= '0';
                            next_state <= INV_SHIFT_ROWST;
                            
                            
                        end if;
                        
               when INV_SHIFT_ROWST =>
                         if a1 = '0' then 
                            a1 <= '1';
                            clk_counter := 0;
                        end if;
                        if clk_counter>=0 and clk_counter<=15 then
                            if clk_counter mod 4 = 0 then 
                                     row_number <= clk_counter/4;
                                     state_in <= data_regs(clk_counter/4);
                            elsif clk_counter mod 4 = 3 then
                                  data_regs((clk_counter-3)/4) <= state_out; 
                                             
                            end if;
                       end if;
                       if clk_counter = 15 then
                                        clk_counter := 0;
                                        a1 <= '0';
                                        next_state <= INV_SUB_BYTEST;
                                       
                       end if; 
                    
                when INV_SUB_BYTEST =>
                    if a1 = '0' and clk_counter <=66 then 
                            a1 <= '1';
                            clk_counter := 0;
                    end if;                
                     if clk_counter = 0 then 
                           input8 <= data_regs(0)(31 downto 24);
                     elsif clk_counter = 4 then 
                           data_regs(0)(31 downto 24) <= output8;
                           input8 <= data_regs(0)(23 downto 16);
                     elsif clk_counter = 8 then 
                           data_regs(0)(23 downto 16) <= output8;
                           input8 <= data_regs(0)(15 downto 8);    
                     elsif clk_counter = 12 then 
                           data_regs(0)(15 downto 8) <= output8;
                           input8 <= data_regs(0)(7 downto 0) ; 
                     elsif clk_counter = 16 then 
                           data_regs(0)(7 downto 0) <= output8;
                           input8 <= data_regs(1)(31 downto 24);
                     elsif clk_counter = 20 then 
                           data_regs(1)(31 downto 24) <= output8;
                           input8 <= data_regs(1)(23 downto 16);    
                     elsif clk_counter = 24 then 
                          data_regs(1)(23 downto 16) <= output8;
                          input8 <= data_regs(1)(15 downto 8) ;
                     elsif clk_counter = 28 then 
                           data_regs(1)(15 downto 8) <= output8;
                           input8 <= data_regs(1)(7 downto 0);    
                     elsif clk_counter = 32 then 
                          data_regs(1)(7 downto 0) <= output8;
                           input8 <= data_regs(2)(31 downto 24);
                     elsif clk_counter = 36 then 
                           data_regs(2)(31 downto 24) <= output8;
                           input8 <= data_regs(2)(23 downto 16);    
                     elsif clk_counter = 40 then 
                          data_regs(2)(23 downto 16) <= output8;
                          input8 <= data_regs(2)(15 downto 8) ;
                     elsif clk_counter = 44 then 
                           data_regs(2)(15 downto 8) <= output8;
                           input8 <= data_regs(2)(7 downto 0);    
                     elsif clk_counter = 48 then 
                          data_regs(2)(7 downto 0) <= output8;
                          input8 <= data_regs(3)(31 downto 24); 
                     elsif clk_counter = 52 then 
                           data_regs(3)(31 downto 24) <= output8;
                           input8 <= data_regs(3)(23 downto 16);    
                     elsif clk_counter = 56 then 
                          data_regs(3)(23 downto 16) <= output8;
                          input8 <= data_regs(3)(15 downto 8) ;
                     elsif clk_counter = 60 then 
                           data_regs(3)(15 downto 8) <= output8;
                           input8 <= data_regs(3)(7 downto 0);    
                     elsif clk_counter = 64 then 
                          data_regs(3)(7 downto 0) <= output8;
                     elsif clk_counter = 66 then 
                           next_state <= CHECK_ROUND;
                          a1 <= '0';
                          cur_round<=cur_round+1;
                     elsif clk_counter = 67 then
                          clk_counter := 0;        
                     end if ;
                    
                when CHECK_ROUND =>
                    if cur_round = 8 then
                        next_state <= FINAL_XOR;
                        cur_round<=9;
                    else
                        next_state <= ROUND_KEY_XOR;
                   
                    end if;
                    
                when FINAL_XOR =>
                     if a1 = '0' then 
                            a1 <= '1';
                            clk_counter := 0;
                        end if;
                        if clk_counter <= 80 then 
                            rema:=(clk_counter)mod 20;
                            quo:=(clk_counter-rema)/20;
                        end if;
                        if (clk_counter = 0) then
    --                        enable_rom1 <= '1';  -- Enable ROM for the first 32-bit read
                            addr_round_key <= std_logic_vector(to_unsigned(16*(9-cur_round),8));
    
                        elsif (rema=4) and clk_counter <= 80 then
                            round_regs(quo)(31 downto 24)<= rom1_data;
                            addr_round_key<= std_logic_vector(TO_UNSIGNED(16*(9-cur_round)+4*quo+1,8));
                            
                        elsif (rema = 8)and clk_counter <= 80 then
                            round_regs(quo)(23 downto 16)<= rom1_data; 
                            addr_round_key<= std_logic_vector(TO_UNSIGNED(16*(9-cur_round)+4*quo+2,8));
                        
                        elsif (rema = 12)and clk_counter <= 80 then
                            round_regs(quo)(15 downto 8)<= rom1_data;  -- Store the 2nd chunk in data_regs(1)
                            addr_round_key<= std_logic_vector(TO_UNSIGNED(16*(9-cur_round)+4*quo+3,8));
                            
                        elsif (rema = 16 or rema =18)and clk_counter <= 80 then
                            if rema =16 then 
                                round_regs(quo)(7 downto 0)<= rom1_data;
                              -- Store the 3rd chunk in data_regs(2)
                            elsif rema =18 then 
                                input1<= data_regs(quo);
                                input2<= round_regs(quo);
                            end if;
                        elsif (rema=19) and clk_counter <= 80 then 
                            data_regs(quo) <= output ;
                            if quo<3 then
                                addr_round_key<= std_logic_vector(TO_UNSIGNED(16*(9-cur_round)+4*quo+4,8));
                            end if;
                        end if;
                        
                        if (clk_counter = 80) then
                             clk_counter := 0;  
                              a1 <= '0';
                              rema := 0;
                              quo := 0;  
                              done_sig <= '1';
                              next_state <= IDLE; 
                         
--                        elsif  (clk_counter = 81) then 
                                                       -- Update round number from FSM output
                        end if;        -- Mark round as done after last chunk
                                  
              when others=>
                next_state <= IDLE;
                      
        end case;
        end if;
    end process;

    -- Output assignment
       done <= done_sig;
       plaintext_out<=data_regs(0)&data_regs(1)&data_regs(2)&data_regs(3);



end Behavioral;
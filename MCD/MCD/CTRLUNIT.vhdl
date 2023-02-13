library ieee;
use ieee.std_logic_1164.all;
 
entity CTRLUNIT is
  port (
        CLK, rst_n        : in std_logic;

        --input ext
        START             : in std_logic;

        --inputs from DP
        maj_AB            : in std_logic;
        maj_R             : in std_logic;
        READY_divider     : in std_logic;


        --output ext
        READY             : out std_logic;

        --outputs to DP
        selA, loadA       : out std_logic;
        selB              : out std_logic_vector(1 downto 0);
        loadB             : out std_logic;
        loadR             : out std_logic;
        START_divider     : out std_logic
       );
end CTRLUNIT;


architecture behav of CTRLUNIT is
  type statetype is (INIT, COMPARE, SWAP, DIV, RESULT, TEST);
  signal state, nextstate: statetype;

  begin
    --FSM Moore
    state <= INIT when rst_n='0' else nextstate when rising_edge(CLK);

    process (state, START, maj_AB, maj_R, READY_divider)
    begin
      -- delta: nextstate
      case state is
        when INIT      =>
                            if START = '1' then
                              nextstate <= COMPARE;
                            else
                              nextstate <= INIT;
                            end if;

        when COMPARE   =>
                            if maj_AB = '1' then --SE A > B HO maj_AB=1
                              nextstate <= DIV;
                            else
                              nextstate <= SWAP;
                            end if;


        when SWAP      =>   nextstate <= DIV;

        when DIV       =>   nextstate <= RESULT;

        when RESULT    =>
                            if  READY_divider = '1' then
                              nextstate <= TEST;
                            else
                              nextstate <= RESULT;
                            end if;


        when TEST      =>
                            if  maj_R = '1' then --SE R>0 HO maj_R=1
                              nextstate <= DIV;
                            else
                              nextstate <= INIT;
                            end if;

        when others    =>   nextstate <= INIT;
      end case;
    end process;


      --lambda: output
      READY           <= '1' when state = INIT       else '0';

      loadA           <= '1' when state = INIT       or
                                  state = SWAP       or
                                  state = TEST       else '0';

      loadB           <= '1' when state = INIT       or
                                  state = SWAP       or
                                  state = TEST       else '0';


      loadR           <= '1' when state = RESULT     else '0';

      selA            <= '1' when state = SWAP       or
                                  state = TEST       else '0';

      selB            <= "00" when state = INIT      else --B<=Y
                         "01" when state = SWAP      else --B<=A
                         "10" when state = TEST      else --B<=R
                         "11";                        --unused


      START_divider   <= '1' when state = DIV        else '0';



end behav;

library ieee;
use ieee.std_logic_1164.all;

entity CTRLUNIT_div is
  port (
        CLK, rst_n        : in std_logic;

        --input ext
        START_divider     : in std_logic;

        --inputs from DP
        eq_AB             : in std_logic;
        maj_AB            : in std_logic;
        eq_CNT            : in std_logic;
        maj_CNT           : in std_logic;
        eq_A              : in std_logic;

        --output ext
        READY_divider     : out std_logic;

        --outputs to DP
        selA, loadA       : out std_logic;
        selB              : out std_logic_vector(1 downto 0);
        loadB             : out std_logic;
        selCNT            : out std_logic_vector(1 downto 0);
        loadCNT           : out std_logic;
        selRES            : out std_logic_vector(1 downto 0);
        loadRES           : out std_logic;
        seladd            : out std_logic;
        selsub            : out std_logic
       );
end CTRLUNIT_div;


architecture behav of CTRLUNIT_div is
  type statetype is (S0, S1, S2, S3, S4, S5, S1_WAIT, S2_WAIT, S5_WAIT);
  signal state, nextstate: statetype;


  begin
    --FSM Moore
    state <= S0 when rst_n='0' else nextstate when rising_edge(CLK);

    process (state, START_divider, maj_AB, eq_A, eq_AB, eq_CNT, maj_CNT)
    begin
      -- delta: nextstate
      case state is
        when S0      =>
                            if START_divider = '1' then -- NOTA: ESEGUO IL TEST SU 1, PERCHE SE START_divider è U VOGLIO CHE RIMANGA IN S0
                              nextstate <= S1;
                            else
                              nextstate <= S0;
                            end if;

        when S1  =>         nextstate <= S1_WAIT;

        when S1_WAIT      =>
                            if  maj_AB = '0' then
                              nextstate <= S3;
                            else
                              nextstate <= S2;
                            end if;

        when S2  =>         nextstate <= S2_WAIT;

        when S2_WAIT    =>
                            if  maj_AB = '0' then
                              nextstate <= S3;
                            else
                              nextstate <= S2;
                            end if;

        when S3    =>       if eq_A = '0' and (maj_AB = '1' or eq_AB = '1') then --if not (eq_A) and (maj_AB or eq_AB) then
                              nextstate <= S4;
                            else
                              nextstate <= S5;
                            end if;

        when S4  =>         nextstate <= S5;

        when S5  =>         nextstate <= S5_WAIT;


        when S5_WAIT    =>
                            if  (eq_CNT = '1' or maj_CNT = '1') then
                              nextstate <= S3;
                            else
                              nextstate <= S0;
                            end if;

        when others     =>  nextstate <= S0;
      end case;
    end process;


      --lambda: output
      READY_divider <= '1' when state = S0      else '0';

      loadA        <= '1' when state = S1       or
                               state = S4       else '0';

      loadB        <= '1' when state = S1       or
                               state = S2       or
                               state = S5       else '0';

      loadCNT      <= '1' when state = S1       or
                               state = S2       or
                               state = S5       else '0';

      loadRES      <= '1' when state = S1       or
                               state = S3       or
                               state = S4       else '0';


      selA         <= '1' when state = S4       else '0';

      selB         <= "00" when state = S1      else --B<=OP2_divider
                      "01" when state = S2      else --B<<1
                      "10" when state = S5      else --B>>1
                      "11";                        --unused

      selCNT       <= "00" when state = S2      else --CNT++
                      "01" when state = S1      else --CNT<=0
                      "10" when state = S5      else --CNT--
                      "11";

      selRES       <= "00" when state = S3      else --RES<<1
                      "01" when state = S1      else --RES<=0
                      "10" when state = S4      else --RES++
                      "11";                        --unused

      seladd       <= '1' when state = S2       else '0';

      selsub       <= '1' when state = S5       else '0';



end behav;

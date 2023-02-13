library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;

--testbench
entity TES is
end TES;


architecture behav of TES is

  --tck = 0.04*10^-6 s = 40 ns
  constant CLK_SEMIPERIOD0: time := 5 ns;
  constant CLK_SEMIPERIOD1: time := 5 ns;
  constant CLK_PERIOD: time := CLK_SEMIPERIOD0 + CLK_SEMIPERIOD1;--10ns
  constant RESET_TIME: time := 3*CLK_PERIOD + 9 ns;

  constant LEN : integer := 32;


  signal CLK, rst_n : std_logic;
  signal OP1_divider          : std_logic_vector(LEN-1 downto 0);
  signal OP2_divider          : std_logic_vector(LEN-1 downto 0);
  signal START_divider        : std_logic;
  signal READY_divider        : std_logic;
  signal RESULT_divider       : std_logic_vector(LEN-1 downto 0);
  signal REMAINDER_divider    : std_logic_vector(LEN-1 downto 0);

  --signals per inout
  signal start : integer := 0;
  signal done : integer := 0;
  signal int_count_clk : integer := 0; -- contatore dei cicli di clock
  signal int_counter_data : integer := 0;




  component DIVIDER is
    generic(LEN : integer);
    port (
          CLK, rst_n           : in std_logic;

          --device input
          OP1_divider          : in std_logic_vector(LEN-1 downto 0);
          OP2_divider          : in std_logic_vector(LEN-1 downto 0);
          START_divider        : in std_logic;

          --device output
          READY_divider        : out std_logic;
          RESULT_divider       : out std_logic_vector(LEN-1 downto 0);
          REMAINDER_divider    : out std_logic_vector(LEN-1 downto 0)
         );
  end component;


  begin
    DUT : DIVIDER generic map (LEN => LEN)
                  port map  (CLK => CLK,
                             rst_n => rst_n,
                             OP1_divider => OP1_divider,
                             OP2_divider => OP2_divider,
                             START_divider  => START_divider,
                             READY_divider  => READY_divider,
                             RESULT_divider    => RESULT_divider,
                             REMAINDER_divider => REMAINDER_divider
                            );

    --reset di tutti i registri
    start_process: process
    begin
      rst_n <= '1';
      wait for CLK_PERIOD;
      rst_n <= '0';
      wait for RESET_TIME;
      rst_n <= '1';
      start <= 1;
      wait;
    end process start_process;


    clk_process: process
    begin
      if CLK = '0' then
        CLK <= '1';
        wait for CLK_SEMIPERIOD1;
      else
        CLK <= '0';
        wait for CLK_SEMIPERIOD0;
        int_count_clk <= int_count_clk+1;
      end if;
    end process clk_process;


    read_file_process: process(CLK)
      file infile : TEXT open READ_MODE is "C:\Users\rikma\Desktop\MCD\DIVIDER\data_div.txt";
      variable inputline : LINE;
      variable in_OP1 : integer;
      variable in_OP2 : integer;
      variable result : integer;
      variable remainder : integer;
      variable outputline: LINE;

    begin
      if (CLK = '0') and (start = 1) then
        if (READY_divider = '1') then

          if int_counter_data > 0 and ((not(to_integer(unsigned(RESULT_divider)) = result)) or (not(to_integer(unsigned(REMAINDER_divider)) = remainder))) then
            write(outputline, string'("------------------------------> Error in DIVIDER("));
            write(outputline, in_OP1);
            write(outputline, string'(","));
            write(outputline, in_OP2);
            write(outputline, string'(")="));
            write(outputline, to_integer(unsigned(RESULT_divider)));
            write(outputline, string'(" rem "));
            write(outputline, to_integer(unsigned(REMAINDER_divider)));

            write(outputline, string'(", expecting "));
            write(outputline, result);
            write(outputline, string'(" rem "));
            write(outputline, remainder);

            write(outputline, string'(".  Data counter is "));
            write(outputline, int_counter_data);
            write(outputline, string'(" <------------------------------"));

            writeline(output, outputline);
            assert false;
              report "ERROR"
              severity failure;
          end if;

          if not endfile(infile) then
            readline(infile, inputline);
            read(inputline, in_OP1);
            read(inputline, in_OP2);
            read(inputline, result);
            read(inputline, remainder);

            OP1_divider <= std_logic_vector(to_unsigned(in_OP1, OP1_divider'length));
            OP2_divider <= std_logic_vector(to_unsigned(in_OP2, OP2_divider'length));
            int_counter_data <= int_counter_data + 1;
            START_divider <= '1';
          else
            done <= 1;
          end if;
        else
          START_divider <= '0';
        end if;

      end if;
    end process read_file_process;



    done_process: process(done)
      variable outputline: LINE;
    begin
      if (done = 1) then
        write(outputline, string'("End simulation - "));
        write(outputline, string'("Cycle counter is "));
        write(outputline, int_count_clk);
        writeline(output, outputline);
        assert false;
          report "ALL OK, END OF SIMULATION"
          severity failure;
        end if;
    end process done_process;

end behav;

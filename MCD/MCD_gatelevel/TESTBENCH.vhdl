library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;

--testbench
entity TESTBENCH is
end TESTBENCH;


architecture behav of TESTBENCH is

  --tck = 0.04*10^-6 s = 40 ns
  constant CLK_SEMIPERIOD0: time := 5 ns;
  constant CLK_SEMIPERIOD1: time := 5 ns;
  constant CLK_PERIOD: time := CLK_SEMIPERIOD0 + CLK_SEMIPERIOD1;--10ns
  constant RESET_TIME: time := 200 ns;

  --constant LEN : integer := 32;

  signal CLK, rst_n : std_logic;
  signal X          : std_logic_vector(31 downto 0);
  signal Y          : std_logic_vector(31 downto 0);
  signal START        : std_logic;
  signal READY        : std_logic;
  signal MCD_out       : std_logic_vector(31 downto 0);

  --signals per inout
  signal t_start : integer := 0;
  signal t_done : integer := 0;
  signal int_count_clk : integer := 0; -- contatore dei cicli di clock
  signal int_counter_data : integer := 0;
  signal wait_reading : integer := 0; -- segnale per permettere la lettura su due cicli


  component MCD is
    port (
          CLK, rst_n           : in std_logic;

          --device input
          X                    : in std_logic_vector(31 downto 0);
          Y                    : in std_logic_vector(31 downto 0);
          START                : in std_logic;

          --device output
          READY                : out std_logic;
          MCD_out              : out std_logic_vector(31 downto 0)
        );
  end component;


  begin
    DUT : MCD
              port map  (CLK     => CLK,
                         rst_n   => rst_n,
                         X       => X,
                         Y       => Y,
                         START   => START,

                         --device output
                         READY   => READY,
                         MCD_out => MCD_out
                        );

    --reset di tutti i registri
    start_process: process
    begin
      rst_n <= '1';
      wait for CLK_PERIOD;
      rst_n <= '0';
      wait for RESET_TIME;
      rst_n <= '1';
      t_start <= 1;
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
      file infile : TEXT open READ_MODE is "C:\Users\rikma\Desktop\MCD_gatelevel\data.txt";
      variable inputline : LINE;
      variable in_X : integer;
      variable in_Y : integer;
      variable result : integer;
      variable outputline: LINE;


    begin
      if (CLK = '0') and (t_start = 1) then

        if (READY = '1') and (wait_reading = 0) then
          wait_reading <= 1;

          if (int_counter_data > 0) and (not(to_integer(unsigned(MCD_out)) = result)) then
            write(outputline, string'("-----------------------------------> Error in MCD("));
            write(outputline, in_X);
            write(outputline, string'(","));
            write(outputline, in_Y);
            write(outputline, string'(")="));
            write(outputline, to_integer(unsigned(MCD_out)));
            write(outputline, string'(", expecting "));
            write(outputline, result);

            write(outputline, string'(".  Data counter is "));
            write(outputline, int_counter_data);
            write(outputline, string'(" <-----------------------------------"));

            writeline(output, outputline);
            assert false;
              report "ERROR"
              severity failure;
          end if;


          if not endfile(infile) then
            readline(infile, inputline);
            read(inputline, in_X);
            read(inputline, in_Y);
            read(inputline, result);

            X <= std_logic_vector(to_unsigned(in_X, X'length));
            Y <= std_logic_vector(to_unsigned(in_Y, Y'length));
            int_counter_data <= int_counter_data + 1;
            START <= '1';
          else
            t_done <= 1;
          end if;

        else
          wait_reading <= 0;
          START <= '0';
        end if;

      end if;
    end process read_file_process;





    done_process: process(t_done)
      variable outputline: LINE;
    begin
      if (t_done = 1) then
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

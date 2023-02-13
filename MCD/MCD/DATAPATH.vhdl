library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DATAPATH is
  generic (LEN : integer);
  port (
        CLK, rst_n        : in std_logic;

        --input ext
        X                 : in std_logic_vector(LEN-1 downto 0);
        Y                 : in std_logic_vector(LEN-1 downto 0);

        --inputs from CU = control signals
        selA, loadA       : in std_logic;
        selB              : in std_logic_vector(1 downto 0);
        loadB             : in std_logic;
        loadR             : in std_logic;
        START_divider     : in std_logic;

        --outputs to CU = status signals
        maj_AB            : out std_logic;
        maj_R             : out std_logic;
        READY_divider     : out std_logic;


        --output ext
        MCD_out           : out std_logic_vector(LEN-1 downto 0)
       );
end DATAPATH;


architecture s of DATAPATH is

component DIVIDER is
  generic (LEN : integer);
  port(
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


  signal A_in, A : std_logic_vector(LEN-1 downto 0);
  signal B_in, B : std_logic_vector(LEN-1 downto 0);
  signal R_in, R : std_logic_vector(LEN-1 downto 0);
  signal CNT_in, CNT : std_logic_vector(LEN-1 downto 0);
  signal RES_in, RES : std_logic_vector(LEN-1 downto 0);
  signal t_REMAINDER_divider : std_logic_vector(LEN-1 downto 0);
  signal t_RESULT_divider : std_logic_vector(LEN-1 downto 0); --non serve

  signal allzeros : std_logic_vector(LEN-1 downto 0) := (others => '0');

begin

  --divider
  DIV: DIVIDER generic map (LEN => LEN)
               port map(CLK               => CLK,
                        rst_n             => rst_n,
                        --device input
                        OP1_divider       => A,
                        OP2_divider       => B,
                        START_divider     => START_divider,

                        --device output
                        READY_divider     => READY_divider,
                        RESULT_divider    => t_RESULT_divider,
                        REMAINDER_divider => t_REMAINDER_divider
                       );

  --registers
  A     <= (others => '0') when rst_n = '0' else
        A_in when rising_edge(CLK) and loadA = '1';
  B     <= (others => '0') when rst_n = '0' else
        B_in when rising_edge(CLK) and loadB = '1';
  R     <= (others => '0') when rst_n = '0' else
        t_REMAINDER_divider when rising_edge(CLK) and loadR = '1';


  --muxs
  with selA select
    A_in <= X when '0',
            B when others;

  with selB select
    B_in <= Y when "00",
            A when "01",
            R when others;


  --comparators, status signals
  maj_AB <= '1' when A > B else '0';
  maj_R  <= '1' when R > allzeros else '0';


  --output ext
  MCD_out <= A;

end s;

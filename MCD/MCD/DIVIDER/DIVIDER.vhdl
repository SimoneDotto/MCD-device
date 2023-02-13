library ieee;
use ieee.std_logic_1164.all;

--top level
entity DIVIDER is
  generic(LEN : integer := 32);
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
end DIVIDER;


architecture struct of DIVIDER is

  component CTRLUNIT_div is
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
  end component;

  component DATAPATH_div is
    generic(LEN : integer);
    port (
          CLK, rst_n        : in std_logic;

          --input ext
          OP1_divider     : in std_logic_vector(LEN-1 downto 0);
          OP2_divider     : in std_logic_vector(LEN-1 downto 0);

          --inputs from CU = control signals
          selA, loadA       : in std_logic;
          selB              : in std_logic_vector(1 downto 0);
          loadB             : in std_logic;
          selCNT            : in std_logic_vector(1 downto 0);
          loadCNT           : in std_logic;
          selRES            : in std_logic_vector(1 downto 0);
          loadRES           : in std_logic;
          seladd            : in std_logic;
          selsub            : in std_logic;

          --outputs to CU = status signals
          eq_AB             : out std_logic;
          maj_AB            : out std_logic;
          eq_CNT            : out std_logic;
          maj_CNT           : out std_logic;
          eq_A              : out std_logic;


          --output ext
          RESULT_divider       : out std_logic_vector(LEN-1 downto 0);
          REMAINDER_divider    : out std_logic_vector(LEN-1 downto 0)
         );
  end component;


  signal t_maj_AB, t_eq_A, t_eq_AB, t_eq_CNT, t_maj_CNT : std_logic;
  signal t_selA, t_loadA, t_loadB, t_loadCNT, t_seladd, t_loadRES, t_selsub : std_logic;
  signal t_selB, t_selRES, t_selCNT : std_logic_vector(1 downto 0);


  begin
    CU: CTRLUNIT_div port map  (CLK            => CLK,
                                rst_n          => rst_n,
                                START_divider  => START_divider,

                                --inputs from DP
                                maj_AB         => t_maj_AB,
                                eq_CNT         => t_eq_CNT,
                                maj_CNT        => t_maj_CNT,
                                eq_AB          => t_eq_AB,
                                eq_A           => t_eq_A,

                                --output ext
                                READY_divider  => READY_divider,

                                --outputs to DP
                                selA    => t_selA,
                                loadA   => t_loadA,
                                selB    => t_selB,
                                loadB   => t_loadB,
                                selCNT  => t_selCNT,
                                loadCNT => t_loadCNT,
                                selRES  => t_selRES,
                                loadRES => t_loadRES,
                                seladd  => t_seladd,
                                selsub  => t_selsub
                               );




    DP: DATAPATH_div generic map (LEN => LEN)
                     port map (CLK            => CLK,
                               rst_n          => rst_n,
                               OP1_divider => OP1_divider,
                               OP2_divider => OP2_divider,

                               --inputs from CU = control signals
                               selA    => t_selA,
                               loadA   => t_loadA,
                               selB    => t_selB,
                               loadB   => t_loadB,
                               selCNT  => t_selCNT,
                               loadCNT => t_loadCNT,
                               selRES  => t_selRES,
                               loadRES => t_loadRES,
                               seladd  => t_seladd,
                               selsub  => t_selsub,

                               --outputs to CU = status signals
                               maj_AB         => t_maj_AB,
                               eq_CNT         => t_eq_CNT,
                               maj_CNT        => t_maj_CNT,
                               eq_AB          => t_eq_AB,
                               eq_A           => t_eq_A,

                               --output ext
                               RESULT_divider    => RESULT_divider,
                               REMAINDER_divider => REMAINDER_divider
                              );


end struct;

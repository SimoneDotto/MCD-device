library ieee;
use ieee.std_logic_1164.all;

--top level
entity MCD is
  generic (LEN : integer := 32);
  port (
    CLK, rst_n           : in std_logic;

    --device input
    X                    : in std_logic_vector(LEN-1 downto 0);
    Y                    : in std_logic_vector(LEN-1 downto 0);
    START                : in std_logic;

    --device output
    READY                : out std_logic;
    MCD_out              : out std_logic_vector(LEN-1 downto 0)
  );
end MCD;


architecture struct of MCD is

  component CTRLUNIT is
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
  end component;

  component DATAPATH is
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
          MCD_out           : out std_logic_vector(31 downto 0)
         );
  end component;


  signal t_maj_AB, t_maj_R, t_READY_divider : std_logic;
  signal t_selA, t_loadA, t_loadB, t_loadR : std_logic;
  signal t_selB : std_logic_vector(1 downto 0);
  signal t_START_divider : std_logic;


  begin
    CU: CTRLUNIT port map  (CLK           => CLK,
                            rst_n         => rst_n,

                            --input ext
                            START         => START,

                            --inputs from DP
                            maj_AB        => t_maj_AB,
                            maj_R         => t_maj_R,
                            READY_divider => t_READY_divider,


                            --output ext
                            READY         => READY,

                            --outputs to DP
                            selA          => t_selA,
                            loadA         => t_loadA,
                            selB          => t_selB,
                            loadB         => t_loadB,
                            loadR         => t_loadR,
                            START_divider => t_START_divider
                          );




    DP: DATAPATH generic map (LEN => LEN)
                 port map (CLK           => CLK,
                           rst_n         => rst_n,
                           --input ext
                           X             => X,
                           Y             => Y,

                           --inputs from CU = control signals
                           selA          => t_selA,
                           loadA         => t_loadA,
                           selB          => t_selB,
                           loadB         => t_loadB,
                           loadR         => t_loadR,
                           START_divider => t_START_divider,

                           --outputs to CU = status signals
                           maj_AB        => t_maj_AB,
                           maj_R         => t_maj_R,
                           READY_divider => t_READY_divider,


                           --output ext
                           MCD_out       => MCD_out
                          );


end struct;

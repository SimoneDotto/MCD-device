library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DATAPATH_div is
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
end DATAPATH_div;


architecture s of DATAPATH_div is
  --constant S: integer := 32;

  signal A_in, A : std_logic_vector(2*LEN-1 downto 0);
  signal B_in, B : std_logic_vector(2*LEN-1 downto 0);
  signal CNT_in, CNT : std_logic_vector(2*LEN-1 downto 0);
  signal RES_in, RES : std_logic_vector(2*LEN-1 downto 0);

  signal adder_in1, adder_in2, adder_out : std_logic_vector(2*LEN-1 downto 0);
  signal subtractor_in1, subtractor_in2, subtractor_out : std_logic_vector(2*LEN-1 downto 0);


  signal in_OP1, in_OP2 : std_logic_vector(2*LEN-1 downto 0);

  signal allzeros : std_logic_vector(2*LEN-1 downto 0) := (others => '0');

begin

  in_OP1(2*LEN-1 downto LEN) <= (others=>'0');
  in_OP1(LEN-1 downto 0) <= OP1_divider;

  in_OP2(2*LEN-1 downto LEN) <= (others=>'0');
  in_OP2(LEN-1 downto 0) <= OP2_divider;

  adder_in1 <= (2*LEN-1 downto 1 => '0')&'1'; --(0 => '1', others => '0'); --000..1, con la concatenazione evito i warnings


  --registers
  A     <= (others => '0') when rst_n = '0' else
        A_in when rising_edge(CLK) and loadA = '1';
  B     <= (others => '0') when rst_n = '0' else
        B_in when rising_edge(CLK) and loadB = '1';
  CNT   <= (others => '0') when rst_n = '0' else
        CNT_in when rising_edge(CLK) and loadCNT = '1';
  RES   <= (others => '0') when rst_n = '0' else
        RES_in when rising_edge(CLK) and loadRES = '1';


  --muxs
  with selA select
    A_in <= in_OP1 when '0',
            subtractor_out when others;

  with selB select
    B_in <= in_OP2                     when "00",
            B(B'left-1 downto 0) & '0' when "01",   --sx --non abbiamo implementato lo shifter a parte perchè lo shift è costante(è giusta la spiegazione?)
            '0' & B(B'left downto 1)   when others; --dx

  with selCNT select
    CNT_in <= adder_out      when "00", -- CNT++
              (others => '0') when "01", --CNT<=0
              subtractor_out when others; -- CNT--

  with selRES select
    RES_in <= RES(RES'left-1 downto 0) & '0' when "00",
              (others => '0') when "01", --RES<=0
              adder_out when others;-- RES++

  with seladd select
    adder_in2 <=  RES when '0',
                  CNT when others;

  process(selsub, A, B, CNT) -- per i 2 mux del sottrattore usiamo un case per implementarli insieme dato che la selezione è la stessa
  begin
    case selsub is
      when '0'    => subtractor_in1 <= A; -- A-B
                     subtractor_in2 <= B;
      when others => subtractor_in1 <= CNT; -- CNT-1
                     subtractor_in2 <= (2*LEN-1 downto 1 => '0')&'1';
    end case;
  end process;



  --adder
  adder_out <= std_logic_vector(unsigned(adder_in1) + unsigned(adder_in2)); --adder_in1=1 sempre, potevamo anche scriverlo diretto


  --subtractor
  subtractor_out <= std_logic_vector(unsigned(subtractor_in1) - unsigned(subtractor_in2)); --uso unsigned erche non ho mai risultati negativi


  --comparators, status signals
  maj_CNT <= '1' when signed(CNT) > signed(allzeros) else '0';
  maj_AB  <= '1' when A > B else '0';
  eq_A    <= '1' when unsigned(A) = 0 else '0';
  eq_AB   <= '1' when unsigned(A) = unsigned(B) else '0';
  eq_CNT  <= '1' when unsigned(CNT) = 0 else '0';


  --output ext
  REMAINDER_divider <= A(LEN-1 downto 0);
  RESULT_divider    <= RES(LEN-1 downto 0);

end s;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.util_pkg.all;

entity cmodA7_top is
  port (
    gclk  : in  std_logic;
    reset : in  std_logic;
    led0  : out std_logic;
    led1  : out std_logic
  );
end entity cmodA7_top;

architecture rtl of cmodA7_top is

  constant K_MAX_COUNT : integer := 12501; -- max counter value supported


  signal sig_cnt_val0  : std_logic_vector(F_clog2(K_MAX_COUNT) - 1 downto 0);
  signal sig_cnt_val1  : std_logic_vector(F_clog2(K_MAX_COUNT) - 1 downto 0);

begin

  sig_cnt_val0 <= std_logic_vector( to_unsigned( 12500, sig_cnt_val0'length ) );
  sig_cnt_val1 <= std_logic_vector( to_unsigned( 12487, sig_cnt_val1'length ) );

  led1 <= reset;

  U_DUT: entity work.fading_pwm_strobe
    generic map (
      G_MAX_COUNT => K_MAX_COUNT,
      G_FREQ_DIV  => 4
    )
    port map (
      clk         => gclk,
      reset       => reset,
      cnt_val0    => sig_cnt_val0,
      cnt_val1    => sig_cnt_val1,
      cnt_val_vld => '1',
      pwm_out     => led0
    );

end rtl;


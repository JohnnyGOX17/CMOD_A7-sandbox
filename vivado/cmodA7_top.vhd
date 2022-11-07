library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library unisim;
  use unisim.vcomponents.all;
library work;
  use work.util_pkg.all;

entity cmodA7_top is
  generic (
    G_BAUD_RATE   : positive              := 9600;      -- UART Baud rate
    G_CHAR_WIDTH  : positive range 5 to 8 := 8;         -- character data width
    G_PARITY      : string                := "NONE";    -- "NONE", "ODD", or "EVEN" parity
    G_DBL_STOP    : boolean               := false;     -- when true use two stop bits, else one stop bit
    G_DEBUG       : string                := "true"     -- feeds synth attributes
  );
  port (
    gclk          : in  std_logic; -- 12 MHz input
    reset         : in  std_logic; -- reset from button
    uart_rx       : in  std_logic;
    uart_tx       : out std_logic;
    led0          : out std_logic;
    led1          : out std_logic
  );
end entity cmodA7_top;

architecture rtl of cmodA7_top is

  constant K_MAX_COUNT : integer := 1501; -- max counter value supported

  signal gclk_bufg     : std_logic;

  signal sig_cnt_val0  : std_logic_vector(F_clog2(K_MAX_COUNT) - 1 downto 0);
  signal sig_cnt_val1  : std_logic_vector(F_clog2(K_MAX_COUNT) - 1 downto 0);
  signal sys_reset     : std_logic;
  signal sys_reset_n   : std_logic;

  signal sig_axis_tdata  : std_logic_vector(G_CHAR_WIDTH - 1 downto 0);
  signal sig_axis_tvalid : std_logic;
  signal sig_axis_tready : std_logic;

  attribute mark_debug : string;
  attribute mark_debug of sig_axis_tdata  : signal is G_DEBUG;
  attribute mark_debug of sig_axis_tvalid : signal is G_DEBUG;
  attribute mark_debug of sig_axis_tready : signal is G_DEBUG;

begin

  -- Given a 12 MHz (~83.3ns period) clock, and a /4 internal clock (3MHz eff.)
  -- a target 2 kHz PWM frequency (fast enough for no LED flicker for example,
  -- but more than slow enough for most LED driver circuits) can be achieved
  -- by a counter which rolls over after (3M/2k) = 1500 cycles.
  -- To have a fairly slow beat frequency (e.g. 1Hz), which is found by the
  -- difference of two counter frequencies (f1 - f2)/2, we can find the counter
  -- value of 3M/2002 ~= 1499 to be the second counter term value.
  sig_cnt_val0 <= std_logic_vector( to_unsigned(1500, sig_cnt_val0'length) );
  sig_cnt_val1 <= std_logic_vector( to_unsigned(1499, sig_cnt_val1'length) );

  led1 <= sys_reset;
  sys_reset_n <= not sys_reset;

  U_clk_input_buffer: BUFG
    port map (
      I => gclk,
      O => gclk_bufg
    );

  U_reg_reset: entity work.synchronizer_reg
    generic map (
      G_NUM_REG => 3
    )
    port map (
      clk       => gclk_bufg,
      din       => reset,
      dout      => sys_reset
    );

  U_DUT: entity work.fading_pwm_strobe
    generic map (
      G_MAX_COUNT => K_MAX_COUNT,
      G_FREQ_DIV  => 4
    )
    port map (
      clk         => gclk_bufg,
      reset       => sys_reset,
      cnt_val0    => sig_cnt_val0,
      cnt_val1    => sig_cnt_val1,
      cnt_val_vld => '1',
      pwm_out     => led0
    );

  U_UART: entity work.UART_top
    generic map (
      G_ACLK_FREQ   => 12000000,
      G_BAUD_RATE   => G_BAUD_RATE,
      G_CHAR_WIDTH  => G_CHAR_WIDTH,
      G_PARITY      => G_PARITY,
      G_DBL_STOP    => G_DBL_STOP
    )
    port map (
      aclk          => gclk_bufg,
      aresetn       => sys_reset_n,

      -- character input
      s_axis_tdata  => sig_axis_tdata,
      s_axis_tvalid => sig_axis_tvalid,
      s_axis_tready => sig_axis_tready,
      -- character output
      m_axis_tdata  => sig_axis_tdata,
      m_axis_tvalid => sig_axis_tvalid,
      m_axis_tready => sig_axis_tready,

      parity_error  => open,
      uart_rx       => uart_rx,
      uart_tx       => uart_tx
    );

end rtl;


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.util_pkg.all;

entity cmodA7_top is
  generic (
    G_BAUD_RATE   : positive              := 9600;      -- UART Baud rate
    G_CHAR_WIDTH  : positive range 5 to 8 := 8;         -- character data width
    G_PARITY      : string                := "NONE";    -- "NONE", "ODD", or "EVEN" parity
    G_DBL_STOP    : boolean               := false      -- when true use two stop bits, else one stop bit
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

  constant K_MAX_COUNT : integer := 12501; -- max counter value supported


  signal sig_cnt_val0  : std_logic_vector(F_clog2(K_MAX_COUNT) - 1 downto 0);
  signal sig_cnt_val1  : std_logic_vector(F_clog2(K_MAX_COUNT) - 1 downto 0);
  signal sys_reset     : std_logic;
  signal sys_reset_n   : std_logic;

  signal sig_tx_axis_tdata  : std_logic_vector(G_CHAR_WIDTH - 1 downto 0);
  signal sig_tx_axis_tvalid : std_logic;
  signal sig_tx_axis_tready : std_logic;
  signal sig_rx_axis_tdata  : std_logic_vector(G_CHAR_WIDTH - 1 downto 0);
  signal sig_rx_axis_tvalid : std_logic;
  signal sig_rx_axis_tready : std_logic;

begin

  sig_cnt_val0 <= std_logic_vector( to_unsigned( 12500, sig_cnt_val0'length ) );
  sig_cnt_val1 <= std_logic_vector( to_unsigned( 12487, sig_cnt_val1'length ) );

  led1 <= sys_reset;
  sys_reset_n <= not sys_reset;

  U_reg_reset: entity work.synchronizer_reg
    generic map (
      G_NUM_REG => 3
    )
    port map (
      clk       => gclk,
      din       => reset,
      dout      => sys_reset
    );

  U_DUT: entity work.fading_pwm_strobe
    generic map (
      G_MAX_COUNT => K_MAX_COUNT,
      G_FREQ_DIV  => 4
    )
    port map (
      clk         => gclk,
      reset       => sys_reset,
      cnt_val0    => sig_cnt_val0,
      cnt_val1    => sig_cnt_val1,
      cnt_val_vld => '1',
      pwm_out     => led0
    );

  U_FIFO: entity work.axis_data_fifo_0
    port map (
      s_axis_aresetn => sys_reset_n,
      s_axis_aclk    => gclk,
      s_axis_tvalid  => sig_rx_axis_tvalid,
      s_axis_tready  => sig_rx_axis_tready,
      s_axis_tdata   => sig_rx_axis_tdata,
      m_axis_tvalid  => sig_tx_axis_tvalid,
      m_axis_tready  => sig_tx_axis_tready,
      m_axis_tdata   => sig_tx_axis_tdata
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
      aclk          => gclk,
      aresetn       => sys_reset_n,

      -- character input
      s_axis_tdata  => sig_tx_axis_tdata,
      s_axis_tvalid => sig_tx_axis_tvalid,
      s_axis_tready => sig_tx_axis_tready,
      -- character output
      m_axis_tdata  => sig_rx_axis_tdata,
      m_axis_tvalid => sig_rx_axis_tvalid,
      m_axis_tready => sig_rx_axis_tready,

      parity_error  => open,
      uart_rx       => uart_rx,
      uart_tx       => uart_tx
    );

end rtl;


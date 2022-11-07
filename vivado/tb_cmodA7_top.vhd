library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library unisim;
  use unisim.vcomponents.all;
library work;
  use work.util_pkg.all;

entity tb_cmodA7_top is
  generic (
    G_BAUD_RATE   : positive              := 9600;      -- UART Baud rate
    G_CHAR_WIDTH  : positive range 5 to 8 := 8;         -- character data width
    G_PARITY      : string                := "NONE";    -- "NONE", "ODD", or "EVEN" parity
    G_DBL_STOP    : boolean               := false      -- when true use two stop bits, else one stop bit
  );
end entity tb_cmodA7_top;

architecture behav of tb_cmodA7_top is

  signal gclk    : std_logic := '0'; -- 12 MHz input
  signal reset   : std_logic; -- reset from button
  signal uart_rx : std_logic;
  signal uart_tx : std_logic;
  signal led0    : std_logic;
  signal led1    : std_logic;

  signal s_axis_tdata  : std_logic_vector(G_CHAR_WIDTH - 1 downto 0);
  signal s_axis_tvalid : std_logic;
  signal s_axis_tready : std_logic;
  signal m_axis_tdata  : std_logic_vector(G_CHAR_WIDTH - 1 downto 0);
  signal m_axis_tvalid : std_logic;
  signal m_axis_tready : std_logic;

begin

  gclk  <= not gclk after 41.66 ns;
  reset <= '1', '0' after 250 ns;

  U_DUT: entity work.cmodA7_top
    generic map (
      G_BAUD_RATE   => G_BAUD_RATE,
      G_CHAR_WIDTH  => G_CHAR_WIDTH,
      G_PARITY      => G_PARITY,
      G_DBL_STOP    => G_DBL_STOP,
      G_DEBUG       => "false" -- feeds synth attributes
    )
    port map (
      gclk          => gclk,  -- 12 MHz input
      reset         => reset, -- reset from button
      uart_rx       => uart_tx,
      uart_tx       => uart_rx,
      led0          => led0,
      led1          => led1
    );

  U_UART_driver: entity work.UART_top
    generic map (
      G_ACLK_FREQ   => 12000000,
      G_BAUD_RATE   => G_BAUD_RATE,
      G_CHAR_WIDTH  => G_CHAR_WIDTH,
      G_PARITY      => G_PARITY,
      G_DBL_STOP    => G_DBL_STOP
    )
    port map (
      aclk          => gclk,
      aresetn       => not reset,

      -- character input
      s_axis_tdata  => s_axis_tdata,
      s_axis_tvalid => s_axis_tvalid,
      s_axis_tready => s_axis_tready,
      -- character output
      m_axis_tdata  => m_axis_tdata,
      m_axis_tvalid => m_axis_tvalid,
      m_axis_tready => m_axis_tready,

      parity_error  => open,
      uart_rx       => uart_rx,
      uart_tx       => uart_tx
    );

  CS_test_UART_loopback: process
  begin
    s_axis_tdata  <= (others => '0');
    s_axis_tvalid <= '0';
    m_axis_tready <= '1';

    wait until reset = '0';
    wait until rising_edge(gclk);

    s_axis_tdata  <= F_char_to_byte('I');
    s_axis_tvalid <= '1';
    wait until rising_edge(gclk) and s_axis_tready = '1';
    s_axis_tvalid <= '0';

    wait;
  end process CS_test_UART_loopback;

end behav;



-- test bench

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY LArPixDAQ_tb IS
END ENTITY LArPixDAQ_tb;

ARCHITECTURE LArPixDAQ_tb_arch OF LArPixDAQ_tb IS

   COMPONENT LArPixDAQ
      PORT (
         GCLK    : IN  STD_LOGIC;
         -- RS232
         RXD     : IN  STD_LOGIC;
         TXD     : OUT STD_LOGIC;
         -- LArPix
         MCLK    : OUT STD_LOGIC;       -- master clock
         MOSI    : OUT STD_LOGIC;
         MISO    : IN  STD_LOGIC;
         RST_N   : OUT STD_LOGIC;
         -- buttons
         BTN0    : IN  STD_LOGIC;
         BTN1    : IN  STD_LOGIC;
         -- utility
         PULSE_OUT : OUT STD_LOGIC;
         -- LEDs
         LED_RGB : OUT STD_LOGIC_VECTOR (2 DOWNTO 0);
         LEDs    : OUT STD_LOGIC_VECTOR (1 DOWNTO 0)
         );
   END COMPONENT LArPixDAQ;

   COMPONENT uart_rx
      GENERIC (
         CLK_Hz     : INTEGER;
         CLKIN_Hz   : INTEGER;
         DATA_WIDTH : INTEGER := 8
         );
      PORT (
         CLK         : IN  STD_LOGIC;
         RST         : IN  STD_LOGIC;
         CLKIN_RATIO : IN INTEGER;
         -- UART RX
         RX          : IN  STD_LOGIC;
         -- received data
         data        : OUT STD_LOGIC_VECTOR (DATA_WIDTH-1 DOWNTO 0);
         data_update : OUT STD_LOGIC;
         -- test signals
         TC          : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
         );
   END COMPONENT uart_rx;

   COMPONENT uart_tx
      GENERIC (
         CLK_Hz     : INTEGER;
         CLKOUT_Hz  : INTEGER;
         DATA_WIDTH : INTEGER := 8
         );
      PORT (
         CLK         : IN  STD_LOGIC;
         RST         : IN  STD_LOGIC;
         CLKOUT_RATIO : IN INTEGER;
         -- UART RX
         TX          : OUT STD_LOGIC;
         CLKout      : OUT STD_LOGIC;
         -- received data
         data        : IN  STD_LOGIC_VECTOR (DATA_WIDTH-1 DOWNTO 0);
         data_update : IN  STD_LOGIC;
         busy        : OUT STD_LOGIC;
         -- test signals
         TC          : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
         );
   END COMPONENT uart_tx;

   SIGNAL GCLK : STD_LOGIC := '0';
   SIGNAL RXD  : STD_LOGIC;
   SIGNAL TXD  : STD_LOGIC;

   TYPE RS232_TX_DATA_TYPE IS ARRAY (NATURAL RANGE <>) OF STD_LOGIC_VECTOR (7 DOWNTO 0);
   CONSTANT RS232_TX_ARRAY : RS232_TX_DATA_TYPE (0 TO 89) := (
      x"73", x"11", x"22", x"33", x"44", x"55", x"66", x"77", x"88", x"71", 
      x"73", x"ff", x"ee", x"dd", x"cc", x"bb", x"aa", x"99", x"88", x"71", 
      x"63", x"00", x"04", x"00", x"00", x"00", x"00", x"00", x"00", x"71",
      x"73", x"11", x"22", x"33", x"44", x"55", x"66", x"77", x"88", x"71",
      x"63", x"00", x"02", x"00", x"00", x"00", x"00", x"00", x"00", x"71",
      x"63", x"01", x"02", x"00", x"00", x"00", x"00", x"00", x"00", x"71",
      x"63", x"02", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"71",
      x"63", x"05", x"01", x"00", x"00", x"00", x"00", x"00", x"00", x"71",
      x"63", x"05", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"71"
      );
   SIGNAL cnt_RS232_data   : INTEGER                      := 0;

   SIGNAL RS232_TX_data        : STD_LOGIC_VECTOR (7 DOWNTO 0);
   SIGNAL RS232_TX_data_update : STD_LOGIC := '0';
   SIGNAL RS232_TX_busy        : STD_LOGIC;
   
   SIGNAL RS232_RX_data        : STD_LOGIC_VECTOR (7 DOWNTO 0) := x"00";
   SIGNAL RS232_RX_data_update : STD_LOGIC := '0';

   CONSTANT RS232_CLK_RATIO : INTEGER := 2;
   
   SIGNAL RST      : STD_LOGIC := '0';
   SIGNAL RST_GLOB : STD_LOGIC := '0';

   SIGNAL MCLK  : STD_LOGIC;
   SIGNAL MISO  : STD_LOGIC;
   SIGNAL MOSI  : STD_LOGIC;
   SIGNAL RST_N : STD_LOGIC := '1';
   
   SIGNAL PULSE_OUT : STD_LOGIC := '0';

BEGIN  -- ARCHITECTURE LArPixDAQ_tb_arch

   --GCLK <= NOT GCLK AFTER 20.833 NS;
   GCLK <= NOT GCLK AFTER 41.667 NS;

   LArPixDAQ_inst : LArPixDAQ
      PORT MAP (
         GCLK    => GCLK,
         -- RS232
         RXD     => RXD,
         TXD     => TXD,
         -- LArPix
         MCLK    => MCLK,
         MOSI    => MOSI,
         MISO    => MISO,
         RST_N   => RST_N,
         -- buttons
         BTN0    => RST,
         BTN1    => RST_GLOB,
         -- utility
         PULSE_OUT => PULSE_OUT,
         -- LEDs
         LED_RGB => OPEN,
         LEDs    => OPEN
         );

   MISO <= MOSI;

   uart_rx_RS232 : uart_rx
      GENERIC MAP (
         CLK_Hz     => 12000000,
         CLKIN_Hz   => 2000000,
         DATA_WIDTH => 8
         )
      PORT MAP (
         CLK         => GCLK,
         RST         => '0',
         CLKIN_RATIO => RS232_CLK_RATIO,
         -- UART RX
         RX          => TXD,
         -- received data
         data        => RS232_RX_data,
         data_update => RS232_RX_data_update,
         -- test signals
         TC          => OPEN
         );

   uart_tx_RS232 : uart_tx
      GENERIC MAP (
         CLK_Hz     => 12000000,
         CLKOUT_Hz  => 2000000,
         DATA_WIDTH => 8
         )
      PORT MAP (
         CLK         => GCLK,
         RST         => '0',
         CLKOUT_RATIO => RS232_CLK_RATIO,
         -- UART RX
         TX          => RXD,
         CLKout      => OPEN,
         -- received data
         data        => RS232_TX_data,
         data_update => RS232_TX_data_update,
         busy        => RS232_TX_busy,
         -- test signals
         TC          => OPEN
         );

   RS232_TX_FSM : PROCESS
   BEGIN  -- PROCESS RS232_TX_FSM
      WAIT FOR 10 NS;
      WAIT UNTIL MCLK = '1';
      RS232_TX_data        <= RS232_TX_ARRAY (cnt_RS232_data);
      RS232_TX_data_update <= '1';
      WAIT UNTIL RS232_TX_busy = '1';
      WAIT FOR 10 NS;
      RS232_TX_data_update <= '0';
      WAIT UNTIL RS232_TX_busy = '0';
      cnt_RS232_data       <= (cnt_RS232_data + 1) MOD 90;
   END PROCESS RS232_TX_FSM;

END ARCHITECTURE LArPixDAQ_tb_arch;

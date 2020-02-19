-- LArPix DAQ top level

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY LArPixDAQ IS
   PORT (
      GCLK    : IN  STD_LOGIC;
      -- RS232
      RXD     : IN  STD_LOGIC;
      TXD     : OUT STD_LOGIC;
      -- LArPix
      MCLK    : OUT STD_LOGIC;          -- master clock
      MOSI    : OUT STD_LOGIC;
      MISO    : IN  STD_LOGIC;
      RST_N   : OUT STD_LOGIC;
      -- buttons
      BTN0    : IN  STD_LOGIC;
      -- LEDs
      LED_RGB : OUT STD_LOGIC_VECTOR (2 DOWNTO 0);
      LEDs    : OUT STD_LOGIC_VECTOR (1 DOWNTO 0)
      );
END ENTITY LArPixDAQ;

ARCHITECTURE LArPixDAQ_arch OF LArPixDAQ IS

   COMPONENT clock_generator
      PORT (
         CLKin  : IN  STD_LOGIC;        -- 12MHz
         RST    : IN  STD_LOGIC;
         CLK100 : OUT STD_LOGIC;
         CLK200 : OUT STD_LOGIC;
         locked : OUT STD_LOGIC
         );
   END COMPONENT clock_generator;

   COMPONENT sync
      PORT (
         CLK : IN  STD_LOGIC;
         I   : IN  STD_LOGIC;
         O   : OUT STD_LOGIC
         );
   END COMPONENT sync;

   COMPONENT uart_rx
      GENERIC (
         CLK_Hz     : INTEGER;
         BAUD       : INTEGER;
         DATA_WIDTH : INTEGER := 8
         );
      PORT (
         CLK         : IN  STD_LOGIC;
         RST         : IN  STD_LOGIC;
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
         BAUD       : INTEGER;
         DATA_WIDTH : INTEGER := 8
         );
      PORT (
         CLK         : IN  STD_LOGIC;
         RST         : IN  STD_LOGIC;
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

   COMPONENT RS232_2_LArPix
      PORT (
         CLK                : IN  STD_LOGIC;
         RST                : IN  STD_LOGIC;
         -- RS232 UART RX
         data_RS232         : IN  STD_LOGIC_VECTOR (7 DOWNTO 0);
         data_update_RS232  : IN  STD_LOGIC;
         -- LArPix UART TX
         data_LArPix        : OUT STD_LOGIC_VECTOR (63 DOWNTO 0);
         data_update_LArPix : OUT STD_LOGIC;
         busy_LArPix        : IN  STD_LOGIC;
         -- test
         TC                 : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
         );
   END COMPONENT RS232_2_LArPix;

   COMPONENT fifo_54x32k
      PORT (
         clk   : IN  STD_LOGIC;
         srst  : IN  STD_LOGIC;
         din   : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
         wr_en : IN  STD_LOGIC;
         rd_en : IN  STD_LOGIC;
         dout  : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
         full  : OUT STD_LOGIC;
         empty : OUT STD_LOGIC
         );
   END COMPONENT;

   COMPONENT LArPix_2_RS232
      PORT (
         CLK               : IN  STD_LOGIC;
         RST               : IN  STD_LOGIC;
         -- LArPix FIFO 
         data_LArPix       : IN  STD_LOGIC_VECTOR (63 DOWNTO 0);
         empty_LArPix      : IN  STD_LOGIC;
         ren_LArPix        : OUT STD_LOGIC;
         -- RS232 UART RX
         data_RS232        : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
         data_update_RS232 : OUT STD_LOGIC;
         busy_RS232        : IN  STD_LOGIC;
         -- test
         TC                : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
         );
   END COMPONENT LArPix_2_RS232;

   COMPONENT LArPixRST_N
      PORT (
         CLK   : IN  STD_LOGIC;
         RST   : IN  STD_LOGIC;
         BTN   : IN  STD_LOGIC;
         MCLK  : IN  STD_LOGIC;
         RST_N : OUT STD_LOGIC;
         TC    : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
         );
   END COMPONENT LArPixRST_N;

   COMPONENT ila_16
      PORT (
         clk    : IN STD_LOGIC;
         probe0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
         );
   END COMPONENT;

   SIGNAL CLK      : STD_LOGIC;
   SIGNAL RST      : STD_LOGIC;
   SIGNAL locked   : STD_LOGIC;
   SIGNAL locked_n : STD_LOGIC;

   SIGNAL TXDi  : STD_LOGIC;
   SIGNAL MCLKi : STD_LOGIC;

   SIGNAL RS232_TX_busy : STD_LOGIC;

   SIGNAL RS232_RX_data        : STD_LOGIC_VECTOR (7 DOWNTO 0);
   SIGNAL RS232_TX_data        : STD_LOGIC_VECTOR (7 DOWNTO 0);
   SIGNAL RS232_RX_data_update : STD_LOGIC;
   SIGNAL RS232_TX_data_update : STD_LOGIC;

   SIGNAL LArPix_TX_data        : STD_LOGIC_VECTOR (63 DOWNTO 0);
   SIGNAL LArPix_TX_data_update : STD_LOGIC;
   SIGNAL LArPix_TX_busy        : STD_LOGIC;

   SIGNAL LArPix_RX_data        : STD_LOGIC_VECTOR (63 DOWNTO 0) := (OTHERS => '0');
   SIGNAL LArPix_RX_data_update : STD_LOGIC;

   SIGNAL fifo_dout  : STD_LOGIC_VECTOR (63 DOWNTO 0);
   SIGNAL fifo_ren   : STD_LOGIC;
   SIGNAL fifo_empty : STD_LOGIC;

   SIGNAL probe0 : STD_LOGIC_VECTOR(15 DOWNTO 0);

BEGIN  -- ARCHITECTURE LArPixDAQ_arch

   clock_generator_inst : clock_generator
      PORT MAP (
         CLKin  => GCLK,
         RST    => '0',
         CLK100 => CLK,
         CLK200 => OPEN,
         locked => locked
         );

   locked_n <= NOT locked;

   sync_inst : sync
      PORT MAP (
         CLK => CLK,
         I   => locked_n,
         O   => RST
         );

   ----------------------------------------------------------------------------
   -- RS232
   ----------------------------------------------------------------------------

   uart_rx_RS232 : uart_rx
      GENERIC MAP (
         CLK_Hz     => 100000000,
         BAUD       => 100000, -- 1000000, default
         DATA_WIDTH => 8
         )
      PORT MAP (
         CLK         => CLK,
         RST         => RST,
         -- UART RX
         RX          => RXD,
         -- received data
         data        => RS232_RX_data,
         data_update => RS232_RX_data_update,
         -- test signals
         TC          => OPEN
         );

   uart_tx_RS232 : uart_tx
      GENERIC MAP (
         CLK_Hz     => 100000000,
         BAUD       => 100000, -- 1000000, default
         DATA_WIDTH => 8
         )
      PORT MAP (
         CLK         => CLK,
         RST         => RST,
         -- UART RX
         TX          => TXDi,
         CLKout      => OPEN,
         -- received data
         data        => RS232_TX_data,
         data_update => RS232_TX_data_update,
         busy        => RS232_TX_busy,
         -- test signals
         TC          => OPEN
         );

   TXD <= TXDi;

   ----------------------------------------------------------------------------
   -- LArPix to RS232 translator
   ----------------------------------------------------------------------------

   --RS232_TX_data        <= RS232_RX_data;
   --RS232_TX_data_update <= RS232_RX_data_update;

   RS232_2_LArPix_inst : RS232_2_LArPix
      PORT MAP (
         CLK                => CLK,
         RST                => RST,
         -- RS232 UART RX
         data_RS232         => RS232_RX_data,
         data_update_RS232  => RS232_RX_data_update,
         -- LArPix UART TX
         data_LArPix        => LArPix_TX_data,
         data_update_LArPix => LArPix_TX_data_update,
         busy_LArPix        => LArPix_TX_busy,
         -- test
         TC                 => OPEN
         );


   fifo_54x32k_inst : fifo_54x32k
      PORT MAP (
         clk   => CLK,
         srst  => RST,
         din   => LArPix_RX_data,
         wr_en => LArPix_RX_data_update,
         rd_en => fifo_ren,
         dout  => fifo_dout,
         full  => OPEN,
         empty => fifo_empty
         );

   LArPix_2_RS232_inst : LArPix_2_RS232
      PORT MAP (
         CLK               => CLK,
         RST               => RST,
         -- LArPix FIFO 
         data_LArPix       => fifo_dout,
         empty_LArPix      => fifo_empty,
         ren_LArPix        => fifo_ren,
         -- RS232 UART RX
         data_RS232        => RS232_TX_data,
         data_update_RS232 => RS232_TX_data_update,
         busy_RS232        => RS232_TX_busy,
         -- test
         TC                => OPEN
         );

   ----------------------------------------------------------------------------
   -- LArPix UART
   ----------------------------------------------------------------------------

   uart_rx_LArPix : uart_rx
      GENERIC MAP (
         CLK_Hz     => 100000000,
         BAUD       => 25000000, -- 5000000, -- default
         DATA_WIDTH => 64
         )
      PORT MAP (
         CLK         => CLK,
         RST         => RST,
         -- UART RX
         RX          => MISO,
         -- received data
         data        => LArPix_RX_data,
         data_update => LArPix_RX_data_update,
         -- test signals
         TC          => OPEN
         );

   -- for propper BAUD rate (no rounding errors)
   -- CLK_Hz / BAUD / 4 must be an integer > 1
   --
   -- LArPix clock MCLK is 2x BAUD
   uart_tx_LArPix : uart_tx
      GENERIC MAP (
         CLK_Hz       => 100000000,
         BAUD         => 25000000, -- 5000000, -- default
         DATA_WIDTH   => 64,
         CLKOUT_RATIO => 4
         )
      PORT MAP (
         CLK         => CLK,
         RST         => RST,
         -- UART RX
         TX          => MOSI,
         CLKout      => MCLKi,
         -- received data
         data        => LArPix_TX_data,
         data_update => LArPix_TX_data_update,
         busy        => LArPix_TX_busy,
         -- test signals
         TC          => OPEN
         );
   MCLK <= MCLKi;

   LArPixRST_N_inst : LArPixRST_N
      PORT MAP (
         CLK   => CLK,
         RST   => RST,
         BTN   => BTN0,
         MCLK  => MCLKi,
         RST_N => RST_N,
         TC    => OPEN
         );

   -----------------------------------------------------------------------------
   LEDs(0) <= RS232_TX_busy;
   LEDs(1) <= LArPix_TX_busy;

   LED_RGB <= "111";

   --ila_16_inst : ila_16
   --   PORT MAP (
   --      clk    => CLK,
   --      probe0 => probe0
   --      );

   probe0 (7 DOWNTO 0)  <= RS232_RX_data;
   probe0 (8)           <= RS232_RX_data_update;
   probe0 (13 DOWNTO 9) <= (OTHERS => '0');
   probe0 (14)          <= LArPix_TX_data_update;
   probe0 (15)          <= LArPix_TX_busy;

END ARCHITECTURE LArPixDAQ_arch;

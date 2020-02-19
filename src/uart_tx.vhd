-- general purpose UART

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY uart_tx IS
   GENERIC (
      CLK_Hz       : INTEGER;
      BAUD         : INTEGER;
      DATA_WIDTH   : INTEGER := 8;
      CLKOUT_RATIO : INTEGER := 2 -- number of clkout cycles for each baud cycle
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
END ENTITY uart_tx;

ARCHITECTURE uart_tx_arch OF uart_tx IS

   CONSTANT CLK_LENGTH    : INTEGER := CLK_Hz / BAUD / 2;
   SIGNAL cnt_baud_length : INTEGER RANGE 0 TO CLKOUT_RATIO;
   SIGNAL cnt_clk_length  : INTEGER RANGE 0 TO CLK_LENGTH;
   SIGNAL cnt_bits        : INTEGER RANGE 0 TO DATA_WIDTH+2;

   SIGNAL CLK_MASTER    : STD_LOGIC := '0';
   SIGNAL CLK_MASTER1   : STD_LOGIC := '0';
   SIGNAL CLK_MASTERold : STD_LOGIC := '0';
   SIGNAL CLK_BAUD      : STD_LOGIC := '0';
   SIGNAL CLK_BAUD1     : STD_LOGIC := '0';
   SIGNAL CLK_BAUDold   : STD_LOGIC := '0';

   TYPE state_type IS (IDLE, SHIFT);
   SIGNAL state : state_type := IDLE;

   SIGNAL srg : STD_LOGIC_VECTOR (DATA_WIDTH+1 DOWNTO 0);

BEGIN  -- ARCHITECTURE uart_tx_arch

   BAUD_TICK_GEN : PROCESS (CLK, RST) IS
   BEGIN  -- PROCESS BAUD_TICK_GEN
      IF RST = '1' THEN                   -- asynchronous reset (active high)
         CLK_MASTER <= '0';
         CLK_BAUD   <= '0';
      ELSIF CLK'EVENT AND CLK = '1' THEN  -- rising clock edge
         CLK_MASTER1 <= CLK_MASTER;
         CLKout      <= CLK_MASTER1;
         IF CLK_MASTERold = '1' AND CLK_MASTER = '0' THEN
            IF cnt_baud_length = 0 THEN
                cnt_baud_length <= (CLKOUT_RATIO/2) - 1;
                CLK_BAUD        <= NOT CLK_BAUD;
            ELSE
                cnt_baud_length <= cnt_baud_length - 1;
            END IF;
         END IF;
         CLK_MASTERold <= CLK_MASTER;
         IF cnt_clk_length = 0 THEN
            cnt_clk_length <= (CLK_LENGTH/2) - 1;
            CLK_MASTER     <= NOT CLK_MASTER;
         ELSE
            cnt_clk_length <= cnt_clk_length - 1;
         END IF;
      END IF;
   END PROCESS BAUD_TICK_GEN;

   UART_TX_FSM : PROCESS (CLK, RST) IS
   BEGIN  -- PROCESS UART_TX_FSM
      IF RST = '1' THEN                   -- asynchronous reset (active high)
         state <= IDLE;
         TX    <= '1';
      ELSIF CLK'EVENT AND CLK = '1' THEN  -- rising clock edge
         CLK_BAUDold <= CLK_BAUD;
         busy        <= '0';
         CASE state IS
            WHEN IDLE =>
               TX       <= '1';
               cnt_bits <= 0;
               srg      <= '1' & data & '0';
               IF data_update = '1' THEN
                  state <= SHIFT;
               END IF;
            WHEN SHIFT =>
               busy <= '1';
               IF CLK_BAUDold = '1' AND CLK_BAUD = '0' THEN
                  TX       <= srg (0);
                  srg      <= '1' & srg(DATA_WIDTH+1 DOWNTO 1);
                  cnt_bits <= cnt_bits + 1;
                  IF cnt_bits >= DATA_WIDTH+1 THEN
                     state <= IDLE;
                  END IF;
               END IF;
            WHEN OTHERS =>
               NULL;
         END CASE;
      END IF;
   END PROCESS UART_TX_FSM;

   TC <= (OTHERS => '0');

END ARCHITECTURE uart_tx_arch;

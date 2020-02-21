-- generic RS232 UART

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY uart_rx IS
   GENERIC (
      CLK_Hz     : INTEGER;
      CLKIN_Hz   : INTEGER;
      DATA_WIDTH : INTEGER := 8
      );
   PORT (
      CLK         : IN  STD_LOGIC;
      RST         : IN  STD_LOGIC;
      CLKIN_RATIO : IN  INTEGER;
      -- UART RX
      RX          : IN  STD_LOGIC;
      -- received data
      data        : OUT STD_LOGIC_VECTOR (DATA_WIDTH-1 DOWNTO 0);
      data_update : OUT STD_LOGIC;
      -- test signals
      TC          : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
      );
END ENTITY uart_rx;

ARCHITECTURE uart_rx_arch OF uart_rx IS

   CONSTANT CLK_LENGTH   : INTEGER := CLK_Hz / CLKIN_Hz;
   SIGNAL bit_length     : INTEGER RANGE CLK_LENGTH TO CLK_LENGTH * 255;
   SIGNAL cnt_bit_length : INTEGER RANGE -1 TO CLK_LENGTH * 255;
   SIGNAL cnt_bits       : INTEGER RANGE 0 TO DATA_WIDTH+2;

   TYPE state_type IS (IDLE, WT, SHIFT, UPDATE);
   SIGNAL state : state_type := IDLE;

   SIGNAL RXfiltered  : STD_LOGIC;
   SIGNAL RXfilterSRG : STD_LOGIC_VECTOR (2 DOWNTO 0);

   SIGNAL srg : STD_LOGIC_VECTOR (DATA_WIDTH+1 DOWNTO 0);


BEGIN  -- ARCHITECTURE uart_rx_arch

   -- filter glitched from input data
   RX_FILTER : PROCESS (CLK, RST) IS
   BEGIN  -- PROCESS RX_FILTER
      IF RST = '1' THEN  -- asynchronous reset (active high)
         RXfiltered <= '1';
      ELSIF CLK'EVENT AND CLK = '1' THEN  -- rising clock edge
         RXfilterSRG <= RXfilterSRG (1 DOWNTO 0) & RX;
         IF RXfilterSRG = "111" THEN
            RXfiltered <= '1';
         END IF;
         IF RXfilterSRG = "000" THEN
            RXfiltered <= '0';
         END IF;
      END IF;
   END PROCESS RX_FILTER;

   UART_RX_FSM : PROCESS (CLK, RST) IS
   BEGIN  -- PROCESS UART_RX_FSM
      IF RST = '1' THEN  -- asynchronous reset (active high)
         state <= IDLE;
      ELSIF CLK'EVENT AND CLK = '1' THEN  -- rising clock edge
         data_update <= '0';
         bit_length  <= CLK_LENGTH * CLKIN_RATIO;
         CASE state IS
            WHEN IDLE =>
               cnt_bit_length <= (bit_length / 2) - 2;
               cnt_bits       <= 0;
               IF RXfiltered = '0' THEN
                  state <= WT;
               END IF;
            WHEN WT =>
               cnt_bit_length <= cnt_bit_length - 1;
               IF cnt_bit_length = 0 THEN
                  state <= SHIFT;
               ELSE
                  state <= WT;
               END IF;
            WHEN SHIFT =>
               cnt_bits       <= cnt_bits + 1;
               srg            <= RXfiltered & srg (DATA_WIDTH+1 DOWNTO 1);
               cnt_bit_length <= bit_length - 2;
               IF cnt_bits >= DATA_WIDTH+1 THEN
                  state <= UPDATE;
               ELSE
                  state <= WT;
               END IF;
            WHEN UPDATE =>
               -- check stop bit
               IF srg(DATA_WIDTH+1) = '1' THEN
                  data_update <= '1';
                  data        <= srg(DATA_WIDTH DOWNTO 1);
               END IF;
               state <= IDLE;
            WHEN OTHERS =>
               NULL;
         END CASE;
      END IF;
   END PROCESS UART_RX_FSM;

   TC <= (OTHERS => '0');

END ARCHITECTURE uart_rx_arch;

-- convert the LArPix data to the RS232 out stream

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY LArPix_2_RS232 IS
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
END ENTITY LArPix_2_RS232;

ARCHITECTURE LArPix_2_RS232_arch OF LArPix_2_RS232 IS

   TYPE state_type IS (IDLE, RD_FIFO, LATCH_FIFO, TX, WT_TX_DONE);
   SIGNAL state : state_type := IDLE;

   SIGNAL fifo_data : STD_LOGIC_VECTOR (63 DOWNTO 0);

   TYPE RS232_ARRAY_TYPE IS ARRAY (NATURAL RANGE <>) OF STD_LOGIC_VECTOR (7 DOWNTO 0);
   SIGNAL RS232_TX_array : RS232_ARRAY_TYPE (0 TO 9);

   SIGNAL cnt_byte : INTEGER RANGE 0 TO 9;

BEGIN  -- ARCHITECTURE LArPix_2_RS232_arch

   RS232_TX_array (0) <= x"73";
   RS232_TX_array (1) <= fifo_data (7 DOWNTO 0);
   RS232_TX_array (2) <= fifo_data (15 DOWNTO 8);
   RS232_TX_array (3) <= fifo_data (23 DOWNTO 16);
   RS232_TX_array (4) <= fifo_data (31 DOWNTO 24);
   RS232_TX_array (5) <= fifo_data (39 DOWNTO 32);
   RS232_TX_array (6) <= fifo_data (47 DOWNTO 40);
   RS232_TX_array (7) <= fifo_data (55 DOWNTO 48);
   RS232_TX_array (8) <= fifo_data (63 DOWNTO 56);
   RS232_TX_array (9) <= x"71";

   RS232_TX_FSM : PROCESS (CLK, RST) IS
   BEGIN  -- PROCESS RS232_TX_FSM
      IF RST = '1' THEN                 -- asynchronous reset (active high)

      ELSIF CLK'EVENT AND CLK = '1' THEN  -- rising clock edge
         ren_LArPix        <= '0';
         data_update_RS232 <= '0';
         CASE state IS
            WHEN IDLE =>
               cnt_byte <= 0;
               IF empty_LArPix = '0' THEN
                  ren_LArPix <= '1';
                  state      <= RD_FIFO;
               END IF;
            WHEN RD_FIFO =>
               state <= LATCH_FIFO;
            WHEN LATCH_FIFO =>
               fifo_data <= data_LArPix;
               state     <= TX;
            WHEN TX =>
               data_RS232        <= RS232_TX_array (cnt_byte);
               data_update_RS232 <= '1';
               IF busy_RS232 = '1' THEN
                  state <= WT_TX_DONE;
               END IF;
            WHEN WT_TX_DONE =>
               IF busy_RS232 = '0' THEN
                  IF cnt_byte >= 9 THEN
                     state <= IDLE;
                  ELSE
                     cnt_byte <= cnt_byte + 1;
                     state    <= TX;
                  END IF;
               END IF;
            WHEN OTHERS =>
               NULL;
         END CASE;
      END IF;
   END PROCESS RS232_TX_FSM;

   TC <= (OTHERS => '0');

END ARCHITECTURE LArPix_2_RS232_arch;

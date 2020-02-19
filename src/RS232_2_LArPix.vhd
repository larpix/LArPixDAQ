--c onvert RS232 to LArPix

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY RS232_2_LArPix IS
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
END ENTITY RS232_2_LArPix;

ARCHITECTURE RS232_2_LArPix_arch OF RS232_2_LArPix IS

   CONSTANT START_BYTE : STD_LOGIC_VECTOR (7 DOWNTO 0) := x"73";  -- ASCII s
   CONSTANT STOP_BYTE  : STD_LOGIC_VECTOR (7 DOWNTO 0) := x"71";  -- ASCII q

   TYPE state_type IS (IDLE, START_TX, WT_TX_DONE);
   SIGNAL state : state_type := IDLE;

   -- 64 bit data 8 bits start byte 8 bits stop byte
   SIGNAL srg          : STD_LOGIC_VECTOR ((64+8+8)-1 DOWNTO 0);
   SIGNAL srg_updated  : STD_LOGIC;
   SIGNAL cnt_RX_bytes : INTEGER RANGE 0 TO 10 := 0;

BEGIN  -- ARCHITECTURE RS232_2_LArPix_arch

   GET_RS232_BYTES : PROCESS (CLK, RST) IS
   BEGIN  -- PROCESS GET_RS232_BYTES
      IF RST = '1' THEN                 -- asynchronous reset (active high)

      ELSIF CLK'EVENT AND CLK = '1' THEN  -- rising clock edge
         IF data_update_RS232 = '1' THEN
            -- LSB comes first
            srg         <= data_RS232 & srg(srg'LENGTH-1 DOWNTO 8);
            srg_updated <= '1';
         ELSE
            srg_updated <= '0';
         END IF;
      END IF;
   END PROCESS GET_RS232_BYTES;

   LArPix_TX_FSM : PROCESS (CLK, RST) IS
   BEGIN  -- PROCESS LArPix_TX_FSM
      IF RST = '1' THEN                 -- asynchronous reset (active high)

      ELSIF CLK'EVENT AND CLK = '1' THEN  -- rising clock edge
         IF srg_updated = '1' THEN
            IF cnt_RX_bytes < 10 THEN
               cnt_RX_bytes <= cnt_RX_bytes + 1;
            END IF;
         END IF;
         CASE state IS
            WHEN IDLE =>
               IF srg_updated = '1' THEN
                  IF srg (7 DOWNTO 0) = START_BYTE AND srg (79 DOWNTO 72) = STOP_BYTE AND cnt_RX_bytes >= 9 THEN
                     -- start and stop byte found and at least 10 bytes since
                     -- the last transmission
                     cnt_RX_bytes <= 0;
                     state        <= START_TX;
                  END IF;
               END IF;
               data_LArPix        <= srg (71 DOWNTO 8);
               data_update_LArPix <= '0';
            WHEN START_TX =>
               data_update_LArPix <= '1';
               IF busy_LArPix = '1' THEN
                  state <= WT_TX_DONE;
               END IF;
            WHEN WT_TX_DONE =>
               data_update_LArPix <= '0';
               IF busy_LArPix = '0' THEN
                  state <= IDLE;
               END IF;
            WHEN OTHERS =>
               NULL;
         END CASE;
      END IF;
   END PROCESS LArPix_TX_FSM;

   TC <= (OTHERS => '0');

END ARCHITECTURE RS232_2_LArPix_arch;

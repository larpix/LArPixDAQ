-- reset generator for the LArPix chip-
-- use push button to initialize reset
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY LArPixRST_N IS
   PORT (
      CLK   : IN  STD_LOGIC;
      RST   : IN  STD_LOGIC;
      CNT_RESET : IN INTEGER RANGE 0 TO 255;
      TRIG  : IN  STD_LOGIC;
      MCLK  : IN  STD_LOGIC;
      RST_N : OUT STD_LOGIC;
      TC    : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
      );
END ENTITY LArPixRST_N;

ARCHITECTURE LArPixRST_N_arch OF LArPixRST_N IS

   SIGNAL cnt      : INTEGER RANGE -1 TO 255;

   SIGNAL srg     : STD_LOGIC_VECTOR (3 DOWNTO 0) := (OTHERS => '0');
   SIGNAL MCLKold : STD_LOGIC;

BEGIN  -- ARCHITECTURE LArPixRST_N_arch

   TRIG_SYNC : PROCESS (CLK, RST) IS
   BEGIN  -- PROCESS TRIG_SYNC
      IF RST = '1' THEN                 -- asynchronous reset (active high)
         
      ELSIF CLK'EVENT AND CLK = '1' THEN  -- rising clock edge
         srg <= srg (2 DOWNTO 0) & TRIG;
      END IF;
   END PROCESS TRIG_SYNC;

   GEN_RST_N : PROCESS (CLK, RST) IS
   BEGIN  -- PROCESS GEN_RST_N
      IF RST = '1' THEN                   -- asynchronous reset (active high)
         cnt <= CNT_RESET;

      ELSIF CLK'EVENT AND CLK = '1' THEN  -- rising clock edge
         MCLKold <= MCLK;
         
         IF srg (3) = '1' THEN
            -- reset the counter
            -- button is high active
            cnt      <= CNT_RESET;
            RST_N    <= '0';
         ELSIF cnt >= 0 THEN
            -- count down (based on MCLK rising edges)
            IF MCLK = '1' and MCLKold = '0' THEN
               cnt   <= cnt - 1;
               RST_N <= '0';
            END IF;
         ELSE
            -- the reset is done
            cnt <= cnt;
            -- wait for MCLK falling edge
            IF MCLK = '0' AND MCLKold = '1' THEN
               RST_N <= '1';
            END IF;
         END IF;
      END IF;
   END PROCESS GEN_RST_N;

   TC <= (OTHERS => '0');

END ARCHITECTURE LArPixRST_N_arch;

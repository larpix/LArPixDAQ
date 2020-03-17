-- periodic pulse generator
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY PulseGen IS
   PORT (
      CLK   : IN  STD_LOGIC;
      RST   : IN  STD_LOGIC;
      CNT_PULSE_LEN : IN INTEGER RANGE 0 TO 2147483647; -- PULSE is high for CNT_PULSE_LEN+2 MCLK cycles
      CNT_PULSE_REP : IN INTEGER RANGE 0 TO 2147483647; -- rising edges of PULSE are sep by CNT_PULSE_REP+1 MCLK cycles
      EN    : IN  STD_LOGIC;
      MCLK  : IN  STD_LOGIC;
      PULSE : OUT STD_LOGIC;
      TC    : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
      );
END ENTITY PulseGen;

ARCHITECTURE PulseGen_arch OF PulseGen IS

   SIGNAL cntr_pulse : INTEGER RANGE -1 TO 2147483647;
   SIGNAL cntr_rep   : INTEGER RANGE -1 TO 2147483647;

BEGIN  -- ARCHITECTURE PulseGen_arch

   GEN_PULSE : PROCESS (MCLK, RST) IS
   BEGIN  -- PROCESS GEN_PULSE
      IF RST = '1' THEN                   -- asynchronous reset (active high)
         cntr_pulse <= -1;
         cntr_rep   <= -1;

      ELSIF MCLK'EVENT AND MCLK = '1' THEN  -- rising clock edge
         IF EN = '1' THEN
            IF cntr_rep <= 0 THEN
               cntr_pulse <= CNT_PULSE_LEN;
               cntr_rep   <= CNT_PULSE_REP;
               PULSE <= '1';
            ELSIF cntr_pulse >= 0 THEN
               cntr_pulse <= cntr_pulse - 1;
               cntr_rep   <= cntr_rep - 1;
               PULSE <= '1';
            ELSIF cntr_rep >= 0 THEN
               cntr_rep <= cntr_rep - 1;
               PULSE    <= '0';
            END IF;
         ELSE
            cntr_pulse <= -1;
            cntr_rep <= -1;
            PULSE <= '0';
         END IF;
      END IF;
   END PROCESS GEN_PULSE;

   TC <= (OTHERS => '0');

END ARCHITECTURE PulseGen_arch;

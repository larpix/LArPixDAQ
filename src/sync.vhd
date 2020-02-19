-- clock synchronizer

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY sync IS
   PORT (
      CLK : IN  STD_LOGIC;
      I   : IN  STD_LOGIC;
      O   : OUT STD_LOGIC
      );
END ENTITY sync;

ARCHITECTURE sync_arch OF sync IS

   SIGNAL srg : STD_LOGIC_VECTOR (3 DOWNTO 0) := "1111";

BEGIN  -- ARCHITECTURE sync_arch

   SYNC_PROC : PROCESS (CLK) IS
   BEGIN  -- PROCESS SYNC_PROC
      IF CLK'EVENT AND CLK = '1' THEN   -- rising clock edge
         srg <= srg (2 DOWNTO 0) & I;
         IF srg (3 DOWNTO 1) = "111" THEN
            O <= '1';
         ELSIF srg (3 DOWNTO 1) = "000" THEN
            O <= '0';
         END IF;
      END IF;
   END PROCESS SYNC_PROC;

END ARCHITECTURE sync_arch;

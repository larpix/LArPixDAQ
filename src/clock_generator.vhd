-- generate the user logic clocks

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

LIBRARY UNISIM;
USE UNISIM.vcomponents.ALL;


ENTITY clock_generator IS
   PORT (
      CLKin  : IN  STD_LOGIC;           -- 12MHz
      RST    : IN  STD_LOGIC;
      CLK100 : OUT STD_LOGIC;
      CLK200 : OUT STD_LOGIC;
      locked : OUT STD_LOGIC
      );
END ENTITY clock_generator;

ARCHITECTURE clock_generator_arch OF clock_generator IS

   SIGNAL CLKIN1   : STD_LOGIC;
   SIGNAL CLKFBIN  : STD_LOGIC;
   SIGNAL CLKFBOUT : STD_LOGIC;
   SIGNAL CLKOUT1  : STD_LOGIC;
   SIGNAL CLKOUT2  : STD_LOGIC;

BEGIN  -- ARCHITECTURE clock_generator_arch

   BUFG_CLKin_inst : BUFG
      PORT MAP (
         O => CLKIN1,                   -- 1-bit output: Clock output
         I => CLKin                     -- 1-bit input: Clock input
         );

   MMCME2_BASE_inst : MMCME2_BASE
      GENERIC MAP (
         BANDWIDTH          => "OPTIMIZED",  -- Jitter programming (OPTIMIZED, HIGH, LOW)
         CLKFBOUT_MULT_F    => 50.0,  -- Multiply value for all CLKOUT (2.000-64.000).
         CLKFBOUT_PHASE     => 0.0,  -- Phase offset in degrees of CLKFB (-360.000-360.000).
         CLKIN1_PERIOD      => 83.333,  -- Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
         -- CLKOUT0_DIVIDE  - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
         CLKOUT1_DIVIDE     => 6,       -- 100 MHz
         CLKOUT2_DIVIDE     => 3,       -- 200 MHz
         CLKOUT3_DIVIDE     => 1,
         CLKOUT4_DIVIDE     => 1,
         CLKOUT5_DIVIDE     => 1,
         CLKOUT6_DIVIDE     => 1,
         CLKOUT0_DIVIDE_F   => 1.0,  -- Divide amount for CLKOUT0 (1.000-128.000).
         --CLKOUT0_DUTY_CYCLE => 0.5,  -- CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
         CLKOUT0_DUTY_CYCLE => 0.5,
         CLKOUT1_DUTY_CYCLE => 0.5,
         CLKOUT2_DUTY_CYCLE => 0.5,
         CLKOUT3_DUTY_CYCLE => 0.5,
         CLKOUT4_DUTY_CYCLE => 0.5,
         CLKOUT5_DUTY_CYCLE => 0.5,
         CLKOUT6_DUTY_CYCLE => 0.5,
         --CLKOUT0_PHASE      => 0.0,  -- CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
         CLKOUT0_PHASE      => 0.0,
         CLKOUT1_PHASE      => 0.0,
         CLKOUT2_PHASE      => 0.0,
         CLKOUT3_PHASE      => 0.0,
         CLKOUT4_PHASE      => 0.0,
         CLKOUT5_PHASE      => 0.0,
         CLKOUT6_PHASE      => 0.0,
         CLKOUT4_CASCADE    => FALSE,  -- Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
         DIVCLK_DIVIDE      => 1,       -- Master division value (1-106)
         REF_JITTER1        => 0.0,  -- Reference input jitter in UI (0.000-0.999).
         STARTUP_WAIT       => FALSE  -- Delays DONE until MMCM is locked (FALSE, TRUE)
         )
      PORT MAP (
         -- Clock Outputs: 1-bit (each) output: User configurable clock outputs
         --CLKOUT0   => OPEN,             -- 1-bit output: CLKOUT0
         CLKOUT0B  => OPEN,             -- 1-bit output: Inverted CLKOUT0
         CLKOUT1   => CLKOUT1,          -- 1-bit output: CLKOUT1
         CLKOUT1B  => OPEN,             -- 1-bit output: Inverted CLKOUT1
         CLKOUT2   => CLKOUT2,          -- 1-bit output: CLKOUT2
         CLKOUT2B  => OPEN,             -- 1-bit output: Inverted CLKOUT2
         CLKOUT3   => OPEN,             -- 1-bit output: CLKOUT3
         CLKOUT3B  => OPEN,             -- 1-bit output: Inverted CLKOUT3
         CLKOUT4   => OPEN,             -- 1-bit output: CLKOUT4
         CLKOUT5   => OPEN,             -- 1-bit output: CLKOUT5
         CLKOUT6   => OPEN,             -- 1-bit output: CLKOUT6
         -- Feedback Clocks: 1-bit (each) output: Clock feedback ports
         CLKFBOUT  => CLKFBOUT,         -- 1-bit output: Feedback clock
         CLKFBOUTB => OPEN,             -- 1-bit output: Inverted CLKFBOUT
         -- Status Ports: 1-bit (each) output: MMCM status ports
         LOCKED    => locked,           -- 1-bit output: LOCK
         -- Clock Inputs: 1-bit (each) input: Clock input
         CLKIN1    => CLKIN1,           -- 1-bit input: Clock
         -- Control Ports: 1-bit (each) input: MMCM control ports
         PWRDWN    => '0',              -- 1-bit input: Power-down
         RST       => RST,              -- 1-bit input: Reset
         -- Feedback Clocks: 1-bit (each) input: Clock feedback ports
         CLKFBIN   => CLKFBIN           -- 1-bit input: Feedback clock
         );

   --BUFG_FB_inst : BUFG
   --   PORT MAP (
   --      O => CLKFBIN,                  -- 1-bit output: Clock output
   --      I => CLKFBOUT                  -- 1-bit input: Clock input
   --      );
   CLKFBIN <= CLKFBOUT;

   BUFG_CLK100_inst : BUFG
      PORT MAP (
         O => CLK100,                   -- 1-bit output: Clock output
         I => CLKOUT1                   -- 1-bit input: Clock input
         );

   BUFG_CLK200_inst : BUFG
      PORT MAP (
         O => CLK200,                   -- 1-bit output: Clock output
         I => CLKOUT2                   -- 1-bit input: Clock input
         );

END ARCHITECTURE clock_generator_arch;

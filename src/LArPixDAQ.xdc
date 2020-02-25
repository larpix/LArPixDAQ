# CLOCK input
create_clock -period 83.333 -name GCLK [get_ports GCLK]
set_property PACKAGE_PIN L17 [get_ports GCLK]
set_property IOSTANDARD LVCMOS33 [get_ports GCLK]

# RS232
#set_property PACKAGE_PIN J18 [get_ports TXD]
# external FTDI
set_property PACKAGE_PIN R3 [get_ports TXD]
set_property IOSTANDARD LVCMOS33 [get_ports TXD]
#set_property PACKAGE_PIN J17 [get_ports RXD]
# external FTDI
set_property PACKAGE_PIN T3 [get_ports RXD]
set_property IOSTANDARD LVCMOS33 [get_ports RXD]

# LArPix
set_property PACKAGE_PIN M3 [get_ports MCLK]
set_property IOSTANDARD LVCMOS33 [get_ports MCLK]
set_property PACKAGE_PIN L3 [get_ports MOSI]
set_property IOSTANDARD LVCMOS33 [get_ports MOSI]
set_property PACKAGE_PIN A16 [get_ports MISO]
set_property IOSTANDARD LVCMOS33 [get_ports MISO]
set_property PACKAGE_PIN K3 [get_ports RST_N]
set_property IOSTANDARD LVCMOS33 [get_ports RST_N]

# Buttons
set_property PACKAGE_PIN A18 [get_ports BTN0]
set_property IOSTANDARD LVCMOS33 [get_ports BTN0]
set_property PACKAGE_PIN B18 [get_ports BTN1]
set_property IOSTANDARD LVCMOS33 [get_ports BTN1]

# Utility
set_property PACKAGE_PIN G17 [get_ports PULSE_OUT]
set_property IOSTANDARD LVCMOS [get_ports PULSE_OUT]

# LEDs
set_property PACKAGE_PIN A17 [get_ports {LEDs[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LEDs[0]}]
set_property PACKAGE_PIN C16 [get_ports {LEDs[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LEDs[1]}]

set_property PACKAGE_PIN C17 [get_ports {LED_RGB[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_RGB[0]}]
set_property PACKAGE_PIN B16 [get_ports {LED_RGB[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_RGB[1]}]
set_property PACKAGE_PIN B17 [get_ports {LED_RGB[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_RGB[2]}]

set_property CONFIG_MODE SPIx4 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CFGBVS VCCO [current_design]


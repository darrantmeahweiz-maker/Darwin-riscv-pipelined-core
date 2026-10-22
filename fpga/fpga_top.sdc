# =========================================================================
# 1. Base Clock Constraint
# =========================================================================
# Define the 50 MHz on-board oscillator (20.000 ns period)
create_clock -name CLOCK_50 -period 20.000 [get_ports CLOCK_50]

# Automatically calculate clock jitter and PLL uncertainty for Cyclone V
derive_clock_uncertainty

# =========================================================================
# 2. Asynchronous Input False Paths
# =========================================================================
# Pushbuttons (KEY) and slide switches (SW) are asynchronous human inputs.
# Setting false paths prevents TimeQuest from calculating timing on them.
set_false_path -from [get_ports {KEY[*]}]
set_false_path -from [get_ports {SW[*]}]

# =========================================================================
# 3. Asynchronous Output False Paths
# =========================================================================
# LEDs, 7-segment displays, and asynchronous UART lines do not need to meet
# strict board-synchronous setup/hold timing.
set_false_path -to [get_ports {LEDR[*]}]
set_false_path -to [get_ports {HEX0[*]}]
set_false_path -to [get_ports {HEX1[*]}]
set_false_path -to [get_ports {HEX2[*]}]
set_false_path -to [get_ports {HEX3[*]}]
set_false_path -to [get_ports {HEX4[*]}]
set_false_path -to [get_ports {HEX5[*]}]
set_false_path -to [get_ports {UART_TXD}]
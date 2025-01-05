# I2C Slave Module

## Description
This repository contains an I2C slave module implemented in Verilog. The module is designed to receive data and address from an I2C master and handle the necessary acknowledgments (ACKs). The module also includes a testbench to verify its functionality.

## Files
- `i2c_slave.v`: The main I2C slave module.
- `i2c_slave_tb.v`: Testbench for the I2C slave module.

## Simulation
Run the testbench using a Verilog simulator (Icarus Verilog was used) to verify the functionality of the I2C slave module.
```bash
iverilog -o i2c_slave_tb i2c_slave_tb.v i2c_slave.v
vvp i2c_slave_tb
```

## Notes
- The module currently supports receiving data and address but does not yet implement the data output functionality.
- The testbench demonstrates basic I2C communication and can be extended for more complex scenarios.
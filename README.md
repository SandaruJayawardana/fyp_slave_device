# fyp_slave_device

> This is an ongoing project. The system block diagram is shown below. The aim of the project was to design and develop a total system to control multi devices using single pair cable. In here we will design and implement a total design using Fast Etherent medium. Total system is a master slave architecture. Master device will be implemented in SoC FPGA device and slave device is implemented in FPGA. 

## Specifications of Current Design

1. Supports up to 255 slave devices.
2. 10us precision time synchronization.
3. 5kHz data rate within 255 slaves.
4. Total system contains custom protocol over the selected medium.
5. Supports any physical network topology.
5. Fully customizable slave device according to the requirement.
6. System design can be moved on to high bandwidth mediums like Gigabit Ethernet, 10Gb Ethernet .etc with minor modification.

## Design Architecture
<img src="https://github.com/SandaruJayawardana/fyp_slave_device/blob/main/slave%20design.png" alt="alt text" width="500" height="1000">

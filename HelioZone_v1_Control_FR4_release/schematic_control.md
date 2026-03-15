# Control Board Schematic Description

## Blocks
1. 48 V input and protection: reverse polarity MOSFET, TVS, input fuse.
2. Buck stage: 48 V -> 5 V (2 A), then LDO 5 V -> 3.3 V for MCU.
3. ESP32-S3 core: module, EN/BOOT circuits, UART programming, status LEDs.
4. Driver block U4/U5/U6 (TPS92518HV): each drives two channels with PWM/analog dim pins.
5. Current sense: per-channel Rsense footprints and optional trim jumpers.
6. Temperature sensing: NTC1/NTC2 remote connectors + onboard NTC3.
7. Connectors: J1 power in, J2/J3/J4 LED outputs, J5 sensors, J6 service.

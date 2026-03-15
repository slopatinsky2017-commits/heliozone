# HelioZone v1 Control FR4 Release

## Hardware overview
- MCU: ESP32-S3-WROOM-1 (Wi-Fi/BLE optional for service features).
- LED drivers: 3 x TPS92518HV, each providing 2 current-regulated outputs.
- Input: 48 VDC nominal from external PSU.
- Outputs: 6 physical outputs mapped to 5 logical channels (Main White split A/B).
- Sensing: 2 remote NTC inputs + on-board NTC.
- Service: USB-UART programming header + SWD/UART debug pads.

## Design philosophy
- Keep power and control grounds partitioned then joined at star point near input filter.
- Reserve large copper for thermal and current return around TPS92518HV sections.
- Use keyed locking connectors for field harness reliability.

# Power Architecture

- Primary input: 48 VDC constant voltage PSU.
- Control board branch:
  - EMI + surge suppression.
  - Buck to 5 V rail for auxiliaries.
  - LDO to 3.3 V for ESP32-S3 and sensors.
- LED branch:
  - 6 constant-current physical outputs from TPS92518HV stages.
  - CH1A/CH1B combine as logical Main White.

## Protection
- Input fuse and reverse polarity MOSFET.
- TVS clamp on 48 V input.
- Per-channel current regulation with soft-start ramp in firmware.

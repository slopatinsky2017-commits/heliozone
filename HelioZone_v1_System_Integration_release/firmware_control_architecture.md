# Firmware Control Architecture

## Logical channels
- Logical CH_MAIN_WHITE -> Physical OUT1 + OUT2 synchronized.
- Logical CH_WARM_WHITE -> OUT3.
- Logical CH_BLUE_450 -> OUT4.
- Logical CH_DEEP_RED_660 -> OUT5.
- Logical CH_FAR_RED_730 -> OUT6.

## Control loop
1. Receive setpoints (local UI or network command).
2. Apply recipe scheduler and safety clamps.
3. Convert logical channel intensity to physical PWM and IADJ values.
4. Read NTC sensors every 250 ms.
5. Apply thermal derating + fault latch policy.

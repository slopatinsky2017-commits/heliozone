# HelioZone ESP32 Firmware (ESP-IDF)

Basic ESP-IDF firmware implementation for ESP32-S3 using FreeRTOS tasks.

## Modules

- `wifi_manager`
  - AP mode for first setup (`HelioZone-Setup`)
  - STA mode for home WiFi (configure `HZ_STA_SSID` / `HZ_STA_PASSWORD` in `wifi_manager.c`)
  - mDNS hostname `heliozone.local` when STA gets an IP
- `time_manager`
  - NTP synchronization with `pool.ntp.org`
  - sync on boot and periodic resync every 6 hours
  - shared system-time accessors for synchronized sun simulation
- `led_controller`
  - PWM control for 4 channels: White, Blue, Red, Far Red
  - Brightness per channel in range `0..100` percent
- `sensor_manager`
  - SEM228P PAR sensor via RS485/Modbus (placeholder reader in current scaffold)
  - PPFD update every second
- `sun_engine`
  - Sunrise ramp + daylight plateau + sunset ramp
  - Smooth cosine transition curve
  - Adjustable sunrise/sunset, max intensity, and channel ratios
  - DLI-based intensity scaling input
- `light_regulator`
  - Target-PPFD proportional feedback controller
  - Automatically increases/decreases brightness to maintain PPFD
- `dli_manager`
  - Integrates DLI each second: `DLI += PPFD / 1,000,000`
  - Resets dose at midnight
  - Gradually reduces light scale when `current_dli >= target_dli`
- `telemetry_manager`
  - Aggregates live telemetry for streaming
  - Tracks `ppfd`, `dli`, `led_power`, `sun_phase`
- `http_api`
  - REST API + SSE stream over ESP-IDF HTTP server

## API endpoints

- `GET /api/v1/status`
- `POST /api/v1/control/power`
- `POST /api/v1/control/channels`
- `GET /api/v1/sun/status`
- `POST /api/v1/sun/config`
- `GET /api/v1/par`
- `POST /api/v1/par/target`
- `GET /api/v1/dli`
- `POST /api/v1/dli/target`
- `GET /api/v1/time`
- `GET /api/v1/stream` (SSE)

### Time response

```json
{
  "timestamp": 1735689600,
  "timezone": "UTC0"
}
```

### SSE stream event payload

```json
{
  "ppfd": 420.0,
  "dli": 6.2,
  "led_power": 75.0,
  "sun_phase": "day"
}
```

## Build

```bash
idf.py set-target esp32s3
idf.py build
```

# HelioZone

HelioZone is a smart grow light platform with an ESP32-S3 firmware stack and a Flutter mobile app.

## Repository structure

- `firmware/esp32` — ESP-IDF project for the ESP32-S3 lighting controller.
- `mobile_app/flutter` — Flutter app (Android/iOS) for setup and control.
- `backend` — reserved for optional backend/cloud services.
- `docs` — product and technical documentation.

## Current scope

This initial scaffold includes:

- ESP-IDF firmware skeleton with core modules:
  - `wifi_manager`
  - `http_api`
  - `led_controller` (White, Blue, Red, Far Red)
  - `sensor_manager` (PAR + RS485)
- Example HTTP endpoints:
  - `GET /api/v1/status`
  - `POST /api/v1/control/power`
  - `POST /api/v1/control/channels`
- Flutter folder scaffold with `lib/features`, `lib/core`, and `lib/api`.

## Getting started

### Firmware (ESP-IDF)

1. Install ESP-IDF (v5.x recommended).
2. Open `firmware/esp32`.
3. Run:
   - `idf.py set-target esp32s3`
   - `idf.py build`

### Mobile app (Flutter)

1. Install Flutter SDK.
2. Open `mobile_app/flutter`.
3. Run:
   - `flutter pub get`
   - `flutter run`

## Notes

This is an initial project skeleton intended to unblock parallel development for firmware and mobile app teams.

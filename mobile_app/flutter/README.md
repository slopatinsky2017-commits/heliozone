# HelioZone Flutter App

Flutter mobile app scaffold for Android and iOS.

## Architecture

Clean architecture-inspired UI/data layers:

- `lib/services` — REST, discovery, telemetry, storage, and zone fan-out services
- `lib/models` — API/domain models
- `lib/screens` — feature screens
- `lib/widgets` — reusable UI widgets

## Device discovery (mDNS / Bonjour)

The app auto-discovers HelioZone controllers on the local network using mDNS:

- service type: `_http._tcp`
- expected controller name: `heliozone`
- expected hostname: `heliozone.local`

## Multi-device + zones

- Persistent device model:
  - `Device { deviceId, name, host, ip, fw, lastSeen }`
- Persistent zone model:
  - `Zone { zoneId, name, deviceIds[] }`
- Local persistence via `shared_preferences`.
- New Zones tab:
  - create/delete zones
  - open zone details
  - per-device online/offline checks
  - open selected device context
- Zone apply control (fan-out):
  - mode
  - power
  - PPFD target
  - DLI target
  - sunrise/sunset
  - White/Blue/Red/Far Red ratios
- Fan-out networking uses parallel requests with timeout/retry and per-device result status.

## Real-time telemetry

`TelemetryService` subscribes to firmware SSE endpoint and updates dashboard live:

- stream endpoint: `GET /api/v1/stream`
- fields: `ppfd`, `dli`, `led_power`, `sun_phase`

## ESP32 endpoints used

- `GET /api/v1/status`
- `GET /api/v1/par`
- `GET /api/v1/dli`
- `GET /api/v1/stream` (SSE)
- `POST /api/v1/control`
- `POST /api/v1/control/power`
- `POST /api/v1/par/target`
- `POST /api/v1/dli/target`

## Run

```bash
flutter pub get
flutter run
```

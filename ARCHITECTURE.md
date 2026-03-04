# HelioZone Smart Grow Light System Architecture

## 1) System Overview

HelioZone is an IoT grow-light controller based on an ESP32-S3 that drives 4 LED channels:

- White
- Blue
- Red
- Far Red

It supports:

- **Manual mode** (direct channel/intensity control)
- **Auto mode** (PAR-target and schedule based control)
- **Sunrise/sunset simulation** (smooth spectral and intensity ramping)
- **Initial setup via ESP32 Access Point (AP)**
- **Home WiFi operation with mDNS discovery** (`heliozone.local`)
- **HTTP API** used by a Flutter mobile app (Android/iOS)
- **Real-time control and telemetry**

---

## 2) High-Level Component Architecture

```text
+---------------------+                +---------------------------+
| Flutter Mobile App  |  HTTP/JSON     |      ESP32-S3 Firmware    |
| (Android / iOS)     +--------------->+---------------------------+
|                     | <--------------+ REST API + Event Stream   |
+---------------------+   telemetry    |                           |
                                         |  Control Engine          |
                                         |  Mode Manager            |
                                         |  Schedule Engine         |
                                         |  Sensor Manager          |
                                         |  Network/Provisioning    |
                                         +------------+--------------+
                                                      |
                         +----------------------------+-------------------------+
                         |                            |                         |
                  PWM / DAC / 0-10V            RS485 Bus                  ADC / I2C
                         |                            |                         |
                4x LED Drivers                 External Sensors             PAR Sensor
          (White/Blue/Red/FarRed)        (temp/humidity/etc optional)   (light feedback)
```

---

## 3) Firmware Architecture (ESP32-S3)

Use a modular, task-based architecture (e.g., FreeRTOS tasks + message queues).

### 3.1 Core Modules

1. **Network & Provisioning Manager**
   - Boots into STA mode using saved credentials.
   - If credentials are missing/fail repeatedly, enters **Provisioning AP mode**.
   - Exposes setup endpoint in AP mode for WiFi onboarding.
   - Advertises mDNS hostname in STA mode (`heliozone.local`).

2. **HTTP API Server**
   - REST endpoints for state, control, configuration, schedule, and diagnostics.
   - Optional event channel via **Server-Sent Events (SSE)** for near real-time updates.
   - Auth token or pairing key for local security.

3. **Control Engine**
   - Converts desired channel percentages/PPFD targets into hardware outputs.
   - Maintains synchronized updates for all 4 channels.
   - Handles smoothing/interpolation for flicker-free transitions.

4. **Mode Manager**
   - State machine: `MANUAL`, `AUTO`, `SAFE`.
   - MANUAL: app-driven direct channel setpoints.
   - AUTO: schedule + sensor feedback driven setpoints.
   - SAFE: fallback on sensor/driver/network faults.

5. **Schedule Engine**
   - Stores and executes daily lighting recipes.
   - Supports sunrise/sunset ramps and multi-phase day profiles.
   - Works with timezone and NTP-synced time.

6. **Sensor Manager**
   - Reads PAR sensor at fixed interval.
   - Polls RS485 sensors (temperature, humidity, CO2, etc.) with timeout/retry.
   - Publishes sanitized sensor values to other modules.

7. **Persistence Manager**
   - Stores:
     - WiFi credentials
     - Device identity and token
     - Last mode and channel state
     - Schedules and calibration constants
   - Uses NVS/flash with versioned config schema.

8. **Hardware Abstraction Layer (HAL)**
   - LED channel abstraction over PWM/DAC + 0-10V scaling.
   - Sensor abstraction over ADC/I2C/UART-RS485.
   - Keeps application logic independent from low-level drivers.

### 3.2 Recommended Task Layout

- `task_network` (connectivity/provisioning)
- `task_http` (API handling)
- `task_control_loop` (20–100 ms loop)
- `task_schedule` (1 s loop)
- `task_sensors` (250 ms–2 s loop depending on sensor)
- `task_persistence` (debounced writes)
- `task_watchdog` (health and fail-safe)

Inter-task communication:

- **Event bus** for state changes (`MODE_CHANGED`, `WIFI_CONNECTED`, `SENSOR_UPDATED`)
- **Command queue** for deterministic control writes
- **Read-only state snapshot** for API responses

### 3.3 Control Strategy

- Internal intensity representation: `0.0 .. 1.0` per channel.
- Output mapping to driver voltage: `V_out = intensity * 10.0V`.
- Apply calibration table per channel for non-linear driver/LED behavior.
- In AUTO mode:
  - Use PAR target + spectral ratio constraints.
  - PID-lite or bounded proportional correction on global intensity.
  - Preserve relative channel spectrum while raising/lowering total output.

### 3.4 Safety & Reliability

- Failsafe defaults on boot until control loop stable.
- Limits:
  - Max ramp rate per channel (prevents abrupt spikes)
  - Max total power budget
  - Sensor stale timeout handling
- Brownout and reboot reason logging.
- Watchdog resets for hung tasks.
- Optional thermal derating from RS485 temp sensor.

---

## 4) HTTP API Design

Base URL (STA mode):

- `http://heliozone.local/api/v1`

Base URL (AP mode):

- `http://192.168.4.1/api/v1`

### 4.1 Device & Health

- `GET /device`
  - Device metadata: model, fw version, serial, uptime.
- `GET /health`
  - Health summary: wifi, sensor status, task heartbeat, safe mode.
- `GET /time`
  - Current RTC/NTP time and timezone.
- `PUT /time`
  - Set timezone and optional manual time fallback.

### 4.2 Provisioning & Network

- `POST /provisioning/wifi`
  - Body: `{ "ssid": "...", "password": "..." }`
  - Stores creds and attempts STA connection.
- `GET /network/status`
  - AP/STA mode, IP, RSSI, mDNS status.
- `POST /network/reconnect`
  - Force reconnect.

### 4.3 Mode & Light Control

- `GET /mode`
  - Returns `MANUAL` or `AUTO` (+ reason if `SAFE`).
- `PUT /mode`
  - Body: `{ "mode": "MANUAL" | "AUTO" }`
- `GET /lights/channels`
  - Returns current normalized setpoints for White/Blue/Red/FarRed.
- `PUT /lights/channels`
  - Body example:
    ```json
    {
      "white": 0.65,
      "blue": 0.30,
      "red": 0.50,
      "far_red": 0.10,
      "transition_ms": 1200
    }
    ```
- `PUT /lights/master`
  - Global dimmer preserving spectral ratios.
- `POST /lights/off`
  - Immediate or ramped shutdown.

### 4.4 Auto Mode & Schedule

- `GET /auto/config`
  - PAR target, tolerances, correction gains, safety limits.
- `PUT /auto/config`
  - Update auto-control parameters.
- `GET /schedule`
  - Full weekly/daily schedule.
- `PUT /schedule`
  - Replace schedule definition.
- `POST /schedule/preview`
  - Simulate resulting channel curve for validation.

### 4.5 Sensor Endpoints

- `GET /sensors`
  - Latest PAR + RS485 sensor values with timestamps.
- `GET /sensors/par`
  - PAR-specific telemetry + calibration info.
- `PUT /sensors/par/calibration`
  - Calibration coefficient update.

### 4.6 Real-Time Updates

- `GET /events` (SSE)
  - Events: `state`, `sensor`, `mode`, `alarm`, `network`.
  - Used by app for live UI updates without aggressive polling.

### 4.7 Security

- Pairing token issued on first setup.
- `Authorization: Bearer <token>` for protected endpoints.
- Local-network-only by default; no cloud dependency required.

---

## 5) Mobile App Architecture (Flutter)

Use clean feature-first structure.

```text
lib/
  core/
    api/               # HTTP client, auth interceptor, mDNS discovery
    models/            # shared DTOs
    storage/           # secure storage for token/device info
    state/             # app-level state and connectivity
  features/
    onboarding/        # AP join guide + WiFi provisioning flow
    dashboard/         # live status, quick controls
    manual_control/    # 4-channel sliders, master dimmer
    auto_mode/         # PAR targets, control parameters
    schedules/         # sunrise/sunset editor + profile timeline
    sensors/           # PAR + RS485 telemetry views
    settings/          # device, firmware, network, timezone
  main.dart
```

### 5.1 State Management

- Recommended: Riverpod/Bloc for predictable state.
- Keep API models separate from UI view models.
- Single source of truth for device state updated by:
  - periodic pull (`GET /device`, `/lights/channels`, `/sensors`)
  - push updates (`/events` SSE)

### 5.2 Onboarding Flow

1. User powers on device.
2. App discovers device AP (or user connects manually).
3. App calls `POST /provisioning/wifi` with home WiFi credentials.
4. Device joins home network and restarts API in STA mode.
5. App discovers `heliozone.local` (mDNS) and stores paired device profile.

### 5.3 Main Screens

- **Dashboard**: mode, current intensity, PAR, quick on/off.
- **Manual**: channel sliders + presets.
- **Auto**: target PAR, spectral presets, enable/disable auto.
- **Schedule**: sunrise/sunset curve and weekly planner.
- **Sensors**: live charts, sensor health.
- **Settings**: firmware version, timezone, WiFi, reboot/reset.

---

## 6) Communication Between Components

### 6.1 App ↔ Device

- Transport: local HTTP over WiFi.
- Discovery: mDNS (`heliozone.local`) after provisioning.
- Data patterns:
  - Command/response for configuration and control.
  - SSE stream for low-latency updates.
- Retry/backoff and local cache to tolerate brief WiFi drops.

### 6.2 Internal Firmware Communication

- Queue-based commands to control loop (deterministic ordering).
- Event bus notifications for observers (API/state/logging).
- Shared immutable snapshot object for API reads to avoid locking contention.

### 6.3 Sensor & Driver Interfaces

- PAR sensor → Sensor Manager → Control Engine (AUTO mode feedback).
- RS485 sensors → Sensor Manager → Mode/Safety logic.
- Control Engine → HAL → 0-10V outputs to LED drivers.

---

## 7) Suggested Data Models

### 7.1 Light State

```json
{
  "mode": "MANUAL",
  "channels": {
    "white": 0.60,
    "blue": 0.25,
    "red": 0.50,
    "far_red": 0.10
  },
  "master": 0.75,
  "transition_ms": 1000,
  "updated_at": "2026-03-04T13:00:00Z"
}
```

### 7.2 Sensor Snapshot

```json
{
  "par_umol_m2_s": 420.3,
  "temperature_c": 25.8,
  "humidity_rh": 61.2,
  "co2_ppm": 810,
  "timestamp": "2026-03-04T13:00:01Z",
  "stale": false
}
```

---

## 8) Implementation Phases

1. **Phase 1 (MVP firmware + app)**
   - AP provisioning, STA reconnect, mDNS
   - Manual mode, channel control, basic sensor readout
   - Flutter dashboard + manual controls

2. **Phase 2 (automation)**
   - Schedule engine with sunrise/sunset
   - AUTO mode with PAR feedback loop
   - Sensor and control calibration screens

3. **Phase 3 (hardening)**
   - Watchdog/failsafe, richer diagnostics, OTA update support
   - Improved analytics/charts and preset management

This phased approach keeps integration risk low while delivering usable control early.

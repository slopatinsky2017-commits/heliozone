#include "health_manager.h"

#include <string.h>

#include "esp_heap_caps.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "ota_manager.h"
#include "time_manager.h"
#include "wifi_manager.h"

static const char *TAG = "health_manager";

static health_snapshot_t s_health = {
    .uptime_seconds = 0,
    .free_heap_bytes = 0,
    .wifi_rssi = 0,
    .temperature_c = -1.0f,
    .last_sensor_ok = false,
    .last_sensor_ok_age_seconds = 0,
    .last_ntp_sync_epoch = 0,
    .ota_last_result = "unknown",
    .degraded = true,
};

static int64_t s_last_sensor_ok_us = 0;
static int64_t s_last_ntp_sync_epoch = 0;

void health_manager_init(void) {
    s_last_sensor_ok_us = 0;
    s_last_ntp_sync_epoch = 0;
    ESP_LOGI(TAG, "health_manager initialized");
}

void health_manager_mark_sensor_ok(void) {
    s_last_sensor_ok_us = esp_timer_get_time();
    s_health.last_sensor_ok = true;
}

void health_manager_update(void) {
    int64_t now_us = esp_timer_get_time();
    s_health.uptime_seconds = (uint32_t)(now_us / 1000000ULL);
    s_health.free_heap_bytes = (uint32_t)heap_caps_get_free_size(MALLOC_CAP_8BIT);
    s_health.wifi_rssi = wifi_manager_get_rssi();
    s_health.temperature_c = -1.0f;

    if (s_last_sensor_ok_us > 0) {
        s_health.last_sensor_ok_age_seconds = (uint32_t)((now_us - s_last_sensor_ok_us) / 1000000ULL);
        s_health.last_sensor_ok = (s_health.last_sensor_ok_age_seconds <= 5);
    } else {
        s_health.last_sensor_ok_age_seconds = 0;
        s_health.last_sensor_ok = false;
    }

    if (time_manager_is_synced()) {
        s_last_ntp_sync_epoch = (int64_t)time_manager_get_timestamp();
    }
    s_health.last_ntp_sync_epoch = s_last_ntp_sync_epoch;

    ota_manager_status_t ota_status;
    ota_manager_get_status(&ota_status);
    switch (ota_status.state) {
        case OTA_MANAGER_STATE_SUCCESS:
            snprintf(s_health.ota_last_result, sizeof(s_health.ota_last_result), "%s", "success");
            break;
        case OTA_MANAGER_STATE_FAILED:
            snprintf(s_health.ota_last_result, sizeof(s_health.ota_last_result), "%s", "failed");
            break;
        case OTA_MANAGER_STATE_IN_PROGRESS:
            snprintf(s_health.ota_last_result, sizeof(s_health.ota_last_result), "%s", "running");
            break;
        default:
            snprintf(s_health.ota_last_result, sizeof(s_health.ota_last_result), "%s", "idle");
            break;
    }

    bool sensor_bad = !s_health.last_sensor_ok;
    bool wifi_bad = wifi_manager_is_connected() && s_health.wifi_rssi < -85;
    bool heap_bad = s_health.free_heap_bytes < 60000;
    s_health.degraded = sensor_bad || wifi_bad || heap_bad;
}

void health_manager_get(health_snapshot_t *out_snapshot) {
    if (out_snapshot == NULL) {
        return;
    }
    *out_snapshot = s_health;
}

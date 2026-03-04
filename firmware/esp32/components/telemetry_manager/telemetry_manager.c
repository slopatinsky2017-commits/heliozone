#include "telemetry_manager.h"

#include <string.h>

#include "esp_log.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/semphr.h"

static const char *TAG = "telemetry_manager";

static telemetry_data_t s_data = {
    .ppfd = 0.0f,
    .dli = 0.0f,
    .target_ppfd = 0.0f,
    .target_dli = 0.0f,
    .power_percent = 0.0f,
    .sun_phase = "day",
    .uptime_seconds = 0,
    .wifi_rssi = 0,
    .cloud_factor = 1.0f,
    .active_crop = "",
    .active_stage = "",
};

static SemaphoreHandle_t s_data_lock = NULL;

void telemetry_manager_init(void) {
    if (s_data_lock == NULL) {
        s_data_lock = xSemaphoreCreateMutex();
    }
    ESP_LOGI(TAG, "telemetry_manager initialized");
}

void telemetry_manager_update(float ppfd,
                              float dli,
                              float target_ppfd,
                              float target_dli,
                              float power_percent,
                              const char *sun_phase,
                              int wifi_rssi,
                              float cloud_factor,
                              const char *active_crop,
                              const char *active_stage) {
    if (s_data_lock == NULL) {
        return;
    }

    xSemaphoreTake(s_data_lock, portMAX_DELAY);
    s_data.ppfd = ppfd;
    s_data.dli = dli;
    s_data.target_ppfd = target_ppfd;
    s_data.target_dli = target_dli;
    s_data.power_percent = power_percent;
    s_data.wifi_rssi = wifi_rssi;
    s_data.cloud_factor = cloud_factor;

    if (active_crop == NULL) {
        s_data.active_crop[0] = '\0';
    } else {
        strncpy(s_data.active_crop, active_crop, sizeof(s_data.active_crop) - 1);
        s_data.active_crop[sizeof(s_data.active_crop) - 1] = '\0';
    }

    if (active_stage == NULL) {
        s_data.active_stage[0] = '\0';
    } else {
        strncpy(s_data.active_stage, active_stage, sizeof(s_data.active_stage) - 1);
        s_data.active_stage[sizeof(s_data.active_stage) - 1] = '\0';
    }
    s_data.uptime_seconds = (uint32_t)(esp_timer_get_time() / 1000000ULL);

    if (sun_phase == NULL) {
        strncpy(s_data.sun_phase, "day", sizeof(s_data.sun_phase) - 1);
    } else {
        strncpy(s_data.sun_phase, sun_phase, sizeof(s_data.sun_phase) - 1);
    }
    s_data.sun_phase[sizeof(s_data.sun_phase) - 1] = '\0';
    xSemaphoreGive(s_data_lock);
}

void telemetry_manager_get(telemetry_data_t *out_data) {
    if (out_data == NULL || s_data_lock == NULL) {
        return;
    }

    xSemaphoreTake(s_data_lock, portMAX_DELAY);
    *out_data = s_data;
    xSemaphoreGive(s_data_lock);
}

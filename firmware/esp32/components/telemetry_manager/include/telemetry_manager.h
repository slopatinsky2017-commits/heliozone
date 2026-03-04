#pragma once

#include <stdint.h>

typedef struct {
    float ppfd;
    float dli;
    float target_ppfd;
    float target_dli;
    float power_percent;
    char sun_phase[16];
    uint32_t uptime_seconds;
    int wifi_rssi;
    float cloud_factor;
    char active_crop[32];
    char active_stage[32];
} telemetry_data_t;

void telemetry_manager_init(void);
void telemetry_manager_update(float ppfd,
                              float dli,
                              float target_ppfd,
                              float target_dli,
                              float power_percent,
                              const char *sun_phase,
                              int wifi_rssi,
                              float cloud_factor,
                              const char *active_crop,
                              const char *active_stage);
void telemetry_manager_get(telemetry_data_t *out_data);

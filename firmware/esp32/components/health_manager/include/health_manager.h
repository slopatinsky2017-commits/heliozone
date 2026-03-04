#pragma once

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    uint32_t uptime_seconds;
    uint32_t free_heap_bytes;
    int wifi_rssi;
    float temperature_c;
    bool last_sensor_ok;
    uint32_t last_sensor_ok_age_seconds;
    int64_t last_ntp_sync_epoch;
    char ota_last_result[16];
    bool degraded;
} health_snapshot_t;

void health_manager_init(void);
void health_manager_mark_sensor_ok(void);
void health_manager_update(void);
void health_manager_get(health_snapshot_t *out_snapshot);

#ifdef __cplusplus
}
#endif

#pragma once

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    bool enabled;
    int cloudiness;
    float min_factor;
    float max_factor;
    int avg_interval_s;
} cloud_engine_config_t;

typedef struct {
    float current_factor;
    float target_factor;
    bool dip_active;
    int seconds_to_next_event;
} cloud_engine_status_t;

void cloud_engine_init(void);
void cloud_engine_tick(void);
void cloud_engine_get_config(cloud_engine_config_t *out_config);
bool cloud_engine_set_config(const cloud_engine_config_t *config);
void cloud_engine_get_status(cloud_engine_status_t *out_status);
float cloud_engine_get_factor(void);

#ifdef __cplusplus
}
#endif

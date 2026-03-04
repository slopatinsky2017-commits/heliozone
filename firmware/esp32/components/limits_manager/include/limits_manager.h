#pragma once

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    float max_total_power_percent;
    float max_channel_percent[4];
    float max_ramp_rate_percent_per_sec;
    int sensor_timeout_sec;
} limits_config_t;

void limits_manager_init(void);
void limits_manager_get_config(limits_config_t *out_config);
bool limits_manager_set_config(const limits_config_t *config);

#ifdef __cplusplus
}
#endif

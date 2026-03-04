#include "limits_manager.h"

static limits_config_t s_config = {
    .max_total_power_percent = 85.0f,
    .max_channel_percent = {100.0f, 100.0f, 100.0f, 100.0f},
    .max_ramp_rate_percent_per_sec = 8.0f,
    .sensor_timeout_sec = 5,
};

static float clampf(float v, float lo, float hi) {
    if (v < lo) return lo;
    if (v > hi) return hi;
    return v;
}

void limits_manager_init(void) {}

void limits_manager_get_config(limits_config_t *out_config) {
    if (out_config == NULL) return;
    *out_config = s_config;
}

bool limits_manager_set_config(const limits_config_t *config) {
    if (config == NULL) {
        return false;
    }

    limits_config_t c = *config;
    c.max_total_power_percent = clampf(c.max_total_power_percent, 1.0f, 100.0f);
    c.max_ramp_rate_percent_per_sec = clampf(c.max_ramp_rate_percent_per_sec, 0.1f, 100.0f);
    if (c.sensor_timeout_sec < 1 || c.sensor_timeout_sec > 600) {
        return false;
    }

    for (int i = 0; i < 4; ++i) {
        c.max_channel_percent[i] = clampf(c.max_channel_percent[i], 0.0f, 100.0f);
    }

    s_config = c;
    return true;
}

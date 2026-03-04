#pragma once

#include <stdbool.h>

typedef struct {
    int sunrise_minutes;
    int sunset_minutes;
    float max_intensity; // Legacy percent peak [0..100]
    float midday_peak;   // Normalized peak [0..1]
    float ratio_white;
    float ratio_blue;
    float ratio_red;
    float ratio_far_red;
} sun_engine_config_t;

typedef struct {
    int now_minutes;
    float brightness;
    float white;
    float blue;
    float red;
    float far_red;
    float dli_scale;
    float normalized_intensity;
} sun_engine_status_t;

void sun_engine_init(void);
void sun_engine_update(int time_of_day_minutes);
void sun_engine_tick(int now_minutes); // Backward-compatible alias
void sun_engine_set_dli_scale(float dli_scale);
void sun_engine_get_config(sun_engine_config_t *out_config);
bool sun_engine_set_config(const sun_engine_config_t *config);
void sun_engine_get_status(sun_engine_status_t *out_status);

bool sun_engine_parse_hhmm(const char *text, int *out_minutes);
void sun_engine_format_hhmm(int minutes, char *out, int out_len);

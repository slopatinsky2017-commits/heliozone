#include "cloud_engine.h"

#include <stdlib.h>

#include "esp_log.h"
#include "esp_random.h"

static const char *TAG = "cloud_engine";

static cloud_engine_config_t s_config = {
    .enabled = true,
    .cloudiness = 25,
    .min_factor = 0.70f,
    .max_factor = 0.95f,
    .avg_interval_s = 180,
};

static cloud_engine_status_t s_status = {
    .current_factor = 1.0f,
    .target_factor = 1.0f,
    .dip_active = false,
    .seconds_to_next_event = 120,
};

static int s_dip_remaining_s = 0;

static float clampf(float v, float lo, float hi) {
    if (v < lo) return lo;
    if (v > hi) return hi;
    return v;
}

static int random_between(int min, int max) {
    if (max <= min) {
        return min;
    }
    uint32_t r = esp_random();
    return min + (int)(r % (uint32_t)(max - min + 1));
}

static void plan_next_event(void) {
    int base = s_config.avg_interval_s;
    int spread = base / 2;
    if (spread < 5) {
        spread = 5;
    }
    s_status.seconds_to_next_event = random_between(base - spread, base + spread);
    if (s_status.seconds_to_next_event < 5) {
        s_status.seconds_to_next_event = 5;
    }
}

void cloud_engine_init(void) {
    plan_next_event();
    ESP_LOGI(TAG, "cloud_engine initialized");
}

void cloud_engine_tick(void) {
    if (!s_config.enabled || s_config.cloudiness <= 0) {
        s_status.target_factor = 1.0f;
        s_status.dip_active = false;
        s_dip_remaining_s = 0;
        plan_next_event();
    } else {
        if (s_status.dip_active) {
            if (s_dip_remaining_s > 0) {
                s_dip_remaining_s--;
            } else {
                s_status.dip_active = false;
                s_status.target_factor = 1.0f;
                plan_next_event();
            }
        } else {
            s_status.seconds_to_next_event--;
            if (s_status.seconds_to_next_event <= 0) {
                int trigger = random_between(0, 100);
                if (trigger <= s_config.cloudiness) {
                    s_status.dip_active = true;
                    int duration = random_between(10, 60 + s_config.cloudiness);
                    s_dip_remaining_s = duration;
                    float lo = clampf(s_config.min_factor, 0.1f, 1.0f);
                    float hi = clampf(s_config.max_factor, lo, 1.0f);
                    float t = (float)(esp_random() % 1000) / 1000.0f;
                    s_status.target_factor = lo + (hi - lo) * t;
                }
                plan_next_event();
            }
        }
    }

    float max_step = 0.03f;
    if (s_status.current_factor < s_status.target_factor) {
        s_status.current_factor += max_step;
        if (s_status.current_factor > s_status.target_factor) {
            s_status.current_factor = s_status.target_factor;
        }
    } else if (s_status.current_factor > s_status.target_factor) {
        s_status.current_factor -= max_step;
        if (s_status.current_factor < s_status.target_factor) {
            s_status.current_factor = s_status.target_factor;
        }
    }

    s_status.current_factor = clampf(s_status.current_factor, 0.1f, 1.0f);
}

void cloud_engine_get_config(cloud_engine_config_t *out_config) {
    if (out_config == NULL) return;
    *out_config = s_config;
}

bool cloud_engine_set_config(const cloud_engine_config_t *config) {
    if (config == NULL) return false;
    cloud_engine_config_t c = *config;
    if (c.cloudiness < 0 || c.cloudiness > 100) return false;
    if (c.avg_interval_s < 5 || c.avg_interval_s > 7200) return false;

    c.min_factor = clampf(c.min_factor, 0.1f, 1.0f);
    c.max_factor = clampf(c.max_factor, c.min_factor, 1.0f);
    s_config = c;

    if (!s_config.enabled) {
        s_status.target_factor = 1.0f;
        s_status.dip_active = false;
        s_dip_remaining_s = 0;
    }
    plan_next_event();
    return true;
}

void cloud_engine_get_status(cloud_engine_status_t *out_status) {
    if (out_status == NULL) return;
    *out_status = s_status;
}

float cloud_engine_get_factor(void) {
    return s_status.current_factor;
}

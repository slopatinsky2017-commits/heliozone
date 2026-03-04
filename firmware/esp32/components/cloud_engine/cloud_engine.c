#include "cloud_engine.h"

#include "esp_log.h"
#include "esp_random.h"

static const char *TAG = "cloud_engine";

static cloud_engine_config_t s_config = {
    .enabled = true,
    .cloudiness = 25,
    .min_factor = 0.60f,
    .max_factor = 1.00f,
    .avg_interval_s = 90,
};

static cloud_engine_status_t s_status = {
    .current_factor = 1.0f,
    .target_factor = 1.0f,
    .dip_active = false,
    .seconds_to_next_event = 60,
};

static float clampf(float v, float lo, float hi) {
    if (v < lo) return lo;
    if (v > hi) return hi;
    return v;
}

static int random_between(int min, int max) {
    if (max <= min) return min;
    uint32_t r = esp_random();
    return min + (int)(r % (uint32_t)(max - min + 1));
}

static float random_unit(void) {
    return (float)(esp_random() % 10000U) / 10000.0f;
}

static int choose_interval_s(void) {
    // Required cloud transition cadence: 30..180 seconds.
    int min_s = 30;
    int max_s = 180;

    // Keep avg_interval_s meaningful while remaining in 30..180.
    int avg = s_config.avg_interval_s;
    if (avg < min_s) avg = min_s;
    if (avg > max_s) avg = max_s;

    int spread = 45;
    int lo = avg - spread;
    int hi = avg + spread;
    if (lo < min_s) lo = min_s;
    if (hi > max_s) hi = max_s;

    return random_between(lo, hi);
}

static void plan_next_event(void) {
    s_status.seconds_to_next_event = choose_interval_s();
}

static float choose_next_target(void) {
    // Required cloud factor bounds.
    float min_factor = clampf(s_config.min_factor, 0.6f, 1.0f);
    float max_factor = clampf(s_config.max_factor, min_factor, 1.0f);

    // Cloudiness biases the distribution toward lower factors.
    float cloudiness = clampf((float)s_config.cloudiness / 100.0f, 0.0f, 1.0f);
    float r = random_unit();
    float skewed = 1.0f - (r * (0.25f + 0.75f * cloudiness));

    float target = min_factor + (max_factor - min_factor) * skewed;
    return clampf(target, 0.6f, 1.0f);
}

void cloud_engine_init(void) {
    s_status.current_factor = 1.0f;
    s_status.target_factor = 1.0f;
    s_status.dip_active = false;
    plan_next_event();
    ESP_LOGI(TAG, "cloud_engine initialized");
}

void cloud_engine_tick(void) {
    if (!s_config.enabled || s_config.cloudiness <= 0) {
        s_status.target_factor = 1.0f;
        s_status.dip_active = false;
        s_status.seconds_to_next_event = choose_interval_s();
    } else {
        s_status.seconds_to_next_event--;
        if (s_status.seconds_to_next_event <= 0) {
            s_status.target_factor = choose_next_target();
            s_status.dip_active = (s_status.target_factor < 0.99f);
            plan_next_event();
        }
    }

    // Smooth random-walk-like movement to avoid jumps.
    const float max_step = 0.005f;  // ~=0.5% per second.
    float delta = s_status.target_factor - s_status.current_factor;
    float step = clampf(delta * 0.15f, -max_step, max_step);
    s_status.current_factor = clampf(s_status.current_factor + step, 0.6f, 1.0f);
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

    c.min_factor = clampf(c.min_factor, 0.6f, 1.0f);
    c.max_factor = clampf(c.max_factor, c.min_factor, 1.0f);
    s_config = c;

    if (!s_config.enabled) {
        s_status.target_factor = 1.0f;
        s_status.dip_active = false;
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

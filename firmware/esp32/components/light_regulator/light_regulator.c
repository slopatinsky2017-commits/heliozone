#include "light_regulator.h"

#include "esp_log.h"

static const char *TAG = "light_regulator";

static float s_target_ppfd = 450.0f;
static float s_kp = 0.08f;  // proportional gain in brightness % per PPFD error unit
static float s_last_ppfd = 0.0f;
static float s_last_control_output = 0.0f;

static float clampf(float v, float lo, float hi) {
    if (v < lo) {
        return lo;
    }
    if (v > hi) {
        return hi;
    }
    return v;
}

void light_regulator_init(void) {
    ESP_LOGI(TAG, "light_regulator initialized with target=%.1f", s_target_ppfd);
}

void light_regulator_set_target(float target) {
    s_target_ppfd = clampf(target, 0.0f, 3000.0f);
}

float light_regulator_get_target(void) {
    return s_target_ppfd;
}

float light_regulator_update(float measured_ppfd, float base_brightness) {
    float error = s_target_ppfd - measured_ppfd;
    float adjustment = s_kp * error;
    float output = clampf(base_brightness + adjustment, 0.0f, 100.0f);

    s_last_ppfd = measured_ppfd;
    s_last_control_output = output;
    return output;
}

void light_regulator_get_status(light_regulator_status_t *out_status) {
    if (out_status == NULL) {
        return;
    }

    out_status->ppfd = s_last_ppfd;
    out_status->target = s_target_ppfd;
    out_status->control_output = s_last_control_output;
}

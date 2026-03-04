#include "dli_manager.h"

#include "esp_log.h"

static const char *TAG = "dli_manager";

static float s_current_dli = 0.0f;
static float s_target_dli = 10.0f;
static float s_output_scale = 1.0f;
static int s_last_minute = -1;

static float clampf(float v, float lo, float hi) {
    if (v < lo) {
        return lo;
    }
    if (v > hi) {
        return hi;
    }
    return v;
}

void dli_manager_init(void) {
    ESP_LOGI(TAG, "dli_manager initialized target=%.2f mol/day", s_target_dli);
}

void dli_manager_set_target(float target_dli) {
    s_target_dli = clampf(target_dli, 0.1f, 100.0f);
}

float dli_manager_get_target(void) {
    return s_target_dli;
}

void dli_manager_tick(float ppfd, int now_minutes) {
    if (s_last_minute >= 0 && now_minutes < s_last_minute) {
        // Midnight rollover reset.
        s_current_dli = 0.0f;
        s_output_scale = 1.0f;
        ESP_LOGI(TAG, "midnight reset: DLI cleared");
    }
    s_last_minute = now_minutes;

    // DLI increment each second: PPFD [umol/m2/s] * 1 sec / 1,000,000.
    s_current_dli += clampf(ppfd, 0.0f, 5000.0f) / 1000000.0f;

    if (s_current_dli >= s_target_dli) {
        // Reduce gradually once target dose is met.
        s_output_scale = clampf(s_output_scale - 0.01f, 0.15f, 1.0f);
    } else {
        // Recover gradually while below target.
        s_output_scale = clampf(s_output_scale + 0.002f, 0.15f, 1.0f);
    }
}

void dli_manager_get_status(dli_status_t *out_status) {
    if (out_status == NULL) {
        return;
    }

    out_status->current_dli = s_current_dli;
    out_status->target_dli = s_target_dli;
    out_status->output_scale = s_output_scale;
}

float dli_manager_get_current(void) {
    return s_current_dli;
}

float dli_manager_get_output_scale(void) {
    return s_output_scale;
}

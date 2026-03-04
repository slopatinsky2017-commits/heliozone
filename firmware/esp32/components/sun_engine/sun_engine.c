#include "sun_engine.h"

#include <math.h>
#include <stdio.h>
#include <string.h>

#include "esp_log.h"

static const char *TAG = "sun_engine";

static sun_engine_config_t s_config = {
    .sunrise_minutes = 6 * 60,
    .sunset_minutes = 18 * 60,
    .max_intensity = 80.0f,
    .ratio_white = 0.40f,
    .ratio_blue = 0.20f,
    .ratio_red = 0.30f,
    .ratio_far_red = 0.10f,
};

static sun_engine_status_t s_status = {
    .now_minutes = 0,
    .brightness = 0.0f,
    .white = 0.0f,
    .blue = 0.0f,
    .red = 0.0f,
    .far_red = 0.0f,
    .dli_scale = 1.0f,
};

static float clampf(float value, float min, float max) {
    if (value < min) {
        return min;
    }
    if (value > max) {
        return max;
    }
    return value;
}

static float cosine_ease(float t) {
    return 0.5f - 0.5f * cosf((float)M_PI * clampf(t, 0.0f, 1.0f));
}

static void normalize_ratios(sun_engine_config_t *cfg) {
    float sum = cfg->ratio_white + cfg->ratio_blue + cfg->ratio_red + cfg->ratio_far_red;
    if (sum <= 0.0001f) {
        cfg->ratio_white = 0.40f;
        cfg->ratio_blue = 0.20f;
        cfg->ratio_red = 0.30f;
        cfg->ratio_far_red = 0.10f;
        return;
    }

    cfg->ratio_white /= sum;
    cfg->ratio_blue /= sum;
    cfg->ratio_red /= sum;
    cfg->ratio_far_red /= sum;
}

static float calculate_brightness(int now_minutes) {
    int sunrise = s_config.sunrise_minutes;
    int sunset = s_config.sunset_minutes;

    if (sunset <= sunrise) {
        return 0.0f;
    }

    if (now_minutes < sunrise || now_minutes > sunset) {
        return 0.0f;
    }

    int photoperiod = sunset - sunrise;
    int ramp = photoperiod / 4;
    if (ramp < 30) {
        ramp = 30;
    }
    if (ramp > 120) {
        ramp = 120;
    }

    int sunrise_end = sunrise + ramp;
    int sunset_start = sunset - ramp;

    if (now_minutes <= sunrise_end) {
        float t = (float)(now_minutes - sunrise) / (float)ramp;
        return s_config.max_intensity * cosine_ease(t);
    }

    if (now_minutes < sunset_start) {
        return s_config.max_intensity;
    }

    float t = (float)(now_minutes - sunset_start) / (float)ramp;
    return s_config.max_intensity * (1.0f - cosine_ease(t));
}

void sun_engine_init(void) {
    normalize_ratios(&s_config);
    ESP_LOGI(TAG, "sun_engine initialized");
}

void sun_engine_set_dli_scale(float dli_scale) {
    s_status.dli_scale = clampf(dli_scale, 0.0f, 1.0f);
}

void sun_engine_tick(int now_minutes) {
    s_status.now_minutes = now_minutes;

    float base = clampf(calculate_brightness(now_minutes), 0.0f, 100.0f);
    s_status.brightness = base * s_status.dli_scale;
    s_status.white = s_status.brightness * s_config.ratio_white;
    s_status.blue = s_status.brightness * s_config.ratio_blue;
    s_status.red = s_status.brightness * s_config.ratio_red;
    s_status.far_red = s_status.brightness * s_config.ratio_far_red;
}

void sun_engine_get_config(sun_engine_config_t *out_config) {
    if (out_config == NULL) {
        return;
    }
    *out_config = s_config;
}

bool sun_engine_set_config(const sun_engine_config_t *config) {
    if (config == NULL) {
        return false;
    }

    if (config->sunrise_minutes < 0 || config->sunrise_minutes >= 24 * 60) {
        return false;
    }
    if (config->sunset_minutes < 0 || config->sunset_minutes >= 24 * 60) {
        return false;
    }
    if (config->sunset_minutes <= config->sunrise_minutes) {
        return false;
    }

    sun_engine_config_t candidate = *config;
    candidate.max_intensity = clampf(candidate.max_intensity, 0.0f, 100.0f);
    normalize_ratios(&candidate);

    s_config = candidate;
    return true;
}

void sun_engine_get_status(sun_engine_status_t *out_status) {
    if (out_status == NULL) {
        return;
    }
    *out_status = s_status;
}

bool sun_engine_parse_hhmm(const char *text, int *out_minutes) {
    if (text == NULL || out_minutes == NULL) {
        return false;
    }

    int hh = -1;
    int mm = -1;
    if (sscanf(text, "%d:%d", &hh, &mm) != 2) {
        return false;
    }
    if (hh < 0 || hh > 23 || mm < 0 || mm > 59) {
        return false;
    }

    *out_minutes = hh * 60 + mm;
    return true;
}

void sun_engine_format_hhmm(int minutes, char *out, int out_len) {
    if (out == NULL || out_len <= 0) {
        return;
    }

    if (minutes < 0) {
        minutes = 0;
    }
    minutes %= (24 * 60);

    int hh = minutes / 60;
    int mm = minutes % 60;
    snprintf(out, out_len, "%02d:%02d", hh, mm);
}

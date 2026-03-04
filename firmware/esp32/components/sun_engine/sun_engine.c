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
    .midday_peak = 0.80f,
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
    .normalized_intensity = 0.0f,
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

static bool calculate_day_progress(int now_minutes, float *out_progress) {
    int sunrise = s_config.sunrise_minutes;
    int sunset = s_config.sunset_minutes;

    if (out_progress == NULL || sunset <= sunrise) {
        return false;
    }

    if (now_minutes < sunrise || now_minutes > sunset) {
        return false;
    }

    float progress = (float)(now_minutes - sunrise) / (float)(sunset - sunrise);
    *out_progress = clampf(progress, 0.0f, 1.0f);
    return true;
}

static float calculate_normalized_intensity_from_progress(float day_progress) {
    // sunrise->0, midday->0.5, sunset->1
    // cosine-based dome: 0 at sunrise/sunset, 1 at midday.
    float centered = day_progress - 0.5f;
    float intensity = cosf(centered * (float)M_PI);
    return clampf(intensity, 0.0f, 1.0f);
}

static void calculate_dynamic_ratios(float day_progress, float *white, float *blue, float *red, float *far_red) {
    float midday_bias = calculate_normalized_intensity_from_progress(day_progress);
    float edge_bias = 1.0f - midday_bias;

    // Sunrise/sunset: warmer spectrum (red/far-red heavier).
    // Midday: cooler/fuller spectrum (white/blue heavier).
    float w = 0.30f + 0.30f * midday_bias;
    float b = 0.08f + 0.22f * midday_bias;
    float r = 0.44f - 0.20f * midday_bias;
    float fr = 0.18f - 0.12f * midday_bias;

    // Blend with configured ratios to preserve compatibility/tuning behavior.
    w = 0.7f * w + 0.3f * s_config.ratio_white;
    b = 0.7f * b + 0.3f * s_config.ratio_blue;
    r = 0.7f * r + 0.3f * s_config.ratio_red;
    fr = 0.7f * fr + 0.3f * s_config.ratio_far_red;

    float sum = w + b + r + fr;
    if (sum <= 0.0001f) {
        w = 0.40f;
        b = 0.20f;
        r = 0.30f;
        fr = 0.10f;
        sum = 1.0f;
    }

    *white = w / sum;
    *blue = b / sum;
    *red = r / sum;
    *far_red = fr / sum;
    (void)edge_bias;
}

void sun_engine_init(void) {
    normalize_ratios(&s_config);
    s_config.midday_peak = clampf(s_config.midday_peak, 0.0f, 1.0f);
    s_config.max_intensity = s_config.midday_peak * 100.0f;
    ESP_LOGI(TAG, "sun_engine initialized");
}

void sun_engine_set_dli_scale(float dli_scale) {
    s_status.dli_scale = clampf(dli_scale, 0.0f, 1.0f);
}

void sun_engine_update(int time_of_day_minutes) {
    s_status.now_minutes = time_of_day_minutes;

    float day_progress = 0.0f;
    float normalized_intensity = 0.0f;
    if (calculate_day_progress(time_of_day_minutes, &day_progress)) {
        normalized_intensity = calculate_normalized_intensity_from_progress(day_progress);
    }

    s_status.normalized_intensity = normalized_intensity;

    float base_brightness = normalized_intensity * s_config.midday_peak * 100.0f;
    s_status.brightness = clampf(base_brightness, 0.0f, 100.0f) * s_status.dli_scale;

    float ratio_white = s_config.ratio_white;
    float ratio_blue = s_config.ratio_blue;
    float ratio_red = s_config.ratio_red;
    float ratio_far_red = s_config.ratio_far_red;

    if (normalized_intensity > 0.0f) {
        calculate_dynamic_ratios(day_progress, &ratio_white, &ratio_blue, &ratio_red, &ratio_far_red);
    }

    s_status.white = s_status.brightness * ratio_white;
    s_status.blue = s_status.brightness * ratio_blue;
    s_status.red = s_status.brightness * ratio_red;
    s_status.far_red = s_status.brightness * ratio_far_red;
}

void sun_engine_tick(int now_minutes) {
    sun_engine_update(now_minutes);
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

    if (candidate.midday_peak <= 0.0f) {
        candidate.midday_peak = candidate.max_intensity / 100.0f;
    }
    candidate.midday_peak = clampf(candidate.midday_peak, 0.0f, 1.0f);
    candidate.max_intensity = candidate.midday_peak * 100.0f;

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

#include "cloud_engine.h"
#include "device_identity.h"
#include "dli_manager.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "health_manager.h"
#include "helio_controller.h"
#include "http_api.h"
#include "led_controller.h"
#include "light_regulator.h"
#include "mqtt_manager.h"
#include "ota_manager.h"
#include "sensor_manager.h"
#include "sun_engine.h"
#include "telemetry_manager.h"
#include "time_manager.h"
#include "wifi_manager.h"

static const char *TAG = "heliozone_main";

static float clampf(float v, float lo, float hi) {
    if (v < lo) {
        return lo;
    }
    if (v > hi) {
        return hi;
    }
    return v;
}

static const char *detect_sun_phase(const sun_engine_config_t *cfg, int now_minutes) {
    int sunrise = cfg->sunrise_minutes;
    int sunset = cfg->sunset_minutes;
    int ramp = (sunset - sunrise) / 4;
    if (ramp < 30) {
        ramp = 30;
    }
    if (ramp > 120) {
        ramp = 120;
    }

    if (now_minutes < sunrise || now_minutes > sunset) {
        return "night";
    }
    if (now_minutes <= sunrise + ramp) {
        return "sunrise";
    }
    if (now_minutes >= sunset - ramp) {
        return "sunset";
    }
    return "day";
}

static void task_sensor_loop(void *arg) {
    (void)arg;
    while (1) {
        sensor_manager_poll();
        health_manager_mark_sensor_ok();
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}

static void task_sun_loop(void *arg) {
    (void)arg;
    while (1) {
        int now_minutes = time_manager_get_minutes_of_day();
        float ppfd = sensor_manager_get_ppfd();

        dli_manager_tick(ppfd, now_minutes);
        sun_engine_set_dli_scale(dli_manager_get_output_scale());
        sun_engine_update(now_minutes);
        cloud_engine_tick();

        sun_engine_status_t sun;
        sun_engine_config_t sun_cfg;
        sun_engine_get_status(&sun);
        sun_engine_get_config(&sun_cfg);

        float cloud_factor = cloud_engine_get_factor();
        float sun_curve_brightness =
            sun.normalized_intensity * sun_cfg.midday_peak * 100.0f * sun.dli_scale;
        float cloudy_brightness = clampf(sun_curve_brightness * cloud_factor, 0.0f, 100.0f);
        float regulated_brightness = light_regulator_update(ppfd, cloudy_brightness);

        float scale = 0.0f;
        if (cloudy_brightness > 0.01f) {
            scale = regulated_brightness / cloudy_brightness;
        }

        led_controller_set_channel_percent(LED_CHANNEL_WHITE, clampf(sun.white * scale, 0.0f, 100.0f));
        led_controller_set_channel_percent(LED_CHANNEL_BLUE, clampf(sun.blue * scale, 0.0f, 100.0f));
        led_controller_set_channel_percent(LED_CHANNEL_RED, clampf(sun.red * scale, 0.0f, 100.0f));
        led_controller_set_channel_percent(LED_CHANNEL_FAR_RED, clampf(sun.far_red * scale, 0.0f, 100.0f));
        led_controller_set_power(regulated_brightness > 0.0f);

        telemetry_manager_update(ppfd,
                                 dli_manager_get_current(),
                                 light_regulator_get_target(),
                                 dli_manager_get_target(),
                                 regulated_brightness,
                                 detect_sun_phase(&sun_cfg, now_minutes),
                                 wifi_manager_get_rssi());

        health_manager_update();

        telemetry_data_t telemetry;
        telemetry_manager_get(&telemetry);
        mqtt_manager_publish_telemetry(&telemetry);

        health_snapshot_t health;
        health_manager_get(&health);
        mqtt_manager_publish_health(&health);

        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}

static void task_heartbeat(void *arg) {
    (void)arg;
    while (1) {
        sun_engine_status_t sun;
        light_regulator_status_t reg;
        dli_status_t dli;
        telemetry_data_t telemetry;
        sun_engine_get_status(&sun);
        light_regulator_get_status(&reg);
        dli_manager_get_status(&dli);
        telemetry_manager_get(&telemetry);

        ESP_LOGI(TAG,
                 "heartbeat mode=%s connected=%s ip=%s power=%s sun=%.1f%% ppfd=%.1f target=%.1f out=%.1f%% dli=%.2f/%.2f phase=%s",
                 wifi_manager_get_mode() == WIFI_MANAGER_MODE_AP ? "AP" : "STA",
                 wifi_manager_is_connected() ? "yes" : "no",
                 wifi_manager_get_ip(),
                 led_controller_is_powered() ? "on" : "off",
                 sun.brightness,
                 reg.ppfd,
                 reg.target,
                 reg.control_output,
                 dli.current_dli,
                 dli.target_dli,
                 telemetry.sun_phase);

        vTaskDelay(pdMS_TO_TICKS(5000));
    }
}

void app_main(void) {
    ESP_LOGI(TAG, "Starting HelioZone basic firmware");

    led_controller_init();
    sensor_manager_init();
    sun_engine_init();
    cloud_engine_init();
    light_regulator_init();
    dli_manager_init();
    telemetry_manager_init();
    health_manager_init();
    wifi_manager_init();
    wifi_manager_start();
    device_identity_init();
    ota_manager_init();
    mqtt_manager_init();
    time_manager_init();
    time_manager_start();
    http_api_start();

    // Start higher-level orchestration after base subsystems are up
    helio_controller_start();

    xTaskCreate(task_sensor_loop, "task_sensor_loop", 4096, NULL, 5, NULL);
    xTaskCreate(task_sun_loop, "task_sun_loop", 4096, NULL, 5, NULL);
    xTaskCreate(task_heartbeat, "task_heartbeat", 3072, NULL, 3, NULL);
}
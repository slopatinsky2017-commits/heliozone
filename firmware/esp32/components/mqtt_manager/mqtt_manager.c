#include "mqtt_manager.h"

#include <stdio.h>
#include <string.h>

#include "cJSON.h"
#include "cloud_engine.h"
#include "device_identity.h"
#include "dli_manager.h"
#include "esp_event.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "health_manager.h"
#include "led_controller.h"
#include "light_regulator.h"
#include "mqtt_client.h"
#include "sun_engine.h"

#ifndef HZ_MQTT_BROKER_URI
#define HZ_MQTT_BROKER_URI ""
#endif

static const char *TAG = "mqtt_manager";

static esp_mqtt_client_handle_t s_client = NULL;
static bool s_connected = false;
static bool s_enabled = false;
static char s_topic_prefix[96] = {0};
static char s_device_cmd_topic[128] = {0};
static char s_zone_cmd_topic[128] = {0};
static char s_ack_topic[128] = {0};
static char s_status_topic[128] = {0};
static char s_telemetry_topic[128] = {0};
static char s_health_topic[128] = {0};

static void publish_ack(bool ok, const char *source_topic, const char *error_message) {
    if (!s_connected || s_client == NULL) {
        return;
    }

    char payload[256] = {0};
    snprintf(payload,
             sizeof(payload),
             "{\"device_id\":\"%s\",\"ok\":%s,\"source_topic\":\"%s\",\"error\":\"%s\",\"ts\":%llu}",
             device_identity_get_id(),
             ok ? "true" : "false",
             source_topic != NULL ? source_topic : "",
             error_message != NULL ? error_message : "",
             (unsigned long long)(esp_timer_get_time() / 1000ULL));

    esp_mqtt_client_publish(s_client, s_ack_topic, payload, 0, 1, 0);
}

static bool apply_command_json(const char *json, char *error_out, size_t error_out_len) {
    cJSON *root = cJSON_Parse(json);
    if (root == NULL) {
        snprintf(error_out, error_out_len, "%s", "invalid json");
        return false;
    }

    cJSON *power = cJSON_GetObjectItem(root, "power");
    if (cJSON_IsBool(power)) {
        led_controller_set_power(cJSON_IsTrue(power));
    }

    cJSON *target_ppfd = cJSON_GetObjectItem(root, "target_ppfd");
    if (cJSON_IsNumber(target_ppfd)) {
        light_regulator_set_target((float)target_ppfd->valuedouble);
    }

    cJSON *target_dli = cJSON_GetObjectItem(root, "target_dli");
    if (cJSON_IsNumber(target_dli)) {
        dli_manager_set_target((float)target_dli->valuedouble);
    }

    cJSON *channels = cJSON_GetObjectItem(root, "channels");
    if (cJSON_IsObject(channels)) {
        cJSON *white = cJSON_GetObjectItem(channels, "white");
        cJSON *blue = cJSON_GetObjectItem(channels, "blue");
        cJSON *red = cJSON_GetObjectItem(channels, "red");
        cJSON *far_red = cJSON_GetObjectItem(channels, "far_red");
        if (cJSON_IsNumber(white)) {
            led_controller_set_channel_percent(LED_CHANNEL_WHITE, (float)white->valuedouble);
        }
        if (cJSON_IsNumber(blue)) {
            led_controller_set_channel_percent(LED_CHANNEL_BLUE, (float)blue->valuedouble);
        }
        if (cJSON_IsNumber(red)) {
            led_controller_set_channel_percent(LED_CHANNEL_RED, (float)red->valuedouble);
        }
        if (cJSON_IsNumber(far_red)) {
            led_controller_set_channel_percent(LED_CHANNEL_FAR_RED, (float)far_red->valuedouble);
        }
    }

    cJSON *sun_cfg_json = cJSON_GetObjectItem(root, "sun_config");
    if (cJSON_IsObject(sun_cfg_json)) {
        sun_engine_config_t cfg;
        sun_engine_get_config(&cfg);

        cJSON *sunrise = cJSON_GetObjectItem(sun_cfg_json, "sunrise_time");
        cJSON *sunset = cJSON_GetObjectItem(sun_cfg_json, "sunset_time");
        cJSON *max_intensity = cJSON_GetObjectItem(sun_cfg_json, "max_intensity");
        cJSON *midday_peak = cJSON_GetObjectItem(sun_cfg_json, "midday_peak");

        if (cJSON_IsString(sunrise) && sunrise->valuestring != NULL) {
            if (!sun_engine_parse_hhmm(sunrise->valuestring, &cfg.sunrise_minutes)) {
                cJSON_Delete(root);
                snprintf(error_out, error_out_len, "%s", "invalid sunrise_time");
                return false;
            }
        }
        if (cJSON_IsString(sunset) && sunset->valuestring != NULL) {
            if (!sun_engine_parse_hhmm(sunset->valuestring, &cfg.sunset_minutes)) {
                cJSON_Delete(root);
                snprintf(error_out, error_out_len, "%s", "invalid sunset_time");
                return false;
            }
        }
        if (cJSON_IsNumber(max_intensity)) {
            cfg.max_intensity = (float)max_intensity->valuedouble;
        }
        if (cJSON_IsNumber(midday_peak)) {
            cfg.midday_peak = (float)midday_peak->valuedouble;
        }
        if (!sun_engine_set_config(&cfg)) {
            cJSON_Delete(root);
            snprintf(error_out, error_out_len, "%s", "invalid sun_config");
            return false;
        }
    }

    cJSON_Delete(root);
    snprintf(error_out, error_out_len, "%s", "");
    return true;
}

static void handle_command_message(const char *topic, const char *payload) {
    char err[96] = {0};
    bool ok = apply_command_json(payload, err, sizeof(err));
    publish_ack(ok, topic, ok ? "" : err);
}

static void mqtt_event_handler(void *handler_args,
                               esp_event_base_t base,
                               int32_t event_id,
                               void *event_data) {
    (void)handler_args;
    (void)base;

    esp_mqtt_event_handle_t event = event_data;
    switch ((esp_mqtt_event_id_t)event_id) {
        case MQTT_EVENT_CONNECTED:
            s_connected = true;
            ESP_LOGI(TAG, "mqtt connected");
            esp_mqtt_client_subscribe(s_client, s_device_cmd_topic, 1);
            esp_mqtt_client_subscribe(s_client, s_zone_cmd_topic, 1);
            esp_mqtt_client_publish(s_client, s_status_topic, "online", 0, 1, 1);
            break;
        case MQTT_EVENT_DISCONNECTED:
            s_connected = false;
            ESP_LOGW(TAG, "mqtt disconnected");
            break;
        case MQTT_EVENT_DATA: {
            char topic[128] = {0};
            char data[512] = {0};
            int tlen = event->topic_len < (int)sizeof(topic) - 1 ? event->topic_len : (int)sizeof(topic) - 1;
            int dlen = event->data_len < (int)sizeof(data) - 1 ? event->data_len : (int)sizeof(data) - 1;
            memcpy(topic, event->topic, tlen);
            memcpy(data, event->data, dlen);
            topic[tlen] = '\0';
            data[dlen] = '\0';

            if (strcmp(topic, s_device_cmd_topic) == 0 || strstr(topic, "/cmd") != NULL) {
                handle_command_message(topic, data);
            }
            break;
        }
        default:
            break;
    }
}

void mqtt_manager_init(void) {
    if (strlen(HZ_MQTT_BROKER_URI) == 0) {
        ESP_LOGI(TAG, "MQTT disabled (no broker configured)");
        s_enabled = false;
        return;
    }

    snprintf(s_topic_prefix, sizeof(s_topic_prefix), "heliozone/%s", device_identity_get_id());
    snprintf(s_telemetry_topic, sizeof(s_telemetry_topic), "%s/telemetry", s_topic_prefix);
    snprintf(s_health_topic, sizeof(s_health_topic), "%s/health", s_topic_prefix);
    snprintf(s_status_topic, sizeof(s_status_topic), "%s/status", s_topic_prefix);
    snprintf(s_ack_topic, sizeof(s_ack_topic), "%s/status/ack", s_topic_prefix);
    snprintf(s_device_cmd_topic, sizeof(s_device_cmd_topic), "%s/cmd", s_topic_prefix);
    snprintf(s_zone_cmd_topic, sizeof(s_zone_cmd_topic), "heliozone/zone/+/cmd");

    esp_mqtt_client_config_t mqtt_cfg = {
        .broker.address.uri = HZ_MQTT_BROKER_URI,
        .session.last_will.topic = s_status_topic,
        .session.last_will.msg = "offline",
        .session.last_will.qos = 1,
        .session.last_will.retain = 1,
    };

    s_client = esp_mqtt_client_init(&mqtt_cfg);
    if (s_client == NULL) {
        ESP_LOGE(TAG, "failed to init mqtt client");
        s_enabled = false;
        return;
    }

    esp_mqtt_client_register_event(s_client, ESP_EVENT_ANY_ID, mqtt_event_handler, NULL);
    esp_mqtt_client_start(s_client);
    s_enabled = true;
}

void mqtt_manager_publish_telemetry(const telemetry_data_t *telemetry) {
    if (!s_enabled || !s_connected || s_client == NULL || telemetry == NULL) {
        return;
    }

    cloud_engine_config_t cloud_cfg;
    cloud_engine_get_config(&cloud_cfg);

    char payload[512] = {0};
    snprintf(payload,
             sizeof(payload),
             "{\"device_id\":\"%s\",\"ppfd\":%.2f,\"dli\":%.4f,\"target_ppfd\":%.2f,\"target_dli\":%.2f,\"power_percent\":%.2f,\"sun_phase\":\"%s\",\"uptime\":%u,\"wifi_rssi\":%d,\"cloud_factor\":%.3f,\"cloudiness\":%d,\"active_crop\":\"%s\",\"active_stage\":\"%s\"}",
             device_identity_get_id(),
             telemetry->ppfd,
             telemetry->dli,
             telemetry->target_ppfd,
             telemetry->target_dli,
             telemetry->power_percent,
             telemetry->sun_phase,
             telemetry->uptime_seconds,
             telemetry->wifi_rssi,
             telemetry->cloud_factor,
             cloud_cfg.cloudiness,
             telemetry->active_crop,
             telemetry->active_stage);

    esp_mqtt_client_publish(s_client, s_telemetry_topic, payload, 0, 0, 0);
}

bool mqtt_manager_is_enabled(void) {
    return s_enabled;
}

void mqtt_manager_publish_health(const health_snapshot_t *health) {
    if (!s_enabled || !s_connected || s_client == NULL || health == NULL) {
        return;
    }

    char payload[512] = {0};
    snprintf(payload,
             sizeof(payload),
             "{\"device_id\":\"%s\",\"uptime\":%u,\"heap\":%u,\"wifi_rssi\":%d,\"temperature_c\":%.2f,\"last_sensor_ok\":%s,\"last_sensor_ok_age_seconds\":%u,\"last_ntp_sync\":%lld,\"ota_last_result\":\"%s\",\"degraded\":%s}",
             device_identity_get_id(),
             health->uptime_seconds,
             health->free_heap_bytes,
             health->wifi_rssi,
             health->temperature_c,
             health->last_sensor_ok ? "true" : "false",
             health->last_sensor_ok_age_seconds,
             (long long)health->last_ntp_sync_epoch,
             health->ota_last_result,
             health->degraded ? "true" : "false");

    esp_mqtt_client_publish(s_client, s_health_topic, payload, 0, 0, 0);
}

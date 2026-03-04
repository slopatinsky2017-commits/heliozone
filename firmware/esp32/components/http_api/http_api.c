#include "http_api.h"

#include <string.h>
#include <stdio.h>

#include "cJSON.h"
#include "cloud_engine.h"
#include "device_identity.h"
#include "dli_manager.h"
#include "esp_http_server.h"
#include "esp_log.h"
#include "esp_random.h"
#include "led_controller.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "health_manager.h"
#include "light_regulator.h"
#include "ota_manager.h"
#include "nvs.h"
#include "sensor_manager.h"
#include "sun_engine.h"
#include "telemetry_manager.h"
#include "time_manager.h"
#include "wifi_manager.h"

static const char *TAG = "http_api";

static esp_err_t send_json(httpd_req_t *req, cJSON *json) {
    char *resp = cJSON_PrintUnformatted(json);
    if (resp == NULL) {
        httpd_resp_send_err(req, HTTPD_500_INTERNAL_SERVER_ERROR, "json encode failed");
        return ESP_FAIL;
    }

    httpd_resp_set_type(req, "application/json");
    httpd_resp_sendstr(req, resp);
    cJSON_free(resp);
    return ESP_OK;
}

static esp_err_t recv_json(httpd_req_t *req, cJSON **json_out) {
    char buf[512] = {0};
    int total = req->content_len;

    if (total <= 0 || total >= (int)sizeof(buf)) {
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "invalid body length");
        return ESP_FAIL;
    }

    int received = 0;
    while (received < total) {
        int r = httpd_req_recv(req, buf + received, total - received);
        if (r <= 0) {
            httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "failed to read body");
            return ESP_FAIL;
        }
        received += r;
    }

    cJSON *json = cJSON_ParseWithLength(buf, received);
    if (json == NULL) {
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "invalid json");
        return ESP_FAIL;
    }

    *json_out = json;
    return ESP_OK;
}


#define AUTH_TOKEN_NAMESPACE "auth"
#define AUTH_TOKEN_KEY "token"

static char s_auth_token[65] = {0};

static bool load_or_generate_auth_token(void) {
    nvs_handle_t nvs;
    esp_err_t err = nvs_open(AUTH_TOKEN_NAMESPACE, NVS_READWRITE, &nvs);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "failed to open nvs for auth token: %s", esp_err_to_name(err));
        return false;
    }

    size_t token_len = sizeof(s_auth_token);
    err = nvs_get_str(nvs, AUTH_TOKEN_KEY, s_auth_token, &token_len);
    if (err == ESP_OK && s_auth_token[0] != '\0') {
        nvs_close(nvs);
        return true;
    }

    const char *hex = "0123456789abcdef";
    for (size_t i = 0; i < 64; ++i) {
        uint32_t r = esp_random();
        s_auth_token[i] = hex[r & 0x0F];
    }
    s_auth_token[64] = '\0';

    err = nvs_set_str(nvs, AUTH_TOKEN_KEY, s_auth_token);
    if (err == ESP_OK) {
        err = nvs_commit(nvs);
    }
    nvs_close(nvs);

    if (err != ESP_OK) {
        ESP_LOGE(TAG, "failed to persist auth token: %s", esp_err_to_name(err));
        return false;
    }

    return true;
}

static bool is_pairing_mode(void) {
    return wifi_manager_get_mode() == WIFI_MANAGER_MODE_AP;
}

static esp_err_t require_bearer_auth(httpd_req_t *req) {
    if (s_auth_token[0] == '\0') {
        httpd_resp_send_err(req, HTTPD_500_INTERNAL_SERVER_ERROR, "auth token unavailable");
        return ESP_FAIL;
    }

    size_t auth_len = httpd_req_get_hdr_value_len(req, "Authorization");
    if (auth_len == 0 || auth_len >= 160) {
        httpd_resp_set_status(req, "401 Unauthorized");
        httpd_resp_send_err(req, HTTPD_401_UNAUTHORIZED, "missing authorization");
        return ESP_FAIL;
    }

    char auth[160] = {0};
    if (httpd_req_get_hdr_value_str(req, "Authorization", auth, sizeof(auth)) != ESP_OK) {
        httpd_resp_set_status(req, "401 Unauthorized");
        httpd_resp_send_err(req, HTTPD_401_UNAUTHORIZED, "invalid authorization");
        return ESP_FAIL;
    }

    const char *prefix = "Bearer ";
    if (strncmp(auth, prefix, strlen(prefix)) != 0) {
        httpd_resp_set_status(req, "401 Unauthorized");
        httpd_resp_send_err(req, HTTPD_401_UNAUTHORIZED, "invalid authorization");
        return ESP_FAIL;
    }

    const char *token = auth + strlen(prefix);
    if (strcmp(token, s_auth_token) != 0) {
        httpd_resp_set_status(req, "401 Unauthorized");
        httpd_resp_send_err(req, HTTPD_401_UNAUTHORIZED, "unauthorized");
        return ESP_FAIL;
    }

    return ESP_OK;
}

static esp_err_t auth_pair_post_handler(httpd_req_t *req) {
    if (!is_pairing_mode()) {
        httpd_resp_send_err(req, HTTPD_403_FORBIDDEN, "pairing mode is disabled");
        return ESP_FAIL;
    }

    cJSON *root = cJSON_CreateObject();
    cJSON_AddBoolToObject(root, "ok", true);
    cJSON_AddStringToObject(root, "token", s_auth_token);
    cJSON_AddStringToObject(root, "device_id", device_identity_get_id());
    cJSON_AddStringToObject(root, "pairing_mode", "ap");

    esp_err_t err = send_json(req, root);
    cJSON_Delete(root);
    return err;
}

static void append_sun_config(cJSON *root, const sun_engine_config_t *cfg) {
    char sunrise[6] = {0};
    char sunset[6] = {0};
    sun_engine_format_hhmm(cfg->sunrise_minutes, sunrise, sizeof(sunrise));
    sun_engine_format_hhmm(cfg->sunset_minutes, sunset, sizeof(sunset));

    cJSON *config = cJSON_AddObjectToObject(root, "sun_config");
    cJSON_AddStringToObject(config, "sunrise_time", sunrise);
    cJSON_AddStringToObject(config, "sunset_time", sunset);
    cJSON_AddNumberToObject(config, "max_intensity", cfg->max_intensity);

    cJSON *ratios = cJSON_AddObjectToObject(config, "channel_ratios");
    cJSON_AddNumberToObject(ratios, "white", cfg->ratio_white);
    cJSON_AddNumberToObject(ratios, "blue", cfg->ratio_blue);
    cJSON_AddNumberToObject(ratios, "red", cfg->ratio_red);
    cJSON_AddNumberToObject(ratios, "far_red", cfg->ratio_far_red);
}

static void append_par_json(cJSON *root) {
    cJSON *par = cJSON_AddObjectToObject(root, "par");
    cJSON_AddNumberToObject(par, "ppfd", sensor_manager_get_ppfd());
    cJSON_AddNumberToObject(par, "target", light_regulator_get_target());
}

static void append_dli_json(cJSON *root) {
    cJSON *dli = cJSON_AddObjectToObject(root, "dli");
    cJSON_AddNumberToObject(dli, "current_dli", dli_manager_get_current());
    cJSON_AddNumberToObject(dli, "target_dli", dli_manager_get_target());
}

static void append_health_json(cJSON *root) {
    health_snapshot_t health;
    health_manager_get(&health);

    cJSON *health_json = cJSON_AddObjectToObject(root, "health");
    cJSON_AddNumberToObject(health_json, "uptime", health.uptime_seconds);
    cJSON_AddNumberToObject(health_json, "heap", health.free_heap_bytes);
    cJSON_AddNumberToObject(health_json, "wifi_rssi", health.wifi_rssi);
    cJSON_AddNumberToObject(health_json, "temperature_c", health.temperature_c);
    cJSON_AddBoolToObject(health_json, "last_sensor_ok", health.last_sensor_ok);
    cJSON_AddNumberToObject(health_json, "last_sensor_ok_age_seconds", health.last_sensor_ok_age_seconds);
    cJSON_AddNumberToObject(health_json, "last_ntp_sync", (double)health.last_ntp_sync_epoch);
    cJSON_AddStringToObject(health_json, "ota_last_result", health.ota_last_result);
    cJSON_AddBoolToObject(health_json, "degraded", health.degraded);
}

static esp_err_t health_get_handler(httpd_req_t *req) {
    cJSON *root = cJSON_CreateObject();
    cJSON_AddStringToObject(root, "device_id", device_identity_get_id());
    append_health_json(root);

    esp_err_t err = send_json(req, root);
    cJSON_Delete(root);
    return err;
}

static void append_cloud_json(cJSON *root) {
    cloud_engine_config_t cfg;
    cloud_engine_status_t status;
    cloud_engine_get_config(&cfg);
    cloud_engine_get_status(&status);

    cJSON *cloud = cJSON_AddObjectToObject(root, "cloud");
    cJSON_AddBoolToObject(cloud, "enabled", cfg.enabled);
    cJSON_AddNumberToObject(cloud, "cloudiness", cfg.cloudiness);
    cJSON_AddNumberToObject(cloud, "min_factor", cfg.min_factor);
    cJSON_AddNumberToObject(cloud, "max_factor", cfg.max_factor);
    cJSON_AddNumberToObject(cloud, "avg_interval_s", cfg.avg_interval_s);
    cJSON_AddNumberToObject(cloud, "current_factor", status.current_factor);
    cJSON_AddBoolToObject(cloud, "dip_active", status.dip_active);
}

static esp_err_t cloud_get_handler(httpd_req_t *req) {
    cJSON *root = cJSON_CreateObject();
    append_cloud_json(root);

    esp_err_t err = send_json(req, root);
    cJSON_Delete(root);
    return err;
}

static esp_err_t cloud_post_handler(httpd_req_t *req) {
    if (require_bearer_auth(req) != ESP_OK) {
        return ESP_FAIL;
    }

    cJSON *root = NULL;
    if (recv_json(req, &root) != ESP_OK) {
        return ESP_FAIL;
    }

    cloud_engine_config_t cfg;
    cloud_engine_get_config(&cfg);

    cJSON *enabled = cJSON_GetObjectItem(root, "enabled");
    cJSON *cloudiness = cJSON_GetObjectItem(root, "cloudiness");
    cJSON *min_factor = cJSON_GetObjectItem(root, "min_factor");
    cJSON *max_factor = cJSON_GetObjectItem(root, "max_factor");
    cJSON *avg_interval_s = cJSON_GetObjectItem(root, "avg_interval_s");

    if (cJSON_IsBool(enabled)) {
        cfg.enabled = cJSON_IsTrue(enabled);
    }
    if (cJSON_IsNumber(cloudiness)) {
        cfg.cloudiness = cloudiness->valueint;
    }
    if (cJSON_IsNumber(min_factor)) {
        cfg.min_factor = (float)min_factor->valuedouble;
    }
    if (cJSON_IsNumber(max_factor)) {
        cfg.max_factor = (float)max_factor->valuedouble;
    }
    if (cJSON_IsNumber(avg_interval_s)) {
        cfg.avg_interval_s = avg_interval_s->valueint;
    }
    cJSON_Delete(root);

    if (!cloud_engine_set_config(&cfg)) {
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "invalid cloud config");
        return ESP_FAIL;
    }

    cJSON *resp = cJSON_CreateObject();
    cJSON_AddBoolToObject(resp, "ok", true);
    append_cloud_json(resp);
    esp_err_t err = send_json(req, resp);
    cJSON_Delete(resp);
    return err;
}

static esp_err_t status_get_handler(httpd_req_t *req) {
    sensor_snapshot_t sensors = sensor_manager_get_snapshot();
    sun_engine_status_t sun_status;
    sun_engine_config_t sun_config;
    sun_engine_get_status(&sun_status);
    sun_engine_get_config(&sun_config);

    cJSON *root = cJSON_CreateObject();
    cJSON_AddStringToObject(root, "device", "heliozone");
    cJSON_AddStringToObject(root, "device_id", device_identity_get_id());
    cJSON_AddStringToObject(root,
                            "wifi_mode",
                            wifi_manager_get_mode() == WIFI_MANAGER_MODE_AP ? "AP" : "STA");
    cJSON_AddBoolToObject(root, "wifi_connected", wifi_manager_is_connected());
    cJSON_AddStringToObject(root, "ip", wifi_manager_get_ip());
    cJSON_AddBoolToObject(root, "power", led_controller_is_powered());

    cJSON *channels = cJSON_AddObjectToObject(root, "channels");
    cJSON_AddNumberToObject(channels, "white", led_controller_get_channel_percent(LED_CHANNEL_WHITE));
    cJSON_AddNumberToObject(channels, "blue", led_controller_get_channel_percent(LED_CHANNEL_BLUE));
    cJSON_AddNumberToObject(channels, "red", led_controller_get_channel_percent(LED_CHANNEL_RED));
    cJSON_AddNumberToObject(channels, "far_red", led_controller_get_channel_percent(LED_CHANNEL_FAR_RED));

    cJSON *sensor_json = cJSON_AddObjectToObject(root, "sensors");
    cJSON_AddNumberToObject(sensor_json, "par_umol_m2_s", sensors.par_umol_m2_s);
    cJSON_AddNumberToObject(sensor_json, "temperature_c", sensors.temperature_c);
    cJSON_AddNumberToObject(sensor_json, "humidity_rh", sensors.humidity_rh);

    cJSON *sun = cJSON_AddObjectToObject(root, "sun");
    cJSON_AddNumberToObject(sun, "brightness", sun_status.brightness);
    cJSON_AddNumberToObject(sun, "white", sun_status.white);
    cJSON_AddNumberToObject(sun, "blue", sun_status.blue);
    cJSON_AddNumberToObject(sun, "red", sun_status.red);
    cJSON_AddNumberToObject(sun, "far_red", sun_status.far_red);
    cJSON_AddNumberToObject(sun, "dli_scale", sun_status.dli_scale);

    append_sun_config(root, &sun_config);
    append_par_json(root);
    append_dli_json(root);
    append_health_json(root);
    append_cloud_json(root);

    esp_err_t err = send_json(req, root);
    cJSON_Delete(root);
    return err;
}

static esp_err_t device_info_get_handler(httpd_req_t *req) {
    cJSON *root = cJSON_CreateObject();
    cJSON_AddStringToObject(root, "device", "heliozone");
    cJSON_AddStringToObject(root, "device_id", device_identity_get_id());

    esp_err_t err = send_json(req, root);
    cJSON_Delete(root);
    return err;
}

static const char *ota_state_to_string(ota_manager_state_t state) {
    switch (state) {
        case OTA_MANAGER_STATE_IDLE:
            return "idle";
        case OTA_MANAGER_STATE_IN_PROGRESS:
            return "in_progress";
        case OTA_MANAGER_STATE_SUCCESS:
            return "success";
        case OTA_MANAGER_STATE_FAILED:
            return "failed";
        default:
            return "unknown";
    }
}

static esp_err_t ota_status_get_handler(httpd_req_t *req) {
    ota_manager_status_t status;
    ota_manager_get_status(&status);

    cJSON *root = cJSON_CreateObject();
    cJSON_AddStringToObject(root, "state", ota_state_to_string(status.state));
    cJSON_AddNumberToObject(root, "progress_percent", status.progress_percent);
    cJSON_AddStringToObject(root, "version", status.version);
    cJSON_AddStringToObject(root, "message", status.message);
    cJSON_AddStringToObject(root, "last_error", status.last_error);
    cJSON_AddBoolToObject(root, "reboot_scheduled", status.reboot_scheduled);
    cJSON_AddBoolToObject(root, "pending_boot_validation", status.pending_boot_validation);

    esp_err_t err = send_json(req, root);
    cJSON_Delete(root);
    return err;
}

static esp_err_t ota_update_post_handler(httpd_req_t *req) {
    if (require_bearer_auth(req) != ESP_OK) {
        return ESP_FAIL;
    }

    cJSON *root = NULL;
    if (recv_json(req, &root) != ESP_OK) {
        return ESP_FAIL;
    }

    cJSON *url = cJSON_GetObjectItem(root, "url");
    cJSON *sha256 = cJSON_GetObjectItem(root, "sha256");
    cJSON *version = cJSON_GetObjectItem(root, "version");
    if (!cJSON_IsString(url) || url->valuestring == NULL || url->valuestring[0] == '\0') {
        cJSON_Delete(root);
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "missing url string");
        return ESP_FAIL;
    }
    if (!cJSON_IsString(sha256) || sha256->valuestring == NULL || sha256->valuestring[0] == '\0') {
        cJSON_Delete(root);
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "missing sha256 string");
        return ESP_FAIL;
    }
    if (!cJSON_IsString(version) || version->valuestring == NULL || version->valuestring[0] == '\0') {
        cJSON_Delete(root);
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "missing version string");
        return ESP_FAIL;
    }

    char error_message[96] = {0};
    bool started = ota_manager_start_update(url->valuestring,
                                            sha256->valuestring,
                                            version->valuestring,
                                            error_message,
                                            sizeof(error_message));
    cJSON_Delete(root);

    if (!started) {
        const char *msg = error_message[0] != '\0' ? error_message : "failed to start ota";
        cJSON *error = cJSON_CreateObject();
        cJSON_AddBoolToObject(error, "ok", false);
        cJSON_AddStringToObject(error, "error", msg);
        if (strcmp(msg, "ota already in progress") == 0) {
            httpd_resp_set_status(req, "409 Conflict");
        } else {
            httpd_resp_set_status(req, "400 Bad Request");
        }
        esp_err_t err = send_json(req, error);
        cJSON_Delete(error);
        return err;
    }

    cJSON *resp = cJSON_CreateObject();
    cJSON_AddBoolToObject(resp, "ok", true);
    cJSON_AddStringToObject(resp, "message", "ota update started");
    esp_err_t err = send_json(req, resp);
    cJSON_Delete(resp);
    return err;
}

static esp_err_t par_get_handler(httpd_req_t *req) {
    cJSON *root = cJSON_CreateObject();
    cJSON_AddNumberToObject(root, "ppfd", sensor_manager_get_ppfd());
    cJSON_AddNumberToObject(root, "target", light_regulator_get_target());

    esp_err_t err = send_json(req, root);
    cJSON_Delete(root);
    return err;
}

static esp_err_t par_target_post_handler(httpd_req_t *req) {
    if (require_bearer_auth(req) != ESP_OK) {
        return ESP_FAIL;
    }

    cJSON *root = NULL;
    if (recv_json(req, &root) != ESP_OK) {
        return ESP_FAIL;
    }

    cJSON *target = cJSON_GetObjectItem(root, "target");
    if (!cJSON_IsNumber(target)) {
        cJSON_Delete(root);
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "missing target number");
        return ESP_FAIL;
    }

    light_regulator_set_target((float)target->valuedouble);
    cJSON_Delete(root);

    cJSON *resp = cJSON_CreateObject();
    cJSON_AddNumberToObject(resp, "ppfd", sensor_manager_get_ppfd());
    cJSON_AddNumberToObject(resp, "target", light_regulator_get_target());
    esp_err_t err = send_json(req, resp);
    cJSON_Delete(resp);
    return err;
}

static esp_err_t dli_get_handler(httpd_req_t *req) {
    cJSON *root = cJSON_CreateObject();
    cJSON_AddNumberToObject(root, "current_dli", dli_manager_get_current());
    cJSON_AddNumberToObject(root, "target_dli", dli_manager_get_target());

    esp_err_t err = send_json(req, root);
    cJSON_Delete(root);
    return err;
}

static esp_err_t dli_target_post_handler(httpd_req_t *req) {
    if (require_bearer_auth(req) != ESP_OK) {
        return ESP_FAIL;
    }

    cJSON *root = NULL;
    if (recv_json(req, &root) != ESP_OK) {
        return ESP_FAIL;
    }

    cJSON *target_dli = cJSON_GetObjectItem(root, "target_dli");
    if (!cJSON_IsNumber(target_dli)) {
        cJSON_Delete(root);
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "missing target_dli number");
        return ESP_FAIL;
    }

    dli_manager_set_target((float)target_dli->valuedouble);
    cJSON_Delete(root);

    cJSON *resp = cJSON_CreateObject();
    cJSON_AddNumberToObject(resp, "current_dli", dli_manager_get_current());
    cJSON_AddNumberToObject(resp, "target_dli", dli_manager_get_target());
    esp_err_t err = send_json(req, resp);
    cJSON_Delete(resp);
    return err;
}


static esp_err_t time_get_handler(httpd_req_t *req) {
    cJSON *root = cJSON_CreateObject();
    cJSON_AddNumberToObject(root, "timestamp", (double)time_manager_get_timestamp());
    cJSON_AddStringToObject(root, "timezone", time_manager_get_timezone());

    esp_err_t err = send_json(req, root);
    cJSON_Delete(root);
    return err;
}

static esp_err_t stream_get_handler(httpd_req_t *req) {
    httpd_resp_set_type(req, "text/event-stream");
    httpd_resp_set_hdr(req, "Cache-Control", "no-cache");
    httpd_resp_set_hdr(req, "Connection", "keep-alive");
    httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");

    TickType_t last_data_sent = xTaskGetTickCount();
    TickType_t last_ping_sent = xTaskGetTickCount();

    while (1) {
        TickType_t now = xTaskGetTickCount();

        if ((now - last_data_sent) >= pdMS_TO_TICKS(1000)) {
            telemetry_data_t t;
            telemetry_manager_get(&t);

            char payload[512] = {0};
            health_snapshot_t h;
            health_manager_get(&h);

            cloud_engine_config_t cloud_cfg;
            cloud_engine_get_config(&cloud_cfg);

            snprintf(payload,
                     sizeof(payload),
                     "data: {\"ppfd\":%.2f,\"dli\":%.4f,\"target_ppfd\":%.2f,\"target_dli\":%.2f,\"power_percent\":%.2f,\"sun_phase\":\"%s\",\"uptime\":%u,\"wifi_rssi\":%d,\"cloud_factor\":%.3f,\"cloudiness\":%d,\"health\":{\"heap\":%u,\"last_sensor_ok\":%s,\"last_sensor_ok_age_seconds\":%u,\"last_ntp_sync\":%lld,\"ota_last_result\":\"%s\",\"degraded\":%s}}\n\n",
                     t.ppfd,
                     t.dli,
                     t.target_ppfd,
                     t.target_dli,
                     t.power_percent,
                     t.sun_phase,
                     t.uptime_seconds,
                     t.wifi_rssi,
                     cloud_engine_get_factor(),
                     cloud_cfg.cloudiness,
                     h.free_heap_bytes,
                     h.last_sensor_ok ? "true" : "false",
                     h.last_sensor_ok_age_seconds,
                     (long long)h.last_ntp_sync_epoch,
                     h.ota_last_result,
                     h.degraded ? "true" : "false");

            if (httpd_resp_send_chunk(req, payload, HTTPD_RESP_USE_STRLEN) != ESP_OK) {
                break;
            }
            last_data_sent = now;
        }

        if ((now - last_ping_sent) >= pdMS_TO_TICKS(15000)) {
            if (httpd_resp_send_chunk(req, ": keepalive\n\n", HTTPD_RESP_USE_STRLEN) != ESP_OK) {
                break;
            }
            last_ping_sent = now;
        }

        vTaskDelay(pdMS_TO_TICKS(200));
    }

    httpd_resp_sendstr_chunk(req, NULL);
    return ESP_OK;
}

static esp_err_t sun_status_get_handler(httpd_req_t *req) {
    sun_engine_status_t sun_status;
    sun_engine_config_t sun_config;
    sun_engine_get_status(&sun_status);
    sun_engine_get_config(&sun_config);

    cJSON *root = cJSON_CreateObject();
    cJSON_AddNumberToObject(root, "now_minutes", sun_status.now_minutes);
    cJSON_AddNumberToObject(root, "brightness", sun_status.brightness);
    cJSON_AddNumberToObject(root, "white", sun_status.white);
    cJSON_AddNumberToObject(root, "blue", sun_status.blue);
    cJSON_AddNumberToObject(root, "red", sun_status.red);
    cJSON_AddNumberToObject(root, "far_red", sun_status.far_red);
    cJSON_AddNumberToObject(root, "dli_scale", sun_status.dli_scale);
    append_sun_config(root, &sun_config);

    esp_err_t err = send_json(req, root);
    cJSON_Delete(root);
    return err;
}

static esp_err_t sun_config_post_handler(httpd_req_t *req) {
    if (require_bearer_auth(req) != ESP_OK) {
        return ESP_FAIL;
    }

    cJSON *root = NULL;
    if (recv_json(req, &root) != ESP_OK) {
        return ESP_FAIL;
    }

    sun_engine_config_t cfg;
    sun_engine_get_config(&cfg);

    cJSON *sunrise = cJSON_GetObjectItem(root, "sunrise_time");
    cJSON *sunset = cJSON_GetObjectItem(root, "sunset_time");
    cJSON *max_intensity = cJSON_GetObjectItem(root, "max_intensity");
    cJSON *ratios = cJSON_GetObjectItem(root, "channel_ratios");

    if (cJSON_IsString(sunrise) && sunrise->valuestring != NULL) {
        if (!sun_engine_parse_hhmm(sunrise->valuestring, &cfg.sunrise_minutes)) {
            cJSON_Delete(root);
            httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "invalid sunrise_time");
            return ESP_FAIL;
        }
    }

    if (cJSON_IsString(sunset) && sunset->valuestring != NULL) {
        if (!sun_engine_parse_hhmm(sunset->valuestring, &cfg.sunset_minutes)) {
            cJSON_Delete(root);
            httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "invalid sunset_time");
            return ESP_FAIL;
        }
    }

    if (cJSON_IsNumber(max_intensity)) {
        cfg.max_intensity = (float)max_intensity->valuedouble;
    }

    if (cJSON_IsObject(ratios)) {
        cJSON *white = cJSON_GetObjectItem(ratios, "white");
        cJSON *blue = cJSON_GetObjectItem(ratios, "blue");
        cJSON *red = cJSON_GetObjectItem(ratios, "red");
        cJSON *far_red = cJSON_GetObjectItem(ratios, "far_red");

        if (cJSON_IsNumber(white)) {
            cfg.ratio_white = (float)white->valuedouble;
        }
        if (cJSON_IsNumber(blue)) {
            cfg.ratio_blue = (float)blue->valuedouble;
        }
        if (cJSON_IsNumber(red)) {
            cfg.ratio_red = (float)red->valuedouble;
        }
        if (cJSON_IsNumber(far_red)) {
            cfg.ratio_far_red = (float)far_red->valuedouble;
        }
    }

    cJSON_Delete(root);

    if (!sun_engine_set_config(&cfg)) {
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "invalid sun config");
        return ESP_FAIL;
    }

    cJSON *resp = cJSON_CreateObject();
    cJSON_AddBoolToObject(resp, "ok", true);
    append_sun_config(resp, &cfg);
    esp_err_t err = send_json(req, resp);
    cJSON_Delete(resp);
    return err;
}

static esp_err_t control_power_post_handler(httpd_req_t *req) {
    if (require_bearer_auth(req) != ESP_OK) {
        return ESP_FAIL;
    }

    cJSON *root = NULL;
    if (recv_json(req, &root) != ESP_OK) {
        return ESP_FAIL;
    }

    cJSON *power = cJSON_GetObjectItem(root, "power");
    if (!cJSON_IsBool(power)) {
        cJSON_Delete(root);
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "missing power bool");
        return ESP_FAIL;
    }

    led_controller_set_power(cJSON_IsTrue(power));
    cJSON_Delete(root);

    cJSON *resp = cJSON_CreateObject();
    cJSON_AddBoolToObject(resp, "ok", true);
    cJSON_AddBoolToObject(resp, "power", led_controller_is_powered());
    esp_err_t err = send_json(req, resp);
    cJSON_Delete(resp);
    return err;
}

static void set_channel_if_present(cJSON *root, const char *name, led_channel_t channel) {
    cJSON *node = cJSON_GetObjectItem(root, name);
    if (cJSON_IsNumber(node)) {
        led_controller_set_channel_percent(channel, (float)node->valuedouble);
    }
}

static esp_err_t control_channels_post_handler(httpd_req_t *req) {
    if (require_bearer_auth(req) != ESP_OK) {
        return ESP_FAIL;
    }

    cJSON *root = NULL;
    if (recv_json(req, &root) != ESP_OK) {
        return ESP_FAIL;
    }

    set_channel_if_present(root, "white", LED_CHANNEL_WHITE);
    set_channel_if_present(root, "blue", LED_CHANNEL_BLUE);
    set_channel_if_present(root, "red", LED_CHANNEL_RED);
    set_channel_if_present(root, "far_red", LED_CHANNEL_FAR_RED);
    cJSON_Delete(root);

    cJSON *resp = cJSON_CreateObject();
    cJSON_AddBoolToObject(resp, "ok", true);
    cJSON *channels = cJSON_AddObjectToObject(resp, "channels");
    cJSON_AddNumberToObject(channels, "white", led_controller_get_channel_percent(LED_CHANNEL_WHITE));
    cJSON_AddNumberToObject(channels, "blue", led_controller_get_channel_percent(LED_CHANNEL_BLUE));
    cJSON_AddNumberToObject(channels, "red", led_controller_get_channel_percent(LED_CHANNEL_RED));
    cJSON_AddNumberToObject(channels, "far_red", led_controller_get_channel_percent(LED_CHANNEL_FAR_RED));
    esp_err_t err = send_json(req, resp);
    cJSON_Delete(resp);
    return err;
}

void http_api_start(void) {
    httpd_config_t config = HTTPD_DEFAULT_CONFIG();
    httpd_handle_t server = NULL;

    if (!load_or_generate_auth_token()) {
        ESP_LOGE(TAG, "failed to initialize local auth token");
        return;
    }

    if (httpd_start(&server, &config) != ESP_OK) {
        ESP_LOGE(TAG, "failed to start HTTP server");
        return;
    }

    httpd_uri_t status_uri = {.uri = "/api/v1/status", .method = HTTP_GET, .handler = status_get_handler};
    httpd_uri_t power_uri = {.uri = "/api/v1/control/power", .method = HTTP_POST, .handler = control_power_post_handler};
    httpd_uri_t channels_uri = {.uri = "/api/v1/control/channels", .method = HTTP_POST, .handler = control_channels_post_handler};
    httpd_uri_t sun_status_uri = {.uri = "/api/v1/sun/status", .method = HTTP_GET, .handler = sun_status_get_handler};
    httpd_uri_t sun_config_uri = {.uri = "/api/v1/sun/config", .method = HTTP_POST, .handler = sun_config_post_handler};
    httpd_uri_t par_uri = {.uri = "/api/v1/par", .method = HTTP_GET, .handler = par_get_handler};
    httpd_uri_t par_target_uri = {.uri = "/api/v1/par/target", .method = HTTP_POST, .handler = par_target_post_handler};
    httpd_uri_t dli_uri = {.uri = "/api/v1/dli", .method = HTTP_GET, .handler = dli_get_handler};
    httpd_uri_t dli_target_uri = {.uri = "/api/v1/dli/target", .method = HTTP_POST, .handler = dli_target_post_handler};
    httpd_uri_t time_uri = {.uri = "/api/v1/time", .method = HTTP_GET, .handler = time_get_handler};
    httpd_uri_t stream_uri = {.uri = "/api/v1/stream", .method = HTTP_GET, .handler = stream_get_handler};
    httpd_uri_t device_info_uri = {.uri = "/api/v1/device/info", .method = HTTP_GET, .handler = device_info_get_handler};
    httpd_uri_t ota_update_uri = {.uri = "/api/v1/ota/update", .method = HTTP_POST, .handler = ota_update_post_handler};
    httpd_uri_t ota_status_uri = {.uri = "/api/v1/ota/status", .method = HTTP_GET, .handler = ota_status_get_handler};
    httpd_uri_t auth_pair_uri = {.uri = "/api/v1/auth/pair", .method = HTTP_POST, .handler = auth_pair_post_handler};
    httpd_uri_t health_uri = {.uri = "/api/v1/health", .method = HTTP_GET, .handler = health_get_handler};
    httpd_uri_t cloud_get_uri = {.uri = "/api/v1/cloud", .method = HTTP_GET, .handler = cloud_get_handler};
    httpd_uri_t cloud_post_uri = {.uri = "/api/v1/cloud", .method = HTTP_POST, .handler = cloud_post_handler};

    httpd_register_uri_handler(server, &status_uri);
    httpd_register_uri_handler(server, &power_uri);
    httpd_register_uri_handler(server, &channels_uri);
    httpd_register_uri_handler(server, &sun_status_uri);
    httpd_register_uri_handler(server, &sun_config_uri);
    httpd_register_uri_handler(server, &par_uri);
    httpd_register_uri_handler(server, &par_target_uri);
    httpd_register_uri_handler(server, &dli_uri);
    httpd_register_uri_handler(server, &dli_target_uri);
    httpd_register_uri_handler(server, &time_uri);
    httpd_register_uri_handler(server, &stream_uri);
    httpd_register_uri_handler(server, &device_info_uri);
    httpd_register_uri_handler(server, &ota_update_uri);
    httpd_register_uri_handler(server, &ota_status_uri);
    httpd_register_uri_handler(server, &auth_pair_uri);
    httpd_register_uri_handler(server, &health_uri);
    httpd_register_uri_handler(server, &cloud_get_uri);
    httpd_register_uri_handler(server, &cloud_post_uri);

    ESP_LOGI(TAG, "HTTP API started");
}

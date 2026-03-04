#include "device_identity.h"

#include <stdio.h>
#include <string.h>

#include "esp_err.h"
#include "esp_log.h"
#include "esp_mac.h"
#include "nvs.h"

#define DEVICE_IDENTITY_NAMESPACE "device"
#define DEVICE_IDENTITY_KEY "id"
#define DEVICE_IDENTITY_MAX_LEN 24

static const char *TAG = "device_identity";
static char s_device_id[DEVICE_IDENTITY_MAX_LEN] = "unknown";

static void format_device_id_from_mac(char *out, size_t out_len) {
    uint8_t mac[6] = {0};
    esp_read_mac(mac, ESP_MAC_WIFI_STA);
    snprintf(out,
             out_len,
             "HZ-%02X%02X%02X%02X%02X%02X",
             mac[0],
             mac[1],
             mac[2],
             mac[3],
             mac[4],
             mac[5]);
}

bool device_identity_init(void) {
    nvs_handle_t nvs;
    esp_err_t err = nvs_open(DEVICE_IDENTITY_NAMESPACE, NVS_READWRITE, &nvs);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "nvs_open failed: %s", esp_err_to_name(err));
        format_device_id_from_mac(s_device_id, sizeof(s_device_id));
        return false;
    }

    size_t id_len = sizeof(s_device_id);
    err = nvs_get_str(nvs, DEVICE_IDENTITY_KEY, s_device_id, &id_len);
    if (err == ESP_OK && s_device_id[0] != '\0') {
        ESP_LOGI(TAG, "loaded device id: %s", s_device_id);
        nvs_close(nvs);
        return true;
    }

    format_device_id_from_mac(s_device_id, sizeof(s_device_id));
    err = nvs_set_str(nvs, DEVICE_IDENTITY_KEY, s_device_id);
    if (err == ESP_OK) {
        err = nvs_commit(nvs);
    }

    if (err != ESP_OK) {
        ESP_LOGW(TAG, "failed to persist device id, using runtime value: %s", s_device_id);
        nvs_close(nvs);
        return false;
    }

    ESP_LOGI(TAG, "generated device id: %s", s_device_id);
    nvs_close(nvs);
    return true;
}

const char *device_identity_get_id(void) {
    return s_device_id;
}

#include "wifi_manager.h"

#include <string.h>

#include "esp_event.h"
#include "esp_log.h"
#include "esp_netif.h"
#include "esp_wifi.h"
#include "mdns.h"
#include "nvs_flash.h"

#define HZ_MAX_STA_RETRIES 5
#define HZ_AP_SSID "HelioZone-Setup"
#define HZ_AP_PASSWORD "heliozone123"
#define HZ_STA_SSID ""
#define HZ_STA_PASSWORD ""

static const char *TAG = "wifi_manager";

static wifi_manager_mode_t s_mode = WIFI_MANAGER_MODE_AP;
static bool s_connected = false;
static int s_retry_count = 0;
static char s_ip_addr[16] = "0.0.0.0";

static void start_mdns(void) {
    mdns_init();
    mdns_hostname_set("heliozone");
    mdns_instance_name_set("HelioZone Controller");
    ESP_LOGI(TAG, "mDNS started at heliozone.local");
}

static void start_ap_mode(void) {
    wifi_config_t ap_cfg = {
        .ap = {
            .ssid = HZ_AP_SSID,
            .password = HZ_AP_PASSWORD,
            .ssid_len = strlen(HZ_AP_SSID),
            .max_connection = 4,
            .authmode = WIFI_AUTH_WPA2_PSK,
        },
    };

    if (strlen(HZ_AP_PASSWORD) == 0) {
        ap_cfg.ap.authmode = WIFI_AUTH_OPEN;
    }

    esp_wifi_set_mode(WIFI_MODE_AP);
    esp_wifi_set_config(WIFI_IF_AP, &ap_cfg);
    esp_wifi_start();

    s_mode = WIFI_MANAGER_MODE_AP;
    s_connected = true;
    strncpy(s_ip_addr, "192.168.4.1", sizeof(s_ip_addr) - 1);
    s_ip_addr[sizeof(s_ip_addr) - 1] = '\0';
    ESP_LOGI(TAG, "AP mode enabled (SSID: %s)", HZ_AP_SSID);
}

static void start_sta_mode(void) {
    wifi_config_t sta_cfg = {
        .sta = {
            .threshold.authmode = WIFI_AUTH_WPA2_PSK,
        },
    };

    strncpy((char *)sta_cfg.sta.ssid, HZ_STA_SSID, sizeof(sta_cfg.sta.ssid) - 1);
    strncpy((char *)sta_cfg.sta.password, HZ_STA_PASSWORD, sizeof(sta_cfg.sta.password) - 1);

    esp_wifi_set_mode(WIFI_MODE_STA);
    esp_wifi_set_config(WIFI_IF_STA, &sta_cfg);
    esp_wifi_start();
    esp_wifi_connect();

    s_mode = WIFI_MANAGER_MODE_STA;
    s_connected = false;
    ESP_LOGI(TAG, "STA mode enabled");
}

static void wifi_event_handler(void *arg,
                               esp_event_base_t event_base,
                               int32_t event_id,
                               void *event_data) {
    (void)arg;
    (void)event_data;

    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
        esp_wifi_connect();
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {
        s_connected = false;
        if (s_retry_count < HZ_MAX_STA_RETRIES) {
            s_retry_count++;
            esp_wifi_connect();
            ESP_LOGW(TAG, "STA disconnected, retry %d/%d", s_retry_count, HZ_MAX_STA_RETRIES);
        } else {
            ESP_LOGW(TAG, "STA failed, switching to AP mode");
            start_ap_mode();
        }
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
        ip_event_got_ip_t *event = (ip_event_got_ip_t *)event_data;
        snprintf(s_ip_addr, sizeof(s_ip_addr), IPSTR, IP2STR(&event->ip_info.ip));
        s_connected = true;
        s_retry_count = 0;
        ESP_LOGI(TAG, "STA connected with IP: %s", s_ip_addr);
        start_mdns();
    }
}

void wifi_manager_init(void) {
    esp_netif_init();
    esp_event_loop_create_default();
    esp_netif_create_default_wifi_sta();
    esp_netif_create_default_wifi_ap();

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    esp_wifi_init(&cfg);

    esp_event_handler_instance_register(WIFI_EVENT,
                                        ESP_EVENT_ANY_ID,
                                        &wifi_event_handler,
                                        NULL,
                                        NULL);
    esp_event_handler_instance_register(IP_EVENT,
                                        IP_EVENT_STA_GOT_IP,
                                        &wifi_event_handler,
                                        NULL,
                                        NULL);

    ESP_LOGI(TAG, "wifi_manager initialized");
}

void wifi_manager_start(void) {
    nvs_flash_init();

    if (strlen(HZ_STA_SSID) == 0) {
        start_ap_mode();
        return;
    }

    start_sta_mode();
}

bool wifi_manager_is_connected(void) {
    return s_connected;
}

const char *wifi_manager_get_ip(void) {
    return s_ip_addr;
}

wifi_manager_mode_t wifi_manager_get_mode(void) {
    return s_mode;
}

int wifi_manager_get_rssi(void) {
    if (s_mode != WIFI_MANAGER_MODE_STA || !s_connected) {
        return 0;
    }

    wifi_ap_record_t ap_info;
    if (esp_wifi_sta_get_ap_info(&ap_info) != ESP_OK) {
        return 0;
    }

    return ap_info.rssi;
}

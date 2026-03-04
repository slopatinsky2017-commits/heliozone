#pragma once

#include <stdbool.h>

typedef enum {
    WIFI_MANAGER_MODE_AP = 0,
    WIFI_MANAGER_MODE_STA
} wifi_manager_mode_t;

void wifi_manager_init(void);
void wifi_manager_start(void);
bool wifi_manager_is_connected(void);
const char *wifi_manager_get_ip(void);
wifi_manager_mode_t wifi_manager_get_mode(void);

int wifi_manager_get_rssi(void);

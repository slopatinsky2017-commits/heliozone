#include "time_manager.h"

#include <string.h>
#include <stdlib.h>
#include <sys/time.h>

#include "esp_log.h"
#include "esp_sntp.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#define HZ_NTP_SERVER "pool.ntp.org"
#define HZ_RESYNC_PERIOD_MS (6 * 60 * 60 * 1000)

static const char *TAG = "time_manager";
static bool s_synced = false;
static char s_timezone[32] = "UTC0";

static void sync_time_once(void) {
    esp_sntp_stop();
    esp_sntp_setoperatingmode(SNTP_OPMODE_POLL);
    esp_sntp_setservername(0, HZ_NTP_SERVER);
    esp_sntp_init();

    for (int i = 0; i < 20; i++) {
        time_t now = time(NULL);
        if (now > 1700000000) {
            s_synced = true;
            ESP_LOGI(TAG, "time synchronized from %s", HZ_NTP_SERVER);
            return;
        }
        vTaskDelay(pdMS_TO_TICKS(500));
    }

    ESP_LOGW(TAG, "time sync timeout");
}

static void task_time_resync(void *arg) {
    (void)arg;
    while (1) {
        sync_time_once();
        vTaskDelay(pdMS_TO_TICKS(HZ_RESYNC_PERIOD_MS));
    }
}

void time_manager_init(void) {
    const char *tz = getenv("TZ");
    if (tz != NULL && strlen(tz) > 0) {
        strncpy(s_timezone, tz, sizeof(s_timezone) - 1);
        s_timezone[sizeof(s_timezone) - 1] = '\0';
    } else {
        setenv("TZ", s_timezone, 1);
        tzset();
    }

    ESP_LOGI(TAG, "time_manager initialized timezone=%s", s_timezone);
}

void time_manager_start(void) {
    sync_time_once();
    xTaskCreate(task_time_resync, "task_time_resync", 4096, NULL, 4, NULL);
}

bool time_manager_is_synced(void) {
    return s_synced;
}

time_t time_manager_get_timestamp(void) {
    return time(NULL);
}

int time_manager_get_minutes_of_day(void) {
    time_t now = time_manager_get_timestamp();
    struct tm local_time = {0};
    localtime_r(&now, &local_time);
    return local_time.tm_hour * 60 + local_time.tm_min;
}

const char *time_manager_get_timezone(void) {
    return s_timezone;
}

#include "grow_engine.h"

#include "esp_log.h"

static const char *TAG = "grow_engine";

void grow_engine_init(void) {}

void grow_engine_run(const grow_profile_t *profile) {
    if (profile == NULL) {
        ESP_LOGW(TAG, "grow_engine_run called with NULL profile");
        return;
    }

    ESP_LOGI(TAG,
             "Profile resolved: crop=%s stage=%s ppfd=%d photoperiod=%dh dli=%.1f",
             profile->crop,
             profile->stage,
             profile->ppfd,
             profile->photoperiod_hours,
             profile->dli);
}

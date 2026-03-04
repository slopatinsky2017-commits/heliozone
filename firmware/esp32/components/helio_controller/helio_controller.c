#include "helio_controller.h"

#include "esp_log.h"
#include "grow_engine.h"
#include "grow_profiles.h"
#include "zone_manager.h"

static const char *TAG = "helio_controller";

void helio_controller_start(void) {
    grow_profiles_init();
    zone_manager_init();
    grow_engine_init();

    if (!zone_set_profile(0, "Tomato", "Seedling")) {
        ESP_LOGW(TAG, "Failed to bind default profile to zone 0");
        return;
    }

    const grow_profile_t *profile = zone_get_profile(0);
    if (profile == NULL) {
        ESP_LOGW(TAG, "Zone 0 profile resolution failed");
        return;
    }

    ESP_LOGI(TAG, "Helio controller started with zone 0 profile %s/%s", profile->crop, profile->stage);
    grow_engine_run(profile);
}

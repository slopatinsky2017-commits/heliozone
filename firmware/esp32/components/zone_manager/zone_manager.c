#include "zone_manager.h"

#include <string.h>

static zone_profile_binding_t s_zone_bindings[ZONE_MANAGER_MAX_ZONES];

static bool is_valid_zone(int zone_id) {
    return zone_id >= 0 && zone_id < ZONE_MANAGER_MAX_ZONES;
}

void zone_manager_init(void) {
    memset(s_zone_bindings, 0, sizeof(s_zone_bindings));
}

bool zone_set_profile(int zone_id, const char *crop, const char *stage) {
    if (!is_valid_zone(zone_id) || crop == NULL || stage == NULL) {
        return false;
    }

    const grow_profile_t *resolved = grow_profiles_find(crop, stage);
    if (resolved == NULL) {
        return false;
    }

    zone_profile_binding_t *binding = &s_zone_bindings[zone_id];
    strncpy(binding->crop, crop, sizeof(binding->crop) - 1);
    binding->crop[sizeof(binding->crop) - 1] = '\0';
    strncpy(binding->stage, stage, sizeof(binding->stage) - 1);
    binding->stage[sizeof(binding->stage) - 1] = '\0';

    return true;
}

const grow_profile_t *zone_get_profile(int zone_id) {
    if (!is_valid_zone(zone_id)) {
        return NULL;
    }

    const zone_profile_binding_t *binding = &s_zone_bindings[zone_id];
    if (binding->crop[0] == '\0' || binding->stage[0] == '\0') {
        return NULL;
    }

    return grow_profiles_find(binding->crop, binding->stage);
}

const zone_profile_binding_t *zone_get_binding(int zone_id) {
    if (!is_valid_zone(zone_id)) {
        return NULL;
    }
    return &s_zone_bindings[zone_id];
}

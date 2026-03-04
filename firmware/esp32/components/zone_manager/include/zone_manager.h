#pragma once

#include <stdbool.h>

#include "crop_profiles.h"

#ifdef __cplusplus
extern "C" {
#endif

#define ZONE_MANAGER_MAX_ZONES 4

typedef struct {
    char crop[32];
    char stage[32];
} zone_profile_binding_t;

void zone_manager_init(void);
bool zone_set_profile(int zone_id, const char *crop, const char *stage);
const crop_profile_t *zone_get_profile(int zone_id);
const zone_profile_binding_t *zone_get_binding(int zone_id);

#ifdef __cplusplus
}
#endif

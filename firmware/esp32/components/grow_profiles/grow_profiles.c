#include "grow_profiles.h"

#include <stddef.h>
#include <string.h>

static const grow_profile_t s_profiles[] = {
    {"Tomato", "Seedling", 220, 16, 12.7f},
    {"Tomato", "Vegetative", 420, 18, 27.2f},
    {"Tomato", "Fruiting", 650, 16, 37.4f},

    {"Cucumber", "Seedling", 200, 16, 11.5f},
    {"Cucumber", "Vegetative", 380, 18, 24.6f},
    {"Cucumber", "Fruiting", 580, 16, 33.4f},

    {"Pepper", "Seedling", 220, 16, 12.7f},
    {"Pepper", "Vegetative", 400, 18, 25.9f},
    {"Pepper", "Fruiting", 600, 16, 34.6f},

    {"Eggplant", "Seedling", 200, 16, 11.5f},
    {"Eggplant", "Vegetative", 380, 18, 24.6f},
    {"Eggplant", "Fruiting", 600, 16, 34.6f},

    {"Watermelon", "Seedling", 220, 16, 12.7f},
    {"Watermelon", "Vegetative", 450, 18, 29.2f},
    {"Watermelon", "Fruiting", 700, 16, 40.3f},

    {"Melon", "Seedling", 220, 16, 12.7f},
    {"Melon", "Vegetative", 420, 18, 27.2f},
    {"Melon", "Fruiting", 650, 16, 37.4f},

    {"Greens", "Seedling", 160, 16, 9.2f},
    {"Greens", "Vegetative", 260, 18, 16.8f},
    {"Greens", "Fruiting", 320, 16, 18.4f},

    {"Flowers", "Seedling", 180, 16, 10.4f},
    {"Flowers", "Vegetative", 350, 18, 22.7f},
    {"Flowers", "Flowering", 550, 12, 23.8f},
};

void grow_profiles_init(void) {}

int grow_profiles_count(void) {
    return (int)(sizeof(s_profiles) / sizeof(s_profiles[0]));
}

const grow_profile_t *grow_profiles_get(int idx) {
    if (idx < 0 || idx >= grow_profiles_count()) {
        return NULL;
    }
    return &s_profiles[idx];
}

const grow_profile_t *grow_profiles_find(const char *crop, const char *stage) {
    if (crop == NULL || stage == NULL) {
        return NULL;
    }

    for (int i = 0; i < grow_profiles_count(); ++i) {
        const grow_profile_t *profile = &s_profiles[i];
        if (strcmp(profile->crop, crop) == 0 && strcmp(profile->stage, stage) == 0) {
            return profile;
        }
    }

    return NULL;
}

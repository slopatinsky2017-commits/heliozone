#include "crop_profiles.h"

#include <string.h>

static const crop_profile_t s_profiles[] = {
    {"tomato", "seedling", 220, 16, 12.7f, 75, 90, 0.72f, 0.22f},
    {"tomato", "vegetative", 420, 18, 27.2f, 65, 80, 0.85f, 0.25f},
    {"tomato", "fruiting", 650, 16, 37.4f, 55, 70, 0.93f, 0.30f},

    {"cucumber", "seedling", 200, 16, 11.5f, 75, 90, 0.70f, 0.22f},
    {"cucumber", "vegetative", 380, 18, 24.6f, 65, 80, 0.82f, 0.24f},
    {"cucumber", "fruiting", 580, 16, 33.4f, 55, 70, 0.90f, 0.30f},

    {"pepper", "seedling", 220, 16, 12.7f, 75, 90, 0.72f, 0.22f},
    {"pepper", "vegetative", 400, 18, 25.9f, 65, 80, 0.84f, 0.25f},
    {"pepper", "fruiting", 600, 16, 34.6f, 55, 70, 0.92f, 0.30f},

    {"eggplant", "seedling", 200, 16, 11.5f, 75, 90, 0.70f, 0.22f},
    {"eggplant", "vegetative", 380, 18, 24.6f, 65, 80, 0.82f, 0.24f},
    {"eggplant", "fruiting", 600, 16, 34.6f, 55, 70, 0.92f, 0.30f},

    {"watermelon", "seedling", 220, 16, 12.7f, 75, 90, 0.72f, 0.22f},
    {"watermelon", "vegetative", 450, 18, 29.2f, 65, 80, 0.87f, 0.26f},
    {"watermelon", "fruiting", 700, 16, 40.3f, 55, 70, 0.96f, 0.32f},

    {"melon", "seedling", 220, 16, 12.7f, 75, 90, 0.72f, 0.22f},
    {"melon", "vegetative", 420, 18, 27.2f, 65, 80, 0.85f, 0.25f},
    {"melon", "fruiting", 650, 16, 37.4f, 55, 70, 0.93f, 0.30f},

    {"greens", "seedling", 160, 16, 9.2f, 80, 95, 0.60f, 0.20f},
    {"greens", "vegetative", 260, 18, 16.8f, 70, 85, 0.70f, 0.22f},

    {"flowers", "seedling", 180, 16, 10.4f, 80, 95, 0.64f, 0.20f},
    {"flowers", "vegetative", 350, 18, 22.7f, 70, 85, 0.78f, 0.24f},
    {"flowers", "flowering", 550, 12, 23.8f, 60, 75, 0.88f, 0.28f},
};

void crop_profiles_init(void) {}

int crop_profiles_count(void) {
    return (int)(sizeof(s_profiles) / sizeof(s_profiles[0]));
}

const crop_profile_t *crop_profiles_get(int index) {
    if (index < 0 || index >= crop_profiles_count()) {
        return NULL;
    }
    return &s_profiles[index];
}

const crop_profile_t *crop_profiles_find(const char *crop, const char *stage) {
    if (crop == NULL || stage == NULL) {
        return NULL;
    }

    for (int i = 0; i < crop_profiles_count(); ++i) {
        const crop_profile_t *p = &s_profiles[i];
        if (strcmp(p->crop, crop) == 0 && strcmp(p->stage, stage) == 0) {
            return p;
        }
    }
    return NULL;
}

#include "profiles_loader.h"

#include "grow_profiles.h"

void profiles_loader_init(void) {
    grow_profiles_init();
}

const grow_profile_t *profiles_loader_default(void) {
    return grow_profiles_find("Tomato", "Seedling");
}

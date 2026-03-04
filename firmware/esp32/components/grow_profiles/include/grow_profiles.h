#pragma once

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    char crop[32];
    char stage[32];
    int ppfd;
    int photoperiod_hours;
    float dli;
} grow_profile_t;

void grow_profiles_init(void);
int grow_profiles_count(void);
const grow_profile_t *grow_profiles_get(int idx);
const grow_profile_t *grow_profiles_find(const char *crop, const char *stage);

#ifdef __cplusplus
}
#endif

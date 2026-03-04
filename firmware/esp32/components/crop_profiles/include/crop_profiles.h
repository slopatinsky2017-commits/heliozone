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
    int sunrise_ramp_minutes;
    int sunset_ramp_minutes;
    float midday_peak;
    float cloud_variability;
} crop_profile_t;

void crop_profiles_init(void);
int crop_profiles_count(void);
const crop_profile_t *crop_profiles_get(int index);
const crop_profile_t *crop_profiles_find(const char *crop, const char *stage);

#ifdef __cplusplus
}
#endif

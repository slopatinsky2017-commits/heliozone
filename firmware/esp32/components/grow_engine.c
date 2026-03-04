#include <stdio.h>
#include <math.h>
#include <string.h>

typedef struct {
    char crop[32];
    char stage[32];
    int ppfd;
    int photoperiod;
    float dli;
} grow_profile_t;

float calculate_dli(int ppfd, int photoperiod_hours)
{
    float seconds = photoperiod_hours * 3600.0;
    float dli = (ppfd * seconds) / 1000000.0;
    return dli;
}

void grow_engine_run(grow_profile_t profile)
{
    float dli = calculate_dli(profile.ppfd, profile.photoperiod);

    printf("HelioZone Grow Engine\n");
    printf("Crop: %s\n", profile.crop);
    printf("Stage: %s\n", profile.stage);
    printf("PPFD: %d umol\n", profile.ppfd);
    printf("Photoperiod: %d h\n", profile.photoperiod);
    printf("Target DLI: %.2f mol/m2/day\n", dli);
}

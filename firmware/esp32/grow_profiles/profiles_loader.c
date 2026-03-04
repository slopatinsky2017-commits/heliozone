#include <stdio.h>
#include <string.h>

typedef struct {
    char crop[32];
    char stage[32];
    int ppfd;
    int photoperiod;
    float dli;
} grow_profile_t;

grow_profile_t profiles[16];
int profiles_count = 0;

void grow_profiles_init()
{
    printf("HelioZone: grow profiles module initialized\n");
}

void grow_profiles_print()
{
    for(int i = 0; i < profiles_count; i++)
    {
        printf("Crop: %s | Stage: %s | PPFD: %d | Photoperiod: %d | DLI: %.2f\n",
               profiles[i].crop,
               profiles[i].stage,
               profiles[i].ppfd,
               profiles[i].photoperiod,
               profiles[i].dli);
    }
}

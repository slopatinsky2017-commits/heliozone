#include <stdio.h>
#include <math.h>

float calculate_dli(int ppfd, int photoperiod_hours)
{
    float seconds = photoperiod_hours * 3600.0;
    float dli = (ppfd * seconds) / 1000000.0;
    return dli;
}

void grow_engine_print(int ppfd, int photoperiod)
{
    float dli = calculate_dli(ppfd, photoperiod);

    printf("HelioZone Grow Engine\n");
    printf("PPFD: %d umol\n", ppfd);
    printf("Photoperiod: %d h\n", photoperiod);
    printf("DLI: %.2f mol/m2/day\n", dli);
}

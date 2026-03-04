#include <stdio.h>
#include <string.h>

#define MAX_LAMPS 128

typedef struct {
    int lamp_id;
    int brightness;
    int ppfd;
} lamp_t;

typedef struct {
    char zone_name[32];
    int lamp_count;
    lamp_t lamps[MAX_LAMPS];
} zone_t;

void zone_print(zone_t zone)
{
    printf("Zone: %s\n", zone.zone_name);
    printf("Lamp count: %d\n", zone.lamp_count);

    for(int i = 0; i < zone.lamp_count; i++)
    {
        printf("Lamp %d | brightness %d | PPFD %d\n",
               zone.lamps[i].lamp_id,
               zone.lamps[i].brightness,
               zone.lamps[i].ppfd);
    }
}

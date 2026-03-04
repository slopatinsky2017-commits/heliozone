#include <stdio.h>

#define MAX_LAMPS 256

typedef struct {
    int id;
    int zone_id;
    int online;
} lamp_node_t;

lamp_node_t lamps[MAX_LAMPS];
int lamp_count = 0;

void lamp_register(int id, int zone)
{
    lamps[lamp_count].id = id;
    lamps[lamp_count].zone_id = zone;
    lamps[lamp_count].online = 1;

    lamp_count++;

    printf("Lamp registered: %d in zone %d\n", id, zone);
}

void lamp_network_print()
{
    printf("HelioZone Lamp Network\n");

    for(int i = 0; i < lamp_count; i++)
    {
        printf("Lamp %d | Zone %d | Online %d\n",
               lamps[i].id,
               lamps[i].zone_id,
               lamps[i].online);
    }
}

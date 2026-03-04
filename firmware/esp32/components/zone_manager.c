#include <stdio.h>
#include <string.h>

#define MAX_LAMPS 128
#define MAX_ZONES 16

typedef struct {
    int lamp_id;
    int brightness;
    int ppfd;
} lamp_t;

typedef struct {
    int zone_id;
    char zone_name[32];
    int lamp_count;
    lamp_t lamps[MAX_LAMPS];
} zone_t;

zone_t zones[MAX_ZONES];
int zone_count = 0;

void zone_create(int id, const char* name)
{
    zones[zone_count].zone_id = id;
    strcpy(zones[zone_count].zone_name, name);
    zones[zone_count].lamp_count = 0;

    zone_count++;

    printf("Zone created: %s\n", name);
}

void zone_add_lamp(int zone_id, int lamp_id)
{
    for(int i = 0; i < zone_count; i++)
    {
        if(zones[i].zone_id == zone_id)
        {
            int index = zones[i].lamp_count;

            zones[i].lamps[index].lamp_id = lamp_id;
            zones[i].lamps[index].brightness = 0;
            zones[i].lamps[index].ppfd = 0;

            zones[i].lamp_count++;

            printf("Lamp %d added to zone %s\n",
                   lamp_id,
                   zones[i].zone_name);
        }
    }
}

void zone_print()
{
    for(int i = 0; i < zone_count; i++)
    {
        printf("Zone %s\n", zones[i].zone_name);

        for(int j = 0; j < zones[i].lamp_count; j++)
        {
            printf("Lamp %d\n",
                   zones[i].lamps[j].lamp_id);
        }
    }
}

#pragma once

#include <stdbool.h>
#include <time.h>

void time_manager_init(void);
void time_manager_start(void);

bool time_manager_is_synced(void);
time_t time_manager_get_timestamp(void);
int time_manager_get_minutes_of_day(void);
const char *time_manager_get_timezone(void);

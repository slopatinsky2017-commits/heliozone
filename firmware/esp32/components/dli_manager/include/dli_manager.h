#pragma once

#include <stdbool.h>

typedef struct {
    float current_dli;
    float target_dli;
    float output_scale;
} dli_status_t;

void dli_manager_init(void);
void dli_manager_set_target(float target_dli);
float dli_manager_get_target(void);

// Call once per second with current PPFD and minute-of-day [0..1439].
void dli_manager_tick(float ppfd, int now_minutes);

void dli_manager_get_status(dli_status_t *out_status);
float dli_manager_get_current(void);
float dli_manager_get_output_scale(void);

#pragma once

#include <stdbool.h>

typedef struct {
    float ppfd;
    float target;
    float control_output;
} light_regulator_status_t;

void light_regulator_init(void);
void light_regulator_set_target(float target);
float light_regulator_get_target(void);

// Runs one regulation step and returns desired master brightness [0..100].
float light_regulator_update(float measured_ppfd, float base_brightness);

void light_regulator_get_status(light_regulator_status_t *out_status);

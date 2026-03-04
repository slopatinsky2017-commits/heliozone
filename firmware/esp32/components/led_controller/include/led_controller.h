#pragma once

#include <stdbool.h>

typedef enum {
    LED_CHANNEL_WHITE = 0,
    LED_CHANNEL_BLUE,
    LED_CHANNEL_RED,
    LED_CHANNEL_FAR_RED,
    LED_CHANNEL_COUNT
} led_channel_t;

void led_controller_init(void);
void led_controller_set_power(bool on);
void led_controller_set_channel_percent(led_channel_t channel, float percent);
float led_controller_get_channel_percent(led_channel_t channel);
bool led_controller_is_powered(void);

#include "led_controller.h"

#include "driver/ledc.h"
#include "esp_log.h"

#define HZ_PWM_FREQ_HZ 5000
#define HZ_PWM_TIMER_RES LEDC_TIMER_13_BIT
#define HZ_PWM_MAX_DUTY ((1 << 13) - 1)

#define HZ_GPIO_WHITE 4
#define HZ_GPIO_BLUE 5
#define HZ_GPIO_RED 6
#define HZ_GPIO_FAR_RED 7

static const char *TAG = "led_controller";

static bool s_powered = false;
static float s_channels_percent[LED_CHANNEL_COUNT] = {0};

static ledc_channel_t channel_to_ledc(led_channel_t channel) {
    return (ledc_channel_t)channel;
}

static int channel_to_gpio(led_channel_t channel) {
    static const int gpio_map[LED_CHANNEL_COUNT] = {
        HZ_GPIO_WHITE,
        HZ_GPIO_BLUE,
        HZ_GPIO_RED,
        HZ_GPIO_FAR_RED,
    };
    return gpio_map[channel];
}

static void apply_channel(led_channel_t channel) {
    float percent = s_powered ? s_channels_percent[channel] : 0.0f;
    uint32_t duty = (uint32_t)((percent / 100.0f) * HZ_PWM_MAX_DUTY);

    ledc_set_duty(LEDC_LOW_SPEED_MODE, channel_to_ledc(channel), duty);
    ledc_update_duty(LEDC_LOW_SPEED_MODE, channel_to_ledc(channel));
}

void led_controller_init(void) {
    ledc_timer_config_t timer_cfg = {
        .speed_mode = LEDC_LOW_SPEED_MODE,
        .duty_resolution = HZ_PWM_TIMER_RES,
        .timer_num = LEDC_TIMER_0,
        .freq_hz = HZ_PWM_FREQ_HZ,
        .clk_cfg = LEDC_AUTO_CLK,
    };
    ledc_timer_config(&timer_cfg);

    for (int i = 0; i < LED_CHANNEL_COUNT; i++) {
        ledc_channel_config_t ch_cfg = {
            .gpio_num = channel_to_gpio((led_channel_t)i),
            .speed_mode = LEDC_LOW_SPEED_MODE,
            .channel = channel_to_ledc((led_channel_t)i),
            .intr_type = LEDC_INTR_DISABLE,
            .timer_sel = LEDC_TIMER_0,
            .duty = 0,
            .hpoint = 0,
        };
        ledc_channel_config(&ch_cfg);
    }

    ESP_LOGI(TAG, "PWM initialized for channels W/B/R/FR");
}

void led_controller_set_power(bool on) {
    s_powered = on;
    for (int i = 0; i < LED_CHANNEL_COUNT; i++) {
        apply_channel((led_channel_t)i);
    }
    ESP_LOGI(TAG, "power %s", on ? "ON" : "OFF");
}

void led_controller_set_channel_percent(led_channel_t channel, float percent) {
    if (channel >= LED_CHANNEL_COUNT) {
        return;
    }

    if (percent < 0.0f) {
        percent = 0.0f;
    }
    if (percent > 100.0f) {
        percent = 100.0f;
    }

    s_channels_percent[channel] = percent;
    apply_channel(channel);
}

float led_controller_get_channel_percent(led_channel_t channel) {
    if (channel >= LED_CHANNEL_COUNT) {
        return 0.0f;
    }
    return s_channels_percent[channel];
}

bool led_controller_is_powered(void) {
    return s_powered;
}

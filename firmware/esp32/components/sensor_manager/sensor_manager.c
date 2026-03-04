#include "sensor_manager.h"

#include "esp_log.h"

static const char *TAG = "sensor_manager";
static sensor_snapshot_t s_snapshot = {
    .par_umol_m2_s = 250.0f,
    .temperature_c = 25.0f,
    .humidity_rh = 55.0f,
};

static float read_sem228p_ppfd_modbus(void) {
    // Placeholder for SEM228P RS485/Modbus polling.
    // Example behavior for bring-up/testing environments.
    static float mock_ppfd = 250.0f;
    mock_ppfd += 7.5f;
    if (mock_ppfd > 800.0f) {
        mock_ppfd = 150.0f;
    }
    return mock_ppfd;
}

void sensor_manager_init(void) {
    ESP_LOGI(TAG, "sensor_manager initialized (SEM228P PAR via RS485 Modbus placeholder)");
}

void sensor_manager_poll(void) {
    s_snapshot.par_umol_m2_s = read_sem228p_ppfd_modbus();
}

sensor_snapshot_t sensor_manager_get_snapshot(void) {
    return s_snapshot;
}

float sensor_manager_get_ppfd(void) {
    return s_snapshot.par_umol_m2_s;
}

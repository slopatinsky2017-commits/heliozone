#pragma once

typedef struct {
    float par_umol_m2_s;
    float temperature_c;
    float humidity_rh;
} sensor_snapshot_t;

void sensor_manager_init(void);
void sensor_manager_poll(void);
sensor_snapshot_t sensor_manager_get_snapshot(void);

// SEM228P PAR sensor value over RS485/Modbus.
float sensor_manager_get_ppfd(void);

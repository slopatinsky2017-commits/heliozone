#pragma once

#include <stdbool.h>

#include "health_manager.h"
#include "telemetry_manager.h"

#ifdef __cplusplus
extern "C" {
#endif

void mqtt_manager_init(void);
void mqtt_manager_publish_telemetry(const telemetry_data_t *telemetry);
void mqtt_manager_publish_health(const health_snapshot_t *health);
bool mqtt_manager_is_enabled(void);

#ifdef __cplusplus
}
#endif

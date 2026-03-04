#pragma once

#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    OTA_MANAGER_STATE_IDLE = 0,
    OTA_MANAGER_STATE_IN_PROGRESS,
    OTA_MANAGER_STATE_SUCCESS,
    OTA_MANAGER_STATE_FAILED
} ota_manager_state_t;

typedef struct {
    ota_manager_state_t state;
    int progress_percent;
    bool reboot_scheduled;
    bool pending_boot_validation;
    char message[96];
    char version[32];
    char last_error[96];
} ota_manager_status_t;

void ota_manager_init(void);
bool ota_manager_start_update(const char *url,
                              const char *expected_sha256,
                              const char *expected_version,
                              char *error_buf,
                              size_t error_buf_len);
void ota_manager_get_status(ota_manager_status_t *out_status);

#ifdef __cplusplus
}
#endif

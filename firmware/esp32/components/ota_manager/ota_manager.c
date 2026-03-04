#include "ota_manager.h"

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>

#include "esp_app_desc.h"
#include "esp_http_client.h"
#include "esp_log.h"
#include "esp_ota_ops.h"
#include "esp_system.h"
#include "freertos/FreeRTOS.h"
#include "freertos/semphr.h"
#include "freertos/task.h"
#include "mbedtls/sha256.h"

#define OTA_TASK_STACK_SIZE 8192
#define OTA_TASK_PRIORITY 5
#define OTA_REBOOT_DELAY_MS 3000
#define OTA_BOOT_VALIDATION_DELAY_SEC 60

static const char *TAG = "ota_manager";

static SemaphoreHandle_t s_status_lock = NULL;
static ota_manager_status_t s_status = {
    .state = OTA_MANAGER_STATE_IDLE,
    .progress_percent = 0,
    .reboot_scheduled = false,
    .pending_boot_validation = false,
    .message = "idle",
    .version = "unknown",
    .last_error = "",
};

typedef struct {
    char url[256];
    char expected_sha256[65];
    char expected_version[32];
} ota_task_args_t;

static void status_set_message(const char *message) {
    if (message == NULL) {
        s_status.message[0] = '\0';
        return;
    }
    snprintf(s_status.message, sizeof(s_status.message), "%s", message);
}

static void status_set_error(const char *error) {
    if (error == NULL) {
        s_status.last_error[0] = '\0';
        return;
    }
    snprintf(s_status.last_error, sizeof(s_status.last_error), "%s", error);
}

static void set_status(ota_manager_state_t state,
                       int progress_percent,
                       bool reboot_scheduled,
                       const char *message) {
    if (s_status_lock == NULL) {
        return;
    }

    xSemaphoreTake(s_status_lock, portMAX_DELAY);
    s_status.state = state;
    s_status.progress_percent = progress_percent;
    s_status.reboot_scheduled = reboot_scheduled;
    status_set_message(message);
    xSemaphoreGive(s_status_lock);
}

static void set_failed_status(const char *error_message) {
    if (s_status_lock == NULL) {
        return;
    }

    xSemaphoreTake(s_status_lock, portMAX_DELAY);
    s_status.state = OTA_MANAGER_STATE_FAILED;
    s_status.progress_percent = 0;
    s_status.reboot_scheduled = false;
    status_set_message(error_message);
    status_set_error(error_message);
    xSemaphoreGive(s_status_lock);
}

static bool is_update_in_progress(void) {
    bool in_progress = false;
    xSemaphoreTake(s_status_lock, portMAX_DELAY);
    in_progress = (s_status.state == OTA_MANAGER_STATE_IN_PROGRESS);
    xSemaphoreGive(s_status_lock);
    return in_progress;
}

static bool is_valid_sha256_hex(const char *sha) {
    if (sha == NULL || strlen(sha) != 64) {
        return false;
    }

    for (size_t i = 0; i < 64; ++i) {
        char c = sha[i];
        bool is_hex = (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
        if (!is_hex) {
            return false;
        }
    }
    return true;
}

static void to_hex(const uint8_t *bytes, size_t len, char *out, size_t out_len) {
    if (out_len < (len * 2 + 1)) {
        if (out_len > 0) {
            out[0] = '\0';
        }
        return;
    }

    for (size_t i = 0; i < len; ++i) {
        snprintf(out + (i * 2), out_len - (i * 2), "%02x", bytes[i]);
    }
}

static void app_desc_version(char *out, size_t out_len) {
    const esp_app_desc_t *desc = esp_app_get_description();
    if (desc == NULL || desc->version[0] == '\0') {
        snprintf(out, out_len, "%s", "unknown");
        return;
    }
    snprintf(out, out_len, "%s", desc->version);
}

static void boot_validation_task(void *arg) {
    (void)arg;
    ESP_LOGI(TAG, "pending verify image detected, waiting %ds before marking valid", OTA_BOOT_VALIDATION_DELAY_SEC);
    vTaskDelay(pdMS_TO_TICKS(OTA_BOOT_VALIDATION_DELAY_SEC * 1000));

    esp_err_t err = esp_ota_mark_app_valid_cancel_rollback();
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "failed to mark app valid: %s", esp_err_to_name(err));
        set_failed_status("boot validation failed");
        xSemaphoreTake(s_status_lock, portMAX_DELAY);
        s_status.pending_boot_validation = true;
        xSemaphoreGive(s_status_lock);
        vTaskDelete(NULL);
        return;
    }

    xSemaphoreTake(s_status_lock, portMAX_DELAY);
    s_status.pending_boot_validation = false;
    s_status.state = OTA_MANAGER_STATE_IDLE;
    status_set_message("boot validated");
    xSemaphoreGive(s_status_lock);

    ESP_LOGI(TAG, "boot validation complete, app marked valid");
    vTaskDelete(NULL);
}

static bool verify_partition_version(const esp_partition_t *partition,
                                     const char *expected_version,
                                     char *error_buf,
                                     size_t error_buf_len) {
    esp_app_desc_t app_desc;
    esp_err_t err = esp_ota_get_partition_description(partition, &app_desc);
    if (err != ESP_OK) {
        snprintf(error_buf, error_buf_len, "unable to read image metadata");
        return false;
    }

    if (strcmp(app_desc.version, expected_version) != 0) {
        snprintf(error_buf,
                 error_buf_len,
                 "version mismatch (expected %s got %s)",
                 expected_version,
                 app_desc.version);
        return false;
    }

    return true;
}

static void ota_task(void *arg) {
    ota_task_args_t *task_args = (ota_task_args_t *)arg;

    esp_http_client_config_t http_cfg = {
        .url = task_args->url,
        .timeout_ms = 10000,
        .keep_alive_enable = true,
    };

    esp_http_client_handle_t http_client = esp_http_client_init(&http_cfg);
    if (http_client == NULL) {
        set_failed_status("http client init failed");
        free(task_args);
        vTaskDelete(NULL);
        return;
    }

    esp_err_t err = esp_http_client_open(http_client, 0);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "esp_http_client_open failed: %s", esp_err_to_name(err));
        set_failed_status("unable to open url");
        esp_http_client_cleanup(http_client);
        free(task_args);
        vTaskDelete(NULL);
        return;
    }

    int64_t content_length = esp_http_client_fetch_headers(http_client);
    if (content_length <= 0) {
        ESP_LOGW(TAG, "content-length unavailable, progress will be partial");
    }

    const esp_partition_t *update_partition = esp_ota_get_next_update_partition(NULL);
    if (update_partition == NULL) {
        set_failed_status("no update partition");
        esp_http_client_close(http_client);
        esp_http_client_cleanup(http_client);
        free(task_args);
        vTaskDelete(NULL);
        return;
    }

    esp_ota_handle_t ota_handle;
    err = esp_ota_begin(update_partition, OTA_SIZE_UNKNOWN, &ota_handle);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "esp_ota_begin failed: %s", esp_err_to_name(err));
        set_failed_status("ota begin failed");
        esp_http_client_close(http_client);
        esp_http_client_cleanup(http_client);
        free(task_args);
        vTaskDelete(NULL);
        return;
    }

    mbedtls_sha256_context sha_ctx;
    mbedtls_sha256_init(&sha_ctx);
    mbedtls_sha256_starts_ret(&sha_ctx, 0);

    uint8_t buffer[1024];
    int total_read = 0;
    set_status(OTA_MANAGER_STATE_IN_PROGRESS, 0, false, "downloading firmware");

    while (true) {
        int read_bytes = esp_http_client_read(http_client, (char *)buffer, sizeof(buffer));
        if (read_bytes < 0) {
            ESP_LOGE(TAG, "esp_http_client_read failed");
            set_failed_status("download failed");
            esp_ota_abort(ota_handle);
            esp_http_client_close(http_client);
            esp_http_client_cleanup(http_client);
            mbedtls_sha256_free(&sha_ctx);
            free(task_args);
            vTaskDelete(NULL);
            return;
        }

        if (read_bytes == 0) {
            break;
        }

        mbedtls_sha256_update_ret(&sha_ctx, buffer, read_bytes);

        err = esp_ota_write(ota_handle, buffer, read_bytes);
        if (err != ESP_OK) {
            ESP_LOGE(TAG, "esp_ota_write failed: %s", esp_err_to_name(err));
            set_failed_status("flash write failed");
            esp_ota_abort(ota_handle);
            esp_http_client_close(http_client);
            esp_http_client_cleanup(http_client);
            mbedtls_sha256_free(&sha_ctx);
            free(task_args);
            vTaskDelete(NULL);
            return;
        }

        total_read += read_bytes;
        if (content_length > 0) {
            int progress = (int)((total_read * 100) / content_length);
            if (progress > 100) {
                progress = 100;
            }
            set_status(OTA_MANAGER_STATE_IN_PROGRESS, progress, false, "downloading firmware");
        }
    }

    uint8_t digest[32] = {0};
    char digest_hex[65] = {0};
    mbedtls_sha256_finish_ret(&sha_ctx, digest);
    mbedtls_sha256_free(&sha_ctx);
    to_hex(digest, sizeof(digest), digest_hex, sizeof(digest_hex));

    if (strcasecmp(digest_hex, task_args->expected_sha256) != 0) {
        ESP_LOGE(TAG, "SHA256 mismatch expected=%s actual=%s", task_args->expected_sha256, digest_hex);
        set_failed_status("sha256 mismatch");
        esp_ota_abort(ota_handle);
        esp_http_client_close(http_client);
        esp_http_client_cleanup(http_client);
        free(task_args);
        vTaskDelete(NULL);
        return;
    }

    set_status(OTA_MANAGER_STATE_IN_PROGRESS, 95, false, "verifying image");

    err = esp_ota_end(ota_handle);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "esp_ota_end failed: %s", esp_err_to_name(err));
        set_failed_status("firmware verify failed");
        esp_http_client_close(http_client);
        esp_http_client_cleanup(http_client);
        free(task_args);
        vTaskDelete(NULL);
        return;
    }

    char verify_error[96] = {0};
    if (!verify_partition_version(update_partition,
                                  task_args->expected_version,
                                  verify_error,
                                  sizeof(verify_error))) {
        ESP_LOGE(TAG, "version validation failed: %s", verify_error);
        set_failed_status(verify_error);
        esp_http_client_close(http_client);
        esp_http_client_cleanup(http_client);
        free(task_args);
        vTaskDelete(NULL);
        return;
    }

    err = esp_ota_set_boot_partition(update_partition);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "esp_ota_set_boot_partition failed: %s", esp_err_to_name(err));
        set_failed_status("install failed");
        esp_http_client_close(http_client);
        esp_http_client_cleanup(http_client);
        free(task_args);
        vTaskDelete(NULL);
        return;
    }

    xSemaphoreTake(s_status_lock, portMAX_DELAY);
    s_status.state = OTA_MANAGER_STATE_SUCCESS;
    s_status.progress_percent = 100;
    s_status.reboot_scheduled = true;
    status_set_message("update installed, rebooting");
    status_set_error("");
    snprintf(s_status.version, sizeof(s_status.version), "%s", task_args->expected_version);
    xSemaphoreGive(s_status_lock);

    esp_http_client_close(http_client);
    esp_http_client_cleanup(http_client);
    free(task_args);

    vTaskDelay(pdMS_TO_TICKS(OTA_REBOOT_DELAY_MS));
    esp_restart();
    vTaskDelete(NULL);
}

void ota_manager_init(void) {
    if (s_status_lock == NULL) {
        s_status_lock = xSemaphoreCreateMutex();
    }

    char running_version[32] = {0};
    app_desc_version(running_version, sizeof(running_version));

    xSemaphoreTake(s_status_lock, portMAX_DELAY);
    s_status.state = OTA_MANAGER_STATE_IDLE;
    s_status.progress_percent = 0;
    s_status.reboot_scheduled = false;
    s_status.pending_boot_validation = false;
    status_set_message("idle");
    status_set_error("");
    snprintf(s_status.version, sizeof(s_status.version), "%s", running_version);
    xSemaphoreGive(s_status_lock);

    const esp_partition_t *running = esp_ota_get_running_partition();
    esp_ota_img_states_t ota_state;
    if (esp_ota_get_state_partition(running, &ota_state) == ESP_OK &&
        ota_state == ESP_OTA_IMG_PENDING_VERIFY) {
        xSemaphoreTake(s_status_lock, portMAX_DELAY);
        s_status.pending_boot_validation = true;
        status_set_message("pending boot validation");
        xSemaphoreGive(s_status_lock);
        xTaskCreate(boot_validation_task,
                    "ota_boot_valid",
                    3072,
                    NULL,
                    OTA_TASK_PRIORITY,
                    NULL);
    }

    ESP_LOGI(TAG, "ota_manager initialized (version=%s)", running_version);
}

bool ota_manager_start_update(const char *url,
                              const char *expected_sha256,
                              const char *expected_version,
                              char *error_buf,
                              size_t error_buf_len) {
    if (url == NULL || url[0] == '\0') {
        if (error_buf != NULL && error_buf_len > 0) {
            snprintf(error_buf, error_buf_len, "url is required");
        }
        return false;
    }
    if (!is_valid_sha256_hex(expected_sha256)) {
        if (error_buf != NULL && error_buf_len > 0) {
            snprintf(error_buf, error_buf_len, "sha256 must be 64 hex chars");
        }
        return false;
    }
    if (expected_version == NULL || expected_version[0] == '\0') {
        if (error_buf != NULL && error_buf_len > 0) {
            snprintf(error_buf, error_buf_len, "version is required");
        }
        return false;
    }

    if (s_status_lock == NULL) {
        if (error_buf != NULL && error_buf_len > 0) {
            snprintf(error_buf, error_buf_len, "ota manager not initialized");
        }
        return false;
    }

    if (is_update_in_progress()) {
        if (error_buf != NULL && error_buf_len > 0) {
            snprintf(error_buf, error_buf_len, "ota already in progress");
        }
        return false;
    }

    ota_task_args_t *args = calloc(1, sizeof(ota_task_args_t));
    if (args == NULL) {
        if (error_buf != NULL && error_buf_len > 0) {
            snprintf(error_buf, error_buf_len, "out of memory");
        }
        return false;
    }

    snprintf(args->url, sizeof(args->url), "%s", url);
    snprintf(args->expected_sha256, sizeof(args->expected_sha256), "%s", expected_sha256);
    snprintf(args->expected_version, sizeof(args->expected_version), "%s", expected_version);

    xSemaphoreTake(s_status_lock, portMAX_DELAY);
    s_status.state = OTA_MANAGER_STATE_IN_PROGRESS;
    s_status.progress_percent = 0;
    s_status.reboot_scheduled = false;
    s_status.pending_boot_validation = false;
    status_set_message("starting update");
    status_set_error("");
    snprintf(s_status.version, sizeof(s_status.version), "%s", expected_version);
    xSemaphoreGive(s_status_lock);

    BaseType_t ok = xTaskCreate(ota_task,
                                "ota_task",
                                OTA_TASK_STACK_SIZE,
                                args,
                                OTA_TASK_PRIORITY,
                                NULL);
    if (ok != pdPASS) {
        free(args);
        set_failed_status("failed to start ota task");
        if (error_buf != NULL && error_buf_len > 0) {
            snprintf(error_buf, error_buf_len, "failed to start ota task");
        }
        return false;
    }

    return true;
}

void ota_manager_get_status(ota_manager_status_t *out_status) {
    if (out_status == NULL) {
        return;
    }

    if (s_status_lock == NULL) {
        memset(out_status, 0, sizeof(*out_status));
        out_status->state = OTA_MANAGER_STATE_FAILED;
        snprintf(out_status->message, sizeof(out_status->message), "%s", "ota manager not initialized");
        snprintf(out_status->last_error, sizeof(out_status->last_error), "%s", "ota manager not initialized");
        return;
    }

    xSemaphoreTake(s_status_lock, portMAX_DELAY);
    *out_status = s_status;
    xSemaphoreGive(s_status_lock);
}

idf_component_register(
    SRCS "telemetry_manager.c"
    INCLUDE_DIRS "include"
    REQUIRES esp_timer freertos
)

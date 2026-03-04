idf_component_register(
    SRCS "health_manager.c"
    INCLUDE_DIRS "include"
    REQUIRES esp_timer wifi_manager time_manager ota_manager
)

idf_component_register(
    SRCS "http_api.c"
    INCLUDE_DIRS "include"
    REQUIRES esp_http_server json led_controller sensor_manager wifi_manager sun_engine light_regulator dli_manager telemetry_manager time_manager device_identity ota_manager health_manager cloud_engine
)

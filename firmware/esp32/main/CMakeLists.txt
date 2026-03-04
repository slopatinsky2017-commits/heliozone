idf_component_register(
    SRCS "main.c"
    INCLUDE_DIRS "."
    REQUIRES wifi_manager http_api led_controller sensor_manager sun_engine light_regulator dli_manager telemetry_manager time_manager device_identity ota_manager mqtt_manager health_manager cloud_engine helio_controller
)

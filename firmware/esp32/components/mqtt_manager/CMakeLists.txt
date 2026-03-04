idf_component_register(
    SRCS "mqtt_manager.c"
    INCLUDE_DIRS "include"
    REQUIRES mqtt json device_identity telemetry_manager led_controller light_regulator dli_manager sun_engine health_manager cloud_engine
)

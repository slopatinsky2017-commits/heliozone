idf_component_register(
    SRCS "helio_controller.c"
    INCLUDE_DIRS "include"
    REQUIRES crop_profiles grow_engine zone_manager
)

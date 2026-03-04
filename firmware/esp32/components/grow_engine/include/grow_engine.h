#pragma once

#include "crop_profiles.h"

#ifdef __cplusplus
extern "C" {
#endif

void grow_engine_init(void);
void grow_engine_run(const crop_profile_t *profile);

#ifdef __cplusplus
}
#endif

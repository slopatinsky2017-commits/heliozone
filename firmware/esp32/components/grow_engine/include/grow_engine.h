#pragma once

#include "grow_profiles.h"

#ifdef __cplusplus
extern "C" {
#endif

void grow_engine_init(void);
void grow_engine_run(const grow_profile_t *profile);

#ifdef __cplusplus
}
#endif

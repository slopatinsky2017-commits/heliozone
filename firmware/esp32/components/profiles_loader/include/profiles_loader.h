#pragma once

#include "grow_profiles.h"

#ifdef __cplusplus
extern "C" {
#endif

void profiles_loader_init(void);
const grow_profile_t *profiles_loader_default(void);

#ifdef __cplusplus
}
#endif

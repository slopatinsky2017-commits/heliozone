#pragma once

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

bool device_identity_init(void);
const char *device_identity_get_id(void);

#ifdef __cplusplus
}
#endif

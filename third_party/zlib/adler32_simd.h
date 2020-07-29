/* adler32_simd.h
 *
 * Copyright 2017 The Chromium Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the Chromium source repository LICENSE file.
 */

#include <stdint.h>

#include "zconf.h"
#include "zutil.h"

uint32_t ZLIB_INTERNAL adler32_simd_(
    uint32_t adler,
    const unsigned char *buf,
    z_size_t len);

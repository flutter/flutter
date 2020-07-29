// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include "third_party/zlib/zlib.h"

static Bytef buffer[256 * 1024] = {0};

// Entry point for LibFuzzer.
extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size) {
  uLongf buffer_length = static_cast<uLongf>(sizeof(buffer));
  if (Z_OK !=
      uncompress(buffer, &buffer_length, data, static_cast<uLong>(size))) {
    return 0;
  }
  return 0;
}

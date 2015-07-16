// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/rand_util.h"

#include <nacl/nacl_random.h>

#include "base/basictypes.h"
#include "base/logging.h"

namespace {

void GetRandomBytes(void* output, size_t num_bytes) {
  char* output_ptr = static_cast<char*>(output);
  while (num_bytes > 0) {
    size_t nread;
    const int error = nacl_secure_random(output_ptr, num_bytes, &nread);
    CHECK_EQ(error, 0);
    CHECK_LE(nread, num_bytes);
    output_ptr += nread;
    num_bytes -= nread;
  }
}

}  // namespace

namespace base {

// NOTE: This function must be cryptographically secure. http://crbug.com/140076
uint64 RandUint64() {
  uint64 result;
  GetRandomBytes(&result, sizeof(result));
  return result;
}

void RandBytes(void* output, size_t output_length) {
  GetRandomBytes(output, output_length);
}

}  // namespace base

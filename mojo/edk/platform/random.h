// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_PLATFORM_RANDOM_H_
#define MOJO_EDK_PLATFORM_RANDOM_H_

#include <stddef.h>

namespace mojo {
namespace platform {

// Gets |num_bytes| bytes of cryptographic random bytes. (Implementations of
// this function must be thread-safe.)
void GetCryptoRandomBytes(void* bytes, size_t num_bytes);

}  // namespace platform
}  // namespace mojo

#endif  // MOJO_EDK_PLATFORM_RANDOM_H_

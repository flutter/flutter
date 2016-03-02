// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file implements the function declared //mojo/edk/platform/random.h.

#include "mojo/edk/platform/random.h"

#include "base/rand_util.h"

namespace mojo {
namespace platform {

void GetCryptoRandomBytes(void* bytes, size_t num_bytes) {
  // Note: We rely on |base::RandBytes()| being cryptographic (which it is).
  // (Otherwise, we'd have to depend on //crypto, which just then calls
  // |base::RandBytes()| anyway.)
  base::RandBytes(bytes, num_bytes);
}

}  // namespace platform
}  // namespace mojo

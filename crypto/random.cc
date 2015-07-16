// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/random.h"

#include "base/rand_util.h"

namespace crypto {

void RandBytes(void *bytes, size_t length) {
  // It's OK to call base::RandBytes(), because it's already strongly random.
  // But _other_ code should go through this function to ensure that code which
  // needs secure randomness is easily discoverable.
  base::RandBytes(bytes, length);
}

}  // namespace crypto


// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/secure_util.h"

namespace crypto {

bool SecureMemEqual(const void* s1, const void* s2, size_t n) {
  const unsigned char* s1_ptr = reinterpret_cast<const unsigned char*>(s1);
  const unsigned char* s2_ptr = reinterpret_cast<const unsigned char*>(s2);
  unsigned char tmp = 0;
  for (size_t i = 0; i < n; ++i, ++s1_ptr, ++s2_ptr)
    tmp |= *s1_ptr ^ *s2_ptr;
  return (tmp == 0);
}

}  // namespace crypto


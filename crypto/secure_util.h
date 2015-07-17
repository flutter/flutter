// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CRYPTO_SECURE_UTIL_H_
#define CRYPTO_SECURE_UTIL_H_

#include <stddef.h>

#include "crypto/crypto_export.h"

namespace crypto {

// Performs a constant-time comparison of two strings, returning true if the
// strings are equal.
//
// For cryptographic operations, comparison functions such as memcmp() may
// expose side-channel information about input, allowing an attacker to
// perform timing analysis to determine what the expected bits should be. In
// order to avoid such attacks, the comparison must execute in constant time,
// so as to not to reveal to the attacker where the difference(s) are.
// For an example attack, see
// http://groups.google.com/group/keyczar-discuss/browse_thread/thread/5571eca0948b2a13
CRYPTO_EXPORT bool SecureMemEqual(const void* s1, const void* s2, size_t n);

}  // namespace crypto

#endif  // CRYPTO_SECURE_UTIL_H_


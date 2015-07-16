// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_RAND_UTIL_H_
#define BASE_RAND_UTIL_H_

#include <string>

#include "base/base_export.h"
#include "base/basictypes.h"

namespace base {

// Returns a random number in range [0, kuint64max]. Thread-safe.
BASE_EXPORT uint64 RandUint64();

// Returns a random number between min and max (inclusive). Thread-safe.
BASE_EXPORT int RandInt(int min, int max);

// Returns a random number in range [0, range).  Thread-safe.
//
// Note that this can be used as an adapter for std::random_shuffle():
// Given a pre-populated |std::vector<int> myvector|, shuffle it as
//   std::random_shuffle(myvector.begin(), myvector.end(), base::RandGenerator);
BASE_EXPORT uint64 RandGenerator(uint64 range);

// Returns a random double in range [0, 1). Thread-safe.
BASE_EXPORT double RandDouble();

// Given input |bits|, convert with maximum precision to a double in
// the range [0, 1). Thread-safe.
BASE_EXPORT double BitsToOpenEndedUnitInterval(uint64 bits);

// Fills |output_length| bytes of |output| with random data.
//
// WARNING:
// Do not use for security-sensitive purposes.
// See crypto/ for cryptographically secure random number generation APIs.
BASE_EXPORT void RandBytes(void* output, size_t output_length);

// Fills a string of length |length| with random data and returns it.
// |length| should be nonzero.
//
// Note that this is a variation of |RandBytes| with a different return type.
// The returned string is likely not ASCII/UTF-8. Use with care.
//
// WARNING:
// Do not use for security-sensitive purposes.
// See crypto/ for cryptographically secure random number generation APIs.
BASE_EXPORT std::string RandBytesAsString(size_t length);

#if defined(OS_POSIX)
BASE_EXPORT int GetUrandomFD();
#endif

}  // namespace base

#endif  // BASE_RAND_UTIL_H_

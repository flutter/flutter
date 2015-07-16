// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/guid.h"

#include "base/rand_util.h"
#include "base/strings/stringprintf.h"

namespace base {

std::string GenerateGUID() {
  uint64 sixteen_bytes[2] = { base::RandUint64(), base::RandUint64() };

  // Set the GUID to version 4 as described in RFC 4122, section 4.4.
  // The format of GUID version 4 must be xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx,
  // where y is one of [8, 9, A, B].

  // Clear the version bits and set the version to 4:
  sixteen_bytes[0] &= 0xffffffffffff0fffULL;
  sixteen_bytes[0] |= 0x0000000000004000ULL;

  // Set the two most significant bits (bits 6 and 7) of the
  // clock_seq_hi_and_reserved to zero and one, respectively:
  sixteen_bytes[1] &= 0x3fffffffffffffffULL;
  sixteen_bytes[1] |= 0x8000000000000000ULL;

  return RandomDataToGUIDString(sixteen_bytes);
}

// TODO(cmasone): Once we're comfortable this works, migrate Windows code to
// use this as well.
std::string RandomDataToGUIDString(const uint64 bytes[2]) {
  return StringPrintf("%08X-%04X-%04X-%04X-%012llX",
                      static_cast<unsigned int>(bytes[0] >> 32),
                      static_cast<unsigned int>((bytes[0] >> 16) & 0x0000ffff),
                      static_cast<unsigned int>(bytes[0] & 0x0000ffff),
                      static_cast<unsigned int>(bytes[1] >> 48),
                      bytes[1] & 0x0000ffffffffffffULL);
}

}  // namespace base

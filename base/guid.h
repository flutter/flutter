// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_GUID_H_
#define BASE_GUID_H_

#include <string>

#include "base/base_export.h"
#include "base/basictypes.h"
#include "build/build_config.h"

namespace base {

// Generate a 128-bit random GUID of the form: "%08X-%04X-%04X-%04X-%012llX".
// If GUID generation fails an empty string is returned.
// The POSIX implementation uses pseudo random number generation to create
// the GUID.  The Windows implementation uses system services.
BASE_EXPORT std::string GenerateGUID();

// Returns true if the input string conforms to the GUID format.
BASE_EXPORT bool IsValidGUID(const std::string& guid);

#if defined(OS_POSIX)
// For unit testing purposes only.  Do not use outside of tests.
BASE_EXPORT std::string RandomDataToGUIDString(const uint64 bytes[2]);
#endif

}  // namespace base

#endif  // BASE_GUID_H_

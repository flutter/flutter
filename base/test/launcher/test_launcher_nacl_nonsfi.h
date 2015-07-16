// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_LAUNCHER_TEST_LAUNCHER_NACL_NONSFI_H_
#define BASE_TEST_LAUNCHER_TEST_LAUNCHER_NACL_NONSFI_H_

#include <string>

namespace base {

// Launches the NaCl Non-SFI test binary |test_binary|.
int TestLauncherNonSfiMain(const std::string& test_binary);

}  // namespace base

#endif  // BASE_TEST_LAUNCHER_TEST_LAUNCHER_NACL_NONSFI_H_

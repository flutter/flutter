// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_TONIC_PLATFORM_UTILS_H_
#define LIB_TONIC_PLATFORM_UTILS_H_

namespace tonic {

// Calls the equivalent of exit(status) for a given platform.
void PlatformExit(int status);

}  // namespace tonic

#endif  // LIB_TONIC_PLATFORM_UTILS_H_

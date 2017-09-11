// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTER_MAIN_IOS_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTER_MAIN_IOS_H_

#include "lib/fxl/macros.h"

namespace shell {

/// Initializes the Flutter shell. This must be called before interacting with
/// the engine in any way. It is safe to call this method multiple times.
void FlutterMain();

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTER_MAIN_IOS_H_

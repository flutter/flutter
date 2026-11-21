// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_BUILD_BAZEL_TOOLCHAINS_TESTS_MACOS_SWIFT_SMOKE_BRIDGING_H_
#define FLUTTER_BUILD_BAZEL_TOOLCHAINS_TESTS_MACOS_SWIFT_SMOKE_BRIDGING_H_

// The bridging header of the Swift smoke module (flutter_swift_library's
// bridge_header): the C the Swift calls, declared by a header reached
// through the deps' include directories, as darwin/common's bridging
// header reaches fml's.
#include "flutter/build/bazel/toolchains/tests/macos_swift_smoke_c.h"

#endif  // FLUTTER_BUILD_BAZEL_TOOLCHAINS_TESTS_MACOS_SWIFT_SMOKE_BRIDGING_H_

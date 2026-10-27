// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_BUILD_BAZEL_TOOLCHAINS_TESTS_MACOS_SWIFT_SMOKE_C_H_
#define FLUTTER_BUILD_BAZEL_TOOLCHAINS_TESTS_MACOS_SWIFT_SMOKE_C_H_

#ifdef __cplusplus
extern "C" {
#endif

// C the Swift smoke module calls through its bridging header.
int FlutterBazelSwiftSmokeCAnswer(void);

#ifdef __cplusplus
}
#endif

#endif  // FLUTTER_BUILD_BAZEL_TOOLCHAINS_TESTS_MACOS_SWIFT_SMOKE_C_H_

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_BUILD_BAZEL_TOOLCHAINS_TESTS_MACOS_OBJC_SMOKE_H_
#define FLUTTER_BUILD_BAZEL_TOOLCHAINS_TESTS_MACOS_OBJC_SMOKE_H_

#include <string>

// Objective-C++ (macos_objc_smoke.mm, an objc_library) called from C++.

// Whether the Objective-C++ translation unit was compiled with ARC.
bool FlutterBazelSmokeObjcUsesArc();

// `text` upper-cased by NSString: Foundation, linked through the SDK.
std::string FlutterBazelSmokeUppercase(const std::string& text);

// Constructs and releases an Objective-C object holding a C++ member whose
// constructor and destructor each count once: 2 when both ran.
int FlutterBazelSmokeCxxMemberLifetime();

#endif  // FLUTTER_BUILD_BAZEL_TOOLCHAINS_TESTS_MACOS_OBJC_SMOKE_H_

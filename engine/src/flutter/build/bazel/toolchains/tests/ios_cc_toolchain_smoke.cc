// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Checks that an iOS toolchain compiles and links the way the GN build
// does (build/toolchain/mac's ios_clang_arm, ios_clang_arm_sim and
// ios_clang_x64_sim): the same language mode, the engine's own libc++, the
// iPhoneOS or iPhoneSimulator SDK as sysroot with GN's deployment target,
// no exceptions or RTTI, and Objective-C++ against Foundation.
//
// A program rather than a gtest suite: nothing on the host runs an iOS
// binary, so the checks print and exit non-zero on a failure, and a Mac runs
// the simulator build under `xcrun simctl spawn <device> <binary>` (the
// device build is a link check alone). GN runs no gtest on iOS either
// (testing.gni's enable_unittests is false there).

#include <Availability.h>        // The SDK's deployment-target macros.
#include <TargetConditionals.h>  // The SDK's platform macros.

#include <cstdio>
#include <cstring>
#include <sstream>
#include <string>
#include <vector>

#include "flutter/build/bazel/toolchains/tests/macos_objc_smoke.h"

extern "C" int FlutterBazelSmokeAddFromC(int a, int b);

#define FLUTTER_STRINGIFY_IMPL(x) #x
#define FLUTTER_STRINGIFY(x) FLUTTER_STRINGIFY_IMPL(x)

namespace {

int failures = 0;

void Check(bool condition, const char* what) {
  std::printf("%s: %s\n", condition ? "ok" : "FAILED", what);
  if (!condition) {
    ++failures;
  }
}

}  // namespace

int main() {
  static_assert(__cplusplus >= 202002L, "GN builds with -std=c++20");
  static_assert(sizeof(void*) == 8, "GN builds 64-bit binaries");

  // The engine's libc++ (its own ABI namespace, as on Linux and macOS), not
  // the SDK's.
  Check(std::strcmp(FLUTTER_STRINGIFY(_LIBCPP_ABI_NAMESPACE), "__fl") == 0,
        "the engine's libc++ headers (_LIBCPP_ABI_NAMESPACE == __fl)");
#if !defined(_LIBCPP_VERSION)
  Check(false, "libc++ headers were used");
#endif

  // -isysroot an iOS SDK of the host's Xcode, and
  // -miphoneos-version-min / -mios-simulator-version-min=15.0
  // (darwin_sdk.gni's ios_deployment_target), which the SDK's headers turn
  // into this macro.
#if defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE
  Check(true, "TargetConditionals.h came from an iOS SDK");
#else
  Check(false, "TargetConditionals.h came from an iOS SDK");
#endif
#if defined(TARGET_OS_SIMULATOR) && TARGET_OS_SIMULATOR
  std::printf("environment: simulator\n");
#else
  std::printf("environment: device\n");
#endif
  Check(__IPHONE_OS_VERSION_MIN_REQUIRED == 150000,
        "__IPHONE_OS_VERSION_MIN_REQUIRED == 150000 (GN's deployment target)");
  Check(__IPHONE_OS_VERSION_MAX_ALLOWED >= 150000,
        "__IPHONE_OS_VERSION_MAX_ALLOWED >= 150000");

#if defined(__cpp_exceptions) || defined(__EXCEPTIONS)
  Check(false, "GN builds with -fno-exceptions");
#endif
#if defined(__cpp_rtti) || defined(__GXX_RTTI)
  Check(false, "GN builds with -fno-rtti");
#endif

  Check(FlutterBazelSmokeAddFromC(40, 2) == 42, "C compiles and links");

  std::vector<std::string> parts;
  parts.reserve(3);
  for (int i = 0; i < 3; ++i) {
    parts.push_back(std::to_string(i));
  }
  std::ostringstream joined;
  for (const auto& part : parts) {
    joined << part << ',';
  }
  Check(joined.str() == "0,1,2,", "the libc++ runtime works");

  // objc_library compiled the .mm (with ARC, the engine's Objective-C
  // flags) and the link found Foundation through the SDK.
  Check(FlutterBazelSmokeObjcUsesArc(), "Objective-C++ compiled with ARC");
  Check(FlutterBazelSmokeUppercase("flutter") == "FLUTTER",
        "Foundation linked through the SDK");
  Check(FlutterBazelSmokeCxxMemberLifetime() == 2,
        "a C++ member of an Objective-C object is constructed and destroyed");

  std::printf("%s\n", failures == 0 ? "PASSED" : "FAILED");
  return failures == 0 ? 0 : 1;
}

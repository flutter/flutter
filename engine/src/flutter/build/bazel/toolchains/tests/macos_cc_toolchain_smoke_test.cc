// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Checks that the macOS toolchain compiles and links the way the GN build
// does on a Mac: the same language mode, the engine's own libc++, the Xcode
// SDK as sysroot with GN's deployment target, no exceptions or RTTI, and
// Objective-C++ through objc_library against Foundation.

#include <Availability.h>        // The SDK's deployment-target macros.
#include <TargetConditionals.h>  // The SDK's platform macros.

#include <cstdint>
#include <sstream>
#include <string>
#include <vector>

#include "gtest/gtest.h"

#include "flutter/build/bazel/toolchains/tests/macos_objc_smoke.h"

extern "C" int FlutterBazelSmokeAddFromC(int a, int b);

#define FLUTTER_STRINGIFY_IMPL(x) #x
#define FLUTTER_STRINGIFY(x) FLUTTER_STRINGIFY_IMPL(x)

namespace {

TEST(MacosCcToolchain, LanguageStandard) {
  static_assert(__cplusplus >= 202002L, "GN builds with -std=c++20");
  static_assert(sizeof(void*) == 8, "GN builds 64-bit binaries");
}

TEST(MacosCcToolchain, UsesTheEnginesLibcxx) {
  // The engine's libc++ is configured by
  // //flutter/build/secondary/flutter/third_party/libcxx/config/__config_site,
  // which puts the library in its own ABI namespace; the SDK's libc++ uses
  // the default (__1), so this proves both the headers and the linked
  // runtime are the engine's, as on Linux.
  EXPECT_STREQ(FLUTTER_STRINGIFY(_LIBCPP_ABI_NAMESPACE), "__fl");
#if !defined(_LIBCPP_VERSION)
  FAIL() << "libc++ headers were not used";
#endif
}

TEST(MacosCcToolchain, UsesTheSdkWithGnsDeploymentTarget) {
  // -isysroot the SDK of the host's Xcode, and -mmacosx-version-min=12.0.0
  // (tools/gn's mac_deployment_target), which the SDK's headers turn into
  // this macro.
#if !defined(TARGET_OS_OSX) || !TARGET_OS_OSX
  FAIL() << "TargetConditionals.h did not come from a macOS SDK";
#endif
  EXPECT_EQ(__MAC_OS_X_VERSION_MIN_REQUIRED, 120000);
  EXPECT_GE(__MAC_OS_X_VERSION_MAX_ALLOWED, 120000);
}

TEST(MacosCcToolchain, NoExceptionsNoRtti) {
#if defined(__cpp_exceptions) || defined(__EXCEPTIONS)
  FAIL() << "GN builds with -fno-exceptions";
#endif
#if defined(__cpp_rtti) || defined(__GXX_RTTI)
  FAIL() << "GN builds with -fno-rtti";
#endif
}

TEST(MacosCcToolchain, CompilesC) {
  EXPECT_EQ(FlutterBazelSmokeAddFromC(40, 2), 42);
}

TEST(MacosCcToolchain, LibcxxRuntimeWorks) {
  std::vector<std::string> parts;
  parts.reserve(3);
  for (int i = 0; i < 3; ++i) {
    parts.push_back(std::to_string(i));
  }
  std::ostringstream joined;
  for (const auto& part : parts) {
    joined << part << ',';
  }
  EXPECT_EQ(joined.str(), "0,1,2,");
}

TEST(MacosCcToolchain, ObjectiveCxxAgainstFoundation) {
  // objc_library compiled the .mm (with ARC, the engine's Objective-C
  // flags) and the link found Foundation through the SDK.
  EXPECT_TRUE(FlutterBazelSmokeObjcUsesArc());
  EXPECT_EQ(FlutterBazelSmokeUppercase("flutter"), "FLUTTER");
  // A C++ object inside an Objective-C one is constructed and destroyed
  // (-fobjc-call-cxx-cdtors, GN's one toolchain-wide Objective-C++ flag).
  EXPECT_EQ(FlutterBazelSmokeCxxMemberLifetime(), 2);
}

}  // namespace

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Checks that the hermetic Bazel toolchain compiles and links the way the GN
// build does: the same language mode, the engine's own libc++, the Debian
// sysroot, and no exceptions or RTTI.

#include <features.h>  // glibc's version macros, from the sysroot.

#include <cstdint>
#include <memory>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

#include "gtest/gtest.h"

extern "C" int FlutterBazelSmokeAddFromC(int a, int b);

#define FLUTTER_STRINGIFY_IMPL(x) #x
#define FLUTTER_STRINGIFY(x) FLUTTER_STRINGIFY_IMPL(x)

namespace {

TEST(CcToolchain, LanguageStandard) {
  static_assert(__cplusplus >= 202002L, "GN builds with -std=c++20");
  static_assert(sizeof(void*) == 8, "GN builds host binaries with -m64");
}

TEST(CcToolchain, UsesTheEnginesLibcxx) {
  // The engine's libc++ is configured by
  // //flutter/build/secondary/flutter/third_party/libcxx/config/__config_site,
  // which puts the library in its own ABI namespace. The toolchain's bundled
  // libc++ uses the default (__1), so this proves both the headers and the
  // linked runtime are the engine's.
  EXPECT_STREQ(FLUTTER_STRINGIFY(_LIBCPP_ABI_NAMESPACE), "__fl");
#if !defined(_LIBCPP_VERSION)
  FAIL() << "libc++ headers were not used";
#endif
}

TEST(CcToolchain, UsesTheDebianSysroot) {
  // Debian bullseye ships glibc 2.31, but the Chrome sysroot creator patches
  // features.h to advertise 2.26 so that code checking __GLIBC_MINOR__ keeps
  // the binaries compatible with older distributions:
  //
  //   #define __GLIBC_MINOR__ 26 // 31
  //
  // No regular distribution reports 2.26 in 2026, so this is a reliable
  // fingerprint of the sysroot, as opposed to the host's /usr/include.
  EXPECT_EQ(__GLIBC__, 2);
  EXPECT_EQ(__GLIBC_MINOR__, 26);
}

TEST(CcToolchain, NoExceptionsNoRtti) {
#if defined(__cpp_exceptions) || defined(__EXCEPTIONS)
  FAIL() << "GN builds with -fno-exceptions";
#endif
#if defined(__cpp_rtti) || defined(__GXX_RTTI)
  FAIL() << "GN builds with -fno-rtti";
#endif
}

TEST(CcToolchain, CompilesC) {
  EXPECT_EQ(FlutterBazelSmokeAddFromC(40, 2), 42);
}

TEST(CcToolchain, LibcxxRuntimeWorks) {
  std::vector<std::string> parts;
  for (int i = 0; i < 3; ++i) {
    parts.push_back(std::to_string(i));
  }
  std::ostringstream joined;
  for (const auto& part : parts) {
    joined << part << ',';
  }
  EXPECT_EQ(joined.str(), "0,1,2,");

  auto shared = std::make_shared<int64_t>(7);
  std::thread thread([shared] { *shared *= 6; });
  thread.join();
  EXPECT_EQ(*shared, 42);
}

}  // namespace

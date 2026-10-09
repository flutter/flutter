// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Smoke test for the Bazel-wrapped GN build of the Dart SDK: links the VM
// archive the way an embedder does and starts the VM.

#include <cstring>
#include <string>

#include "gtest/gtest.h"
#include "third_party/dart/runtime/include/bin/dart_io_api.h"
#include "third_party/dart/runtime/include/dart_api.h"

namespace {

// The wrapped build stamps the version from tools/VERSION without a git hash
// (dart_version_git_info = false), so the string starts with the SDK
// version and names the channel.
TEST(DartWrap, VersionStringIsStamped) {
  const char* version = Dart_VersionString();
  ASSERT_NE(version, nullptr);
  std::string str(version);
  EXPECT_NE(str.find("3.14.0"), std::string::npos) << str;
  EXPECT_NE(str.find("(dev)"), std::string::npos) << str;
  EXPECT_EQ(str.find("0000000000"), std::string::npos)
      << "placeholder git hash in " << str;
}

TEST(DartWrap, IsJitRuntime) {
  EXPECT_FALSE(Dart_IsPrecompiledRuntime());
}

// Initializes and tears down the VM without creating an isolate, which
// exercises the archive's object closure (VM, platform, compiler, ICU for
// the regexp engine) at link time and its static initialization at run time.
TEST(DartWrap, InitializeAndCleanup) {
  char* flags_error = Dart_SetVMFlags(0, nullptr);
  ASSERT_EQ(flags_error, nullptr) << flags_error;

  Dart_InitializeParams params;
  std::memset(&params, 0, sizeof(params));
  params.version = DART_INITIALIZE_PARAMS_CURRENT_VERSION;

  char* init_error = Dart_Initialize(&params);
  ASSERT_EQ(init_error, nullptr) << init_error;

  char* cleanup_error = Dart_Cleanup();
  EXPECT_EQ(cleanup_error, nullptr) << cleanup_error;
}

// Links the dart:io embedder library the way the engine's DartVM does, which
// reaches BoringSSL (entropy, TLS) and zlib through the Bazel-built
// libraries rather than through the archive.
TEST(DartWrap, DartIoBootstrapsAndCleansUp) {
  dart::bin::BootstrapDartIo();
  uint8_t entropy[16] = {};
  EXPECT_TRUE(dart::bin::GetEntropy(entropy, sizeof(entropy)));
  dart::bin::CleanupDartIo();
}

}  // namespace

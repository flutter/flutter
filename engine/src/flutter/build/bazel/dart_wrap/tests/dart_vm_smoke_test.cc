// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Smoke test for the Bazel-wrapped GN build of the Dart SDK: links the VM
// archive the way an embedder does and starts the VM.

#include <cstdio>
#include <cstring>
#include <fstream>
#include <map>
#include <sstream>
#include <string>

#include "gtest/gtest.h"
#include "third_party/dart/runtime/include/bin/dart_io_api.h"
#include "third_party/dart/runtime/include/dart_api.h"

namespace {

// The path of the Dart tree's tools/VERSION, the test's one argument.
std::string g_version_file;

// `MAJOR.MINOR.PATCH-PRERELEASE.PRERELEASE_PATCH.CHANNEL` from tools/VERSION,
// as tools/make_version.py spells a dev or beta version (`3.15.0-101.0.dev`;
// a stable release is `MAJOR.MINOR.PATCH`).
std::string ExpectedVersion() {
  std::ifstream file(g_version_file);
  EXPECT_TRUE(file.is_open()) << g_version_file;
  std::map<std::string, std::string> fields;
  std::string line;
  while (std::getline(file, line)) {
    if (line.empty() || line[0] == '#') {
      continue;
    }
    std::istringstream words(line);
    std::string key, value;
    if (words >> key >> value) {
      fields[key] = value;
    }
  }
  std::string version =
      fields["MAJOR"] + "." + fields["MINOR"] + "." + fields["PATCH"];
  if (fields["CHANNEL"] != "stable") {
    version += "-" + fields["PRERELEASE"] + "." + fields["PRERELEASE_PATCH"] +
               "." + fields["CHANNEL"];
  }
  return version;
}

// The wrapped build stamps the version from tools/VERSION without a git hash
// (dart_version_git_info = false), so the string starts with the SDK
// version and names the channel.
TEST(DartWrap, VersionStringIsStamped) {
  const char* version = Dart_VersionString();
  ASSERT_NE(version, nullptr);
  std::string str(version);
  const std::string expected = ExpectedVersion();
  EXPECT_FALSE(expected.empty());
  EXPECT_EQ(str.find(expected), 0u) << str << " should start with " << expected;
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

int main(int argc, char** argv) {
  testing::InitGoogleTest(&argc, argv);
  if (argc != 2) {
    std::fprintf(stderr, "usage: %s <path of the Dart tree's tools/VERSION>\n",
                 argv[0]);
    return 2;
  }
  g_version_file = argv[1];
  return RUN_ALL_TESTS();
}

// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/bind.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/path_service.h"
#include "crypto/random.h"
#include "mojo/dart/embedder/dart_controller.h"
#include "mojo/public/c/system/types.h"
#include "mojo/public/cpp/environment/environment.h"
#include "testing/gtest/include/gtest/gtest.h"

// TODO(zra): Pull vm options from the test scripts.

namespace mojo {
namespace dart {
namespace {

static bool generateEntropy(uint8_t* buffer, intptr_t length) {
  crypto::RandBytes(reinterpret_cast<void*>(buffer), length);
  return true;
}

static void exceptionCallback(bool* exception, Dart_Handle error) {
  *exception = true;
}

static void RunTest(const std::string& test,
                    bool compile_all,
                    const char** extra_args,
                    int num_extra_args) {
  base::FilePath path;
  PathService::Get(base::DIR_SOURCE_ROOT, &path);
  path = path.AppendASCII("mojo")
             .AppendASCII("dart")
             .AppendASCII("test")
             .AppendASCII(test);

  // Read in the source.
  std::string source;
  EXPECT_TRUE(ReadFileToString(path, &source)) << "Failed to read test file";

  // Setup the package root.
  base::FilePath package_root;
  PathService::Get(base::DIR_EXE, &package_root);
  package_root = package_root.AppendASCII("gen")
                             .AppendASCII("dart-pkg")
                             .AppendASCII("packages");

  char* error = NULL;
  bool unhandled_exception = false;
  DartControllerConfig config;
  // Run with strict compilation even in Release mode so that ASAN testing gets
  // coverage of Dart asserts, type-checking, etc.
  config.strict_compilation = true;
  config.script = source;
  config.script_uri = path.AsUTF8Unsafe();
  config.package_root = package_root.AsUTF8Unsafe();
  config.application_data = nullptr;
  config.callbacks.exception =
      base::Bind(&exceptionCallback, &unhandled_exception);
  config.entropy = generateEntropy;
  config.arguments = extra_args;
  config.arguments_count = num_extra_args;
  config.handle = MOJO_HANDLE_INVALID;
  config.compile_all = compile_all;
  config.error = &error;

  bool success = DartController::RunSingleDartScript(config);
  EXPECT_TRUE(success) << error;
  EXPECT_FALSE(unhandled_exception);
}

// TODO(zra): instead of listing all these tests, search //mojo/dart/test for
// _test.dart files.

TEST(DartTest, hello_mojo) {
  RunTest("hello_mojo.dart", false, nullptr, 0);
}

TEST(DartTest, core_types_test) {
  RunTest("core_types_test.dart", false, nullptr, 0);
}

TEST(DartTest, async_test) {
  RunTest("async_test.dart", false, nullptr, 0);
}

TEST(DartTest, isolate_test) {
  RunTest("isolate_test.dart", false, nullptr, 0);
}

TEST(DartTest, import_mojo) {
  RunTest("import_mojo.dart", false, nullptr, 0);
}

TEST(DartTest, simple_handle_watcher_test) {
  RunTest("simple_handle_watcher_test.dart", false, nullptr, 0);
}

TEST(DartTest, ping_pong_test) {
  RunTest("ping_pong_test.dart", false, nullptr, 0);
}

TEST(DartTest, timer_test) {
  RunTest("timer_test.dart", false, nullptr, 0);
}

TEST(DartTest, async_await_test) {
  RunTest("async_await_test.dart", false, nullptr, 0);
}

TEST(DartTest, core_test) {
  RunTest("core_test.dart", false, nullptr, 0);
}

TEST(DartTest, codec_test) {
  RunTest("codec_test.dart", false, nullptr, 0);
}

TEST(DartTest, handle_watcher_test) {
  RunTest("handle_watcher_test.dart", false, nullptr, 0);
}

TEST(DartTest, bindings_generation_test) {
  RunTest("bindings_generation_test.dart", false, nullptr, 0);
}

TEST(DartTest, compile_all_interfaces_test) {
  RunTest("compile_all_interfaces_test.dart", true, nullptr, 0);
}

TEST(DartTest, uri_base_test) {
  RunTest("uri_base_test.dart", false, nullptr, 0);
}

TEST(DartTest, exception_test) {
  RunTest("exception_test.dart", false, nullptr, 0);
}

TEST(DartTest, control_messages_test) {
  RunTest("control_messages_test.dart", false, nullptr, 0);
}

TEST(DartTest, handle_finalizer_test) {
  const int kNumArgs = 2;
  const char* args[kNumArgs];
  args[0] = "--new-gen-semi-max-size=1";
  args[1] = "--old_gen_growth_rate=1";
  RunTest("handle_finalizer_test.dart", false, args, kNumArgs);
}

}  // namespace
}  // namespace dart
}  // namespace mojo

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <stdio.h>

#include <algorithm>
#include <string>
#include <vector>

#include "base/bind.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/path_service.h"
#include "crypto/random.h"
#include "mojo/dart/embedder/dart_controller.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace dart {
namespace {

std::string GetPath() {
  base::FilePath path;
  PathService::Get(base::DIR_SOURCE_ROOT, &path);
  path = path.AppendASCII("mojo")
             .AppendASCII("public")
             .AppendASCII("interfaces")
             .AppendASCII("bindings")
             .AppendASCII("tests")
             .AppendASCII("data")
             .AppendASCII("validation");

  return path.AsUTF8Unsafe();
}

static bool generateEntropy(uint8_t* buffer, intptr_t length) {
  crypto::RandBytes(reinterpret_cast<void*>(buffer), length);
  return true;
}

static void exceptionCallback(bool* exception, Dart_Handle error) {
  *exception = true;
}

static void RunTest(const std::string& test) {
  base::FilePath path;
  PathService::Get(base::DIR_SOURCE_ROOT, &path);
  path = path.AppendASCII("mojo")
             .AppendASCII("dart")
             .AppendASCII("test")
             .AppendASCII("validation_test.dart");

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
  config.script = source;
  // Run with strict compilation even in Release mode so that ASAN testing gets
  // coverage of Dart asserts, type-checking, etc.
  config.strict_compilation = true;
  config.script_uri = test;
  config.package_root = package_root.AsUTF8Unsafe();
  config.application_data = nullptr;
  config.callbacks.exception =
      base::Bind(&exceptionCallback, &unhandled_exception);
  config.entropy = generateEntropy;
  config.arguments = nullptr;
  config.arguments_count = 0;
  config.handle = MOJO_HANDLE_INVALID;
  config.compile_all = false;
  config.error = &error;

  bool success = DartController::RunSingleDartScript(config);
  EXPECT_TRUE(success) << error;
  EXPECT_FALSE(unhandled_exception);
}

TEST(DartTest, validation) {
  RunTest(GetPath());
}

}  // namespace
}  // namespace dart
}  // namespace mojo

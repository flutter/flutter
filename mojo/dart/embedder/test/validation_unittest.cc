// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <stdio.h>

#include <algorithm>
#include <string>
#include <vector>

#include "base/bind.h"
#include "base/files/file_enumerator.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/path_service.h"
#include "base/rand_util.h"
#include "base/strings/string_util.h"
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
  base::RandBytes(reinterpret_cast<void*>(buffer), length);
  return true;
}

static void exceptionCallback(bool* exception, Dart_Handle error) {
  *exception = true;
}

// Enumerates files inside |path| and collects all data needed to run
// conformance tests.
// For each test there are three entries in the returned vector.
// [0] -> test name.
// [1] -> contents of test's .data file.
// [2] -> contents of test's .expected file.
static std::vector<std::string> CollectTests(base::FilePath path) {
  base::FileEnumerator enumerator(path, false, base::FileEnumerator::FILES);
  std::set<std::string> tests;
  while (true) {
    base::FilePath file_path = enumerator.Next();
    if (file_path.empty()) {
      break;
    }
    file_path = file_path.RemoveExtension();
    tests.insert(file_path.value());
  }
  std::vector<std::string> result;
  for (auto it = tests.begin(); it != tests.end(); it++) {
    const std::string& test_name = *it;
    std::string source;
    bool r;
    std::string filename = base::FilePath(test_name).BaseName().value();
    if (!StartsWithASCII(filename, "conformance_", true)) {
      // Only include conformance tests.
      continue;
    }
    base::FilePath data_path(test_name);
    data_path = data_path.AddExtension(".data");
    base::FilePath expected_path(test_name);
    expected_path = expected_path.AddExtension(".expected");
    // Test name.
    result.push_back(test_name.c_str());
    // Test's .data.
    r = ReadFileToString(data_path, &source);
    DCHECK(r);
    result.push_back(source);
    source.clear();
    // Test's .expected.
    r = ReadFileToString(expected_path, &source);
    DCHECK(r);
    result.push_back(source);
    source.clear();
  }
  return result;
}

static void RunTest(const std::string& test) {
  // Gather test data.
  std::vector<std::string> arguments = CollectTests(base::FilePath(test));
  DCHECK(arguments.size() > 0);
  // Grab the C string pointer.
  std::vector<const char*> arguments_c_str;
  for (size_t i = 0; i < arguments.size(); i++) {
    arguments_c_str.push_back(arguments[i].c_str());
  }
  DCHECK(arguments.size() == arguments_c_str.size());

  base::FilePath path;
  PathService::Get(base::DIR_SOURCE_ROOT, &path);
  path = path.AppendASCII("mojo")
             .AppendASCII("dart")
             .AppendASCII("test")
             .AppendASCII("validation_test.dart");

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
  config.script_uri = path.value();
  config.package_root = package_root.AsUTF8Unsafe();
  config.callbacks.exception =
      base::Bind(&exceptionCallback, &unhandled_exception);
  config.entropy = generateEntropy;
  config.SetVmFlags(nullptr, 0);
  config.error = &error;
  config.SetScriptFlags(arguments_c_str.data(), arguments_c_str.size());

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

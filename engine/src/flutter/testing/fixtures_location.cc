// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// The compiled-in default locations that flutter::testing::GetSourcePath,
// GetFixturesPath and GetTestingAssetsPath fall back to when the corresponding
// FLUTTER_TEST_*_DIR environment variable is not set, and the source URI
// prefix GetSourceUri joins.
//
// GN generates an equivalent translation unit per test_fixtures target with
// absolute paths baked in (see the fixtures_location template in
// testing.gni). Under Bazel this file is compiled once per fixtures target
// with the four values passed as macros by flutter_test_fixtures (see
// testing.bzl): the paths are relative to the runfiles root, which is the
// working directory Bazel runs tests in, and the URI prefix is the virtual
// root the Dart sources are compiled under (build/bazel/dart/kernel.bzl).

#include "flutter/testing/testing.h"

#if !defined(FLUTTER_TEST_SOURCE_DIR_DEFAULT) ||         \
    !defined(FLUTTER_TEST_FIXTURES_DIR_DEFAULT) ||       \
    !defined(FLUTTER_TEST_TESTING_ASSETS_DIR_DEFAULT) || \
    !defined(FLUTTER_TEST_SOURCE_URI_PREFIX_DEFAULT)
#error "This file is only meaningful with the default locations defined."
#endif

namespace flutter::testing {

const char* GetCompiledInSourcePath() {
  return FLUTTER_TEST_SOURCE_DIR_DEFAULT;
}

const char* GetCompiledInFixturesPath() {
  return FLUTTER_TEST_FIXTURES_DIR_DEFAULT;
}

const char* GetCompiledInTestingAssetsPath() {
  return FLUTTER_TEST_TESTING_ASSETS_DIR_DEFAULT;
}

const char* GetCompiledInSourceUriPrefix() {
  return FLUTTER_TEST_SOURCE_URI_PREFIX_DEFAULT;
}

}  // namespace flutter::testing

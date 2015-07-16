// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_EXPECTATIONS_EXPECTATION_H_
#define BASE_TEST_EXPECTATIONS_EXPECTATION_H_

#include <string>
#include <vector>

#include "base/base_export.h"
#include "base/compiler_specific.h"
#include "base/strings/string_piece.h"

namespace test_expectations {

// A Result is the expectation of a test's behavior.
enum Result {
  // The test has a failing assertion.
  RESULT_FAILURE,

  // The test does not complete within the test runner's alloted duration.
  RESULT_TIMEOUT,

  // The test crashes during the course of its execution.
  RESULT_CRASH,

  // The test should not be run ever.
  RESULT_SKIP,

  // The test passes, used to override a more general expectation.
  RESULT_PASS,
};

// Converts a text string form of a |result| to its enum value, written to
// |out_result|. Returns true on success and false on error.
bool ResultFromString(const base::StringPiece& result,
                      Result* out_result) WARN_UNUSED_RESULT;

// A Platform stores information about the OS environment.
struct Platform {
  // The name of the platform. E.g., "Win", or "Mac".
  std::string name;

  // The variant of the platform, either an OS version like "XP" or "10.8", or
  // "Device" or "Simulator" in the case of mobile.
  std::string variant;
};

// Converts a text string |modifier| to a Platform struct, written to
// |out_platform|. Returns true on success and false on failure.
bool PlatformFromString(const base::StringPiece& modifier,
                        Platform* out_platform) WARN_UNUSED_RESULT;

// Returns the Platform for the currently running binary.
Platform GetCurrentPlatform();

// The build configuration.
enum Configuration {
  CONFIGURATION_UNSPECIFIED,
  CONFIGURATION_DEBUG,
  CONFIGURATION_RELEASE,
};

// Converts the |modifier| to a Configuration constant, writing the value to
// |out_configuration|. Returns true on success or false on failure.
bool ConfigurationFromString(const base::StringPiece& modifier,
    Configuration* out_configuration) WARN_UNUSED_RESULT;

// Returns the Configuration for the currently running binary.
Configuration GetCurrentConfiguration();

// An Expectation is records what the result for a given test name should be on
// the specified platforms and configuration.
struct Expectation {
  Expectation();
  ~Expectation();

  // The name of the test, like FooBarTest.BarIsBaz.
  std::string test_name;

  // The set of platforms for which this expectation is applicable.
  std::vector<Platform> platforms;

  // The build configuration.
  Configuration configuration;

  // The expected result of this test.
  Result result;
};

}  // namespace test_expectations

#endif  // BASE_TEST_EXPECTATIONS_EXPECTATION_H_

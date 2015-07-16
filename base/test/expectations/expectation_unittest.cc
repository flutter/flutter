// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/expectations/expectation.h"

#include "base/basictypes.h"
#include "testing/gtest/include/gtest/gtest.h"

TEST(TestExpectationsFunctionsTest, ResultFromString) {
  test_expectations::Result result = test_expectations::RESULT_PASS;

  EXPECT_TRUE(ResultFromString("Failure", &result));
  EXPECT_EQ(test_expectations::RESULT_FAILURE, result);

  EXPECT_TRUE(ResultFromString("Timeout", &result));
  EXPECT_EQ(test_expectations::RESULT_TIMEOUT, result);

  EXPECT_TRUE(ResultFromString("Crash", &result));
  EXPECT_EQ(test_expectations::RESULT_CRASH, result);

  EXPECT_TRUE(ResultFromString("Skip", &result));
  EXPECT_EQ(test_expectations::RESULT_SKIP, result);

  EXPECT_TRUE(ResultFromString("Pass", &result));
  EXPECT_EQ(test_expectations::RESULT_PASS, result);

  // Case sensitive.
  EXPECT_FALSE(ResultFromString("failure", &result));
  EXPECT_EQ(test_expectations::RESULT_PASS, result);
}

TEST(TestExpectationsFunctionsTest, ConfigurationFromString) {
  test_expectations::Configuration config =
      test_expectations::CONFIGURATION_UNSPECIFIED;

  EXPECT_TRUE(ConfigurationFromString("Debug", &config));
  EXPECT_EQ(test_expectations::CONFIGURATION_DEBUG, config);

  EXPECT_TRUE(ConfigurationFromString("Release", &config));
  EXPECT_EQ(test_expectations::CONFIGURATION_RELEASE, config);

  EXPECT_FALSE(ConfigurationFromString("NotAConfig", &config));
  EXPECT_EQ(test_expectations::CONFIGURATION_RELEASE, config);

  // Case sensitive.
  EXPECT_FALSE(ConfigurationFromString("debug", &config));
  EXPECT_EQ(test_expectations::CONFIGURATION_RELEASE, config);
}

TEST(TestExpectationsFunctionsTest, PlatformFromString) {
  test_expectations::Platform platform;

  EXPECT_TRUE(PlatformFromString("Win", &platform));
  EXPECT_EQ("Win", platform.name);
  EXPECT_EQ("", platform.variant);

  EXPECT_TRUE(PlatformFromString("Mac-10.6", &platform));
  EXPECT_EQ("Mac", platform.name);
  EXPECT_EQ("10.6", platform.variant);

  EXPECT_TRUE(PlatformFromString("ChromeOS", &platform));
  EXPECT_EQ("ChromeOS", platform.name);
  EXPECT_EQ("", platform.variant);

  EXPECT_TRUE(PlatformFromString("Linux-", &platform));
  EXPECT_EQ("Linux", platform.name);
  EXPECT_EQ("", platform.variant);

  EXPECT_FALSE(PlatformFromString("", &platform));
}

TEST(TestExpectationsFunctionsTest, IsValidPlatform) {
  const char* const kValidPlatforms[] = {
    "Win",
    "Win-XP",
    "Win-Vista",
    "Win-7",
    "Win-8",
    "Mac",
    "Mac-10.6",
    "Mac-10.7",
    "Mac-10.8",
    "Linux",
    "Linux-32",
    "Linux-64",
    "ChromeOS",
    "iOS",
    "Android",
  };

  const char* const kInvalidPlatforms[] = {
    "Solaris",
    "Plan9",
  };

  for (size_t i = 0; i < arraysize(kValidPlatforms); ++i) {
    test_expectations::Platform platform;
    EXPECT_TRUE(test_expectations::PlatformFromString(
        kValidPlatforms[i], &platform)) << kValidPlatforms[i];
  }

  for (size_t i = 0; i < arraysize(kInvalidPlatforms); ++i) {
    test_expectations::Platform platform;
    EXPECT_FALSE(test_expectations::PlatformFromString(
        kInvalidPlatforms[i], &platform)) << kInvalidPlatforms[i];
  }
}

TEST(TestExpectationsFunctionsTest, CurrentPlatform) {
  test_expectations::Platform current =
      test_expectations::GetCurrentPlatform();
  EXPECT_FALSE(current.name.empty());
}

TEST(TestExpectationsFunctionsTest, CurrentConfiguration) {
  test_expectations::Configuration current =
      test_expectations::GetCurrentConfiguration();
  EXPECT_NE(test_expectations::CONFIGURATION_UNSPECIFIED, current);
}

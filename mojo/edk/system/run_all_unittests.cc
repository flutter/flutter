// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/bind.h"
#include "base/test/launcher/unit_test_launcher.h"
#include "base/test/test_suite.h"
#include "testing/gtest/include/gtest/gtest.h"

int main(int argc, char** argv) {
// Silence death test thread warnings on Linux. We can afford to run our death
// tests a little more slowly (< 10 ms per death test on a Z620).
// On android, we need to run in the default mode, as the threadsafe mode
// relies on execve which is not available.
#if !defined(OS_ANDROID)
  testing::GTEST_FLAG(death_test_style) = "threadsafe";
#endif

  base::TestSuite test_suite(argc, argv);

  return base::LaunchUnitTests(
      argc, argv,
      base::Bind(&base::TestSuite::Run, base::Unretained(&test_suite)));
}

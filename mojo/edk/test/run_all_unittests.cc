// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <signal.h>

#include "base/bind.h"
#include "base/test/launcher/unit_test_launcher.h"
#include "base/test/test_suite.h"
#include "mojo/edk/embedder/test_embedder.h"
#include "mojo/edk/test/test_support_impl.h"
#include "mojo/public/tests/test_support_private.h"
#include "testing/gtest/include/gtest/gtest.h"

int main(int argc, char** argv) {
#if !defined(OS_ANDROID)
  // Silence death test thread warnings on Linux. We can afford to run our death
  // tests a little more slowly (< 10 ms per death test on a Z620).
  // On android, we need to run in the default mode, as the threadsafe mode
  // relies on execve which is not available.
  testing::GTEST_FLAG(death_test_style) = "threadsafe";
#endif
#if defined(OS_ANDROID)
  // On android, the test framework has a signal handler that will print a
  // [ CRASH ] line when the application crashes. This breaks death test has the
  // test runner will consider the death of the child process a test failure.
  // Removing the signal handler solves this issue.
  signal(SIGABRT, SIG_DFL);
#endif

  base::TestSuite test_suite(argc, argv);

  mojo::embedder::test::InitWithSimplePlatformSupport();
  mojo::test::TestSupport::Init(new mojo::test::TestSupportImpl());

  return base::LaunchUnitTests(
      argc, argv,
      base::Bind(&base::TestSuite::Run, base::Unretained(&test_suite)));
}

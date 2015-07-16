// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/at_exit.h"
#include "base/bind.h"
#include "base/command_line.h"
#include "base/test/launcher/unit_test_launcher.h"
#include "base/test/test_suite.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace {

class NoAtExitBaseTestSuite : public base::TestSuite {
 public:
  NoAtExitBaseTestSuite(int argc, char** argv)
      : base::TestSuite(argc, argv, false) {
  }
};

int RunTestSuite(int argc, char** argv) {
  return NoAtExitBaseTestSuite(argc, argv).Run();
}

}  // namespace

int main(int argc, char** argv) {
  // On Android, AtExitManager is created in
  // testing/android/native_test_wrapper.cc before main() is called.
  // The same thing is also done in base/test/test_suite.cc
#if !defined(OS_ANDROID)
  base::AtExitManager exit_manager;
#endif
  base::CommandLine::Init(argc, argv);
  testing::InitGoogleMock(&argc, argv);
  return base::LaunchUnitTests(argc,
                               argv,
                               base::Bind(&RunTestSuite, argc, argv));
}

// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/at_exit.h"
#include "base/bind.h"
#include "base/command_line.h"
#include "base/message_loop/message_loop.h"
#include "base/test/launcher/unit_test_launcher.h"
#include "base/test/test_suite.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "third_party/angle/tests/angle_tests/ANGLETest.h"

namespace {

int RunHelper(base::TestSuite* test_suite) {
  base::MessageLoop message_loop;
  return test_suite->Run();
}

}  // namespace

int main(int argc, char** argv) {
  base::CommandLine::Init(argc, argv);
  testing::InitGoogleMock(&argc, argv);
  testing::AddGlobalTestEnvironment(new ANGLETestEnvironment());
  base::TestSuite test_suite(argc, argv);
  int rt = base::LaunchUnitTestsSerially(
      argc,
      argv,
      base::Bind(&RunHelper, base::Unretained(&test_suite)));
  return rt;
}

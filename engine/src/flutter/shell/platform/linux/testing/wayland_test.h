// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_TESTING_WAYLAND_TEST_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_TESTING_WAYLAND_TEST_H_

#include <glib.h>

#include "flutter/shell/platform/linux/testing/mock_wayland.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

// The base class for tests that use the Wayland mock. Warnings and criticals
// are expected in these tests (they check failure paths), so log output is
// suppressed, these logs are not treated as fatal, and the levels received are
// made available to tests.
class WaylandTest : public ::testing::Test {
 public:
  WaylandTest();
  ~WaylandTest() override;

 protected:
  // The Wayland library the code being tested runs against.
  ::testing::NiceMock<MockWayland> wayland;

  // Checks if a log of the given level has been received since the start of
  // the test.
  bool HasReceivedLogLevel(GLogLevelFlags level);

 private:
  // The log levels that were fatal before this test started.
  GLogLevelFlags fatal_log_levels_;
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_TESTING_WAYLAND_TEST_H_

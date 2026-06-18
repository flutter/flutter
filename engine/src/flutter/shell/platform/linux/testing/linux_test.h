// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_TESTING_LINUX_TEST_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_TESTING_LINUX_TEST_H_

#include <glib.h>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_dart_project.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_engine.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

/// The base class for all Linux test fixtures.
///
/// Test fixtures for the Linux embedder should inherit from this class instead
/// of `::testing::Test` so that common setup is shared between them.
class LinuxTest : public ::testing::Test {
 public:
  LinuxTest();
  ~LinuxTest() override;

 protected:
  // Frees the engine. This is done in TearDown (rather than the destructor) so
  // that the engine is torn down while subclass members - such as GTK mocks -
  // are still alive.
  void TearDown() override;

  // A main loop that tests can run to process asynchronous work.
  GMainLoop* loop = nullptr;

  // A Dart project that tests can use to create an engine.
  FlDartProject* project = nullptr;

  // An engine created from the above project. Subclasses that need an engine
  // backed by a different binary messenger may replace this in SetUp.
  FlEngine* engine = nullptr;

  // Starts the given engine, failing the test if it does not start.
  void StartEngine(FlEngine* engine);

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(LinuxTest);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_TESTING_LINUX_TEST_H_

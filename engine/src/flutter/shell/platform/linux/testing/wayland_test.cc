// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/testing/wayland_test.h"

#include "flutter/shell/platform/linux/testing/fl_test_gtk_logs.h"

namespace flutter {
namespace testing {

namespace {

// Stops expected warnings from being written to the test output.
GLogWriterOutput ignore_logs(GLogLevelFlags log_level,
                             const GLogField* fields,
                             gsize n_fields,
                             gpointer user_data) {
  return G_LOG_WRITER_HANDLED;
}

}  // namespace

WaylandTest::WaylandTest() {
  fl_ensure_gtk_init(ignore_logs);

  // The tests are run with G_DEBUG=fatal-criticals, which would abort when a
  // failure path is checked.
  fatal_log_levels_ =
      g_log_set_always_fatal(static_cast<GLogLevelFlags>(G_LOG_LEVEL_ERROR));

  // Tests only check the Wayland requests they care about.
  EXPECT_CALL(wayland, CreateObject(::testing::_))
      .Times(::testing::AnyNumber());
  EXPECT_CALL(wayland, DestroyObject(::testing::_))
      .Times(::testing::AnyNumber());
  EXPECT_CALL(wayland, Request(::testing::_, ::testing::_))
      .Times(::testing::AnyNumber());
  EXPECT_CALL(wayland, EGLWindowCreate(::testing::_, ::testing::_))
      .Times(::testing::AnyNumber());
  EXPECT_CALL(wayland, EGLWindowResize(::testing::_, ::testing::_))
      .Times(::testing::AnyNumber());
  EXPECT_CALL(wayland, EGLWindowDestroy()).Times(::testing::AnyNumber());
}

WaylandTest::~WaylandTest() {
  g_log_set_always_fatal(fatal_log_levels_);
  fl_ensure_gtk_init(nullptr);
}

bool WaylandTest::HasReceivedLogLevel(GLogLevelFlags level) {
  return fl_has_received_gtk_log_level(level);
}

}  // namespace testing
}  // namespace flutter

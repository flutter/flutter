// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/public/flutter_linux/fl_view.h"
#include "flutter/shell/platform/linux/fl_view_private.h"
#include "flutter/shell/platform/linux/testing/fl_test_gtk_logs.h"

#include "gtest/gtest.h"

static void first_frame_cb(FlView* view, gboolean* first_frame_emitted) {
  *first_frame_emitted = TRUE;
}

TEST(FlViewTest, GetEngine) {
  flutter::testing::fl_ensure_gtk_init();
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  FlView* view = fl_view_new(project);

  // Check the engine is immediately available (i.e. before the widget is
  // realized).
  FlEngine* engine = fl_view_get_engine(view);
  EXPECT_NE(engine, nullptr);
}

TEST(FlViewTest, StateUpdateDoesNotHappenInInit) {
  flutter::testing::fl_ensure_gtk_init();
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  FlView* view = fl_view_new(project);
  // Check that creating a view doesn't try to query the window state in
  // initialization, causing a critical log to be issued.
  EXPECT_EQ(
      flutter::testing::fl_get_received_gtk_log_levels() & G_LOG_LEVEL_CRITICAL,
      (GLogLevelFlags)0x0);

  (void)view;
}

TEST(FlViewTest, FirstFrameSignal) {
  flutter::testing::fl_ensure_gtk_init();

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  FlView* view = fl_view_new(project);
  gboolean first_frame_emitted = FALSE;
  g_signal_connect(view, "first-frame", G_CALLBACK(first_frame_cb),
                   &first_frame_emitted);

  EXPECT_FALSE(first_frame_emitted);

  fl_view_redraw(view);

  // Signal is emitted in idle, clear the main loop.
  while (g_main_context_iteration(g_main_context_default(), FALSE)) {
    // Repeat until nothing to iterate on.
  }

  // Check view has detected frame.
  EXPECT_TRUE(first_frame_emitted);
}

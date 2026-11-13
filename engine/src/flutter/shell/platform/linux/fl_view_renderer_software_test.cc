// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Included first as it collides with the X11 headers.
#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "gtest/gtest.h"

#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_view_renderer.h"
#include "flutter/shell/platform/linux/fl_view_renderer_software.h"
#include "flutter/shell/platform/linux/testing/fl_test_gtk_logs.h"
#include "flutter/shell/platform/linux/testing/mock_gtk.h"

// MOCK_ENGINE_PROC is leaky by design
// NOLINTBEGIN(clang-analyzer-core.StackAddressEscape)

class FlViewRendererSoftwareTest : public flutter::testing::LinuxTest {
 protected:
  // GTK queries the window state when widgets are realized.
  ::testing::NiceMock<flutter::testing::MockGtk> gtk;
};

TEST_F(FlViewRendererSoftwareTest, New) {
  g_autoptr(FlViewRendererSoftware) renderer =
      fl_view_renderer_software_new(engine, FALSE);
  ASSERT_NE(renderer, nullptr);
  g_object_ref_sink(renderer);
  EXPECT_TRUE(FL_IS_VIEW_RENDERER(renderer));
  EXPECT_TRUE(GTK_IS_WIDGET(renderer));
}

// Frames rendered before the widget is realized are dropped, so a frame is
// requested once there is somewhere to present one.
TEST_F(FlViewRendererSoftwareTest, RealizeSchedulesFrame) {
  StartEngine();

  bool called = false;
  fl_engine_get_embedder_api(engine)->ScheduleFrame =
      MOCK_ENGINE_PROC(ScheduleFrame, ([&called](auto engine) {
                         called = true;
                         return kSuccess;
                       }));

  FlViewRendererSoftware* renderer =
      fl_view_renderer_software_new(engine, FALSE);
  ASSERT_NE(renderer, nullptr);
  GtkWidget* window = gtk_offscreen_window_new();
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(renderer));

  EXPECT_FALSE(called);
  gtk_widget_show_all(window);
  EXPECT_TRUE(called);

  gtk_widget_destroy(window);
}

TEST_F(FlViewRendererSoftwareTest, PresentLayersAfterDestroy) {
  // Create a renderer and destroy it.
  FlViewRendererSoftware* renderer =
      fl_view_renderer_software_new(engine, FALSE);
  g_object_ref_sink(renderer);
  fl_gtk_widget_destroy(GTK_WIDGET(renderer));

  // Present a frame on a destroyed widget.
  fl_view_renderer_present_layers(FL_VIEW_RENDERER(renderer), nullptr, 0);

  g_object_unref(renderer);
}

TEST_F(FlViewRendererSoftwareTest, PresentLayersAfterRealizedDestroy) {
  StartEngine();
  fl_engine_get_embedder_api(engine)->ScheduleFrame =
      MOCK_ENGINE_PROC(ScheduleFrame, ([](auto engine) { return kSuccess; }));

  g_autoptr(FlViewRendererSoftware) renderer =
      fl_view_renderer_software_new(engine, FALSE);
  g_object_ref_sink(renderer);
  GtkWidget* window = gtk_offscreen_window_new();
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(renderer));
  gtk_widget_show_all(window);
  ASSERT_TRUE(gtk_widget_get_realized(GTK_WIDGET(renderer)));
  fl_gtk_widget_destroy(GTK_WIDGET(renderer));
  fl_gtk_widget_destroy(window);

  flutter::testing::fl_reset_received_gtk_log_levels();
  fl_view_renderer_present_layers(FL_VIEW_RENDERER(renderer), nullptr, 0);
  EXPECT_FALSE(
      flutter::testing::fl_has_received_gtk_log_level(G_LOG_LEVEL_CRITICAL));

  while (g_main_context_iteration(nullptr, FALSE)) {
  }
}

// NOLINTEND(clang-analyzer-core.StackAddressEscape)

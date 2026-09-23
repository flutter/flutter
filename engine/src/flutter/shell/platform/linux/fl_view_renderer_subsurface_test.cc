// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_view_renderer_subsurface.h"

#include "gtest/gtest.h"

#include <gdk/gdkwayland.h>

#include "flutter/shell/platform/linux/fl_view_renderer.h"
#include "flutter/shell/platform/linux/testing/fl_test_gtk_logs.h"
#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "flutter/shell/platform/linux/testing/mock_gtk.h"

class FlViewRendererSubsurfaceTest : public flutter::testing::LinuxTest {
 protected:
  // GTK queries the window state when widgets are realized.
  ::testing::NiceMock<flutter::testing::MockGtk> gtk;
};

TEST_F(FlViewRendererSubsurfaceTest, New) {
  g_autoptr(FlViewRendererSubsurface) renderer =
      fl_view_renderer_subsurface_new(engine, FALSE);
  ASSERT_NE(renderer, nullptr);
  g_object_ref_sink(renderer);
  EXPECT_TRUE(FL_IS_VIEW_RENDERER(renderer));
  EXPECT_TRUE(GTK_IS_WIDGET(renderer));
}

// Frames presented before the widget is realized are dropped rather than
// drawn to a subsurface that doesn't exist yet.
TEST_F(FlViewRendererSubsurfaceTest, PresentBeforeRealize) {
  g_autoptr(FlViewRendererSubsurface) renderer =
      fl_view_renderer_subsurface_new(engine, FALSE);
  ASSERT_NE(renderer, nullptr);
  g_object_ref_sink(renderer);

  FlutterLayer layer = {.type = kFlutterLayerContentTypeBackingStore,
                        .backing_store = nullptr,
                        .offset = {0, 0},
                        .size = {100, 100}};
  const FlutterLayer* layers[1] = {&layer};
  fl_view_renderer_present_layers(FL_VIEW_RENDERER(renderer), layers, 1);

  EXPECT_FALSE(flutter::testing::fl_has_received_gtk_log_level(
      static_cast<GLogLevelFlags>(G_LOG_LEVEL_WARNING | G_LOG_LEVEL_CRITICAL)));
}

// The subsurface renderer can only be used on Wayland. The tests don't run on
// Wayland, so realizing warns and leaves the widget without a subsurface
// rather than failing.
TEST_F(FlViewRendererSubsurfaceTest, RealizeWithoutWayland) {
  FlViewRendererSubsurface* renderer =
      fl_view_renderer_subsurface_new(engine, FALSE);
  ASSERT_NE(renderer, nullptr);
  GtkWidget* window = gtk_offscreen_window_new();
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(renderer));

  // Tests are run on X11.
  ASSERT_FALSE(GDK_IS_WAYLAND_DISPLAY(gtk_widget_get_display(window)));

  flutter::testing::fl_reset_received_gtk_log_levels();
  gtk_widget_show_all(window);
  EXPECT_TRUE(
      flutter::testing::fl_has_received_gtk_log_level(G_LOG_LEVEL_WARNING));

  // Unrealizing a widget that has no subsurface must not fail.
  gtk_widget_destroy(window);
}

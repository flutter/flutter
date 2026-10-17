// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_gtk.h"

#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "flutter/shell/platform/linux/testing/mock_gtk.h"
#include "gtest/gtest.h"

class FlGtkTest : public flutter::testing::LinuxTest {
 protected:
  ::testing::NiceMock<flutter::testing::MockGtk> gtk;
};

TEST_F(FlGtkTest, WidgetGetSurface) {
  // Opaque sentinels must be forwarded unchanged, not dereferenced.
  int widget_token = 0;
  int surface_token = 0;
  auto* widget = reinterpret_cast<GtkWidget*>(&widget_token);
  auto* surface = reinterpret_cast<GdkWindow*>(&surface_token);
  EXPECT_CALL(gtk, gtk_widget_get_window(widget))
      .WillOnce(::testing::Return(surface));

  EXPECT_EQ(fl_gtk_widget_get_surface(widget), surface);
}

TEST_F(FlGtkTest, WidgetGetSurfaceWithoutWindow) {
  int widget_token = 0;
  auto* widget = reinterpret_cast<GtkWidget*>(&widget_token);
  EXPECT_CALL(gtk, gtk_widget_get_window(widget))
      .WillOnce(::testing::Return(nullptr));

  EXPECT_EQ(fl_gtk_widget_get_surface(widget), nullptr);
}

TEST_F(FlGtkTest, SurfaceGetDisplay) {
  int surface_token = 0;
  int display_token = 0;
  auto* surface = reinterpret_cast<GdkWindow*>(&surface_token);
  auto* display = reinterpret_cast<GdkDisplay*>(&display_token);
  EXPECT_CALL(gtk, gdk_window_get_display(surface))
      .WillOnce(::testing::Return(display));

  EXPECT_EQ(fl_gtk_surface_get_display(surface), display);
}

TEST_F(FlGtkTest, DisplayGetMonitorAtSurface) {
  int display_token = 0;
  int surface_token = 0;
  int monitor_token = 0;
  auto* display = reinterpret_cast<GdkDisplay*>(&display_token);
  auto* surface = reinterpret_cast<GdkWindow*>(&surface_token);
  auto* monitor = reinterpret_cast<GdkMonitor*>(&monitor_token);
  EXPECT_CALL(gtk, gdk_display_get_monitor_at_window(display, surface))
      .WillOnce(::testing::Return(monitor));

  EXPECT_EQ(fl_gtk_display_get_monitor_at_surface(display, surface), monitor);
}

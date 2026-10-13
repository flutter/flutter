// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_display_monitor.h"
#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_gtk.h"

#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "gtest/gtest.h"
#if !FLUTTER_LINUX_GTK4
#include "flutter/shell/platform/linux/testing/mock_gtk.h"
#endif

class FlDisplayMonitorTest : public flutter::testing::LinuxTest {};

TEST_F(FlDisplayMonitorTest, Test) {
  StartEngine();

  bool called = false;
  fl_engine_get_embedder_api(engine)->NotifyDisplayUpdate = MOCK_ENGINE_PROC(
      NotifyDisplayUpdate,
      ([&called](auto engine, FlutterEngineDisplaysUpdateType update_type,
                 const FlutterEngineDisplay* displays, size_t displays_length) {
        called = true;

        EXPECT_EQ(displays_length, 1u);

        return kSuccess;
      }));

  g_autoptr(FlDisplayMonitor) monitor =
      fl_display_monitor_new(engine, gdk_display_get_default());
  EXPECT_FALSE(called);
  fl_display_monitor_start(monitor);
  EXPECT_TRUE(called);
}

TEST_F(FlDisplayMonitorTest, DimensionsArePhysicalPixels) {
#if !FLUTTER_LINUX_GTK4
  ::testing::NiceMock<flutter::testing::MockGtk> gtk;
  ON_CALL(gtk, gdk_monitor_get_geometry(::testing::_, ::testing::_))
      .WillByDefault([](GdkMonitor*, GdkRectangle* geometry) {
        *geometry = {0, 0, 640, 512};
      });
  ON_CALL(gtk, gdk_monitor_get_scale_factor(::testing::_))
      .WillByDefault(::testing::Return(2));
#endif
  StartEngine();
  GdkDisplay* display = gdk_display_get_default();
#if FLUTTER_LINUX_GTK4
  g_autoptr(GdkMonitor) native_monitor =
      GDK_MONITOR(g_list_model_get_item(gdk_display_get_monitors(display), 0));
#else
  GdkMonitor* native_monitor = gdk_display_get_monitor(display, 0);
#endif
  GdkRectangle geometry = {};
  gdk_monitor_get_geometry(native_monitor, &geometry);
  const double scale = gdk_monitor_get_scale_factor(native_monitor);
  bool called = false;
  fl_engine_get_embedder_api(engine)->NotifyDisplayUpdate = MOCK_ENGINE_PROC(
      NotifyDisplayUpdate,
      ([&](auto, auto, const FlutterEngineDisplay* displays, size_t count) {
        called = true;
        EXPECT_GE(count, 1u);
        if (count == 0) {
          return kSuccess;
        }
        EXPECT_DOUBLE_EQ(displays[0].device_pixel_ratio, scale);
        EXPECT_EQ(displays[0].width,
                  fl_gtk_size_to_pixels(geometry.width, scale));
        EXPECT_EQ(displays[0].height,
                  fl_gtk_size_to_pixels(geometry.height, scale));
        return kSuccess;
      }));
  g_autoptr(FlDisplayMonitor) monitor = fl_display_monitor_new(engine, display);
  fl_display_monitor_start(monitor);
  EXPECT_TRUE(called);
}

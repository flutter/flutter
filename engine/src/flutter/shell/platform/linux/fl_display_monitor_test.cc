// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_display_monitor.h"
#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"

#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "flutter/shell/platform/linux/testing/mock_gtk.h"
#include "gtest/gtest.h"

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

TEST_F(FlDisplayMonitorTest, RefreshRate) {
  ::testing::NiceMock<flutter::testing::MockGtk> mock_gtk;
  EXPECT_CALL(mock_gtk, gdk_monitor_get_refresh_rate(::testing::_))
      .WillRepeatedly(::testing::Return(144000));

  StartEngine();

  g_autoptr(FlDisplayMonitor) monitor =
      fl_display_monitor_new(engine, gdk_display_get_default());
  fl_display_monitor_start(monitor);

  EXPECT_DOUBLE_EQ(fl_display_monitor_get_refresh_rate(monitor, 1), 144.0);
  EXPECT_DOUBLE_EQ(fl_display_monitor_get_max_refresh_rate(monitor), 144.0);
}

TEST_F(FlDisplayMonitorTest, RefreshRateUnknownDisplay) {
  StartEngine();

  g_autoptr(FlDisplayMonitor) monitor =
      fl_display_monitor_new(engine, gdk_display_get_default());
  fl_display_monitor_start(monitor);

  EXPECT_DOUBLE_EQ(fl_display_monitor_get_refresh_rate(monitor, 0), 0.0);
  EXPECT_DOUBLE_EQ(fl_display_monitor_get_refresh_rate(monitor, 99), 0.0);
  EXPECT_DOUBLE_EQ(fl_display_monitor_get_max_refresh_rate(monitor), 60.0);
}

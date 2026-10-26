// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_display_monitor.h"

#include <vector>
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

// Keep the engine's own watcher unstarted so updates come only from the watcher
// under test. Stable fake monitor objects make hotplug and ID behavior
// testable.
class FlDisplayMonitorSnapshotTest : public flutter::testing::LinuxTest {
 protected:
  void SetUp() override {
    display = gdk_display_get_default();
    first = GDK_MONITOR(g_object_new(gdk_monitor_get_type(), nullptr));
    second = GDK_MONITOR(g_object_new(gdk_monitor_get_type(), nullptr));
    ON_CALL(gtk, gdk_display_get_n_monitors(::testing::_))
        .WillByDefault(
            [this](GdkDisplay*) { return static_cast<int>(current.size()); });
    ON_CALL(gtk, gdk_display_get_monitor(::testing::_, ::testing::_))
        .WillByDefault([this](GdkDisplay*, int n) { return current[n]; });
    ON_CALL(gtk, gdk_monitor_get_geometry(::testing::_, ::testing::_))
        .WillByDefault([this](GdkMonitor* monitor, GdkRectangle* geometry) {
          *geometry = monitor == first ? GdkRectangle{10, 20, 640, 480}
                                       : GdkRectangle{650, 20, 1280, 720};
        });
    ON_CALL(gtk, gdk_monitor_get_scale_factor(::testing::_))
        .WillByDefault(
            [this](GdkMonitor* monitor) { return monitor == first ? 2 : 1; });
    ON_CALL(gtk, gdk_monitor_get_refresh_rate(::testing::_))
        .WillByDefault([this](GdkMonitor* monitor) {
          return monitor == first ? 90000 : 144000;
        });
    fl_engine_get_embedder_api(engine)->NotifyDisplayUpdate = MOCK_ENGINE_PROC(
        NotifyDisplayUpdate,
        ([this](auto, FlutterEngineDisplaysUpdateType type,
                const FlutterEngineDisplay* values, size_t count) {
          EXPECT_EQ(type, kFlutterEngineDisplaysUpdateTypeStartup);
          updates++;
          displays.clear();
          for (size_t i = 0; i < count; i++) {
            displays.push_back(values[i]);
          }
          return kSuccess;
        }));
    watcher = fl_display_monitor_new(engine, display);
  }

  void TearDown() override {
    g_clear_object(&watcher);
    g_clear_object(&first);
    g_clear_object(&second);
    flutter::testing::LinuxTest::TearDown();
  }

  ::testing::NiceMock<flutter::testing::MockGtk> gtk;
  GdkDisplay* display = nullptr;
  GdkMonitor* first = nullptr;
  GdkMonitor* second = nullptr;
  FlDisplayMonitor* watcher = nullptr;
  std::vector<GdkMonitor*> current;
  std::vector<FlutterEngineDisplay> displays;
  int updates = 0;
};

TEST_F(FlDisplayMonitorSnapshotTest,
       ReportsEveryMonitorAndPreservesLogicalDimensions) {
  current = {first, second};
  fl_display_monitor_start(watcher);
  ASSERT_EQ(displays.size(), 2u);
  EXPECT_NE(displays[0].display_id, displays[1].display_id);
  EXPECT_NE(displays[0].display_id, 0u);
  EXPECT_NE(displays[1].display_id, 0u);
  EXPECT_EQ(displays[0].struct_size, sizeof(FlutterEngineDisplay));
  EXPECT_FALSE(displays[0].single_display);
  EXPECT_EQ(displays[0].width, 640u);
  EXPECT_EQ(displays[0].height, 480u);
  EXPECT_DOUBLE_EQ(displays[0].device_pixel_ratio, 2.0);
  EXPECT_DOUBLE_EQ(displays[0].refresh_rate, 90.0);
  EXPECT_EQ(displays[1].width, 1280u);
  EXPECT_EQ(displays[1].height, 720u);
  EXPECT_DOUBLE_EQ(displays[1].device_pixel_ratio, 1.0);
  EXPECT_DOUBLE_EQ(displays[1].refresh_rate, 144.0);
}

TEST_F(FlDisplayMonitorSnapshotTest,
       RemovalPreservesSurvivingIdsAndReadditionGetsANewId) {
  current = {first, second};
  fl_display_monitor_start(watcher);
  const auto first_id = fl_display_monitor_get_display_id(watcher, first);
  const auto second_id = fl_display_monitor_get_display_id(watcher, second);
  current = {second};
  g_signal_emit_by_name(display, "monitor-removed", first);
  ASSERT_EQ(displays.size(), 1u);
  EXPECT_EQ(displays[0].display_id, second_id);
  EXPECT_EQ(fl_display_monitor_get_display_id(watcher, first), 0u);
  current = {second, first};
  g_signal_emit_by_name(display, "monitor-added", first);
  ASSERT_EQ(displays.size(), 2u);
  EXPECT_EQ(displays[0].display_id, second_id);
  EXPECT_NE(displays[1].display_id, first_id);
  EXPECT_NE(displays[1].display_id, second_id);
  EXPECT_EQ(updates, 3);
}

TEST_F(FlDisplayMonitorSnapshotTest,
       HandlesEmptyMonitorListAndRemovalOfLastMonitor) {
  fl_display_monitor_start(watcher);
  EXPECT_TRUE(displays.empty());
  current = {first};
  g_signal_emit_by_name(display, "monitor-added", first);
  ASSERT_EQ(displays.size(), 1u);
  current.clear();
  g_signal_emit_by_name(display, "monitor-removed", first);
  EXPECT_TRUE(displays.empty());
  EXPECT_EQ(fl_display_monitor_get_display_id(watcher, first), 0u);
  EXPECT_EQ(updates, 3);
}

TEST_F(FlDisplayMonitorSnapshotTest, ReorderingDoesNotReassignIds) {
  current = {first, second};
  fl_display_monitor_start(watcher);
  const auto first_id = displays[0].display_id;
  const auto second_id = displays[1].display_id;
  current = {second, first};
  fl_display_monitor_start(watcher);
  ASSERT_EQ(displays.size(), 2u);
  EXPECT_EQ(displays[0].display_id, second_id);
  EXPECT_EQ(displays[1].display_id, first_id);
}

TEST_F(FlDisplayMonitorSnapshotTest, DisposalDisconnectsBothTopologySignals) {
  current = {first};
  fl_display_monitor_start(watcher);
  g_clear_object(&watcher);
  current.push_back(second);
  g_signal_emit_by_name(display, "monitor-added", second);
  current = {second};
  g_signal_emit_by_name(display, "monitor-removed", first);
  EXPECT_EQ(updates, 1);
}

TEST_F(FlDisplayMonitorSnapshotTest, EngineDestructionMakesNotificationsSafe) {
  current = {first};
  fl_display_monitor_start(watcher);
  g_clear_object(&engine);
  current.push_back(second);
  g_signal_emit_by_name(display, "monitor-added", second);
  EXPECT_EQ(updates, 1);
}

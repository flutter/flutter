// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_window_state_monitor.h"
#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/testing/mock_gtk.h"

#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "gtest/gtest.h"

// MOCK_ENGINE_PROC is leaky by design
// NOLINTBEGIN(clang-analyzer-core.StackAddressEscape)

class FlWindowStateMonitorTest : public flutter::testing::LinuxTest {
 protected:
  void SetUp() override {
    gtk_init(0, nullptr);
    StartEngine();
  }

  // Checks changing a window from |old_state| to |new_state| sets the
  // lifecycle state to |expected_state|.
  void CheckStateChange(GdkWindowState old_state,
                        GdkWindowState new_state,
                        FlutterAppLifecycleState expected_state) {
    EXPECT_CALL(mock_gtk, gdk_window_get_state)
        .WillOnce(::testing::Return(old_state));

    int call_count = 0;
    fl_engine_get_embedder_api(engine)->SetAppLifecycleState =
        MOCK_ENGINE_PROC(SetAppLifecycleState,
                         ([&call_count, expected_state](
                              auto engine, FlutterAppLifecycleState state) {
                           call_count++;
                           EXPECT_EQ(state, expected_state);
                           return kSuccess;
                         }));

    GtkWindow* window = GTK_WINDOW(gtk_window_new(GTK_WINDOW_TOPLEVEL));
    gtk_widget_show(GTK_WIDGET(window));
    g_autoptr(FlWindowStateMonitor) monitor =
        fl_window_state_monitor_new(engine, window);

    GdkEvent event = {.window_state = {.new_window_state = new_state}};
    gboolean handled;
    g_signal_emit_by_name(window, "window-state-event", &event, &handled);
    EXPECT_EQ(call_count, 1);
  }

  ::testing::NiceMock<flutter::testing::MockGtk> mock_gtk;
};

TEST_F(FlWindowStateMonitorTest, GainFocus) {
  CheckStateChange(static_cast<GdkWindowState>(0), GDK_WINDOW_STATE_FOCUSED,
                   kFlutterAppLifecycleStateResumed);
}

TEST_F(FlWindowStateMonitorTest, LoseFocus) {
  CheckStateChange(GDK_WINDOW_STATE_FOCUSED, static_cast<GdkWindowState>(0),
                   kFlutterAppLifecycleStateInactive);
}

TEST_F(FlWindowStateMonitorTest, EnterIconified) {
  CheckStateChange(static_cast<GdkWindowState>(0), GDK_WINDOW_STATE_ICONIFIED,
                   kFlutterAppLifecycleStateHidden);
}

TEST_F(FlWindowStateMonitorTest, LeaveIconified) {
  CheckStateChange(GDK_WINDOW_STATE_ICONIFIED, static_cast<GdkWindowState>(0),
                   kFlutterAppLifecycleStateInactive);
}

TEST_F(FlWindowStateMonitorTest, LeaveIconifiedFocused) {
  CheckStateChange(GDK_WINDOW_STATE_ICONIFIED, GDK_WINDOW_STATE_FOCUSED,
                   kFlutterAppLifecycleStateResumed);
}

TEST_F(FlWindowStateMonitorTest, EnterWithdrawn) {
  CheckStateChange(static_cast<GdkWindowState>(0), GDK_WINDOW_STATE_WITHDRAWN,
                   kFlutterAppLifecycleStateHidden);
}

TEST_F(FlWindowStateMonitorTest, LeaveWithdrawn) {
  CheckStateChange(GDK_WINDOW_STATE_WITHDRAWN, static_cast<GdkWindowState>(0),
                   kFlutterAppLifecycleStateInactive);
}

TEST_F(FlWindowStateMonitorTest, LeaveWithdrawnFocused) {
  CheckStateChange(GDK_WINDOW_STATE_WITHDRAWN, GDK_WINDOW_STATE_FOCUSED,
                   kFlutterAppLifecycleStateResumed);
}

// NOLINTEND(clang-analyzer-core.StackAddressEscape)

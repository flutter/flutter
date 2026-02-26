// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_window_state_monitor.h"
#include "flutter/shell/platform/linux/fl_binary_messenger_private.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_string_codec.h"
#include "flutter/shell/platform/linux/testing/fl_mock_binary_messenger.h"
#include "flutter/shell/platform/linux/testing/mock_gtk.h"

#include "gtest/gtest.h"

#if FLUTTER_LINUX_GTK4
#include <string>
#include <vector>
#endif

#if !FLUTTER_LINUX_GTK4
TEST(FlWindowStateMonitorTest, GainFocus) {
  g_autoptr(FlMockBinaryMessenger) messenger = fl_mock_binary_messenger_new();
  ::testing::NiceMock<flutter::testing::MockGtk> mock_gtk;

  gtk_init(0, nullptr);

  EXPECT_CALL(mock_gtk, gdk_window_get_state)
      .WillOnce(::testing::Return(static_cast<GdkWindowState>(0)));

  gboolean called = TRUE;
  fl_mock_binary_messenger_set_string_message_channel(
      messenger, "flutter/lifecycle",
      [](FlMockBinaryMessenger* messenger, GTask* task, FlValue* message,
         gpointer user_data) {
        gboolean* called = static_cast<gboolean*>(user_data);
        *called = TRUE;
        EXPECT_STREQ(fl_value_get_string(message), "AppLifecycleState.resumed");
        return fl_value_new_string("");
      },
      &called);

  GtkWindow* window = GTK_WINDOW(gtk_window_new(GTK_WINDOW_TOPLEVEL));
  gtk_widget_show(GTK_WIDGET(window));
  g_autoptr(FlWindowStateMonitor) monitor =
      fl_window_state_monitor_new(FL_BINARY_MESSENGER(messenger), window);

  GdkEvent event = {
      .window_state = {.new_window_state = GDK_WINDOW_STATE_FOCUSED}};
  gboolean handled;
  g_signal_emit_by_name(window, "window-state-event", &event, &handled);
  EXPECT_TRUE(called);

  fl_binary_messenger_shutdown(FL_BINARY_MESSENGER(messenger));
}
TEST(FlWindowStateMonitorTest, LoseFocus) {
  g_autoptr(FlMockBinaryMessenger) messenger = fl_mock_binary_messenger_new();
  ::testing::NiceMock<flutter::testing::MockGtk> mock_gtk;

  gtk_init(0, nullptr);

  EXPECT_CALL(mock_gtk, gdk_window_get_state)
      .WillOnce(::testing::Return(GDK_WINDOW_STATE_FOCUSED));
  gboolean called = TRUE;
  fl_mock_binary_messenger_set_string_message_channel(
      messenger, "flutter/lifecycle",
      [](FlMockBinaryMessenger* messenger, GTask* task, FlValue* message,
         gpointer user_data) {
        gboolean* called = static_cast<gboolean*>(user_data);
        *called = TRUE;
        EXPECT_STREQ(fl_value_get_string(message),
                     "AppLifecycleState.inactive");
        return fl_value_new_string("");
      },
      &called);

  GtkWindow* window = GTK_WINDOW(gtk_window_new(GTK_WINDOW_TOPLEVEL));
  gtk_widget_show(GTK_WIDGET(window));
  g_autoptr(FlWindowStateMonitor) monitor =
      fl_window_state_monitor_new(FL_BINARY_MESSENGER(messenger), window);

  GdkEvent event = {
      .window_state = {.new_window_state = static_cast<GdkWindowState>(0)}};
  gboolean handled;
  g_signal_emit_by_name(window, "window-state-event", &event, &handled);
  EXPECT_TRUE(called);

  fl_binary_messenger_shutdown(FL_BINARY_MESSENGER(messenger));
}

TEST(FlWindowStateMonitorTest, EnterIconified) {
  g_autoptr(FlMockBinaryMessenger) messenger = fl_mock_binary_messenger_new();
  ::testing::NiceMock<flutter::testing::MockGtk> mock_gtk;

  gtk_init(0, nullptr);

  EXPECT_CALL(mock_gtk, gdk_window_get_state)
      .WillOnce(::testing::Return(static_cast<GdkWindowState>(0)));
  gboolean called = TRUE;
  fl_mock_binary_messenger_set_string_message_channel(
      messenger, "flutter/lifecycle",
      [](FlMockBinaryMessenger* messenger, GTask* task, FlValue* message,
         gpointer user_data) {
        gboolean* called = static_cast<gboolean*>(user_data);
        *called = TRUE;
        EXPECT_STREQ(fl_value_get_string(message), "AppLifecycleState.hidden");
        return fl_value_new_string("");
      },
      &called);

  GtkWindow* window = GTK_WINDOW(gtk_window_new(GTK_WINDOW_TOPLEVEL));
  gtk_widget_show(GTK_WIDGET(window));
  g_autoptr(FlWindowStateMonitor) monitor =
      fl_window_state_monitor_new(FL_BINARY_MESSENGER(messenger), window);

  GdkEvent event = {
      .window_state = {.new_window_state = GDK_WINDOW_STATE_ICONIFIED}};
  gboolean handled;
  g_signal_emit_by_name(window, "window-state-event", &event, &handled);
  EXPECT_TRUE(called);

  fl_binary_messenger_shutdown(FL_BINARY_MESSENGER(messenger));
}

TEST(FlWindowStateMonitorTest, LeaveIconified) {
  g_autoptr(FlMockBinaryMessenger) messenger = fl_mock_binary_messenger_new();
  ::testing::NiceMock<flutter::testing::MockGtk> mock_gtk;

  gtk_init(0, nullptr);

  EXPECT_CALL(mock_gtk, gdk_window_get_state)
      .WillOnce(::testing::Return(GDK_WINDOW_STATE_ICONIFIED));
  gboolean called = TRUE;
  fl_mock_binary_messenger_set_string_message_channel(
      messenger, "flutter/lifecycle",
      [](FlMockBinaryMessenger* messenger, GTask* task, FlValue* message,
         gpointer user_data) {
        gboolean* called = static_cast<gboolean*>(user_data);
        *called = TRUE;
        EXPECT_STREQ(fl_value_get_string(message),
                     "AppLifecycleState.inactive");
        return fl_value_new_string("");
      },
      &called);

  GtkWindow* window = GTK_WINDOW(gtk_window_new(GTK_WINDOW_TOPLEVEL));
  gtk_widget_show(GTK_WIDGET(window));
  g_autoptr(FlWindowStateMonitor) monitor =
      fl_window_state_monitor_new(FL_BINARY_MESSENGER(messenger), window);

  GdkEvent event = {
      .window_state = {.new_window_state = static_cast<GdkWindowState>(0)}};
  gboolean handled;
  g_signal_emit_by_name(window, "window-state-event", &event, &handled);
  EXPECT_TRUE(called);

  fl_binary_messenger_shutdown(FL_BINARY_MESSENGER(messenger));
}

TEST(FlWindowStateMonitorTest, LeaveIconifiedFocused) {
  g_autoptr(FlMockBinaryMessenger) messenger = fl_mock_binary_messenger_new();
  ::testing::NiceMock<flutter::testing::MockGtk> mock_gtk;

  gtk_init(0, nullptr);

  EXPECT_CALL(mock_gtk, gdk_window_get_state)
      .WillOnce(::testing::Return(GDK_WINDOW_STATE_ICONIFIED));
  gboolean called = TRUE;
  fl_mock_binary_messenger_set_string_message_channel(
      messenger, "flutter/lifecycle",
      [](FlMockBinaryMessenger* messenger, GTask* task, FlValue* message,
         gpointer user_data) {
        gboolean* called = static_cast<gboolean*>(user_data);
        *called = TRUE;
        EXPECT_STREQ(fl_value_get_string(message), "AppLifecycleState.resumed");
        return fl_value_new_string("");
      },
      &called);

  GtkWindow* window = GTK_WINDOW(gtk_window_new(GTK_WINDOW_TOPLEVEL));
  gtk_widget_show(GTK_WIDGET(window));
  g_autoptr(FlWindowStateMonitor) monitor =
      fl_window_state_monitor_new(FL_BINARY_MESSENGER(messenger), window);

  GdkEvent event = {
      .window_state = {.new_window_state = static_cast<GdkWindowState>(
                           GDK_WINDOW_STATE_FOCUSED)}};
  gboolean handled;
  g_signal_emit_by_name(window, "window-state-event", &event, &handled);
  EXPECT_TRUE(called);

  fl_binary_messenger_shutdown(FL_BINARY_MESSENGER(messenger));
}

TEST(FlWindowStateMonitorTest, EnterWithdrawn) {
  g_autoptr(FlMockBinaryMessenger) messenger = fl_mock_binary_messenger_new();
  ::testing::NiceMock<flutter::testing::MockGtk> mock_gtk;

  gtk_init(0, nullptr);

  EXPECT_CALL(mock_gtk, gdk_window_get_state)
      .WillOnce(::testing::Return(static_cast<GdkWindowState>(0)));
  gboolean called = TRUE;
  fl_mock_binary_messenger_set_string_message_channel(
      messenger, "flutter/lifecycle",
      [](FlMockBinaryMessenger* messenger, GTask* task, FlValue* message,
         gpointer user_data) {
        gboolean* called = static_cast<gboolean*>(user_data);
        *called = TRUE;
        EXPECT_STREQ(fl_value_get_string(message), "AppLifecycleState.hidden");
        return fl_value_new_string("");
      },
      &called);

  GtkWindow* window = GTK_WINDOW(gtk_window_new(GTK_WINDOW_TOPLEVEL));
  gtk_widget_show(GTK_WIDGET(window));
  g_autoptr(FlWindowStateMonitor) monitor =
      fl_window_state_monitor_new(FL_BINARY_MESSENGER(messenger), window);

  GdkEvent event = {
      .window_state = {.new_window_state = GDK_WINDOW_STATE_WITHDRAWN}};
  gboolean handled;
  g_signal_emit_by_name(window, "window-state-event", &event, &handled);
  EXPECT_TRUE(called);

  fl_binary_messenger_shutdown(FL_BINARY_MESSENGER(messenger));
}

TEST(FlWindowStateMonitorTest, LeaveWithdrawn) {
  g_autoptr(FlMockBinaryMessenger) messenger = fl_mock_binary_messenger_new();
  ::testing::NiceMock<flutter::testing::MockGtk> mock_gtk;

  gtk_init(0, nullptr);

  EXPECT_CALL(mock_gtk, gdk_window_get_state)
      .WillOnce(::testing::Return(GDK_WINDOW_STATE_WITHDRAWN));
  gboolean called = TRUE;
  fl_mock_binary_messenger_set_string_message_channel(
      messenger, "flutter/lifecycle",
      [](FlMockBinaryMessenger* messenger, GTask* task, FlValue* message,
         gpointer user_data) {
        gboolean* called = static_cast<gboolean*>(user_data);
        *called = TRUE;
        EXPECT_STREQ(fl_value_get_string(message),
                     "AppLifecycleState.inactive");
        return fl_value_new_string("");
      },
      &called);

  GtkWindow* window = GTK_WINDOW(gtk_window_new(GTK_WINDOW_TOPLEVEL));
  gtk_widget_show(GTK_WIDGET(window));
  g_autoptr(FlWindowStateMonitor) monitor =
      fl_window_state_monitor_new(FL_BINARY_MESSENGER(messenger), window);

  GdkEvent event = {
      .window_state = {.new_window_state = static_cast<GdkWindowState>(0)}};
  gboolean handled;
  g_signal_emit_by_name(window, "window-state-event", &event, &handled);
  EXPECT_TRUE(called);

  fl_binary_messenger_shutdown(FL_BINARY_MESSENGER(messenger));
}

TEST(FlWindowStateMonitorTest, LeaveWithdrawnFocused) {
  g_autoptr(FlMockBinaryMessenger) messenger = fl_mock_binary_messenger_new();
  ::testing::NiceMock<flutter::testing::MockGtk> mock_gtk;

  gtk_init(0, nullptr);

  EXPECT_CALL(mock_gtk, gdk_window_get_state)
      .WillOnce(::testing::Return(GDK_WINDOW_STATE_WITHDRAWN));
  gboolean called = TRUE;
  fl_mock_binary_messenger_set_string_message_channel(
      messenger, "flutter/lifecycle",
      [](FlMockBinaryMessenger* messenger, GTask* task, FlValue* message,
         gpointer user_data) {
        gboolean* called = static_cast<gboolean*>(user_data);
        *called = TRUE;
        EXPECT_STREQ(fl_value_get_string(message), "AppLifecycleState.resumed");
        return fl_value_new_string("");
      },
      &called);

  GtkWindow* window = GTK_WINDOW(gtk_window_new(GTK_WINDOW_TOPLEVEL));
  gtk_widget_show(GTK_WIDGET(window));
  g_autoptr(FlWindowStateMonitor) monitor =
      fl_window_state_monitor_new(FL_BINARY_MESSENGER(messenger), window);

  GdkEvent event = {
      .window_state = {.new_window_state = static_cast<GdkWindowState>(
                           GDK_WINDOW_STATE_FOCUSED)}};
  gboolean handled;
  g_signal_emit_by_name(window, "window-state-event", &event, &handled);
  EXPECT_TRUE(called);

  fl_binary_messenger_shutdown(FL_BINARY_MESSENGER(messenger));
}

#endif  // !FLUTTER_LINUX_GTK4

#if FLUTTER_LINUX_GTK4
TEST(FlWindowStateMonitorTest, Gtk4FocusToInactive) {
  g_autoptr(FlMockBinaryMessenger) messenger = fl_mock_binary_messenger_new();
  ::testing::NiceMock<flutter::testing::MockGtk> mock_gtk;

  gtk_init(0, nullptr);

  EXPECT_CALL(mock_gtk, gdk_surface_get_mapped)
      .WillRepeatedly(::testing::Return(TRUE));
  EXPECT_CALL(mock_gtk, gdk_toplevel_get_state)
      .WillOnce(::testing::Return(GDK_TOPLEVEL_STATE_FOCUSED))
      .WillOnce(::testing::Return(static_cast<GdkToplevelState>(0)));

  std::vector<std::string> lifecycle_states;
  fl_mock_binary_messenger_set_string_message_channel(
      messenger, "flutter/lifecycle",
      [](FlMockBinaryMessenger* messenger, GTask* task, FlValue* message,
         gpointer user_data) {
        auto* states = static_cast<std::vector<std::string>*>(user_data);
        states->emplace_back(fl_value_get_string(message));
        return fl_value_new_string("");
      },
      &lifecycle_states);

  GtkWindow* window = GTK_WINDOW(gtk_window_new(GTK_WINDOW_TOPLEVEL));
  gtk_widget_show(GTK_WIDGET(window));
  g_autoptr(FlWindowStateMonitor) monitor =
      fl_window_state_monitor_new(FL_BINARY_MESSENGER(messenger), window);

  GtkNative* native = gtk_widget_get_native(GTK_WIDGET(window));
  GdkSurface* surface = gtk_native_get_surface(native);
  GParamSpec* state_pspec =
      g_object_class_find_property(G_OBJECT_GET_CLASS(surface), "state");
  ASSERT_NE(state_pspec, nullptr);
  g_object_notify_by_pspec(G_OBJECT(surface), state_pspec);

  ASSERT_EQ(lifecycle_states.size(), 2u);
  EXPECT_EQ(lifecycle_states[0], "AppLifecycleState.resumed");
  EXPECT_EQ(lifecycle_states[1], "AppLifecycleState.inactive");

  fl_binary_messenger_shutdown(FL_BINARY_MESSENGER(messenger));
}

TEST(FlWindowStateMonitorTest, Gtk4MappedToHidden) {
  g_autoptr(FlMockBinaryMessenger) messenger = fl_mock_binary_messenger_new();
  ::testing::NiceMock<flutter::testing::MockGtk> mock_gtk;

  gtk_init(0, nullptr);

  EXPECT_CALL(mock_gtk, gdk_surface_get_mapped)
      .WillOnce(::testing::Return(TRUE))
      .WillOnce(::testing::Return(FALSE));
  EXPECT_CALL(mock_gtk, gdk_toplevel_get_state)
      .WillRepeatedly(::testing::Return(static_cast<GdkToplevelState>(0)));

  std::vector<std::string> lifecycle_states;
  fl_mock_binary_messenger_set_string_message_channel(
      messenger, "flutter/lifecycle",
      [](FlMockBinaryMessenger* messenger, GTask* task, FlValue* message,
         gpointer user_data) {
        auto* states = static_cast<std::vector<std::string>*>(user_data);
        states->emplace_back(fl_value_get_string(message));
        return fl_value_new_string("");
      },
      &lifecycle_states);

  GtkWindow* window = GTK_WINDOW(gtk_window_new(GTK_WINDOW_TOPLEVEL));
  gtk_widget_show(GTK_WIDGET(window));
  g_autoptr(FlWindowStateMonitor) monitor =
      fl_window_state_monitor_new(FL_BINARY_MESSENGER(messenger), window);

  GtkNative* native = gtk_widget_get_native(GTK_WIDGET(window));
  GdkSurface* surface = gtk_native_get_surface(native);
  GParamSpec* mapped_pspec =
      g_object_class_find_property(G_OBJECT_GET_CLASS(surface), "mapped");
  ASSERT_NE(mapped_pspec, nullptr);
  g_object_notify_by_pspec(G_OBJECT(surface), mapped_pspec);

  ASSERT_EQ(lifecycle_states.size(), 2u);
  EXPECT_EQ(lifecycle_states[0], "AppLifecycleState.inactive");
  EXPECT_EQ(lifecycle_states[1], "AppLifecycleState.hidden");

  fl_binary_messenger_shutdown(FL_BINARY_MESSENGER(messenger));
}
#endif  // FLUTTER_LINUX_GTK4

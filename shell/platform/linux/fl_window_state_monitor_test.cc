// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_window_state_monitor.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_string_codec.h"
#include "flutter/shell/platform/linux/testing/fl_test.h"
#include "flutter/shell/platform/linux/testing/mock_binary_messenger.h"
#include "flutter/shell/platform/linux/testing/mock_window.h"

#include "gtest/gtest.h"

// Matches if a FlValue is a the supplied string.
class FlValueStringMatcher {
 public:
  using is_gtest_matcher = void;

  explicit FlValueStringMatcher(::testing::Matcher<std::string> value)
      : value_(std::move(value)) {}

  bool MatchAndExplain(GBytes* data,
                       ::testing::MatchResultListener* result_listener) const {
    g_autoptr(FlStringCodec) codec = fl_string_codec_new();
    g_autoptr(GError) error = nullptr;
    g_autoptr(FlValue) value =
        fl_message_codec_decode_message(FL_MESSAGE_CODEC(codec), data, &error);
    if (value == nullptr) {
      *result_listener << ::testing::PrintToString(error->message);
      return false;
    }
    if (!value_.MatchAndExplain(fl_value_get_string(value), result_listener)) {
      *result_listener << " where the value doesn't match: \"" << value << "\"";
      return false;
    }
    return true;
  }

  void DescribeTo(std::ostream* os) const {
    *os << "value ";
    value_.DescribeTo(os);
  }

  void DescribeNegationTo(std::ostream* os) const {
    *os << "value ";
    value_.DescribeNegationTo(os);
  }

 private:
  ::testing::Matcher<std::string> value_;
};

::testing::Matcher<GBytes*> LifecycleString(const std::string& value) {
  return FlValueStringMatcher(::testing::StrEq(value));
}

TEST(FlWindowStateMonitorTest, GainFocus) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;
  ::testing::NiceMock<flutter::testing::MockWindow> mock_window;

  gtk_init(0, nullptr);

  EXPECT_CALL(mock_window, gdk_window_get_state)
      .WillOnce(::testing::Return(static_cast<GdkWindowState>(0)));
  EXPECT_CALL(messenger, fl_binary_messenger_send_on_channel(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::StrEq("flutter/lifecycle"),
                             LifecycleString("AppLifecycleState.resumed"),
                             ::testing::_, ::testing::_, ::testing::_));

  GtkWindow* window = GTK_WINDOW(gtk_window_new(GTK_WINDOW_TOPLEVEL));
  gtk_widget_show(GTK_WIDGET(window));
  g_autoptr(FlWindowStateMonitor) monitor =
      fl_window_state_monitor_new(messenger, window);

  GdkEvent event = {
      .window_state = {.new_window_state = GDK_WINDOW_STATE_FOCUSED}};
  gboolean handled;
  g_signal_emit_by_name(window, "window-state-event", &event, &handled);
}

TEST(FlWindowStateMonitorTest, LoseFocus) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;
  ::testing::NiceMock<flutter::testing::MockWindow> mock_window;

  gtk_init(0, nullptr);

  EXPECT_CALL(mock_window, gdk_window_get_state)
      .WillOnce(::testing::Return(GDK_WINDOW_STATE_FOCUSED));
  EXPECT_CALL(messenger, fl_binary_messenger_send_on_channel(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::StrEq("flutter/lifecycle"),
                             LifecycleString("AppLifecycleState.inactive"),
                             ::testing::_, ::testing::_, ::testing::_));

  GtkWindow* window = GTK_WINDOW(gtk_window_new(GTK_WINDOW_TOPLEVEL));
  gtk_widget_show(GTK_WIDGET(window));
  g_autoptr(FlWindowStateMonitor) monitor =
      fl_window_state_monitor_new(messenger, window);

  GdkEvent event = {
      .window_state = {.new_window_state = static_cast<GdkWindowState>(0)}};
  gboolean handled;
  g_signal_emit_by_name(window, "window-state-event", &event, &handled);
}

TEST(FlWindowStateMonitorTest, EnterIconified) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;
  ::testing::NiceMock<flutter::testing::MockWindow> mock_window;

  gtk_init(0, nullptr);

  EXPECT_CALL(mock_window, gdk_window_get_state)
      .WillOnce(::testing::Return(static_cast<GdkWindowState>(0)));
  EXPECT_CALL(messenger, fl_binary_messenger_send_on_channel(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::StrEq("flutter/lifecycle"),
                             LifecycleString("AppLifecycleState.hidden"),
                             ::testing::_, ::testing::_, ::testing::_));

  GtkWindow* window = GTK_WINDOW(gtk_window_new(GTK_WINDOW_TOPLEVEL));
  gtk_widget_show(GTK_WIDGET(window));
  g_autoptr(FlWindowStateMonitor) monitor =
      fl_window_state_monitor_new(messenger, window);

  GdkEvent event = {
      .window_state = {.new_window_state = GDK_WINDOW_STATE_ICONIFIED}};
  gboolean handled;
  g_signal_emit_by_name(window, "window-state-event", &event, &handled);
}

TEST(FlWindowStateMonitorTest, LeaveIconified) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;
  ::testing::NiceMock<flutter::testing::MockWindow> mock_window;

  gtk_init(0, nullptr);

  EXPECT_CALL(mock_window, gdk_window_get_state)
      .WillOnce(::testing::Return(GDK_WINDOW_STATE_ICONIFIED));
  EXPECT_CALL(messenger, fl_binary_messenger_send_on_channel(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::StrEq("flutter/lifecycle"),
                             LifecycleString("AppLifecycleState.inactive"),
                             ::testing::_, ::testing::_, ::testing::_));

  GtkWindow* window = GTK_WINDOW(gtk_window_new(GTK_WINDOW_TOPLEVEL));
  gtk_widget_show(GTK_WIDGET(window));
  g_autoptr(FlWindowStateMonitor) monitor =
      fl_window_state_monitor_new(messenger, window);

  GdkEvent event = {
      .window_state = {.new_window_state = static_cast<GdkWindowState>(0)}};
  gboolean handled;
  g_signal_emit_by_name(window, "window-state-event", &event, &handled);
}

TEST(FlWindowStateMonitorTest, LeaveIconifiedFocused) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;
  ::testing::NiceMock<flutter::testing::MockWindow> mock_window;

  gtk_init(0, nullptr);

  EXPECT_CALL(mock_window, gdk_window_get_state)
      .WillOnce(::testing::Return(GDK_WINDOW_STATE_ICONIFIED));
  EXPECT_CALL(messenger, fl_binary_messenger_send_on_channel(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::StrEq("flutter/lifecycle"),
                             LifecycleString("AppLifecycleState.resumed"),
                             ::testing::_, ::testing::_, ::testing::_));

  GtkWindow* window = GTK_WINDOW(gtk_window_new(GTK_WINDOW_TOPLEVEL));
  gtk_widget_show(GTK_WIDGET(window));
  g_autoptr(FlWindowStateMonitor) monitor =
      fl_window_state_monitor_new(messenger, window);

  GdkEvent event = {
      .window_state = {.new_window_state = static_cast<GdkWindowState>(
                           GDK_WINDOW_STATE_FOCUSED)}};
  gboolean handled;
  g_signal_emit_by_name(window, "window-state-event", &event, &handled);
}

TEST(FlWindowStateMonitorTest, EnterWithdrawn) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;
  ::testing::NiceMock<flutter::testing::MockWindow> mock_window;

  gtk_init(0, nullptr);

  EXPECT_CALL(mock_window, gdk_window_get_state)
      .WillOnce(::testing::Return(static_cast<GdkWindowState>(0)));
  EXPECT_CALL(messenger, fl_binary_messenger_send_on_channel(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::StrEq("flutter/lifecycle"),
                             LifecycleString("AppLifecycleState.hidden"),
                             ::testing::_, ::testing::_, ::testing::_));

  GtkWindow* window = GTK_WINDOW(gtk_window_new(GTK_WINDOW_TOPLEVEL));
  gtk_widget_show(GTK_WIDGET(window));
  g_autoptr(FlWindowStateMonitor) monitor =
      fl_window_state_monitor_new(messenger, window);

  GdkEvent event = {
      .window_state = {.new_window_state = GDK_WINDOW_STATE_WITHDRAWN}};
  gboolean handled;
  g_signal_emit_by_name(window, "window-state-event", &event, &handled);
}

TEST(FlWindowStateMonitorTest, LeaveWithdrawn) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;
  ::testing::NiceMock<flutter::testing::MockWindow> mock_window;

  gtk_init(0, nullptr);

  EXPECT_CALL(mock_window, gdk_window_get_state)
      .WillOnce(::testing::Return(GDK_WINDOW_STATE_WITHDRAWN));
  EXPECT_CALL(messenger, fl_binary_messenger_send_on_channel(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::StrEq("flutter/lifecycle"),
                             LifecycleString("AppLifecycleState.inactive"),
                             ::testing::_, ::testing::_, ::testing::_));

  GtkWindow* window = GTK_WINDOW(gtk_window_new(GTK_WINDOW_TOPLEVEL));
  gtk_widget_show(GTK_WIDGET(window));
  g_autoptr(FlWindowStateMonitor) monitor =
      fl_window_state_monitor_new(messenger, window);

  GdkEvent event = {
      .window_state = {.new_window_state = static_cast<GdkWindowState>(0)}};
  gboolean handled;
  g_signal_emit_by_name(window, "window-state-event", &event, &handled);
}

TEST(FlWindowStateMonitorTest, LeaveWithdrawnFocused) {
  ::testing::NiceMock<flutter::testing::MockBinaryMessenger> messenger;
  ::testing::NiceMock<flutter::testing::MockWindow> mock_window;

  gtk_init(0, nullptr);

  EXPECT_CALL(mock_window, gdk_window_get_state)
      .WillOnce(::testing::Return(GDK_WINDOW_STATE_WITHDRAWN));
  EXPECT_CALL(messenger, fl_binary_messenger_send_on_channel(
                             ::testing::Eq<FlBinaryMessenger*>(messenger),
                             ::testing::StrEq("flutter/lifecycle"),
                             LifecycleString("AppLifecycleState.resumed"),
                             ::testing::_, ::testing::_, ::testing::_));

  GtkWindow* window = GTK_WINDOW(gtk_window_new(GTK_WINDOW_TOPLEVEL));
  gtk_widget_show(GTK_WIDGET(window));
  g_autoptr(FlWindowStateMonitor) monitor =
      fl_window_state_monitor_new(messenger, window);

  GdkEvent event = {
      .window_state = {.new_window_state = static_cast<GdkWindowState>(
                           GDK_WINDOW_STATE_FOCUSED)}};
  gboolean handled;
  g_signal_emit_by_name(window, "window-state-event", &event, &handled);
}

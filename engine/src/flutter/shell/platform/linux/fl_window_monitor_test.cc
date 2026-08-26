// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_window_monitor.h"

#include "flutter/shell/platform/linux/testing/fl_test_gtk_logs.h"
#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "flutter/shell/platform/linux/testing/mock_gtk.h"
#include "flutter/shell/platform/linux/testing/mock_isolate.h"
#include "gtest/gtest.h"

namespace {

// The monitor reports using function pointers that have no user data, so the
// calls they make are recorded here.
struct MonitorCalls {
  int configure = 0;
  int state_changed = 0;
  int is_active_notify = 0;
  int title_notify = 0;
  int moved_to_rect = 0;
  int close = 0;
  int destroy = 0;
  GdkRectangle rect = {};
};

MonitorCalls calls;

void on_configure() {
  calls.configure++;
}

void on_state_changed() {
  calls.state_changed++;
}

void on_is_active_notify() {
  calls.is_active_notify++;
}

void on_title_notify() {
  calls.title_notify++;
}

void on_moved_to_rect(int x, int y, int width, int height) {
  calls.moved_to_rect++;
  calls.rect = {x, y, width, height};
}

void on_close() {
  calls.close++;
}

void on_destroy() {
  calls.destroy++;
}

FlWindowMonitor* monitor_new(GtkWindow* window) {
  return fl_window_monitor_new(window, on_configure, on_state_changed,
                               on_is_active_notify, on_title_notify,
                               on_moved_to_rect, on_close, on_destroy);
}

// GdkWindow is abstract, so a concrete subclass is required to make instances
// that signals can be connected to. GdkWindow expects to be created by GDK with
// a backend behind it, so its dispose and finalize methods are replaced with
// ones that don't touch that state.
//
// The G_DEFINE_TYPE macros can't be used to do this, as they need to place a
// GdkWindow inside the instance structure and GDK doesn't make that structure
// public. The size of the structure is instead requested from the type system
// at runtime.
void test_gdk_window_dispose(GObject* object) {}

void test_gdk_window_finalize(GObject* object) {
  G_OBJECT_CLASS(g_type_class_peek(G_TYPE_OBJECT))->finalize(object);
}

void test_gdk_window_class_init(gpointer klass, gpointer data) {
  G_OBJECT_CLASS(klass)->dispose = test_gdk_window_dispose;
  G_OBJECT_CLASS(klass)->finalize = test_gdk_window_finalize;
}

GType test_gdk_window_get_type() {
  static gsize type = 0;
  if (g_once_init_enter(&type)) {
    GTypeQuery query;
    g_type_query(GDK_TYPE_WINDOW, &query);
    g_once_init_leave(
        &type, g_type_register_static_simple(
                   GDK_TYPE_WINDOW, "TestGdkWindow", query.class_size,
                   test_gdk_window_class_init, query.instance_size, nullptr,
                   static_cast<GTypeFlags>(0)));
  }
  return type;
}

GdkWindow* test_gdk_window_new() {
  return GDK_WINDOW(g_object_new(test_gdk_window_get_type(), nullptr));
}

// Checks if @monitor is listening to @name on @instance.
bool has_handler(gpointer instance,
                 const gchar* name,
                 FlWindowMonitor* monitor) {
  GSignalMatchType match =
      static_cast<GSignalMatchType>(G_SIGNAL_MATCH_ID | G_SIGNAL_MATCH_DATA);
  guint signal_id = g_signal_lookup(name, G_OBJECT_TYPE(instance));
  return g_signal_handler_find(instance, match, signal_id, 0, nullptr, nullptr,
                               monitor) != 0;
}

}  // namespace

using flutter::testing::fl_has_received_gtk_log_level;
using flutter::testing::fl_reset_received_gtk_log_levels;

class FlWindowMonitorTest : public flutter::testing::LinuxTest {
 protected:
  void SetUp() override {
    fl_reset_received_gtk_log_levels();
    calls = MonitorCalls();
  }

  // The monitor records the isolate it is created in.
  flutter::testing::MockIsolate isolate;
  ::testing::NiceMock<flutter::testing::MockGtk> mock_gtk;
};

// The moved-to-rect signal is emitted by the GdkWindow, which does not exist
// until the window is realized. The monitor has to wait for that to happen.
TEST_F(FlWindowMonitorTest, ConnectsToRealize) {
  g_autoptr(GtkWindow) window =
      GTK_WINDOW(g_object_ref_sink(gtk_window_new(GTK_WINDOW_TOPLEVEL)));
  ASSERT_FALSE(gtk_widget_get_realized(GTK_WIDGET(window)));

  g_autoptr(FlWindowMonitor) monitor = monitor_new(window);

  EXPECT_TRUE(has_handler(window, "realize", monitor));
}

// Unrealizing destroys the GdkWindow and the moved-to-rect connection with it,
// so the monitor has to stay connected to realize even if the window is already
// realized when it is created.
TEST_F(FlWindowMonitorTest, ConnectsToRealizeWhenAlreadyRealized) {
  g_autoptr(GtkWindow) window =
      GTK_WINDOW(g_object_ref_sink(gtk_window_new(GTK_WINDOW_TOPLEVEL)));
  gtk_widget_set_realized(GTK_WIDGET(window), TRUE);

  g_autoptr(FlWindowMonitor) monitor = monitor_new(window);

  EXPECT_TRUE(has_handler(window, "realize", monitor));
  // The window has no GdkWindow to connect moved-to-rect to yet, which is not
  // an error.
  EXPECT_FALSE(fl_has_received_gtk_log_level(G_LOG_LEVEL_CRITICAL));

  gtk_widget_set_realized(GTK_WIDGET(window), FALSE);
}

// A window that is already realized has a GdkWindow, so moved-to-rect can be
// connected immediately.
TEST_F(FlWindowMonitorTest, ConnectsMovedToRectWhenAlreadyRealized) {
  g_autoptr(GtkWindow) window =
      GTK_WINDOW(g_object_ref_sink(gtk_window_new(GTK_WINDOW_TOPLEVEL)));
  gtk_widget_set_realized(GTK_WIDGET(window), TRUE);
  g_autoptr(GdkWindow) gdk_window = test_gdk_window_new();
  EXPECT_CALL(mock_gtk, gtk_widget_get_window)
      .WillRepeatedly(::testing::Return(gdk_window));

  g_autoptr(FlWindowMonitor) monitor = monitor_new(window);

  EXPECT_TRUE(has_handler(gdk_window, "moved-to-rect", monitor));

  gtk_widget_set_realized(GTK_WIDGET(window), FALSE);
}

// A window that is not yet realized has no GdkWindow, so moved-to-rect can only
// be connected once it is realized.
TEST_F(FlWindowMonitorTest, ConnectsMovedToRectOnRealize) {
  g_autoptr(GtkWindow) window =
      GTK_WINDOW(g_object_ref_sink(gtk_window_new(GTK_WINDOW_TOPLEVEL)));
  g_autoptr(GdkWindow) gdk_window = test_gdk_window_new();

  g_autoptr(FlWindowMonitor) monitor = monitor_new(window);
  EXPECT_FALSE(has_handler(gdk_window, "moved-to-rect", monitor));

  // The GdkWindow is created when the window is realized.
  EXPECT_CALL(mock_gtk, gtk_widget_get_window)
      .WillRepeatedly(::testing::Return(gdk_window));
  g_signal_emit_by_name(window, "realize");

  EXPECT_TRUE(has_handler(gdk_window, "moved-to-rect", monitor));
}

// The window reports changes to its size, position or stacking with the
// configure-event signal.
TEST_F(FlWindowMonitorTest, Configure) {
  g_autoptr(GtkWindow) window =
      GTK_WINDOW(g_object_ref_sink(gtk_window_new(GTK_WINDOW_TOPLEVEL)));
  g_autoptr(FlWindowMonitor) monitor = monitor_new(window);

  GdkEventConfigure event = {};
  event.type = GDK_CONFIGURE;
  gboolean result = FALSE;
  g_signal_emit_by_name(window, "configure-event", &event, &result);

  EXPECT_EQ(calls.configure, 1);
}

// The window reports changes to its state with the window-state-event signal.
TEST_F(FlWindowMonitorTest, StateChanged) {
  g_autoptr(GtkWindow) window =
      GTK_WINDOW(g_object_ref_sink(gtk_window_new(GTK_WINDOW_TOPLEVEL)));
  g_autoptr(FlWindowMonitor) monitor = monitor_new(window);

  GdkEventWindowState event = {};
  event.type = GDK_WINDOW_STATE;
  event.changed_mask = GDK_WINDOW_STATE_MAXIMIZED;
  event.new_window_state = GDK_WINDOW_STATE_MAXIMIZED;
  gboolean result = FALSE;
  g_signal_emit_by_name(window, "window-state-event", &event, &result);

  EXPECT_EQ(calls.state_changed, 1);
}

TEST_F(FlWindowMonitorTest, IsActiveNotify) {
  g_autoptr(GtkWindow) window =
      GTK_WINDOW(g_object_ref_sink(gtk_window_new(GTK_WINDOW_TOPLEVEL)));
  g_autoptr(FlWindowMonitor) monitor = monitor_new(window);

  g_object_notify(G_OBJECT(window), "is-active");

  EXPECT_EQ(calls.is_active_notify, 1);
}

TEST_F(FlWindowMonitorTest, TitleNotify) {
  g_autoptr(GtkWindow) window =
      GTK_WINDOW(g_object_ref_sink(gtk_window_new(GTK_WINDOW_TOPLEVEL)));
  g_autoptr(FlWindowMonitor) monitor = monitor_new(window);

  g_object_notify(G_OBJECT(window), "title");

  EXPECT_EQ(calls.title_notify, 1);
}

// Popup windows are told where they ended up by the moved-to-rect signal.
TEST_F(FlWindowMonitorTest, MovedToRect) {
  g_autoptr(GtkWindow) window =
      GTK_WINDOW(g_object_ref_sink(gtk_window_new(GTK_WINDOW_TOPLEVEL)));
  gtk_widget_set_realized(GTK_WIDGET(window), TRUE);
  g_autoptr(GdkWindow) gdk_window = test_gdk_window_new();
  EXPECT_CALL(mock_gtk, gtk_widget_get_window)
      .WillRepeatedly(::testing::Return(gdk_window));
  g_autoptr(FlWindowMonitor) monitor = monitor_new(window);

  GdkRectangle flipped_rect = {1, 2, 3, 4};
  GdkRectangle final_rect = {5, 6, 7, 8};
  g_signal_emit_by_name(gdk_window, "moved-to-rect", &flipped_rect, &final_rect,
                        FALSE, FALSE);

  EXPECT_EQ(calls.moved_to_rect, 1);
  EXPECT_EQ(calls.rect.x, 5);
  EXPECT_EQ(calls.rect.y, 6);
  EXPECT_EQ(calls.rect.width, 7);
  EXPECT_EQ(calls.rect.height, 8);

  gtk_widget_set_realized(GTK_WIDGET(window), FALSE);
}

// The backend is not always able to report where the window ended up, in which
// case there is nothing to report.
TEST_F(FlWindowMonitorTest, MovedToRectWithoutFinalRect) {
  g_autoptr(GtkWindow) window =
      GTK_WINDOW(g_object_ref_sink(gtk_window_new(GTK_WINDOW_TOPLEVEL)));
  gtk_widget_set_realized(GTK_WIDGET(window), TRUE);
  g_autoptr(GdkWindow) gdk_window = test_gdk_window_new();
  EXPECT_CALL(mock_gtk, gtk_widget_get_window)
      .WillRepeatedly(::testing::Return(gdk_window));
  g_autoptr(FlWindowMonitor) monitor = monitor_new(window);

  GdkRectangle flipped_rect = {1, 2, 3, 4};
  g_signal_emit_by_name(gdk_window, "moved-to-rect", &flipped_rect, nullptr,
                        FALSE, FALSE);

  EXPECT_EQ(calls.moved_to_rect, 0);

  gtk_widget_set_realized(GTK_WIDGET(window), FALSE);
}

// Closing is requested with the delete-event signal. The window is not
// destroyed in response, as Flutter decides if the close is allowed.
TEST_F(FlWindowMonitorTest, Close) {
  g_autoptr(GtkWindow) window =
      GTK_WINDOW(g_object_ref_sink(gtk_window_new(GTK_WINDOW_TOPLEVEL)));
  g_autoptr(FlWindowMonitor) monitor = monitor_new(window);

  GdkEvent event = {};
  event.type = GDK_DELETE;
  gboolean result = FALSE;
  g_signal_emit_by_name(window, "delete-event", &event, &result);

  EXPECT_EQ(calls.close, 1);
  EXPECT_TRUE(result);
  EXPECT_EQ(calls.destroy, 0);
}

TEST_F(FlWindowMonitorTest, Destroy) {
  g_autoptr(GtkWindow) window =
      GTK_WINDOW(g_object_ref_sink(gtk_window_new(GTK_WINDOW_TOPLEVEL)));
  g_autoptr(FlWindowMonitor) monitor = monitor_new(window);

  g_signal_emit_by_name(window, "destroy");

  EXPECT_EQ(calls.destroy, 1);
}

// The monitor keeps the window alive for as long as it is monitoring it, and
// releases it when it stops.
TEST_F(FlWindowMonitorTest, ReferencesWindow) {
  g_autoptr(GtkWindow) window =
      GTK_WINDOW(g_object_ref_sink(gtk_window_new(GTK_WINDOW_TOPLEVEL)));
  guint ref_count = G_OBJECT(window)->ref_count;

  FlWindowMonitor* monitor = monitor_new(window);
  EXPECT_EQ(G_OBJECT(window)->ref_count, ref_count + 1);

  g_object_unref(monitor);
  EXPECT_EQ(G_OBJECT(window)->ref_count, ref_count);
}

// A destroyed monitor stops reporting, rather than using its callbacks after
// the Dart object they belong to has gone.
TEST_F(FlWindowMonitorTest, StopsReportingWhenDestroyed) {
  g_autoptr(GtkWindow) window =
      GTK_WINDOW(g_object_ref_sink(gtk_window_new(GTK_WINDOW_TOPLEVEL)));
  FlWindowMonitor* monitor = monitor_new(window);
  g_object_unref(monitor);

  GdkEventConfigure event = {};
  event.type = GDK_CONFIGURE;
  gboolean result = FALSE;
  g_signal_emit_by_name(window, "configure-event", &event, &result);
  g_object_notify(G_OBJECT(window), "title");

  EXPECT_EQ(calls.configure, 0);
  EXPECT_EQ(calls.title_notify, 0);
}

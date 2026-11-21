// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_view_renderer_subsurface.h"

#include "gtest/gtest.h"

#include <gdk/gdkwayland.h>

#include "flutter/shell/platform/linux/fl_view_renderer.h"
#include "flutter/shell/platform/linux/testing/fl_test_gtk_logs.h"
#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "flutter/shell/platform/linux/testing/mock_epoxy.h"
#include "flutter/shell/platform/linux/testing/mock_gtk.h"
#include "flutter/shell/platform/linux/testing/mock_wayland.h"

class FlViewRendererSubsurfaceTest : public flutter::testing::LinuxTest {
 protected:
  // GTK queries the window state when widgets are realized.
  ::testing::NiceMock<flutter::testing::MockGtk> gtk;
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  ::testing::NiceMock<flutter::testing::MockWayland> wayland;
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

TEST_F(FlViewRendererSubsurfaceTest, PresentLayersAfterDestroy) {
  // Create a renderer and destroy it.
  FlViewRendererSubsurface* renderer =
      fl_view_renderer_subsurface_new(engine, FALSE);
  g_object_ref_sink(renderer);
  fl_gtk_widget_destroy(GTK_WIDGET(renderer));

  // Present a frame on a destroyed widget.
  fl_view_renderer_present_layers(FL_VIEW_RENDERER(renderer), nullptr, 0);

  g_object_unref(renderer);
}

// GTK destroys the window's Wayland surface when it is hidden. When the window
// is shown again the new surface may not exist yet when the widget is mapped,
// so the subsurface is recreated once it does.
TEST_F(FlViewRendererSubsurfaceTest, RecreateSubsurfaceAfterShow) {
  // GDK can't destroy a window without a backend, so this is never freed.
  static GdkWindow* toplevel_window =
      GDK_WINDOW(g_object_new(gdk_wayland_window_get_type(), nullptr));
  struct wl_surface* old_surface =
      flutter::testing::fl_mock_wayland_get_surface();
  struct wl_surface* new_surface =
      flutter::testing::fl_mock_wayland_get_surface();
  struct wl_surface* toplevel_surface = old_surface;

  FlViewRendererSubsurface* renderer =
      fl_view_renderer_subsurface_new(engine, FALSE);
  ASSERT_NE(renderer, nullptr);
  GtkWidget* window = gtk_offscreen_window_new();
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(renderer));

  GdkDisplay* display = gdk_display_get_default();
  ASSERT_TRUE(GDK_IS_WAYLAND_DISPLAY(display));
  ON_CALL(gtk, gtk_widget_get_display)
      .WillByDefault(::testing::Return(display));
  ON_CALL(gtk, gdk_wayland_display_get_wl_display(display))
      .WillByDefault(
          ::testing::Return(flutter::testing::fl_mock_wayland_get_display()));
  ON_CALL(gtk, gtk_widget_get_window(GTK_WIDGET(renderer)))
      .WillByDefault(::testing::Return(toplevel_window));
  ON_CALL(gtk, gdk_wayland_window_get_wl_surface(toplevel_window))
      .WillByDefault(::testing::ReturnPointee(&toplevel_surface));

  int subsurface_count = 0;
  ON_CALL(wayland, CreateObject(::testing::StrEq("wl_subsurface")))
      .WillByDefault([&subsurface_count](const char*) { subsurface_count++; });

  gtk_widget_show_all(window);
  while (g_main_context_iteration(nullptr, FALSE)) {
  }
  EXPECT_EQ(subsurface_count, 1);

  // Hide the window, which destroys its surface.
  toplevel_surface = nullptr;
  gtk_widget_hide(window);

  // Show the window, with the new surface only made after it is mapped.
  gtk_widget_show_all(window);
  toplevel_surface = new_surface;
  while (g_main_context_iteration(nullptr, FALSE)) {
  }
  EXPECT_EQ(subsurface_count, 2);

  fl_gtk_widget_destroy(window);
  flutter::testing::fl_mock_wayland_free_surface(old_surface);
  flutter::testing::fl_mock_wayland_free_surface(new_surface);
}

// The window may be hidden again before the subsurface is recreated after it
// is shown. A surface of a hidden window is going away, so no subsurface is
// made on it, and one is made once the window is shown again.
TEST_F(FlViewRendererSubsurfaceTest, NoSubsurfaceWhenHiddenBeforeIdle) {
  // GDK can't destroy a window without a backend, so this is never freed.
  static GdkWindow* toplevel_window =
      GDK_WINDOW(g_object_new(gdk_wayland_window_get_type(), nullptr));
  struct wl_surface* old_surface =
      flutter::testing::fl_mock_wayland_get_surface();
  struct wl_surface* new_surface =
      flutter::testing::fl_mock_wayland_get_surface();
  struct wl_surface* toplevel_surface = old_surface;

  FlViewRendererSubsurface* renderer =
      fl_view_renderer_subsurface_new(engine, FALSE);
  ASSERT_NE(renderer, nullptr);
  GtkWidget* window = gtk_offscreen_window_new();
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(renderer));

  GdkDisplay* display = gdk_display_get_default();
  ASSERT_TRUE(GDK_IS_WAYLAND_DISPLAY(display));
  ON_CALL(gtk, gtk_widget_get_display)
      .WillByDefault(::testing::Return(display));
  ON_CALL(gtk, gdk_wayland_display_get_wl_display(display))
      .WillByDefault(
          ::testing::Return(flutter::testing::fl_mock_wayland_get_display()));
  ON_CALL(gtk, gtk_widget_get_window(GTK_WIDGET(renderer)))
      .WillByDefault(::testing::Return(toplevel_window));
  ON_CALL(gtk, gdk_wayland_window_get_wl_surface(toplevel_window))
      .WillByDefault(::testing::ReturnPointee(&toplevel_surface));

  int subsurface_count = 0;
  ON_CALL(wayland, CreateObject(::testing::StrEq("wl_subsurface")))
      .WillByDefault([&subsurface_count](const char*) { subsurface_count++; });

  gtk_widget_show_all(window);
  while (g_main_context_iteration(nullptr, FALSE)) {
  }
  EXPECT_EQ(subsurface_count, 1);

  toplevel_surface = nullptr;
  gtk_widget_hide(window);

  // Show the window and hide it again before the main loop runs. The new
  // surface still exists, but is going away with the hidden window.
  gtk_widget_show_all(window);
  toplevel_surface = new_surface;
  gtk_widget_hide(window);
  while (g_main_context_iteration(nullptr, FALSE)) {
  }
  EXPECT_EQ(subsurface_count, 1);

  // Showing the window again makes the subsurface on its surface.
  gtk_widget_show_all(window);
  while (g_main_context_iteration(nullptr, FALSE)) {
  }
  EXPECT_EQ(subsurface_count, 2);

  fl_gtk_widget_destroy(window);
  flutter::testing::fl_mock_wayland_free_surface(old_surface);
  flutter::testing::fl_mock_wayland_free_surface(new_surface);
}

// Hiding the window releases the subsurface and its EGL resources. Showing it
// again recreates them on the replacement surface.
TEST_F(FlViewRendererSubsurfaceTest, ReleasesSubsurfaceWhenHidden) {
  // GDK can't destroy a window without a backend, so this is never freed.
  static GdkWindow* toplevel_window =
      GDK_WINDOW(g_object_new(gdk_wayland_window_get_type(), nullptr));
  struct wl_surface* old_surface =
      flutter::testing::fl_mock_wayland_get_surface();
  struct wl_surface* new_surface =
      flutter::testing::fl_mock_wayland_get_surface();
  struct wl_surface* toplevel_surface = old_surface;

  FlViewRendererSubsurface* renderer =
      fl_view_renderer_subsurface_new(engine, FALSE);
  ASSERT_NE(renderer, nullptr);
  GtkWidget* window = gtk_offscreen_window_new();
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(renderer));

  GdkDisplay* display = gdk_display_get_default();
  ASSERT_TRUE(GDK_IS_WAYLAND_DISPLAY(display));
  ON_CALL(gtk, gtk_widget_get_display)
      .WillByDefault(::testing::Return(display));
  ON_CALL(gtk, gdk_wayland_display_get_wl_display(display))
      .WillByDefault(
          ::testing::Return(flutter::testing::fl_mock_wayland_get_display()));
  ON_CALL(gtk, gtk_widget_get_window(GTK_WIDGET(renderer)))
      .WillByDefault(::testing::Return(toplevel_window));
  ON_CALL(gtk, gdk_wayland_window_get_wl_surface(toplevel_window))
      .WillByDefault(::testing::ReturnPointee(&toplevel_surface));

  int subsurface_count = 0;
  int subsurface_destroy_count = 0;
  ON_CALL(wayland, CreateObject(::testing::StrEq("wl_subsurface")))
      .WillByDefault([&subsurface_count](const char*) { subsurface_count++; });
  ON_CALL(wayland, DestroyObject(::testing::StrEq("wl_subsurface")))
      .WillByDefault([&subsurface_destroy_count](const char*) {
        subsurface_destroy_count++;
      });

  gtk_widget_show_all(window);
  while (g_main_context_iteration(nullptr, FALSE)) {
  }
  EXPECT_EQ(subsurface_count, 1);
  EXPECT_EQ(subsurface_destroy_count, 0);

  toplevel_surface = nullptr;
  gtk_widget_hide(window);
  EXPECT_EQ(subsurface_destroy_count, 1);

  toplevel_surface = new_surface;
  gtk_widget_show_all(window);
  while (g_main_context_iteration(nullptr, FALSE)) {
  }
  EXPECT_EQ(subsurface_count, 2);

  fl_gtk_widget_destroy(window);
  flutter::testing::fl_mock_wayland_free_surface(old_surface);
  flutter::testing::fl_mock_wayland_free_surface(new_surface);
}

// Repeated hide/show cycles keep creating one subsurface per show. This also
// checks that the parent surface state is reset on unmap, so a recycled
// Wayland object can't be mistaken for the previous parent.
TEST_F(FlViewRendererSubsurfaceTest, RepeatedHideShow) {
  // GDK can't destroy a window without a backend, so this is never freed.
  static GdkWindow* toplevel_window =
      GDK_WINDOW(g_object_new(gdk_wayland_window_get_type(), nullptr));
  struct wl_surface* old_surface =
      flutter::testing::fl_mock_wayland_get_surface();
  struct wl_surface* new_surface =
      flutter::testing::fl_mock_wayland_get_surface();
  struct wl_surface* toplevel_surface = old_surface;

  FlViewRendererSubsurface* renderer =
      fl_view_renderer_subsurface_new(engine, FALSE);
  ASSERT_NE(renderer, nullptr);
  GtkWidget* window = gtk_offscreen_window_new();
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(renderer));

  GdkDisplay* display = gdk_display_get_default();
  ASSERT_TRUE(GDK_IS_WAYLAND_DISPLAY(display));
  ON_CALL(gtk, gtk_widget_get_display)
      .WillByDefault(::testing::Return(display));
  ON_CALL(gtk, gdk_wayland_display_get_wl_display(display))
      .WillByDefault(
          ::testing::Return(flutter::testing::fl_mock_wayland_get_display()));
  ON_CALL(gtk, gtk_widget_get_window(GTK_WIDGET(renderer)))
      .WillByDefault(::testing::Return(toplevel_window));
  ON_CALL(gtk, gdk_wayland_window_get_wl_surface(toplevel_window))
      .WillByDefault(::testing::ReturnPointee(&toplevel_surface));

  int subsurface_count = 0;
  ON_CALL(wayland, CreateObject(::testing::StrEq("wl_subsurface")))
      .WillByDefault([&subsurface_count](const char*) { subsurface_count++; });

  gtk_widget_show_all(window);
  while (g_main_context_iteration(nullptr, FALSE)) {
  }
  EXPECT_EQ(subsurface_count, 1);

  for (int i = 0; i < 5; i++) {
    toplevel_surface = nullptr;
    gtk_widget_hide(window);
    while (g_main_context_iteration(nullptr, FALSE)) {
    }

    // Use the same surface pointer each time; the state must still be reset on
    // unmap so the renderer doesn't rely on the pointer changing.
    toplevel_surface = new_surface;
    gtk_widget_show_all(window);
    while (g_main_context_iteration(nullptr, FALSE)) {
    }
    EXPECT_EQ(subsurface_count, 2 + i);
  }

  fl_gtk_widget_destroy(window);
  flutter::testing::fl_mock_wayland_free_surface(old_surface);
  flutter::testing::fl_mock_wayland_free_surface(new_surface);
}

// A size allocation while the window is hidden must not create a subsurface,
// even if the toplevel still reports an old Wayland surface.
TEST_F(FlViewRendererSubsurfaceTest,
       HiddenSizeAllocateDoesNotCreateSubsurface) {
  // GDK can't destroy a window without a backend, so this is never freed.
  static GdkWindow* toplevel_window =
      GDK_WINDOW(g_object_new(gdk_wayland_window_get_type(), nullptr));
  struct wl_surface* old_surface =
      flutter::testing::fl_mock_wayland_get_surface();
  struct wl_surface* new_surface =
      flutter::testing::fl_mock_wayland_get_surface();
  struct wl_surface* toplevel_surface = old_surface;

  FlViewRendererSubsurface* renderer =
      fl_view_renderer_subsurface_new(engine, FALSE);
  ASSERT_NE(renderer, nullptr);
  GtkWidget* window = gtk_offscreen_window_new();
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(renderer));

  GdkDisplay* display = gdk_display_get_default();
  ASSERT_TRUE(GDK_IS_WAYLAND_DISPLAY(display));
  ON_CALL(gtk, gtk_widget_get_display)
      .WillByDefault(::testing::Return(display));
  ON_CALL(gtk, gdk_wayland_display_get_wl_display(display))
      .WillByDefault(
          ::testing::Return(flutter::testing::fl_mock_wayland_get_display()));
  ON_CALL(gtk, gtk_widget_get_window(GTK_WIDGET(renderer)))
      .WillByDefault(::testing::Return(toplevel_window));
  ON_CALL(gtk, gdk_wayland_window_get_wl_surface(toplevel_window))
      .WillByDefault(::testing::ReturnPointee(&toplevel_surface));

  int subsurface_count = 0;
  ON_CALL(wayland, CreateObject(::testing::StrEq("wl_subsurface")))
      .WillByDefault([&subsurface_count](const char*) { subsurface_count++; });

  gtk_widget_show_all(window);
  while (g_main_context_iteration(nullptr, FALSE)) {
  }
  EXPECT_EQ(subsurface_count, 1);

  toplevel_surface = nullptr;
  gtk_widget_hide(window);
  while (g_main_context_iteration(nullptr, FALSE)) {
  }
  EXPECT_EQ(subsurface_count, 1);

  // Pretend the hidden window still has a surface while it is being allocated.
  toplevel_surface = new_surface;
  GtkAllocation allocation = {0, 0, 100, 100};
  gtk_widget_size_allocate(GTK_WIDGET(renderer), &allocation);
  while (g_main_context_iteration(nullptr, FALSE)) {
  }
  EXPECT_EQ(subsurface_count, 1);

  gtk_widget_show_all(window);
  while (g_main_context_iteration(nullptr, FALSE)) {
  }
  EXPECT_EQ(subsurface_count, 2);

  fl_gtk_widget_destroy(window);
  flutter::testing::fl_mock_wayland_free_surface(old_surface);
  flutter::testing::fl_mock_wayland_free_surface(new_surface);
}

// GtkWidget::unmap also runs when only the renderer is hidden while the
// toplevel window stays mapped, as happens when a GtkStack page is switched.
// The subsurface is attached to the toplevel surface, so it is released and
// recreated when the widget is shown again instead of leaving the old frame
// over the new page.
TEST_F(FlViewRendererSubsurfaceTest, WidgetHideShowWithWindowMapped) {
  // GDK can't destroy a window without a backend, so this is never freed.
  static GdkWindow* toplevel_window =
      GDK_WINDOW(g_object_new(gdk_wayland_window_get_type(), nullptr));
  struct wl_surface* old_surface =
      flutter::testing::fl_mock_wayland_get_surface();
  struct wl_surface* new_surface =
      flutter::testing::fl_mock_wayland_get_surface();
  struct wl_surface* toplevel_surface = old_surface;

  FlViewRendererSubsurface* renderer =
      fl_view_renderer_subsurface_new(engine, FALSE);
  ASSERT_NE(renderer, nullptr);
  GtkWidget* window = gtk_offscreen_window_new();
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(renderer));

  GdkDisplay* display = gdk_display_get_default();
  ASSERT_TRUE(GDK_IS_WAYLAND_DISPLAY(display));
  ON_CALL(gtk, gtk_widget_get_display)
      .WillByDefault(::testing::Return(display));
  ON_CALL(gtk, gdk_wayland_display_get_wl_display(display))
      .WillByDefault(
          ::testing::Return(flutter::testing::fl_mock_wayland_get_display()));
  ON_CALL(gtk, gtk_widget_get_window(GTK_WIDGET(renderer)))
      .WillByDefault(::testing::Return(toplevel_window));
  ON_CALL(gtk, gdk_wayland_window_get_wl_surface(toplevel_window))
      .WillByDefault(::testing::ReturnPointee(&toplevel_surface));

  int subsurface_count = 0;
  int subsurface_destroy_count = 0;
  ON_CALL(wayland, CreateObject(::testing::StrEq("wl_subsurface")))
      .WillByDefault([&subsurface_count](const char*) { subsurface_count++; });
  ON_CALL(wayland, DestroyObject(::testing::StrEq("wl_subsurface")))
      .WillByDefault([&subsurface_destroy_count](const char*) {
        subsurface_destroy_count++;
      });

  gtk_widget_show_all(window);
  while (g_main_context_iteration(nullptr, FALSE)) {
  }
  EXPECT_EQ(subsurface_count, 1);
  EXPECT_TRUE(gtk_widget_get_mapped(window));
  EXPECT_TRUE(gtk_widget_get_mapped(GTK_WIDGET(renderer)));

  // Hide only the renderer, as a GtkStack does for a page that is switched
  // away. The toplevel window and its surface remain.
  gtk_widget_set_child_visible(GTK_WIDGET(renderer), FALSE);
  while (g_main_context_iteration(nullptr, FALSE)) {
  }
  EXPECT_EQ(subsurface_destroy_count, 1);
  EXPECT_TRUE(gtk_widget_get_mapped(window));
  EXPECT_FALSE(gtk_widget_get_mapped(GTK_WIDGET(renderer)));

  // Showing the renderer recreates the subsurface on the same toplevel surface.
  gtk_widget_set_child_visible(GTK_WIDGET(renderer), TRUE);
  while (g_main_context_iteration(nullptr, FALSE)) {
  }
  EXPECT_TRUE(gtk_widget_get_mapped(GTK_WIDGET(renderer)));
  EXPECT_EQ(subsurface_count, 2);
  EXPECT_EQ(toplevel_surface, old_surface);

  fl_gtk_widget_destroy(window);
  flutter::testing::fl_mock_wayland_free_surface(old_surface);
  flutter::testing::fl_mock_wayland_free_surface(new_surface);
}

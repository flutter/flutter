// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_view_renderer_subsurface.h"

#include "gtest/gtest.h"

#include <gdk/gdkwayland.h>

#include <chrono>
#include <condition_variable>
#include <mutex>
#include <thread>

#include "flutter/shell/platform/linux/fl_framebuffer.h"
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

// Presenting to a subsurface can block until the GTK thread commits the parent
// surface, as the subsurface is synchronized with it and the driver waits for a
// buffer to be released. The GTK thread must not block on the renderer while
// that happens, e.g. when the window is resized.
TEST_F(FlViewRendererSubsurfaceTest, ResizeWhilePresentIsBlocked) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  ::testing::NiceMock<flutter::testing::MockWayland> wayland;

  // Pretend the widget is on Wayland, using the mock Wayland display.
  GdkDisplay* display =
      GDK_DISPLAY(g_object_new(gdk_wayland_display_get_type(), nullptr));
  GdkWindow* window =
      GDK_WINDOW(g_object_new(gdk_wayland_window_get_type(), nullptr));
  struct wl_surface* parent_surface =
      flutter::testing::fl_mock_wayland_get_surface();
  ON_CALL(gtk, gtk_widget_get_display(::testing::_))
      .WillByDefault(::testing::Return(display));
  ON_CALL(gtk, gdk_wayland_display_get_wl_display(display))
      .WillByDefault(
          ::testing::Return(flutter::testing::fl_mock_wayland_get_display()));
  ON_CALL(gtk, gtk_widget_get_window(::testing::_))
      .WillByDefault(::testing::Return(window));
  ON_CALL(gtk, gdk_wayland_window_get_wl_surface(window))
      .WillByDefault(::testing::Return(parent_surface));

  // Simulate the driver waiting for the compositor to release a buffer, which
  // happens when the GTK thread next commits the parent surface. Gives up
  // after a timeout so the test fails rather than hangs on a deadlock.
  std::mutex swap_mutex;
  std::condition_variable swap_cond;
  bool in_swap = false;
  bool parent_committed = true;
  bool swap_timed_out = false;
  ON_CALL(epoxy, eglSwapBuffers()).WillByDefault([&]() {
    std::unique_lock<std::mutex> lock(swap_mutex);
    in_swap = true;
    swap_cond.notify_all();
    if (!swap_cond.wait_for(lock, std::chrono::seconds(1),
                            [&]() { return parent_committed; })) {
      swap_timed_out = true;
    }
  });

  FlViewRendererSubsurface* renderer =
      fl_view_renderer_subsurface_new(engine, FALSE);
  constexpr size_t width = 100;
  constexpr size_t height = 100;
  gtk_widget_set_size_request(GTK_WIDGET(renderer), width, height);
  GtkWidget* toplevel = gtk_offscreen_window_new();
  gtk_container_add(GTK_CONTAINER(toplevel), GTK_WIDGET(renderer));
  gtk_widget_show_all(toplevel);

  g_autoptr(FlFramebuffer) framebuffer =
      fl_framebuffer_new(GL_RGB, width, height, FALSE);
  FlutterBackingStore backing_store = {
      .type = kFlutterBackingStoreTypeOpenGL,
      .open_gl = {.framebuffer = {.user_data = framebuffer}}};
  FlutterLayer layer = {.type = kFlutterLayerContentTypeBackingStore,
                        .backing_store = &backing_store,
                        .offset = {0, 0},
                        .size = {width, height}};
  const FlutterLayer* layers[1] = {&layer};

  // Present a first frame, so the view already has a frame of the size it is
  // resized to below.
  fl_view_renderer_present_layers(FL_VIEW_RENDERER(renderer), layers, 1);

  // Present a frame from the raster thread that blocks until the GTK thread
  // commits the parent surface.
  {
    std::lock_guard<std::mutex> lock(swap_mutex);
    in_swap = false;
    parent_committed = false;
  }
  std::thread raster_thread([&]() {
    fl_view_renderer_present_layers(FL_VIEW_RENDERER(renderer), layers, 1);
  });
  {
    std::unique_lock<std::mutex> lock(swap_mutex);
    swap_cond.wait(lock, [&]() { return in_swap; });
  }

  // Resize the view, after which GTK would commit the parent surface.
  GtkAllocation allocation = {.x = 0, .y = 0, .width = width, .height = height};
  g_signal_emit_by_name(renderer, "size-allocate", &allocation);
  {
    std::lock_guard<std::mutex> lock(swap_mutex);
    parent_committed = true;
  }
  swap_cond.notify_all();
  raster_thread.join();

  EXPECT_FALSE(swap_timed_out);

  // Process the notifications of the presented frames.
  while (g_main_context_iteration(nullptr, FALSE)) {
  }

  fl_gtk_widget_destroy(toplevel);
  flutter::testing::fl_mock_wayland_free_surface(parent_surface);
}

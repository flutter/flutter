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

#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_framebuffer.h"
#include "flutter/shell/platform/linux/fl_view_renderer.h"
#include "flutter/shell/platform/linux/testing/fl_test_gtk_logs.h"
#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "flutter/shell/platform/linux/testing/mock_epoxy.h"
#include "flutter/shell/platform/linux/testing/mock_gtk.h"
#include "flutter/shell/platform/linux/testing/mock_wayland.h"

class FlViewRendererSubsurfaceTest : public flutter::testing::LinuxTest {
 protected:
  void TearDown() override {
    if (parent_surface != nullptr) {
      flutter::testing::fl_mock_wayland_free_surface(parent_surface);
      parent_surface = nullptr;
    }
    LinuxTest::TearDown();
  }

  // Pretends widgets are on Wayland, using the mock Wayland display.
  void UseWayland() {
    GdkDisplay* display =
        GDK_DISPLAY(g_object_new(gdk_wayland_display_get_type(), nullptr));
    GdkWindow* window =
        GDK_WINDOW(g_object_new(gdk_wayland_window_get_type(), nullptr));
    parent_surface = flutter::testing::fl_mock_wayland_get_surface();
    ON_CALL(gtk, gtk_widget_get_display(::testing::_))
        .WillByDefault(::testing::Return(display));
    ON_CALL(gtk, gdk_wayland_display_get_wl_display(display))
        .WillByDefault(
            ::testing::Return(flutter::testing::fl_mock_wayland_get_display()));
    ON_CALL(gtk, gtk_widget_get_window(::testing::_))
        .WillByDefault(::testing::Return(window));
    ON_CALL(gtk, gdk_wayland_window_get_wl_surface(window))
        .WillByDefault(::testing::Return(parent_surface));
  }

  // Creates a renderer inside a window that is shown, so it has a subsurface.
  FlViewRendererSubsurface* CreateRenderer(gboolean sized_to_content,
                                           size_t width,
                                           size_t height,
                                           GtkWidget** toplevel) {
    FlViewRendererSubsurface* renderer =
        fl_view_renderer_subsurface_new(engine, sized_to_content);
    gtk_widget_set_size_request(GTK_WIDGET(renderer), width, height);
    *toplevel = gtk_offscreen_window_new();
    gtk_container_add(GTK_CONTAINER(*toplevel), GTK_WIDGET(renderer));
    gtk_widget_show_all(*toplevel);
    return renderer;
  }

  // Presents a frame of the given size, as the raster thread would.
  void Present(FlViewRendererSubsurface* renderer,
               size_t width,
               size_t height) {
    g_autoptr(FlFramebuffer) framebuffer =
        fl_framebuffer_new(GL_RGB, width, height, FALSE);
    FlutterBackingStore backing_store = {
        .type = kFlutterBackingStoreTypeOpenGL,
        .open_gl = {.framebuffer = {.user_data = framebuffer}}};
    FlutterLayer layer = {
        .type = kFlutterLayerContentTypeBackingStore,
        .backing_store = &backing_store,
        .offset = {0, 0},
        .size = {static_cast<double>(width), static_cast<double>(height)}};
    const FlutterLayer* layers[1] = {&layer};
    fl_view_renderer_present_layers(FL_VIEW_RENDERER(renderer), layers, 1);
  }

  // Runs the main loop until [done] is set, or a second has passed.
  void RunUntil(const bool& done) {
    gint64 expiry_time = g_get_monotonic_time() + G_USEC_PER_SEC;
    while (!done && g_get_monotonic_time() < expiry_time) {
      g_main_context_iteration(nullptr, FALSE);
      g_usleep(1000);
    }
  }

  // GTK queries the window state when widgets are realized.
  ::testing::NiceMock<flutter::testing::MockGtk> gtk;

  struct wl_surface* parent_surface = nullptr;
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

// The raster thread holds a reference to the renderer while presenting, which
// doesn't stop the GTK thread destroying the window it is in. Everything the
// renderer uses to present has to survive that.
TEST_F(FlViewRendererSubsurfaceTest, PresentAfterWindowDestroyed) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  ::testing::NiceMock<flutter::testing::MockWayland> wayland;
  UseWayland();

  GtkWidget* toplevel;
  FlViewRendererSubsurface* renderer =
      CreateRenderer(FALSE, 100, 100, &toplevel);
  Present(renderer, 100, 100);

  g_object_ref(renderer);
  fl_gtk_widget_destroy(toplevel);

  // The frame is dropped, as there is nothing left to show it in.
  EXPECT_CALL(epoxy, eglSwapBuffers).Times(0);
  Present(renderer, 100, 100);

  // Process the notifications of the presented frames.
  while (g_main_context_iteration(nullptr, FALSE)) {
  }

  g_object_unref(renderer);
}

// While the window is being resized the frame of the new size is held back by
// the compositor until GTK commits the window. The compositor keeps the buffer
// of a held frame until then, and of any frame it is replaced with, so only
// one is presented: a driver that runs out of buffers blocks the raster thread
// until a commit that GTK may have no reason to make.
TEST_F(FlViewRendererSubsurfaceTest, ResizeHoldsOneFrame) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  ::testing::NiceMock<flutter::testing::MockWayland> wayland;
  UseWayland();

  StartEngine(engine);
  bool frame_scheduled = false;
  fl_engine_get_embedder_api(engine)->ScheduleFrame =
      MOCK_ENGINE_PROC(ScheduleFrame, ([&frame_scheduled](auto engine) {
                         frame_scheduled = true;
                         return kSuccess;
                       }));

  GtkWidget* toplevel;
  FlViewRendererSubsurface* renderer =
      CreateRenderer(FALSE, 100, 100, &toplevel);
  Present(renderer, 100, 100);

  // The driver gives a buffer of the size the window was resized to.
  epoxy.egl_surface_width = 200;
  epoxy.egl_surface_height = 100;

  // Present frames from a raster thread once the resize has synchronized the
  // subsurface: one of the old size, then two of the new size.
  std::mutex mutex;
  std::condition_variable cond;
  bool synchronized = false;
  bool desynchronized = false;
  ON_CALL(wayland,
          Request(::testing::StrEq("wl_subsurface"), WL_SUBSURFACE_SET_SYNC))
      .WillByDefault([&]() {
        std::lock_guard<std::mutex> lock(mutex);
        synchronized = true;
        cond.notify_all();
      });
  ON_CALL(wayland,
          Request(::testing::StrEq("wl_subsurface"), WL_SUBSURFACE_SET_DESYNC))
      .WillByDefault([&]() { desynchronized = true; });
  int swap_count = 0;
  ON_CALL(epoxy, eglSwapBuffers()).WillByDefault([&]() { swap_count++; });
  std::thread raster_thread([&]() {
    {
      std::unique_lock<std::mutex> lock(mutex);
      cond.wait(lock, [&]() { return synchronized; });
    }
    Present(renderer, 100, 100);
    Present(renderer, 200, 100);
    Present(renderer, 200, 100);
  });

  // Resize the view. This waits for the frame of the new size.
  GtkAllocation allocation = {.x = 0, .y = 0, .width = 200, .height = 100};
  g_signal_emit_by_name(renderer, "size-allocate", &allocation);
  raster_thread.join();

  // Only the first frame of the new size was presented.
  EXPECT_EQ(swap_count, 1);

  // The frame stops being held back once GTK has painted the window: the
  // window is committed to show it, and another frame is asked for in place of
  // the ones that were dropped.
  bool window_committed = false;
  ON_CALL(wayland, Request(::testing::StrEq("wl_surface"), WL_SURFACE_COMMIT))
      .WillByDefault([&]() { window_committed = true; });
  RunUntil(desynchronized);
  EXPECT_TRUE(desynchronized);
  EXPECT_TRUE(window_committed);
  EXPECT_TRUE(frame_scheduled);

  // Frames are presented as they arrive again.
  Present(renderer, 200, 100);
  EXPECT_EQ(swap_count, 2);

  // Process the notifications of the presented frames.
  while (g_main_context_iteration(nullptr, FALSE)) {
  }

  fl_gtk_widget_destroy(toplevel);
}

// A view sized to its content is resized to fit the frames it is given. Only a
// frame that changes the size is held back for the window to be resized;
// others are shown as soon as they are presented, without GTK having to commit
// the window for each one.
TEST_F(FlViewRendererSubsurfaceTest, SizedToContentHoldsFrameOfNewSize) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  ::testing::NiceMock<flutter::testing::MockWayland> wayland;
  UseWayland();

  int sync_count = 0;
  bool desynchronized = false;
  ON_CALL(wayland,
          Request(::testing::StrEq("wl_subsurface"), WL_SUBSURFACE_SET_SYNC))
      .WillByDefault([&]() { sync_count++; });
  int swap_count = 0;
  ON_CALL(epoxy, eglSwapBuffers()).WillByDefault([&]() { swap_count++; });

  GtkWidget* toplevel;
  FlViewRendererSubsurface* renderer =
      CreateRenderer(TRUE, 100, 100, &toplevel);

  // Frames of the same size aren't held back.
  Present(renderer, 100, 100);
  Present(renderer, 100, 100);
  EXPECT_EQ(sync_count, 0);
  EXPECT_EQ(swap_count, 2);

  // A frame of a new size is, and frames after it are dropped until it has
  // been shown.
  epoxy.egl_surface_width = 150;
  epoxy.egl_surface_height = 100;
  Present(renderer, 150, 100);
  EXPECT_EQ(sync_count, 1);
  EXPECT_EQ(swap_count, 3);
  Present(renderer, 150, 100);
  EXPECT_EQ(swap_count, 3);

  // The frame is shown once GTK has resized and painted the window.
  ON_CALL(wayland,
          Request(::testing::StrEq("wl_subsurface"), WL_SUBSURFACE_SET_DESYNC))
      .WillByDefault([&]() { desynchronized = true; });
  RunUntil(desynchronized);
  EXPECT_TRUE(desynchronized);

  // Frames of that size aren't held back, but one of another size is.
  Present(renderer, 150, 100);
  EXPECT_EQ(sync_count, 1);
  EXPECT_EQ(swap_count, 4);
  epoxy.egl_surface_width = 180;
  Present(renderer, 180, 100);
  EXPECT_EQ(sync_count, 2);
  EXPECT_EQ(swap_count, 5);

  // Process the notifications of the presented frames.
  while (g_main_context_iteration(nullptr, FALSE)) {
  }

  fl_gtk_widget_destroy(toplevel);
}

// A held frame is only shown when the window is committed, which GTK does
// after painting it. GTK doesn't paint a window that isn't visible, or that
// the compositor isn't asking for frames for, so the frame is shown after a
// timeout instead and no more are held back until GTK paints again. The
// compositor would otherwise be left holding the frame, and its buffer.
TEST_F(FlViewRendererSubsurfaceTest, HeldFrameShownIfWindowNotPainted) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  ::testing::NiceMock<flutter::testing::MockWayland> wayland;
  UseWayland();

  int sync_count = 0;
  bool desynchronized = false;
  bool window_committed = false;
  ON_CALL(wayland,
          Request(::testing::StrEq("wl_subsurface"), WL_SUBSURFACE_SET_SYNC))
      .WillByDefault([&]() { sync_count++; });
  int swap_count = 0;
  ON_CALL(epoxy, eglSwapBuffers()).WillByDefault([&]() { swap_count++; });

  // GTK doesn't paint a window that is hidden.
  GtkWidget* toplevel;
  FlViewRendererSubsurface* renderer =
      CreateRenderer(TRUE, 100, 100, &toplevel);
  gtk_widget_hide(toplevel);

  Present(renderer, 100, 100);
  epoxy.egl_surface_width = 150;
  epoxy.egl_surface_height = 100;
  Present(renderer, 150, 100);
  EXPECT_EQ(sync_count, 1);
  EXPECT_EQ(swap_count, 2);

  ON_CALL(wayland,
          Request(::testing::StrEq("wl_subsurface"), WL_SUBSURFACE_SET_DESYNC))
      .WillByDefault([&]() { desynchronized = true; });
  ON_CALL(wayland, Request(::testing::StrEq("wl_surface"), WL_SURFACE_COMMIT))
      .WillByDefault([&]() { window_committed = true; });
  RunUntil(desynchronized);
  EXPECT_TRUE(desynchronized);
  EXPECT_TRUE(window_committed);

  // A frame of another size is no longer held back.
  epoxy.egl_surface_width = 180;
  Present(renderer, 180, 100);
  EXPECT_EQ(sync_count, 1);
  EXPECT_EQ(swap_count, 3);

  // Process the notifications of the presented frames.
  while (g_main_context_iteration(nullptr, FALSE)) {
  }

  fl_gtk_widget_destroy(toplevel);
}

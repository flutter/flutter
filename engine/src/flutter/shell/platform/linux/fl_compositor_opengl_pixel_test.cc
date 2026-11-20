// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_compositor_opengl_private.h"

#include <gdk/wayland/gdkwayland.h>

#include "flutter/shell/platform/linux/fl_gtk.h"
#include "flutter/shell/platform/linux/fl_view_private.h"

static void test_subsurface_resize() {
  if (!GDK_IS_WAYLAND_DISPLAY(gdk_display_get_default())) {
    g_test_skip("Requires a Wayland display at integer scale");
    return;
  }
  const gboolean requested =
      g_strcmp0(g_getenv("FLUTTER_GTK4_ENABLE_SUBSURFACE"), "1") == 0;
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlView) view = FL_VIEW(g_object_ref_sink(fl_view_new(project)));
  // Realize just the toplevel so the view has a Wayland parent without
  // starting the engine or receiving an initial allocation.
  g_autoptr(GtkWindow) window = GTK_WINDOW(g_object_ref_sink(gtk_window_new()));
  gtk_window_set_child(window, GTK_WIDGET(view));
  gtk_widget_realize(GTK_WIDGET(window));
  const double scale = fl_gtk_widget_get_scale(view->render_area);
  if (scale != static_cast<int>(scale)) {
    gtk_window_destroy(window);
    g_test_skip("Direct subsurface presentation requires integer scale");
    return;
  }
  g_assert_cmpint(gtk_widget_get_width(view->render_area), ==, 0);
  fl_view_gtk4_resize_subsurface(view, 0, 0);
  g_assert_null(view->subsurface_egl);
  gtk_widget_allocate(view->render_area, 64, 48, -1, nullptr);
  fl_view_gtk4_resize_subsurface(view, 64, 48);
  g_assert_cmpint(view->subsurface_egl != nullptr, ==, requested);
  gtk_window_destroy(window);
}

static void test_offset_layer() {
  constexpr int width = 6;
  constexpr int height = 4;
  g_autoptr(FlOpenGLManager) manager = fl_opengl_manager_new();
  g_assert_true(fl_opengl_manager_make_current(manager));
  g_autoptr(FlTaskRunner) runner = fl_task_runner_new(nullptr);
  g_autoptr(FlCompositorOpenGL) compositor =
      fl_compositor_opengl_new(runner, manager, FALSE);
  if (!compositor->can_blit) {
    g_test_skip("Driver does not support the compositor blit path");
    return;
  }
  g_autoptr(FlFramebuffer) source =
      fl_framebuffer_new(GL_RGBA, width, height, FALSE);
  glBindFramebuffer(GL_FRAMEBUFFER, fl_framebuffer_get_id(source));
  glClearColor(0, 1, 0, 1);
  glClear(GL_COLOR_BUFFER_BIT);
  FlutterBackingStore store = {
      .type = kFlutterBackingStoreTypeOpenGL,
      .open_gl = {.framebuffer = {.user_data = source}}};
  FlutterLayer layer = {.type = kFlutterLayerContentTypeBackingStore,
                        .backing_store = &store,
                        .size = {width, height}};
  const FlutterLayer* layers[] = {&layer};
  // Seed the retained target so a missing clear produces a visible pixel.
  g_assert_true(
      fl_compositor_present_layers(FL_COMPOSITOR(compositor), layers, 1));
  glBindFramebuffer(GL_FRAMEBUFFER, fl_framebuffer_get_id(source));
  glEnable(GL_SCISSOR_TEST);
  glScissor(0, height - 1, 1, 1);
  glClearColor(1, 0, 0, 1);
  glClear(GL_COLOR_BUFFER_BIT);
  layer.offset = {2, 1};
  g_assert_true(
      fl_compositor_present_layers(FL_COMPOSITOR(compositor), layers, 1));
  for (int y = 0; y < height; ++y) {
    for (int x = 0; x < width; ++x) {
      const uint8_t* pixel =
          compositor->pixels + 4 * ((height - 1 - y) * width + x);
      bool covered = x >= 2 && y >= 1;
      bool red = x == 2 && y == 1;
      g_assert_cmpuint(pixel[0], ==, red ? 255 : 0);
      g_assert_cmpuint(pixel[1], ==, covered && !red ? 255 : 0);
      g_assert_cmpuint(pixel[2], ==, 0);
      g_assert_cmpuint(pixel[3], ==, covered ? 255 : 0);
    }
  }
}

int main(int argc, char** argv) {
  g_test_init(&argc, &argv, nullptr);
  gtk_init();
  g_test_add_func("/compositor/offset-layer", test_offset_layer);
  g_test_add_func("/compositor/subsurface/resize", test_subsurface_resize);
  return g_test_run();
}

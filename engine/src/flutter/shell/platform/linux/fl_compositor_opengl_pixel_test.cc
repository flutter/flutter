// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_compositor_opengl_private.h"

#include <gdk/wayland/gdkwayland.h>

#include "flutter/shell/platform/linux/fl_engine_private.h"
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
  // Exercise the view's selection with a live destination, then again while
  // the requested surface is unavailable and after recreating it.
  FlOpenGLManager* manager = fl_engine_get_opengl_manager(view->engine);
  g_assert_true(fl_opengl_manager_make_current(manager));
  auto* compositor = fl_compositor_opengl_new(
      fl_engine_get_task_runner(view->engine), manager, TRUE);
  view->compositor = FL_COMPOSITOR(compositor);
  g_autoptr(FlFramebuffer) source = fl_framebuffer_new(GL_RGBA, 64, 48, FALSE);
  FlutterBackingStore store = {
      .type = kFlutterBackingStoreTypeOpenGL,
      .open_gl = {.framebuffer = {.user_data = source}}};
  FlutterLayer layer = {.type = kFlutterLayerContentTypeBackingStore,
                        .backing_store = &store,
                        .size = {64, 48}};
  const FlutterLayer* layers[] = {&layer};
  fl_view_gtk4_present_layers(view, layers, 1);
  g_assert_cmpint(compositor->frame_for_subsurface, ==, requested);
  if (requested) {
    g_assert_true(compositor->native_texture_sync == EGL_NO_SYNC_KHR);
    g_assert_cmpint(compositor->dmabuf_published_snapshot, ==, -1);
    fl_view_gtk4_clear_subsurface(view);
    g_assert_true(fl_opengl_manager_make_current(manager));
    fl_view_gtk4_present_layers(view, layers, 1);
    g_assert_false(compositor->frame_for_subsurface);
    fl_view_gtk4_resize_subsurface(view, 64, 48);
    g_assert_true(fl_opengl_manager_make_current(manager));
    fl_view_gtk4_present_layers(view, layers, 1);
    g_assert_true(compositor->frame_for_subsurface);
  }
  while (g_main_context_iteration(nullptr, FALSE)) {
  }
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
  const FlutterLayer* layers[] = {&layer, &layer};
  // Seed the retained target so a missing clear produces a visible pixel.
  g_assert_true(
      fl_compositor_present_layers(FL_COMPOSITOR(compositor), layers, 1));
  glBindFramebuffer(GL_FRAMEBUFFER, fl_framebuffer_get_id(source));
  glEnable(GL_SCISSOR_TEST);
  glScissor(0, height - 1, 1, 1);
  glClearColor(1, 0, 0, 1);
  glClear(GL_COLOR_BUFFER_BIT);
  glViewport(0, 0, width, height);
  layer.offset = {2, 1};
  // A second opaque layer of the same size covers the same pixels through
  // the shader path. Both paths should preserve scissor and framebuffer state.
  for (size_t layers_count : {1u, 2u}) {
    g_assert_true(fl_compositor_present_layers(FL_COMPOSITOR(compositor),
                                               layers, layers_count));
    g_assert_true(glIsEnabled(GL_SCISSOR_TEST));
    GLint framebuffer = 0;
    glGetIntegerv(GL_READ_FRAMEBUFFER_BINDING, &framebuffer);
    g_assert_cmpuint(framebuffer, ==, fl_framebuffer_get_id(source));
    glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &framebuffer);
    g_assert_cmpuint(framebuffer, ==, fl_framebuffer_get_id(source));
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
}

static void test_retained_texture() {
  g_autoptr(FlOpenGLManager) manager = fl_opengl_manager_new();
  g_assert_true(fl_opengl_manager_make_current(manager));
  g_autoptr(FlTaskRunner) runner = fl_task_runner_new(nullptr);
  g_autoptr(FlCompositorOpenGL) compositor =
      fl_compositor_opengl_new(runner, manager, TRUE);
  compositor->dmabuf_disabled = TRUE;
  g_autoptr(FlFramebuffer) source = fl_framebuffer_new(GL_RGBA, 4, 4, FALSE);
  FlutterBackingStore store = {
      .type = kFlutterBackingStoreTypeOpenGL,
      .open_gl = {.framebuffer = {.user_data = source}}};
  FlutterLayer layer = {.type = kFlutterLayerContentTypeBackingStore,
                        .backing_store = &store,
                        .size = {4, 4}};
  const FlutterLayer* layers[] = {&layer};
  glBindFramebuffer(GL_FRAMEBUFFER, fl_framebuffer_get_id(source));
  glClearColor(1, 0, 0, 1);
  glClear(GL_COLOR_BUFFER_BIT);
  g_assert_true(
      fl_compositor_present_layers(FL_COMPOSITOR(compositor), layers, 1));
  if (!fl_framebuffer_get_shareable(compositor->framebuffer)) {
    g_test_skip("Requires EGL image sharing");
    return;
  }
  glBindFramebuffer(GL_FRAMEBUFFER,
                    fl_framebuffer_get_id(compositor->framebuffer));
  GLint attachment = -1;
  glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                                        GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE,
                                        &attachment);
  g_assert_cmpint(attachment, ==, GL_NONE);
  g_autoptr(GtkWindow) window = GTK_WINDOW(g_object_ref_sink(gtk_window_new()));
  gtk_widget_realize(GTK_WIDGET(window));
  GdkSurface* surface = gtk_native_get_surface(GTK_NATIVE(window));
  g_autoptr(GError) error = nullptr;
  g_autoptr(GdkGLContext) context =
      gdk_surface_create_gl_context(surface, &error);
  g_assert_no_error(error);
  gdk_gl_context_make_current(context);
  g_autoptr(GdkTexture) retained = fl_compositor_acquire_texture(
      FL_COMPOSITOR(compositor), surface, context, 4, 4, FALSE);
  g_assert_nonnull(retained);
  g_assert_true(compositor->framebuffer_published);
  gdk_gl_context_clear_current();
  g_assert_true(fl_opengl_manager_make_current(manager));
  glBindFramebuffer(GL_FRAMEBUFFER, fl_framebuffer_get_id(source));
  glClearColor(0, 1, 0, 1);
  glClear(GL_COLOR_BUFFER_BIT);
  g_assert_true(
      fl_compositor_present_layers(FL_COMPOSITOR(compositor), layers, 1));
  glBindFramebuffer(GL_FRAMEBUFFER,
                    fl_framebuffer_get_id(compositor->framebuffer));
  uint8_t pixel[4];
  glReadPixels(0, 0, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, pixel);
  g_assert_cmpuint(pixel[1], ==, 255);
  // gdk_texture_download returns native-endian premultiplied ARGB pixels.
  uint32_t pixels[16];
  gdk_texture_download(retained, reinterpret_cast<guchar*>(pixels),
                       4 * sizeof(uint32_t));
  g_assert_cmphex(pixels[0], ==, 0xffff0000);
  g_clear_object(&retained);
  gtk_window_destroy(window);
  g_assert_true(fl_opengl_manager_make_current(manager));
}

int main(int argc, char** argv) {
  g_test_init(&argc, &argv, nullptr);
  gtk_init();
  g_test_add_func("/compositor/retained-texture", test_retained_texture);
  g_test_add_func("/compositor/offset-layer", test_offset_layer);
  g_test_add_func("/compositor/subsurface/resize", test_subsurface_resize);
  return g_test_run();
}

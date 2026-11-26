// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_compositor_opengl_private.h"

#include <gdk/wayland/gdkwayland.h>

#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_gl_texture_readback.h"
#include "flutter/shell/platform/linux/fl_gl_texture_vulkan.h"
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
  if (requested) {
    // Realize the render widget to get a frame clock without starting Dart.
    const guint realize = g_signal_lookup("realize", GTK_TYPE_WIDGET);
    g_signal_handlers_block_matched(view->render_area, G_SIGNAL_MATCH_ID,
                                    realize, 0, nullptr, nullptr, nullptr);
    gtk_widget_realize(GTK_WIDGET(view));
    g_signal_handlers_unblock_matched(view->render_area, G_SIGNAL_MATCH_ID,
                                      realize, 0, nullptr, nullptr, nullptr);
  }
  g_assert_cmpint(gtk_widget_get_width(view->render_area), ==, 0);
  fl_view_gtk4_resize_subsurface(view, 0, 0);
  g_assert_null(view->subsurface_egl);
  gtk_widget_allocate(view->render_area, 64, 48, -1, nullptr);
  fl_view_gtk4_resize_subsurface(view, 64, 48);
  g_assert_cmpint(view->subsurface_egl != nullptr, ==, requested);
  if (requested) {
    GdkFrameClock* clock = gtk_widget_get_frame_clock(view->render_area);
    g_assert_nonnull(clock);
    const guint after_paint =
        g_signal_lookup("after-paint", GDK_TYPE_FRAME_CLOCK);
    auto sync_handler = [&]() {
      return g_signal_handler_find(clock,
                                   static_cast<GSignalMatchType>(
                                       G_SIGNAL_MATCH_ID | G_SIGNAL_MATCH_DATA),
                                   after_paint, 0, nullptr, nullptr,
                                   view->subsurface);
    };
    const gulong initial_handler = sync_handler();
    g_assert_cmpuint(initial_handler, !=, 0);
    fl_view_gtk4_resize_subsurface(view, 64, 48);
    g_assert_cmpuint(sync_handler(), ==, initial_handler);
    gtk_widget_allocate(view->render_area, 80, 60, -1, nullptr);
    g_assert_cmpuint(sync_handler(), !=, 0);
    g_assert_cmpuint(sync_handler(), !=, initial_handler);
    gtk_widget_allocate(view->render_area, 64, 48, -1, nullptr);
  }
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

constexpr uint8_t kTexturePixels[] = {255, 0,   0,   255, 0,   255, 0,   255,
                                      0,   0,   255, 255, 255, 255, 255, 255,
                                      0,   255, 255, 255, 255, 255, 0,   255};

struct TestVulkanGlTexture {
  FlTextureGL parent;
  GLuint texture;
  GLuint pack_buffer;
  bool extended_pack;
};
struct TestVulkanGlTextureClass {
  FlTextureGLClass parent;
};
G_DEFINE_TYPE(TestVulkanGlTexture,
              test_vulkan_gl_texture,
              fl_texture_gl_get_type())

static void test_vulkan_gl_texture_class_init(TestVulkanGlTextureClass* klass) {
  FL_TEXTURE_GL_CLASS(klass)->populate =
      [](FlTextureGL* texture, uint32_t* target, uint32_t* name,
         uint32_t* width, uint32_t* height, GError**) -> gboolean {
    auto* self = reinterpret_cast<TestVulkanGlTexture*>(texture);
    g_assert_cmpuint(*width, ==, 7u);
    g_assert_cmpuint(*height, ==, 9u);
    g_assert_true(eglGetCurrentContext() != EGL_NO_CONTEXT);
    glGenTextures(1, &self->texture);
    glBindTexture(GL_TEXTURE_2D, self->texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 3, 2, 0, GL_RGBA, GL_UNSIGNED_BYTE,
                 kTexturePixels);
    glPixelStorei(GL_PACK_ALIGNMENT, 8);
    self->extended_pack = epoxy_gl_version() >= 30;
    if (self->extended_pack) {
      glGenBuffers(1, &self->pack_buffer);
      glBindBuffer(GL_PIXEL_PACK_BUFFER, self->pack_buffer);
      glPixelStorei(GL_PACK_ROW_LENGTH, 32);
      glPixelStorei(GL_PACK_SKIP_ROWS, 2);
      glPixelStorei(GL_PACK_SKIP_PIXELS, 1);
    }
    *target = GL_TEXTURE_2D;
    *name = self->texture;
    *width = 3;
    *height = 2;
    return TRUE;
  };
}
static void test_vulkan_gl_texture_init(TestVulkanGlTexture*) {}

static void test_gl_texture_readback() {
  if (g_strcmp0(g_getenv("FLUTTER_TEST_VULKAN"), "1") != 0) {
    g_test_skip("Set FLUTTER_TEST_VULKAN=1 with a Vulkan ICD to run");
    return;
  }
  // Keep Vulkan and EGL real while forcing the compatibility transfer path.
  g_autofree gchar* previous =
      g_strdup(g_getenv("FLUTTER_GTK4_VULKAN_GL_TEXTURES"));
  g_setenv("FLUTTER_GTK4_VULKAN_GL_TEXTURES", "0", TRUE);
  g_autoptr(FlVulkanManager) staging_manager = fl_vulkan_manager_new();
  FlutterVulkanRendererConfig staging_config = {};
  g_autoptr(GError) error = nullptr;
  const bool initialized =
      fl_vulkan_manager_initialize(staging_manager, &staging_config, &error);
  if (previous != nullptr) {
    g_setenv("FLUTTER_GTK4_VULKAN_GL_TEXTURES", previous, TRUE);
  } else {
    g_unsetenv("FLUTTER_GTK4_VULKAN_GL_TEXTURES");
  }
  g_assert_no_error(error);
  g_assert_true(initialized);
  g_assert_false(fl_vulkan_manager_supports_gl_images(staging_manager));

  g_autoptr(FlOpenGLManager) gl = fl_opengl_manager_new();
  g_assert_null(fl_gl_texture_check_context(gl));
  g_autoptr(FlTextureGL) texture =
      FL_TEXTURE_GL(g_object_new(test_vulkan_gl_texture_get_type(), nullptr));
  auto* source = reinterpret_cast<TestVulkanGlTexture*>(texture);
  FlutterVulkanExternalTexture external = {};
  g_test_expect_message(
      nullptr, G_LOG_LEVEL_WARNING,
      "*CPU readback for OpenGL plugin texture TestVulkanGlTexture*"
      "linux-gtk-rendering.md#plugin-texture-migration*");
  g_assert_true(fl_gl_texture_populate_vulkan(texture, gl, staging_manager, 7,
                                              9, &external));
  g_test_assert_expected_messages();
  g_assert_cmpuint(external.width, ==, 3u);
  g_assert_cmpuint(external.height, ==, 2u);
  g_assert_cmpuint(external.format, ==, VK_FORMAT_R8G8B8A8_UNORM);
  g_assert_cmpuint(external.image, !=, 0u);
  g_assert_nonnull(external.destruction_callback);
  external.destruction_callback(external.user_data);
  g_assert_true(fl_opengl_manager_make_current(gl));
  GLint value = 0;
  glGetIntegerv(GL_PACK_ALIGNMENT, &value);
  g_assert_cmpint(value, ==, 8);
  if (source->extended_pack) {
    glGetIntegerv(GL_PIXEL_PACK_BUFFER_BINDING, &value);
    g_assert_cmpuint(value, ==, source->pack_buffer);
    glGetIntegerv(GL_PACK_ROW_LENGTH, &value);
    g_assert_cmpint(value, ==, 32);
    glGetIntegerv(GL_PACK_SKIP_ROWS, &value);
    g_assert_cmpint(value, ==, 2);
    glGetIntegerv(GL_PACK_SKIP_PIXELS, &value);
    g_assert_cmpint(value, ==, 1);
    glDeleteBuffers(1, &source->pack_buffer);
  }
  glDeleteTextures(1, &source->texture);
  fl_opengl_manager_clear_current(gl);
}

static void test_external_egl_texture_readback() {
  g_autoptr(FlOpenGLManager) gl = fl_opengl_manager_new();
  g_assert_true(fl_opengl_manager_make_current(gl));
  const EGLDisplay display = eglGetCurrentDisplay();
  const EGLContext context = eglGetCurrentContext();
  if (!epoxy_has_egl_extension(display, "EGL_KHR_gl_texture_2D_image") ||
      !epoxy_has_gl_extension("GL_OES_EGL_image_external")) {
    fl_opengl_manager_clear_current(gl);
    g_test_skip(
        "Requires EGL image texture import and external texture support");
    return;
  }

  GLuint names[2] = {};
  glGenTextures(2, names);
  glBindTexture(GL_TEXTURE_2D, names[0]);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 3, 2, 0, GL_RGBA, GL_UNSIGNED_BYTE,
               kTexturePixels);
  const EGLint attributes[] = {EGL_IMAGE_PRESERVED_KHR, EGL_TRUE, EGL_NONE};
  EGLImageKHR image = eglCreateImageKHR(
      display, context, EGL_GL_TEXTURE_2D_KHR,
      reinterpret_cast<EGLClientBuffer>(static_cast<uintptr_t>(names[0])),
      attributes);
  g_assert_true(image != EGL_NO_IMAGE_KHR);
  glBindTexture(GL_TEXTURE_EXTERNAL_OES, names[1]);
  glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glEGLImageTargetTexture2DOES(GL_TEXTURE_EXTERNAL_OES, image);
  g_assert_cmpuint(glGetError(), ==, GL_NO_ERROR);

  FlGlTextureReadback reader;
  FlutterOpenGLTexture source = {};
  source.target = GL_TEXTURE_EXTERNAL_OES;
  source.name = names[1];
  source.width = 3;
  source.height = 2;
  uint8_t pixels[sizeof(kTexturePixels)] = {};
  // The first read creates the shared context and the second reuses it.
  for (int read = 0; read < 2; ++read) {
    g_assert_true(reader.Read(source, pixels));
    g_assert_cmpmem(pixels, sizeof(pixels), kTexturePixels,
                    sizeof(kTexturePixels));
    g_assert_true(eglGetCurrentContext() == context);
  }
  glDeleteTextures(2, names);
  eglDestroyImageKHR(display, image);
  fl_opengl_manager_clear_current(gl);
}

int main(int argc, char** argv) {
  g_test_init(&argc, &argv, nullptr);
  gtk_init();
  g_test_add_func("/compositor/retained-texture", test_retained_texture);
  g_test_add_func("/compositor/offset-layer", test_offset_layer);
  g_test_add_func("/compositor/subsurface/resize", test_subsurface_resize);
  g_test_add_func("/gtk4/vulkan/gl-texture-readback", test_gl_texture_readback);
  g_test_add_func("/gtk4/gl/external-egl-texture-readback",
                  test_external_egl_texture_readback);
  return g_test_run();
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <thread>
#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "gtest/gtest.h"

#include "flutter/common/constants.h"
#include "flutter/fml/logging.h"
#include "flutter/shell/platform/linux/fl_compositor_opengl.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_framebuffer.h"
#include "flutter/shell/platform/linux/fl_opengl_manager.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_dart_project.h"
#include "flutter/shell/platform/linux/testing/mock_epoxy.h"
#include "flutter/shell/platform/linux/testing/mock_gtk.h"
#include "flutter/shell/platform/linux/testing/mock_renderable.h"

#include <epoxy/egl.h>

class FlCompositorOpenGLTest : public flutter::testing::LinuxTest {
 protected:
  void SetUp() override {
    opengl_manager = fl_opengl_manager_new();
    renderable = fl_mock_renderable_new();
    compositor = fl_compositor_opengl_new(
        opengl_manager, FL_COMPOSITOR_OPENGL_FRAME_SHARING_CPU_COPY);
    fl_engine_set_implicit_view(engine, FL_RENDERABLE(renderable));
  }

  ~FlCompositorOpenGLTest() {
    g_clear_object(&compositor);
    g_clear_object(&renderable);
    g_clear_object(&opengl_manager);
  }

  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  FlOpenGLManager* opengl_manager = nullptr;
  FlMockRenderable* renderable = nullptr;
  FlCompositorOpenGL* compositor = nullptr;
};

TEST_F(FlCompositorOpenGLTest, Render) {
  // Present layer from a thread.
  constexpr size_t width = 100;
  constexpr size_t height = 100;
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
  std::thread([&]() {
    fl_compositor_opengl_present_layers(compositor, layers, 1);
  }).join();

  size_t frame_width, frame_height;
  fl_compositor_opengl_get_frame_size(compositor, &frame_width, &frame_height);
  EXPECT_EQ(frame_width, width);
  EXPECT_EQ(frame_height, height);

  // Render presented layer.
  int stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);
  g_autofree unsigned char* image_data =
      static_cast<unsigned char*>(malloc(height * stride));
  cairo_surface_t* surface = cairo_image_surface_create_for_data(
      image_data, CAIRO_FORMAT_ARGB32, width, height, stride);
  cairo_t* cr = cairo_create(surface);
  fl_compositor_opengl_render(compositor, cr, nullptr);
  cairo_surface_destroy(surface);
  cairo_destroy(cr);
}

TEST_F(FlCompositorOpenGLTest, Resize) {
  // Present a layer that is the old size.
  constexpr size_t width1 = 90;
  constexpr size_t height1 = 90;
  g_autoptr(FlFramebuffer) framebuffer1 =
      fl_framebuffer_new(GL_RGB, width1, height1, FALSE);
  FlutterBackingStore backing_store1 = {
      .type = kFlutterBackingStoreTypeOpenGL,
      .open_gl = {.framebuffer = {.user_data = framebuffer1}}};
  FlutterLayer layer1 = {.type = kFlutterLayerContentTypeBackingStore,
                         .backing_store = &backing_store1,
                         .offset = {0, 0},
                         .size = {width1, height1}};
  const FlutterLayer* layers1[1] = {&layer1};
  fl_compositor_opengl_present_layers(compositor, layers1, 1);

  // Present layer in current size.
  constexpr size_t width2 = 100;
  constexpr size_t height2 = 100;
  g_autoptr(FlFramebuffer) framebuffer2 =
      fl_framebuffer_new(GL_RGB, width2, height2, FALSE);
  FlutterBackingStore backing_store2 = {
      .type = kFlutterBackingStoreTypeOpenGL,
      .open_gl = {.framebuffer = {.user_data = framebuffer2}}};
  FlutterLayer layer2 = {.type = kFlutterLayerContentTypeBackingStore,
                         .backing_store = &backing_store2,
                         .offset = {0, 0},
                         .size = {width2, height2}};
  const FlutterLayer* layers2[1] = {&layer2};
  fl_compositor_opengl_present_layers(compositor, layers2, 1);

  // The stored frame is now the new size.
  size_t frame_width, frame_height;
  fl_compositor_opengl_get_frame_size(compositor, &frame_width, &frame_height);
  EXPECT_EQ(frame_width, width2);
  EXPECT_EQ(frame_height, height2);

  // Render the presented layer.
  int stride2 = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width2);
  g_autofree unsigned char* image_data =
      static_cast<unsigned char*>(malloc(height2 * stride2));
  cairo_surface_t* surface = cairo_image_surface_create_for_data(
      image_data, CAIRO_FORMAT_ARGB32, width2, height2, stride2);
  cairo_t* cr = cairo_create(surface);
  fl_compositor_opengl_render(compositor, cr, nullptr);
  cairo_surface_destroy(surface);
  cairo_destroy(cr);
}

TEST_F(FlCompositorOpenGLTest, RestoresGLState) {
  constexpr size_t width = 100;
  constexpr size_t height = 100;

  // OpenGL 3.0
  ON_CALL(epoxy, glGetString(GL_VENDOR))
      .WillByDefault(
          ::testing::Return(reinterpret_cast<const GLubyte*>("Intel")));
  ON_CALL(epoxy, epoxy_is_desktop_gl).WillByDefault(::testing::Return(true));
  ON_CALL(epoxy, epoxy_gl_version).WillByDefault(::testing::Return(30));

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

  constexpr GLuint kFakeTextureName = 123;
  glBindTexture(GL_TEXTURE_2D, kFakeTextureName);
  glDisable(GL_BLEND);
  glEnable(GL_SCISSOR_TEST);

  // Present layer and render.
  std::thread([&]() {
    fl_compositor_opengl_present_layers(compositor, layers, 1);
  }).join();
  int stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);
  g_autofree unsigned char* image_data =
      static_cast<unsigned char*>(malloc(height * stride));
  cairo_surface_t* surface = cairo_image_surface_create_for_data(
      image_data, CAIRO_FORMAT_ARGB32, width, height, stride);
  cairo_t* cr = cairo_create(surface);
  fl_compositor_opengl_render(compositor, cr, nullptr);
  cairo_surface_destroy(surface);
  cairo_destroy(cr);

  GLuint texture_2d_binding;
  glGetIntegerv(GL_TEXTURE_BINDING_2D,
                reinterpret_cast<GLint*>(&texture_2d_binding));
  EXPECT_EQ(texture_2d_binding, kFakeTextureName);
  EXPECT_EQ(glIsEnabled(GL_BLEND), GL_FALSE);
  EXPECT_EQ(glIsEnabled(GL_SCISSOR_TEST), GL_TRUE);
}

TEST_F(FlCompositorOpenGLTest, BlitFramebuffer) {
  constexpr size_t width = 100;
  constexpr size_t height = 100;

  // OpenGL 3.0
  ON_CALL(epoxy, glGetString(GL_VENDOR))
      .WillByDefault(
          ::testing::Return(reinterpret_cast<const GLubyte*>("Intel")));
  ON_CALL(epoxy, epoxy_is_desktop_gl).WillByDefault(::testing::Return(true));
  EXPECT_CALL(epoxy, epoxy_gl_version).WillRepeatedly(::testing::Return(30));

  EXPECT_CALL(epoxy, glBlitFramebuffer);

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

  // Present layer and render.
  std::thread([&]() {
    fl_compositor_opengl_present_layers(compositor, layers, 1);
  }).join();
  int stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);
  g_autofree unsigned char* image_data =
      static_cast<unsigned char*>(malloc(height * stride));
  cairo_surface_t* surface = cairo_image_surface_create_for_data(
      image_data, CAIRO_FORMAT_ARGB32, width, height, stride);
  cairo_t* cr = cairo_create(surface);
  fl_compositor_opengl_render(compositor, cr, nullptr);
  cairo_surface_destroy(surface);
  cairo_destroy(cr);
}

TEST_F(FlCompositorOpenGLTest, BlitFramebufferExtension) {
  constexpr size_t width = 100;
  constexpr size_t height = 100;

  // OpenGL 2.0 with GL_EXT_framebuffer_blit extension
  ON_CALL(epoxy, glGetString(GL_VENDOR))
      .WillByDefault(
          ::testing::Return(reinterpret_cast<const GLubyte*>("Intel")));
  ON_CALL(epoxy, epoxy_is_desktop_gl).WillByDefault(::testing::Return(true));
  EXPECT_CALL(epoxy, epoxy_gl_version).WillRepeatedly(::testing::Return(20));
  EXPECT_CALL(epoxy, epoxy_has_gl_extension(::testing::_))
      .WillRepeatedly(::testing::Return(false));
  EXPECT_CALL(epoxy, epoxy_has_gl_extension(
                         ::testing::StrEq("GL_EXT_framebuffer_blit")))
      .WillRepeatedly(::testing::Return(true));

  EXPECT_CALL(epoxy, glBlitFramebuffer);

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

  // Present layer and render.
  std::thread([&]() {
    fl_compositor_opengl_present_layers(compositor, layers, 1);
  }).join();
  int stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);
  g_autofree unsigned char* image_data =
      static_cast<unsigned char*>(malloc(height * stride));
  cairo_surface_t* surface = cairo_image_surface_create_for_data(
      image_data, CAIRO_FORMAT_ARGB32, width, height, stride);
  cairo_t* cr = cairo_create(surface);
  fl_compositor_opengl_render(compositor, cr, nullptr);
  cairo_surface_destroy(surface);
  cairo_destroy(cr);
}

TEST_F(FlCompositorOpenGLTest, NoBlitFramebuffer) {
  constexpr size_t width = 100;
  constexpr size_t height = 100;

  // OpenGL 2.0
  ON_CALL(epoxy, glGetString(GL_VENDOR))
      .WillByDefault(
          ::testing::Return(reinterpret_cast<const GLubyte*>("Intel")));
  ON_CALL(epoxy, epoxy_is_desktop_gl).WillByDefault(::testing::Return(true));
  EXPECT_CALL(epoxy, epoxy_gl_version).WillRepeatedly(::testing::Return(20));

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

  // Present layer and render.
  std::thread([&]() {
    fl_compositor_opengl_present_layers(compositor, layers, 1);
  }).join();
  int stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);
  g_autofree unsigned char* image_data =
      static_cast<unsigned char*>(malloc(height * stride));
  cairo_surface_t* surface = cairo_image_surface_create_for_data(
      image_data, CAIRO_FORMAT_ARGB32, width, height, stride);
  cairo_t* cr = cairo_create(surface);
  fl_compositor_opengl_render(compositor, cr, nullptr);
  cairo_surface_destroy(surface);
  cairo_destroy(cr);
}

TEST_F(FlCompositorOpenGLTest, BlitFramebufferNvidia) {
  constexpr size_t width = 100;
  constexpr size_t height = 100;

  // OpenGL 3.0, but on NVIDIA driver so temporarily disabled due to
  // https://github.com/flutter/flutter/issues/152099
  ON_CALL(epoxy, glGetString(GL_VENDOR))
      .WillByDefault(
          ::testing::Return(reinterpret_cast<const GLubyte*>("NVIDIA")));
  ON_CALL(epoxy, epoxy_is_desktop_gl).WillByDefault(::testing::Return(true));
  EXPECT_CALL(epoxy, epoxy_gl_version).WillRepeatedly(::testing::Return(30));

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

  // Present layer and render.
  std::thread([&]() {
    fl_compositor_opengl_present_layers(compositor, layers, 1);
  }).join();
  int stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);
  g_autofree unsigned char* image_data =
      static_cast<unsigned char*>(malloc(height * stride));
  cairo_surface_t* surface = cairo_image_surface_create_for_data(
      image_data, CAIRO_FORMAT_ARGB32, width, height, stride);
  cairo_t* cr = cairo_create(surface);
  fl_compositor_opengl_render(compositor, cr, nullptr);
  cairo_surface_destroy(surface);
  cairo_destroy(cr);
}

TEST_F(FlCompositorOpenGLTest, RenderResizeCrash) {
  // Present layer of size 100x100.
  constexpr size_t width = 100;
  constexpr size_t height = 100;
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
  std::thread([&]() {
    fl_compositor_opengl_present_layers(compositor, layers, 1);
  }).join();

  // Mock window size to be larger (200x200).
  flutter::testing::MockGtk mock_gtk;
  EXPECT_CALL(mock_gtk, gdk_window_get_width(::testing::_))
      .WillRepeatedly(::testing::Return(200));
  EXPECT_CALL(mock_gtk, gdk_window_get_height(::testing::_))
      .WillRepeatedly(::testing::Return(200));

  // Render into the larger window.
  // This renders the 100x100 frame into the 200x200 window without waiting.
  // If bug is present, it will try to read 200x200 from 100x100 buffer.
  int stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, 200);
  g_autofree unsigned char* image_data =
      static_cast<unsigned char*>(g_malloc(200 * stride));
  cairo_surface_t* surface = cairo_image_surface_create_for_data(
      image_data, CAIRO_FORMAT_ARGB32, 200, 200, stride);
  cairo_t* cr = cairo_create(surface);

  // We expect this to not crash.
  fl_compositor_opengl_render(compositor, cr, nullptr);

  cairo_surface_destroy(surface);
  cairo_destroy(cr);
}

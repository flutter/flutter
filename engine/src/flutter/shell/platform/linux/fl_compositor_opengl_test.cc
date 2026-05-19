// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <thread>
#include "gtest/gtest.h"

#include "flutter/common/constants.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/shell/platform/linux/fl_compositor_opengl.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_framebuffer.h"
#include "flutter/shell/platform/linux/fl_opengl_manager.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_dart_project.h"
#include "flutter/shell/platform/linux/testing/mock_epoxy.h"
#include "flutter/shell/platform/linux/testing/mock_renderable.h"

#include <epoxy/egl.h>

TEST(FlCompositorOpenGLTest, Render) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlEngine) engine = fl_engine_new(project);
  g_autoptr(FlTaskRunner) task_runner = fl_task_runner_new(engine);
  g_autoptr(FlOpenGLManager) opengl_manager = fl_opengl_manager_new();

  g_autoptr(FlMockRenderable) renderable = fl_mock_renderable_new();
  g_autoptr(FlCompositorOpenGL) compositor =
      fl_compositor_opengl_new(task_runner, opengl_manager, FALSE);
  fl_engine_set_implicit_view(engine, FL_RENDERABLE(renderable));

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
    fl_compositor_present_layers(FL_COMPOSITOR(compositor), layers, 1);
  }).join();

  // Render presented layer.
  int stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);
  g_autofree unsigned char* image_data =
      static_cast<unsigned char*>(malloc(height * stride));
  cairo_surface_t* surface = cairo_image_surface_create_for_data(
      image_data, CAIRO_FORMAT_ARGB32, width, height, stride);
  cairo_t* cr = cairo_create(surface);
  fl_compositor_render(FL_COMPOSITOR(compositor), cr, nullptr);
  cairo_surface_destroy(surface);
  cairo_destroy(cr);
}

TEST(FlCompositorOpenGLTest, Resize) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlEngine) engine = fl_engine_new(project);
  g_autoptr(FlTaskRunner) task_runner = fl_task_runner_new(engine);
  g_autoptr(FlOpenGLManager) opengl_manager = fl_opengl_manager_new();

  g_autoptr(FlMockRenderable) renderable = fl_mock_renderable_new();
  g_autoptr(FlCompositorOpenGL) compositor =
      fl_compositor_opengl_new(task_runner, opengl_manager, FALSE);
  fl_engine_set_implicit_view(engine, FL_RENDERABLE(renderable));

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
  std::thread([&]() {
    fl_compositor_present_layers(FL_COMPOSITOR(compositor), layers1, 1);
  }).join();

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
  fml::AutoResetWaitableEvent latch;
  std::thread([&]() {
    fl_compositor_present_layers(FL_COMPOSITOR(compositor), layers2, 1);
    latch.Signal();
  }).detach();

  // Render, will wait for the second layer if necessary.
  int stride2 = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width2);
  g_autofree unsigned char* image_data =
      static_cast<unsigned char*>(malloc(height2 * stride2));
  cairo_surface_t* surface = cairo_image_surface_create_for_data(
      image_data, CAIRO_FORMAT_ARGB32, width2, height2, stride2);
  cairo_t* cr = cairo_create(surface);
  fl_compositor_render(FL_COMPOSITOR(compositor), cr, nullptr);
  cairo_surface_destroy(surface);
  cairo_destroy(cr);

  latch.Wait();
}

TEST(FlCompositorOpenGLTest, RestoresGLState) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlEngine) engine = fl_engine_new(project);
  g_autoptr(FlTaskRunner) task_runner = fl_task_runner_new(engine);
  g_autoptr(FlOpenGLManager) opengl_manager = fl_opengl_manager_new();

  constexpr size_t width = 100;
  constexpr size_t height = 100;

  // OpenGL 3.0
  ON_CALL(epoxy, glGetString(GL_VENDOR))
      .WillByDefault(
          ::testing::Return(reinterpret_cast<const GLubyte*>("Intel")));
  ON_CALL(epoxy, epoxy_is_desktop_gl).WillByDefault(::testing::Return(true));
  ON_CALL(epoxy, epoxy_gl_version).WillByDefault(::testing::Return(30));

  g_autoptr(FlMockRenderable) renderable = fl_mock_renderable_new();
  g_autoptr(FlCompositorOpenGL) compositor =
      fl_compositor_opengl_new(task_runner, opengl_manager, FALSE);
  fl_engine_set_implicit_view(engine, FL_RENDERABLE(renderable));

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
    fl_compositor_present_layers(FL_COMPOSITOR(compositor), layers, 1);
  }).join();
  int stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);
  g_autofree unsigned char* image_data =
      static_cast<unsigned char*>(malloc(height * stride));
  cairo_surface_t* surface = cairo_image_surface_create_for_data(
      image_data, CAIRO_FORMAT_ARGB32, width, height, stride);
  cairo_t* cr = cairo_create(surface);
  fl_compositor_render(FL_COMPOSITOR(compositor), cr, nullptr);
  cairo_surface_destroy(surface);
  cairo_destroy(cr);

  GLuint texture_2d_binding;
  glGetIntegerv(GL_TEXTURE_BINDING_2D,
                reinterpret_cast<GLint*>(&texture_2d_binding));
  EXPECT_EQ(texture_2d_binding, kFakeTextureName);
  EXPECT_EQ(glIsEnabled(GL_BLEND), GL_FALSE);
  EXPECT_EQ(glIsEnabled(GL_SCISSOR_TEST), GL_TRUE);
}

TEST(FlCompositorOpenGLTest, BlitFramebuffer) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlEngine) engine = fl_engine_new(project);
  g_autoptr(FlTaskRunner) task_runner = fl_task_runner_new(engine);
  g_autoptr(FlOpenGLManager) opengl_manager = fl_opengl_manager_new();

  constexpr size_t width = 100;
  constexpr size_t height = 100;

  // OpenGL 3.0
  ON_CALL(epoxy, glGetString(GL_VENDOR))
      .WillByDefault(
          ::testing::Return(reinterpret_cast<const GLubyte*>("Intel")));
  ON_CALL(epoxy, epoxy_is_desktop_gl).WillByDefault(::testing::Return(true));
  EXPECT_CALL(epoxy, epoxy_gl_version).WillRepeatedly(::testing::Return(30));

  EXPECT_CALL(epoxy, glBlitFramebuffer);

  g_autoptr(FlMockRenderable) renderable = fl_mock_renderable_new();
  g_autoptr(FlCompositorOpenGL) compositor =
      fl_compositor_opengl_new(task_runner, opengl_manager, FALSE);
  fl_engine_set_implicit_view(engine, FL_RENDERABLE(renderable));

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
    fl_compositor_present_layers(FL_COMPOSITOR(compositor), layers, 1);
  }).join();
  int stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);
  g_autofree unsigned char* image_data =
      static_cast<unsigned char*>(malloc(height * stride));
  cairo_surface_t* surface = cairo_image_surface_create_for_data(
      image_data, CAIRO_FORMAT_ARGB32, width, height, stride);
  cairo_t* cr = cairo_create(surface);
  fl_compositor_render(FL_COMPOSITOR(compositor), cr, nullptr);
  cairo_surface_destroy(surface);
  cairo_destroy(cr);
}

TEST(FlCompositorOpenGLTest, BlitFramebufferExtension) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlEngine) engine = fl_engine_new(project);
  g_autoptr(FlTaskRunner) task_runner = fl_task_runner_new(engine);
  g_autoptr(FlOpenGLManager) opengl_manager = fl_opengl_manager_new();

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

  g_autoptr(FlMockRenderable) renderable = fl_mock_renderable_new();
  g_autoptr(FlCompositorOpenGL) compositor =
      fl_compositor_opengl_new(task_runner, opengl_manager, FALSE);
  fl_engine_set_implicit_view(engine, FL_RENDERABLE(renderable));

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
    fl_compositor_present_layers(FL_COMPOSITOR(compositor), layers, 1);
  }).join();
  int stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);
  g_autofree unsigned char* image_data =
      static_cast<unsigned char*>(malloc(height * stride));
  cairo_surface_t* surface = cairo_image_surface_create_for_data(
      image_data, CAIRO_FORMAT_ARGB32, width, height, stride);
  cairo_t* cr = cairo_create(surface);
  fl_compositor_render(FL_COMPOSITOR(compositor), cr, nullptr);
  cairo_surface_destroy(surface);
  cairo_destroy(cr);
}

TEST(FlCompositorOpenGLTest, NoBlitFramebuffer) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlEngine) engine = fl_engine_new(project);
  g_autoptr(FlTaskRunner) task_runner = fl_task_runner_new(engine);
  g_autoptr(FlOpenGLManager) opengl_manager = fl_opengl_manager_new();

  constexpr size_t width = 100;
  constexpr size_t height = 100;

  // OpenGL 2.0
  ON_CALL(epoxy, glGetString(GL_VENDOR))
      .WillByDefault(
          ::testing::Return(reinterpret_cast<const GLubyte*>("Intel")));
  ON_CALL(epoxy, epoxy_is_desktop_gl).WillByDefault(::testing::Return(true));
  EXPECT_CALL(epoxy, epoxy_gl_version).WillRepeatedly(::testing::Return(20));

  g_autoptr(FlMockRenderable) renderable = fl_mock_renderable_new();
  g_autoptr(FlCompositorOpenGL) compositor =
      fl_compositor_opengl_new(task_runner, opengl_manager, FALSE);
  fl_engine_set_implicit_view(engine, FL_RENDERABLE(renderable));

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
    fl_compositor_present_layers(FL_COMPOSITOR(compositor), layers, 1);
  }).join();
  int stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);
  g_autofree unsigned char* image_data =
      static_cast<unsigned char*>(malloc(height * stride));
  cairo_surface_t* surface = cairo_image_surface_create_for_data(
      image_data, CAIRO_FORMAT_ARGB32, width, height, stride);
  cairo_t* cr = cairo_create(surface);
  fl_compositor_render(FL_COMPOSITOR(compositor), cr, nullptr);
  cairo_surface_destroy(surface);
  cairo_destroy(cr);
}

TEST(FlCompositorOpenGLTest, BlitFramebufferNvidia) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlEngine) engine = fl_engine_new(project);
  g_autoptr(FlTaskRunner) task_runner = fl_task_runner_new(engine);
  g_autoptr(FlOpenGLManager) opengl_manager = fl_opengl_manager_new();

  constexpr size_t width = 100;
  constexpr size_t height = 100;

  // OpenGL 3.0, but on NVIDIA driver so temporarily disabled due to
  // https://github.com/flutter/flutter/issues/152099
  ON_CALL(epoxy, glGetString(GL_VENDOR))
      .WillByDefault(
          ::testing::Return(reinterpret_cast<const GLubyte*>("NVIDIA")));
  ON_CALL(epoxy, epoxy_is_desktop_gl).WillByDefault(::testing::Return(true));
  EXPECT_CALL(epoxy, epoxy_gl_version).WillRepeatedly(::testing::Return(30));

  g_autoptr(FlMockRenderable) renderable = fl_mock_renderable_new();
  g_autoptr(FlCompositorOpenGL) compositor =
      fl_compositor_opengl_new(task_runner, opengl_manager, FALSE);
  fl_engine_set_implicit_view(engine, FL_RENDERABLE(renderable));

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
    fl_compositor_present_layers(FL_COMPOSITOR(compositor), layers, 1);
  }).join();
  int stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);
  g_autofree unsigned char* image_data =
      static_cast<unsigned char*>(malloc(height * stride));
  cairo_surface_t* surface = cairo_image_surface_create_for_data(
      image_data, CAIRO_FORMAT_ARGB32, width, height, stride);
  cairo_t* cr = cairo_create(surface);
  fl_compositor_render(FL_COMPOSITOR(compositor), cr, nullptr);
  cairo_surface_destroy(surface);
  cairo_destroy(cr);
}

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
#include "flutter/shell/platform/linux/public/flutter_linux/fl_dart_project.h"
#include "flutter/shell/platform/linux/testing/mock_epoxy.h"
#include "flutter/shell/platform/linux/testing/mock_renderable.h"

#include <epoxy/egl.h>

TEST(FlCompositorOpenGLTest, RestoresGLState) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlEngine) engine = fl_engine_new(project);

  constexpr int kWidth = 100;
  constexpr int kHeight = 100;

  // OpenGL 3.0
  ON_CALL(epoxy, glGetString(GL_VENDOR))
      .WillByDefault(
          ::testing::Return(reinterpret_cast<const GLubyte*>("Intel")));
  ON_CALL(epoxy, epoxy_is_desktop_gl).WillByDefault(::testing::Return(true));
  ON_CALL(epoxy, epoxy_gl_version).WillByDefault(::testing::Return(30));

  g_autoptr(FlMockRenderable) renderable = fl_mock_renderable_new();
  g_autoptr(FlCompositorOpenGL) compositor =
      fl_compositor_opengl_new(engine, nullptr);
  fl_engine_set_implicit_view(engine, FL_RENDERABLE(renderable));
  fl_compositor_wait_for_frame(FL_COMPOSITOR(compositor), kWidth, kHeight);

  fml::AutoResetWaitableEvent latch;

  g_autoptr(FlFramebuffer) framebuffer =
      fl_framebuffer_new(GL_RGB, kWidth, kHeight);
  FlutterBackingStore backing_store = {
      .type = kFlutterBackingStoreTypeOpenGL,
      .open_gl = {.framebuffer = {.user_data = framebuffer}}};
  FlutterLayer layer = {.type = kFlutterLayerContentTypeBackingStore,
                        .backing_store = &backing_store,
                        .offset = {0, 0},
                        .size = {kWidth, kHeight}};
  const FlutterLayer* layers[1] = {&layer};

  constexpr GLuint kFakeTextureName = 123;
  glBindTexture(GL_TEXTURE_2D, kFakeTextureName);

  // Simulate raster thread.
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);
  std::thread([&]() {
    fl_compositor_present_layers(FL_COMPOSITOR(compositor), layers, 1);
    g_main_loop_quit(loop);
    latch.Signal();
  }).detach();

  g_main_loop_run(loop);

  fl_compositor_opengl_render(compositor, kWidth, kHeight);

  GLuint texture_2d_binding;
  glGetIntegerv(GL_TEXTURE_BINDING_2D,
                reinterpret_cast<GLint*>(&texture_2d_binding));
  EXPECT_EQ(texture_2d_binding, kFakeTextureName);

  // Wait until the raster thread has finished before letting
  // the engine go out of scope.
  latch.Wait();
}

TEST(FlCompositorOpenGLTest, BlitFramebuffer) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlEngine) engine = fl_engine_new(project);

  constexpr int kWidth = 100;
  constexpr int kHeight = 100;

  // OpenGL 3.0
  ON_CALL(epoxy, glGetString(GL_VENDOR))
      .WillByDefault(
          ::testing::Return(reinterpret_cast<const GLubyte*>("Intel")));
  ON_CALL(epoxy, epoxy_is_desktop_gl).WillByDefault(::testing::Return(true));
  EXPECT_CALL(epoxy, epoxy_gl_version).WillRepeatedly(::testing::Return(30));

  EXPECT_CALL(epoxy, glBlitFramebuffer);

  g_autoptr(FlMockRenderable) renderable = fl_mock_renderable_new();
  g_autoptr(FlCompositorOpenGL) compositor =
      fl_compositor_opengl_new(engine, nullptr);
  fl_engine_set_implicit_view(engine, FL_RENDERABLE(renderable));
  fl_compositor_wait_for_frame(FL_COMPOSITOR(compositor), kWidth, kHeight);

  fml::AutoResetWaitableEvent latch;

  g_autoptr(FlFramebuffer) framebuffer =
      fl_framebuffer_new(GL_RGB, kWidth, kHeight);
  FlutterBackingStore backing_store = {
      .type = kFlutterBackingStoreTypeOpenGL,
      .open_gl = {.framebuffer = {.user_data = framebuffer}}};
  FlutterLayer layer = {.type = kFlutterLayerContentTypeBackingStore,
                        .backing_store = &backing_store,
                        .offset = {0, 0},
                        .size = {kWidth, kHeight}};
  const FlutterLayer* layers[1] = {&layer};

  // Simulate raster thread.
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);
  std::thread([&]() {
    fl_compositor_present_layers(FL_COMPOSITOR(compositor), layers, 1);
    g_main_loop_quit(loop);
    latch.Signal();
  }).detach();

  g_main_loop_run(loop);

  fl_compositor_opengl_render(compositor, kWidth, kHeight);

  latch.Wait();
}

TEST(FlCompositorOpenGLTest, BlitFramebufferExtension) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlEngine) engine = fl_engine_new(project);

  constexpr int kWidth = 100;
  constexpr int kHeight = 100;

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
      fl_compositor_opengl_new(engine, nullptr);
  fl_engine_set_implicit_view(engine, FL_RENDERABLE(renderable));
  fl_compositor_wait_for_frame(FL_COMPOSITOR(compositor), kWidth, kHeight);

  fml::AutoResetWaitableEvent latch;

  g_autoptr(FlFramebuffer) framebuffer =
      fl_framebuffer_new(GL_RGB, kWidth, kHeight);
  FlutterBackingStore backing_store = {
      .type = kFlutterBackingStoreTypeOpenGL,
      .open_gl = {.framebuffer = {.user_data = framebuffer}}};
  FlutterLayer layer = {.type = kFlutterLayerContentTypeBackingStore,
                        .backing_store = &backing_store,
                        .offset = {0, 0},
                        .size = {kWidth, kHeight}};
  const FlutterLayer* layers[1] = {&layer};

  // Simulate raster thread.
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);
  std::thread([&]() {
    fl_compositor_present_layers(FL_COMPOSITOR(compositor), layers, 1);
    g_main_loop_quit(loop);
    latch.Signal();
  }).detach();

  g_main_loop_run(loop);

  fl_compositor_opengl_render(compositor, kWidth, kHeight);
  // Wait until the raster thread has finished before letting
  // the engine go out of scope.
  latch.Wait();
}

TEST(FlCompositorOpenGLTest, NoBlitFramebuffer) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlEngine) engine = fl_engine_new(project);

  constexpr int kWidth = 100;
  constexpr int kHeight = 100;

  // OpenGL 2.0
  ON_CALL(epoxy, glGetString(GL_VENDOR))
      .WillByDefault(
          ::testing::Return(reinterpret_cast<const GLubyte*>("Intel")));
  ON_CALL(epoxy, epoxy_is_desktop_gl).WillByDefault(::testing::Return(true));
  EXPECT_CALL(epoxy, epoxy_gl_version).WillRepeatedly(::testing::Return(20));

  g_autoptr(FlMockRenderable) renderable = fl_mock_renderable_new();
  g_autoptr(FlCompositorOpenGL) compositor =
      fl_compositor_opengl_new(engine, nullptr);
  fl_engine_set_implicit_view(engine, FL_RENDERABLE(renderable));
  fl_compositor_wait_for_frame(FL_COMPOSITOR(compositor), kWidth, kHeight);

  fml::AutoResetWaitableEvent latch;

  g_autoptr(FlFramebuffer) framebuffer =
      fl_framebuffer_new(GL_RGB, kWidth, kHeight);
  FlutterBackingStore backing_store = {
      .type = kFlutterBackingStoreTypeOpenGL,
      .open_gl = {.framebuffer = {.user_data = framebuffer}}};
  FlutterLayer layer = {.type = kFlutterLayerContentTypeBackingStore,
                        .backing_store = &backing_store,
                        .offset = {0, 0},
                        .size = {kWidth, kHeight}};
  const FlutterLayer* layers[1] = {&layer};

  // Simulate raster thread.
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);
  std::thread([&]() {
    fl_compositor_present_layers(FL_COMPOSITOR(compositor), layers, 1);
    g_main_loop_quit(loop);
    latch.Signal();
  }).detach();

  g_main_loop_run(loop);

  fl_compositor_opengl_render(compositor, kWidth, kHeight);

  // Wait until the raster thread has finished before letting
  // the engine go out of scope.
  latch.Wait();
}

TEST(FlCompositorOpenGLTest, BlitFramebufferNvidia) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlEngine) engine = fl_engine_new(project);

  constexpr int kWidth = 100;
  constexpr int kHeight = 100;

  // OpenGL 3.0, but on NVIDIA driver so temporarily disabled due to
  // https://github.com/flutter/flutter/issues/152099
  ON_CALL(epoxy, glGetString(GL_VENDOR))
      .WillByDefault(
          ::testing::Return(reinterpret_cast<const GLubyte*>("NVIDIA")));
  ON_CALL(epoxy, epoxy_is_desktop_gl).WillByDefault(::testing::Return(true));
  EXPECT_CALL(epoxy, epoxy_gl_version).WillRepeatedly(::testing::Return(30));

  g_autoptr(FlMockRenderable) renderable = fl_mock_renderable_new();
  g_autoptr(FlCompositorOpenGL) compositor =
      fl_compositor_opengl_new(engine, nullptr);
  fl_engine_set_implicit_view(engine, FL_RENDERABLE(renderable));
  fl_compositor_wait_for_frame(FL_COMPOSITOR(compositor), kWidth, kHeight);

  fml::AutoResetWaitableEvent latch;

  g_autoptr(FlFramebuffer) framebuffer =
      fl_framebuffer_new(GL_RGB, kWidth, kHeight);
  FlutterBackingStore backing_store = {
      .type = kFlutterBackingStoreTypeOpenGL,
      .open_gl = {.framebuffer = {.user_data = framebuffer}}};
  FlutterLayer layer = {.type = kFlutterLayerContentTypeBackingStore,
                        .backing_store = &backing_store,
                        .offset = {0, 0},
                        .size = {kWidth, kHeight}};
  const FlutterLayer* layers[1] = {&layer};

  // Simulate raster thread.
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);
  std::thread([&]() {
    fl_compositor_present_layers(FL_COMPOSITOR(compositor), layers, 1);
    g_main_loop_quit(loop);
    latch.Signal();
  }).detach();

  g_main_loop_run(loop);

  fl_compositor_opengl_render(compositor, kWidth, kHeight);

  // Wait until the raster thread has finished before letting
  // the engine go out of scope.
  latch.Wait();
}

TEST(FlCompositorOpenGLTest, MultiView) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlEngine) engine = fl_engine_new(project);

  constexpr int kWidth = 100;
  constexpr int kHeight = 100;

  // OpenGL 3.0
  ON_CALL(epoxy, glGetString(GL_VENDOR))
      .WillByDefault(
          ::testing::Return(reinterpret_cast<const GLubyte*>("Intel")));
  ON_CALL(epoxy, epoxy_is_desktop_gl).WillByDefault(::testing::Return(true));
  ON_CALL(epoxy, epoxy_gl_version).WillByDefault(::testing::Return(30));

  g_autoptr(FlMockRenderable) renderable = fl_mock_renderable_new();
  g_autoptr(FlMockRenderable) secondary_renderable = fl_mock_renderable_new();

  g_autoptr(FlCompositorOpenGL) compositor =
      fl_compositor_opengl_new(engine, nullptr);
  fl_engine_set_implicit_view(engine, FL_RENDERABLE(renderable));
  fl_engine_add_view(engine, FL_RENDERABLE(secondary_renderable), 1024, 768,
                     1.0, nullptr, nullptr, nullptr);
  fl_compositor_wait_for_frame(FL_COMPOSITOR(compositor), kWidth, kHeight);

  fml::AutoResetWaitableEvent latch;

  g_autoptr(FlFramebuffer) framebuffer =
      fl_framebuffer_new(GL_RGB, kWidth, kHeight);
  FlutterBackingStore backing_store = {
      .type = kFlutterBackingStoreTypeOpenGL,
      .open_gl = {.framebuffer = {.user_data = framebuffer}}};
  FlutterLayer layer = {.type = kFlutterLayerContentTypeBackingStore,
                        .backing_store = &backing_store,
                        .offset = {0, 0},
                        .size = {kWidth, kHeight}};
  const FlutterLayer* layers[1] = {&layer};

  // Simulate raster thread.
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, 0);
  std::thread([&]() {
    fl_compositor_present_layers(FL_COMPOSITOR(compositor), layers, 1);
    g_main_loop_quit(loop);
    latch.Signal();
  }).detach();

  g_main_loop_run(loop);

  // FIXME
  // EXPECT_EQ(fl_mock_renderable_get_present_count(renderable),
  //          static_cast<size_t>(0));
  // EXPECT_EQ(fl_mock_renderable_get_present_count(secondary_renderable),
  //          static_cast<size_t>(1));

  // Wait until the raster thread has finished before letting
  // the engine go out of scope.
  latch.Wait();
}

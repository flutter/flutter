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
#include "flutter/shell/platform/linux/testing/mock_epoxy.h"
#include "flutter/shell/platform/linux/testing/mock_renderable.h"

#include <epoxy/egl.h>

TEST(FlCompositorOpenGLTest, BackgroundColor) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlEngine) engine = fl_engine_new(project);

  ON_CALL(epoxy, epoxy_is_desktop_gl).WillByDefault(::testing::Return(true));
  EXPECT_CALL(epoxy, epoxy_gl_version).WillRepeatedly(::testing::Return(30));
  ON_CALL(epoxy, glGetString(GL_VENDOR))
      .WillByDefault(
          ::testing::Return(reinterpret_cast<const GLubyte*>("Intel")));
  EXPECT_CALL(epoxy, glClearColor(0.2, 0.3, 0.4, 0.5));

  g_autoptr(FlMockRenderable) renderable = fl_mock_renderable_new();
  g_autoptr(FlCompositorOpenGL) compositor = fl_compositor_opengl_new(engine);
  fl_compositor_opengl_setup(compositor);
  fl_engine_set_implicit_view(engine, FL_RENDERABLE(renderable));
  fl_compositor_wait_for_frame(FL_COMPOSITOR(compositor), 1024, 1024);
  FlutterBackingStoreConfig config = {
      .struct_size = sizeof(FlutterBackingStoreConfig),
      .size = {.width = 1024, .height = 1024}};
  FlutterBackingStore backing_store;
  fl_compositor_create_backing_store(FL_COMPOSITOR(compositor), &config,
                                     &backing_store);

  fml::AutoResetWaitableEvent latch;

  // Simulate raster thread.
  std::thread([&]() {
    const FlutterLayer layer0 = {.struct_size = sizeof(FlutterLayer),
                                 .type = kFlutterLayerContentTypeBackingStore,
                                 .backing_store = &backing_store,
                                 .size = {.width = 1024, .height = 1024}};
    const FlutterLayer* layers[] = {&layer0};

    fl_compositor_present_layers(FL_COMPOSITOR(compositor),
                                 flutter::kFlutterImplicitViewId, layers, 1);
    latch.Signal();
  }).detach();

  while (fl_mock_renderable_get_redraw_count(renderable) == 0) {
    g_main_context_iteration(nullptr, true);
  }

  GdkRGBA background_color = {
      .red = 0.2, .green = 0.3, .blue = 0.4, .alpha = 0.5};
  fl_compositor_opengl_render(compositor, flutter::kFlutterImplicitViewId, 1024,
                              1024, &background_color);

  // Wait until the raster thread has finished before letting
  // the engine go out of scope.
  latch.Wait();
}

TEST(FlCompositorOpenGLTest, RestoresGLState) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlEngine) engine = fl_engine_new(project);

  constexpr int kWidth = 100;
  constexpr int kHeight = 100;

  g_autoptr(FlMockRenderable) renderable = fl_mock_renderable_new();
  g_autoptr(FlCompositorOpenGL) compositor = fl_compositor_opengl_new(engine);
  g_autoptr(FlFramebuffer) framebuffer =
      fl_framebuffer_new(GL_RGB, kWidth, kHeight);

  fl_engine_set_implicit_view(engine, FL_RENDERABLE(renderable));
  fl_compositor_wait_for_frame(FL_COMPOSITOR(compositor), kWidth, kHeight);

  FlutterBackingStore backing_store;
  backing_store.type = kFlutterBackingStoreTypeOpenGL;
  backing_store.open_gl.framebuffer.user_data = framebuffer;

  FlutterLayer layer;
  layer.type = kFlutterLayerContentTypeBackingStore;
  layer.backing_store = &backing_store;
  layer.offset = {0, 0};
  layer.size = {kWidth, kHeight};

  std::array<const FlutterLayer*, 1> layers = {&layer};

  constexpr GLuint kFakeTextureName = 123;
  glBindTexture(GL_TEXTURE_2D, kFakeTextureName);

  fml::AutoResetWaitableEvent latch;

  // Simulate raster thread.
  std::thread([&]() {
    fl_compositor_present_layers(FL_COMPOSITOR(compositor),
                                 flutter::kFlutterImplicitViewId, layers.data(),
                                 layers.size());
    latch.Signal();
  }).detach();

  while (fl_mock_renderable_get_redraw_count(renderable) == 0) {
    g_main_context_iteration(nullptr, true);
  }

  GdkRGBA background_color = {
      .red = 0.0, .green = 0.0, .blue = 0.0, .alpha = 1.0};
  fl_compositor_opengl_render(compositor, flutter::kFlutterImplicitViewId,
                              kWidth, kHeight, &background_color);

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

  // OpenGL 3.0
  ON_CALL(epoxy, glGetString(GL_VENDOR))
      .WillByDefault(
          ::testing::Return(reinterpret_cast<const GLubyte*>("Intel")));
  ON_CALL(epoxy, epoxy_is_desktop_gl).WillByDefault(::testing::Return(true));
  EXPECT_CALL(epoxy, epoxy_gl_version).WillRepeatedly(::testing::Return(30));

  EXPECT_CALL(epoxy, glBlitFramebuffer);

  g_autoptr(FlMockRenderable) renderable = fl_mock_renderable_new();
  g_autoptr(FlCompositorOpenGL) compositor = fl_compositor_opengl_new(engine);
  fl_compositor_opengl_setup(compositor);
  fl_engine_set_implicit_view(engine, FL_RENDERABLE(renderable));
  fl_compositor_wait_for_frame(FL_COMPOSITOR(compositor), 1024, 1024);
  FlutterBackingStoreConfig config = {
      .struct_size = sizeof(FlutterBackingStoreConfig),
      .size = {.width = 1024, .height = 1024}};
  FlutterBackingStore backing_store;
  fl_compositor_create_backing_store(FL_COMPOSITOR(compositor), &config,
                                     &backing_store);

  fml::AutoResetWaitableEvent latch;

  // Simulate raster thread.
  std::thread([&]() {
    const FlutterLayer layer0 = {.struct_size = sizeof(FlutterLayer),
                                 .type = kFlutterLayerContentTypeBackingStore,
                                 .backing_store = &backing_store,
                                 .size = {.width = 1024, .height = 1024}};
    const FlutterLayer* layers[] = {&layer0};
    fl_compositor_present_layers(FL_COMPOSITOR(compositor),
                                 flutter::kFlutterImplicitViewId, layers, 1);
    latch.Signal();
  }).detach();

  while (fl_mock_renderable_get_redraw_count(renderable) == 0) {
    g_main_context_iteration(nullptr, true);
  }

  GdkRGBA background_color = {
      .red = 0.0, .green = 0.0, .blue = 0.0, .alpha = 1.0};
  fl_compositor_opengl_render(compositor, flutter::kFlutterImplicitViewId, 1024,
                              1024, &background_color);

  latch.Wait();
}

TEST(FlCompositorOpenGLTest, BlitFramebufferExtension) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlEngine) engine = fl_engine_new(project);

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
  g_autoptr(FlCompositorOpenGL) compositor = fl_compositor_opengl_new(engine);
  fl_compositor_opengl_setup(compositor);
  fl_engine_set_implicit_view(engine, FL_RENDERABLE(renderable));
  fl_compositor_wait_for_frame(FL_COMPOSITOR(compositor), 1024, 1024);
  FlutterBackingStoreConfig config = {
      .struct_size = sizeof(FlutterBackingStoreConfig),
      .size = {.width = 1024, .height = 1024}};
  FlutterBackingStore backing_store;
  fl_compositor_create_backing_store(FL_COMPOSITOR(compositor), &config,
                                     &backing_store);

  fml::AutoResetWaitableEvent latch;

  // Simulate raster thread.
  std::thread([&]() {
    const FlutterLayer layer0 = {.struct_size = sizeof(FlutterLayer),
                                 .type = kFlutterLayerContentTypeBackingStore,
                                 .backing_store = &backing_store,
                                 .size = {.width = 1024, .height = 1024}};
    const FlutterLayer* layers[] = {&layer0};
    fl_compositor_present_layers(FL_COMPOSITOR(compositor),
                                 flutter::kFlutterImplicitViewId, layers, 1);
    latch.Signal();
  }).detach();

  while (fl_mock_renderable_get_redraw_count(renderable) == 0) {
    g_main_context_iteration(nullptr, true);
  }
  GdkRGBA background_color = {
      .red = 0.0, .green = 0.0, .blue = 0.0, .alpha = 1.0};
  fl_compositor_opengl_render(compositor, flutter::kFlutterImplicitViewId, 1024,
                              1024, &background_color);
  // Wait until the raster thread has finished before letting
  // the engine go out of scope.
  latch.Wait();
}

TEST(FlCompositorOpenGLTest, NoBlitFramebuffer) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlEngine) engine = fl_engine_new(project);

  // OpenGL 2.0
  ON_CALL(epoxy, glGetString(GL_VENDOR))
      .WillByDefault(
          ::testing::Return(reinterpret_cast<const GLubyte*>("Intel")));
  ON_CALL(epoxy, epoxy_is_desktop_gl).WillByDefault(::testing::Return(true));
  EXPECT_CALL(epoxy, epoxy_gl_version).WillRepeatedly(::testing::Return(20));

  g_autoptr(FlMockRenderable) renderable = fl_mock_renderable_new();
  g_autoptr(FlCompositorOpenGL) compositor = fl_compositor_opengl_new(engine);
  fl_compositor_opengl_setup(compositor);
  fl_engine_set_implicit_view(engine, FL_RENDERABLE(renderable));
  fl_compositor_wait_for_frame(FL_COMPOSITOR(compositor), 1024, 1024);
  FlutterBackingStoreConfig config = {
      .struct_size = sizeof(FlutterBackingStoreConfig),
      .size = {.width = 1024, .height = 1024}};
  FlutterBackingStore backing_store;
  fl_compositor_create_backing_store(FL_COMPOSITOR(compositor), &config,
                                     &backing_store);

  fml::AutoResetWaitableEvent latch;

  // Simulate raster thread.
  std::thread([&]() {
    const FlutterLayer layer0 = {.struct_size = sizeof(FlutterLayer),
                                 .type = kFlutterLayerContentTypeBackingStore,
                                 .backing_store = &backing_store,
                                 .size = {.width = 1024, .height = 1024}};
    const FlutterLayer* layers[] = {&layer0};
    fl_compositor_present_layers(FL_COMPOSITOR(compositor),
                                 flutter::kFlutterImplicitViewId, layers, 1);
    latch.Signal();
  }).detach();

  while (fl_mock_renderable_get_redraw_count(renderable) == 0) {
    g_main_context_iteration(nullptr, true);
  }

  GdkRGBA background_color = {
      .red = 0.0, .green = 0.0, .blue = 0.0, .alpha = 1.0};
  fl_compositor_opengl_render(compositor, flutter::kFlutterImplicitViewId, 1024,
                              1024, &background_color);

  // Wait until the raster thread has finished before letting
  // the engine go out of scope.
  latch.Wait();
}

TEST(FlCompositorOpenGLTest, BlitFramebufferNvidia) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlEngine) engine = fl_engine_new(project);

  // OpenGL 3.0, but on NVIDIA driver so temporarily disabled due to
  // https://github.com/flutter/flutter/issues/152099
  ON_CALL(epoxy, glGetString(GL_VENDOR))
      .WillByDefault(
          ::testing::Return(reinterpret_cast<const GLubyte*>("NVIDIA")));
  ON_CALL(epoxy, epoxy_is_desktop_gl).WillByDefault(::testing::Return(true));
  EXPECT_CALL(epoxy, epoxy_gl_version).WillRepeatedly(::testing::Return(30));

  g_autoptr(FlMockRenderable) renderable = fl_mock_renderable_new();
  g_autoptr(FlCompositorOpenGL) compositor = fl_compositor_opengl_new(engine);
  fl_compositor_opengl_setup(compositor);
  fl_engine_set_implicit_view(engine, FL_RENDERABLE(renderable));
  fl_compositor_wait_for_frame(FL_COMPOSITOR(compositor), 1024, 1024);
  FlutterBackingStoreConfig config = {
      .struct_size = sizeof(FlutterBackingStoreConfig),
      .size = {.width = 1024, .height = 1024}};
  FlutterBackingStore backing_store;
  fl_compositor_create_backing_store(FL_COMPOSITOR(compositor), &config,
                                     &backing_store);

  fml::AutoResetWaitableEvent latch;

  // Simulate raster thread.
  std::thread([&]() {
    const FlutterLayer layer0 = {.struct_size = sizeof(FlutterLayer),
                                 .type = kFlutterLayerContentTypeBackingStore,
                                 .backing_store = &backing_store,
                                 .size = {.width = 1024, .height = 1024}};
    const FlutterLayer* layers[] = {&layer0};
    fl_compositor_present_layers(FL_COMPOSITOR(compositor),
                                 flutter::kFlutterImplicitViewId, layers, 1);
    latch.Signal();
  }).detach();

  while (fl_mock_renderable_get_redraw_count(renderable) == 0) {
    g_main_context_iteration(nullptr, true);
  }

  GdkRGBA background_color = {
      .red = 0.0, .green = 0.0, .blue = 0.0, .alpha = 1.0};
  fl_compositor_opengl_render(compositor, flutter::kFlutterImplicitViewId, 1024,
                              1024, &background_color);

  // Wait until the raster thread has finished before letting
  // the engine go out of scope.
  latch.Wait();
}

TEST(FlCompositorOpenGLTest, MultiView) {
  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlEngine) engine = fl_engine_new(project);

  // OpenGL 3.0
  ON_CALL(epoxy, glGetString(GL_VENDOR))
      .WillByDefault(
          ::testing::Return(reinterpret_cast<const GLubyte*>("Intel")));
  ON_CALL(epoxy, epoxy_is_desktop_gl).WillByDefault(::testing::Return(true));
  EXPECT_CALL(epoxy, epoxy_gl_version).WillRepeatedly(::testing::Return(30));

  g_autoptr(FlMockRenderable) renderable = fl_mock_renderable_new();
  g_autoptr(FlMockRenderable) secondary_renderable = fl_mock_renderable_new();

  g_autoptr(FlCompositorOpenGL) compositor = fl_compositor_opengl_new(engine);
  fl_compositor_opengl_setup(compositor);
  fl_engine_set_implicit_view(engine, FL_RENDERABLE(renderable));
  FlutterViewId view_id =
      fl_engine_add_view(engine, FL_RENDERABLE(secondary_renderable), 1024, 768,
                         1.0, nullptr, nullptr, nullptr);
  fl_compositor_wait_for_frame(FL_COMPOSITOR(compositor), 1024, 1024);

  EXPECT_EQ(fl_mock_renderable_get_redraw_count(renderable),
            static_cast<size_t>(0));
  EXPECT_EQ(fl_mock_renderable_get_redraw_count(secondary_renderable),
            static_cast<size_t>(0));

  FlutterBackingStoreConfig config = {
      .struct_size = sizeof(FlutterBackingStoreConfig),
      .size = {.width = 1024, .height = 1024}};
  FlutterBackingStore backing_store;
  fl_compositor_create_backing_store(FL_COMPOSITOR(compositor), &config,
                                     &backing_store);

  fml::AutoResetWaitableEvent latch;

  // Simulate raster thread.
  std::thread([&]() {
    const FlutterLayer layer0 = {.struct_size = sizeof(FlutterLayer),
                                 .type = kFlutterLayerContentTypeBackingStore,
                                 .backing_store = &backing_store,
                                 .size = {.width = 1024, .height = 1024}};
    const FlutterLayer* layers[] = {&layer0};
    fl_compositor_present_layers(FL_COMPOSITOR(compositor), view_id, layers, 1);
    latch.Signal();
  }).detach();

  while (fl_mock_renderable_get_redraw_count(secondary_renderable) == 0) {
    g_main_context_iteration(nullptr, true);
  }

  EXPECT_EQ(fl_mock_renderable_get_redraw_count(renderable),
            static_cast<size_t>(0));
  EXPECT_EQ(fl_mock_renderable_get_redraw_count(secondary_renderable),
            static_cast<size_t>(1));

  // Wait until the raster thread has finished before letting
  // the engine go out of scope.
  latch.Wait();
}

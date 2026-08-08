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
    compositor = fl_compositor_opengl_new(opengl_manager);
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

TEST_F(FlCompositorOpenGLTest, Composite) {
  constexpr size_t width = 100;
  constexpr size_t height = 100;
  g_autoptr(FlFramebuffer) target =
      fl_framebuffer_new(GL_RGBA, width, height, FALSE);
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
  // Composite the layers from a thread, as is done on the raster thread.
  std::thread([&]() {
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, fl_framebuffer_get_id(target));
    fl_compositor_opengl_composite_layers(compositor, layers, 1);
  }).join();
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

  g_autoptr(FlFramebuffer) target =
      fl_framebuffer_new(GL_RGBA, width, height, FALSE);
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

  // Composite the layers.
  std::thread([&]() {
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, fl_framebuffer_get_id(target));
    fl_compositor_opengl_composite_layers(compositor, layers, 1);
  }).join();

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

  g_autoptr(FlFramebuffer) target =
      fl_framebuffer_new(GL_RGBA, width, height, FALSE);
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
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, fl_framebuffer_get_id(target));
    fl_compositor_opengl_composite_layers(compositor, layers, 1);
  }).join();
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

  g_autoptr(FlFramebuffer) target =
      fl_framebuffer_new(GL_RGBA, width, height, FALSE);
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
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, fl_framebuffer_get_id(target));
    fl_compositor_opengl_composite_layers(compositor, layers, 1);
  }).join();
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

  g_autoptr(FlFramebuffer) target =
      fl_framebuffer_new(GL_RGBA, width, height, FALSE);
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
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, fl_framebuffer_get_id(target));
    fl_compositor_opengl_composite_layers(compositor, layers, 1);
  }).join();
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

  g_autoptr(FlFramebuffer) target =
      fl_framebuffer_new(GL_RGBA, width, height, FALSE);
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
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, fl_framebuffer_get_id(target));
    fl_compositor_opengl_composite_layers(compositor, layers, 1);
  }).join();
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_opengl_frame.h"

#include <epoxy/gl.h>

#include "flutter/shell/platform/linux/fl_compositor_opengl.h"
#include "flutter/shell/platform/linux/fl_framebuffer.h"
#include "flutter/shell/platform/linux/fl_opengl_manager.h"
#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "flutter/shell/platform/linux/testing/mock_epoxy.h"
#include "gtest/gtest.h"

class FlOpenGLFrameTest : public flutter::testing::LinuxTest {
 protected:
  void SetUp() override {
    opengl_manager = fl_opengl_manager_new();
    compositor = fl_compositor_opengl_new(opengl_manager);
  }

  ~FlOpenGLFrameTest() override {
    g_clear_object(&compositor);
    g_clear_object(&opengl_manager);
  }

  ::testing::NiceMock<flutter::testing::MockEpoxy> epoxy;
  FlOpenGLManager* opengl_manager = nullptr;
  FlCompositorOpenGL* compositor = nullptr;
};

TEST_F(FlOpenGLFrameTest, GetSizeInitiallyZero) {
  g_autoptr(FlOpenGLFrame) frame = fl_opengl_frame_new(/*shareable=*/TRUE);
  size_t frame_width = 123;
  size_t frame_height = 456;
  fl_opengl_frame_get_size(frame, &frame_width, &frame_height);
  EXPECT_EQ(frame_width, 0u);
  EXPECT_EQ(frame_height, 0u);
}

TEST_F(FlOpenGLFrameTest, CompositeRGBA) {
  constexpr size_t width = 100;
  constexpr size_t height = 100;

  g_autoptr(FlOpenGLFrame) frame = fl_opengl_frame_new(/*shareable=*/TRUE);
  g_autoptr(FlFramebuffer) framebuffer =
      fl_framebuffer_new(GL_RGBA, width, height, FALSE);
  FlutterBackingStore backing_store = {
      .type = kFlutterBackingStoreTypeOpenGL,
      .open_gl = {
          .type = kFlutterOpenGLTargetTypeFramebuffer,
          .framebuffer = {.target = GL_RGBA8, .user_data = framebuffer}}};
  FlutterLayer layer = {.type = kFlutterLayerContentTypeBackingStore,
                        .backing_store = &backing_store,
                        .offset = {0, 0},
                        .size = {width, height}};
  const FlutterLayer* layers[1] = {&layer};

  EXPECT_CALL(epoxy, glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0,
                                  GL_RGBA, GL_UNSIGNED_BYTE, nullptr));

  fl_opengl_frame_composite(frame, compositor, layers, 1);

  size_t frame_width = 0;
  size_t frame_height = 0;
  fl_opengl_frame_get_size(frame, &frame_width, &frame_height);
  EXPECT_EQ(frame_width, width);
  EXPECT_EQ(frame_height, height);
}

TEST_F(FlOpenGLFrameTest, CompositeBGRA) {
  constexpr size_t width = 100;
  constexpr size_t height = 100;

  g_autoptr(FlOpenGLFrame) frame = fl_opengl_frame_new(/*shareable=*/TRUE);
  g_autoptr(FlFramebuffer) framebuffer =
      fl_framebuffer_new(GL_BGRA_EXT, width, height, FALSE);
  FlutterBackingStore backing_store = {
      .type = kFlutterBackingStoreTypeOpenGL,
      .open_gl = {
          .type = kFlutterOpenGLTargetTypeFramebuffer,
          .framebuffer = {.target = GL_BGRA8_EXT, .user_data = framebuffer}}};
  FlutterLayer layer = {.type = kFlutterLayerContentTypeBackingStore,
                        .backing_store = &backing_store,
                        .offset = {0, 0},
                        .size = {width, height}};
  const FlutterLayer* layers[1] = {&layer};

  EXPECT_CALL(epoxy, glTexImage2D(GL_TEXTURE_2D, 0, GL_BGRA_EXT, width, height,
                                  0, GL_BGRA_EXT, GL_UNSIGNED_BYTE, nullptr));

  fl_opengl_frame_composite(frame, compositor, layers, 1);

  size_t frame_width = 0;
  size_t frame_height = 0;
  fl_opengl_frame_get_size(frame, &frame_width, &frame_height);
  EXPECT_EQ(frame_width, width);
  EXPECT_EQ(frame_height, height);
}

TEST_F(FlOpenGLFrameTest, ZeroSizeClearsFrame) {
  constexpr size_t width = 100;
  constexpr size_t height = 100;

  g_autoptr(FlOpenGLFrame) frame = fl_opengl_frame_new(/*shareable=*/TRUE);
  g_autoptr(FlFramebuffer) framebuffer =
      fl_framebuffer_new(GL_RGBA, width, height, FALSE);
  FlutterBackingStore backing_store = {
      .type = kFlutterBackingStoreTypeOpenGL,
      .open_gl = {
          .type = kFlutterOpenGLTargetTypeFramebuffer,
          .framebuffer = {.target = GL_RGBA8, .user_data = framebuffer}}};
  FlutterLayer layer = {.type = kFlutterLayerContentTypeBackingStore,
                        .backing_store = &backing_store,
                        .offset = {0, 0},
                        .size = {width, height}};
  const FlutterLayer* layers[1] = {&layer};

  fl_opengl_frame_composite(frame, compositor, layers, 1);

  size_t frame_width = 0;
  size_t frame_height = 0;
  fl_opengl_frame_get_size(frame, &frame_width, &frame_height);
  EXPECT_EQ(frame_width, width);
  EXPECT_EQ(frame_height, height);

  FlutterLayer zero_layer = {.type = kFlutterLayerContentTypeBackingStore,
                             .backing_store = &backing_store,
                             .offset = {0, 0},
                             .size = {0, 0}};
  const FlutterLayer* zero_layers[1] = {&zero_layer};
  fl_opengl_frame_composite(frame, compositor, zero_layers, 1);

  fl_opengl_frame_get_size(frame, &frame_width, &frame_height);
  EXPECT_EQ(frame_width, 0u);
  EXPECT_EQ(frame_height, 0u);
}

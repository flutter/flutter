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

// Checks a shareable frame is synchronized before it is handed to GTK, which
// draws it using a different OpenGL context.
// https://github.com/flutter/flutter/issues/191775
TEST_F(FlOpenGLFrameTest, ShareableFrameSynchronized) {
  constexpr size_t width = 100;
  constexpr size_t height = 100;

  g_autoptr(FlOpenGLFrame) frame = fl_opengl_frame_new(/*shareable=*/TRUE);
  g_autoptr(FlFramebuffer) framebuffer =
      fl_framebuffer_new(GL_RGBA, width, height, TRUE);
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

  // Rendering the frame takes a fence rather than waiting for the rendering to
  // complete, so this thread can carry on rendering the next frame.
  EXPECT_CALL(epoxy,
              eglCreateSyncKHR(::testing::_, EGL_SYNC_FENCE_KHR, ::testing::_));
  EXPECT_CALL(epoxy, glFinish()).Times(0);

  fl_opengl_frame_composite(frame, compositor, layers, 1);

  // Drawing the frame waits for that fence. GTK draws using the window's paint
  // context rather than the current one, so the wait can't be left to the GPU.
  EXPECT_CALL(epoxy, eglClientWaitSyncKHR)
      .WillOnce(::testing::Return(EGL_CONDITION_SATISFIED_KHR));
  EXPECT_CALL(epoxy, eglWaitSyncKHR).Times(0);

  int stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);
  g_autofree unsigned char* image_data =
      static_cast<unsigned char*>(g_malloc(height * stride));
  cairo_surface_t* surface = cairo_image_surface_create_for_data(
      image_data, CAIRO_FORMAT_ARGB32, width, height, stride);
  cairo_t* cr = cairo_create(surface);
  EXPECT_TRUE(fl_opengl_frame_draw(frame, cr, nullptr, 1, width, height));
  cairo_destroy(cr);
  cairo_surface_destroy(surface);
}

// Checks a shareable frame is still synchronized on drivers without fences, by
// waiting for the rendering to complete instead.
TEST_F(FlOpenGLFrameTest, ShareableFrameSynchronizedWithoutFences) {
  constexpr size_t width = 100;
  constexpr size_t height = 100;

  g_autoptr(FlOpenGLFrame) frame = fl_opengl_frame_new(/*shareable=*/TRUE);
  g_autoptr(FlFramebuffer) framebuffer =
      fl_framebuffer_new(GL_RGBA, width, height, TRUE);
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

  // The compositor checks for fence support when it is created.
  EXPECT_CALL(epoxy, eglQueryString(::testing::_, EGL_EXTENSIONS))
      .WillRepeatedly(::testing::Return("EGL_KHR_image_base"));
  g_autoptr(FlCompositorOpenGL) unfenced_compositor =
      fl_compositor_opengl_new(opengl_manager);

  EXPECT_CALL(epoxy, eglCreateSyncKHR).Times(0);
  EXPECT_CALL(epoxy, glFinish());

  fl_opengl_frame_composite(frame, unfenced_compositor, layers, 1);
}

// Checks a frame that is copied into CPU memory does not pay for a second
// synchronization - glReadPixels() already waits for the frame to be rendered.
TEST_F(FlOpenGLFrameTest, UnshareableFrameNotSynchronizedTwice) {
  constexpr size_t width = 100;
  constexpr size_t height = 100;

  g_autoptr(FlOpenGLFrame) frame = fl_opengl_frame_new(/*shareable=*/FALSE);
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

  EXPECT_CALL(epoxy, glFinish()).Times(0);
  EXPECT_CALL(epoxy, eglCreateSyncKHR).Times(0);

  fl_opengl_frame_composite(frame, compositor, layers, 1);
}

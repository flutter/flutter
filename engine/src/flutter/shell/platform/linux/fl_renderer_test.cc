// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include <epoxy/egl.h>

#include "flutter/fml/logging.h"
#include "flutter/shell/platform/linux/fl_backing_store_provider.h"
#include "flutter/shell/platform/linux/testing/fl_test_gtk_logs.h"
#include "flutter/shell/platform/linux/testing/mock_renderer.h"

TEST(FlRendererTest, RestoresGLState) {
  constexpr int kWidth = 100;
  constexpr int kHeight = 100;

  flutter::testing::fl_ensure_gtk_init();
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlView) view = fl_view_new(project);
  g_autoptr(FlMockRenderer) renderer = fl_mock_renderer_new();
  g_autoptr(FlBackingStoreProvider) backing_store_provider =
      fl_backing_store_provider_new(kWidth, kHeight);

  fl_renderer_start(FL_RENDERER(renderer), view);
  fl_renderer_wait_for_frame(FL_RENDERER(renderer), kWidth, kHeight);

  FlutterBackingStore backing_store;
  backing_store.type = kFlutterBackingStoreTypeOpenGL;
  backing_store.open_gl.framebuffer.user_data = backing_store_provider;

  FlutterLayer layer;
  layer.type = kFlutterLayerContentTypeBackingStore;
  layer.backing_store = &backing_store;
  layer.offset = {0, 0};
  layer.size = {kWidth, kHeight};

  std::array<const FlutterLayer*, 1> layers = {&layer};

  constexpr GLuint kFakeTextureName = 123;
  glBindTexture(GL_TEXTURE_2D, kFakeTextureName);

  fl_renderer_present_layers(FL_RENDERER(renderer), layers.data(),
                             layers.size());
  fl_renderer_render(FL_RENDERER(renderer), kWidth, kHeight);

  GLuint texture_2d_binding;
  glGetIntegerv(GL_TEXTURE_BINDING_2D,
                reinterpret_cast<GLint*>(&texture_2d_binding));
  EXPECT_EQ(texture_2d_binding, kFakeTextureName);

  g_object_ref_sink(view);
}

static constexpr double kExpectedRefreshRate = 120.0;
static gdouble renderer_get_refresh_rate(FlRenderer* renderer) {
  return kExpectedRefreshRate;
}

TEST(FlRendererTest, RefreshRate) {
  flutter::testing::fl_ensure_gtk_init();
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlMockRenderer) renderer =
      fl_mock_renderer_new(&renderer_get_refresh_rate);

  gdouble result_refresh_rate =
      fl_renderer_get_refresh_rate(FL_RENDERER(renderer));
  EXPECT_DOUBLE_EQ(result_refresh_rate, kExpectedRefreshRate);
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_compositor_opengl_private.h"

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
  const FlutterLayer* layers[] = {&layer};
  // Seed the retained target so a missing clear produces a visible pixel.
  g_assert_true(
      fl_compositor_present_layers(FL_COMPOSITOR(compositor), layers, 1));
  glBindFramebuffer(GL_FRAMEBUFFER, fl_framebuffer_get_id(source));
  glEnable(GL_SCISSOR_TEST);
  glScissor(0, height - 1, 1, 1);
  glClearColor(1, 0, 0, 1);
  glClear(GL_COLOR_BUFFER_BIT);
  layer.offset = {2, 1};
  g_assert_true(
      fl_compositor_present_layers(FL_COMPOSITOR(compositor), layers, 1));
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

int main(int argc, char** argv) {
  g_test_init(&argc, &argv, nullptr);
  gtk_init();
  g_test_add_func("/compositor/offset-layer", test_offset_layer);
  return g_test_run();
}

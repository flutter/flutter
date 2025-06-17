// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include "flutter/common/constants.h"
#include "flutter/shell/platform/linux/fl_compositor_software.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/testing/mock_renderable.h"

TEST(FlCompositorSoftwareTest, Render) {
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlEngine) engine = fl_engine_new(project);

  g_autoptr(FlMockRenderable) renderable = fl_mock_renderable_new();
  g_autoptr(FlCompositorSoftware) compositor =
      fl_compositor_software_new(engine);
  fl_engine_set_implicit_view(engine, FL_RENDERABLE(renderable));
  FlutterBackingStoreConfig config = {
      .struct_size = sizeof(FlutterBackingStoreConfig),
      .size = {.width = 1024, .height = 1024}};
  FlutterBackingStore backing_store;
  fl_compositor_create_backing_store(FL_COMPOSITOR(compositor), &config,
                                     &backing_store);

  const FlutterLayer layer0 = {.struct_size = sizeof(FlutterLayer),
                               .type = kFlutterLayerContentTypeBackingStore,
                               .backing_store = &backing_store,
                               .size = {.width = 1024, .height = 1024}};
  const FlutterLayer* layers[] = {&layer0};

  unsigned char image_data[1024 * 1024 * 4];
  cairo_surface_t* surface = cairo_image_surface_create_for_data(
      image_data, CAIRO_FORMAT_ARGB32, 1024, 1024, 1024 * 4);
  cairo_t* cr = cairo_create(surface);
  fl_compositor_present_layers(FL_COMPOSITOR(compositor),
                               flutter::kFlutterImplicitViewId, layers, 1);
  fl_compositor_software_render(compositor, flutter::kFlutterImplicitViewId, cr,
                                1);
  cairo_surface_destroy(surface);
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include "flutter/common/constants.h"
#include "flutter/shell/platform/linux/fl_compositor_software.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_dart_project.h"
#include "flutter/shell/platform/linux/testing/mock_renderable.h"

TEST(FlCompositorSoftwareTest, Render) {
  g_autoptr(FlDartProject) project = fl_dart_project_new();

  g_autoptr(FlCompositorSoftware) compositor = fl_compositor_software_new();

  unsigned char image_data[1024 * 1024 * 4];
  cairo_surface_t* surface = cairo_image_surface_create_for_data(
      image_data, CAIRO_FORMAT_ARGB32, 1024, 1024, 1024 * 4);
  cairo_t* cr = cairo_create(surface);
  fl_compositor_present_layers(FL_COMPOSITOR(compositor), nullptr, 0);
  fl_compositor_software_render(compositor, cr, 1);
  cairo_surface_destroy(surface);
}

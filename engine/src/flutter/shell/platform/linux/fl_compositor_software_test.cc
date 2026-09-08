// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <thread>
#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "gtest/gtest.h"

#include "flutter/shell/platform/linux/fl_compositor_software.h"

class FlCompositorSoftwareTest : public flutter::testing::LinuxTest {
 protected:
  void SetUp() override { compositor = fl_compositor_software_new(); }

  ~FlCompositorSoftwareTest() { g_clear_object(&compositor); }

  FlCompositorSoftware* compositor = nullptr;
};

TEST_F(FlCompositorSoftwareTest, Render) {
  constexpr size_t width = 100;
  constexpr size_t height = 100;
  size_t row_bytes = width * 4;
  g_autofree unsigned char* layer_data =
      static_cast<unsigned char*>(malloc(height * row_bytes));
  // Fill the layer with an opaque white.
  memset(layer_data, 0xFF, height * row_bytes);
  FlutterBackingStore backing_store = {
      .type = kFlutterBackingStoreTypeSoftware,
      .software = {
          .allocation = layer_data, .row_bytes = row_bytes, .height = height}};
  FlutterLayer layer = {.type = kFlutterLayerContentTypeBackingStore,
                        .backing_store = &backing_store,
                        .offset = {0, 0},
                        .size = {width, height}};
  const FlutterLayer* layers[1] = {&layer};

  // Composite the layer into a caller-managed surface.
  int stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);
  g_autofree unsigned char* image_data =
      static_cast<unsigned char*>(malloc(height * stride));
  memset(image_data, 0, height * stride);
  cairo_surface_t* surface = cairo_image_surface_create_for_data(
      image_data, CAIRO_FORMAT_ARGB32, width, height, stride);
  cairo_t* cr = cairo_create(surface);
  EXPECT_TRUE(
      fl_compositor_software_composite_layers(compositor, cr, layers, 1));
  cairo_surface_flush(surface);

  // The layer was drawn into the surface.
  uint32_t* pixels = reinterpret_cast<uint32_t*>(image_data);
  EXPECT_EQ(pixels[50 * (stride / 4) + 50], 0xFFFFFFFFu);

  cairo_destroy(cr);
  cairo_surface_destroy(surface);
}

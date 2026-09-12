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

// The layers replace the target contents, so a frame with nothing to
// rasterize (which has no layers) clears the previous frame.
TEST_F(FlCompositorSoftwareTest, RenderNoLayers) {
  constexpr size_t width = 100;
  constexpr size_t height = 100;

  int stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);
  g_autofree unsigned char* image_data =
      static_cast<unsigned char*>(malloc(height * stride));
  // Fill the surface with an opaque white, as if a previous frame had been
  // rendered into it.
  memset(image_data, 0xFF, height * stride);
  cairo_surface_t* surface = cairo_image_surface_create_for_data(
      image_data, CAIRO_FORMAT_ARGB32, width, height, stride);
  cairo_t* cr = cairo_create(surface);
  EXPECT_TRUE(
      fl_compositor_software_composite_layers(compositor, cr, nullptr, 0));
  cairo_surface_flush(surface);

  // The previous frame was cleared.
  uint32_t* pixels = reinterpret_cast<uint32_t*>(image_data);
  EXPECT_EQ(pixels[50 * (stride / 4) + 50], 0x00000000u);

  cairo_destroy(cr);
  cairo_surface_destroy(surface);
}

TEST_F(FlCompositorSoftwareTest, RenderMultipleLayers) {
  constexpr size_t width = 100;
  constexpr size_t height = 100;

  // The first layer covers the whole frame, the second is a smaller layer
  // offset inside it.
  size_t layer0_row_bytes = width * 4;
  g_autofree unsigned char* layer0_data =
      static_cast<unsigned char*>(malloc(height * layer0_row_bytes));
  // Fill the layer with an opaque white.
  memset(layer0_data, 0xFF, height * layer0_row_bytes);
  FlutterBackingStore backing_store0 = {
      .type = kFlutterBackingStoreTypeSoftware,
      .software = {.allocation = layer0_data,
                   .row_bytes = layer0_row_bytes,
                   .height = height}};
  FlutterLayer layer0 = {.type = kFlutterLayerContentTypeBackingStore,
                         .backing_store = &backing_store0,
                         .offset = {0, 0},
                         .size = {width, height}};

  constexpr size_t layer1_width = 10;
  constexpr size_t layer1_height = 10;
  size_t layer1_row_bytes = layer1_width * 4;
  g_autofree unsigned char* layer1_data =
      static_cast<unsigned char*>(malloc(layer1_height * layer1_row_bytes));
  // Fill the layer with an opaque red.
  uint32_t* layer1_pixels = reinterpret_cast<uint32_t*>(layer1_data);
  for (size_t i = 0; i < layer1_width * layer1_height; i++) {
    layer1_pixels[i] = 0xFFFF0000;
  }
  FlutterBackingStore backing_store1 = {
      .type = kFlutterBackingStoreTypeSoftware,
      .software = {.allocation = layer1_data,
                   .row_bytes = layer1_row_bytes,
                   .height = layer1_height}};
  FlutterLayer layer1 = {.type = kFlutterLayerContentTypeBackingStore,
                         .backing_store = &backing_store1,
                         .offset = {20, 20},
                         .size = {layer1_width, layer1_height}};

  const FlutterLayer* layers[2] = {&layer0, &layer1};

  int stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);
  g_autofree unsigned char* image_data =
      static_cast<unsigned char*>(malloc(height * stride));
  memset(image_data, 0, height * stride);
  cairo_surface_t* surface = cairo_image_surface_create_for_data(
      image_data, CAIRO_FORMAT_ARGB32, width, height, stride);
  cairo_t* cr = cairo_create(surface);
  EXPECT_TRUE(
      fl_compositor_software_composite_layers(compositor, cr, layers, 2));
  cairo_surface_flush(surface);

  uint32_t* pixels = reinterpret_cast<uint32_t*>(image_data);
  // The second layer is drawn at its offset.
  EXPECT_EQ(pixels[25 * (stride / 4) + 25], 0xFFFF0000u);
  // The first layer is drawn everywhere the second doesn't cover.
  EXPECT_EQ(pixels[50 * (stride / 4) + 50], 0xFFFFFFFFu);
  EXPECT_EQ(pixels[25 * (stride / 4) + 15], 0xFFFFFFFFu);
  EXPECT_EQ(pixels[15 * (stride / 4) + 25], 0xFFFFFFFFu);

  cairo_destroy(cr);
  cairo_surface_destroy(surface);
}

// Platform views are not implemented, but must not stop the other layers being
// drawn.
TEST_F(FlCompositorSoftwareTest, RenderPlatformViewLayer) {
  constexpr size_t width = 100;
  constexpr size_t height = 100;
  size_t row_bytes = width * 4;
  g_autofree unsigned char* layer_data =
      static_cast<unsigned char*>(malloc(height * row_bytes));
  // Fill the layer with an opaque white.
  memset(layer_data, 0xFF, height * row_bytes);
  FlutterPlatformView platform_view = {.identifier = 1};
  FlutterLayer platform_view_layer = {
      .type = kFlutterLayerContentTypePlatformView,
      .platform_view = &platform_view,
      .offset = {0, 0},
      .size = {width, height}};
  FlutterBackingStore backing_store = {
      .type = kFlutterBackingStoreTypeSoftware,
      .software = {
          .allocation = layer_data, .row_bytes = row_bytes, .height = height}};
  FlutterLayer layer = {.type = kFlutterLayerContentTypeBackingStore,
                        .backing_store = &backing_store,
                        .offset = {0, 0},
                        .size = {width, height}};
  const FlutterLayer* layers[2] = {&platform_view_layer, &layer};

  int stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);
  g_autofree unsigned char* image_data =
      static_cast<unsigned char*>(malloc(height * stride));
  memset(image_data, 0, height * stride);
  cairo_surface_t* surface = cairo_image_surface_create_for_data(
      image_data, CAIRO_FORMAT_ARGB32, width, height, stride);
  cairo_t* cr = cairo_create(surface);
  EXPECT_TRUE(
      fl_compositor_software_composite_layers(compositor, cr, layers, 2));
  cairo_surface_flush(surface);

  uint32_t* pixels = reinterpret_cast<uint32_t*>(image_data);
  EXPECT_EQ(pixels[50 * (stride / 4) + 50], 0xFFFFFFFFu);

  cairo_destroy(cr);
  cairo_surface_destroy(surface);
}

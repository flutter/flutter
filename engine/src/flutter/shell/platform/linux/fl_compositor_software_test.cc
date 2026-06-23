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
  // Present layer from a thread.
  constexpr size_t width = 100;
  constexpr size_t height = 100;
  size_t row_bytes = width * 4;
  g_autofree unsigned char* layer_data =
      static_cast<unsigned char*>(malloc(height * row_bytes));
  FlutterBackingStore backing_store = {
      .type = kFlutterBackingStoreTypeSoftware,
      .software = {
          .allocation = layer_data, .row_bytes = row_bytes, .height = height}};
  FlutterLayer layer = {.type = kFlutterLayerContentTypeBackingStore,
                        .backing_store = &backing_store,
                        .offset = {0, 0},
                        .size = {width, height}};
  const FlutterLayer* layers[1] = {&layer};
  fl_compositor_software_present_layers(compositor, layers, 1);

  size_t frame_width, frame_height;
  fl_compositor_software_get_frame_size(compositor, &frame_width,
                                        &frame_height);
  EXPECT_EQ(frame_width, width);
  EXPECT_EQ(frame_height, height);

  // Render presented layer.
  int stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);
  g_autofree unsigned char* image_data =
      static_cast<unsigned char*>(malloc(height * stride));
  cairo_surface_t* surface = cairo_image_surface_create_for_data(
      image_data, CAIRO_FORMAT_ARGB32, width, height, stride);
  cairo_t* cr = cairo_create(surface);
  EXPECT_TRUE(fl_compositor_software_render(compositor, cr, 1));
  cairo_surface_destroy(surface);
  cairo_destroy(cr);
}

TEST_F(FlCompositorSoftwareTest, Resize) {
  // Present a layer that is the old size.
  constexpr size_t width1 = 90;
  constexpr size_t height1 = 90;
  size_t row_bytes = width1 * 4;
  g_autofree unsigned char* layer1_data =
      static_cast<unsigned char*>(malloc(height1 * row_bytes));
  FlutterBackingStore backing_store1 = {
      .type = kFlutterBackingStoreTypeSoftware,
      .software = {.allocation = layer1_data,
                   .row_bytes = row_bytes,
                   .height = height1}};
  FlutterLayer layer1 = {.type = kFlutterLayerContentTypeBackingStore,
                         .backing_store = &backing_store1,
                         .offset = {0, 0},
                         .size = {width1, height1}};
  const FlutterLayer* layers1[1] = {&layer1};
  fl_compositor_software_present_layers(compositor, layers1, 1);

  // Present a layer in the new size.
  constexpr size_t width2 = 100;
  constexpr size_t height2 = 100;
  row_bytes = width2 * 4;
  g_autofree unsigned char* layer2_data =
      static_cast<unsigned char*>(malloc(height2 * row_bytes));
  FlutterBackingStore backing_store2 = {
      .type = kFlutterBackingStoreTypeSoftware,
      .software = {.allocation = layer2_data,
                   .row_bytes = row_bytes,
                   .height = height2}};
  FlutterLayer layer2 = {.type = kFlutterLayerContentTypeBackingStore,
                         .backing_store = &backing_store2,
                         .offset = {0, 0},
                         .size = {width2, height2}};
  const FlutterLayer* layers2[1] = {&layer2};
  fl_compositor_software_present_layers(compositor, layers2, 1);

  // The stored frame is now the new size.
  size_t frame_width, frame_height;
  fl_compositor_software_get_frame_size(compositor, &frame_width,
                                        &frame_height);
  EXPECT_EQ(frame_width, width2);
  EXPECT_EQ(frame_height, height2);

  // Render the presented layer.
  int stride2 = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width2);
  g_autofree unsigned char* image_data =
      static_cast<unsigned char*>(malloc(height2 * stride2));
  cairo_surface_t* surface = cairo_image_surface_create_for_data(
      image_data, CAIRO_FORMAT_ARGB32, width2, height2, stride2);
  cairo_t* cr = cairo_create(surface);
  EXPECT_TRUE(fl_compositor_software_render(compositor, cr, 1));
  cairo_surface_destroy(surface);
  cairo_destroy(cr);
}

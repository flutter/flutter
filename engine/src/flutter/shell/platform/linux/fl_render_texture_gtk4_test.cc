// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_render_texture_gtk4.h"

#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "flutter/testing/testing.h"

namespace {

class FlRenderTextureGtk4Test : public flutter::testing::LinuxTest {};

TEST_F(FlRenderTextureGtk4Test, TextureDoesNotSetMinimumSize) {
  constexpr int kTextureWidth = 640;
  constexpr int kTextureHeight = 480;
  constexpr gsize kStride = kTextureWidth * 4;
  g_autoptr(GBytes) bytes = g_bytes_new_take(
      g_malloc0(kStride * kTextureHeight), kStride * kTextureHeight);
  g_autoptr(GdkTexture) texture = gdk_memory_texture_new(
      kTextureWidth, kTextureHeight, GDK_MEMORY_DEFAULT, bytes, kStride);
  g_autoptr(GtkWidget) widget =
      GTK_WIDGET(g_object_ref_sink(fl_render_texture_gtk4_new()));

  fl_render_texture_gtk4_set_texture(FL_RENDER_TEXTURE_GTK4(widget), texture);

  const int scale_factor = MAX(gtk_widget_get_scale_factor(widget), 1);
  int minimum = -1;
  int natural = -1;
  gtk_widget_measure(widget, GTK_ORIENTATION_HORIZONTAL, -1, &minimum, &natural,
                     nullptr, nullptr);
  EXPECT_EQ(minimum, 0);
  EXPECT_EQ(natural, (kTextureWidth + scale_factor - 1) / scale_factor);

  gtk_widget_measure(widget, GTK_ORIENTATION_VERTICAL, -1, &minimum, &natural,
                     nullptr, nullptr);
  EXPECT_EQ(minimum, 0);
  EXPECT_EQ(natural, (kTextureHeight + scale_factor - 1) / scale_factor);
}

}  // namespace

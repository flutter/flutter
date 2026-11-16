// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Included first as it collides with the X11 headers.
#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "gtest/gtest.h"

#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_view_renderer.h"
#include "flutter/shell/platform/linux/fl_view_renderer_opengl.h"
#include "flutter/shell/platform/linux/testing/mock_gtk.h"

// MOCK_ENGINE_PROC is leaky by design
// NOLINTBEGIN(clang-analyzer-core.StackAddressEscape)

class FlViewRendererOpenGLTest : public flutter::testing::LinuxTest {
 protected:
  // GTK queries the window state when widgets are realized.
  ::testing::NiceMock<flutter::testing::MockGtk> gtk;
};

TEST_F(FlViewRendererOpenGLTest, New) {
  g_autoptr(FlViewRendererOpenGL) renderer =
      fl_view_renderer_opengl_new(engine, FALSE);
  ASSERT_NE(renderer, nullptr);
  g_object_ref_sink(renderer);
  EXPECT_TRUE(FL_IS_VIEW_RENDERER(renderer));
  EXPECT_TRUE(GTK_IS_WIDGET(renderer));
}

TEST_F(FlViewRendererOpenGLTest, PresentLayersAfterDestroy) {
  // Create a renderer and destroy it.
  FlViewRendererOpenGL* renderer = fl_view_renderer_opengl_new(engine, FALSE);
  g_object_ref_sink(renderer);
  fl_gtk_widget_destroy(GTK_WIDGET(renderer));

  // Present a frame on a destroyed widget.
  fl_view_renderer_present_layers(FL_VIEW_RENDERER(renderer), nullptr, 0);

  g_object_unref(renderer);
}

// NOLINTEND(clang-analyzer-core.StackAddressEscape)

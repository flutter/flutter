// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <gdk/wayland/gdkwayland.h>

#include "gtest/gtest.h"

#include "flutter/shell/platform/linux/fl_graphics_offload_gtk4.h"

#include "flutter/shell/platform/linux/fl_gtk4_runtime_api.h"
#include "flutter/shell/platform/linux/fl_render_texture_gtk4.h"
#include "flutter/shell/platform/linux/fl_view_private.h"
#include "flutter/shell/platform/linux/testing/linux_test.h"

namespace {

class FlGraphicsOffloadGtk4Test : public flutter::testing::LinuxTest {
 protected:
  void SetUp() override {
    previous_ = g_strdup(g_getenv("FLUTTER_GTK4_ENABLE_GRAPHICS_OFFLOAD"));
    g_unsetenv("FLUTTER_GTK4_ENABLE_GRAPHICS_OFFLOAD");
  }

  void TearDown() override {
    if (previous_ != nullptr) {
      g_setenv("FLUTTER_GTK4_ENABLE_GRAPHICS_OFFLOAD", previous_, TRUE);
    } else {
      g_unsetenv("FLUTTER_GTK4_ENABLE_GRAPHICS_OFFLOAD");
    }
    g_free(previous_);
    flutter::testing::LinuxTest::TearDown();
  }

 private:
  gchar* previous_ = nullptr;
};

TEST_F(FlGraphicsOffloadGtk4Test, DisabledLeavesOriginalHierarchy) {
  g_autoptr(GtkWidget) child =
      GTK_WIDGET(g_object_ref_sink(fl_render_texture_gtk4_new()));
  EXPECT_EQ(fl_graphics_offload_gtk4_wrap(child), child);
  EXPECT_EQ(gtk_widget_get_parent(child), nullptr);
}

TEST_F(FlGraphicsOffloadGtk4Test, ExplicitDisableOverridesAutomaticOffload) {
  g_autoptr(GtkWidget) child =
      GTK_WIDGET(g_object_ref_sink(fl_render_texture_gtk4_new()));
  for (const gchar* value : {"0", "false", "true", ""}) {
    g_setenv("FLUTTER_GTK4_ENABLE_GRAPHICS_OFFLOAD", value, TRUE);
    EXPECT_FALSE(fl_graphics_offload_gtk4_is_requested());
    EXPECT_EQ(fl_graphics_offload_gtk4_wrap(child, nullptr, TRUE), child);
  }
}

TEST_F(FlGraphicsOffloadGtk4Test, OldRuntimeOrMissingSymbolPreservesChild) {
  g_setenv("FLUTTER_GTK4_ENABLE_GRAPHICS_OFFLOAD", "1", TRUE);
  g_autoptr(GtkWidget) child =
      GTK_WIDGET(g_object_ref_sink(fl_render_texture_gtk4_new()));
  FlGtkRuntimeApi api = {};
  EXPECT_EQ(fl_graphics_offload_gtk4_wrap(child, &api), child);
  api.gtk_at_least_4_14 = TRUE;
  EXPECT_EQ(fl_graphics_offload_gtk4_wrap(child, &api), child);
  // A resolved symbol must not bypass the minimum runtime version.
  api = *fl_gtk_runtime_api_get();
  api.gtk_at_least_4_14 = FALSE;
  EXPECT_EQ(fl_graphics_offload_gtk4_wrap(child, &api), child);
  EXPECT_EQ(gtk_widget_get_parent(child), nullptr);
}

TEST_F(FlGraphicsOffloadGtk4Test, WrapperPreservesSizingAndChildLifetime) {
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  if (!api->gtk_at_least_4_14 ||
      api->gtk_graphics_offload_get_type == nullptr) {
    GTEST_SKIP() << "Graphics offload is unavailable on this GTK runtime";
  }
  GtkWidget* child = fl_render_texture_gtk4_new();
  gtk_widget_set_size_request(child, 200, 100);
  GtkWidget* weak_child = child;
  g_object_add_weak_pointer(G_OBJECT(child),
                            reinterpret_cast<gpointer*>(&weak_child));
  GtkWidget* wrapper = fl_graphics_offload_gtk4_wrap(child, api, TRUE);
  g_object_ref_sink(wrapper);
  EXPECT_NE(wrapper, child);
  EXPECT_EQ(gtk_widget_get_parent(child), wrapper);
  EXPECT_EQ(gtk_accessible_get_accessible_role(GTK_ACCESSIBLE(wrapper)),
            GTK_ACCESSIBLE_ROLE_PRESENTATION);
  EXPECT_FALSE(gtk_test_accessible_has_property(GTK_ACCESSIBLE(wrapper),
                                                GTK_ACCESSIBLE_PROPERTY_LABEL));
  for (GtkOrientation orientation :
       {GTK_ORIENTATION_HORIZONTAL, GTK_ORIENTATION_VERTICAL}) {
    int minimum = -1;
    int natural = -1;
    gtk_widget_measure(wrapper, orientation, -1, &minimum, &natural, nullptr,
                       nullptr);
    EXPECT_EQ(minimum, orientation == GTK_ORIENTATION_HORIZONTAL ? 200 : 100);
    EXPECT_EQ(natural, minimum);
  }
  g_object_unref(wrapper);
  EXPECT_EQ(weak_child, nullptr);
}

TEST_F(FlGraphicsOffloadGtk4Test, VulkanViewRequestsOffloadOnWayland) {
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  if (!fl_gtk_runtime_supports_dmabuf_textures() ||
      api->gtk_graphics_offload_get_type == nullptr ||
      g_strcmp0(g_getenv("FLUTTER_GTK4_ENABLE_DMABUF"), "0") == 0) {
    GTEST_SKIP() << "Requires enabled DMA-BUF and graphics offload APIs";
  }
  g_autofree gchar* renderer = g_strdup(g_getenv("FLUTTER_LINUX_RENDERER"));
  g_setenv("FLUTTER_LINUX_RENDERER", "vulkan", TRUE);
  g_autoptr(FlView) view = fl_view_new(project);
  if (renderer == nullptr) {
    g_unsetenv("FLUTTER_LINUX_RENDERER");
  } else {
    g_setenv("FLUTTER_LINUX_RENDERER", renderer, TRUE);
  }
  g_object_ref_sink(view);

  GtkWidget* parent = gtk_widget_get_parent(view->render_area);
  if (GDK_IS_WAYLAND_DISPLAY(gtk_widget_get_display(GTK_WIDGET(view)))) {
    EXPECT_EQ(G_OBJECT_TYPE(parent), api->gtk_graphics_offload_get_type());
  } else {
    EXPECT_EQ(parent, GTK_WIDGET(view));
  }
}

TEST_F(FlGraphicsOffloadGtk4Test, ViewRetainsRenderWidgetInsideWrapper) {
  if (!fl_gtk_runtime_api_get()->gtk_at_least_4_14) {
    GTEST_SKIP() << "Graphics offload needs GTK 4.14";
  }
  g_setenv("FLUTTER_GTK4_ENABLE_GRAPHICS_OFFLOAD", "1", TRUE);
  g_autoptr(FlView) view = fl_view_new(project);
  g_object_ref_sink(view);
  GtkWidget* wrapper = gtk_widget_get_parent(view->render_area);
  ASSERT_NE(wrapper, GTK_WIDGET(view));
  EXPECT_EQ(gtk_widget_get_parent(wrapper), GTK_WIDGET(view));
  EXPECT_EQ(gtk_widget_get_first_child(wrapper), view->render_area);
  EXPECT_TRUE(FL_IS_RENDER_TEXTURE_GTK4(view->render_area));
  EXPECT_EQ(gtk_accessible_get_accessible_role(GTK_ACCESSIBLE(wrapper)),
            GTK_ACCESSIBLE_ROLE_PRESENTATION);
}

}  // namespace

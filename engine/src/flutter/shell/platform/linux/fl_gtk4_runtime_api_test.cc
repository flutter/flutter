// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_gtk4_runtime_api.h"

#include "flutter/testing/testing.h"

namespace {

bool GtkRuntimeAtLeast(int major, int minor, int micro) {
  return gtk_check_version(major, minor, micro) == nullptr;
}

TEST(FlGtk4RuntimeApiTest, CapabilitiesMatchLoadedGtk) {
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();

  EXPECT_EQ(api->gtk_at_least_4_10, GtkRuntimeAtLeast(4, 10, 0));
  EXPECT_EQ(api->gtk_at_least_4_14, GtkRuntimeAtLeast(4, 14, 0));
  EXPECT_EQ(api->gtk_accessible_set_accessible_parent != nullptr,
            GtkRuntimeAtLeast(4, 10, 0));
  EXPECT_EQ(api->gtk_accessible_get_first_accessible_child != nullptr,
            GtkRuntimeAtLeast(4, 10, 0));
  EXPECT_EQ(api->gtk_accessible_announce != nullptr,
            GtkRuntimeAtLeast(4, 14, 0));
  EXPECT_EQ(api->gtk_accessible_text_get_type != nullptr,
            GtkRuntimeAtLeast(4, 14, 0));
  EXPECT_EQ(api->gtk_accessible_text_update_caret_position != nullptr,
            GtkRuntimeAtLeast(4, 14, 0));
  EXPECT_EQ(api->gtk_accessible_text_update_selection_bound != nullptr,
            GtkRuntimeAtLeast(4, 14, 0));
  EXPECT_EQ(api->gtk_accessible_text_update_contents != nullptr,
            GtkRuntimeAtLeast(4, 14, 0));
  EXPECT_EQ(fl_gtk_runtime_supports_native_accessibility_tree(),
            GtkRuntimeAtLeast(4, 10, 0));
  EXPECT_EQ(fl_gtk_runtime_supports_native_accessibility_text(),
            GtkRuntimeAtLeast(4, 14, 0));
  EXPECT_EQ(fl_gtk_runtime_supports_dmabuf_textures(),
            GtkRuntimeAtLeast(4, 14, 0));

  const bool supports_dmabuf = GtkRuntimeAtLeast(4, 14, 0);
  EXPECT_EQ(api->gdk_display_get_dmabuf_formats != nullptr, supports_dmabuf);
  EXPECT_EQ(api->gdk_dmabuf_formats_contains != nullptr, supports_dmabuf);
  EXPECT_EQ(api->gdk_dmabuf_texture_builder_new != nullptr, supports_dmabuf);
  EXPECT_EQ(api->gdk_dmabuf_texture_builder_build != nullptr, supports_dmabuf);
}

TEST(FlGtk4RuntimeApiTest, MissingOptionalFunctionsUseNoOpFallback) {
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();

  if (api->gtk_accessible_set_accessible_parent == nullptr) {
    fl_gtk_runtime_accessible_set_accessible_parent(nullptr, nullptr, nullptr);
  }
  if (api->gtk_accessible_get_first_accessible_child == nullptr) {
    EXPECT_EQ(fl_gtk_runtime_accessible_get_first_accessible_child(nullptr),
              nullptr);
  }
  if (api->gtk_accessible_announce == nullptr) {
    fl_gtk_runtime_accessible_announce(nullptr, "test announcement", 0);
  }
  if (!fl_gtk_runtime_supports_native_accessibility_text()) {
    EXPECT_EQ(fl_gtk_runtime_accessible_text_get_type(), G_TYPE_INVALID);
    fl_gtk_runtime_accessible_text_update_caret_position(nullptr);
    fl_gtk_runtime_accessible_text_update_selection_bound(nullptr);
    fl_gtk_runtime_accessible_text_update_contents(nullptr, 0, 0, 0);
  }
}

}  // namespace

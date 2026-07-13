// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_view_gtk4_accessibility.h"

#include "flutter/shell/platform/linux/fl_gtk4_runtime_api.h"
#include "flutter/shell/platform/linux/fl_view_private.h"
#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "flutter/testing/testing.h"

namespace {

class FlViewGtk4AccessibilityTest : public flutter::testing::LinuxTest {};

TEST_F(FlViewGtk4AccessibilityTest, BuildsNativeTreeFromSemantics) {
  if (!fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing()) {
    GTEST_SKIP() << "Native GtkAccessible traversal requires GTK 4.10+";
  }

  FlView* view = fl_view_new(project);
  ASSERT_NE(view->accessibility_backend, nullptr);

  int32_t children[] = {1, 2, 3};
  FlutterSemanticsFlags root_flags = {};
  FlutterSemanticsFlags button_flags = {};
  button_flags.is_button = kFlutterTristateTrue;
  FlutterSemanticsFlags toggle_flags = {};
  toggle_flags.is_toggled = kFlutterTristateTrue;
  FlutterSemanticsFlags label_flags = {};
  FlutterSemanticsNode2 root = {
      .id = 0,
      .label = "root",
      .child_count = 3,
      .children_in_traversal_order = children,
      .flags2 = &root_flags,
  };
  FlutterSemanticsNode2 button = {
      .id = 1,
      .label = "button",
      .rect = {.left = 4, .top = 6, .right = 24, .bottom = 36},
      .flags2 = &button_flags,
  };
  FlutterSemanticsNode2 toggle = {
      .id = 2,
      .label = "toggle",
      .flags2 = &toggle_flags,
  };
  FlutterSemanticsNode2 label = {
      .id = 3,
      .label = "label",
      .flags2 = &label_flags,
  };
  FlutterSemanticsNode2* nodes[] = {&root, &button, &toggle, &label};
  FlutterSemanticsUpdate2 update = {
      .node_count = 4,
      .nodes = nodes,
      .view_id = fl_view_get_id(view),
  };

  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);

  g_autoptr(GtkAccessible) native_root =
      fl_view_gtk4_accessibility_ref_native_root_for_testing(
          view->accessibility_backend);
  ASSERT_NE(native_root, nullptr);
  EXPECT_EQ(gtk_accessible_get_accessible_role(native_root),
            GTK_ACCESSIBLE_ROLE_GROUP);

  g_autoptr(GtkAccessible) renderer_child =
      fl_gtk_runtime_accessible_get_first_accessible_child(
          GTK_ACCESSIBLE(view->renderer));
  ASSERT_NE(renderer_child, nullptr);
  EXPECT_EQ(renderer_child, native_root);

  g_autoptr(GtkAccessible) first_child =
      fl_view_gtk4_accessibility_ref_first_native_child_for_testing(
          native_root);
  ASSERT_NE(first_child, nullptr);
  EXPECT_EQ(gtk_accessible_get_accessible_role(first_child),
            GTK_ACCESSIBLE_ROLE_BUTTON);

  int x = 0;
  int y = 0;
  int width = 0;
  int height = 0;
  EXPECT_TRUE(fl_view_gtk4_accessibility_get_native_bounds_for_testing(
      first_child, &x, &y, &width, &height));
  EXPECT_EQ(x, 4);
  EXPECT_EQ(y, 6);
  EXPECT_EQ(width, 20);
  EXPECT_EQ(height, 30);

  g_autoptr(GtkAccessible) second_child =
      fl_view_gtk4_accessibility_ref_next_native_sibling_for_testing(
          first_child);
  ASSERT_NE(second_child, nullptr);
  EXPECT_EQ(gtk_accessible_get_accessible_role(second_child),
            static_cast<GtkAccessibleRole>(GTK_ACCESSIBLE_ROLE_WINDOW + 1));

  g_autoptr(GtkAccessible) third_child =
      fl_view_gtk4_accessibility_ref_next_native_sibling_for_testing(
          second_child);
  ASSERT_NE(third_child, nullptr);
  EXPECT_EQ(gtk_accessible_get_accessible_role(third_child),
            GTK_ACCESSIBLE_ROLE_LABEL);
  EXPECT_EQ(fl_view_gtk4_accessibility_ref_next_native_sibling_for_testing(
                third_child),
            nullptr);
}

}  // namespace

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include "flutter/shell/platform/linux/fl_view_gtk4_accessibility.h"

#include <cstring>

#include "flutter/shell/platform/linux/fl_gtk4_runtime_api.h"
#include "flutter/shell/platform/linux/fl_render_texture_gtk4.h"
#include "flutter/shell/platform/linux/fl_renderable.h"
#include "flutter/shell/platform/linux/fl_view_private.h"
#include "flutter/shell/platform/linux/testing/fl_test_gtk_logs.h"
#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "flutter/testing/testing.h"

namespace {

class FlViewGtk4AccessibilityTest : public flutter::testing::LinuxTest {};

TEST_F(FlViewGtk4AccessibilityTest, PresentBeforeRealizeDoesNotWarn) {
  FlView* view = fl_view_new(project);
  ASSERT_NE(view, nullptr);

  flutter::testing::fl_reset_received_gtk_log_levels();
  fl_renderable_present_layers(FL_RENDERABLE(view), nullptr, 0);

  EXPECT_FALSE(flutter::testing::fl_has_received_gtk_log_level(
      static_cast<GLogLevelFlags>(G_LOG_LEVEL_WARNING | G_LOG_LEVEL_CRITICAL)));
}

TEST_F(FlViewGtk4AccessibilityTest, BuildsNativeTreeFromSemantics) {
  if (!fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing()) {
    GTEST_SKIP() << "Native GtkAccessible traversal requires GTK 4.10+";
  }

  FlView* view = fl_view_new(project);
  ASSERT_NE(view->accessibility_backend, nullptr);

  int32_t children[] = {1, 2, 3, 4};
  FlutterSemanticsFlags root_flags = {};
  FlutterSemanticsFlags button_flags = {};
  button_flags.is_button = kFlutterTristateTrue;
  button_flags.is_selected = kFlutterTristateTrue;
  FlutterSemanticsFlags toggle_flags = {};
  toggle_flags.is_toggled = kFlutterTristateTrue;
  toggle_flags.is_expanded = kFlutterTristateTrue;
  FlutterSemanticsFlags label_flags = {};
  FlutterSemanticsFlags read_only_text_flags = {};
  read_only_text_flags.is_text_field = true;
  read_only_text_flags.is_read_only = true;
  read_only_text_flags.is_multiline = true;
  FlutterSemanticsNode2 root = {
      .id = 0,
      .label = "root",
      .child_count = 4,
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
  FlutterSemanticsNode2 read_only_text = {
      .id = 4,
      .text_selection_base = 1,
      .text_selection_extent = 4,
      .label = "read-only text",
      .value = "one two",
      .flags2 = &read_only_text_flags,
  };
  FlutterSemanticsNode2* nodes[] = {&root, &button, &toggle, &label,
                                    &read_only_text};
  FlutterSemanticsUpdate2 update = {
      .node_count = 5,
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

  g_autoptr(GtkAccessible) exported_root =
      fl_gtk_runtime_accessible_get_first_accessible_child(
          GTK_ACCESSIBLE(view->render_area));
  EXPECT_EQ(exported_root, native_root);

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

  FlutterSemanticsNode2 updated_button = button;
  updated_button.label = "updated button";
  FlutterSemanticsNode2* updated_nodes[] = {&updated_button};
  FlutterSemanticsUpdate2 updated_update = {
      .node_count = 1,
      .nodes = updated_nodes,
      .view_id = fl_view_get_id(view),
  };
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &updated_update);

  g_autoptr(GtkAccessible) updated_root =
      fl_view_gtk4_accessibility_ref_native_root_for_testing(
          view->accessibility_backend);
  EXPECT_EQ(updated_root, native_root);
  g_autoptr(GtkAccessible) updated_first_child =
      fl_view_gtk4_accessibility_ref_first_native_child_for_testing(
          updated_root);
  EXPECT_EQ(updated_first_child, first_child);

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
  g_autoptr(GtkAccessible) fourth_child =
      fl_view_gtk4_accessibility_ref_next_native_sibling_for_testing(
          third_child);
  ASSERT_NE(fourth_child, nullptr);
  EXPECT_EQ(gtk_accessible_get_accessible_role(fourth_child),
            GTK_ACCESSIBLE_ROLE_TEXT_BOX);
  EXPECT_EQ(fl_view_gtk4_accessibility_ref_next_native_sibling_for_testing(
                fourth_child),
            nullptr);

  if (fl_gtk_runtime_supports_native_accessibility_text()) {
    EXPECT_TRUE(g_type_is_a(G_OBJECT_TYPE(fourth_child),
                            fl_gtk_runtime_accessible_text_get_type()));
    g_autoptr(GBytes) text =
        fl_view_gtk4_accessibility_ref_native_text_for_testing(fourth_child);
    ASSERT_NE(text, nullptr);
    gsize text_length = 0;
    const gchar* text_data =
        static_cast<const gchar*>(g_bytes_get_data(text, &text_length));
    EXPECT_STREQ(text_data, "one two");
    EXPECT_EQ(text_length, std::strlen("one two"));
  }

  // Reordering and removal must preserve retained objects and repair sibling
  // links even when the children themselves are absent from the update.
  int32_t reordered[] = {2, 1};
  root.child_count = 2;
  root.children_in_traversal_order = reordered;
  FlutterSemanticsNode2* root_only[] = {&root};
  update.node_count = 1;
  update.nodes = root_only;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  g_autoptr(GtkAccessible) reordered_first =
      fl_view_gtk4_accessibility_ref_first_native_child_for_testing(
          native_root);
  EXPECT_EQ(reordered_first, second_child);
  g_autoptr(GtkAccessible) reordered_second =
      fl_view_gtk4_accessibility_ref_next_native_sibling_for_testing(
          second_child);
  EXPECT_EQ(reordered_second, first_child);
  EXPECT_EQ(fl_view_gtk4_accessibility_ref_next_native_sibling_for_testing(
                first_child),
            nullptr);
}

}  // namespace

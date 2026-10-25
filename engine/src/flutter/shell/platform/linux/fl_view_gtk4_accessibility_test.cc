// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include "flutter/shell/platform/linux/fl_view_gtk4_accessibility.h"

#include <cstring>

#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_gtk4_runtime_api.h"
#include "flutter/shell/platform/linux/fl_render_texture_gtk4.h"
#include "flutter/shell/platform/linux/fl_renderable.h"
#include "flutter/shell/platform/linux/fl_view_private.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_standard_message_codec.h"
#include "flutter/shell/platform/linux/testing/fl_test_gtk_logs.h"
#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "flutter/testing/testing.h"

namespace {

class FlViewGtk4AccessibilityTest : public flutter::testing::LinuxTest {};

TEST_F(FlViewGtk4AccessibilityTest, CheckAndPressStatesFollowControlRole) {
  if (!fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing()) {
    GTEST_SKIP() << "Native GtkAccessible traversal requires GTK 4.10+";
  }
  g_autoptr(FlView) view = fl_view_new(project);
  g_object_ref_sink(view);
  FlutterSemanticsFlags flags = {};
  FlutterSemanticsNode2 root = {};
  root.flags2 = &flags;
  root.label = "Control";
  FlutterSemanticsNode2* nodes[] = {&root};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = fl_view_get_id(view);
  update.node_count = 1;
  update.nodes = nodes;
  const auto check = [&](bool has_checked, GtkAccessibleTristate checked,
                         bool has_pressed, GtkAccessibleTristate pressed) {
    fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                             &update);
    g_autoptr(GtkAccessible) native =
        fl_view_gtk4_accessibility_ref_native_root_for_testing(
            view->accessibility_backend);
    ASSERT_NE(native, nullptr);
    EXPECT_EQ(
        gtk_test_accessible_has_state(native, GTK_ACCESSIBLE_STATE_CHECKED),
        has_checked);
    EXPECT_EQ(
        gtk_test_accessible_has_state(native, GTK_ACCESSIBLE_STATE_PRESSED),
        has_pressed);
    if (has_checked) {
      gtk_test_accessible_assert_state(native, GTK_ACCESSIBLE_STATE_CHECKED,
                                       checked);
    }
    if (has_pressed) {
      gtk_test_accessible_assert_state(native, GTK_ACCESSIBLE_STATE_PRESSED,
                                       pressed);
    }
  };
  check(false, GTK_ACCESSIBLE_TRISTATE_FALSE, false,
        GTK_ACCESSIBLE_TRISTATE_FALSE);
  flags.is_toggled = kFlutterTristateTrue;
  check(false, GTK_ACCESSIBLE_TRISTATE_FALSE, true,
        GTK_ACCESSIBLE_TRISTATE_TRUE);
  flags.is_toggled = kFlutterTristateFalse;
  check(false, GTK_ACCESSIBLE_TRISTATE_FALSE, true,
        GTK_ACCESSIBLE_TRISTATE_FALSE);
  // A checkbox's own checked state wins even with inconsistent toggle flags.
  flags.is_toggled = kFlutterTristateTrue;
  flags.is_checked = kFlutterCheckStateFalse;
  check(true, GTK_ACCESSIBLE_TRISTATE_FALSE, false,
        GTK_ACCESSIBLE_TRISTATE_FALSE);
  flags.is_checked = kFlutterCheckStateMixed;
  check(true, GTK_ACCESSIBLE_TRISTATE_MIXED, false,
        GTK_ACCESSIBLE_TRISTATE_FALSE);
  flags.is_in_mutually_exclusive_group = true;
  flags.is_checked = kFlutterCheckStateTrue;
  check(true, GTK_ACCESSIBLE_TRISTATE_TRUE, false,
        GTK_ACCESSIBLE_TRISTATE_FALSE);
  flags.is_checked = kFlutterCheckStateNone;
  flags.is_toggled = kFlutterTristateNone;
  check(false, GTK_ACCESSIBLE_TRISTATE_FALSE, false,
        GTK_ACCESSIBLE_TRISTATE_FALSE);
}

TEST_F(FlViewGtk4AccessibilityTest, ExplicitFocusStateWorksWithoutActions) {
  if (!fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing()) {
    GTEST_SKIP() << "Native GtkAccessible traversal requires GTK 4.10+";
  }
  g_autoptr(FlView) view = fl_view_new(project);
  g_object_ref_sink(view);
  FlutterSemanticsFlags flags = {};
  FlutterSemanticsNode2 root = {};
  root.flags2 = &flags;
  root.label = "Keyboard focus target";
  FlutterSemanticsNode2* nodes[] = {&root};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = fl_view_get_id(view);
  update.node_count = 1;
  update.nodes = nodes;
  const auto check = [&](bool focusable, bool focused) {
    fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                             &update);
    g_autoptr(GtkAccessible) native =
        fl_view_gtk4_accessibility_ref_native_root_for_testing(
            view->accessibility_backend);
    ASSERT_NE(native, nullptr);
    auto* iface = reinterpret_cast<FlGtkAccessibleInterface4_10*>(
        GTK_ACCESSIBLE_GET_IFACE(native));
    EXPECT_EQ(iface->get_platform_state(
                  native, FL_GTK_ACCESSIBLE_PLATFORM_STATE_FOCUSABLE),
              focusable);
    EXPECT_EQ(iface->get_platform_state(
                  native, FL_GTK_ACCESSIBLE_PLATFORM_STATE_FOCUSED),
              focused);
    EXPECT_EQ(iface->get_platform_state(
                  native, FL_GTK_ACCESSIBLE_PLATFORM_STATE_ACTIVE),
              focused);
  };
  check(false, false);
  flags.is_focused = kFlutterTristateFalse;
  check(true, false);
  flags.is_focused = kFlutterTristateTrue;
  check(true, true);
  flags.is_hidden = true;
  check(false, false);
  flags.is_hidden = false;
  check(true, true);
  flags.is_enabled = kFlutterTristateFalse;
  check(false, false);
  flags.is_enabled = kFlutterTristateTrue;
  flags.is_focused = kFlutterTristateFalse;
  check(true, false);
  flags.is_focused = kFlutterTristateNone;
  check(false, false);
  flags.is_button = true;
  root.actions = kFlutterSemanticsActionTap;
  check(true, false);
  flags.is_hidden = true;
  check(false, false);
}

TEST_F(FlViewGtk4AccessibilityTest, ViewNameUsesOnlyApplicationSemantics) {
  g_autoptr(FlView) view = fl_view_new(project);
  g_object_ref_sink(view);
  fl_view_gtk4_accessibility_update_accessible_name(
      view->accessibility_backend);
  EXPECT_FALSE(gtk_test_accessible_has_property(GTK_ACCESSIBLE(view),
                                                GTK_ACCESSIBLE_PROPERTY_LABEL));

  FlutterSemanticsFlags flags = {};
  FlutterSemanticsNode2 root = {};
  root.flags2 = &flags;
  root.label = "Application content";
  FlutterSemanticsNode2* nodes[] = {&root};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = fl_view_get_id(view);
  update.node_count = 1;
  update.nodes = nodes;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  gtk_test_accessible_assert_property(GTK_ACCESSIBLE(view),
                                      GTK_ACCESSIBLE_PROPERTY_LABEL,
                                      "Application content");

  root.label = "";
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  EXPECT_FALSE(gtk_test_accessible_has_property(GTK_ACCESSIBLE(view),
                                                GTK_ACCESSIBLE_PROPERTY_LABEL));
}

TEST_F(FlViewGtk4AccessibilityTest,
       StructuralContainersPreserveChildTraversal) {
  if (!fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing()) {
    GTEST_SKIP() << "Native GtkAccessible traversal requires GTK 4.10+";
  }
  g_autoptr(FlView) view = fl_view_new(project);
  g_object_ref_sink(view);
  int32_t children[] = {1};
  FlutterSemanticsFlags flags = {};
  FlutterSemanticsNode2 root = {};
  root.flags2 = &flags;
  root.child_count = 1;
  root.children_in_traversal_order = children;
  FlutterSemanticsNode2 child = {};
  child.id = 1;
  child.label = "Content";
  FlutterSemanticsNode2* nodes[] = {&root, &child};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = fl_view_get_id(view);
  update.node_count = 2;
  update.nodes = nodes;

  for (const char* label : {"", "Related controls", ""}) {
    root.label = label;
    fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                             &update);
    g_autoptr(GtkAccessible) native =
        fl_view_gtk4_accessibility_ref_native_root_for_testing(
            view->accessibility_backend);
    ASSERT_NE(native, nullptr);
    EXPECT_EQ(gtk_accessible_get_accessible_role(native),
              label[0] == '\0' ? GTK_ACCESSIBLE_ROLE_GENERIC
                               : GTK_ACCESSIBLE_ROLE_GROUP);
    g_autoptr(GtkAccessible) native_child =
        fl_gtk_runtime_accessible_get_first_accessible_child(native);
    ASSERT_NE(native_child, nullptr);
    gtk_test_accessible_assert_property(
        native_child, GTK_ACCESSIBLE_PROPERTY_LABEL, "Content");
    EXPECT_EQ(
        gtk_accessible_get_accessible_role(GTK_ACCESSIBLE(view->render_area)),
        GTK_ACCESSIBLE_ROLE_GENERIC);
  }
}

TEST_F(FlViewGtk4AccessibilityTest, ValueOnlyLeafExposesText) {
  if (!fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing()) {
    GTEST_SKIP() << "Native GtkAccessible traversal requires GTK 4.10+";
  }
  g_autoptr(FlView) view = fl_view_new(project);
  g_object_ref_sink(view);
  FlutterSemanticsFlags flags = {};
  FlutterSemanticsNode2 root = {};
  root.flags2 = &flags;
  root.value = "42 results";
  FlutterSemanticsNode2* nodes[] = {&root};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = fl_view_get_id(view);
  update.node_count = 1;
  update.nodes = nodes;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  g_autoptr(GtkAccessible) native =
      fl_view_gtk4_accessibility_ref_native_root_for_testing(
          view->accessibility_backend);
  ASSERT_NE(native, nullptr);
  EXPECT_EQ(gtk_accessible_get_accessible_role(native),
            GTK_ACCESSIBLE_ROLE_LABEL);
  gtk_test_accessible_assert_property(native, GTK_ACCESSIBLE_PROPERTY_LABEL,
                                      "42 results");

  flags.is_obscured = true;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  g_autoptr(GtkAccessible) protected_node =
      fl_view_gtk4_accessibility_ref_native_root_for_testing(
          view->accessibility_backend);
  ASSERT_NE(protected_node, nullptr);
  EXPECT_FALSE(gtk_test_accessible_has_property(protected_node,
                                                GTK_ACCESSIBLE_PROPERTY_LABEL));
  EXPECT_FALSE(gtk_test_accessible_has_property(
      protected_node, GTK_ACCESSIBLE_PROPERTY_VALUE_TEXT));
}

TEST_F(FlViewGtk4AccessibilityTest, ButtonRoleTakesPrecedenceOverPresentation) {
  if (!fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing()) {
    GTEST_SKIP() << "Native GtkAccessible traversal requires GTK 4.10+";
  }
  g_autoptr(FlView) view = fl_view_new(project);
  g_object_ref_sink(view);
  FlutterSemanticsFlags flags = {};
  flags.is_button = true;
  FlutterSemanticsNode2 root = {};
  root.flags2 = &flags;
  root.label = "Open photo";
  root.actions = kFlutterSemanticsActionTap;
  FlutterSemanticsNode2* nodes[] = {&root};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = fl_view_get_id(view);
  update.node_count = 1;
  update.nodes = nodes;
  for (bool is_image : {true, false}) {
    flags.is_image = is_image;
    flags.is_header = !is_image;
    fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                             &update);
    g_autoptr(GtkAccessible) native =
        fl_view_gtk4_accessibility_ref_native_root_for_testing(
            view->accessibility_backend);
    ASSERT_NE(native, nullptr);
    EXPECT_EQ(gtk_accessible_get_accessible_role(native),
              GTK_ACCESSIBLE_ROLE_BUTTON);
    gtk_test_accessible_assert_property(native, GTK_ACCESSIBLE_PROPERTY_LABEL,
                                        "Open photo");
  }
}

TEST_F(FlViewGtk4AccessibilityTest, ScrollContainersPreserveRoleAcrossUpdates) {
  if (!fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing()) {
    GTEST_SKIP() << "Native GtkAccessible traversal requires GTK 4.10+";
  }
  g_autoptr(FlView) view = fl_view_new(project);
  g_object_ref_sink(view);
  FlutterSemanticsFlags flags = {};
  FlutterSemanticsNode2 root = {};
  root.flags2 = &flags;
  root.label = "Scroll region";
  FlutterSemanticsNode2 child = {};
  child.id = 1;
  child.label = "Content";
  FlutterSemanticsNode2* nodes[] = {&root, &child};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = fl_view_get_id(view);
  update.node_count = 1;
  update.nodes = nodes;
  const auto apply = [&]() {
    fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                             &update);
    return fl_view_gtk4_accessibility_ref_native_root_for_testing(
        view->accessibility_backend);
  };

  // An ordinary label retains its text role.
  g_autoptr(GtkAccessible) label = apply();
  EXPECT_EQ(gtk_accessible_get_accessible_role(label),
            GTK_ACCESSIBLE_ROLE_LABEL);
  root.actions = kFlutterSemanticsActionScrollDown;
  g_autoptr(GtkAccessible) container = apply();
  EXPECT_EQ(gtk_accessible_get_accessible_role(container),
            GTK_ACCESSIBLE_ROLE_GROUP);
  EXPECT_NE(container, label);
  const FlutterSemanticsAction directions[] = {
      kFlutterSemanticsActionScrollUp, kFlutterSemanticsActionScrollLeft,
      kFlutterSemanticsActionScrollRight};
  for (auto direction : directions) {
    root.actions = direction;
    g_autoptr(GtkAccessible) current = apply();
    EXPECT_EQ(current, container);
  }

  // Reaching a boundary can remove directional actions; implicit scrolling
  // still identifies a container. Adding children must not replace it either.
  root.actions = static_cast<FlutterSemanticsAction>(0);
  flags.has_implicit_scrolling = true;
  g_autoptr(GtkAccessible) boundary = apply();
  EXPECT_EQ(boundary, container);
  int32_t child_id = 1;
  root.child_count = 1;
  root.children_in_traversal_order = &child_id;
  update.node_count = 2;
  g_autoptr(GtkAccessible) populated = apply();
  EXPECT_EQ(populated, container);
  g_autoptr(GtkAccessible) native_child =
      fl_gtk_runtime_accessible_get_first_accessible_child(populated);
  ASSERT_NE(native_child, nullptr);

  // Explicit control semantics take precedence over scrolling capability.
  flags.is_text_field = true;
  g_autoptr(GtkAccessible) editor = apply();
  EXPECT_EQ(gtk_accessible_get_accessible_role(editor),
            GTK_ACCESSIBLE_ROLE_TEXT_BOX);
  flags.is_text_field = false;
  flags.is_button = true;
  g_autoptr(GtkAccessible) button = apply();
  EXPECT_EQ(gtk_accessible_get_accessible_role(button),
            GTK_ACCESSIBLE_ROLE_BUTTON);
}

TEST_F(FlViewGtk4AccessibilityTest, OptionalStatesPreserveUndefined) {
  if (!fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing()) {
    GTEST_SKIP() << "Native GtkAccessible traversal requires GTK 4.10+";
  }
  g_autoptr(FlView) view = fl_view_new(project);
  g_object_ref_sink(view);
  FlutterSemanticsFlags flags = {};
  FlutterSemanticsNode2 root = {};
  root.flags2 = &flags;
  FlutterSemanticsNode2* nodes[] = {&root};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = fl_view_get_id(view);
  update.node_count = 1;
  update.nodes = nodes;
  const struct {
    FlutterTristate selected;
    FlutterTristate expanded;
  } cases[] = {
      {kFlutterTristateNone, kFlutterTristateNone},
      {kFlutterTristateFalse, kFlutterTristateNone},
      {kFlutterTristateTrue, kFlutterTristateFalse},
      {kFlutterTristateNone, kFlutterTristateTrue},
      {kFlutterTristateNone, kFlutterTristateNone},
  };
  for (const auto& test : cases) {
    SCOPED_TRACE(testing::Message() << "selected=" << test.selected
                                    << " expanded=" << test.expanded);
    flags.is_selected = test.selected;
    flags.is_expanded = test.expanded;
    fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                             &update);
    g_autoptr(GtkAccessible) native =
        fl_view_gtk4_accessibility_ref_native_root_for_testing(
            view->accessibility_backend);
    ASSERT_NE(native, nullptr);
    const auto check = [&](GtkAccessibleState state, FlutterTristate value) {
      EXPECT_EQ(gtk_test_accessible_has_state(native, state),
                value != kFlutterTristateNone);
      if (value != kFlutterTristateNone) {
        g_autofree gchar* mismatch = gtk_test_accessible_check_state(
            native, state, value == kFlutterTristateTrue);
        EXPECT_EQ(mismatch, nullptr);
      }
    };
    check(GTK_ACCESSIBLE_STATE_SELECTED, test.selected);
    check(GTK_ACCESSIBLE_STATE_EXPANDED, test.expanded);
  }
}

TEST_F(FlViewGtk4AccessibilityTest, NativeActionsRespectCurrentSemantics) {
  if (!fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing()) {
    GTEST_SKIP() << "Native GtkAccessible traversal requires GTK 4.10+";
  }
  g_autoptr(FlView) primary_view = fl_view_new(project);
  g_object_ref_sink(primary_view);
  FlEngine* view_engine = fl_view_get_engine(primary_view);
  StartEngine(view_engine);
  g_autoptr(FlView) view = fl_view_new_for_engine(view_engine);
  g_object_ref_sink(view);
  size_t calls = 0;
  FlutterSemanticsAction expected = kFlutterSemanticsActionTap;
  const FlutterViewId view_id = fl_view_get_id(view);
  ASSERT_NE(view_id, 0);
  fl_engine_get_embedder_api(view_engine)->SendSemanticsAction =
      MOCK_ENGINE_PROC(SendSemanticsAction,
                       ([&](auto, const FlutterSendSemanticsActionInfo* info) {
                         EXPECT_EQ(info->view_id, view_id);
                         EXPECT_EQ(info->node_id, 42u);
                         EXPECT_EQ(info->action, expected);
                         EXPECT_EQ(info->data_length, 0u);
                         calls++;
                         return kSuccess;
                       }));
  int32_t children[] = {42};
  FlutterSemanticsNode2 root = {};
  root.child_count = 1;
  root.children_in_traversal_order = children;
  FlutterSemanticsFlags flags = {};
  flags.is_button = true;
  FlutterSemanticsNode2 button = {};
  button.id = 42;
  button.actions = static_cast<FlutterSemanticsAction>(
      kFlutterSemanticsActionTap | kFlutterSemanticsActionLongPress);
  button.flags2 = &flags;
  FlutterSemanticsNode2* nodes[] = {&root, &button};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = view_id;
  update.node_count = 2;
  update.nodes = nodes;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  g_autoptr(GtkAccessible) native_root =
      fl_view_gtk4_accessibility_ref_native_root_for_testing(
          view->accessibility_backend);
  g_autoptr(GtkAccessible) native_button =
      fl_view_gtk4_accessibility_ref_first_native_child_for_testing(
          native_root);
  ASSERT_TRUE(GTK_IS_WIDGET(native_button));
  GtkWidget* widget = GTK_WIDGET(native_button);
  EXPECT_EQ(gtk_widget_get_parent(widget), view->render_area);
  EXPECT_FALSE(gtk_widget_get_child_visible(widget));
  EXPECT_FALSE(gtk_widget_get_mapped(widget));
  EXPECT_FALSE(gtk_widget_get_can_target(widget));
  EXPECT_TRUE(gtk_widget_activate_action(widget, "flutter.tap", nullptr));
  EXPECT_EQ(calls, 1u);
  expected = kFlutterSemanticsActionLongPress;
  EXPECT_TRUE(
      gtk_widget_activate_action(widget, "flutter.long-press", nullptr));
  EXPECT_EQ(calls, 2u);

  // Action removal, disabled and hidden semantics must all block dispatch.
  button.actions = kFlutterSemanticsActionTap;
  update.node_count = 1;
  update.nodes = &nodes[1];
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  gtk_widget_activate_action(widget, "flutter.long-press", nullptr);
  flags.is_enabled = kFlutterTristateFalse;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  gtk_widget_activate_action(widget, "flutter.tap", nullptr);
  flags.is_enabled = kFlutterTristateTrue;
  flags.is_hidden = true;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  gtk_widget_activate_action(widget, "flutter.tap", nullptr);
  EXPECT_EQ(calls, 2u);

  flags.is_hidden = false;
  expected = kFlutterSemanticsActionTap;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  EXPECT_TRUE(gtk_widget_activate_action(widget, "flutter.tap", nullptr));
  EXPECT_EQ(calls, 3u);
  g_object_run_dispose(G_OBJECT(view));
  gtk_widget_activate_action(widget, "flutter.tap", nullptr);
  EXPECT_EQ(calls, 3u);
}

TEST_F(FlViewGtk4AccessibilityTest,
       ParameterlessActionsRespectCurrentSemantics) {
  if (!fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing()) {
    GTEST_SKIP() << "Native GtkAccessible traversal requires GTK 4.10+";
  }
  g_autoptr(FlView) primary = fl_view_new(project);
  g_object_ref_sink(primary);
  FlEngine* engine = fl_view_get_engine(primary);
  StartEngine(engine);
  g_autoptr(FlView) view = fl_view_new_for_engine(engine);
  g_object_ref_sink(view);
  ASSERT_NE(fl_view_get_id(view), 0);
  const struct {
    const char* name;
    FlutterSemanticsAction action;
  } actions[] = {
      {"flutter.scroll-left", kFlutterSemanticsActionScrollLeft},
      {"flutter.scroll-right", kFlutterSemanticsActionScrollRight},
      {"flutter.scroll-up", kFlutterSemanticsActionScrollUp},
      {"flutter.scroll-down", kFlutterSemanticsActionScrollDown},
      {"flutter.increase", kFlutterSemanticsActionIncrease},
      {"flutter.decrease", kFlutterSemanticsActionDecrease},
      {"flutter.show-on-screen", kFlutterSemanticsActionShowOnScreen},
      {"flutter.dismiss", kFlutterSemanticsActionDismiss},
      {"flutter.focus", kFlutterSemanticsActionFocus},
      {"flutter.expand", kFlutterSemanticsActionExpand},
      {"flutter.collapse", kFlutterSemanticsActionCollapse},
  };
  size_t calls = 0;
  FlutterSemanticsAction expected = kFlutterSemanticsActionScrollLeft;
  fl_engine_get_embedder_api(engine)->SendSemanticsAction =
      MOCK_ENGINE_PROC(SendSemanticsAction,
                       ([&](auto, const FlutterSendSemanticsActionInfo* info) {
                         EXPECT_EQ(info->view_id, fl_view_get_id(view));
                         EXPECT_EQ(info->node_id, 0u);
                         EXPECT_EQ(info->action, expected);
                         EXPECT_EQ(info->data_length, 0u);
                         calls++;
                         return kSuccess;
                       }));
  FlutterSemanticsFlags flags = {};
  // Keep the container role stable while individual scroll actions disappear.
  flags.has_implicit_scrolling = true;
  FlutterSemanticsNode2 root = {};
  root.flags2 = &flags;
  FlutterSemanticsNode2* nodes[] = {&root};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = fl_view_get_id(view);
  update.node_count = 1;
  update.nodes = nodes;
  const auto apply_update = [&]() {
    fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                             &update);
  };
  apply_update();
  g_autoptr(GtkAccessible) native =
      fl_view_gtk4_accessibility_ref_native_root_for_testing(
          view->accessibility_backend);
  ASSERT_TRUE(GTK_IS_WIDGET(native));
  GtkWidget* widget = GTK_WIDGET(native);
  for (const auto& action : actions) {
    SCOPED_TRACE(action.name);
    expected = action.action;
    root.actions = action.action;
    apply_update();
    const size_t before = calls;
    EXPECT_TRUE(gtk_widget_activate_action(widget, action.name, nullptr));
    EXPECT_EQ(calls, before + 1);
    for (const auto& other : actions) {
      if (other.action != action.action) {
        gtk_widget_activate_action(widget, other.name, nullptr);
      }
    }
    root.actions = static_cast<FlutterSemanticsAction>(0);
    apply_update();
    gtk_widget_activate_action(widget, action.name, nullptr);
    root.actions = action.action;
    flags.is_enabled = kFlutterTristateFalse;
    apply_update();
    gtk_widget_activate_action(widget, action.name, nullptr);
    flags.is_enabled = kFlutterTristateTrue;
    flags.is_hidden = true;
    apply_update();
    gtk_widget_activate_action(widget, action.name, nullptr);
    EXPECT_EQ(calls, before + 1);
    flags.is_hidden = false;
  }
  // Re-enable every action before disposal to exercise lifetime gating.
  for (const auto& action : actions) {
    root.actions =
        static_cast<FlutterSemanticsAction>(root.actions | action.action);
  }
  apply_update();
  const size_t before = calls;
  g_object_run_dispose(G_OBJECT(view));
  for (const auto& action : actions) {
    gtk_widget_activate_action(widget, action.name, nullptr);
  }
  EXPECT_EQ(calls, before);
}

TEST_F(FlViewGtk4AccessibilityTest,
       NativeProxyUsesSurfaceLifecycleWithoutLayout) {
  if (!fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing()) {
    GTEST_SKIP() << "Native GtkAccessible traversal requires GTK 4.10+";
  }
  g_autoptr(FlView) view = fl_view_new(project);
  g_object_ref_sink(view);
  GtkWidget* surface = view->render_area;
  int minimum_before = 0;
  int natural_before = 0;
  gtk_widget_measure(surface, GTK_ORIENTATION_HORIZONTAL, -1, &minimum_before,
                     &natural_before, nullptr, nullptr);
  FlutterSemanticsFlags flags = {};
  flags.is_button = true;
  FlutterSemanticsNode2 root = {};
  root.rect.right = 10000;
  root.rect.bottom = 10000;
  root.flags2 = &flags;
  FlutterSemanticsNode2* nodes[] = {&root};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = fl_view_get_id(view);
  update.node_count = 1;
  update.nodes = nodes;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  g_autoptr(GtkAccessible) native =
      fl_view_gtk4_accessibility_ref_native_root_for_testing(
          view->accessibility_backend);
  ASSERT_NE(native, nullptr);
  GtkWidget* proxy = GTK_WIDGET(native);
  EXPECT_EQ(gtk_widget_get_parent(proxy), surface);
  EXPECT_FALSE(gtk_widget_get_child_visible(proxy));
  EXPECT_FALSE(gtk_widget_get_can_target(proxy));
  EXPECT_FALSE(gtk_widget_get_focusable(proxy));
  EXPECT_FALSE(gtk_widget_get_realized(proxy));
  int minimum_after = 0;
  int natural_after = 0;
  gtk_widget_measure(surface, GTK_ORIENTATION_HORIZONTAL, -1, &minimum_after,
                     &natural_after, nullptr, nullptr);
  EXPECT_EQ(minimum_after, minimum_before);
  EXPECT_EQ(natural_after, natural_before);

  // Exercise the real surface lifecycle without starting Flutter GL rendering.
  g_object_ref(surface);
  g_signal_handlers_disconnect_by_data(surface, view);
  gtk_box_remove(GTK_BOX(view), surface);
  g_autoptr(GtkWindow) window = GTK_WINDOW(gtk_window_new());
  g_object_ref_sink(window);
  gtk_window_set_child(window, surface);
  gtk_window_present(window);
  EXPECT_TRUE(gtk_widget_get_realized(proxy));
  EXPECT_FALSE(gtk_widget_get_mapped(proxy));
  EXPECT_EQ(gtk_widget_get_width(proxy), 0);
  EXPECT_EQ(gtk_widget_get_height(proxy), 0);
  // Replacement after realization must acquire the same lifecycle immediately.
  flags.is_button = false;
  flags.is_header = true;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  g_autoptr(GtkAccessible) replacement =
      fl_view_gtk4_accessibility_ref_native_root_for_testing(
          view->accessibility_backend);
  ASSERT_NE(replacement, native);
  EXPECT_EQ(gtk_widget_get_parent(proxy), nullptr);
  EXPECT_FALSE(gtk_widget_get_realized(proxy));
  proxy = GTK_WIDGET(replacement);
  EXPECT_TRUE(gtk_widget_get_realized(proxy));
  EXPECT_FALSE(gtk_widget_get_child_visible(proxy));
  EXPECT_FALSE(gtk_widget_get_mapped(proxy));
  gtk_widget_unrealize(surface);
  EXPECT_FALSE(gtk_widget_get_realized(proxy));
  gtk_widget_realize(surface);
  EXPECT_TRUE(gtk_widget_get_realized(proxy));
  EXPECT_FALSE(gtk_widget_get_mapped(proxy));
  gtk_window_set_child(window, nullptr);
  gtk_box_append(GTK_BOX(view), surface);
  g_object_unref(surface);
  gtk_window_destroy(window);

  g_object_run_dispose(G_OBJECT(view));
  EXPECT_EQ(gtk_widget_get_parent(proxy), nullptr);
  EXPECT_FALSE(gtk_widget_get_realized(proxy));
}

// Run with the external AT-SPI client; ordinary unit runs do not require a bus.
TEST_F(FlViewGtk4AccessibilityTest, ExternalAtspiActivation) {
  if (g_strcmp0(g_getenv("FLUTTER_TEST_ATSPI_ACTION"), "1") != 0) {
    GTEST_SKIP() << "Requires an external AT-SPI action client";
  }
  ASSERT_TRUE(fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing());
  g_autoptr(FlView) view = fl_view_new(project);
  g_object_ref_sink(view);
  FlEngine* view_engine = fl_view_get_engine(view);
  StartEngine(view_engine);
  size_t calls = 0;
  const FlutterViewId view_id = fl_view_get_id(view);
  const bool check_focus =
      g_strcmp0(g_getenv("FLUTTER_TEST_ATSPI_FOCUS"), "1") == 0;
  if (check_focus) {
    ASSERT_EQ(gtk_check_version(4, 18, 0), nullptr);
  }
  FlutterSemanticsFlags flags = {};
  flags.is_button = true;
  FlutterSemanticsNode2 button = {};
  button.label = "Flutter AT-SPI activation fixture";
  button.actions = kFlutterSemanticsActionTap;
  button.flags2 = &flags;
  const bool check_text =
      g_strcmp0(g_getenv("FLUTTER_TEST_ATSPI_TEXT"), "1") == 0;
  const bool check_selection =
      g_strcmp0(g_getenv("FLUTTER_TEST_ATSPI_SELECTION"), "1") == 0;
  if (check_selection) {
    ASSERT_TRUE(check_text);
    ASSERT_EQ(gtk_check_version(4, 22, 0), nullptr);
  }
  if (check_text) {
    ASSERT_TRUE(fl_gtk_runtime_supports_native_accessibility_text());
  }
  FlutterSemanticsFlags text_flags = {};
  text_flags.is_text_field = true;
  FlutterSemanticsNode2 text = {};
  text.id = 1;
  text.flags2 = &text_flags;
  text.label = "Flutter AT-SPI text fixture";
  text.value = "A\xF0\x9F\x98\x80 caf\xC3\xA9. Next sentence!\nFinal";
  text.text_selection_base = 1;
  text.text_selection_extent = 3;
  if (check_selection) {
    text.actions = kFlutterSemanticsActionSetSelection;
  }
  const FlutterSemanticsAction cursor_actions[] = {
      kFlutterSemanticsActionMoveCursorForwardByCharacter,
      kFlutterSemanticsActionMoveCursorBackwardByCharacter,
      kFlutterSemanticsActionMoveCursorForwardByWord,
      kFlutterSemanticsActionMoveCursorBackwardByWord,
  };
  for (const auto action : cursor_actions) {
    text.actions = static_cast<FlutterSemanticsAction>(text.actions | action);
  }
  const FlutterSemanticsAction adjustment_actions[] = {
      kFlutterSemanticsActionScrollLeft,   kFlutterSemanticsActionScrollRight,
      kFlutterSemanticsActionScrollUp,     kFlutterSemanticsActionScrollDown,
      kFlutterSemanticsActionIncrease,     kFlutterSemanticsActionDecrease,
      kFlutterSemanticsActionShowOnScreen, kFlutterSemanticsActionDismiss,
      kFlutterSemanticsActionFocus,        kFlutterSemanticsActionExpand,
      kFlutterSemanticsActionCollapse,     kFlutterSemanticsActionCopy,
      kFlutterSemanticsActionCut,          kFlutterSemanticsActionPaste,
  };
  FlutterSemanticsNode2 adjustment = {};
  adjustment.id = 2;
  adjustment.label = "Flutter AT-SPI adjustment fixture";
  for (const auto action : adjustment_actions) {
    adjustment.actions =
        static_cast<FlutterSemanticsAction>(adjustment.actions | action);
  }
  int32_t children[] = {2, 1};
  button.child_count = check_text ? 2 : 1;
  button.children_in_traversal_order = children;
  FlutterSemanticsNode2* nodes[] = {&button, &adjustment, &text};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = view_id;
  update.node_count = check_text ? 3 : 2;
  update.nodes = nodes;
  size_t text_updates = 0;
  size_t selection_calls = 0;
  size_t adjustment_calls = 0;
  size_t cursor_calls = 0;
  const gchar* text_values[] = {
      "New \xF0\x9F\x98\x80 text",
      "New \xF0\x9F\x98\x81 text",
      "New \xF0\x9F\x98\x81 added text",
      "New \xF0\x9F\x98\x81 text",
  };
  fl_engine_get_embedder_api(view_engine)
      ->SendSemanticsAction = MOCK_ENGINE_PROC(
      SendSemanticsAction,
      ([&](auto, const FlutterSendSemanticsActionInfo* info) {
        EXPECT_EQ(info->view_id, view_id);
        if (info->node_id == 1 &&
            info->action != kFlutterSemanticsActionSetSelection) {
          EXPECT_TRUE(check_text);
          EXPECT_LT(cursor_calls, G_N_ELEMENTS(cursor_actions));
          if (cursor_calls < G_N_ELEMENTS(cursor_actions)) {
            EXPECT_EQ(info->action, cursor_actions[cursor_calls]);
          }
          g_autoptr(GBytes) bytes = g_bytes_new(info->data, info->data_length);
          g_autoptr(FlStandardMessageCodec) codec =
              fl_standard_message_codec_new();
          g_autoptr(FlValue) value = fl_message_codec_decode_message(
              FL_MESSAGE_CODEC(codec), bytes, nullptr);
          EXPECT_NE(value, nullptr);
          if (value != nullptr) {
            EXPECT_EQ(fl_value_get_type(value), FL_VALUE_TYPE_BOOL);
            if (fl_value_get_type(value) == FL_VALUE_TYPE_BOOL) {
              EXPECT_FALSE(fl_value_get_bool(value));
            }
          }
          cursor_calls++;
          return kSuccess;
        }
        if (info->node_id == 2) {
          EXPECT_LT(adjustment_calls, G_N_ELEMENTS(adjustment_actions));
          if (adjustment_calls < G_N_ELEMENTS(adjustment_actions)) {
            EXPECT_EQ(info->action, adjustment_actions[adjustment_calls]);
          }
          EXPECT_EQ(info->data_length, 0u);
          adjustment_calls++;
          return kSuccess;
        }
        if (info->action == kFlutterSemanticsActionSetSelection) {
          EXPECT_TRUE(check_selection);
          EXPECT_EQ(info->node_id, 1u);
          EXPECT_LT(selection_calls, 2u);
          g_autoptr(GBytes) bytes = g_bytes_new(info->data, info->data_length);
          g_autoptr(FlStandardMessageCodec) codec =
              fl_standard_message_codec_new();
          g_autoptr(FlValue) value = fl_message_codec_decode_message(
              FL_MESSAGE_CODEC(codec), bytes, nullptr);
          EXPECT_NE(value, nullptr);
          if (value != nullptr) {
            EXPECT_EQ(fl_value_get_int(fl_value_lookup_string(value, "base")),
                      selection_calls == 0 ? 6 : 4);
            EXPECT_EQ(fl_value_get_int(fl_value_lookup_string(value, "extent")),
                      6);
          }
          selection_calls++;
          return kSuccess;
        }
        EXPECT_EQ(info->node_id, 0u);
        EXPECT_EQ(info->action, kFlutterSemanticsActionTap);
        if (check_text && text_updates < 4) {
          text.value = text_values[text_updates++];
          text.text_selection_base = 4;
          text.text_selection_extent = 6;
          fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                                   &update);
          // Repeating the same batch must not emit text events.
          fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                                   &update);
          return kSuccess;
        }
        calls++;
        if (check_focus && calls <= 2) {
          flags.is_focused =
              calls == 1 ? kFlutterTristateTrue : kFlutterTristateFalse;
          fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                                   &update);
          // Neither a geometry-only change nor a repeated
          // batch should duplicate the focus notification.
          button.rect.right++;
          fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                                   &update);
          fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                                   &update);
        } else {
          g_main_loop_quit(loop);
        }
        return kSuccess;
      }));
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);

  // Export the real render widget and native tree without starting GL
  // rendering.
  g_autoptr(GtkWidget) surface = GTK_WIDGET(g_object_ref(view->render_area));
  g_signal_handlers_disconnect_by_data(surface, view);
  gtk_box_remove(GTK_BOX(view), surface);
  g_autoptr(GtkWindow) window = GTK_WINDOW(gtk_window_new());
  g_object_ref_sink(window);
  gtk_window_set_child(window, surface);
  gtk_window_present(window);
  guint timeout = g_timeout_add_seconds(
      15,
      [](gpointer data) -> gboolean {
        g_main_loop_quit(static_cast<GMainLoop*>(data));
        return G_SOURCE_CONTINUE;
      },
      loop);
  g_main_loop_run(loop);
  g_source_remove(timeout);
  EXPECT_EQ(calls, check_focus ? 3u : 1u);
  EXPECT_EQ(text_updates, check_text ? 4u : 0u);
  EXPECT_EQ(selection_calls, check_selection ? 2u : 0u);
  EXPECT_EQ(adjustment_calls, G_N_ELEMENTS(adjustment_actions));
  EXPECT_EQ(cursor_calls, check_text ? G_N_ELEMENTS(cursor_actions) : 0u);
  gtk_window_set_child(window, nullptr);
  gtk_box_append(GTK_BOX(view), surface);
  gtk_window_destroy(window);
}

// Keep a second native view alive while clients query the removed view.
TEST_F(FlViewGtk4AccessibilityTest, ExternalAtspiLifetime) {
  if (g_strcmp0(g_getenv("FLUTTER_TEST_ATSPI_LIFETIME"), "1") != 0) {
    GTEST_SKIP() << "Requires the external AT-SPI lifetime client";
  }
  ASSERT_TRUE(fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing());
  g_autoptr(FlView) view = fl_view_new(project);
  g_object_ref_sink(view);
  FlEngine* engine = fl_view_get_engine(view);
  StartEngine(engine);
  g_autoptr(FlView) control = fl_view_new_for_engine(engine);
  g_object_ref_sink(control);
  const FlutterViewId target_id = fl_view_get_id(view);
  const FlutterViewId control_id = fl_view_get_id(control);
  ASSERT_NE(target_id, control_id);
  FlutterSemanticsFlags flags = {};
  flags.is_button = true;
  flags.is_focused = kFlutterTristateTrue;
  FlutterSemanticsNode2 root = {};
  root.label = "Lifetime root";
  root.rect = {0, 0, 300, 200};
  int32_t root_children[] = {18};
  root.child_count = 1;
  root.children_in_traversal_order = root_children;
  FlutterSemanticsNode2 parent = {};
  parent.id = 18;
  parent.label = "Lifetime old parent";
  parent.rect = {10, 10, 210, 110};
  int32_t child_id = 19;
  parent.child_count = 1;
  parent.children_in_traversal_order = &child_id;
  FlutterSemanticsNode2 child = {};
  child.id = 19;
  child.label = "Lifetime child";
  child.flags2 = &flags;
  child.actions = kFlutterSemanticsActionTap;
  child.rect = {20, 20, 100, 60};
  FlutterSemanticsNode2* nodes[] = {&root, &parent, &child};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = target_id;
  update.node_count = 3;
  update.nodes = nodes;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  FlutterSemanticsFlags control_flags = {};
  control_flags.is_button = true;
  FlutterSemanticsNode2 controller = {};
  controller.label = "Lifetime controller";
  controller.flags2 = &control_flags;
  controller.actions = kFlutterSemanticsActionTap;
  controller.rect = {0, 0, 120, 80};
  FlutterSemanticsNode2* control_nodes[] = {&controller};
  FlutterSemanticsUpdate2 control_update = {};
  control_update.view_id = control_id;
  control_update.node_count = 1;
  control_update.nodes = control_nodes;
  fl_view_gtk4_accessibility_handle_update(control->accessibility_backend,
                                           &control_update);
  g_autoptr(GtkAccessible) retained_root =
      fl_view_gtk4_accessibility_ref_native_root_for_testing(
          view->accessibility_backend);
  g_autoptr(GtkAccessible) retained_parent =
      fl_gtk_runtime_accessible_get_first_accessible_child(retained_root);
  g_autoptr(GtkAccessible) retained_child =
      fl_gtk_runtime_accessible_get_first_accessible_child(retained_parent);
  ASSERT_NE(retained_child, nullptr);
  g_autoptr(GtkWidget) surface = GTK_WIDGET(g_object_ref(view->render_area));
  g_autoptr(GtkWidget) control_surface =
      GTK_WIDGET(g_object_ref(control->render_area));
  g_signal_handlers_disconnect_by_data(surface, view);
  g_signal_handlers_disconnect_by_data(control_surface, control);
  gtk_box_remove(GTK_BOX(view), surface);
  gtk_box_remove(GTK_BOX(control), control_surface);
  g_autoptr(GtkWindow) window = GTK_WINDOW(gtk_window_new());
  g_object_ref_sink(window);
  g_autoptr(GtkWindow) control_window = GTK_WINDOW(gtk_window_new());
  g_object_ref_sink(control_window);
  gtk_window_set_title(window, "Lifetime target window");
  gtk_window_set_child(window, surface);
  gtk_window_set_child(control_window, control_surface);
  gtk_window_present(window);
  gtk_window_present(control_window);
  ASSERT_TRUE(gtk_widget_get_realized(GTK_WIDGET(retained_child)));
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, FALSE);
  size_t steps = 0;
  size_t child_calls = 0;
  bool destroyed = false;
  fl_engine_get_embedder_api(engine)->SendSemanticsAction = MOCK_ENGINE_PROC(
      SendSemanticsAction,
      ([&](auto, const FlutterSendSemanticsActionInfo* info) {
        EXPECT_EQ(info->action, kFlutterSemanticsActionTap);
        if (info->view_id == target_id) {
          EXPECT_EQ(info->node_id, 19u);
          EXPECT_EQ(steps, 1u);
          EXPECT_FALSE(destroyed);
          child_calls++;
          return kSuccess;
        }
        EXPECT_EQ(info->view_id, control_id);
        EXPECT_EQ(info->node_id, 0u);
        steps++;
        if (steps == 1) {
          // Root-only reparenting preserves the omitted child and removes its
          // old parent while all proxies have native AT-SPI contexts.
          root.children_in_traversal_order = &child_id;
          update.node_count = 1;
          fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                                   &update);
          g_autoptr(GtkAccessible) current =
              fl_gtk_runtime_accessible_get_first_accessible_child(
                  retained_root);
          EXPECT_EQ(current, retained_child);
          EXPECT_TRUE(gtk_widget_get_realized(GTK_WIDGET(retained_child)));
        } else if (steps == 2) {
          gtk_window_set_child(window, nullptr);
          gtk_box_append(GTK_BOX(view), surface);
          gtk_window_destroy(window);
          g_object_run_dispose(G_OBJECT(view));
          g_clear_object(&view);
          destroyed = true;
          EXPECT_FALSE(gtk_widget_get_realized(GTK_WIDGET(retained_child)));
          EXPECT_FALSE(fl_view_gtk4_accessibility_get_native_bounds_for_testing(
              retained_child, nullptr, nullptr, nullptr, nullptr));
          gtk_widget_activate_action(GTK_WIDGET(retained_child), "flutter.tap",
                                     nullptr);
          EXPECT_EQ(child_calls, 1u);
          controller.label = "Lifetime destroyed";
          fl_view_gtk4_accessibility_handle_update(
              control->accessibility_backend, &control_update);
        } else {
          EXPECT_EQ(steps, 3u);
          EXPECT_EQ(child_calls, 1u);
          g_main_loop_quit(loop);
        }
        return kSuccess;
      }));
  guint timeout = g_timeout_add_seconds(
      20,
      [](gpointer data) -> gboolean {
        g_main_loop_quit(static_cast<GMainLoop*>(data));
        return G_SOURCE_REMOVE;
      },
      loop);
  g_main_loop_run(loop);
  if (steps == 3) {
    g_source_remove(timeout);
  }
  EXPECT_EQ(steps, 3u);
  EXPECT_EQ(child_calls, 1u);
  EXPECT_TRUE(destroyed);
  gtk_window_set_child(control_window, nullptr);
  gtk_box_append(GTK_BOX(control), control_surface);
  gtk_window_destroy(control_window);
  if (!destroyed) {
    gtk_window_set_child(window, nullptr);
    gtk_box_append(GTK_BOX(view), surface);
    gtk_window_destroy(window);
  }
}

// Check GTK's parent-relative geometry through an external AT-SPI client.
TEST_F(FlViewGtk4AccessibilityTest, ExternalAtspiGeometry) {
  if (g_strcmp0(g_getenv("FLUTTER_TEST_ATSPI_GEOMETRY"), "1") != 0) {
    GTEST_SKIP() << "Requires an external AT-SPI geometry client";
  }
  ASSERT_TRUE(fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing());
  g_autoptr(FlView) view = fl_view_new(project);
  g_object_ref_sink(view);
  StartEngine(fl_view_get_engine(view));
  const bool overlap =
      g_strcmp0(g_getenv("FLUTTER_TEST_ATSPI_OVERLAP"), "1") == 0;
  FlutterSemanticsFlags flags[4] = {};
  flags[3].is_button = true;
  flags[3].is_hidden = !overlap;
  flags[2].is_button = true;
  FlutterSemanticsNode2 root = {};
  root.id = 0;
  root.label = "Geometry root";
  root.flags2 = &flags[0];
  root.rect = {5, 7, 305, 207};
  root.transform = {.scaleX = 2, .transX = 30, .scaleY = 2, .transY = 40};
  int32_t root_children[] = {1};
  root.child_count = 1;
  root.children_in_traversal_order = root_children;
  FlutterSemanticsNode2 group = {};
  group.id = 1;
  group.label = "Geometry group";
  group.flags2 = &flags[1];
  group.rect = {3, 5, 103, 85};
  group.transform.transX = 20;
  group.transform.transY = 10;
  int32_t group_children[] = {2, 3};
  group.child_count = 2;
  group.children_in_traversal_order = group_children;
  int32_t hit_order[] = {2, 3};
  group.children_in_hit_test_order = hit_order;
  FlutterSemanticsNode2 button = {};
  button.id = 2;
  button.label = "Geometry button";
  button.flags2 = &flags[2];
  button.actions = kFlutterSemanticsActionTap;
  button.rect = {4.5, 6.5, 24.5, 16.5};
  button.transform.transX = 7;
  button.transform.transY = 11;
  // A later, overlapping hidden sibling must neither enter native traversal
  // nor intercept point lookup for the visible button.
  FlutterSemanticsNode2 hidden = button;
  hidden.id = 3;
  hidden.label =
      overlap ? "Overlapping geometry button" : "Hidden geometry button";
  hidden.flags2 = &flags[3];
  FlutterSemanticsNode2* nodes[] = {&root, &group, &button, &hidden};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = fl_view_get_id(view);
  update.node_count = G_N_ELEMENTS(nodes);
  update.nodes = nodes;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  g_autoptr(GMainLoop) loop = g_main_loop_new(nullptr, FALSE);
  size_t calls = 0;
  fl_engine_get_embedder_api(fl_view_get_engine(view))->SendSemanticsAction =
      MOCK_ENGINE_PROC(SendSemanticsAction,
                       ([&](auto engine, const auto* info) {
                         EXPECT_EQ(info->view_id, fl_view_get_id(view));
                         EXPECT_EQ(info->node_id, 2u);
                         EXPECT_EQ(info->action, kFlutterSemanticsActionTap);
                         if (calls++ == 0) {
                           root.transform.transX += 12;
                           root.transform.transY += 8;
                           hit_order[0] = 3;
                           hit_order[1] = 2;
                           FlutterSemanticsNode2* partial[] = {&root, &group};
                           FlutterSemanticsUpdate2 ancestor = update;
                           ancestor.node_count = overlap ? 2 : 1;
                           ancestor.nodes = partial;
                           fl_view_gtk4_accessibility_handle_update(
                               view->accessibility_backend, &ancestor);
                         } else {
                           // Route navigation removes a realized subtree whose
                           // descendants can still have pending GTK states.
                           root.child_count = 0;
                           root.children_in_traversal_order = nullptr;
                           FlutterSemanticsNode2* partial[] = {&root};
                           FlutterSemanticsUpdate2 removal = update;
                           removal.node_count = 1;
                           removal.nodes = partial;
                           fl_view_gtk4_accessibility_handle_update(
                               view->accessibility_backend, &removal);
                           g_main_loop_quit(loop);
                         }
                         return kSuccess;
                       }));
  g_autoptr(GtkWidget) surface = GTK_WIDGET(g_object_ref(view->render_area));
  g_signal_handlers_disconnect_by_data(surface, view);
  gtk_box_remove(GTK_BOX(view), surface);
  g_autoptr(GtkWindow) window = GTK_WINDOW(gtk_window_new());
  g_object_ref_sink(window);
  GtkWidget* host = gtk_fixed_new();
  gtk_window_set_child(window, host);
  gtk_widget_set_size_request(surface, 700, 600);
  gtk_fixed_put(GTK_FIXED(host), surface, 37, 29);
  gtk_window_set_default_size(window, 800, 700);
  gtk_window_present(window);
  g_print("GEOMETRY_SCALE %d\n", gtk_widget_get_scale_factor(surface));
  g_print("GEOMETRY_RUNTIME {\"gtk\":\"%u.%u.%u\",\"glib\":\"%u.%u.%u\"}\n",
          gtk_get_major_version(), gtk_get_minor_version(),
          gtk_get_micro_version(), glib_major_version, glib_minor_version,
          glib_micro_version);
  guint timeout = g_timeout_add_seconds(
      15,
      [](gpointer data) -> gboolean {
        g_main_loop_quit(static_cast<GMainLoop*>(data));
        return G_SOURCE_REMOVE;
      },
      loop);
  g_main_loop_run(loop);
  if (calls == 2) {
    g_source_remove(timeout);
  }
  EXPECT_EQ(calls, 2u);
  gtk_fixed_remove(GTK_FIXED(host), surface);
  gtk_box_append(GTK_BOX(view), surface);
  gtk_window_destroy(window);
}

TEST_F(FlViewGtk4AccessibilityTest, PresentBeforeRealizeDoesNotWarn) {
  FlView* view = fl_view_new(project);
  ASSERT_NE(view, nullptr);

  flutter::testing::fl_reset_received_gtk_log_levels();
  fl_renderable_present_layers(FL_RENDERABLE(view), nullptr, 0);

  EXPECT_FALSE(flutter::testing::fl_has_received_gtk_log_level(
      static_cast<GLogLevelFlags>(G_LOG_LEVEL_WARNING | G_LOG_LEVEL_CRITICAL)));
}

TEST_F(FlViewGtk4AccessibilityTest,
       PresentLayersAfterDisposeDoesNotRequestFrame) {
  g_autoptr(FlView) view = fl_view_new(project);
  g_object_ref_sink(view);
  g_object_run_dispose(G_OBJECT(view));

  flutter::testing::fl_reset_received_gtk_log_levels();
  fl_renderable_present_layers(FL_RENDERABLE(view), nullptr, 0);

  EXPECT_FALSE(view->needs_frame_after_realize);
  EXPECT_FALSE(flutter::testing::fl_has_received_gtk_log_level(
      static_cast<GLogLevelFlags>(G_LOG_LEVEL_WARNING | G_LOG_LEVEL_CRITICAL)));
}

TEST_F(FlViewGtk4AccessibilityTest, RemovedSubtreeClearsRetainedLinks) {
  if (!fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing()) {
    GTEST_SKIP() << "Native GtkAccessible traversal requires GTK 4.10+";
  }
  g_autoptr(FlView) view = fl_view_new(project);
  g_object_ref_sink(view);
  int32_t children[] = {1};
  int32_t grandchildren[] = {2, 3};
  FlutterSemanticsNode2 root = {};
  root.child_count = 1;
  root.children_in_traversal_order = children;
  FlutterSemanticsNode2 parent = {};
  parent.id = 1;
  parent.child_count = 2;
  parent.children_in_traversal_order = grandchildren;
  FlutterSemanticsNode2 child = {};
  child.id = 2;
  FlutterSemanticsNode2 sibling = {};
  sibling.id = 3;
  FlutterSemanticsNode2* nodes[] = {&root, &parent, &child, &sibling};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = fl_view_get_id(view);
  update.node_count = 4;
  update.nodes = nodes;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  g_autoptr(GtkAccessible) native_root =
      fl_view_gtk4_accessibility_ref_native_root_for_testing(
          view->accessibility_backend);
  g_autoptr(GtkAccessible) removed_parent =
      fl_view_gtk4_accessibility_ref_first_native_child_for_testing(
          native_root);
  ASSERT_NE(removed_parent, nullptr);
  g_autoptr(GtkAccessible) retained_child =
      fl_view_gtk4_accessibility_ref_first_native_child_for_testing(
          removed_parent);
  ASSERT_NE(retained_child, nullptr);
  GWeakRef parent_ref;
  g_weak_ref_init(&parent_ref, removed_parent);

  root.child_count = 0;
  root.children_in_traversal_order = nullptr;
  update.node_count = 1;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  g_autoptr(GtkAccessible) stale_child =
      fl_view_gtk4_accessibility_ref_first_native_child_for_testing(
          removed_parent);
  EXPECT_EQ(stale_child, nullptr);
  g_clear_object(&removed_parent);
  g_autoptr(GObject) surviving_parent = G_OBJECT(g_weak_ref_get(&parent_ref));
  EXPECT_EQ(surviving_parent, nullptr);
  g_weak_ref_clear(&parent_ref);

  auto* iface = reinterpret_cast<FlGtkAccessibleInterface4_10*>(
      GTK_ACCESSIBLE_GET_IFACE(retained_child));
  g_autoptr(GtkAccessible) stale_parent =
      iface->get_accessible_parent(retained_child);
  EXPECT_EQ(stale_parent, nullptr);
  g_autoptr(GtkAccessible) stale_sibling =
      fl_view_gtk4_accessibility_ref_next_native_sibling_for_testing(
          retained_child);
  EXPECT_EQ(stale_sibling, nullptr);
}

TEST_F(FlViewGtk4AccessibilityTest, RemovedParentPreservesReparentedChild) {
  if (!fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing()) {
    GTEST_SKIP() << "Native GtkAccessible traversal requires GTK 4.10+";
  }
  g_autoptr(FlView) view = fl_view_new(project);
  g_object_ref_sink(view);
  int32_t children[] = {1};
  int32_t grandchildren[] = {2};
  FlutterSemanticsNode2 root = {};
  root.child_count = 1;
  root.children_in_traversal_order = children;
  FlutterSemanticsNode2 parent = {};
  parent.id = 1;
  parent.child_count = 1;
  parent.children_in_traversal_order = grandchildren;
  FlutterSemanticsNode2 child = {};
  child.id = 2;
  FlutterSemanticsNode2* nodes[] = {&root, &parent, &child};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = fl_view_get_id(view);
  update.node_count = 3;
  update.nodes = nodes;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  g_autoptr(GtkAccessible) native_root =
      fl_view_gtk4_accessibility_ref_native_root_for_testing(
          view->accessibility_backend);
  g_autoptr(GtkAccessible) removed_parent =
      fl_view_gtk4_accessibility_ref_first_native_child_for_testing(
          native_root);
  ASSERT_NE(removed_parent, nullptr);
  g_autoptr(GtkAccessible) retained_child =
      fl_view_gtk4_accessibility_ref_first_native_child_for_testing(
          removed_parent);
  ASSERT_NE(retained_child, nullptr);

  root.children_in_traversal_order = grandchildren;
  update.node_count = 1;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  g_autoptr(GtkAccessible) current_child =
      fl_view_gtk4_accessibility_ref_first_native_child_for_testing(
          native_root);
  EXPECT_EQ(current_child, retained_child);
  g_autoptr(GtkAccessible) stale_child =
      fl_view_gtk4_accessibility_ref_first_native_child_for_testing(
          removed_parent);
  EXPECT_EQ(stale_child, nullptr);
  auto* iface = reinterpret_cast<FlGtkAccessibleInterface4_10*>(
      GTK_ACCESSIBLE_GET_IFACE(retained_child));
  g_autoptr(GtkAccessible) current_parent =
      iface->get_accessible_parent(retained_child);
  EXPECT_EQ(current_parent, native_root);
}

TEST_F(FlViewGtk4AccessibilityTest, ViewDisposalDetachesRetainedNodes) {
  if (!fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing()) {
    GTEST_SKIP() << "Native GtkAccessible traversal requires GTK 4.10+";
  }
  g_autoptr(FlView) view = fl_view_new(project);
  g_object_ref_sink(view);
  int32_t children[] = {1, 2};
  FlutterSemanticsNode2 root = {};
  root.child_count = 2;
  root.children_in_traversal_order = children;
  FlutterSemanticsNode2 child = {};
  child.id = 1;
  FlutterSemanticsNode2 sibling = {};
  sibling.id = 2;
  FlutterSemanticsNode2* nodes[] = {&root, &child, &sibling};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = fl_view_get_id(view);
  update.node_count = 3;
  update.nodes = nodes;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  g_autoptr(GtkAccessible) retained_root =
      fl_view_gtk4_accessibility_ref_native_root_for_testing(
          view->accessibility_backend);
  g_autoptr(GtkAccessible) retained_child =
      fl_view_gtk4_accessibility_ref_first_native_child_for_testing(
          retained_root);
  ASSERT_NE(retained_child, nullptr);

  g_object_run_dispose(G_OBJECT(view));
  g_clear_object(&view);

  for (GtkAccessible* node : {retained_root, retained_child}) {
    auto* iface = reinterpret_cast<FlGtkAccessibleInterface4_10*>(
        GTK_ACCESSIBLE_GET_IFACE(node));
    g_autoptr(GtkAccessible) parent = iface->get_accessible_parent(node);
    EXPECT_EQ(parent, nullptr);
    g_autoptr(GtkAccessible) first_child =
        iface->get_first_accessible_child(node);
    EXPECT_EQ(first_child, nullptr);
    g_autoptr(GtkAccessible) next = iface->get_next_accessible_sibling(node);
    EXPECT_EQ(next, nullptr);
    EXPECT_FALSE(iface->get_bounds(node, nullptr, nullptr, nullptr, nullptr));
  }
}

TEST_F(FlViewGtk4AccessibilityTest, RoleChangesReplaceAndDetachNativeNodes) {
  if (!fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing()) {
    GTEST_SKIP() << "Native GtkAccessible traversal requires GTK 4.10+";
  }
  g_autoptr(FlView) view = fl_view_new(project);
  g_object_ref_sink(view);
  FlEngine* engine = fl_view_get_engine(view);
  StartEngine(engine);
  size_t calls = 0;
  fl_engine_get_embedder_api(engine)->SendSemanticsAction = MOCK_ENGINE_PROC(
      SendSemanticsAction, ([&](auto, const FlutterSendSemanticsActionInfo*) {
        calls++;
        return kSuccess;
      }));
  int32_t children[] = {1, 2};
  int32_t grandchildren[] = {3};
  FlutterSemanticsFlags root_flags = {};
  FlutterSemanticsFlags child_flags = {};
  child_flags.is_button = true;
  FlutterSemanticsNode2 root = {};
  root.child_count = 2;
  root.children_in_traversal_order = children;
  root.flags2 = &root_flags;
  root.actions = kFlutterSemanticsActionTap;
  FlutterSemanticsNode2 child = {};
  child.id = 1;
  child.child_count = 1;
  child.children_in_traversal_order = grandchildren;
  child.flags2 = &child_flags;
  child.actions = kFlutterSemanticsActionTap;
  FlutterSemanticsNode2 sibling = {};
  sibling.id = 2;
  FlutterSemanticsNode2 grandchild = {};
  grandchild.id = 3;
  FlutterSemanticsNode2* nodes[] = {&root, &child, &sibling, &grandchild};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = fl_view_get_id(view);
  update.node_count = 4;
  update.nodes = nodes;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  g_autoptr(GtkAccessible) old_root =
      fl_view_gtk4_accessibility_ref_native_root_for_testing(
          view->accessibility_backend);
  g_autoptr(GtkAccessible) old_child =
      fl_gtk_runtime_accessible_get_first_accessible_child(old_root);
  g_autoptr(GtkAccessible) retained_grandchild =
      fl_gtk_runtime_accessible_get_first_accessible_child(old_child);
  g_autoptr(GtkAccessible) retained_sibling =
      fl_view_gtk4_accessibility_ref_next_native_sibling_for_testing(old_child);
  ASSERT_NE(retained_grandchild, nullptr);
  ASSERT_NE(retained_sibling, nullptr);
  gtk_widget_activate_action(GTK_WIDGET(old_child), "flutter.tap", nullptr);
  EXPECT_EQ(calls, 1u);

  // A partial role update replaces only this node, preserving its descendants.
  child_flags.is_button = false;
  child_flags.is_checked = kFlutterCheckStateTrue;
  update.node_count = 1;
  update.nodes = &nodes[1];
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  g_autoptr(GtkAccessible) new_child =
      fl_gtk_runtime_accessible_get_first_accessible_child(old_root);
  ASSERT_NE(new_child, nullptr);
  ASSERT_NE(new_child, old_child);
  EXPECT_EQ(gtk_accessible_get_accessible_role(old_child),
            GTK_ACCESSIBLE_ROLE_BUTTON);
  EXPECT_EQ(gtk_accessible_get_accessible_role(new_child),
            GTK_ACCESSIBLE_ROLE_CHECKBOX);
  g_autoptr(GtkAccessible) new_grandchild =
      fl_gtk_runtime_accessible_get_first_accessible_child(new_child);
  EXPECT_EQ(new_grandchild, retained_grandchild);
  g_autoptr(GtkAccessible) new_sibling =
      fl_view_gtk4_accessibility_ref_next_native_sibling_for_testing(new_child);
  EXPECT_EQ(new_sibling, retained_sibling);
  gtk_widget_activate_action(GTK_WIDGET(old_child), "flutter.tap", nullptr);
  EXPECT_EQ(calls, 1u);
  gtk_widget_activate_action(GTK_WIDGET(new_child), "flutter.tap", nullptr);
  EXPECT_EQ(calls, 2u);

  // Root replacement must also update the render widget's exported child.
  root_flags.is_header = true;
  update.nodes = nodes;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  g_autoptr(GtkAccessible) new_root =
      fl_view_gtk4_accessibility_ref_native_root_for_testing(
          view->accessibility_backend);
  ASSERT_NE(new_root, nullptr);
  ASSERT_NE(new_root, old_root);
  EXPECT_EQ(gtk_accessible_get_accessible_role(old_root),
            GTK_ACCESSIBLE_ROLE_GENERIC);
  EXPECT_EQ(gtk_accessible_get_accessible_role(new_root),
            GTK_ACCESSIBLE_ROLE_HEADING);
  g_autoptr(GtkAccessible) exported_root =
      fl_gtk_runtime_accessible_get_first_accessible_child(
          GTK_ACCESSIBLE(view->render_area));
  EXPECT_EQ(exported_root, new_root);
  g_autoptr(GtkAccessible) retained_child =
      fl_gtk_runtime_accessible_get_first_accessible_child(new_root);
  EXPECT_EQ(retained_child, new_child);
  auto* child_iface = reinterpret_cast<FlGtkAccessibleInterface4_10*>(
      GTK_ACCESSIBLE_GET_IFACE(new_child));
  g_autoptr(GtkAccessible) parent =
      child_iface->get_accessible_parent(new_child);
  EXPECT_EQ(parent, new_root);
  gtk_widget_activate_action(GTK_WIDGET(old_root), "flutter.tap", nullptr);
  EXPECT_EQ(calls, 2u);

  // A structural batch takes the rebuild path rather than the incremental path.
  children[0] = 2;
  children[1] = 1;
  child_flags.is_in_mutually_exclusive_group = true;
  update.node_count = 2;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  g_autoptr(GtkAccessible) reordered_first =
      fl_gtk_runtime_accessible_get_first_accessible_child(new_root);
  EXPECT_EQ(reordered_first, retained_sibling);
  g_autoptr(GtkAccessible) radio =
      fl_view_gtk4_accessibility_ref_next_native_sibling_for_testing(
          reordered_first);
  ASSERT_NE(radio, nullptr);
  ASSERT_NE(radio, new_child);
  EXPECT_EQ(gtk_accessible_get_accessible_role(radio),
            GTK_ACCESSIBLE_ROLE_RADIO);
  g_autoptr(GtkAccessible) radio_child =
      fl_gtk_runtime_accessible_get_first_accessible_child(radio);
  EXPECT_EQ(radio_child, retained_grandchild);
  gtk_widget_activate_action(GTK_WIDGET(new_child), "flutter.tap", nullptr);
  EXPECT_EQ(calls, 2u);
  gtk_widget_activate_action(GTK_WIDGET(radio), "flutter.tap", nullptr);
  EXPECT_EQ(calls, 3u);

  for (GtkAccessible* obsolete : {old_root, old_child, new_child}) {
    auto* iface = reinterpret_cast<FlGtkAccessibleInterface4_10*>(
        GTK_ACCESSIBLE_GET_IFACE(obsolete));
    g_autoptr(GtkAccessible) obsolete_parent =
        iface->get_accessible_parent(obsolete);
    g_autoptr(GtkAccessible) obsolete_child =
        iface->get_first_accessible_child(obsolete);
    g_autoptr(GtkAccessible) obsolete_sibling =
        iface->get_next_accessible_sibling(obsolete);
    EXPECT_EQ(obsolete_parent, nullptr);
    EXPECT_EQ(obsolete_child, nullptr);
    EXPECT_EQ(obsolete_sibling, nullptr);
    EXPECT_FALSE(
        iface->get_bounds(obsolete, nullptr, nullptr, nullptr, nullptr));
  }
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
  updated_button.transform.scaleX = 2;
  updated_button.transform.scaleY = 3;
  updated_button.transform.skewX = 0.5;
  updated_button.transform.skewY = 0.25;
  updated_button.transform.transX = 10;
  updated_button.transform.transY = 20;
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

  EXPECT_TRUE(fl_view_gtk4_accessibility_get_native_bounds_for_testing(
      updated_first_child, &x, &y, &width, &height));
  EXPECT_EQ(x, 21);
  EXPECT_EQ(y, 39);
  EXPECT_EQ(width, 55);
  EXPECT_EQ(height, 95);

  updated_button.transform.pers2 = 2;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &updated_update);
  EXPECT_TRUE(fl_view_gtk4_accessibility_get_native_bounds_for_testing(
      updated_first_child, &x, &y, &width, &height));
  EXPECT_EQ(x, 10);
  EXPECT_EQ(y, 19);
  EXPECT_EQ(width, 28);
  EXPECT_EQ(height, 48);

  // Changing an ancestor must recompute the descendant's composed bounds.
  root.transform.transX = 100;
  FlutterSemanticsNode2* ancestor_update_nodes[] = {&root, &updated_button};
  FlutterSemanticsUpdate2 ancestor_update = {
      .node_count = 2,
      .nodes = ancestor_update_nodes,
      .view_id = fl_view_get_id(view),
  };
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &ancestor_update);
  EXPECT_TRUE(fl_view_gtk4_accessibility_get_native_bounds_for_testing(
      updated_first_child, &x, &y, &width, &height));
  // The root now starts at x=100. GTK adds that ancestor position itself.
  EXPECT_EQ(x, 10);
  EXPECT_EQ(y, 19);
  EXPECT_EQ(width, 28);
  EXPECT_EQ(height, 48);

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
    ASSERT_EQ(text_length, std::strlen("one two"));
    EXPECT_EQ(std::memcmp(text_data, "one two", text_length), 0);
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

TEST_F(FlViewGtk4AccessibilityTest, TextSelectionUsesCharacterOffsets) {
  if (!fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing() ||
      !fl_gtk_runtime_supports_native_accessibility_text()) {
    GTEST_SKIP() << "Native accessible text requires GTK 4.14+";
  }
  g_autoptr(FlView) view = fl_view_new(project);
  g_object_ref_sink(view);
  FlutterSemanticsFlags flags = {};
  flags.is_text_field = true;
  FlutterSemanticsNode2 root = {};
  // A, an emoji (two UTF-16 code units), e, and a combining acute accent.
  root.value =
      "A\xF0\x9F\x98\x80"
      "e\xCC\x81";
  root.flags2 = &flags;
  FlutterSemanticsNode2* nodes[] = {&root};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = fl_view_get_id(view);
  update.node_count = 1;
  update.nodes = nodes;

  struct SelectionCase {
    gint base;
    gint extent;
    guint caret;
    gsize start;
    gsize length;
  };
  const SelectionCase cases[] = {
      {1, 3, 2, 1, 1}, {3, 1, 1, 1, 1},   {3, 3, 2, 0, 0},   {0, 5, 4, 0, 4},
      {4, 5, 4, 3, 1}, {-1, -1, 0, 0, 0}, {0, 100, 4, 0, 4}, {2, 3, 2, 1, 1},
  };
  for (const SelectionCase& selection : cases) {
    SCOPED_TRACE(testing::Message()
                 << selection.base << ":" << selection.extent);
    root.text_selection_base = selection.base;
    root.text_selection_extent = selection.extent;
    fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                             &update);
    g_autoptr(GtkAccessible) native =
        fl_view_gtk4_accessibility_ref_native_root_for_testing(
            view->accessibility_backend);
    ASSERT_NE(native, nullptr);
    auto* iface = static_cast<FlGtkAccessibleTextInterface4_14*>(
        g_type_interface_peek(G_OBJECT_GET_CLASS(native),
                              fl_gtk_runtime_accessible_text_get_type()));
    ASSERT_NE(iface, nullptr);
    EXPECT_EQ(iface->get_caret_position(native), selection.caret);
    gsize n_ranges = 0;
    FlGtkAccessibleTextRange4_14* ranges = nullptr;
    EXPECT_EQ(iface->get_selection(native, &n_ranges, &ranges),
              selection.length != 0);
    g_autofree FlGtkAccessibleTextRange4_14* owned_ranges = ranges;
    if (selection.length != 0) {
      ASSERT_EQ(n_ranges, 1u);
      ASSERT_NE(ranges, nullptr);
      EXPECT_EQ(ranges[0].start, selection.start);
      EXPECT_EQ(ranges[0].length, selection.length);
      g_autoptr(GBytes) contents = iface->get_contents(
          native, ranges[0].start, ranges[0].start + ranges[0].length);
      g_autofree gchar* expected = g_utf8_substring(
          root.value, selection.start, selection.start + selection.length);
      EXPECT_EQ(g_bytes_get_size(contents), strlen(expected));
      EXPECT_EQ(memcmp(g_bytes_get_data(contents, nullptr), expected,
                       strlen(expected)),
                0);
    }
  }
}

TEST_F(FlViewGtk4AccessibilityTest, CharacterQueriesRespectTextEnd) {
  if (!fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing() ||
      !fl_gtk_runtime_supports_native_accessibility_text()) {
    GTEST_SKIP() << "Native accessible text requires GTK 4.14+";
  }
  g_autoptr(FlView) view = fl_view_new(project);
  g_object_ref_sink(view);
  FlutterSemanticsFlags flags = {};
  flags.is_text_field = true;
  FlutterSemanticsNode2 root = {};
  root.flags2 = &flags;
  FlutterSemanticsNode2* nodes[] = {&root};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = fl_view_get_id(view);
  update.node_count = 1;
  update.nodes = nodes;

  const gchar* texts[] = {"",
                          "A\xF0\x9F\x98\x80"
                          "e\xCC\x81"};
  for (const gchar* text : texts) {
    root.value = text;
    fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                             &update);
    g_autoptr(GtkAccessible) native =
        fl_view_gtk4_accessibility_ref_native_root_for_testing(
            view->accessibility_backend);
    ASSERT_NE(native, nullptr);
    auto* iface = static_cast<FlGtkAccessibleTextInterface4_14*>(
        g_type_interface_peek(G_OBJECT_GET_CLASS(native),
                              fl_gtk_runtime_accessible_text_get_type()));
    ASSERT_NE(iface, nullptr);
    const guint length = g_utf8_strlen(text, -1);
    for (guint offset = 0; offset <= length + 1; offset++) {
      SCOPED_TRACE(testing::Message() << text << ":" << offset);
      guint start = G_MAXUINT;
      guint end = G_MAXUINT;
      g_autoptr(GBytes) contents = iface->get_contents_at(
          native, offset, FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_CHARACTER, &start,
          &end);
      ASSERT_NE(contents, nullptr);
      EXPECT_EQ(start, MIN(offset, length));
      EXPECT_EQ(end, MIN(offset + 1, length));
      g_autofree gchar* actual = g_strndup(
          static_cast<const gchar*>(g_bytes_get_data(contents, nullptr)),
          g_bytes_get_size(contents));
      g_autofree gchar* expected =
          g_utf8_substring(text, MIN(offset, length), MIN(offset + 1, length));
      EXPECT_STREQ(actual, expected);
    }
    g_autoptr(GBytes) terminal = iface->get_contents_at(
        native, G_MAXUINT, FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_CHARACTER,
        nullptr, nullptr);
    ASSERT_NE(terminal, nullptr);
    EXPECT_EQ(*static_cast<const gchar*>(g_bytes_get_data(terminal, nullptr)),
              '\0');
  }
}

TEST_F(FlViewGtk4AccessibilityTest, TextQueriesUseLinguisticBoundaries) {
  if (!fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing() ||
      !fl_gtk_runtime_supports_native_accessibility_text()) {
    GTEST_SKIP() << "Native accessible text requires GTK 4.14+";
  }
  g_autoptr(FlView) view = fl_view_new(project);
  g_object_ref_sink(view);
  FlutterSemanticsFlags flags = {};
  flags.is_text_field = true;
  FlutterSemanticsNode2 root = {};
  root.flags2 = &flags;
  FlutterSemanticsNode2* nodes[] = {&root};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = fl_view_get_id(view);
  update.node_count = 1;
  update.nodes = nodes;

  struct BoundaryCase {
    const gchar* text;
    guint offset;
    FlGtkAccessibleTextGranularity4_14 granularity;
    guint start;
    guint end;
    const gchar* expected;
  };
  const BoundaryCase cases[] = {
      {"Hello world. Next sentence!", 7,
       FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_WORD, 6, 13, "world. "},
      {"Hello world. Next sentence!", 5,
       FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_WORD, 0, 6, "Hello "},
      {"Hello world. Next sentence!", 6,
       FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_WORD, 6, 13, "world. "},
      {"Hello world. Next sentence!", 12,
       FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_WORD, 6, 13, "world. "},
      {"Hello world. Next sentence!", 15,
       FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_SENTENCE, 13, 27, "Next sentence!"},
      {"Hello world. Next sentence!", 2,
       FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_SENTENCE, 0, 13, "Hello world. "},
      {"Hello world. Next sentence!", 12,
       FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_SENTENCE, 0, 13, "Hello world. "},
      {"Hello world. Next sentence!", 13,
       FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_SENTENCE, 13, 27, "Next sentence!"},
      {"caf\xC3\xA9 noir", 6, FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_WORD, 5, 9,
       "noir"},
      {"e\xCC\x81lan noir", 1, FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_WORD, 0, 6,
       "e\xCC\x81lan "},
      {"", 0, FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_WORD, 0, 0, ""},
      {"", G_MAXUINT, FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_SENTENCE, 0, 0, ""},
      {"one\ntwo", 0, FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_PARAGRAPH, 0, 4,
       "one\n"},
      {"one\ntwo", 3, FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_PARAGRAPH, 0, 4,
       "one\n"},
      {"one\ntwo", 4, FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_PARAGRAPH, 4, 7,
       "two"},
      {"one\ntwo", G_MAXUINT, FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_PARAGRAPH, 4,
       7, "two"},
      {"one\r\ntwo", 4, FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_PARAGRAPH, 0, 5,
       "one\r\n"},
      {"one\r\ntwo", 5, FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_PARAGRAPH, 5, 8,
       "two"},
      {"one\rtwo", 4, FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_PARAGRAPH, 4, 7,
       "two"},
      {"caf\xC3\xA9\xE2\x80\xA9next", 4,
       FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_PARAGRAPH, 0, 5,
       "caf\xC3\xA9\xE2\x80\xA9"},
      {"caf\xC3\xA9\xE2\x80\xA9next", 5,
       FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_PARAGRAPH, 5, 9, "next"},
      {"one\n\ntwo", 4, FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_PARAGRAPH, 4, 5,
       "\n"},
      {"one\n", 4, FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_PARAGRAPH, 4, 4, ""},
      {"", 0, FL_GTK_ACCESSIBLE_TEXT_GRANULARITY_PARAGRAPH, 0, 0, ""},
  };
  for (const BoundaryCase& test : cases) {
    SCOPED_TRACE(testing::Message() << test.text << ":" << test.offset);
    root.value = test.text;
    fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                             &update);
    g_autoptr(GtkAccessible) native =
        fl_view_gtk4_accessibility_ref_native_root_for_testing(
            view->accessibility_backend);
    ASSERT_NE(native, nullptr);
    auto* iface = static_cast<FlGtkAccessibleTextInterface4_14*>(
        g_type_interface_peek(G_OBJECT_GET_CLASS(native),
                              fl_gtk_runtime_accessible_text_get_type()));
    ASSERT_NE(iface, nullptr);
    guint start = G_MAXUINT;
    guint end = G_MAXUINT;
    g_autoptr(GBytes) contents = iface->get_contents_at(
        native, test.offset, test.granularity, &start, &end);
    ASSERT_NE(contents, nullptr);
    EXPECT_EQ(start, test.start);
    EXPECT_EQ(end, test.end);
    g_autofree gchar* actual = g_strndup(
        static_cast<const gchar*>(g_bytes_get_data(contents, nullptr)),
        g_bytes_get_size(contents));
    EXPECT_STREQ(actual, test.expected);
  }
}

TEST_F(FlViewGtk4AccessibilityTest, CursorActionsEncodeCollapsedSelection) {
  if (!fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing() ||
      !fl_gtk_runtime_supports_native_accessibility_text()) {
    GTEST_SKIP() << "Native accessible text requires GTK 4.14+";
  }
  g_autoptr(FlView) primary = fl_view_new(project);
  g_object_ref_sink(primary);
  FlEngine* engine = fl_view_get_engine(primary);
  StartEngine(engine);
  g_autoptr(FlView) view = fl_view_new_for_engine(engine);
  g_object_ref_sink(view);
  ASSERT_NE(fl_view_get_id(view), 0);
  const struct {
    const char* name;
    FlutterSemanticsAction action;
  } actions[] = {
      {"flutter.move-cursor-forward-by-character",
       kFlutterSemanticsActionMoveCursorForwardByCharacter},
      {"flutter.move-cursor-backward-by-character",
       kFlutterSemanticsActionMoveCursorBackwardByCharacter},
      {"flutter.move-cursor-forward-by-word",
       kFlutterSemanticsActionMoveCursorForwardByWord},
      {"flutter.move-cursor-backward-by-word",
       kFlutterSemanticsActionMoveCursorBackwardByWord},
  };
  size_t calls = 0;
  FlutterSemanticsAction expected = actions[0].action;
  fl_engine_get_embedder_api(engine)->SendSemanticsAction = MOCK_ENGINE_PROC(
      SendSemanticsAction,
      ([&](auto, const FlutterSendSemanticsActionInfo* info) {
        EXPECT_EQ(info->view_id, fl_view_get_id(view));
        EXPECT_EQ(info->node_id, 0u);
        EXPECT_EQ(info->action, expected);
        g_autoptr(GBytes) bytes = g_bytes_new(info->data, info->data_length);
        g_autoptr(FlStandardMessageCodec) codec =
            fl_standard_message_codec_new();
        g_autoptr(FlValue) value = fl_message_codec_decode_message(
            FL_MESSAGE_CODEC(codec), bytes, nullptr);
        EXPECT_NE(value, nullptr);
        if (value != nullptr) {
          EXPECT_EQ(fl_value_get_type(value), FL_VALUE_TYPE_BOOL);
          if (fl_value_get_type(value) == FL_VALUE_TYPE_BOOL) {
            EXPECT_FALSE(fl_value_get_bool(value));
          }
        }
        calls++;
        return kSuccess;
      }));
  FlutterSemanticsFlags flags = {};
  flags.is_text_field = true;
  FlutterSemanticsNode2 root = {};
  root.flags2 = &flags;
  root.value = "A\xF0\x9F\x98\x80 word";
  root.text_selection_base = root.text_selection_extent = 1;
  FlutterSemanticsNode2* nodes[] = {&root};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = fl_view_get_id(view);
  update.node_count = 1;
  update.nodes = nodes;
  const auto apply_update = [&]() {
    fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                             &update);
  };
  apply_update();
  g_autoptr(GtkAccessible) native =
      fl_view_gtk4_accessibility_ref_native_root_for_testing(
          view->accessibility_backend);
  ASSERT_TRUE(GTK_IS_WIDGET(native));
  GtkWidget* widget = GTK_WIDGET(native);
  auto* iface = static_cast<FlGtkAccessibleTextInterface4_14*>(
      g_type_interface_peek(G_OBJECT_GET_CLASS(native),
                            fl_gtk_runtime_accessible_text_get_type()));
  ASSERT_NE(iface, nullptr);
  for (const auto& action : actions) {
    SCOPED_TRACE(action.name);
    expected = action.action;
    root.actions = action.action;
    apply_update();
    const size_t before = calls;
    EXPECT_TRUE(gtk_widget_activate_action(widget, action.name, nullptr));
    EXPECT_EQ(calls, before + 1);
    // Flutter decides the new position and supplies authoritative semantics.
    EXPECT_EQ(iface->get_caret_position(native), 1u);
    for (const auto& other : actions) {
      if (other.action != action.action) {
        gtk_widget_activate_action(widget, other.name, nullptr);
      }
    }
    root.actions = static_cast<FlutterSemanticsAction>(0);
    apply_update();
    gtk_widget_activate_action(widget, action.name, nullptr);
    root.actions = action.action;
    flags.is_enabled = kFlutterTristateFalse;
    apply_update();
    gtk_widget_activate_action(widget, action.name, nullptr);
    flags.is_enabled = kFlutterTristateTrue;
    flags.is_hidden = true;
    apply_update();
    gtk_widget_activate_action(widget, action.name, nullptr);
    flags.is_hidden = false;
    flags.is_obscured = true;
    apply_update();
    gtk_widget_activate_action(widget, action.name, nullptr);
    EXPECT_EQ(calls, before + 2);
    flags.is_obscured = false;
  }
  for (const auto& action : actions) {
    root.actions =
        static_cast<FlutterSemanticsAction>(root.actions | action.action);
  }
  // Even an inconsistent non-text semantics node must not expose cursor
  // actions.
  flags.is_text_field = false;
  apply_update();
  g_autoptr(GtkAccessible) non_text =
      fl_view_gtk4_accessibility_ref_native_root_for_testing(
          view->accessibility_backend);
  ASSERT_TRUE(GTK_IS_WIDGET(non_text));
  const size_t before = calls;
  for (const auto& action : actions) {
    gtk_widget_activate_action(GTK_WIDGET(non_text), action.name, nullptr);
    gtk_widget_activate_action(widget, action.name, nullptr);
  }
  EXPECT_EQ(calls, before);
  flags.is_text_field = true;
  apply_update();
  g_autoptr(GtkAccessible) restored =
      fl_view_gtk4_accessibility_ref_native_root_for_testing(
          view->accessibility_backend);
  ASSERT_TRUE(GTK_IS_WIDGET(restored));
  expected = actions[0].action;
  EXPECT_TRUE(gtk_widget_activate_action(GTK_WIDGET(restored), actions[0].name,
                                         nullptr));
  EXPECT_EQ(calls, before + 1);
  g_object_run_dispose(G_OBJECT(view));
  for (const auto& action : actions) {
    gtk_widget_activate_action(GTK_WIDGET(restored), action.name, nullptr);
  }
  EXPECT_EQ(calls, before + 1);
}

TEST_F(FlViewGtk4AccessibilityTest, ClipboardActionsRespectProtection) {
  if (!fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing()) {
    GTEST_SKIP() << "Native GtkAccessible traversal requires GTK 4.10+";
  }
  g_autoptr(FlView) primary = fl_view_new(project);
  g_object_ref_sink(primary);
  FlEngine* engine = fl_view_get_engine(primary);
  StartEngine(engine);
  g_autoptr(FlView) view = fl_view_new_for_engine(engine);
  g_object_ref_sink(view);
  ASSERT_NE(fl_view_get_id(view), 0);
  const struct {
    const char* name;
    FlutterSemanticsAction action;
  } actions[] = {
      {"flutter.copy", kFlutterSemanticsActionCopy},
      {"flutter.cut", kFlutterSemanticsActionCut},
      {"flutter.paste", kFlutterSemanticsActionPaste},
  };
  size_t calls = 0;
  FlutterSemanticsAction expected = kFlutterSemanticsActionCopy;
  fl_engine_get_embedder_api(engine)->SendSemanticsAction =
      MOCK_ENGINE_PROC(SendSemanticsAction,
                       ([&](auto, const FlutterSendSemanticsActionInfo* info) {
                         EXPECT_EQ(info->view_id, fl_view_get_id(view));
                         EXPECT_EQ(info->node_id, 0u);
                         EXPECT_EQ(info->action, expected);
                         EXPECT_EQ(info->data_length, 0u);
                         calls++;
                         return kSuccess;
                       }));
  FlutterSemanticsFlags flags = {};
  flags.is_text_field = true;
  FlutterSemanticsNode2 root = {};
  root.flags2 = &flags;
  root.value = "Selected text";
  root.text_selection_base = 0;
  root.text_selection_extent = 8;
  FlutterSemanticsNode2* nodes[] = {&root};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = fl_view_get_id(view);
  update.node_count = 1;
  update.nodes = nodes;
  const auto apply_update = [&]() {
    fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                             &update);
  };
  apply_update();
  g_autoptr(GtkAccessible) native =
      fl_view_gtk4_accessibility_ref_native_root_for_testing(
          view->accessibility_backend);
  ASSERT_TRUE(GTK_IS_WIDGET(native));
  GtkWidget* widget = GTK_WIDGET(native);
  for (const auto& action : actions) {
    SCOPED_TRACE(action.name);
    root.actions = action.action;
    expected = action.action;
    apply_update();
    const size_t before = calls;
    EXPECT_TRUE(gtk_widget_activate_action(widget, action.name, nullptr));
    EXPECT_EQ(calls, before + 1);
    for (const auto& other : actions) {
      if (other.action != action.action) {
        gtk_widget_activate_action(widget, other.name, nullptr);
      }
    }
    root.actions = static_cast<FlutterSemanticsAction>(0);
    apply_update();
    gtk_widget_activate_action(widget, action.name, nullptr);
    root.actions = action.action;
    flags.is_enabled = kFlutterTristateFalse;
    apply_update();
    gtk_widget_activate_action(widget, action.name, nullptr);
    flags.is_enabled = kFlutterTristateTrue;
    flags.is_hidden = true;
    apply_update();
    gtk_widget_activate_action(widget, action.name, nullptr);
    EXPECT_EQ(calls, before + 1);
    flags.is_hidden = false;
  }
  root.actions = static_cast<FlutterSemanticsAction>(
      kFlutterSemanticsActionCopy | kFlutterSemanticsActionCut |
      kFlutterSemanticsActionPaste);
  const struct {
    bool obscured;
    bool read_only;
    FlutterSemanticsAction allowed;
  } cases[] = {
      {false, true, kFlutterSemanticsActionCopy},
      {true, false, kFlutterSemanticsActionPaste},
      {true, true, static_cast<FlutterSemanticsAction>(0)},
      {false, false, root.actions},
  };
  for (const auto& test : cases) {
    SCOPED_TRACE(testing::Message() << "obscured=" << test.obscured
                                    << " read_only=" << test.read_only);
    flags.is_obscured = test.obscured;
    flags.is_read_only = test.read_only;
    apply_update();
    for (const auto& action : actions) {
      SCOPED_TRACE(action.name);
      const size_t before = calls;
      expected = action.action;
      gtk_widget_activate_action(widget, action.name, nullptr);
      EXPECT_EQ(calls, before + ((test.allowed & action.action) != 0 ? 1 : 0));
    }
  }
  const size_t before = calls;
  g_object_run_dispose(G_OBJECT(view));
  for (const auto& action : actions) {
    gtk_widget_activate_action(widget, action.name, nullptr);
  }
  EXPECT_EQ(calls, before);
}

TEST_F(FlViewGtk4AccessibilityTest, TextSelectionActionsUseUtf16Offsets) {
  if (!fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing() ||
      gtk_check_version(4, 22, 0) != nullptr) {
    GTEST_SKIP() << "Native text selection actions require GTK 4.22+";
  }
  g_autoptr(FlView) primary = fl_view_new(project);
  g_object_ref_sink(primary);
  FlEngine* engine = fl_view_get_engine(primary);
  StartEngine(engine);
  g_autoptr(FlView) view = fl_view_new_for_engine(engine);
  g_object_ref_sink(view);
  ASSERT_NE(fl_view_get_id(view), 0);
  int calls = 0;
  gint64 expected_base = 1;
  gint64 expected_extent = 3;
  fl_engine_get_embedder_api(engine)->SendSemanticsAction = MOCK_ENGINE_PROC(
      SendSemanticsAction,
      ([&](auto, const FlutterSendSemanticsActionInfo* info) {
        EXPECT_EQ(info->view_id, fl_view_get_id(view));
        EXPECT_EQ(info->node_id, 0u);
        EXPECT_EQ(info->action, kFlutterSemanticsActionSetSelection);
        g_autoptr(GBytes) bytes = g_bytes_new(info->data, info->data_length);
        g_autoptr(FlStandardMessageCodec) codec =
            fl_standard_message_codec_new();
        g_autoptr(FlValue) value = fl_message_codec_decode_message(
            FL_MESSAGE_CODEC(codec), bytes, nullptr);
        EXPECT_NE(value, nullptr);
        if (value != nullptr) {
          EXPECT_EQ(fl_value_get_int(fl_value_lookup_string(value, "base")),
                    expected_base);
          EXPECT_EQ(fl_value_get_int(fl_value_lookup_string(value, "extent")),
                    expected_extent);
        }
        calls++;
        return kSuccess;
      }));
  FlutterSemanticsFlags flags = {};
  flags.is_text_field = true;
  FlutterSemanticsNode2 root = {};
  root.flags2 = &flags;
  root.value =
      "A\xF0\x9F\x98\x80"
      "e\xCC\x81";
  root.actions = kFlutterSemanticsActionSetSelection;
  FlutterSemanticsNode2* nodes[] = {&root};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = fl_view_get_id(view);
  update.node_count = 1;
  update.nodes = nodes;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  g_autoptr(GtkAccessible) native =
      fl_view_gtk4_accessibility_ref_native_root_for_testing(
          view->accessibility_backend);
  ASSERT_NE(native, nullptr);
  auto* iface = static_cast<FlGtkAccessibleTextInterface4_22*>(
      g_type_interface_peek(G_OBJECT_GET_CLASS(native),
                            fl_gtk_runtime_accessible_text_get_type()));
  ASSERT_NE(iface, nullptr);
  ASSERT_NE(iface->set_selection, nullptr);
  ASSERT_NE(iface->set_caret_position, nullptr);
  FlGtkAccessibleTextRange4_14 range = {1, 1};
  EXPECT_TRUE(iface->set_selection(native, 0, &range));
  EXPECT_EQ(calls, 1);
  EXPECT_EQ(iface->base.get_caret_position(native), 0u);
  expected_base = expected_extent = 5;
  EXPECT_TRUE(iface->set_caret_position(native, 4));
  EXPECT_EQ(calls, 2);
  EXPECT_FALSE(iface->set_caret_position(native, 5));
  EXPECT_FALSE(iface->set_selection(native, 1, &range));
  EXPECT_FALSE(iface->set_selection(native, 0, nullptr));
  range.length = G_MAXSIZE;
  EXPECT_FALSE(iface->set_selection(native, 0, &range));
  range = {G_MAXSIZE, 0};
  EXPECT_FALSE(iface->set_selection(native, 0, &range));
  EXPECT_EQ(calls, 2);

  range = {1, 1};
  root.actions = static_cast<FlutterSemanticsAction>(0);
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  EXPECT_FALSE(iface->set_caret_position(native, 0));
  EXPECT_FALSE(iface->set_selection(native, 0, &range));
  root.actions = kFlutterSemanticsActionSetSelection;
  flags.is_enabled = kFlutterTristateFalse;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  EXPECT_FALSE(iface->set_caret_position(native, 0));
  EXPECT_FALSE(iface->set_selection(native, 0, &range));
  flags.is_enabled = kFlutterTristateNone;
  flags.is_obscured = true;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  g_autoptr(GBytes) masked =
      fl_view_gtk4_accessibility_ref_native_text_for_testing(native);
  ASSERT_NE(masked, nullptr);
  EXPECT_EQ(g_bytes_get_size(masked), 4u);
  EXPECT_EQ(memcmp(g_bytes_get_data(masked, nullptr), "****", 4), 0);
  expected_base = expected_extent = 3;
  EXPECT_TRUE(iface->set_caret_position(native, 2));
  expected_base = 1;
  expected_extent = 3;
  EXPECT_TRUE(iface->set_selection(native, 0, &range));
  EXPECT_EQ(calls, 4);
  EXPECT_EQ(iface->base.get_caret_position(native), 0u);
  // Identical masks may represent different UTF-16 boundaries. A partial
  // update must refresh the mapping even when no text notification is needed.
  const char* original = root.value;
  root.value = "Abcd";
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  expected_base = expected_extent = 2;
  EXPECT_TRUE(iface->set_caret_position(native, 2));
  EXPECT_EQ(calls, 5);
  root.value = original;
  flags.is_obscured = false;
  flags.is_hidden = true;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  EXPECT_FALSE(iface->set_caret_position(native, 0));
  EXPECT_FALSE(iface->set_selection(native, 0, &range));
  flags.is_hidden = false;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  expected_base = 1;
  expected_extent = 3;
  EXPECT_TRUE(iface->set_selection(native, 0, &range));
  EXPECT_EQ(calls, 6);
  g_object_run_dispose(G_OBJECT(view));
  EXPECT_FALSE(iface->set_caret_position(native, 0));
  EXPECT_FALSE(iface->set_selection(native, 0, &range));
  EXPECT_EQ(calls, 6);
}

TEST_F(FlViewGtk4AccessibilityTest, ObscuredValueIsNotExported) {
  if (!fl_view_gtk4_accessibility_native_tree_is_enabled_for_testing()) {
    GTEST_SKIP() << "Native GtkAccessible traversal requires GTK 4.10+";
  }
  g_autoptr(FlView) view = fl_view_new(project);
  g_object_ref_sink(view);
  FlutterSemanticsFlags flags = {};
  flags.is_text_field = true;
  flags.is_obscured = true;
  FlutterSemanticsNode2 root = {};
  root.value = "private value";
  root.flags2 = &flags;
  FlutterSemanticsNode2* nodes[] = {&root};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = fl_view_get_id(view);
  update.node_count = 1;
  update.nodes = nodes;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  g_autoptr(GtkAccessible) native =
      fl_view_gtk4_accessibility_ref_native_root_for_testing(
          view->accessibility_backend);
  EXPECT_FALSE(
      gtk_test_accessible_has_property(native, GTK_ACCESSIBLE_PROPERTY_LABEL));
  EXPECT_FALSE(gtk_test_accessible_has_property(
      native, GTK_ACCESSIBLE_PROPERTY_VALUE_TEXT));

  if (!fl_gtk_runtime_supports_native_accessibility_text()) {
    return;
  }
  g_autoptr(GBytes) initial_mask =
      fl_view_gtk4_accessibility_ref_native_text_for_testing(native);
  ASSERT_NE(initial_mask, nullptr);
  EXPECT_EQ(g_bytes_get_size(initial_mask), strlen(root.value));
  g_autofree gchar* expected_mask = g_strnfill(strlen(root.value), '*');
  EXPECT_EQ(memcmp(g_bytes_get_data(initial_mask, nullptr), expected_mask,
                   strlen(root.value)),
            0);
  flags.is_obscured = false;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  g_autoptr(GtkAccessible) readable =
      fl_view_gtk4_accessibility_ref_native_root_for_testing(
          view->accessibility_backend);
  ASSERT_EQ(readable, native);
  g_autoptr(GBytes) before =
      fl_view_gtk4_accessibility_ref_native_text_for_testing(readable);
  ASSERT_NE(before, nullptr);
  EXPECT_EQ(g_bytes_get_size(before), strlen(root.value));

  flags.is_obscured = true;
  root.label = "Password";
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  g_autofree gchar* mismatch = gtk_test_accessible_check_property(
      readable, GTK_ACCESSIBLE_PROPERTY_LABEL, "Password");
  EXPECT_EQ(mismatch, nullptr);
  EXPECT_FALSE(gtk_test_accessible_has_property(
      readable, GTK_ACCESSIBLE_PROPERTY_VALUE_TEXT));
  g_autoptr(GBytes) after =
      fl_view_gtk4_accessibility_ref_native_text_for_testing(readable);
  ASSERT_NE(after, nullptr);
  ASSERT_EQ(g_bytes_get_size(after), strlen(root.value));
  EXPECT_EQ(memcmp(g_bytes_get_data(after, nullptr), expected_mask,
                   strlen(root.value)),
            0);

  // A role change replaces the native object. Clients holding the old text
  // object must not be able to read its former value after protection changes.
  flags.is_obscured = false;
  root.label = nullptr;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  flags.is_obscured = true;
  flags.is_text_field = false;
  flags.is_button = true;
  fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                           &update);
  g_autoptr(GtkAccessible) replacement =
      fl_view_gtk4_accessibility_ref_native_root_for_testing(
          view->accessibility_backend);
  ASSERT_NE(replacement, readable);
  EXPECT_FALSE(gtk_test_accessible_has_property(readable,
                                                GTK_ACCESSIBLE_PROPERTY_LABEL));
  EXPECT_FALSE(gtk_test_accessible_has_property(
      readable, GTK_ACCESSIBLE_PROPERTY_VALUE_TEXT));
  g_autoptr(GBytes) detached =
      fl_view_gtk4_accessibility_ref_native_text_for_testing(readable);
  ASSERT_NE(detached, nullptr);
  ASSERT_EQ(g_bytes_get_size(detached), 1u);
  EXPECT_EQ(*static_cast<const char*>(g_bytes_get_data(detached, nullptr)),
            '\0');
}

}  // namespace

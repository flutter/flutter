// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Included first as it collides with the X11 headers.
#include "gtest/gtest.h"

#include "flutter/shell/platform/linux/fl_accessible_node.h"
#include "flutter/shell/platform/linux/testing/mock_gtk.h"

class FlAccessibleNodeTest : public ::testing::Test {
 protected:
  void SetUp() override {
    g_autoptr(FlDartProject) project = fl_dart_project_new();
    engine = fl_engine_new(project);
  }

  ~FlAccessibleNodeTest() { g_object_unref(engine); }

  ::testing::NiceMock<flutter::testing::MockGtk> mock_gtk;
  FlEngine* engine;
};

// Checks can build a tree of nodes.
TEST_F(FlAccessibleNodeTest, BuildTree) {
  int64_t view_id = 123;
  g_autoptr(FlAccessibleNode) root = fl_accessible_node_new(engine, view_id, 0);
  g_autoptr(FlAccessibleNode) child1 =
      fl_accessible_node_new(engine, view_id, 1);
  fl_accessible_node_set_parent(child1, ATK_OBJECT(root), 0);
  g_autoptr(FlAccessibleNode) child2 =
      fl_accessible_node_new(engine, view_id, 1);
  fl_accessible_node_set_parent(child2, ATK_OBJECT(root), 1);
  g_autoptr(GPtrArray) children =
      g_ptr_array_new_with_free_func(g_object_unref);
  g_ptr_array_add(children, g_object_ref(child1));
  g_ptr_array_add(children, g_object_ref(child2));
  fl_accessible_node_set_children(root, children);

  EXPECT_EQ(atk_object_get_n_accessible_children(ATK_OBJECT(root)), 2);
  EXPECT_EQ(atk_object_get_index_in_parent(ATK_OBJECT(root)), 0);
  g_autoptr(AtkObject) c1 =
      atk_object_ref_accessible_child(ATK_OBJECT(root), 0);
  EXPECT_EQ(ATK_OBJECT(child1), c1);
  g_autoptr(AtkObject) c2 =
      atk_object_ref_accessible_child(ATK_OBJECT(root), 1);
  EXPECT_EQ(ATK_OBJECT(child2), c2);
  EXPECT_EQ(atk_object_get_parent(ATK_OBJECT(root)), nullptr);

  EXPECT_EQ(atk_object_get_parent(ATK_OBJECT(child1)), ATK_OBJECT(root));
  EXPECT_EQ(atk_object_get_index_in_parent(ATK_OBJECT(child1)), 0);
  EXPECT_EQ(atk_object_get_n_accessible_children(ATK_OBJECT(child1)), 0);

  EXPECT_EQ(atk_object_get_parent(ATK_OBJECT(child2)), ATK_OBJECT(root));
  EXPECT_EQ(atk_object_get_index_in_parent(ATK_OBJECT(child2)), 1);
  EXPECT_EQ(atk_object_get_n_accessible_children(ATK_OBJECT(child2)), 0);
}

// Checks node name is exposed to ATK.
TEST_F(FlAccessibleNodeTest, SetName) {
  g_autoptr(FlAccessibleNode) node = fl_accessible_node_new(engine, 123, 0);
  fl_accessible_node_set_name(node, "test");
  EXPECT_STREQ(atk_object_get_name(ATK_OBJECT(node)), "test");
}

// Checks node extents are exposed to ATK.
TEST_F(FlAccessibleNodeTest, SetExtents) {
  g_autoptr(FlAccessibleNode) node = fl_accessible_node_new(engine, 123, 0);
  fl_accessible_node_set_extents(node, 1, 2, 3, 4);
  gint x, y, width, height;
  atk_component_get_extents(ATK_COMPONENT(node), &x, &y, &width, &height,
                            ATK_XY_PARENT);
  EXPECT_EQ(x, 1);
  EXPECT_EQ(y, 2);
  EXPECT_EQ(width, 3);
  EXPECT_EQ(height, 4);
}

// Checks the Flutter focused flag are mapped to ATK flags.
TEST_F(FlAccessibleNodeTest, FocusedFlags) {
  g_autoptr(FlAccessibleNode) node = fl_accessible_node_new(engine, 123, 0);

  FlutterSemanticsFlags flags1 = {};
  flags1.is_focused = kFlutterTristateNone;
  fl_accessible_node_set_flags(node, &flags1);
  AtkStateSet* state1 = atk_object_ref_state_set(ATK_OBJECT(node));
  EXPECT_FALSE(atk_state_set_contains_state(state1, ATK_STATE_FOCUSABLE));
  EXPECT_FALSE(atk_state_set_contains_state(state1, ATK_STATE_FOCUSED));
  g_object_unref(state1);

  FlutterSemanticsFlags flags2 = {};
  flags2.is_focused = kFlutterTristateFalse;
  EXPECT_CALL(mock_gtk, atk_object_notify_state_change(
                            ::testing::_, ATK_STATE_FOCUSABLE, TRUE));
  fl_accessible_node_set_flags(node, &flags2);
  AtkStateSet* state2 = atk_object_ref_state_set(ATK_OBJECT(node));
  EXPECT_TRUE(atk_state_set_contains_state(state2, ATK_STATE_FOCUSABLE));
  EXPECT_FALSE(atk_state_set_contains_state(state2, ATK_STATE_FOCUSED));
  g_object_unref(state2);

  FlutterSemanticsFlags flags3 = {};
  flags3.is_focused = kFlutterTristateTrue;
  EXPECT_CALL(mock_gtk, atk_object_notify_state_change(
                            ::testing::_, ATK_STATE_FOCUSED, TRUE));
  fl_accessible_node_set_flags(node, &flags3);
  AtkStateSet* state3 = atk_object_ref_state_set(ATK_OBJECT(node));
  EXPECT_TRUE(atk_state_set_contains_state(state3, ATK_STATE_FOCUSABLE));
  EXPECT_TRUE(atk_state_set_contains_state(state3, ATK_STATE_FOCUSED));
  g_object_unref(state3);
}

// Checks the Flutter checked and toggled flags are mapped to ATK flags.
TEST_F(FlAccessibleNodeTest, CheckedAndToggledFlags) {
  g_autoptr(FlAccessibleNode) node = fl_accessible_node_new(engine, 123, 0);

  FlutterSemanticsFlags flags1 = {};
  flags1.is_checked = kFlutterCheckStateNone;
  flags1.is_toggled = kFlutterTristateNone;
  fl_accessible_node_set_flags(node, &flags1);
  AtkStateSet* state1 = atk_object_ref_state_set(ATK_OBJECT(node));
  EXPECT_FALSE(atk_state_set_contains_state(state1, ATK_STATE_CHECKABLE));
  EXPECT_FALSE(atk_state_set_contains_state(state1, ATK_STATE_CHECKED));
  g_object_unref(state1);

  FlutterSemanticsFlags flags2 = {};
  flags2.is_checked = kFlutterCheckStateFalse;
  flags2.is_toggled = kFlutterTristateFalse;
  EXPECT_CALL(mock_gtk, atk_object_notify_state_change(
                            ::testing::_, ATK_STATE_CHECKABLE, TRUE));
  fl_accessible_node_set_flags(node, &flags2);
  AtkStateSet* state2 = atk_object_ref_state_set(ATK_OBJECT(node));
  EXPECT_TRUE(atk_state_set_contains_state(state2, ATK_STATE_CHECKABLE));
  EXPECT_FALSE(atk_state_set_contains_state(state2, ATK_STATE_CHECKED));
  g_object_unref(state2);

  FlutterSemanticsFlags flags3 = {};
  flags3.is_checked = kFlutterCheckStateTrue;
  flags3.is_toggled = kFlutterTristateTrue;
  EXPECT_CALL(mock_gtk, atk_object_notify_state_change(
                            ::testing::_, ATK_STATE_CHECKED, TRUE));
  fl_accessible_node_set_flags(node, &flags3);
  AtkStateSet* state3 = atk_object_ref_state_set(ATK_OBJECT(node));
  EXPECT_TRUE(atk_state_set_contains_state(state3, ATK_STATE_CHECKABLE));
  EXPECT_TRUE(atk_state_set_contains_state(state3, ATK_STATE_CHECKED));
  g_object_unref(state3);

  FlutterSemanticsFlags flags4 = {};
  flags4.is_checked = kFlutterCheckStateTrue;
  flags4.is_toggled = kFlutterTristateNone;
  fl_accessible_node_set_flags(node, &flags4);
  AtkStateSet* state4 = atk_object_ref_state_set(ATK_OBJECT(node));
  EXPECT_TRUE(atk_state_set_contains_state(state4, ATK_STATE_CHECKABLE));
  EXPECT_TRUE(atk_state_set_contains_state(state4, ATK_STATE_CHECKED));
  g_object_unref(state4);

  FlutterSemanticsFlags flags5 = {};
  flags5.is_checked = kFlutterCheckStateNone;
  flags5.is_toggled = kFlutterTristateTrue;
  fl_accessible_node_set_flags(node, &flags5);
  AtkStateSet* state5 = atk_object_ref_state_set(ATK_OBJECT(node));
  EXPECT_TRUE(atk_state_set_contains_state(state5, ATK_STATE_CHECKABLE));
  EXPECT_TRUE(atk_state_set_contains_state(state5, ATK_STATE_CHECKED));
  g_object_unref(state5);
}

// Checks the Flutter selected flag is mapped to ATK flags.
TEST_F(FlAccessibleNodeTest, SelectedFlags) {
  g_autoptr(FlAccessibleNode) node = fl_accessible_node_new(engine, 123, 0);

  FlutterSemanticsFlags flags1 = {};
  flags1.is_selected = kFlutterTristateNone;
  fl_accessible_node_set_flags(node, &flags1);
  AtkStateSet* state1 = atk_object_ref_state_set(ATK_OBJECT(node));
  EXPECT_FALSE(atk_state_set_contains_state(state1, ATK_STATE_SELECTED));
  g_object_unref(state1);

  FlutterSemanticsFlags flags2 = {};
  flags2.is_selected = kFlutterTristateFalse;
  fl_accessible_node_set_flags(node, &flags2);
  AtkStateSet* state2 = atk_object_ref_state_set(ATK_OBJECT(node));
  EXPECT_FALSE(atk_state_set_contains_state(state2, ATK_STATE_SELECTED));
  g_object_unref(state2);

  FlutterSemanticsFlags flags3 = {};
  flags3.is_selected = kFlutterTristateTrue;
  EXPECT_CALL(mock_gtk, atk_object_notify_state_change(
                            ::testing::_, ATK_STATE_SELECTED, TRUE));
  fl_accessible_node_set_flags(node, &flags3);
  AtkStateSet* state3 = atk_object_ref_state_set(ATK_OBJECT(node));
  EXPECT_TRUE(atk_state_set_contains_state(state3, ATK_STATE_SELECTED));
  g_object_unref(state3);
}

// Checks the Flutter enabled flag is mapped to ATK flags.
TEST_F(FlAccessibleNodeTest, EnabledFlags) {
  g_autoptr(FlAccessibleNode) node = fl_accessible_node_new(engine, 123, 0);

  FlutterSemanticsFlags flags1 = {};
  flags1.is_enabled = kFlutterTristateNone;
  fl_accessible_node_set_flags(node, &flags1);
  AtkStateSet* state1 = atk_object_ref_state_set(ATK_OBJECT(node));
  EXPECT_FALSE(atk_state_set_contains_state(state1, ATK_STATE_SENSITIVE));
  EXPECT_FALSE(atk_state_set_contains_state(state1, ATK_STATE_ENABLED));
  g_object_unref(state1);

  FlutterSemanticsFlags flags2 = {};
  flags2.is_enabled = kFlutterTristateFalse;
  EXPECT_CALL(mock_gtk, atk_object_notify_state_change(
                            ::testing::_, ATK_STATE_SENSITIVE, TRUE));
  fl_accessible_node_set_flags(node, &flags2);
  AtkStateSet* state2 = atk_object_ref_state_set(ATK_OBJECT(node));
  EXPECT_TRUE(atk_state_set_contains_state(state2, ATK_STATE_SENSITIVE));
  EXPECT_FALSE(atk_state_set_contains_state(state2, ATK_STATE_ENABLED));
  g_object_unref(state2);

  FlutterSemanticsFlags flags3 = {};
  flags3.is_enabled = kFlutterTristateTrue;
  EXPECT_CALL(mock_gtk, atk_object_notify_state_change(
                            ::testing::_, ATK_STATE_ENABLED, TRUE));
  fl_accessible_node_set_flags(node, &flags3);
  AtkStateSet* state3 = atk_object_ref_state_set(ATK_OBJECT(node));
  EXPECT_TRUE(atk_state_set_contains_state(state3, ATK_STATE_SENSITIVE));
  EXPECT_TRUE(atk_state_set_contains_state(state3, ATK_STATE_ENABLED));
  g_object_unref(state3);
}

// Checks the Flutter obscured flag is mapped to ATK flags.
TEST_F(FlAccessibleNodeTest, ObscuredFlags) {
  g_autoptr(FlAccessibleNode) node = fl_accessible_node_new(engine, 123, 0);

  FlutterSemanticsFlags flags1 = {};
  flags1.is_obscured = true;
  fl_accessible_node_set_flags(node, &flags1);
  AtkStateSet* state1 = atk_object_ref_state_set(ATK_OBJECT(node));
  EXPECT_FALSE(atk_state_set_contains_state(state1, ATK_STATE_SHOWING));
  g_object_unref(state1);

  FlutterSemanticsFlags flags2 = {};
  flags2.is_obscured = false;
  EXPECT_CALL(mock_gtk, atk_object_notify_state_change(
                            ::testing::_, ATK_STATE_SHOWING, TRUE));
  fl_accessible_node_set_flags(node, &flags2);
  AtkStateSet* state2 = atk_object_ref_state_set(ATK_OBJECT(node));
  EXPECT_TRUE(atk_state_set_contains_state(state2, ATK_STATE_SHOWING));
  g_object_unref(state2);
}

// Checks the Flutter hidden flag is mapped to ATK flags.
TEST_F(FlAccessibleNodeTest, HiddenFlags) {
  g_autoptr(FlAccessibleNode) node = fl_accessible_node_new(engine, 123, 0);

  FlutterSemanticsFlags flags1 = {};
  flags1.is_hidden = true;
  fl_accessible_node_set_flags(node, &flags1);
  AtkStateSet* state1 = atk_object_ref_state_set(ATK_OBJECT(node));
  EXPECT_FALSE(atk_state_set_contains_state(state1, ATK_STATE_VISIBLE));
  g_object_unref(state1);

  FlutterSemanticsFlags flags2 = {};
  flags2.is_hidden = false;
  EXPECT_CALL(mock_gtk, atk_object_notify_state_change(
                            ::testing::_, ATK_STATE_VISIBLE, TRUE));
  fl_accessible_node_set_flags(node, &flags2);
  AtkStateSet* state2 = atk_object_ref_state_set(ATK_OBJECT(node));
  EXPECT_TRUE(atk_state_set_contains_state(state2, ATK_STATE_VISIBLE));
  g_object_unref(state2);
}

// Checks the Flutter read only flag is mapped to ATK flags.
TEST_F(FlAccessibleNodeTest, ReadOnlyFlags) {
  g_autoptr(FlAccessibleNode) node = fl_accessible_node_new(engine, 123, 0);

  FlutterSemanticsFlags flags1 = {};
  flags1.is_read_only = false;
  fl_accessible_node_set_flags(node, &flags1);
  AtkStateSet* state1 = atk_object_ref_state_set(ATK_OBJECT(node));
  EXPECT_FALSE(atk_state_set_contains_state(state1, ATK_STATE_READ_ONLY));
  g_object_unref(state1);

  FlutterSemanticsFlags flags2 = {};
  flags2.is_read_only = true;
  EXPECT_CALL(mock_gtk, atk_object_notify_state_change(
                            ::testing::_, ATK_STATE_READ_ONLY, TRUE));
  fl_accessible_node_set_flags(node, &flags2);
  AtkStateSet* state2 = atk_object_ref_state_set(ATK_OBJECT(node));
  EXPECT_TRUE(atk_state_set_contains_state(state2, ATK_STATE_READ_ONLY));
  g_object_unref(state2);
}

// Checks the Flutter text field flag is mapped to ATK flags.
TEST_F(FlAccessibleNodeTest, TextFieldFlags) {
  g_autoptr(FlAccessibleNode) node = fl_accessible_node_new(engine, 123, 0);

  FlutterSemanticsFlags flags1 = {};
  flags1.is_text_field = false;
  fl_accessible_node_set_flags(node, &flags1);
  AtkStateSet* state1 = atk_object_ref_state_set(ATK_OBJECT(node));
  EXPECT_FALSE(atk_state_set_contains_state(state1, ATK_STATE_EDITABLE));
  g_object_unref(state1);

  FlutterSemanticsFlags flags2 = {};
  flags2.is_text_field = true;
  EXPECT_CALL(mock_gtk, atk_object_notify_state_change(
                            ::testing::_, ATK_STATE_EDITABLE, TRUE));
  fl_accessible_node_set_flags(node, &flags2);
  AtkStateSet* state2 = atk_object_ref_state_set(ATK_OBJECT(node));
  EXPECT_TRUE(atk_state_set_contains_state(state2, ATK_STATE_EDITABLE));
  g_object_unref(state2);
}

// Checks Flutter flags are mapped to appropriate ATK roles.
TEST_F(FlAccessibleNodeTest, GetRole) {
  g_autoptr(FlAccessibleNode) node = fl_accessible_node_new(engine, 123, 0);

  FlutterSemanticsFlags flags1 = {};
  flags1.is_button = true;
  fl_accessible_node_set_flags(node, &flags1);
  EXPECT_EQ(atk_object_get_role(ATK_OBJECT(node)), ATK_ROLE_PUSH_BUTTON);

  FlutterSemanticsFlags flags2 = {};
  flags2.is_checked = kFlutterCheckStateFalse;
  fl_accessible_node_set_flags(node, &flags2);
  EXPECT_EQ(atk_object_get_role(ATK_OBJECT(node)), ATK_ROLE_CHECK_BOX);

  FlutterSemanticsFlags flags3 = {};
  flags3.is_checked = kFlutterCheckStateFalse;
  flags3.is_in_mutually_exclusive_group = true;
  fl_accessible_node_set_flags(node, &flags3);
  EXPECT_EQ(atk_object_get_role(ATK_OBJECT(node)), ATK_ROLE_RADIO_BUTTON);

  FlutterSemanticsFlags flags4 = {};
  flags4.is_toggled = kFlutterTristateFalse;
  fl_accessible_node_set_flags(node, &flags4);
  EXPECT_EQ(atk_object_get_role(ATK_OBJECT(node)), ATK_ROLE_TOGGLE_BUTTON);

  FlutterSemanticsFlags flags5 = {};
  flags5.is_text_field = true;
  fl_accessible_node_set_flags(node, &flags5);
  EXPECT_EQ(atk_object_get_role(ATK_OBJECT(node)), ATK_ROLE_TEXT);

  FlutterSemanticsFlags flags6 = {};
  flags6.is_text_field = true;
  flags6.is_obscured = true;
  fl_accessible_node_set_flags(node, &flags6);
  EXPECT_EQ(atk_object_get_role(ATK_OBJECT(node)), ATK_ROLE_PASSWORD_TEXT);
}

// Checks Flutter actions are mapped to the appropriate ATK actions.
TEST_F(FlAccessibleNodeTest, SetActions) {
  g_autoptr(FlAccessibleNode) node = fl_accessible_node_new(engine, 123, 0);
  fl_accessible_node_set_actions(
      node, static_cast<FlutterSemanticsAction>(
                kFlutterSemanticsActionTap | kFlutterSemanticsActionLongPress));

  EXPECT_EQ(atk_action_get_n_actions(ATK_ACTION(node)), 2);
  EXPECT_STREQ(atk_action_get_name(ATK_ACTION(node), 0), "Tap");
  EXPECT_STREQ(atk_action_get_name(ATK_ACTION(node), 1), "LongPress");
}

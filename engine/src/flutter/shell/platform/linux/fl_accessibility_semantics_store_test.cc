// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_accessibility_semantics_store.h"

#include "gtest/gtest.h"

TEST(FlAccessibilitySemanticsStoreTest, StoresNodesForMatchingView) {
  g_autoptr(FlAccessibilitySemanticsStore) store =
      fl_accessibility_semantics_store_new(123);

  int32_t children[] = {7, 8};
  FlutterSemanticsFlags flags = {};
  flags.is_text_field = kFlutterTristateTrue;
  FlutterSemanticsNode2 root = {.id = 0,
                                .actions = kFlutterSemanticsActionTap,
                                .text_selection_base = 2,
                                .text_selection_extent = 5,
                                .label = "root",
                                .value = "value",
                                .child_count = 2,
                                .children_in_traversal_order = children,
                                .flags2 = &flags,
                                .identifier = ""};
  FlutterSemanticsNode2* nodes[] = {&root};
  FlutterSemanticsUpdate2 update = {
      .node_count = 1,
      .nodes = nodes,
      .view_id = 123,
  };

  fl_accessibility_semantics_store_handle_update(store, &update);

  EXPECT_TRUE(fl_accessibility_semantics_store_has_root(store));
  const FlAccessibilitySemanticsNode* node =
      fl_accessibility_semantics_store_lookup_node(store, 0);
  ASSERT_NE(node, nullptr);
  EXPECT_EQ(node->id, 0);
  EXPECT_STREQ(node->label, "root");
  EXPECT_STREQ(node->value, "value");
  EXPECT_TRUE(node->flags.is_text_field);
  EXPECT_EQ(node->actions, kFlutterSemanticsActionTap);
  EXPECT_EQ(node->text_selection_base, 2);
  EXPECT_EQ(node->text_selection_extent, 5);
  EXPECT_EQ(node->child_count, static_cast<size_t>(2));
  ASSERT_NE(node->children_in_traversal_order, nullptr);
  EXPECT_EQ(node->children_in_traversal_order[0], 7);
  EXPECT_EQ(node->children_in_traversal_order[1], 8);
}

TEST(FlAccessibilitySemanticsStoreTest, IgnoresOtherViewUpdates) {
  g_autoptr(FlAccessibilitySemanticsStore) store =
      fl_accessibility_semantics_store_new(123);

  FlutterSemanticsFlags flags = {};
  FlutterSemanticsNode2 root = {
      .id = 0, .label = "root", .flags2 = &flags, .identifier = ""};
  FlutterSemanticsNode2* nodes[] = {&root};
  FlutterSemanticsUpdate2 update = {
      .node_count = 1,
      .nodes = nodes,
      .view_id = 999,
  };

  fl_accessibility_semantics_store_handle_update(store, &update);

  EXPECT_FALSE(fl_accessibility_semantics_store_has_root(store));
  EXPECT_EQ(fl_accessibility_semantics_store_lookup_node(store, 0), nullptr);
}

TEST(FlAccessibilitySemanticsStoreTest, ReplacesNodesOnSubsequentUpdates) {
  g_autoptr(FlAccessibilitySemanticsStore) store =
      fl_accessibility_semantics_store_new(123);

  FlutterSemanticsFlags flags = {};
  FlutterSemanticsNode2 root1 = {
      .id = 0, .label = "before", .flags2 = &flags, .identifier = ""};
  FlutterSemanticsNode2* nodes1[] = {&root1};
  FlutterSemanticsUpdate2 update1 = {
      .node_count = 1,
      .nodes = nodes1,
      .view_id = 123,
  };
  fl_accessibility_semantics_store_handle_update(store, &update1);

  FlutterSemanticsNode2 root2 = {
      .id = 0, .label = "after", .flags2 = &flags, .identifier = ""};
  FlutterSemanticsNode2* nodes2[] = {&root2};
  FlutterSemanticsUpdate2 update2 = {
      .node_count = 1,
      .nodes = nodes2,
      .view_id = 123,
  };
  fl_accessibility_semantics_store_handle_update(store, &update2);

  const FlAccessibilitySemanticsNode* node =
      fl_accessibility_semantics_store_lookup_node(store, 0);
  ASSERT_NE(node, nullptr);
  EXPECT_STREQ(node->label, "after");
}

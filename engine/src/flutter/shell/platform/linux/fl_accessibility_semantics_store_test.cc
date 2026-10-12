// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_accessibility_semantics_store.h"

#include "gtest/gtest.h"

TEST(FlAccessibilitySemanticsStoreTest, PrunesDetachedSubtreesAfterBatch) {
  g_autoptr(FlAccessibilitySemanticsStore) store =
      fl_accessibility_semantics_store_new(123);
  int32_t children[] = {1};
  int32_t grandchildren[] = {2};
  FlutterSemanticsNode2 root = {};
  root.id = 0;
  root.child_count = 1;
  root.children_in_traversal_order = children;
  FlutterSemanticsNode2 child = {};
  child.id = 1;
  child.child_count = 1;
  child.children_in_traversal_order = grandchildren;
  FlutterSemanticsNode2 grandchild = {};
  grandchild.id = 2;
  FlutterSemanticsNode2* nodes[] = {&grandchild, &child, &root};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = 123;
  update.node_count = 3;
  update.nodes = nodes;
  fl_accessibility_semantics_store_handle_update(store, &update);
  ASSERT_NE(fl_accessibility_semantics_store_lookup_node(store, 2), nullptr);

  // A root-only update must preserve descendants omitted from the batch.
  FlutterSemanticsNode2* root_only[] = {&root};
  update.node_count = 1;
  update.nodes = root_only;
  fl_accessibility_semantics_store_handle_update(store, &update);
  EXPECT_NE(fl_accessibility_semantics_store_lookup_node(store, 2), nullptr);

  root.child_count = 0;
  root.children_in_traversal_order = nullptr;
  fl_accessibility_semantics_store_handle_update(store, &update);
  EXPECT_NE(fl_accessibility_semantics_store_lookup_node(store, 0), nullptr);
  EXPECT_EQ(fl_accessibility_semantics_store_lookup_node(store, 1), nullptr);
  EXPECT_EQ(fl_accessibility_semantics_store_lookup_node(store, 2), nullptr);
}

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

TEST(FlAccessibilitySemanticsStoreTest,
     DistinguishesContentAndStructureChanges) {
  g_autoptr(FlAccessibilitySemanticsStore) store =
      fl_accessibility_semantics_store_new(123);
  FlutterSemanticsNode2 root = {};
  root.label = "before";
  FlutterSemanticsNode2* nodes[] = {&root};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = 123;
  update.node_count = 1;
  update.nodes = nodes;
  fl_accessibility_semantics_store_handle_update(store, &update);
  EXPECT_TRUE(fl_accessibility_semantics_store_structure_changed(store));
  const auto* original = fl_accessibility_semantics_store_lookup_node(store, 0);
  const guint64 revision = original->revision;

  fl_accessibility_semantics_store_handle_update(store, &update);
  EXPECT_FALSE(fl_accessibility_semantics_store_structure_changed(store));
  EXPECT_EQ(fl_accessibility_semantics_store_lookup_node(store, 0), original);
  EXPECT_EQ(original->revision, revision);

  root.label = "after";
  fl_accessibility_semantics_store_handle_update(store, &update);
  EXPECT_FALSE(fl_accessibility_semantics_store_structure_changed(store));
  EXPECT_GT(fl_accessibility_semantics_store_lookup_node(store, 0)->revision,
            revision);

  int32_t children[] = {1, 2};
  root.child_count = 2;
  root.children_in_traversal_order = children;
  fl_accessibility_semantics_store_handle_update(store, &update);
  EXPECT_TRUE(fl_accessibility_semantics_store_structure_changed(store));
  children[0] = 2;
  children[1] = 1;
  fl_accessibility_semantics_store_handle_update(store, &update);
  EXPECT_TRUE(fl_accessibility_semantics_store_structure_changed(store));
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

TEST(FlAccessibilitySemanticsStoreTest, HitOrderUpdatesPreserveTraversalTree) {
  g_autoptr(FlAccessibilitySemanticsStore) store =
      fl_accessibility_semantics_store_new(123);
  int32_t traversal[] = {1, 2};
  int32_t hit_order[] = {1, 2};
  FlutterSemanticsNode2 root = {};
  root.child_count = 2;
  root.children_in_traversal_order = traversal;
  root.children_in_hit_test_order = hit_order;
  FlutterSemanticsNode2 first = {};
  first.id = 1;
  FlutterSemanticsNode2 second = {};
  second.id = 2;
  FlutterSemanticsNode2* nodes[] = {&root, &first, &second};
  FlutterSemanticsUpdate2 update = {};
  update.view_id = 123;
  update.node_count = 3;
  update.nodes = nodes;
  fl_accessibility_semantics_store_handle_update(store, &update);
  const auto* old_root = fl_accessibility_semantics_store_lookup_node(store, 0);
  const guint64 revision = old_root->revision;
  ASSERT_NE(old_root->children_in_hit_test_order, nullptr);
  EXPECT_NE(old_root->children_in_hit_test_order, hit_order);
  const auto* old_first =
      fl_accessibility_semantics_store_lookup_node(store, 1);
  const auto* old_second =
      fl_accessibility_semantics_store_lookup_node(store, 2);

  // Only the parent hit order changes; reading order and descendants remain.
  hit_order[0] = 2;
  hit_order[1] = 1;
  EXPECT_EQ(old_root->children_in_hit_test_order[0], 1);
  EXPECT_EQ(old_root->children_in_hit_test_order[1], 2);
  update.node_count = 1;
  fl_accessibility_semantics_store_handle_update(store, &update);
  const auto* reordered =
      fl_accessibility_semantics_store_lookup_node(store, 0);
  EXPECT_GT(reordered->revision, revision);
  ASSERT_NE(reordered->children_in_hit_test_order, nullptr);
  EXPECT_EQ(reordered->children_in_hit_test_order[0], 2);
  EXPECT_EQ(reordered->children_in_hit_test_order[1], 1);
  EXPECT_FALSE(fl_accessibility_semantics_store_structure_changed(store));
  EXPECT_EQ(reordered->children_in_traversal_order[0], 1);
  EXPECT_EQ(reordered->children_in_traversal_order[1], 2);
  EXPECT_EQ(fl_accessibility_semantics_store_lookup_node(store, 1), old_first);
  EXPECT_EQ(fl_accessibility_semantics_store_lookup_node(store, 2), old_second);

  // Identical order is a no-op; omission is a real update, not a stale order.
  const guint64 reordered_revision = reordered->revision;
  fl_accessibility_semantics_store_handle_update(store, &update);
  EXPECT_EQ(fl_accessibility_semantics_store_lookup_node(store, 0), reordered);
  root.children_in_hit_test_order = nullptr;
  fl_accessibility_semantics_store_handle_update(store, &update);
  const auto* omitted = fl_accessibility_semantics_store_lookup_node(store, 0);
  EXPECT_GT(omitted->revision, reordered_revision);
  EXPECT_EQ(omitted->children_in_hit_test_order, nullptr);
  EXPECT_FALSE(fl_accessibility_semantics_store_structure_changed(store));
  fl_accessibility_semantics_store_handle_update(store, &update);
  EXPECT_EQ(fl_accessibility_semantics_store_lookup_node(store, 0), omitted);

  root.children_in_hit_test_order = hit_order;
  fl_accessibility_semantics_store_handle_update(store, &update);
  const auto* restored = fl_accessibility_semantics_store_lookup_node(store, 0);
  ASSERT_NE(restored->children_in_hit_test_order, nullptr);
  EXPECT_EQ(restored->children_in_hit_test_order[0], 2);
  root.child_count = 0;
  root.children_in_traversal_order = nullptr;
  fl_accessibility_semantics_store_handle_update(store, &update);
  EXPECT_EQ(fl_accessibility_semantics_store_lookup_node(store, 0)
                ->children_in_hit_test_order,
            nullptr);
  EXPECT_EQ(fl_accessibility_semantics_store_lookup_node(store, 1), nullptr);
  EXPECT_EQ(fl_accessibility_semantics_store_lookup_node(store, 2), nullptr);
}

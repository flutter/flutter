// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "accessibility_bridge.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"

#include "test_accessibility_bridge.h"

namespace flutter {
namespace testing {

using ::testing::Contains;

TEST(AccessibilityBridgeTest, basicTest) {
  std::shared_ptr<AccessibilityBridge> bridge =
      std::make_shared<AccessibilityBridge>(
          std::make_unique<TestAccessibilityBridgeDelegate>());
  FlutterSemanticsNode root;
  root.id = 0;
  root.label = "root";
  root.hint = "";
  root.value = "";
  root.increased_value = "";
  root.decreased_value = "";
  root.child_count = 2;
  int32_t children[] = {1, 2};
  root.children_in_traversal_order = children;
  root.custom_accessibility_actions_count = 0;
  bridge->AddFlutterSemanticsNodeUpdate(&root);

  FlutterSemanticsNode child1;
  child1.id = 1;
  child1.label = "child 1";
  child1.hint = "";
  child1.value = "";
  child1.increased_value = "";
  child1.decreased_value = "";
  child1.child_count = 0;
  child1.custom_accessibility_actions_count = 0;
  bridge->AddFlutterSemanticsNodeUpdate(&child1);

  FlutterSemanticsNode child2;
  child2.id = 2;
  child2.label = "child 2";
  child2.hint = "";
  child2.value = "";
  child2.increased_value = "";
  child2.decreased_value = "";
  child2.child_count = 0;
  child2.custom_accessibility_actions_count = 0;
  bridge->AddFlutterSemanticsNodeUpdate(&child2);

  bridge->CommitUpdates();

  auto root_node = bridge->GetFlutterPlatformNodeDelegateFromID(0).lock();
  auto child1_node = bridge->GetFlutterPlatformNodeDelegateFromID(1).lock();
  auto child2_node = bridge->GetFlutterPlatformNodeDelegateFromID(2).lock();
  EXPECT_EQ(root_node->GetChildCount(), 2);
  EXPECT_EQ(root_node->GetData().child_ids[0], 1);
  EXPECT_EQ(root_node->GetData().child_ids[1], 2);
  EXPECT_EQ(root_node->GetName(), "root");

  EXPECT_EQ(child1_node->GetChildCount(), 0);
  EXPECT_EQ(child1_node->GetName(), "child 1");

  EXPECT_EQ(child2_node->GetChildCount(), 0);
  EXPECT_EQ(child2_node->GetName(), "child 2");
}

TEST(AccessibilityBridgeTest, canFireChildrenChangedCorrectly) {
  TestAccessibilityBridgeDelegate* delegate =
      new TestAccessibilityBridgeDelegate();
  std::unique_ptr<TestAccessibilityBridgeDelegate> ptr(delegate);
  std::shared_ptr<AccessibilityBridge> bridge =
      std::make_shared<AccessibilityBridge>(std::move(ptr));
  FlutterSemanticsNode root;
  root.id = 0;
  root.flags = static_cast<FlutterSemanticsFlag>(0);
  root.actions = static_cast<FlutterSemanticsAction>(0);
  root.text_selection_base = -1;
  root.text_selection_extent = -1;
  root.label = "root";
  root.hint = "";
  root.value = "";
  root.increased_value = "";
  root.decreased_value = "";
  root.child_count = 1;
  int32_t children[] = {1};
  root.children_in_traversal_order = children;
  root.custom_accessibility_actions_count = 0;
  bridge->AddFlutterSemanticsNodeUpdate(&root);

  FlutterSemanticsNode child1;
  child1.id = 1;
  child1.flags = static_cast<FlutterSemanticsFlag>(0);
  child1.actions = static_cast<FlutterSemanticsAction>(0);
  child1.text_selection_base = -1;
  child1.text_selection_extent = -1;
  child1.label = "child 1";
  child1.hint = "";
  child1.value = "";
  child1.increased_value = "";
  child1.decreased_value = "";
  child1.child_count = 0;
  child1.custom_accessibility_actions_count = 0;
  bridge->AddFlutterSemanticsNodeUpdate(&child1);

  bridge->CommitUpdates();

  auto root_node = bridge->GetFlutterPlatformNodeDelegateFromID(0).lock();
  auto child1_node = bridge->GetFlutterPlatformNodeDelegateFromID(1).lock();
  EXPECT_EQ(root_node->GetChildCount(), 1);
  EXPECT_EQ(root_node->GetData().child_ids[0], 1);
  EXPECT_EQ(root_node->GetName(), "root");

  EXPECT_EQ(child1_node->GetChildCount(), 0);
  EXPECT_EQ(child1_node->GetName(), "child 1");
  delegate->accessibility_events.clear();

  // Add a child to root.
  root.child_count = 2;
  int32_t new_children[] = {1, 2};
  root.children_in_traversal_order = new_children;
  bridge->AddFlutterSemanticsNodeUpdate(&root);

  FlutterSemanticsNode child2;
  child2.id = 2;
  child2.flags = static_cast<FlutterSemanticsFlag>(0);
  child2.actions = static_cast<FlutterSemanticsAction>(0);
  child2.text_selection_base = -1;
  child2.text_selection_extent = -1;
  child2.label = "child 2";
  child2.hint = "";
  child2.value = "";
  child2.increased_value = "";
  child2.decreased_value = "";
  child2.child_count = 0;
  child2.custom_accessibility_actions_count = 0;
  bridge->AddFlutterSemanticsNodeUpdate(&child2);

  bridge->CommitUpdates();

  root_node = bridge->GetFlutterPlatformNodeDelegateFromID(0).lock();

  EXPECT_EQ(root_node->GetChildCount(), 2);
  EXPECT_EQ(root_node->GetData().child_ids[0], 1);
  EXPECT_EQ(root_node->GetData().child_ids[1], 2);
  EXPECT_EQ(delegate->accessibility_events.size(), size_t{2});
  std::set<ui::AXEventGenerator::Event> actual_event{
      delegate->accessibility_events.begin(),
      delegate->accessibility_events.end()};
  EXPECT_THAT(actual_event,
              Contains(ui::AXEventGenerator::Event::CHILDREN_CHANGED));
  EXPECT_THAT(actual_event,
              Contains(ui::AXEventGenerator::Event::SUBTREE_CREATED));
}

TEST(AccessibilityBridgeTest, canUpdateDelegate) {
  std::shared_ptr<AccessibilityBridge> bridge =
      std::make_shared<AccessibilityBridge>(
          std::make_unique<TestAccessibilityBridgeDelegate>());
  FlutterSemanticsNode root;
  root.id = 0;
  root.flags = static_cast<FlutterSemanticsFlag>(0);
  root.actions = static_cast<FlutterSemanticsAction>(0);
  root.text_selection_base = -1;
  root.text_selection_extent = -1;
  root.label = "root";
  root.hint = "";
  root.value = "";
  root.increased_value = "";
  root.decreased_value = "";
  root.child_count = 1;
  int32_t children[] = {1};
  root.children_in_traversal_order = children;
  root.custom_accessibility_actions_count = 0;
  bridge->AddFlutterSemanticsNodeUpdate(&root);

  FlutterSemanticsNode child1;
  child1.id = 1;
  child1.flags = static_cast<FlutterSemanticsFlag>(0);
  child1.actions = static_cast<FlutterSemanticsAction>(0);
  child1.text_selection_base = -1;
  child1.text_selection_extent = -1;
  child1.label = "child 1";
  child1.hint = "";
  child1.value = "";
  child1.increased_value = "";
  child1.decreased_value = "";
  child1.child_count = 0;
  child1.custom_accessibility_actions_count = 0;
  bridge->AddFlutterSemanticsNodeUpdate(&child1);

  bridge->CommitUpdates();

  auto root_node = bridge->GetFlutterPlatformNodeDelegateFromID(0);
  auto child1_node = bridge->GetFlutterPlatformNodeDelegateFromID(1);
  EXPECT_FALSE(root_node.expired());
  EXPECT_FALSE(child1_node.expired());
  // Update Delegate
  bridge->UpdateDelegate(std::make_unique<TestAccessibilityBridgeDelegate>());

  // Old tree is destroyed.
  EXPECT_TRUE(root_node.expired());
  EXPECT_TRUE(child1_node.expired());

  // New tree still has the data.
  auto new_root_node = bridge->GetFlutterPlatformNodeDelegateFromID(0).lock();
  auto new_child1_node = bridge->GetFlutterPlatformNodeDelegateFromID(1).lock();
  EXPECT_EQ(new_root_node->GetChildCount(), 1);
  EXPECT_EQ(new_root_node->GetData().child_ids[0], 1);
  EXPECT_EQ(new_root_node->GetName(), "root");

  EXPECT_EQ(new_child1_node->GetChildCount(), 0);
  EXPECT_EQ(new_child1_node->GetName(), "child 1");
}

TEST(AccessibilityBridgeTest, canHandleSelectionChangeCorrectly) {
  TestAccessibilityBridgeDelegate* delegate =
      new TestAccessibilityBridgeDelegate();
  std::unique_ptr<TestAccessibilityBridgeDelegate> ptr(delegate);
  std::shared_ptr<AccessibilityBridge> bridge =
      std::make_shared<AccessibilityBridge>(std::move(ptr));
  FlutterSemanticsNode root;
  root.id = 0;
  root.flags = FlutterSemanticsFlag::kFlutterSemanticsFlagIsTextField;
  root.actions = static_cast<FlutterSemanticsAction>(0);
  root.text_selection_base = -1;
  root.text_selection_extent = -1;
  root.label = "root";
  root.hint = "";
  root.value = "";
  root.increased_value = "";
  root.decreased_value = "";
  root.child_count = 0;
  root.custom_accessibility_actions_count = 0;
  bridge->AddFlutterSemanticsNodeUpdate(&root);

  bridge->CommitUpdates();

  const ui::AXTreeData& tree = bridge->GetAXTreeData();
  EXPECT_EQ(tree.sel_anchor_object_id, ui::AXNode::kInvalidAXID);
  delegate->accessibility_events.clear();

  // Update the selection.
  root.text_selection_base = 0;
  root.text_selection_extent = 5;
  bridge->AddFlutterSemanticsNodeUpdate(&root);

  bridge->CommitUpdates();

  EXPECT_EQ(tree.sel_anchor_object_id, 0);
  EXPECT_EQ(tree.sel_anchor_offset, 0);
  EXPECT_EQ(tree.sel_focus_object_id, 0);
  EXPECT_EQ(tree.sel_focus_offset, 5);
  ASSERT_EQ(delegate->accessibility_events.size(), size_t{2});
  EXPECT_EQ(delegate->accessibility_events[0],
            ui::AXEventGenerator::Event::DOCUMENT_SELECTION_CHANGED);
  EXPECT_EQ(delegate->accessibility_events[1],
            ui::AXEventGenerator::Event::OTHER_ATTRIBUTE_CHANGED);
}

TEST(AccessibilityBridgeTest, doesNotAssignEditableRootToSelectableText) {
  std::shared_ptr<AccessibilityBridge> bridge =
      std::make_shared<AccessibilityBridge>(
          std::make_unique<TestAccessibilityBridgeDelegate>());
  FlutterSemanticsNode root;
  root.id = 0;
  root.flags = static_cast<FlutterSemanticsFlag>(
      FlutterSemanticsFlag::kFlutterSemanticsFlagIsTextField |
      FlutterSemanticsFlag::kFlutterSemanticsFlagIsReadOnly);
  root.actions = static_cast<FlutterSemanticsAction>(0);
  root.text_selection_base = -1;
  root.text_selection_extent = -1;
  root.label = "root";
  root.hint = "";
  root.value = "";
  root.increased_value = "";
  root.decreased_value = "";
  root.child_count = 0;
  root.custom_accessibility_actions_count = 0;
  bridge->AddFlutterSemanticsNodeUpdate(&root);

  bridge->CommitUpdates();

  auto root_node = bridge->GetFlutterPlatformNodeDelegateFromID(0).lock();

  EXPECT_FALSE(root_node->GetData().GetBoolAttribute(
      ax::mojom::BoolAttribute::kEditableRoot));
}

TEST(AccessibilityBridgeTest, ToggleHasToggleButtonRole) {
  std::shared_ptr<AccessibilityBridge> bridge =
      std::make_shared<AccessibilityBridge>(
          std::make_unique<TestAccessibilityBridgeDelegate>());
  FlutterSemanticsNode root{.id = 0};
  root.flags = static_cast<FlutterSemanticsFlag>(
      FlutterSemanticsFlag::kFlutterSemanticsFlagHasToggledState |
      FlutterSemanticsFlag::kFlutterSemanticsFlagHasEnabledState |
      FlutterSemanticsFlag::kFlutterSemanticsFlagIsEnabled);
  root.actions = static_cast<FlutterSemanticsAction>(0);
  root.text_selection_base = -1;
  root.text_selection_extent = -1;
  root.label = "root";
  root.child_count = 0;
  root.custom_accessibility_actions_count = 0;
  bridge->AddFlutterSemanticsNodeUpdate(&root);
  bridge->CommitUpdates();

  auto root_node = bridge->GetFlutterPlatformNodeDelegateFromID(0).lock();
  EXPECT_EQ(root_node->GetData().role, ax::mojom::Role::kToggleButton);
}

TEST(AccessibilityBridgeTest, SliderHasSliderRole) {
  std::shared_ptr<AccessibilityBridge> bridge =
      std::make_shared<AccessibilityBridge>(
          std::make_unique<TestAccessibilityBridgeDelegate>());
  FlutterSemanticsNode root{.id = 0};
  root.flags = static_cast<FlutterSemanticsFlag>(
      FlutterSemanticsFlag::kFlutterSemanticsFlagIsSlider |
      FlutterSemanticsFlag::kFlutterSemanticsFlagHasEnabledState |
      FlutterSemanticsFlag::kFlutterSemanticsFlagIsEnabled |
      FlutterSemanticsFlag::kFlutterSemanticsFlagIsFocusable);
  root.actions = static_cast<FlutterSemanticsAction>(0);
  root.text_selection_base = -1;
  root.text_selection_extent = -1;
  root.label = "root";
  root.child_count = 0;
  root.custom_accessibility_actions_count = 0;
  bridge->AddFlutterSemanticsNodeUpdate(&root);
  bridge->CommitUpdates();

  auto root_node = bridge->GetFlutterPlatformNodeDelegateFromID(0).lock();
  EXPECT_EQ(root_node->GetData().role, ax::mojom::Role::kSlider);
}

}  // namespace testing
}  // namespace flutter

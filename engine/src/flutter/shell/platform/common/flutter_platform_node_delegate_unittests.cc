// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter_platform_node_delegate.h"

#include "flutter/third_party/accessibility/ax/ax_action_data.h"
#include "gtest/gtest.h"

#include "test_accessibility_bridge.h"

namespace flutter {
namespace testing {

TEST(FlutterPlatformNodeDelegateTest, NodeDelegateHasUniqueId) {
  std::shared_ptr<TestAccessibilityBridge> bridge =
      std::make_shared<TestAccessibilityBridge>();

  // Add node 0: root.
  FlutterSemanticsNode2 node0{sizeof(FlutterSemanticsNode2), 0};
  std::vector<int32_t> node0_children{1};
  FlutterSemanticsFlags emptyFlags = FlutterSemanticsFlags{};
  node0.child_count = node0_children.size();
  node0.children_in_traversal_order = node0_children.data();
  node0.children_in_hit_test_order = node0_children.data();
  node0.flags2 = &emptyFlags;

  // Add node 1: text child of node 0.
  FlutterSemanticsNode2 node1{sizeof(FlutterSemanticsNode2), 1};
  node1.label = "prefecture";
  node1.value = "Kyoto";
  node1.flags2 = &emptyFlags;

  bridge->AddFlutterSemanticsNodeUpdate(node0);
  bridge->AddFlutterSemanticsNodeUpdate(node1);
  bridge->CommitUpdates();

  auto node0_delegate = bridge->GetFlutterPlatformNodeDelegateFromID(0).lock();
  auto node1_delegate = bridge->GetFlutterPlatformNodeDelegateFromID(1).lock();
  EXPECT_TRUE(node0_delegate->GetUniqueId() != node1_delegate->GetUniqueId());
}

TEST(FlutterPlatformNodeDelegateTest, canPerfomActions) {
  std::shared_ptr<TestAccessibilityBridge> bridge =
      std::make_shared<TestAccessibilityBridge>();
  FlutterSemanticsNode2 root;
  root.id = 0;
  FlutterSemanticsFlags flags = FlutterSemanticsFlags{0};
  flags.is_text_field = true;
  root.flags2 = &flags;
  // NOLINTNEXTLINE(clang-analyzer-optin.core.EnumCastOutOfRange)
  root.actions = static_cast<FlutterSemanticsAction>(0);
  root.text_selection_base = -1;
  root.text_selection_extent = -1;
  root.label = "root";
  root.hint = "";
  root.value = "";
  root.increased_value = "";
  root.decreased_value = "";
  root.tooltip = "";
  root.child_count = 0;
  root.custom_accessibility_actions_count = 0;
  root.identifier = "";
  bridge->AddFlutterSemanticsNodeUpdate(root);

  bridge->CommitUpdates();

  auto accessibility = bridge->GetFlutterPlatformNodeDelegateFromID(0).lock();
  // Performs an AXAction.
  ui::AXActionData action_data;
  action_data.action = ax::mojom::Action::kDoDefault;
  accessibility->AccessibilityPerformAction(action_data);
  EXPECT_EQ(bridge->performed_actions.size(), size_t{1});
  EXPECT_EQ(bridge->performed_actions[0],
            FlutterSemanticsAction::kFlutterSemanticsActionTap);

  action_data.action = ax::mojom::Action::kFocus;
  accessibility->AccessibilityPerformAction(action_data);
  EXPECT_EQ(bridge->performed_actions.size(), size_t{2});
  EXPECT_EQ(
      bridge->performed_actions[1],
      FlutterSemanticsAction::kFlutterSemanticsActionDidGainAccessibilityFocus);

  action_data.action = ax::mojom::Action::kScrollToMakeVisible;
  accessibility->AccessibilityPerformAction(action_data);
  EXPECT_EQ(bridge->performed_actions.size(), size_t{3});
  EXPECT_EQ(bridge->performed_actions[2],
            FlutterSemanticsAction::kFlutterSemanticsActionShowOnScreen);
}

TEST(FlutterPlatformNodeDelegateTest, canGetAXNode) {
  // Set up a flutter accessibility node.
  std::shared_ptr<TestAccessibilityBridge> bridge =
      std::make_shared<TestAccessibilityBridge>();
  FlutterSemanticsNode2 root;
  root.id = 0;
  FlutterSemanticsFlags flags = FlutterSemanticsFlags{0};
  flags.is_text_field = true;
  root.flags2 = &flags;
  // NOLINTNEXTLINE(clang-analyzer-optin.core.EnumCastOutOfRange)
  root.actions = static_cast<FlutterSemanticsAction>(0);
  root.text_selection_base = -1;
  root.text_selection_extent = -1;
  root.label = "root";
  root.hint = "";
  root.value = "";
  root.increased_value = "";
  root.decreased_value = "";
  root.tooltip = "";
  root.child_count = 0;
  root.custom_accessibility_actions_count = 0;
  root.identifier = "";
  bridge->AddFlutterSemanticsNodeUpdate(root);

  bridge->CommitUpdates();

  auto accessibility = bridge->GetFlutterPlatformNodeDelegateFromID(0).lock();
  EXPECT_EQ(accessibility->GetData().id, 0);
}

TEST(FlutterPlatformNodeDelegateTest, canCalculateBoundsCorrectly) {
  std::shared_ptr<TestAccessibilityBridge> bridge =
      std::make_shared<TestAccessibilityBridge>();
  FlutterSemanticsFlags flags = FlutterSemanticsFlags{0};
  FlutterSemanticsNode2 root;
  root.id = 0;
  root.label = "root";
  root.hint = "";
  root.value = "";
  root.increased_value = "";
  root.decreased_value = "";
  root.tooltip = "";
  root.child_count = 1;
  root.flags2 = &flags;
  int32_t children[] = {1};
  root.children_in_traversal_order = children;
  root.custom_accessibility_actions_count = 0;
  root.identifier = "";
  root.rect = {0, 0, 100, 100};  // LTRB
  root.transform = {1, 0, 0, 0, 1, 0, 0, 0, 1};
  bridge->AddFlutterSemanticsNodeUpdate(root);

  FlutterSemanticsNode2 child1;
  child1.id = 1;
  child1.label = "child 1";
  child1.hint = "";
  child1.value = "";
  child1.increased_value = "";
  child1.decreased_value = "";
  child1.tooltip = "";
  child1.child_count = 0;
  child1.flags2 = &flags;
  child1.custom_accessibility_actions_count = 0;
  child1.identifier = "";
  child1.rect = {0, 0, 50, 50};  // LTRB
  child1.transform = {0.5, 0, 0, 0, 0.5, 0, 0, 0, 1};
  bridge->AddFlutterSemanticsNodeUpdate(child1);

  bridge->CommitUpdates();
  auto child1_node = bridge->GetFlutterPlatformNodeDelegateFromID(1).lock();
  ui::AXOffscreenResult result;
  gfx::Rect bounds =
      child1_node->GetBoundsRect(ui::AXCoordinateSystem::kScreenDIPs,
                                 ui::AXClippingBehavior::kClipped, &result);
  EXPECT_EQ(bounds.x(), 0);
  EXPECT_EQ(bounds.y(), 0);
  EXPECT_EQ(bounds.width(), 25);
  EXPECT_EQ(bounds.height(), 25);
  EXPECT_EQ(result, ui::AXOffscreenResult::kOnscreen);
}

TEST(FlutterPlatformNodeDelegateTest, canCalculateOffScreenBoundsCorrectly) {
  std::shared_ptr<TestAccessibilityBridge> bridge =
      std::make_shared<TestAccessibilityBridge>();
  FlutterSemanticsFlags flags = FlutterSemanticsFlags{0};
  FlutterSemanticsNode2 root;
  root.id = 0;
  root.label = "root";
  root.hint = "";
  root.value = "";
  root.increased_value = "";
  root.decreased_value = "";
  root.tooltip = "";
  root.child_count = 1;
  root.flags2 = &flags;
  int32_t children[] = {1};
  root.children_in_traversal_order = children;
  root.custom_accessibility_actions_count = 0;
  root.identifier = "";
  root.rect = {0, 0, 100, 100};  // LTRB
  root.transform = {1, 0, 0, 0, 1, 0, 0, 0, 1};
  bridge->AddFlutterSemanticsNodeUpdate(root);

  FlutterSemanticsNode2 child1;
  child1.id = 1;
  child1.label = "child 1";
  child1.hint = "";
  child1.value = "";
  child1.increased_value = "";
  child1.decreased_value = "";
  child1.tooltip = "";
  child1.child_count = 0;
  child1.flags2 = &flags;
  child1.custom_accessibility_actions_count = 0;
  child1.identifier = "";
  child1.rect = {90, 90, 100, 100};  // LTRB
  child1.transform = {2, 0, 0, 0, 2, 0, 0, 0, 1};
  bridge->AddFlutterSemanticsNodeUpdate(child1);

  bridge->CommitUpdates();
  auto child1_node = bridge->GetFlutterPlatformNodeDelegateFromID(1).lock();
  ui::AXOffscreenResult result;
  gfx::Rect bounds =
      child1_node->GetBoundsRect(ui::AXCoordinateSystem::kScreenDIPs,
                                 ui::AXClippingBehavior::kUnclipped, &result);
  EXPECT_EQ(bounds.x(), 180);
  EXPECT_EQ(bounds.y(), 180);
  EXPECT_EQ(bounds.width(), 20);
  EXPECT_EQ(bounds.height(), 20);
  EXPECT_EQ(result, ui::AXOffscreenResult::kOffscreen);
}

TEST(FlutterPlatformNodeDelegateTest, canUseOwnerBridge) {
  std::shared_ptr<TestAccessibilityBridge> bridge =
      std::make_shared<TestAccessibilityBridge>();
  FlutterSemanticsFlags flags = FlutterSemanticsFlags{0};
  FlutterSemanticsNode2 root{sizeof(FlutterSemanticsNode2), 0};
  root.label = "root";
  root.hint = "";
  root.value = "";
  root.increased_value = "";
  root.decreased_value = "";
  root.tooltip = "";
  root.heading_level = 0;
  root.child_count = 1;
  root.flags2 = &flags;
  int32_t children[] = {1};
  root.children_in_traversal_order = children;
  root.custom_accessibility_actions_count = 0;
  root.identifier = "";
  root.rect = {0, 0, 100, 100};  // LTRB
  root.transform = {1, 0, 0, 0, 1, 0, 0, 0, 1};
  bridge->AddFlutterSemanticsNodeUpdate(root);

  FlutterSemanticsNode2 child1{sizeof(FlutterSemanticsNode2), 1};
  child1.label = "child 1";
  child1.hint = "";
  child1.value = "";
  child1.increased_value = "";
  child1.decreased_value = "";
  child1.tooltip = "";
  child1.heading_level = 0;
  child1.child_count = 0;
  child1.flags2 = &flags;
  child1.custom_accessibility_actions_count = 0;
  child1.identifier = "";
  child1.rect = {0, 0, 50, 50};  // LTRB
  child1.transform = {0.5, 0, 0, 0, 0.5, 0, 0, 0, 1};
  bridge->AddFlutterSemanticsNodeUpdate(child1);

  bridge->CommitUpdates();
  auto child1_node = bridge->GetFlutterPlatformNodeDelegateFromID(1).lock();
  auto owner_bridge = child1_node->GetOwnerBridge().lock();

  bool result = false;
  gfx::RectF bounds = owner_bridge->RelativeToGlobalBounds(
      child1_node->GetAXNode(), result, true);
  EXPECT_EQ(bounds.x(), 0);
  EXPECT_EQ(bounds.y(), 0);
  EXPECT_EQ(bounds.width(), 25);
  EXPECT_EQ(bounds.height(), 25);
  EXPECT_EQ(result, false);
}

TEST(FlutterPlatformNodeDelegateTest, selfIsLowestPlatformAncestor) {
  std::shared_ptr<TestAccessibilityBridge> bridge =
      std::make_shared<TestAccessibilityBridge>();
  FlutterSemanticsFlags flags = FlutterSemanticsFlags{0};
  FlutterSemanticsNode2 root;
  root.id = 0;
  root.label = "root";
  root.hint = "";
  root.value = "";
  root.increased_value = "";
  root.decreased_value = "";
  root.tooltip = "";
  root.child_count = 0;
  root.flags2 = &flags;
  root.children_in_traversal_order = nullptr;
  root.custom_accessibility_actions_count = 0;
  root.identifier = "";
  bridge->AddFlutterSemanticsNodeUpdate(root);

  bridge->CommitUpdates();
  auto root_node = bridge->GetFlutterPlatformNodeDelegateFromID(0).lock();
  auto lowest_platform_ancestor = root_node->GetLowestPlatformAncestor();
  EXPECT_EQ(root_node->GetNativeViewAccessible(), lowest_platform_ancestor);
}

TEST(FlutterPlatformNodeDelegateTest, canGetFromNodeID) {
  std::shared_ptr<TestAccessibilityBridge> bridge =
      std::make_shared<TestAccessibilityBridge>();
  FlutterSemanticsFlags flags = FlutterSemanticsFlags{0};
  FlutterSemanticsNode2 root;
  root.id = 0;
  root.label = "root";
  root.hint = "";
  root.value = "";
  root.increased_value = "";
  root.decreased_value = "";
  root.tooltip = "";
  root.child_count = 1;
  root.flags2 = &flags;
  int32_t children[] = {1};
  root.children_in_traversal_order = children;
  root.custom_accessibility_actions_count = 0;
  root.identifier = "";
  bridge->AddFlutterSemanticsNodeUpdate(root);

  FlutterSemanticsNode2 child1;
  child1.id = 1;
  child1.label = "child 1";
  child1.hint = "";
  child1.value = "";
  child1.increased_value = "";
  child1.decreased_value = "";
  child1.tooltip = "";
  child1.child_count = 0;
  child1.flags2 = &flags;
  child1.custom_accessibility_actions_count = 0;
  child1.identifier = "";
  bridge->AddFlutterSemanticsNodeUpdate(child1);

  bridge->CommitUpdates();
  auto root_node = bridge->GetFlutterPlatformNodeDelegateFromID(0).lock();
  auto child1_node = bridge->GetFlutterPlatformNodeDelegateFromID(1).lock();
  auto node_by_id = root_node->GetFromNodeID(1);
  EXPECT_EQ(child1_node->GetPlatformNode(), node_by_id);
}

TEST(FlutterPlatformNodeDelegateTest,
     parentRectOriginDoesNotOffsetChildBounds) {
  std::shared_ptr<TestAccessibilityBridge> bridge =
      std::make_shared<TestAccessibilityBridge>();
  FlutterSemanticsFlags flags = FlutterSemanticsFlags{0};

  FlutterSemanticsNode2 root;
  root.id = 0;
  root.label = "root";
  root.hint = "";
  root.value = "";
  root.increased_value = "";
  root.decreased_value = "";
  root.tooltip = "";
  root.child_count = 1;
  root.flags2 = &flags;
  int32_t root_children[] = {1};
  root.children_in_traversal_order = root_children;
  root.custom_accessibility_actions_count = 0;
  root.identifier = "";
  root.rect = {0, 0, 800, 600};
  root.transform = {1, 0, 0, 0, 1, 0, 0, 0, 1};
  bridge->AddFlutterSemanticsNodeUpdate(root);

  // Group has rect starting at (0, 50) and is translated by (0, 100).
  FlutterSemanticsNode2 group;
  group.id = 1;
  group.label = "group";
  group.hint = "";
  group.value = "";
  group.increased_value = "";
  group.decreased_value = "";
  group.tooltip = "";
  group.child_count = 1;
  group.flags2 = &flags;
  int32_t group_children[] = {2};
  group.children_in_traversal_order = group_children;
  group.custom_accessibility_actions_count = 0;
  group.identifier = "";
  group.rect = {0, 50, 200, 250};  // LTRB
  group.transform = {1, 0, 0, 0, 1, 100, 0, 0, 1};
  bridge->AddFlutterSemanticsNodeUpdate(group);

  // Child is at (0, 100) in group's coordinate space.
  FlutterSemanticsNode2 child;
  child.id = 2;
  child.label = "child";
  child.hint = "";
  child.value = "";
  child.increased_value = "";
  child.decreased_value = "";
  child.tooltip = "";
  child.child_count = 0;
  child.flags2 = &flags;
  child.custom_accessibility_actions_count = 0;
  child.identifier = "";
  child.rect = {0, 0, 200, 100};  // LTRB
  child.transform = {1, 0, 0, 0, 1, 100, 0, 0, 1};
  bridge->AddFlutterSemanticsNodeUpdate(child);

  bridge->CommitUpdates();

  auto group_node = bridge->GetFlutterPlatformNodeDelegateFromID(1).lock();
  ui::AXOffscreenResult group_offscreen;
  gfx::Rect group_bounds = group_node->GetBoundsRect(
      ui::AXCoordinateSystem::kScreenDIPs, ui::AXClippingBehavior::kClipped,
      &group_offscreen);
  EXPECT_EQ(group_bounds.x(), 0);
  EXPECT_EQ(group_bounds.y(), 150);
  EXPECT_EQ(group_bounds.width(), 200);
  EXPECT_EQ(group_bounds.height(), 200);
  EXPECT_EQ(group_offscreen, ui::AXOffscreenResult::kOnscreen);

  auto child_node = bridge->GetFlutterPlatformNodeDelegateFromID(2).lock();
  ui::AXOffscreenResult child_offscreen;
  gfx::Rect child_bounds = child_node->GetBoundsRect(
      ui::AXCoordinateSystem::kScreenDIPs, ui::AXClippingBehavior::kClipped,
      &child_offscreen);
  EXPECT_EQ(child_bounds.x(), 0);
  EXPECT_EQ(child_bounds.y(), 200);
  EXPECT_EQ(child_bounds.width(), 200);
  EXPECT_EQ(child_bounds.height(), 100);
  EXPECT_EQ(child_offscreen, ui::AXOffscreenResult::kOnscreen);
}

TEST(FlutterPlatformNodeDelegateTest,
     parentRectOriginClippingAndOffscreenBounds) {
  std::shared_ptr<TestAccessibilityBridge> bridge =
      std::make_shared<TestAccessibilityBridge>();
  FlutterSemanticsFlags flags = FlutterSemanticsFlags{0};

  FlutterSemanticsNode2 root;
  root.id = 0;
  root.label = "root";
  root.hint = "";
  root.value = "";
  root.increased_value = "";
  root.decreased_value = "";
  root.tooltip = "";
  root.child_count = 1;
  root.flags2 = &flags;
  int32_t root_children[] = {1};
  root.children_in_traversal_order = root_children;
  root.custom_accessibility_actions_count = 0;
  root.identifier = "";
  root.rect = {0, 0, 800, 600};
  root.transform = {1, 0, 0, 0, 1, 0, 0, 0, 1};
  bridge->AddFlutterSemanticsNodeUpdate(root);

  // Parent rect is (10, 100) to (110, 200), translated by (20, 30).
  FlutterSemanticsNode2 parent;
  parent.id = 1;
  parent.label = "parent";
  parent.hint = "";
  parent.value = "";
  parent.increased_value = "";
  parent.decreased_value = "";
  parent.tooltip = "";
  parent.child_count = 2;
  parent.flags2 = &flags;
  int32_t parent_children[] = {2, 3};
  parent.children_in_traversal_order = parent_children;
  parent.custom_accessibility_actions_count = 0;
  parent.identifier = "";
  parent.rect = {10, 100, 110, 200};  // LTRB
  parent.transform = {1, 0, 20, 0, 1, 30, 0, 0, 1};
  bridge->AddFlutterSemanticsNodeUpdate(parent);

  // Child 2 is inside parent: (10, 100) to (60, 150) in parent space.
  FlutterSemanticsNode2 child_onscreen;
  child_onscreen.id = 2;
  child_onscreen.label = "onscreen";
  child_onscreen.hint = "";
  child_onscreen.value = "";
  child_onscreen.increased_value = "";
  child_onscreen.decreased_value = "";
  child_onscreen.tooltip = "";
  child_onscreen.child_count = 0;
  child_onscreen.flags2 = &flags;
  child_onscreen.custom_accessibility_actions_count = 0;
  child_onscreen.identifier = "";
  child_onscreen.rect = {0, 0, 50, 50};  // LTRB
  child_onscreen.transform = {1, 0, 10, 0, 1, 100, 0, 0, 1};
  bridge->AddFlutterSemanticsNodeUpdate(child_onscreen);

  // Child 3 is outside parent to the right: (150, 100) to (200, 150).
  FlutterSemanticsNode2 child_offscreen;
  child_offscreen.id = 3;
  child_offscreen.label = "offscreen";
  child_offscreen.hint = "";
  child_offscreen.value = "";
  child_offscreen.increased_value = "";
  child_offscreen.decreased_value = "";
  child_offscreen.tooltip = "";
  child_offscreen.child_count = 0;
  child_offscreen.flags2 = &flags;
  child_offscreen.custom_accessibility_actions_count = 0;
  child_offscreen.identifier = "";
  child_offscreen.rect = {0, 0, 50, 50};  // LTRB
  child_offscreen.transform = {1, 0, 150, 0, 1, 100, 0, 0, 1};
  bridge->AddFlutterSemanticsNodeUpdate(child_offscreen);

  bridge->CommitUpdates();

  auto onscreen_node = bridge->GetFlutterPlatformNodeDelegateFromID(2).lock();
  ui::AXOffscreenResult onscreen_result;
  gfx::Rect onscreen_bounds = onscreen_node->GetBoundsRect(
      ui::AXCoordinateSystem::kScreenDIPs, ui::AXClippingBehavior::kClipped,
      &onscreen_result);
  EXPECT_EQ(onscreen_bounds.x(), 30);
  EXPECT_EQ(onscreen_bounds.y(), 130);
  EXPECT_EQ(onscreen_bounds.width(), 50);
  EXPECT_EQ(onscreen_bounds.height(), 50);
  EXPECT_EQ(onscreen_result, ui::AXOffscreenResult::kOnscreen);

  auto offscreen_node = bridge->GetFlutterPlatformNodeDelegateFromID(3).lock();
  ui::AXOffscreenResult offscreen_result;
  gfx::Rect clipped_bounds = offscreen_node->GetBoundsRect(
      ui::AXCoordinateSystem::kScreenDIPs, ui::AXClippingBehavior::kClipped,
      &offscreen_result);
  EXPECT_EQ(clipped_bounds.x(), 129);
  EXPECT_EQ(clipped_bounds.y(), 130);
  EXPECT_EQ(clipped_bounds.width(), 1);
  EXPECT_EQ(clipped_bounds.height(), 50);
  EXPECT_EQ(offscreen_result, ui::AXOffscreenResult::kOffscreen);

  gfx::Rect unclipped_bounds = offscreen_node->GetBoundsRect(
      ui::AXCoordinateSystem::kScreenDIPs, ui::AXClippingBehavior::kUnclipped,
      &offscreen_result);
  EXPECT_EQ(unclipped_bounds.x(), 170);
  EXPECT_EQ(unclipped_bounds.y(), 130);
  EXPECT_EQ(unclipped_bounds.width(), 50);
  EXPECT_EQ(unclipped_bounds.height(), 50);
  EXPECT_EQ(offscreen_result, ui::AXOffscreenResult::kOffscreen);
}

TEST(FlutterPlatformNodeDelegateTest,
     nestedNonZeroOriginsPartialOverlapAndLeftTopOffscreen) {
  std::shared_ptr<TestAccessibilityBridge> bridge =
      std::make_shared<TestAccessibilityBridge>();
  FlutterSemanticsFlags flags = FlutterSemanticsFlags{0};

  // Root: (0, 0) to (800, 600).
  FlutterSemanticsNode2 root;
  root.id = 0;
  root.label = "root";
  root.hint = "";
  root.value = "";
  root.increased_value = "";
  root.decreased_value = "";
  root.tooltip = "";
  root.child_count = 1;
  root.flags2 = &flags;
  int32_t root_children[] = {1};
  root.children_in_traversal_order = root_children;
  root.custom_accessibility_actions_count = 0;
  root.identifier = "";
  root.rect = {0, 0, 800, 600};
  root.transform = {1, 0, 0, 0, 1, 0, 0, 0, 1};
  bridge->AddFlutterSemanticsNodeUpdate(root);

  // Grandparent: rect (10, 20) to (210, 220), translated by (5, 10).
  // In root: (15, 30) to (215, 230).
  FlutterSemanticsNode2 grandparent;
  grandparent.id = 1;
  grandparent.label = "grandparent";
  grandparent.hint = "";
  grandparent.value = "";
  grandparent.increased_value = "";
  grandparent.decreased_value = "";
  grandparent.tooltip = "";
  grandparent.child_count = 1;
  grandparent.flags2 = &flags;
  int32_t gp_children[] = {2};
  grandparent.children_in_traversal_order = gp_children;
  grandparent.custom_accessibility_actions_count = 0;
  grandparent.identifier = "";
  grandparent.rect = {10, 20, 210, 220};
  grandparent.transform = {1, 0, 5, 0, 1, 10, 0, 0, 1};
  bridge->AddFlutterSemanticsNodeUpdate(grandparent);

  // Parent: rect (30, 40) to (130, 140), translated by (0, 0).
  // In grandparent: (30, 40) to (130, 140).
  // In root: (35, 50) to (135, 150).
  FlutterSemanticsNode2 parent;
  parent.id = 2;
  parent.label = "parent";
  parent.hint = "";
  parent.value = "";
  parent.increased_value = "";
  parent.decreased_value = "";
  parent.tooltip = "";
  parent.child_count = 2;
  parent.flags2 = &flags;
  int32_t parent_children[] = {3, 4};
  parent.children_in_traversal_order = parent_children;
  parent.custom_accessibility_actions_count = 0;
  parent.identifier = "";
  parent.rect = {30, 40, 130, 140};
  parent.transform = {1, 0, 0, 0, 1, 0, 0, 0, 1};
  bridge->AddFlutterSemanticsNodeUpdate(parent);

  // Child 3: partially overlaps parent on the left/top: (10, 20) to (60, 70)
  // in parent space. Clipped to parent: (30, 40) to (60, 70) -> in root:
  // (35, 50, 30, 30), onscreen.
  FlutterSemanticsNode2 child_partial;
  child_partial.id = 3;
  child_partial.label = "partial";
  child_partial.hint = "";
  child_partial.value = "";
  child_partial.increased_value = "";
  child_partial.decreased_value = "";
  child_partial.tooltip = "";
  child_partial.child_count = 0;
  child_partial.flags2 = &flags;
  child_partial.custom_accessibility_actions_count = 0;
  child_partial.identifier = "";
  child_partial.rect = {0, 0, 50, 50};
  child_partial.transform = {1, 0, 10, 0, 1, 20, 0, 0, 1};
  bridge->AddFlutterSemanticsNodeUpdate(child_partial);

  // Child 4: completely offscreen to top-left (negative coordinates):
  // (-50, -30) to (-10, 10) in parent space. Clipped to (30, 40, 1, 1) ->
  // in root: (35, 50, 1, 1), offscreen.
  FlutterSemanticsNode2 child_left_top;
  child_left_top.id = 4;
  child_left_top.label = "left_top";
  child_left_top.hint = "";
  child_left_top.value = "";
  child_left_top.increased_value = "";
  child_left_top.decreased_value = "";
  child_left_top.tooltip = "";
  child_left_top.child_count = 0;
  child_left_top.flags2 = &flags;
  child_left_top.custom_accessibility_actions_count = 0;
  child_left_top.identifier = "";
  child_left_top.rect = {0, 0, 40, 40};
  child_left_top.transform = {1, 0, -50, 0, 1, -30, 0, 0, 1};
  bridge->AddFlutterSemanticsNodeUpdate(child_left_top);

  bridge->CommitUpdates();

  auto partial_node = bridge->GetFlutterPlatformNodeDelegateFromID(3).lock();
  ui::AXOffscreenResult partial_result;
  gfx::Rect partial_bounds = partial_node->GetBoundsRect(
      ui::AXCoordinateSystem::kScreenDIPs, ui::AXClippingBehavior::kClipped,
      &partial_result);
  EXPECT_EQ(partial_bounds.x(), 35);
  EXPECT_EQ(partial_bounds.y(), 50);
  EXPECT_EQ(partial_bounds.width(), 30);
  EXPECT_EQ(partial_bounds.height(), 30);
  EXPECT_EQ(partial_result, ui::AXOffscreenResult::kOnscreen);

  auto left_top_node = bridge->GetFlutterPlatformNodeDelegateFromID(4).lock();
  ui::AXOffscreenResult left_top_result;
  gfx::Rect left_top_bounds = left_top_node->GetBoundsRect(
      ui::AXCoordinateSystem::kScreenDIPs, ui::AXClippingBehavior::kClipped,
      &left_top_result);
  EXPECT_EQ(left_top_bounds.x(), 35);
  EXPECT_EQ(left_top_bounds.y(), 50);
  EXPECT_EQ(left_top_bounds.width(), 1);
  EXPECT_EQ(left_top_bounds.height(), 1);
  EXPECT_EQ(left_top_result, ui::AXOffscreenResult::kOffscreen);
}

TEST(FlutterPlatformNodeDelegateTest,
     emptyBoundsFallbackWithChildrenAndSibling) {
  std::shared_ptr<TestAccessibilityBridge> bridge =
      std::make_shared<TestAccessibilityBridge>();
  FlutterSemanticsFlags flags = FlutterSemanticsFlags{0};

  // Root: (0, 0) to (800, 600).
  FlutterSemanticsNode2 root;
  root.id = 0;
  root.label = "root";
  root.hint = "";
  root.value = "";
  root.increased_value = "";
  root.decreased_value = "";
  root.tooltip = "";
  root.child_count = 1;
  root.flags2 = &flags;
  int32_t root_children[] = {1};
  root.children_in_traversal_order = root_children;
  root.custom_accessibility_actions_count = 0;
  root.identifier = "";
  root.rect = {0, 0, 800, 600};
  root.transform = {1, 0, 0, 0, 1, 0, 0, 0, 1};
  bridge->AddFlutterSemanticsNodeUpdate(root);

  // Empty parent (0x0) with one empty child (id 2) and one sized child (id 3).
  // Computing parent's bounds from children must not let child 2 fall back
  // to root's 800x600 bounds.
  FlutterSemanticsNode2 empty_parent;
  empty_parent.id = 1;
  empty_parent.label = "empty_parent";
  empty_parent.hint = "";
  empty_parent.value = "";
  empty_parent.increased_value = "";
  empty_parent.decreased_value = "";
  empty_parent.tooltip = "";
  empty_parent.child_count = 2;
  empty_parent.flags2 = &flags;
  int32_t parent_children[] = {2, 3};
  empty_parent.children_in_traversal_order = parent_children;
  empty_parent.custom_accessibility_actions_count = 0;
  empty_parent.identifier = "";
  empty_parent.rect = {0, 0, 0, 0};
  empty_parent.transform = {1, 0, 0, 0, 1, 0, 0, 0, 1};
  bridge->AddFlutterSemanticsNodeUpdate(empty_parent);

  FlutterSemanticsNode2 empty_child;
  empty_child.id = 2;
  empty_child.label = "empty_child";
  empty_child.hint = "";
  empty_child.value = "";
  empty_child.increased_value = "";
  empty_child.decreased_value = "";
  empty_child.tooltip = "";
  empty_child.child_count = 0;
  empty_child.flags2 = &flags;
  empty_child.custom_accessibility_actions_count = 0;
  empty_child.identifier = "";
  empty_child.rect = {0, 0, 0, 0};
  empty_child.transform = {1, 0, 0, 0, 1, 0, 0, 0, 1};
  bridge->AddFlutterSemanticsNodeUpdate(empty_child);

  FlutterSemanticsNode2 sized_child;
  sized_child.id = 3;
  sized_child.label = "sized_child";
  sized_child.hint = "";
  sized_child.value = "";
  sized_child.increased_value = "";
  sized_child.decreased_value = "";
  sized_child.tooltip = "";
  sized_child.child_count = 0;
  sized_child.flags2 = &flags;
  sized_child.custom_accessibility_actions_count = 0;
  sized_child.identifier = "";
  sized_child.rect = {0, 0, 50, 40};
  sized_child.transform = {1, 0, 20, 0, 1, 30, 0, 0, 1};
  bridge->AddFlutterSemanticsNodeUpdate(sized_child);

  bridge->CommitUpdates();

  auto parent_node = bridge->GetFlutterPlatformNodeDelegateFromID(1).lock();
  ui::AXOffscreenResult parent_result;
  gfx::Rect parent_bounds = parent_node->GetBoundsRect(
      ui::AXCoordinateSystem::kScreenDIPs, ui::AXClippingBehavior::kUnclipped,
      &parent_result);
  EXPECT_EQ(parent_bounds.x(), 20);
  EXPECT_EQ(parent_bounds.y(), 30);
  EXPECT_EQ(parent_bounds.width(), 50);
  EXPECT_EQ(parent_bounds.height(), 40);

  // Empty leaf node directly queried falls back to nearest non-empty ancestor.
  auto empty_leaf_node = bridge->GetFlutterPlatformNodeDelegateFromID(2).lock();
  ui::AXOffscreenResult leaf_result;
  gfx::Rect leaf_bounds = empty_leaf_node->GetBoundsRect(
      ui::AXCoordinateSystem::kScreenDIPs, ui::AXClippingBehavior::kClipped,
      &leaf_result);
  EXPECT_EQ(leaf_bounds.x(), 0);
  EXPECT_EQ(leaf_bounds.y(), 0);
  EXPECT_EQ(leaf_bounds.width(), 800);
  EXPECT_EQ(leaf_bounds.height(), 600);
  EXPECT_EQ(leaf_result, ui::AXOffscreenResult::kOffscreen);
}

}  // namespace testing
}  // namespace flutter

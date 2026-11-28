// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ax_platform_node_mac_unittest.h"

#include "ax_platform_node_mac.h"
#include "gtest/gtest.h"
#include "test_ax_node_wrapper.h"
#include "third_party/accessibility/ax/ax_node_data.h"

namespace ui {

AXPlatformNodeMacTest::AXPlatformNodeMacTest() = default;

AXPlatformNodeMacTest::~AXPlatformNodeMacTest() = default;

void AXPlatformNodeMacTest::SetUp() {}

void AXPlatformNodeMacTest::TearDown() {
  // Destroy the tree and make sure we're not leaking any objects.
  DestroyTree();
  TestAXNodeWrapper::SetGlobalIsWebContent(false);
  ASSERT_EQ(0U, AXPlatformNodeBase::GetInstanceCountForTesting());
}

AXPlatformNode* AXPlatformNodeMacTest::AXPlatformNodeFromNode(AXNode* node) {
  const TestAXNodeWrapper* wrapper = TestAXNodeWrapper::GetOrCreate(GetTree(), node);
  return wrapper ? wrapper->ax_platform_node() : nullptr;
}

// Verify that we can get an AXPlatformNodeMac and AXPlatformNodeCocoa from the tree.
TEST_F(AXPlatformNodeMacTest, CanGetCocoaPlatformNodeFromTree) {
  AXNodeData root;
  root.id = 1;
  root.relative_bounds.bounds = gfx::RectF(0, 0, 40, 40);

  Init(root);
  AXNode* root_node = GetRootAsAXNode();
  ASSERT_TRUE(root_node != nullptr);

  AXPlatformNode* platform_node = AXPlatformNodeFromNode(root_node);
  ASSERT_TRUE(platform_node != nullptr);

  AXPlatformNodeCocoa* native_root = platform_node->GetNativeViewAccessible();
  EXPECT_TRUE(native_root != nullptr);
}

// Test that [AXPlatformNodeCocoa accessbilityRangeForPosition:] doesn't crash.
// https://github.com/flutter/flutter/issues/102416
TEST_F(AXPlatformNodeMacTest, AccessibilityRangeForPositionDoesntCrash) {
  AXNodeData root;
  root.id = 1;
  root.relative_bounds.bounds = gfx::RectF(0, 0, 40, 40);

  Init(root);
  AXNode* root_node = GetRootAsAXNode();
  ASSERT_TRUE(root_node != nullptr);

  AXPlatformNode* platform_node = AXPlatformNodeFromNode(root_node);
  ASSERT_TRUE(platform_node != nullptr);

  NSPoint point = NSMakePoint(0, 0);
  AXPlatformNodeCocoa* native_root = platform_node->GetNativeViewAccessible();
  ASSERT_TRUE(native_root != nullptr);

  [native_root accessibilityRangeForPosition:(NSPoint)point];
}

TEST_F(AXPlatformNodeMacTest, AccessibilityIdentifierReturnsIdentifier) {
  AXNodeData root;
  root.id = 1;
  root.AddStringAttribute(ax::mojom::StringAttribute::kIdentifier, "probe.button");

  Init(root);
  AXPlatformNode* platform_node = AXPlatformNodeFromNode(GetRootAsAXNode());
  ASSERT_TRUE(platform_node != nullptr);
  AXPlatformNodeCocoa* native_root = platform_node->GetNativeViewAccessible();
  ASSERT_TRUE(native_root != nullptr);

  EXPECT_TRUE([[native_root accessibilityIdentifier] isEqualToString:@"probe.button"]);
}

// The accessibility bridge always sets kIdentifier, so an empty value must be
// treated like a missing one.
TEST_F(AXPlatformNodeMacTest, AccessibilityIdentifierIsNilWhenMissingOrEmpty) {
  AXNodeData root;
  root.id = 1;
  root.child_ids = {2};

  AXNodeData child;
  child.id = 2;
  child.AddStringAttribute(ax::mojom::StringAttribute::kIdentifier, "");

  Init(root, child);
  AXNode* root_node = GetRootAsAXNode();
  AXPlatformNode* root_platform_node = AXPlatformNodeFromNode(root_node);
  AXPlatformNode* child_platform_node = AXPlatformNodeFromNode(root_node->children()[0]);
  ASSERT_TRUE(root_platform_node != nullptr);
  ASSERT_TRUE(child_platform_node != nullptr);

  EXPECT_EQ([root_platform_node->GetNativeViewAccessible() accessibilityIdentifier], nil);
  EXPECT_EQ([child_platform_node->GetNativeViewAccessible() accessibilityIdentifier], nil);
}

}  // namespace ui

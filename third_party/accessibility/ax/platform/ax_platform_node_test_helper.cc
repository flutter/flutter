// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/platform/ax_platform_node_test_helper.h"

#include "ui/accessibility/ax_node_data.h"

namespace ui {

// static
int AXPlatformNodeTestHelper::GetTreeSize(AXPlatformNode* ax_node) {
  if (!ax_node)
    return 0;
  int count = 1;
  AXPlatformNodeDelegate* delegate = ax_node->GetDelegate();
  for (int i = 0; i < delegate->GetChildCount(); ++i) {
    AXPlatformNode* child_node =
        AXPlatformNode::FromNativeViewAccessible(delegate->ChildAtIndex(i));
    count += GetTreeSize(child_node);
  }
  return count;
}

// static
AXPlatformNode* AXPlatformNodeTestHelper::FindChildByName(
    AXPlatformNode* ax_node,
    const std::string& name) {
  if (!ax_node)
    return nullptr;

  AXPlatformNodeDelegate* delegate = ax_node->GetDelegate();
  if (delegate->GetName() == name)
    return ax_node;

  for (int i = 0; i < delegate->GetChildCount(); ++i) {
    AXPlatformNode* result_from_child = FindChildByName(
        AXPlatformNode::FromNativeViewAccessible(delegate->ChildAtIndex(i)),
        name);
    if (result_from_child)
      return result_from_child;
  }
  return nullptr;
}

}  // namespace ui

// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_PLATFORM_AX_PLATFORM_NODE_TEST_HELPER_H_
#define UI_ACCESSIBILITY_PLATFORM_AX_PLATFORM_NODE_TEST_HELPER_H_

#include <string>

#include "ui/accessibility/platform/ax_platform_node.h"
#include "ui/accessibility/platform/ax_platform_node_delegate.h"

namespace ui {

class AX_EXPORT AXPlatformNodeTestHelper {
 public:
  static int GetTreeSize(AXPlatformNode* ax_node);
  static AXPlatformNode* FindChildByName(AXPlatformNode* ax_node,
                                         const std::string& name);
};

}  // namespace ui

#endif  // UI_ACCESSIBILITY_PLATFORM_AX_PLATFORM_NODE_TEST_HELPER_H_

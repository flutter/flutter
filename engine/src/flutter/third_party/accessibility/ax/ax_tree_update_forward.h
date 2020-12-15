// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_AX_TREE_UPDATE_FORWARD_H_
#define UI_ACCESSIBILITY_AX_TREE_UPDATE_FORWARD_H_

namespace ui {

struct AXNodeData;
struct AXTreeData;
template <typename A, typename B>
struct AXTreeUpdateBase;
using AXTreeUpdate = AXTreeUpdateBase<AXNodeData, AXTreeData>;

}  // namespace ui

#endif  // UI_ACCESSIBILITY_AX_TREE_UPDATE_FORWARD_H_

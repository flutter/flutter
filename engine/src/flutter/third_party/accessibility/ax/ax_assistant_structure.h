// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_AX_ASSISTANT_STRUCTURE_H_
#define UI_ACCESSIBILITY_AX_ASSISTANT_STRUCTURE_H_

#include <cstdint>
#include <vector>

#include "base/macros.h"
#include "base/optional.h"
#include "base/strings/string16.h"
#include "ui/accessibility/ax_enums.mojom-forward.h"
#include "ui/accessibility/ax_export.h"
#include "ui/accessibility/ax_tree_update.h"
#include "ui/gfx/geometry/rect.h"
#include "ui/gfx/range/range.h"

namespace ui {

struct AssistantNode {
  AssistantNode();
  AssistantNode(const AssistantNode& other);
  AssistantNode& operator=(const AssistantNode&) = delete;
  ~AssistantNode();

  std::vector<int32_t> children_indices;

  // Geometry of the view in pixels
  gfx::Rect rect;

  // Text of the view.
  base::string16 text;

  // Text properties
  float text_size;
  uint32_t color;
  uint32_t bgcolor;
  bool bold;
  bool italic;
  bool underline;
  bool line_through;

  // Selected portion of the text.
  base::Optional<gfx::Range> selection;

  // Fake Android view class name of the element.  Each node is assigned
  // a closest approximation of Android's views to keep the server happy.
  std::string class_name;

  // Accessibility functionality of the node inferred from DOM or based on HTML
  // role attribute.
  base::Optional<std::string> role;
};

struct AssistantTree {
  AssistantTree();
  AssistantTree(const AssistantTree& other);
  AssistantTree& operator=(const AssistantTree&) = delete;
  ~AssistantTree();

  std::vector<std::unique_ptr<AssistantNode>> nodes;
};

std::unique_ptr<AssistantTree> CreateAssistantTree(const AXTreeUpdate& update,
                                                   bool show_password);

base::string16 AXUrlBaseText(base::string16 url);
const char* AXRoleToAndroidClassName(ax::mojom::Role role, bool has_parent);

}  // namespace ui

#endif  // UI_ACCESSIBILITY_AX_ASSISTANT_STRUCTURE_H_

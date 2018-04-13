// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <map>

#include "flutter/lib/ui/semantics/semantics_node.h"
#include "lib/context/fidl/context_writer.fidl.h"
#include "lib/fxl/macros.h"

namespace flutter {

// Maintain an up-to-date list of SemanticsNodes on screen, and communicate
// with the Context Service.
class AccessibilityBridge final {
 public:
  AccessibilityBridge(maxwell::ContextWriterPtr writer);

  ~AccessibilityBridge();

  // Update the internal representation of the semantics nodes, and write the
  // semantics to Context Service.
  void UpdateSemantics(const blink::SemanticsNodeUpdates& update);

 private:
  maxwell::ContextWriterPtr writer_;
  std::map<int, blink::SemanticsNode> semantics_nodes_;

  // Walk the semantics node tree starting at |id|, and store the id of each
  // visited child in |visited_nodes|.
  void UpdateVisitedForNodeAndChildren(const int id,
                                       std::vector<int>* visited_nodes);

  // Remove any node from |semantics_nodes_| that doesn't have an id in
  // |visited_nodes|.
  void EraseUnvisitedNodes(const std::vector<int>& visited_nodes);

  FXL_DISALLOW_COPY_AND_ASSIGN(AccessibilityBridge);
};

}  // namespace flutter

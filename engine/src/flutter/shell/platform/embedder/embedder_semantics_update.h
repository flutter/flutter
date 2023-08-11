// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_SEMANTICS_UPDATE_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_SEMANTICS_UPDATE_H_

#include "flutter/shell/platform/embedder/embedder.h"
#include "lib/ui/semantics/custom_accessibility_action.h"
#include "lib/ui/semantics/semantics_node.h"

namespace flutter {

// A semantic update, used by the embedder API's v1 and v2 semantic update
// callbacks.
class EmbedderSemanticsUpdate {
 public:
  EmbedderSemanticsUpdate(const SemanticsNodeUpdates& nodes,
                          const CustomAccessibilityActionUpdates& actions);

  ~EmbedderSemanticsUpdate();

  // Get the semantic update. The pointer is only valid while
  // |EmbedderSemanticsUpdate| exists.
  FlutterSemanticsUpdate* get() { return &update_; }

 private:
  FlutterSemanticsUpdate update_;
  std::vector<FlutterSemanticsNode> nodes_;
  std::vector<FlutterSemanticsCustomAction> actions_;

  // Translates engine semantic nodes to embedder semantic nodes.
  void AddNode(const SemanticsNode& node);

  // Translates engine semantic custom actions to embedder semantic custom
  // actions.
  void AddAction(const CustomAccessibilityAction& action);

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderSemanticsUpdate);
};

// A semantic update, used by the embedder API's v3 semantic update callback.
class EmbedderSemanticsUpdate2 {
 public:
  EmbedderSemanticsUpdate2(const SemanticsNodeUpdates& nodes,
                           const CustomAccessibilityActionUpdates& actions);

  ~EmbedderSemanticsUpdate2();

  // Get the semantic update. The pointer is only valid while
  // |EmbedderSemanticsUpdate2| exists.
  FlutterSemanticsUpdate2* get() { return &update_; }

 private:
  FlutterSemanticsUpdate2 update_;
  std::vector<FlutterSemanticsNode2> nodes_;
  std::vector<FlutterSemanticsNode2*> node_pointers_;
  std::vector<FlutterSemanticsCustomAction2> actions_;
  std::vector<FlutterSemanticsCustomAction2*> action_pointers_;

  // Translates engine semantic nodes to embedder semantic nodes.
  void AddNode(const SemanticsNode& node);

  // Translates engine semantic custom actions to embedder semantic custom
  // actions.
  void AddAction(const CustomAccessibilityAction& action);

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderSemanticsUpdate2);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_SEMANTICS_UPDATE_H_
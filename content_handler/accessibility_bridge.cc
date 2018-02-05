// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/accessibility_bridge.h"

#include <unordered_set>

#include "flutter/lib/ui/semantics/semantics_node.h"
#include "lib/app/cpp/application_context.h"
#include "lib/context/fidl/context_writer.fidl.h"
#include "lib/fxl/macros.h"
#include "third_party/rapidjson/rapidjson/document.h"
#include "third_party/rapidjson/rapidjson/stringbuffer.h"
#include "third_party/rapidjson/rapidjson/writer.h"

namespace flutter_runner {

AccessibilityBridge::AccessibilityBridge(app::ApplicationContext* context)
    : writer_(context->ConnectToEnvironmentService<maxwell::ContextWriter>()) {}

void AccessibilityBridge::UpdateSemantics(
    const blink::SemanticsNodeUpdates& update) {
  for (const auto& update : update) {
    const auto& node = update.second;
    semantics_nodes_[node.id] = node;
  }
  std::vector<int> visited_nodes;
  UpdateVisitedForNodeAndChildren(0, &visited_nodes);
  EraseUnvisitedNodes(visited_nodes);

  // The data sent to the Context Service is a JSON formatted list of labels
  // for all on screen widgets.
  rapidjson::Document nodes_json(rapidjson::kArrayType);
  for (const int node_index : visited_nodes) {
    const auto& node = semantics_nodes_[node_index];
    if (!node.label.empty()) {
      rapidjson::Value value;
      value.SetString(node.label.data(), node.label.size());
      nodes_json.PushBack(value, nodes_json.GetAllocator());
    }
  }

  if (nodes_json.Size() > 0) {
    rapidjson::StringBuffer buffer;
    rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
    nodes_json.Accept(writer);
    writer_->WriteEntityTopic("/inferred/accessibility_text",
                              buffer.GetString());
  }
}

void AccessibilityBridge::UpdateVisitedForNodeAndChildren(
    const int id,
    std::vector<int>* visited_nodes) {
  std::map<int, blink::SemanticsNode>::const_iterator it =
      semantics_nodes_.find(id);
  if (it == semantics_nodes_.end()) {
    return;
  }

  visited_nodes->push_back(id);
  for (const int child : it->second.children) {
    UpdateVisitedForNodeAndChildren(child, visited_nodes);
  }
}

void AccessibilityBridge::EraseUnvisitedNodes(
    const std::vector<int>& visited_nodes) {
  const std::unordered_set<int> visited_nodes_lookup(visited_nodes.begin(),
                                                     visited_nodes.end());
  for (auto it = semantics_nodes_.begin(); it != semantics_nodes_.end();) {
    if (visited_nodes_lookup.find((*it).first) == visited_nodes_lookup.end()) {
      it = semantics_nodes_.erase(it);
    } else {
      ++it;
    }
  }
}

}  // namespace flutter_runner

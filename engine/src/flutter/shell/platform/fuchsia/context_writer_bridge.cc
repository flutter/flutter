// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "context_writer_bridge.h"

#include <unordered_set>

#include "rapidjson/document.h"
#include "rapidjson/stringbuffer.h"
#include "rapidjson/writer.h"

namespace flutter_runner {

ContextWriterBridge::ContextWriterBridge(
    fidl::InterfaceHandle<fuchsia::modular::ContextWriter> writer)
    : writer_(writer.Bind()) {}

ContextWriterBridge::~ContextWriterBridge() = default;

void ContextWriterBridge::UpdateSemantics(
    const flutter::SemanticsNodeUpdates& update) {
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

void ContextWriterBridge::UpdateVisitedForNodeAndChildren(
    const int id,
    std::vector<int>* visited_nodes) {
  std::map<int, flutter::SemanticsNode>::const_iterator it =
      semantics_nodes_.find(id);
  if (it == semantics_nodes_.end()) {
    return;
  }

  visited_nodes->push_back(id);
  for (const int child : it->second.childrenInTraversalOrder) {
    UpdateVisitedForNodeAndChildren(child, visited_nodes);
  }
}

void ContextWriterBridge::EraseUnvisitedNodes(
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

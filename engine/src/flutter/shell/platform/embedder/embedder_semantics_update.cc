// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_semantics_update.h"

namespace flutter {

EmbedderSemanticsUpdate::EmbedderSemanticsUpdate(
    const SemanticsNodeUpdates& nodes,
    const CustomAccessibilityActionUpdates& actions) {
  for (const auto& value : nodes) {
    AddNode(value.second);
  }

  for (const auto& value : actions) {
    AddAction(value.second);
  }

  update_ = {
      .struct_size = sizeof(FlutterSemanticsUpdate),
      .nodes_count = nodes_.size(),
      .nodes = nodes_.data(),
      .custom_actions_count = actions_.size(),
      .custom_actions = actions_.data(),
  };
}

void EmbedderSemanticsUpdate::AddNode(const SemanticsNode& node) {
  SkMatrix transform = node.transform.asM33();
  FlutterTransformation flutter_transform{
      transform.get(SkMatrix::kMScaleX), transform.get(SkMatrix::kMSkewX),
      transform.get(SkMatrix::kMTransX), transform.get(SkMatrix::kMSkewY),
      transform.get(SkMatrix::kMScaleY), transform.get(SkMatrix::kMTransY),
      transform.get(SkMatrix::kMPersp0), transform.get(SkMatrix::kMPersp1),
      transform.get(SkMatrix::kMPersp2)};

  // Do not add new members to FlutterSemanticsNode.
  // This would break the forward compatibility of FlutterSemanticsUpdate.
  // All new members must be added to FlutterSemanticsNode2 instead.
  nodes_.push_back({
      sizeof(FlutterSemanticsNode),
      node.id,
      static_cast<FlutterSemanticsFlag>(node.flags),
      static_cast<FlutterSemanticsAction>(node.actions),
      node.textSelectionBase,
      node.textSelectionExtent,
      node.scrollChildren,
      node.scrollIndex,
      node.scrollPosition,
      node.scrollExtentMax,
      node.scrollExtentMin,
      node.elevation,
      node.thickness,
      node.label.c_str(),
      node.hint.c_str(),
      node.value.c_str(),
      node.increasedValue.c_str(),
      node.decreasedValue.c_str(),
      static_cast<FlutterTextDirection>(node.textDirection),
      FlutterRect{node.rect.fLeft, node.rect.fTop, node.rect.fRight,
                  node.rect.fBottom},
      flutter_transform,
      node.childrenInTraversalOrder.size(),
      node.childrenInTraversalOrder.data(),
      node.childrenInHitTestOrder.data(),
      node.customAccessibilityActions.size(),
      node.customAccessibilityActions.data(),
      node.platformViewId,
      node.tooltip.c_str(),
  });
}

void EmbedderSemanticsUpdate::AddAction(
    const CustomAccessibilityAction& action) {
  // Do not add new members to FlutterSemanticsCustomAction.
  // This would break the forward compatibility of FlutterSemanticsUpdate.
  // All new members must be added to FlutterSemanticsCustomAction2 instead.
  actions_.push_back({
      sizeof(FlutterSemanticsCustomAction),
      action.id,
      static_cast<FlutterSemanticsAction>(action.overrideId),
      action.label.c_str(),
      action.hint.c_str(),
  });
}

EmbedderSemanticsUpdate::~EmbedderSemanticsUpdate() {}

EmbedderSemanticsUpdate2::EmbedderSemanticsUpdate2(
    const SemanticsNodeUpdates& nodes,
    const CustomAccessibilityActionUpdates& actions) {
  nodes_.reserve(nodes.size());
  node_pointers_.reserve(nodes.size());
  actions_.reserve(actions.size());
  action_pointers_.reserve(actions.size());

  for (const auto& value : nodes) {
    AddNode(value.second);
  }

  for (const auto& value : actions) {
    AddAction(value.second);
  }

  for (size_t i = 0; i < nodes_.size(); i++) {
    node_pointers_.push_back(&nodes_[i]);
  }

  for (size_t i = 0; i < actions_.size(); i++) {
    action_pointers_.push_back(&actions_[i]);
  }

  update_ = {
      .struct_size = sizeof(FlutterSemanticsUpdate2),
      .node_count = node_pointers_.size(),
      .nodes = node_pointers_.data(),
      .custom_action_count = action_pointers_.size(),
      .custom_actions = action_pointers_.data(),
  };
}

EmbedderSemanticsUpdate2::~EmbedderSemanticsUpdate2() {}

void EmbedderSemanticsUpdate2::AddNode(const SemanticsNode& node) {
  SkMatrix transform = node.transform.asM33();
  FlutterTransformation flutter_transform{
      transform.get(SkMatrix::kMScaleX), transform.get(SkMatrix::kMSkewX),
      transform.get(SkMatrix::kMTransX), transform.get(SkMatrix::kMSkewY),
      transform.get(SkMatrix::kMScaleY), transform.get(SkMatrix::kMTransY),
      transform.get(SkMatrix::kMPersp0), transform.get(SkMatrix::kMPersp1),
      transform.get(SkMatrix::kMPersp2)};

  nodes_.push_back({
      sizeof(FlutterSemanticsNode2),
      node.id,
      static_cast<FlutterSemanticsFlag>(node.flags),
      static_cast<FlutterSemanticsAction>(node.actions),
      node.textSelectionBase,
      node.textSelectionExtent,
      node.scrollChildren,
      node.scrollIndex,
      node.scrollPosition,
      node.scrollExtentMax,
      node.scrollExtentMin,
      node.elevation,
      node.thickness,
      node.label.c_str(),
      node.hint.c_str(),
      node.value.c_str(),
      node.increasedValue.c_str(),
      node.decreasedValue.c_str(),
      static_cast<FlutterTextDirection>(node.textDirection),
      FlutterRect{node.rect.fLeft, node.rect.fTop, node.rect.fRight,
                  node.rect.fBottom},
      flutter_transform,
      node.childrenInTraversalOrder.size(),
      node.childrenInTraversalOrder.data(),
      node.childrenInHitTestOrder.data(),
      node.customAccessibilityActions.size(),
      node.customAccessibilityActions.data(),
      node.platformViewId,
      node.tooltip.c_str(),
  });
}

void EmbedderSemanticsUpdate2::AddAction(
    const CustomAccessibilityAction& action) {
  actions_.push_back({
      sizeof(FlutterSemanticsCustomAction2),
      action.id,
      static_cast<FlutterSemanticsAction>(action.overrideId),
      action.label.c_str(),
      action.hint.c_str(),
  });
}

}  // namespace flutter

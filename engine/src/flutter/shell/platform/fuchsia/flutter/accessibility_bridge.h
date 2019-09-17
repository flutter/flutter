// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOPAZ_RUNTIME_FLUTTER_RUNNER_ACCESSIBILITY_BRIDGE_H_
#define TOPAZ_RUNTIME_FLUTTER_RUNNER_ACCESSIBILITY_BRIDGE_H_

#include <fuchsia/accessibility/semantics/cpp/fidl.h>
#include <fuchsia/sys/cpp/fidl.h>
#include <fuchsia/ui/gfx/cpp/fidl.h>
#include <lib/fidl/cpp/binding_set.h>
#include <lib/sys/cpp/service_directory.h>
#include <zircon/types.h>

#include <memory>
#include <optional>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/lib/ui/semantics/semantics_node.h"

namespace flutter_runner {
// Accessibility bridge.
//
// This class intermediates accessibility-related calls between Fuchsia and
// Flutter. It serves to resolve the impedance mismatch between Flutter's
// platform-agnostic accessibility APIs and Fuchsia's APIs and behaviour.
//
// This bridge performs the following functions, among others:
//
// * Translates Flutter's semantics node updates to events Fuchsia requires
//   (e.g. Flutter only sends updates for changed nodes, but Fuchsia requires
//   the entire flattened subtree to be sent when a node changes.
class AccessibilityBridge
    : public fuchsia::accessibility::semantics::SemanticListener {
 public:
  // TODO(MI4-2531, FIDL-718): Remove this. We shouldn't be worried about
  // batching messages at this level.
  // FIDL may encode a C++ struct as larger than the sizeof the C++ struct.
  // This is to make sure we don't send updates that are too large.
  static constexpr uint32_t kMaxMessageSize = ZX_CHANNEL_MAX_MSG_BYTES / 2;

  static_assert(fuchsia::accessibility::semantics::MAX_LABEL_SIZE <
                kMaxMessageSize - 1);

  // Flutter uses signed 32 bit integers for node IDs, while Fuchsia uses
  // unsigned 32 bit integers. A change in the size on either one would break
  // casts and size tracking logic in the implementation.
  static constexpr size_t kNodeIdSize = sizeof(flutter::SemanticsNode::id);
  static_assert(
      kNodeIdSize ==
          sizeof(fuchsia::accessibility::semantics::Node().node_id()),
      "flutter::SemanticsNode::id and "
      "fuchsia::accessibility::semantics::Node::node_id differ in size.");

  AccessibilityBridge(const std::shared_ptr<sys::ServiceDirectory> services,
                      fuchsia::ui::views::ViewRef view_ref);

  // Returns true if accessible navigation is enabled.
  bool GetSemanticsEnabled() const;

  // Enables Flutter accessibility navigation features.
  //
  // Once enabled, any semantics updates in the Flutter application will
  // trigger |FuchsiaAccessibility::DispatchAccessibilityEvent| callbacks
  // to send events back to the Fuchsia SemanticsManager.
  void SetSemanticsEnabled(bool enabled);

  // Adds a semantics node update to the buffer of node updates to apply.
  void AddSemanticsNodeUpdate(const flutter::SemanticsNodeUpdates update);

  // Notifies the bridge of a 'hover move' touch exploration event.
  zx_status_t OnHoverMove(double x, double y);

 private:
  static constexpr int32_t kRootNodeId = 0;
  fidl::Binding<fuchsia::accessibility::semantics::SemanticListener> binding_;
  fuchsia::accessibility::semantics::SemanticsManagerPtr
      fuchsia_semantics_manager_;
  fuchsia::accessibility::semantics::SemanticTreePtr tree_ptr_;
  bool semantics_enabled_;
  // This is the cache of all nodes we've sent to Fuchsia's SemanticsManager.
  // Assists with pruning unreachable nodes.
  std::unordered_map<int32_t, std::vector<int32_t>> nodes_;

  // Derives the BoundingBox of a Flutter semantics node from its
  // rect and elevation.
  fuchsia::ui::gfx::BoundingBox GetNodeLocation(
      const flutter::SemanticsNode& node) const;

  // Converts a Flutter semantics node's transformation to a mat4.
  fuchsia::ui::gfx::mat4 GetNodeTransform(
      const flutter::SemanticsNode& node) const;

  // Derives the attributes for a Fuchsia semantics node from a Flutter
  // semantics node.
  fuchsia::accessibility::semantics::Attributes GetNodeAttributes(
      const flutter::SemanticsNode& node,
      size_t* added_size) const;

  // Derives the states for a Fuchsia semantics node from a Flutter semantics
  // node.
  fuchsia::accessibility::semantics::States GetNodeStates(
      const flutter::SemanticsNode& node) const;

  // Gets the set of reachable descendants from the given node id.
  std::unordered_set<int32_t> GetDescendants(int32_t node_id) const;

  // Removes internal references to any dangling nodes from previous
  // updates, and updates the Accessibility service.
  //
  // May result in a call to FuchsiaAccessibility::Commit().
  void PruneUnreachableNodes();

  // |fuchsia::accessibility::semantics::SemanticListener|
  void OnAccessibilityActionRequested(
      uint32_t node_id,
      fuchsia::accessibility::semantics::Action action,
      fuchsia::accessibility::semantics::SemanticListener::
          OnAccessibilityActionRequestedCallback callback) override;

  // |fuchsia::accessibility::semantics::SemanticListener|
  void HitTest(
      fuchsia::math::PointF local_point,
      fuchsia::accessibility::semantics::SemanticListener::HitTestCallback
          callback) override;

  // |fuchsia::accessibility::semantics::SemanticListener|
  void OnSemanticsModeChanged(
      bool enabled,
      OnSemanticsModeChangedCallback callback) override {}

  FML_DISALLOW_COPY_AND_ASSIGN(AccessibilityBridge);
};
}  // namespace flutter_runner

#endif  // TOPAZ_RUNTIME_FLUTTER_RUNNER_ACCESSIBILITY_BRIDGE_H_

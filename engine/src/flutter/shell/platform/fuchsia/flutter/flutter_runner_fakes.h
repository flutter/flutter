// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOPAZ_RUNTIME_FLUTTER_RUNNER_PLATFORM_VIEW_FAKES_H_
#define TOPAZ_RUNTIME_FLUTTER_RUNNER_PLATFORM_VIEW_FAKES_H_

#include <fuchsia/accessibility/semantics/cpp/fidl.h>

namespace flutter_runner_test {
using fuchsia::accessibility::semantics::SemanticsManager;

class MockSemanticsManager
    : public SemanticsManager,
      public fuchsia::accessibility::semantics::SemanticTree {
 public:
  MockSemanticsManager() : tree_binding_(this) {}

  // |fuchsia::accessibility::semantics::SemanticsManager|:
  void RegisterViewForSemantics(
      fuchsia::ui::views::ViewRef view_ref,
      fidl::InterfaceHandle<fuchsia::accessibility::semantics::SemanticListener>
          handle,
      fidl::InterfaceRequest<fuchsia::accessibility::semantics::SemanticTree>
          semantic_tree) override {
    tree_binding_.Bind(std::move(semantic_tree));
    has_view_ref_ = true;
  }

  fidl::InterfaceRequestHandler<SemanticsManager> GetHandler(
      async_dispatcher_t* dispatcher) {
    return bindings_.GetHandler(this, dispatcher);
  }

  bool RegisterViewCalled() { return has_view_ref_; }

  void ResetTree() {
    update_count_ = 0;
    delete_count_ = 0;
    commit_count_ = 0;
    last_updated_nodes_.clear();
    last_deleted_node_ids_.clear();
    delete_overflowed_ = false;
    update_overflowed_ = false;
  }

  void UpdateSemanticNodes(
      std::vector<fuchsia::accessibility::semantics::Node> nodes) override {
    update_count_++;
    if (!update_overflowed_) {
      size_t size = 0;
      for (const auto& node : nodes) {
        size += sizeof(node);
        size += sizeof(node.attributes().label().size());
      }
      update_overflowed_ = size > ZX_CHANNEL_MAX_MSG_BYTES;
    }
    last_updated_nodes_ = std::move(nodes);
  }

  void DeleteSemanticNodes(std::vector<uint32_t> node_ids) override {
    delete_count_++;
    if (!delete_overflowed_) {
      size_t size =
          sizeof(node_ids) +
          (node_ids.size() * flutter_runner::AccessibilityBridge::kNodeIdSize);
      delete_overflowed_ = size > ZX_CHANNEL_MAX_MSG_BYTES;
    }
    last_deleted_node_ids_ = std::move(node_ids);
  }

  const std::vector<uint32_t>& LastDeletedNodeIds() const {
    return last_deleted_node_ids_;
  }

  int DeleteCount() const { return delete_count_; }
  bool DeleteOverflowed() const { return delete_overflowed_; }

  int UpdateCount() const { return update_count_; }
  bool UpdateOverflowed() const { return update_overflowed_; }

  int CommitCount() const { return commit_count_; }

  const std::vector<fuchsia::accessibility::semantics::Node>& LastUpdatedNodes()
      const {
    return last_updated_nodes_;
  }

  void CommitUpdates(CommitUpdatesCallback callback) override {
    commit_count_++;
  }

 private:
  bool has_view_ref_ = false;
  fidl::BindingSet<SemanticsManager> bindings_;
  fidl::Binding<SemanticTree> tree_binding_;

  std::vector<fuchsia::accessibility::semantics::Node> last_updated_nodes_;
  bool update_overflowed_;
  int update_count_;
  int delete_count_;
  bool delete_overflowed_;
  std::vector<uint32_t> last_deleted_node_ids_;
  int commit_count_;
};

}  // namespace flutter_runner_test

#endif  // TOPAZ_RUNTIME_FLUTTER_RUNNER_PLATFORM_VIEW_FAKES_H_

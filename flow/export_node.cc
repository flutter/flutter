// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/export_node.h"

#include "flutter/common/threads.h"
#include "lib/ftl/functional/make_copyable.h"

namespace flow {

ExportNodeHolder::ExportNodeHolder(
    ftl::RefPtr<fidl::dart::Handle> export_token_handle)
    : export_node_(std::make_unique<ExportNode>(export_token_handle)) {
  ASSERT_IS_UI_THREAD;
}

void ExportNodeHolder::Bind(SceneUpdateContext& context,
                            mozart::client::ContainerNode& container,
                            const SkPoint& offset,
                            bool hit_testable) {
  ASSERT_IS_GPU_THREAD;
  export_node_->Bind(context, container, offset, hit_testable);
}

ExportNodeHolder::~ExportNodeHolder() {
  ASSERT_IS_UI_THREAD;
  blink::Threads::Gpu()->PostTask(
      ftl::MakeCopyable([export_node = std::move(export_node_)]() {
        export_node->Dispose(true);
      }));
}

ExportNode::ExportNode(ftl::RefPtr<fidl::dart::Handle> export_token_handle)
    : export_token_(export_token_handle->ReleaseHandle()) {}

ExportNode::~ExportNode() {
  // Ensure that we properly released the node.
  FTL_DCHECK(!node_);
  FTL_DCHECK(scene_update_context_ == nullptr);
}

void ExportNode::Bind(SceneUpdateContext& context,
                      mozart::client::ContainerNode& container,
                      const SkPoint& offset,
                      bool hit_testable) {
  ASSERT_IS_GPU_THREAD;

  if (export_token_) {
    // Happens first time we bind.
    node_.reset(new mozart::client::EntityNode(container.session()));
    node_->Export(std::move(export_token_));

    // Add ourselves to the context so it can call Dispose() on us if the Mozart
    // session is closed.
    context.AddExportNode(this);
    scene_update_context_ = &context;
  }

  if (node_) {
    container.AddChild(*node_);
    node_->SetTranslation(offset.x(), offset.y(), 0.f);
    node_->SetHitTestBehavior(hit_testable
                                  ? mozart2::HitTestBehavior::kDefault
                                  : mozart2::HitTestBehavior::kSuppress);
  }
}

void ExportNode::Dispose(bool remove_from_scene_update_context) {
  ASSERT_IS_GPU_THREAD;

  // If scene_update_context_ is set, then we should still have a node left to
  // dereference.
  // If scene_update_context_ is null, then either:
  // 1. A node was never created, or
  // 2. A node was created but was already dereferenced (i.e. Dispose has
  // already been called).
  FTL_DCHECK(scene_update_context_ || !node_);

  if (remove_from_scene_update_context && scene_update_context_) {
    scene_update_context_->RemoveExportNode(this);
  }

  scene_update_context_ = nullptr;
  export_token_.reset();
  node_ = nullptr;
}

}  // namespace flow

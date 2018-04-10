// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/export_node.h"

#include "lib/fxl/functional/make_copyable.h"

namespace flow {

ExportNodeHolder::ExportNodeHolder(
    fxl::RefPtr<fxl::TaskRunner> gpu_task_runner,
    fxl::RefPtr<zircon::dart::Handle> export_token_handle)
    : gpu_task_runner_(std::move(gpu_task_runner)),
      export_node_(std::make_unique<ExportNode>(export_token_handle)) {
  FXL_DCHECK(gpu_task_runner_);
}

void ExportNodeHolder::Bind(SceneUpdateContext& context,
                            scenic_lib::ContainerNode& container,
                            const SkPoint& offset,
                            bool hit_testable) {
  export_node_->Bind(context, container, offset, hit_testable);
}

ExportNodeHolder::~ExportNodeHolder() {
  gpu_task_runner_->PostTask(
      fxl::MakeCopyable([export_node = std::move(export_node_)]() {
        export_node->Dispose(true);
      }));
}

ExportNode::ExportNode(fxl::RefPtr<zircon::dart::Handle> export_token_handle)
    : export_token_(export_token_handle->ReleaseHandle()) {}

ExportNode::~ExportNode() {
  // Ensure that we properly released the node.
  FXL_DCHECK(!node_);
  FXL_DCHECK(scene_update_context_ == nullptr);
}

void ExportNode::Bind(SceneUpdateContext& context,
                      scenic_lib::ContainerNode& container,
                      const SkPoint& offset,
                      bool hit_testable) {
  if (export_token_) {
    // Happens first time we bind.
    node_.reset(new scenic_lib::EntityNode(container.session()));
    node_->Export(std::move(export_token_));

    // Add ourselves to the context so it can call Dispose() on us if the Scenic
    // session is closed.
    context.AddExportNode(this);
    scene_update_context_ = &context;
  }

  if (node_) {
    container.AddChild(*node_);
    node_->SetTranslation(offset.x(), offset.y(), 0.f);
    node_->SetHitTestBehavior(hit_testable
                                  ? gfx::HitTestBehavior::kDefault
                                  : gfx::HitTestBehavior::kSuppress);
  }
}

void ExportNode::Dispose(bool remove_from_scene_update_context) {
  // If scene_update_context_ is set, then we should still have a node left to
  // dereference.
  // If scene_update_context_ is null, then either:
  // 1. A node was never created, or
  // 2. A node was created but was already dereferenced (i.e. Dispose has
  // already been called).
  FXL_DCHECK(scene_update_context_ || !node_);

  if (remove_from_scene_update_context && scene_update_context_) {
    scene_update_context_->RemoveExportNode(this);
  }

  scene_update_context_ = nullptr;
  export_token_.reset();
  node_ = nullptr;
}

}  // namespace flow

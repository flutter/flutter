// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/export_node.h"

#include "flutter/fml/thread_local.h"

namespace {

using ExportNodeBindings =
    std::unordered_map<zx_koid_t, std::unique_ptr<flutter::ExportNode>>;

FML_THREAD_LOCAL fml::ThreadLocalUniquePtr<ExportNodeBindings>
    tls_export_node_bindings;

}  // namespace

namespace flutter {

ExportNode::ExportNode(zx::eventpair export_token)
    : pending_export_token_(std::move(export_token)) {
  FML_DCHECK(pending_export_token_);
}

void ExportNode::Create(zx_koid_t id, zx::eventpair export_token) {
  // This GPU thread contains at least 1 ViewHolder.  Initialize the per-thread
  // bindings.
  if (tls_export_node_bindings.get() == nullptr) {
    tls_export_node_bindings.reset(new ExportNodeBindings());
  }

  auto* bindings = tls_export_node_bindings.get();
  FML_DCHECK(bindings);
  FML_DCHECK(bindings->find(id) == bindings->end());

  auto export_node =
      std::unique_ptr<ExportNode>(new ExportNode(std::move(export_token)));
  bindings->emplace(id, std::move(export_node));
}

void ExportNode::Destroy(zx_koid_t id) {
  auto* bindings = tls_export_node_bindings.get();
  FML_DCHECK(bindings);

  bindings->erase(id);
}

ExportNode* ExportNode::FromId(zx_koid_t id) {
  auto* bindings = tls_export_node_bindings.get();
  if (!bindings) {
    return nullptr;
  }

  auto binding = bindings->find(id);
  if (binding == bindings->end()) {
    return nullptr;
  }

  return binding->second.get();
}

void ExportNode::UpdateScene(SceneUpdateContext& context,
                             const SkPoint& offset,
                             const SkSize& size,
                             bool hit_testable) {
  if (pending_export_token_) {
    export_node_ = std::make_unique<scenic::EntityNode>(context.session());
    export_node_->Export(std::move(pending_export_token_));
  }
  FML_DCHECK(export_node_);

  context.top_entity()->entity_node().AddChild(*export_node_);
  export_node_->SetTranslation(offset.x(), offset.y(), -0.1f);
  export_node_->SetHitTestBehavior(
      hit_testable ? fuchsia::ui::gfx::HitTestBehavior::kDefault
                   : fuchsia::ui::gfx::HitTestBehavior::kSuppress);
}

}  // namespace flutter

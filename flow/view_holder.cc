// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/view_holder.h"

#include "flutter/fml/thread_local.h"

namespace {

using ViewHolderBindings =
    std::unordered_map<zx_koid_t, std::unique_ptr<flow::ViewHolder>>;

FML_THREAD_LOCAL fml::ThreadLocal tls_view_holder_bindings([](intptr_t value) {
  delete reinterpret_cast<ViewHolderBindings*>(value);
});

fuchsia::ui::gfx::ViewProperties ToViewProperties(float width,
                                                  float height,
                                                  float insetTop,
                                                  float insetRight,
                                                  float insetBottom,
                                                  float insetLeft,
                                                  bool focusable) {
  return fuchsia::ui::gfx::ViewProperties({
      .bounding_box = fuchsia::ui::gfx::BoundingBox({
          .min = fuchsia::ui::gfx::vec3({
              .x = 0.f,
              .y = 0.f,
              .z = -1000.f,
          }),
          .max = fuchsia::ui::gfx::vec3({.x = width, .y = height, .z = 0.f}),
      }),
      .inset_from_min = fuchsia::ui::gfx::vec3({
          .x = insetLeft,
          .y = insetTop,
          .z = 0.f,
      }),
      .inset_from_max = fuchsia::ui::gfx::vec3({
          .x = insetRight,
          .y = insetBottom,
          .z = 0.f,
      }),
      .focus_change = focusable,
  });
}

}  // namespace

namespace flow {

ViewHolder::ViewHolder(fml::RefPtr<fml::TaskRunner> ui_task_runner,
                       fuchsia::ui::views::ViewHolderToken view_holder_token,
                       BindCallback on_bind_callback)
    : pending_view_holder_token_(std::move(view_holder_token)),
      ui_task_runner_(std::move(ui_task_runner)),
      pending_bind_callback_(std::move(on_bind_callback)) {
  FML_DCHECK(pending_view_holder_token_.value);
  FML_DCHECK(ui_task_runner_);
}

void ViewHolder::Create(zx_koid_t id,
                        fml::RefPtr<fml::TaskRunner> ui_task_runner,
                        fuchsia::ui::views::ViewHolderToken view_holder_token,
                        BindCallback on_bind_callback) {
  // This GPU thread contains at least 1 ViewHolder.  Initialize the per-thread
  // bindings.
  if (tls_view_holder_bindings.Get() == 0) {
    tls_view_holder_bindings.Set(
        reinterpret_cast<intptr_t>(new ViewHolderBindings()));
  }

  auto* bindings =
      reinterpret_cast<ViewHolderBindings*>(tls_view_holder_bindings.Get());
  FML_DCHECK(bindings);
  FML_DCHECK(bindings->find(id) == bindings->end());

  auto view_holder = std::unique_ptr<ViewHolder>(
      new ViewHolder(std::move(ui_task_runner), std::move(view_holder_token),
                     std::move(on_bind_callback)));
  bindings->emplace(id, std::move(view_holder));
}

void ViewHolder::Destroy(zx_koid_t id) {
  auto* bindings =
      reinterpret_cast<ViewHolderBindings*>(tls_view_holder_bindings.Get());
  FML_DCHECK(bindings);

  bindings->erase(id);
}

ViewHolder* ViewHolder::FromId(zx_koid_t id) {
  auto* bindings =
      reinterpret_cast<ViewHolderBindings*>(tls_view_holder_bindings.Get());
  if (!bindings) {
    return nullptr;
  }

  auto binding = bindings->find(id);
  if (binding == bindings->end()) {
    return nullptr;
  }

  return binding->second.get();
}

void ViewHolder::UpdateScene(SceneUpdateContext& context,
                             const SkPoint& offset,
                             const SkSize& size,
                             bool hit_testable) {
  if (pending_view_holder_token_.value) {
    entity_node_ = std::make_unique<scenic::EntityNode>(context.session());
    view_holder_ = std::make_unique<scenic::ViewHolder>(
        context.session(), std::move(pending_view_holder_token_),
        "Flutter SceneHost");

    entity_node_->Attach(*view_holder_);
    ui_task_runner_->PostTask(
        [bind_callback = std::move(pending_bind_callback_),
         view_holder_id = view_holder_->id()]() {
          bind_callback(view_holder_id);
        });
  }
  FML_DCHECK(entity_node_);
  FML_DCHECK(view_holder_);

  context.top_entity()->entity_node().AddChild(*entity_node_);
  entity_node_->SetTranslation(offset.x(), offset.y(), -0.1f);
  entity_node_->SetHitTestBehavior(
      hit_testable ? fuchsia::ui::gfx::HitTestBehavior::kDefault
                   : fuchsia::ui::gfx::HitTestBehavior::kSuppress);
  if (has_pending_properties_) {
    view_holder_->SetViewProperties(std::move(pending_properties_));

    has_pending_properties_ = false;
  }
}

void ViewHolder::SetProperties(double width,
                               double height,
                               double insetTop,
                               double insetRight,
                               double insetBottom,
                               double insetLeft,
                               bool focusable) {
  pending_properties_ = ToViewProperties(width, height, insetTop, insetRight,
                                         insetBottom, insetLeft, focusable);
  has_pending_properties_ = true;
}

}  // namespace flow

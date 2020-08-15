// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/view_holder.h"

#include <unordered_map>

#include "flutter/fml/thread_local.h"

namespace {

using ViewHolderBindings =
    std::unordered_map<zx_koid_t, std::unique_ptr<flutter::ViewHolder>>;

FML_THREAD_LOCAL fml::ThreadLocalUniquePtr<ViewHolderBindings>
    tls_view_holder_bindings;

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

namespace flutter {

void ViewHolder::Create(zx_koid_t id,
                        fml::RefPtr<fml::TaskRunner> ui_task_runner,
                        fuchsia::ui::views::ViewHolderToken view_holder_token,
                        const BindCallback& on_bind_callback) {
  // This raster thread contains at least 1 ViewHolder.  Initialize the
  // per-thread bindings.
  if (tls_view_holder_bindings.get() == nullptr) {
    tls_view_holder_bindings.reset(new ViewHolderBindings());
  }

  auto* bindings = tls_view_holder_bindings.get();
  FML_DCHECK(bindings);
  FML_DCHECK(bindings->find(id) == bindings->end());

  auto view_holder = std::make_unique<ViewHolder>(std::move(ui_task_runner),
                                                  std::move(view_holder_token),
                                                  on_bind_callback);
  bindings->emplace(id, std::move(view_holder));
}

void ViewHolder::Destroy(zx_koid_t id) {
  auto* bindings = tls_view_holder_bindings.get();
  FML_DCHECK(bindings);

  bindings->erase(id);
}

ViewHolder* ViewHolder::FromId(zx_koid_t id) {
  auto* bindings = tls_view_holder_bindings.get();
  if (!bindings) {
    return nullptr;
  }

  auto binding = bindings->find(id);
  if (binding == bindings->end()) {
    return nullptr;
  }

  return binding->second.get();
}

ViewHolder::ViewHolder(fml::RefPtr<fml::TaskRunner> ui_task_runner,
                       fuchsia::ui::views::ViewHolderToken view_holder_token,
                       const BindCallback& on_bind_callback)
    : ui_task_runner_(std::move(ui_task_runner)),
      pending_view_holder_token_(std::move(view_holder_token)),
      pending_bind_callback_(on_bind_callback) {
  FML_DCHECK(pending_view_holder_token_.value);
}

void ViewHolder::UpdateScene(scenic::Session* session,
                             scenic::ContainerNode& container_node,
                             const SkPoint& offset,
                             const SkSize& size,
                             SkAlpha opacity,
                             bool hit_testable) {
  if (pending_view_holder_token_.value) {
    entity_node_ = std::make_unique<scenic::EntityNode>(session);
    opacity_node_ = std::make_unique<scenic::OpacityNodeHACK>(session);
    view_holder_ = std::make_unique<scenic::ViewHolder>(
        session, std::move(pending_view_holder_token_), "Flutter SceneHost");
    opacity_node_->AddChild(*entity_node_);
    opacity_node_->SetLabel("flutter::ViewHolder");
    entity_node_->Attach(*view_holder_);
    if (ui_task_runner_ && pending_view_holder_token_.value) {
      ui_task_runner_->PostTask(
          [bind_callback = std::move(pending_bind_callback_),
           view_holder_id = view_holder_->id()]() {
            bind_callback(view_holder_id);
          });
    }
  }
  FML_DCHECK(entity_node_);
  FML_DCHECK(opacity_node_);
  FML_DCHECK(view_holder_);

  container_node.AddChild(*opacity_node_);
  opacity_node_->SetOpacity(opacity / 255.0f);
  entity_node_->SetTranslation(offset.x(), offset.y(), -0.1f);
  entity_node_->SetHitTestBehavior(
      hit_testable ? fuchsia::ui::gfx::HitTestBehavior::kDefault
                   : fuchsia::ui::gfx::HitTestBehavior::kSuppress);
  if (has_pending_properties_) {
    // TODO(dworsham): This should be derived from size and elevation.  We
    // should be able to Z-limit the view's box but otherwise it uses all of the
    // available airspace.
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

}  // namespace flutter

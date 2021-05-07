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
                        ViewIdCallback on_view_created,
                        fuchsia::ui::views::ViewHolderToken view_holder_token) {
  // This raster thread contains at least 1 ViewHolder.  Initialize the
  // per-thread bindings.
  if (tls_view_holder_bindings.get() == nullptr) {
    tls_view_holder_bindings.reset(new ViewHolderBindings());
  }

  auto* bindings = tls_view_holder_bindings.get();
  FML_DCHECK(bindings);
  FML_DCHECK(bindings->find(id) == bindings->end());

  auto view_holder = std::unique_ptr<ViewHolder>(
      new ViewHolder(std::move(view_holder_token), std::move(on_view_created)));
  bindings->emplace(id, std::move(view_holder));
}

void ViewHolder::Destroy(zx_koid_t id, ViewIdCallback on_view_destroyed) {
  auto* bindings = tls_view_holder_bindings.get();
  FML_DCHECK(bindings);
  auto binding = bindings->find(id);
  FML_DCHECK(binding != bindings->end());

  if (binding->second->view_holder_ && on_view_destroyed) {
    on_view_destroyed(binding->second->view_holder_->id());
  }
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

ViewHolder::ViewHolder(fuchsia::ui::views::ViewHolderToken view_holder_token,
                       ViewIdCallback on_view_created)
    : pending_view_holder_token_(std::move(view_holder_token)),
      on_view_created_(std::move(on_view_created)) {
  FML_DCHECK(pending_view_holder_token_.value);
}

void ViewHolder::UpdateScene(scenic::Session* session,
                             scenic::ContainerNode& container_node,
                             const SkPoint& offset,
                             SkAlpha opacity) {
  if (pending_view_holder_token_.value) {
    entity_node_ = std::make_unique<scenic::EntityNode>(session);
    opacity_node_ = std::make_unique<scenic::OpacityNodeHACK>(session);
    view_holder_ = std::make_unique<scenic::ViewHolder>(
        session, std::move(pending_view_holder_token_), "Flutter SceneHost");
    opacity_node_->AddChild(*entity_node_);
    opacity_node_->SetLabel("flutter::ViewHolder");
    entity_node_->Attach(*view_holder_);

    // Inform the rest of Flutter about the view being created.
    // As long as we do this before calling `Present` on the session,
    // View-related messages sent to the UI thread will never be processed
    // before this internal message is delivered to the UI thread.
    if (on_view_created_) {
      on_view_created_(view_holder_->id());
    }
  }
  FML_DCHECK(entity_node_);
  FML_DCHECK(opacity_node_);
  FML_DCHECK(view_holder_);

  container_node.AddChild(*opacity_node_);
  opacity_node_->SetOpacity(opacity / 255.0f);
  entity_node_->SetTranslation(offset.x(), offset.y(), -0.1f);
  entity_node_->SetHitTestBehavior(hit_test_behavior_);
  view_holder_->SetViewProperties(view_properties_);
}

void ViewHolder::SetProperties(double width,
                               double height,
                               double insetTop,
                               double insetRight,
                               double insetBottom,
                               double insetLeft,
                               bool focusable) {
  view_properties_ = ToViewProperties(width, height, insetTop, insetRight,
                                      insetBottom, insetLeft, focusable);
}

void ViewHolder::set_hit_testable(bool value) {
  hit_test_behavior_ = value ? fuchsia::ui::gfx::HitTestBehavior::kDefault
                             : fuchsia::ui::gfx::HitTestBehavior::kSuppress;
}

void ViewHolder::set_focusable(bool value) {
  view_properties_.focus_change = value;
}

void ViewHolder::set_size(const SkSize& size) {
  // TODO(dworsham): The Z-bound should be derived from elevation.  We should be
  // able to Z-limit the view's box but otherwise it uses all of the available
  // airspace.
  view_properties_.bounding_box.max.x = size.width();
  view_properties_.bounding_box.max.y = size.height();
}

void ViewHolder::set_occlusion_hint(const SkRect& occlusion_hint) {
  view_properties_.inset_from_min.x = occlusion_hint.fLeft;
  view_properties_.inset_from_min.y = occlusion_hint.fTop;
  view_properties_.inset_from_max.x = occlusion_hint.fRight;
  view_properties_.inset_from_max.y = occlusion_hint.fBottom;
}

}  // namespace flutter

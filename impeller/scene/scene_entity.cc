// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/scene_entity.h"

#include <memory>

#include "impeller/base/validation.h"
#include "impeller/geometry/matrix.h"
#include "impeller/scene/scene_encoder.h"
#include "impeller/scene/static_mesh_entity.h"

namespace impeller {
namespace scene {

SceneEntity::SceneEntity() = default;

SceneEntity::~SceneEntity() = default;

std::shared_ptr<StaticMeshEntity> SceneEntity::MakeStaticMesh() {
  return std::make_shared<StaticMeshEntity>();
}

void SceneEntity::SetLocalTransform(Matrix transform) {
  local_transform_ = transform;
}

Matrix SceneEntity::GetLocalTransform() const {
  return local_transform_;
}

void SceneEntity::SetGlobalTransform(Matrix transform) {
  Matrix inverse_global_transform =
      parent_ ? parent_->GetGlobalTransform().Invert() : Matrix();

  local_transform_ = inverse_global_transform * transform;
}

Matrix SceneEntity::GetGlobalTransform() const {
  if (parent_) {
    return parent_->GetGlobalTransform() * local_transform_;
  }
  return local_transform_;
}

bool SceneEntity::Add(const std::shared_ptr<SceneEntity>& child) {
  if (child->parent_ != nullptr) {
    VALIDATION_LOG << "Cannot add SceneEntity as a child because it already "
                      "has a parent assigned.";
    return false;
  }

  children_.push_back(child);
  child->parent_ = this;
  return true;
}

bool SceneEntity::Render(SceneEncoder& encoder) const {
  OnRender(encoder);
  for (auto& child : children_) {
    if (!child->Render(encoder)) {
      return false;
    }
  }
  return true;
}

bool SceneEntity::OnRender(SceneEncoder& encoder) const {
  return true;
}

}  // namespace scene
}  // namespace impeller

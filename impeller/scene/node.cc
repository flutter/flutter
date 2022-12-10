// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/node.h"

#include <memory>

#include "impeller/base/validation.h"
#include "impeller/geometry/matrix.h"
#include "impeller/scene/mesh.h"
#include "impeller/scene/node.h"
#include "impeller/scene/scene_encoder.h"

namespace impeller {
namespace scene {

Node::Node() = default;

Node::~Node() = default;

void Node::SetLocalTransform(Matrix transform) {
  local_transform_ = transform;
}

Matrix Node::GetLocalTransform() const {
  return local_transform_;
}

void Node::SetGlobalTransform(Matrix transform) {
  Matrix inverse_global_transform =
      parent_ ? parent_->GetGlobalTransform().Invert() : Matrix();

  local_transform_ = inverse_global_transform * transform;
}

Matrix Node::GetGlobalTransform() const {
  if (parent_) {
    return parent_->GetGlobalTransform() * local_transform_;
  }
  return local_transform_;
}

void Node::AddChild(Node child) {
  children_.push_back(child);
  child.parent_ = this;
}

void Node::SetMesh(const Mesh& mesh) {
  mesh_ = mesh;
}

bool Node::Render(SceneEncoder& encoder, const Matrix& parent_transform) const {
  Matrix transform = parent_transform * local_transform_;

  mesh_.Render(encoder, transform);

  for (auto& child : children_) {
    if (!child.Render(encoder, transform)) {
      return false;
    }
  }
  return true;
}

}  // namespace scene
}  // namespace impeller

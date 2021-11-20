// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/entity.h"

namespace impeller {

Entity::Entity() = default;

Entity::~Entity() = default;

const Matrix& Entity::GetTransformation() const {
  return transformation_;
}

void Entity::SetTransformation(const Matrix& transformation) {
  transformation_ = transformation;
}

const Path& Entity::GetPath() const {
  return path_;
}

void Entity::SetPath(Path path) {
  path_ = std::move(path);
}

void Entity::SetContents(std::shared_ptr<Contents> contents) {
  contents_ = std::move(contents);
}

const std::shared_ptr<Contents>& Entity::GetContents() const {
  return contents_;
}

void Entity::SetStencilDepth(uint32_t depth) {
  stencil_depth_ = depth;
}

uint32_t Entity::GetStencilDepth() const {
  return stencil_depth_;
}

}  // namespace impeller

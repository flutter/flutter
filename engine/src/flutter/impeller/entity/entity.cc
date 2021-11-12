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

const Color& Entity::GetStrokeColor() const {
  return stroke_color_;
}

void Entity::SetStrokeColor(const Color& strokeColor) {
  stroke_color_ = strokeColor;
}

double Entity::GetStrokeSize() const {
  return stroke_size_;
}

void Entity::SetStrokeSize(double strokeSize) {
  stroke_size_ = std::max(strokeSize, 0.0);
}

const Path& Entity::GetPath() const {
  return path_;
}

void Entity::SetPath(Path path) {
  path_ = std::move(path);
}

void Entity::SetIsClip(bool is_clip) {
  is_clip_ = is_clip;
}

bool Entity::IsClip() const {
  return is_clip_;
}

void Entity::SetContents(std::shared_ptr<Contents> contents) {
  contents_ = std::move(contents);
}

const std::shared_ptr<Contents>& Entity::GetContents() const {
  return contents_;
}

}  // namespace impeller

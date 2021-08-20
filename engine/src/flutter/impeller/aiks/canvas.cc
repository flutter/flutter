// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/canvas.h"

#include <algorithm>

#include "flutter/fml/logging.h"

namespace impeller {

Canvas::Canvas() {
  xformation_stack_.push(Matrix{});
}

Canvas::~Canvas() = default;

void Canvas::Save() {
  FML_DCHECK(xformation_stack_.size() > 0);
  xformation_stack_.push(xformation_stack_.top());
}

bool Canvas::Restore() {
  FML_DCHECK(xformation_stack_.size() > 0);
  if (xformation_stack_.size() == 1) {
    return false;
  }
  xformation_stack_.pop();
  return true;
}

void Canvas::Concat(const Matrix& xformation) {
  xformation_stack_.top() = xformation_stack_.top() * xformation;
}

const Matrix& Canvas::GetCurrentTransformation() const {
  return xformation_stack_.top();
}

void Canvas::Translate(const Vector3& offset) {
  Concat(Matrix::MakeTranslation(offset));
}

void Canvas::Scale(const Vector3& scale) {
  Concat(Matrix::MakeScale(scale));
}

void Canvas::Rotate(Radians radians) {
  Concat(Matrix::MakeRotationZ(radians));
}

size_t Canvas::GetSaveCount() const {
  return xformation_stack_.size();
}

void AssertionBreak() {}

void Canvas::DrawPath(Path path, Paint paint) {
  if (path.GetBoundingBox().IsZero()) {
    AssertionBreak();
  }
  Entity entity;
  entity.SetTransformation(GetCurrentTransformation());
  entity.SetPath(std::move(path));
  entity.SetBackgroundColor(paint.color);
  ops_.emplace_back(std::move(entity));
}

void Canvas::SaveLayer(const Paint& paint, std::optional<Rect> bounds) {}

void Canvas::ClipPath(Path path) {
  Entity entity;
  entity.SetTransformation(GetCurrentTransformation());
  entity.SetPath(std::move(path));
  entity.SetIsClip(true);
  ops_.emplace_back(std::move(entity));
}

void Canvas::DrawShadow(Path path, Color color, Scalar elevation) {}

void Canvas::DrawPicture(const Picture& picture) {
  for (const auto& entity : picture.entities) {
    auto new_entity = entity;
    new_entity.SetTransformation(GetCurrentTransformation() *
                                 new_entity.GetTransformation());
    ops_.emplace_back(std::move(new_entity));
  }
}

Picture Canvas::EndRecordingAsPicture() {
  Picture picture;
  picture.entities = std::move(ops_);
  return picture;
}

}  // namespace impeller

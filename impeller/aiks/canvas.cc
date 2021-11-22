// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/canvas.h"

#include <algorithm>

#include "flutter/fml/logging.h"
#include "impeller/geometry/path_builder.h"

namespace impeller {

Canvas::Canvas() {
  Save(true);
}

Canvas::~Canvas() = default;

void Canvas::Save() {
  Save(false);
}

bool Canvas::Restore() {
  FML_DCHECK(xformation_stack_.size() > 0);
  if (xformation_stack_.size() == 1) {
    return false;
  }
  xformation_stack_.pop_back();
  return true;
}

void Canvas::Concat(const Matrix& xformation) {
  xformation_stack_.back().xformation = xformation * GetCurrentTransformation();
}

const Matrix& Canvas::GetCurrentTransformation() const {
  return xformation_stack_.back().xformation;
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

void Canvas::RestoreToCount(size_t count) {
  while (GetSaveCount() > count) {
    if (!Restore()) {
      return;
    }
  }
}

void Canvas::DrawPath(Path path, Paint paint) {
  Entity entity;
  entity.SetTransformation(GetCurrentTransformation());
  entity.SetPath(std::move(path));
  entity.SetStencilDepth(GetStencilDepth());
  entity.SetContents(paint.CreateContentsForEntity());

  GetCurrentPass().PushEntity(std::move(entity));
}

void Canvas::SaveLayer(const Paint& paint, std::optional<Rect> bounds) {
  Save();
}

void Canvas::ClipPath(Path path) {
  IncrementStencilDepth();

  Entity entity;
  entity.SetTransformation(GetCurrentTransformation());
  entity.SetPath(std::move(path));
  entity.SetContents(std::make_shared<ClipContents>());
  entity.SetStencilDepth(GetStencilDepth());

  GetCurrentPass().PushEntity(std::move(entity));
}

void Canvas::DrawShadow(Path path, Color color, Scalar elevation) {}

void Canvas::DrawPicture(const Picture& picture) {
  for (const auto& stack_entry : picture.entries) {
    auto new_stack_entry = stack_entry;
    if (auto pass = new_stack_entry.pass) {
      for (auto entity : pass->GetPassEntities()) {
        entity.IncrementStencilDepth(GetStencilDepth());
        entity.SetTransformation(GetCurrentTransformation() *
                                 entity.GetTransformation());
      }
    }
    xformation_stack_.emplace_back(std::move(new_stack_entry));
  }
}

void Canvas::DrawImage(std::shared_ptr<Image> image,
                       Point offset,
                       Paint paint) {
  if (!image) {
    return;
  }

  const auto source = IRect::MakeSize(image->GetSize());
  const auto dest =
      Rect::MakeXYWH(offset.x, offset.y, source.size.width, source.size.height);

  DrawImageRect(image, source, dest, std::move(paint));
}

void Canvas::DrawImageRect(std::shared_ptr<Image> image,
                           IRect source,
                           Rect dest,
                           Paint paint) {
  if (!image || source.size.IsEmpty() || dest.size.IsEmpty()) {
    return;
  }

  auto size = image->GetSize();

  if (size.IsEmpty()) {
    return;
  }

  auto contents = std::make_shared<TextureContents>();
  contents->SetTexture(image->GetTexture());
  contents->SetSourceRect(source);

  Entity entity;
  entity.SetPath(PathBuilder{}.AddRect(dest).CreatePath());
  entity.SetContents(contents);
  entity.SetTransformation(GetCurrentTransformation());
  GetCurrentPass().PushEntity(std::move(entity));
}

Picture Canvas::EndRecordingAsPicture() {
  Picture picture;
  picture.entries = std::move(xformation_stack_);
  return picture;
}

CanvasPass& Canvas::GetCurrentPass() {
  for (auto i = xformation_stack_.rbegin(), end = xformation_stack_.rend();
       i < end; i++) {
    if (i->pass.has_value()) {
      return i->pass.value();
    }
  }
  FML_UNREACHABLE();
}

void Canvas::IncrementStencilDepth() {
  ++xformation_stack_.back().stencil_depth;
}

size_t Canvas::GetStencilDepth() const {
  return xformation_stack_.back().stencil_depth;
}

void Canvas::DrawRect(Rect rect, Paint paint) {
  DrawPath(PathBuilder{}.AddRect(rect).CreatePath(), std::move(paint));
}

void Canvas::Save(bool create_subpass) {
  // Check if called from the ctor.
  if (xformation_stack_.empty()) {
    FML_DCHECK(create_subpass) << "Base entries must have a pass.";
    CanvasStackEntry entry;
    entry.pass = CanvasPass{};
    xformation_stack_.emplace_back(std::move(entry));
  }

  auto entry = CanvasStackEntry{};

  entry.xformation = xformation_stack_.back().xformation;
  entry.stencil_depth = xformation_stack_.back().stencil_depth;
  if (create_subpass) {
    entry.pass = CanvasPass{};
  }
  xformation_stack_.emplace_back(std::move(entry));
}

}  // namespace impeller

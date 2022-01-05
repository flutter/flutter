// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/canvas.h"

#include <algorithm>

#include "flutter/fml/logging.h"
#include "impeller/aiks/paint_pass_delegate.h"
#include "impeller/geometry/path_builder.h"

namespace impeller {

Canvas::Canvas() {
  Initialize();
}

Canvas::~Canvas() = default;

void Canvas::Initialize() {
  base_pass_ = std::make_unique<EntityPass>();
  current_pass_ = base_pass_.get();
  xformation_stack_.emplace_back(CanvasStackEntry{});
  FML_DCHECK(GetSaveCount() == 1u);
  FML_DCHECK(base_pass_->GetSubpassesDepth() == 1u);
}

void Canvas::Reset() {
  base_pass_ = nullptr;
  current_pass_ = nullptr;
  xformation_stack_ = {};
}

void Canvas::Save() {
  Save(false);
}

bool Canvas::Restore() {
  FML_DCHECK(xformation_stack_.size() > 0);
  if (xformation_stack_.size() == 1) {
    return false;
  }
  if (xformation_stack_.back().is_subpass) {
    current_pass_ = GetCurrentPass().GetSuperpass();
    FML_DCHECK(current_pass_);
  }
  xformation_stack_.pop_back();
  return true;
}

void Canvas::Concat(const Matrix& xformation) {
  xformation_stack_.back().xformation = xformation * GetCurrentTransformation();
}

void Canvas::ResetTransform() {
  xformation_stack_.back().xformation = {};
}

void Canvas::Transform(const Matrix& xformation) {
  Concat(xformation);
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

void Canvas::Skew(Scalar sx, Scalar sy) {
  Concat(Matrix::MakeSkew(sx, sy));
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

  GetCurrentPass().AddEntity(std::move(entity));
}

void Canvas::DrawRect(Rect rect, Paint paint) {
  DrawPath(PathBuilder{}.AddRect(rect).TakePath(), std::move(paint));
}

void Canvas::DrawCircle(Point center, Scalar radius, Paint paint) {
  DrawPath(PathBuilder{}.AddCircle(center, radius).TakePath(),
           std::move(paint));
}

void Canvas::SaveLayer(Paint paint, std::optional<Rect> bounds) {
  GetCurrentPass().SetDelegate(
      std::make_unique<PaintPassDelegate>(std::move(paint), bounds));

  Save(true);

  if (bounds.has_value()) {
    // Render target switches due to a save layer can be elided. In such cases
    // where passes are collapsed into their parent, the clipping effect to
    // the size of the render target that would have been allocated will be
    // absent. Explicitly add back a clip to reproduce that behavior. Since
    // clips never require a render target switch, this is a cheap operation.
    ClipPath(PathBuilder{}.AddRect(bounds.value()).TakePath());
  }
}

void Canvas::ClipPath(Path path) {
  IncrementStencilDepth();

  Entity entity;
  entity.SetTransformation(GetCurrentTransformation());
  entity.SetPath(std::move(path));
  entity.SetContents(std::make_shared<ClipContents>());
  entity.SetStencilDepth(GetStencilDepth());
  entity.SetAddsToCoverage(false);

  GetCurrentPass().AddEntity(std::move(entity));
}

void Canvas::DrawShadow(Path path, Color color, Scalar elevation) {}

void Canvas::DrawPicture(Picture picture) {
  if (!picture.pass) {
    return;
  }
  // Clone the base pass and account for the CTM updates.
  auto pass = picture.pass->Clone();
  pass->IterateAllEntities([&](auto& entity) -> bool {
    entity.IncrementStencilDepth(GetStencilDepth());
    entity.SetTransformation(GetCurrentTransformation() *
                             entity.GetTransformation());
    return true;
  });
  return;
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
  entity.SetPath(PathBuilder{}.AddRect(dest).TakePath());
  entity.SetContents(contents);
  entity.SetTransformation(GetCurrentTransformation());

  GetCurrentPass().AddEntity(std::move(entity));
}

Picture Canvas::EndRecordingAsPicture() {
  Picture picture;
  picture.pass = std::move(base_pass_);

  Reset();
  Initialize();

  return picture;
}

EntityPass& Canvas::GetCurrentPass() {
  FML_DCHECK(current_pass_ != nullptr);
  return *current_pass_;
}

void Canvas::IncrementStencilDepth() {
  ++xformation_stack_.back().stencil_depth;
}

size_t Canvas::GetStencilDepth() const {
  return xformation_stack_.back().stencil_depth;
}

void Canvas::Save(bool create_subpass) {
  auto entry = CanvasStackEntry{};
  if (create_subpass) {
    entry.is_subpass = true;
    current_pass_ = GetCurrentPass().AddSubpass(std::make_unique<EntityPass>());
    current_pass_->SetTransformation(xformation_stack_.back().xformation);
    current_pass_->SetStencilDepth(xformation_stack_.back().stencil_depth);
  } else {
    entry.xformation = xformation_stack_.back().xformation;
    entry.stencil_depth = xformation_stack_.back().stencil_depth;
  }
  xformation_stack_.emplace_back(std::move(entry));
}

}  // namespace impeller

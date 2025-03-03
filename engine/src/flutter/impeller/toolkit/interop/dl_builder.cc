// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/toolkit/interop/dl_builder.h"

#include "impeller/toolkit/interop/formats.h"

namespace impeller::interop {

DisplayListBuilder::DisplayListBuilder(const ImpellerRect* rect)
    : builder_(rect) {}

DisplayListBuilder::~DisplayListBuilder() = default;

void DisplayListBuilder::Save() {
  builder_.Save();
}

void DisplayListBuilder::SaveLayer(const Rect& bounds,
                                   const Paint* paint,
                                   const ImageFilter* backdrop) {
  builder_.SaveLayer(
      bounds,                                           //
      paint == nullptr ? nullptr : &paint->GetPaint(),  //
      backdrop == nullptr ? nullptr : backdrop->GetImageFilter().get());
}

void DisplayListBuilder::Restore() {
  builder_.Restore();
}

void DisplayListBuilder::Scale(Size scale) {
  builder_.Scale(scale.width, scale.height);
}

void DisplayListBuilder::Rotate(Degrees angle) {
  builder_.Rotate(angle.degrees);
}

void DisplayListBuilder::Translate(Point translation) {
  builder_.Translate(translation.x, translation.y);
}

Matrix DisplayListBuilder::GetTransform() const {
  return builder_.GetMatrix();
}

void DisplayListBuilder::SetTransform(const Matrix& matrix) {
  builder_.SetTransform(matrix);
}

void DisplayListBuilder::Transform(const Matrix& matrix) {
  builder_.Transform(matrix);
}

void DisplayListBuilder::ResetTransform() {
  builder_.TransformReset();
}

uint32_t DisplayListBuilder::GetSaveCount() const {
  return builder_.GetSaveCount();
}

void DisplayListBuilder::RestoreToCount(uint32_t count) {
  builder_.RestoreToCount(count);
}

void DisplayListBuilder::ClipRect(const Rect& rect, flutter::DlClipOp op) {
  builder_.ClipRect(rect, op);
}

void DisplayListBuilder::ClipOval(const Rect& rect, flutter::DlClipOp op) {
  builder_.ClipOval(rect, op);
}

void DisplayListBuilder::ClipRoundedRect(const Rect& rect,
                                         const RoundingRadii& radii,
                                         flutter::DlClipOp op) {
  builder_.ClipRoundRect(RoundRect::MakeRectRadii(rect, radii), op);
}

void DisplayListBuilder::ClipPath(const Path& path, flutter::DlClipOp op) {
  builder_.ClipPath(flutter::DlPath(path.GetPath()), op);
}

void DisplayListBuilder::DrawRect(const Rect& rect, const Paint& paint) {
  builder_.DrawRect(rect, paint.GetPaint());
}

void DisplayListBuilder::DrawOval(const Rect& oval_bounds, const Paint& paint) {
  builder_.DrawOval(oval_bounds, paint.GetPaint());
}

void DisplayListBuilder::DrawRoundedRect(const Rect& rect,
                                         const RoundingRadii& radii,
                                         const Paint& paint) {
  builder_.DrawRoundRect(RoundRect::MakeRectRadii(rect, radii),
                         paint.GetPaint());
}

void DisplayListBuilder::DrawRoundedRectDifference(
    const Rect& outer_rect,
    const RoundingRadii& outer_radii,
    const Rect& inner_rect,
    const RoundingRadii& inner_radii,
    const Paint& paint) {
  builder_.DrawDiffRoundRect(
      RoundRect::MakeRectRadii(outer_rect, outer_radii),  //
      RoundRect::MakeRectRadii(inner_rect, inner_radii),  //
      paint.GetPaint()                                    //
  );
}

void DisplayListBuilder::DrawPath(const Path& path, const Paint& paint) {
  builder_.DrawPath(flutter::DlPath(path.GetPath()), paint.GetPaint());
}

void DisplayListBuilder::DrawPaint(const Paint& paint) {
  builder_.DrawPaint(paint.GetPaint());
}

void DisplayListBuilder::DrawLine(const Point& from,
                                  const Point& to,
                                  const Paint& paint) {
  builder_.DrawLine(from, to, paint.GetPaint());
}

void DisplayListBuilder::DrawDashedLine(const Point& from,
                                        const Point& to,
                                        Scalar on_length,
                                        Scalar off_length,
                                        const Paint& paint) {
  builder_.DrawDashedLine(from,             //
                          to,               //
                          on_length,        //
                          off_length,       //
                          paint.GetPaint()  //
  );
}

ScopedObject<DisplayList> DisplayListBuilder::Build() {
  return Create<DisplayList>(builder_.Build());
}

void DisplayListBuilder::DrawDisplayList(const DisplayList& dl,
                                         Scalar opacity) {
  builder_.DrawDisplayList(dl.GetDisplayList(), opacity);
}

void DisplayListBuilder::DrawTexture(const Texture& texture,
                                     const Point& point,
                                     flutter::DlImageSampling sampling,
                                     const Paint* paint) {
  builder_.DrawImage(texture.MakeImage(),                             //
                     point,                                           //
                     sampling,                                        //
                     paint == nullptr ? nullptr : &paint->GetPaint()  //
  );
}

void DisplayListBuilder::DrawTextureRect(const Texture& texture,
                                         const Rect& src_rect,
                                         const Rect& dst_rect,
                                         flutter::DlImageSampling sampling,
                                         const Paint* paint) {
  builder_.DrawImageRect(texture.MakeImage(),                             //
                         src_rect,                                        //
                         dst_rect,                                        //
                         sampling,                                        //
                         paint == nullptr ? nullptr : &paint->GetPaint()  //
  );
}

void DisplayListBuilder::DrawParagraph(const Paragraph& paragraph,
                                       Point point) {
  const auto& handle = paragraph.GetHandle();
  if (!handle) {
    return;
  }
  handle->Paint(&builder_, point.x, point.y);
}

}  // namespace impeller::interop

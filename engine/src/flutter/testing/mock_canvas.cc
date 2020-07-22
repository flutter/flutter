// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// FLUTTER_NOLINT

#include "flutter/testing/mock_canvas.h"

#include "flutter/fml/logging.h"
#include "third_party/skia/include/core/SkImageInfo.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkSerialProcs.h"
#include "third_party/skia/include/core/SkSize.h"
#include "third_party/skia/include/core/SkTextBlob.h"

namespace flutter {
namespace testing {

constexpr SkISize kSize = SkISize::Make(64, 64);

MockCanvas::MockCanvas()
    : SkCanvasVirtualEnforcer<SkCanvas>(kSize.fWidth, kSize.fHeight),
      internal_canvas_(imageInfo().width(), imageInfo().height()),
      current_layer_(0) {
  internal_canvas_.addCanvas(this);
}

MockCanvas::~MockCanvas() {
  EXPECT_EQ(current_layer_, 0);
}

void MockCanvas::willSave() {
  draw_calls_.emplace_back(
      DrawCall{current_layer_, SaveData{current_layer_ + 1}});
  current_layer_++;  // Must go here; func params order of eval is undefined
}

SkCanvas::SaveLayerStrategy MockCanvas::getSaveLayerStrategy(
    const SaveLayerRec& rec) {
  // saveLayer calls this prior to running, so we use it to track saveLayer
  // calls
  draw_calls_.emplace_back(DrawCall{
      current_layer_,
      SaveLayerData{rec.fBounds ? *rec.fBounds : SkRect(),
                    rec.fPaint ? *rec.fPaint : SkPaint(),
                    rec.fBackdrop ? sk_ref_sp<SkImageFilter>(rec.fBackdrop)
                                  : sk_sp<SkImageFilter>(),
                    current_layer_ + 1}});
  current_layer_++;  // Must go here; func params order of eval is undefined
  return kNoLayer_SaveLayerStrategy;
}

void MockCanvas::willRestore() {
  FML_DCHECK(current_layer_ > 0);

  draw_calls_.emplace_back(
      DrawCall{current_layer_, RestoreData{current_layer_ - 1}});
  current_layer_--;  // Must go here; func params order of eval is undefined
}

void MockCanvas::didConcat(const SkMatrix& matrix) {
  draw_calls_.emplace_back(DrawCall{current_layer_, ConcatMatrixData{matrix}});
}

void MockCanvas::didConcat44(const SkM44& matrix) {
  draw_calls_.emplace_back(
      DrawCall{current_layer_, ConcatMatrix44Data{matrix}});
}

void MockCanvas::didScale(SkScalar x, SkScalar y) {
  SkMatrix m;
  m.setScale(x, y);
  this->didConcat(m);
}

void MockCanvas::didTranslate(SkScalar x, SkScalar y) {
  SkMatrix m;
  m.setTranslate(x, y);
  this->didConcat(m);
}

void MockCanvas::didSetMatrix(const SkMatrix& matrix) {
  draw_calls_.emplace_back(DrawCall{current_layer_, SetMatrixData{matrix}});
}

void MockCanvas::onDrawTextBlob(const SkTextBlob* text,
                                SkScalar x,
                                SkScalar y,
                                const SkPaint& paint) {
  // This duplicates existing logic in SkCanvas::onDrawPicture
  // that should probably be split out so it doesn't need to be here as well.
  SkRect storage;
  const SkRect* bounds = nullptr;
  if (paint.canComputeFastBounds()) {
    storage = text->bounds().makeOffset(x, y);
    SkRect tmp;
    if (this->quickReject(paint.computeFastBounds(storage, &tmp))) {
      return;
    }
    bounds = &storage;
  }

  draw_calls_.emplace_back(DrawCall{
      current_layer_, DrawTextData{text ? text->serialize(SkSerialProcs{})
                                        : SkData::MakeUninitialized(0),
                                   paint, SkPoint::Make(x, y)}});
}

void MockCanvas::onDrawRect(const SkRect& rect, const SkPaint& paint) {
  draw_calls_.emplace_back(DrawCall{current_layer_, DrawRectData{rect, paint}});
}

void MockCanvas::onDrawPath(const SkPath& path, const SkPaint& paint) {
  draw_calls_.emplace_back(DrawCall{current_layer_, DrawPathData{path, paint}});
}

void MockCanvas::onDrawShadowRec(const SkPath& path,
                                 const SkDrawShadowRec& rec) {
  (void)rec;  // Can't use b/c Skia keeps this type anonymous.
  draw_calls_.emplace_back(DrawCall{current_layer_, DrawShadowData{path}});
}

void MockCanvas::onDrawPicture(const SkPicture* picture,
                               const SkMatrix* matrix,
                               const SkPaint* paint) {
  // This duplicates existing logic in SkCanvas::onDrawPicture
  // that should probably be split out so it doesn't need to be here as well.
  if (!paint || paint->canComputeFastBounds()) {
    SkRect bounds = picture->cullRect();
    if (paint) {
      paint->computeFastBounds(bounds, &bounds);
    }
    if (matrix) {
      matrix->mapRect(&bounds);
    }
    if (this->quickReject(bounds)) {
      return;
    }
  }

  draw_calls_.emplace_back(DrawCall{
      current_layer_,
      DrawPictureData{
          picture ? picture->serialize() : SkData::MakeUninitialized(0),
          paint ? *paint : SkPaint(), matrix ? *matrix : SkMatrix()}});
}

void MockCanvas::onClipRect(const SkRect& rect,
                            SkClipOp op,
                            ClipEdgeStyle style) {
  draw_calls_.emplace_back(
      DrawCall{current_layer_, ClipRectData{rect, op, style}});
}

void MockCanvas::onClipRRect(const SkRRect& rrect,
                             SkClipOp op,
                             ClipEdgeStyle style) {
  draw_calls_.emplace_back(
      DrawCall{current_layer_, ClipRRectData{rrect, op, style}});
}

void MockCanvas::onClipPath(const SkPath& path,
                            SkClipOp op,
                            ClipEdgeStyle style) {
  draw_calls_.emplace_back(
      DrawCall{current_layer_, ClipPathData{path, op, style}});
}

bool MockCanvas::onDoSaveBehind(const SkRect*) {
  FML_DCHECK(false);
  return false;
}

void MockCanvas::onDrawAnnotation(const SkRect&, const char[], SkData*) {
  FML_DCHECK(false);
}

void MockCanvas::onDrawDRRect(const SkRRect&, const SkRRect&, const SkPaint&) {
  FML_DCHECK(false);
}

void MockCanvas::onDrawDrawable(SkDrawable*, const SkMatrix*) {
  FML_DCHECK(false);
}

void MockCanvas::onDrawPatch(const SkPoint[12],
                             const SkColor[4],
                             const SkPoint[4],
                             SkBlendMode,
                             const SkPaint&) {
  FML_DCHECK(false);
}

void MockCanvas::onDrawPaint(const SkPaint&) {
  FML_DCHECK(false);
}

void MockCanvas::onDrawBehind(const SkPaint&) {
  FML_DCHECK(false);
}

void MockCanvas::onDrawPoints(PointMode,
                              size_t,
                              const SkPoint[],
                              const SkPaint&) {
  FML_DCHECK(false);
}

void MockCanvas::onDrawRegion(const SkRegion&, const SkPaint&) {
  FML_DCHECK(false);
}

void MockCanvas::onDrawOval(const SkRect&, const SkPaint&) {
  FML_DCHECK(false);
}

void MockCanvas::onDrawArc(const SkRect&,
                           SkScalar,
                           SkScalar,
                           bool,
                           const SkPaint&) {
  FML_DCHECK(false);
}

void MockCanvas::onDrawRRect(const SkRRect&, const SkPaint&) {
  FML_DCHECK(false);
}

void MockCanvas::onDrawImage(const SkImage*,
                             SkScalar,
                             SkScalar,
                             const SkPaint*) {
  FML_DCHECK(false);
}

void MockCanvas::onDrawImageRect(const SkImage*,
                                 const SkRect*,
                                 const SkRect&,
                                 const SkPaint*,
                                 SrcRectConstraint) {
  FML_DCHECK(false);
}

void MockCanvas::onDrawImageNine(const SkImage*,
                                 const SkIRect&,
                                 const SkRect&,
                                 const SkPaint*) {
  FML_DCHECK(false);
}

void MockCanvas::onDrawImageLattice(const SkImage*,
                                    const Lattice&,
                                    const SkRect&,
                                    const SkPaint*) {
  FML_DCHECK(false);
}

void MockCanvas::onDrawVerticesObject(const SkVertices*,
                                      SkBlendMode,
                                      const SkPaint&) {
  FML_DCHECK(false);
}

void MockCanvas::onDrawAtlas(const SkImage*,
                             const SkRSXform[],
                             const SkRect[],
                             const SkColor[],
                             int,
                             SkBlendMode,
                             const SkRect*,
                             const SkPaint*) {
  FML_DCHECK(false);
}

void MockCanvas::onDrawEdgeAAQuad(const SkRect&,
                                  const SkPoint[4],
                                  QuadAAFlags,
                                  const SkColor4f&,
                                  SkBlendMode) {
  FML_DCHECK(false);
}

void MockCanvas::onDrawEdgeAAImageSet(const ImageSetEntry[],
                                      int,
                                      const SkPoint[],
                                      const SkMatrix[],
                                      const SkPaint*,
                                      SrcRectConstraint) {
  FML_DCHECK(false);
}

void MockCanvas::onClipRegion(const SkRegion&, SkClipOp) {
  FML_DCHECK(false);
}

bool operator==(const MockCanvas::SaveData& a, const MockCanvas::SaveData& b) {
  return a.save_to_layer == b.save_to_layer;
}

std::ostream& operator<<(std::ostream& os, const MockCanvas::SaveData& data) {
  return os << data.save_to_layer;
}

bool operator==(const MockCanvas::SaveLayerData& a,
                const MockCanvas::SaveLayerData& b) {
  return a.save_bounds == b.save_bounds && a.restore_paint == b.restore_paint &&
         a.backdrop_filter == b.backdrop_filter &&
         a.save_to_layer == b.save_to_layer;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::SaveLayerData& data) {
  return os << data.save_bounds << " " << data.restore_paint << " "
            << data.backdrop_filter << " " << data.save_to_layer;
}

bool operator==(const MockCanvas::RestoreData& a,
                const MockCanvas::RestoreData& b) {
  return a.restore_to_layer == b.restore_to_layer;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::RestoreData& data) {
  return os << data.restore_to_layer;
}

bool operator==(const MockCanvas::ConcatMatrixData& a,
                const MockCanvas::ConcatMatrixData& b) {
  return a.matrix == b.matrix;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::ConcatMatrixData& data) {
  return os << data.matrix;
}

bool operator==(const MockCanvas::ConcatMatrix44Data& a,
                const MockCanvas::ConcatMatrix44Data& b) {
  return a.matrix == b.matrix;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::ConcatMatrix44Data& data) {
  return os << data.matrix;
}

bool operator==(const MockCanvas::SetMatrixData& a,
                const MockCanvas::SetMatrixData& b) {
  return a.matrix == b.matrix;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::SetMatrixData& data) {
  return os << data.matrix;
}

bool operator==(const MockCanvas::DrawRectData& a,
                const MockCanvas::DrawRectData& b) {
  return a.rect == b.rect && a.paint == b.paint;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::DrawRectData& data) {
  return os << data.rect << " " << data.paint;
}

bool operator==(const MockCanvas::DrawPathData& a,
                const MockCanvas::DrawPathData& b) {
  return a.path == b.path && a.paint == b.paint;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::DrawPathData& data) {
  return os << data.path << " " << data.paint;
}

bool operator==(const MockCanvas::DrawTextData& a,
                const MockCanvas::DrawTextData& b) {
  return a.serialized_text->equals(b.serialized_text.get()) &&
         a.paint == b.paint && a.offset == b.offset;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::DrawTextData& data) {
  return os << data.serialized_text << " " << data.paint << " " << data.offset;
}

bool operator==(const MockCanvas::DrawPictureData& a,
                const MockCanvas::DrawPictureData& b) {
  return a.serialized_picture->equals(b.serialized_picture.get()) &&
         a.paint == b.paint && a.matrix == b.matrix;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::DrawPictureData& data) {
  return os << data.serialized_picture << " " << data.paint << " "
            << data.matrix;
}

bool operator==(const MockCanvas::DrawShadowData& a,
                const MockCanvas::DrawShadowData& b) {
  return a.path == b.path;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::DrawShadowData& data) {
  return os << data.path;
}

bool operator==(const MockCanvas::ClipRectData& a,
                const MockCanvas::ClipRectData& b) {
  return a.rect == b.rect && a.clip_op == b.clip_op && a.style == b.style;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::ClipRectData& data) {
  return os << data.rect << " " << data.clip_op << " " << data.style;
}

bool operator==(const MockCanvas::ClipRRectData& a,
                const MockCanvas::ClipRRectData& b) {
  return a.rrect == b.rrect && a.clip_op == b.clip_op && a.style == b.style;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::ClipRRectData& data) {
  return os << data.rrect << " " << data.clip_op << " " << data.style;
}

bool operator==(const MockCanvas::ClipPathData& a,
                const MockCanvas::ClipPathData& b) {
  return a.path == b.path && a.clip_op == b.clip_op && a.style == b.style;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::ClipPathData& data) {
  return os << data.path << " " << data.clip_op << " " << data.style;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::DrawCallData& data) {
  std::visit([&os](auto& d) { os << d; }, data);
  return os;
}

bool operator==(const MockCanvas::DrawCall& a, const MockCanvas::DrawCall& b) {
  return a.layer == b.layer && a.data == b.data;
}

std::ostream& operator<<(std::ostream& os, const MockCanvas::DrawCall& draw) {
  return os << "[Layer: " << draw.layer << ", Data: " << draw.data << "]";
}

}  // namespace testing
}  // namespace flutter

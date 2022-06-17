// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_canvas_recorder.h"

#include "flutter/display_list/display_list_blend_mode.h"
#include "flutter/display_list/display_list_builder.h"
#include "flutter/display_list/display_list_image_filter.h"

namespace flutter {

DisplayListCanvasRecorder::DisplayListCanvasRecorder(const SkRect& bounds)
    : SkCanvasVirtualEnforcer(bounds.width(), bounds.height()),
      builder_(sk_make_sp<DisplayListBuilder>(bounds)) {}

sk_sp<DisplayList> DisplayListCanvasRecorder::Build() {
  sk_sp<DisplayList> display_list = builder_->Build();
  builder_.reset();
  return display_list;
}

// clang-format off
void DisplayListCanvasRecorder::didConcat44(const SkM44& m44) {
  builder_->transform(m44);
}
// clang-format on
void DisplayListCanvasRecorder::didSetM44(const SkM44& matrix) {
  builder_->transformReset();
  builder_->transform(matrix);
}
void DisplayListCanvasRecorder::didTranslate(SkScalar tx, SkScalar ty) {
  builder_->translate(tx, ty);
}
void DisplayListCanvasRecorder::didScale(SkScalar sx, SkScalar sy) {
  builder_->scale(sx, sy);
}

void DisplayListCanvasRecorder::onClipRect(const SkRect& rect,
                                           SkClipOp clip_op,
                                           ClipEdgeStyle edge_style) {
  builder_->clipRect(rect, clip_op,
                     edge_style == ClipEdgeStyle::kSoft_ClipEdgeStyle);
}
void DisplayListCanvasRecorder::onClipRRect(const SkRRect& rrect,
                                            SkClipOp clip_op,
                                            ClipEdgeStyle edge_style) {
  builder_->clipRRect(rrect, clip_op,
                      edge_style == ClipEdgeStyle::kSoft_ClipEdgeStyle);
}
void DisplayListCanvasRecorder::onClipPath(const SkPath& path,
                                           SkClipOp clip_op,
                                           ClipEdgeStyle edge_style) {
  builder_->clipPath(path, clip_op,
                     edge_style == ClipEdgeStyle::kSoft_ClipEdgeStyle);
}

void DisplayListCanvasRecorder::willSave() {
  builder_->save();
}
SkCanvas::SaveLayerStrategy DisplayListCanvasRecorder::getSaveLayerStrategy(
    const SaveLayerRec& rec) {
  std::shared_ptr<DlImageFilter> backdrop = DlImageFilter::From(rec.fBackdrop);
  if (rec.fPaint) {
    builder_->setAttributesFromPaint(*rec.fPaint, kSaveLayerWithPaintFlags);
    builder_->saveLayer(rec.fBounds, SaveLayerOptions::kWithAttributes,
                        backdrop.get());
  } else {
    builder_->saveLayer(rec.fBounds, SaveLayerOptions::kNoAttributes,
                        backdrop.get());
  }
  return SaveLayerStrategy::kNoLayer_SaveLayerStrategy;
}
void DisplayListCanvasRecorder::didRestore() {
  builder_->restore();
}

void DisplayListCanvasRecorder::onDrawPaint(const SkPaint& paint) {
  builder_->setAttributesFromPaint(paint, kDrawPaintFlags);
  builder_->drawPaint();
}
void DisplayListCanvasRecorder::onDrawRect(const SkRect& rect,
                                           const SkPaint& paint) {
  builder_->setAttributesFromPaint(paint, kDrawRectFlags);
  builder_->drawRect(rect);
}
void DisplayListCanvasRecorder::onDrawRRect(const SkRRect& rrect,
                                            const SkPaint& paint) {
  builder_->setAttributesFromPaint(paint, kDrawRRectFlags);
  builder_->drawRRect(rrect);
}
void DisplayListCanvasRecorder::onDrawDRRect(const SkRRect& outer,
                                             const SkRRect& inner,
                                             const SkPaint& paint) {
  builder_->setAttributesFromPaint(paint, kDrawDRRectFlags);
  builder_->drawDRRect(outer, inner);
}
void DisplayListCanvasRecorder::onDrawOval(const SkRect& rect,
                                           const SkPaint& paint) {
  builder_->setAttributesFromPaint(paint, kDrawOvalFlags);
  builder_->drawOval(rect);
}
void DisplayListCanvasRecorder::onDrawArc(const SkRect& rect,
                                          SkScalar startAngle,
                                          SkScalar sweepAngle,
                                          bool useCenter,
                                          const SkPaint& paint) {
  builder_->setAttributesFromPaint(paint,
                                   useCenter  //
                                       ? kDrawArcWithCenterFlags
                                       : kDrawArcNoCenterFlags);
  builder_->drawArc(rect, startAngle, sweepAngle, useCenter);
}
void DisplayListCanvasRecorder::onDrawPath(const SkPath& path,
                                           const SkPaint& paint) {
  builder_->setAttributesFromPaint(paint, kDrawPathFlags);
  builder_->drawPath(path);
}

void DisplayListCanvasRecorder::onDrawPoints(SkCanvas::PointMode mode,
                                             size_t count,
                                             const SkPoint pts[],
                                             const SkPaint& paint) {
  switch (mode) {
    case SkCanvas::kPoints_PointMode:
      builder_->setAttributesFromPaint(paint, kDrawPointsAsPointsFlags);
      break;
    case SkCanvas::kLines_PointMode:
      builder_->setAttributesFromPaint(paint, kDrawPointsAsLinesFlags);
      break;
    case SkCanvas::kPolygon_PointMode:
      builder_->setAttributesFromPaint(paint, kDrawPointsAsPolygonFlags);
      break;
  }
  if (mode == SkCanvas::PointMode::kLines_PointMode && count == 2) {
    builder_->drawLine(pts[0], pts[1]);
  } else {
    uint32_t count32 = static_cast<uint32_t>(count);
    // TODO(flar): depending on the mode we could break it down into
    // multiple calls to drawPoints, but how much do we really want
    // to support more than a couple billion points?
    FML_DCHECK(count32 == count);
    builder_->drawPoints(mode, count32, pts);
  }
}
void DisplayListCanvasRecorder::onDrawVerticesObject(const SkVertices* vertices,
                                                     SkBlendMode mode,
                                                     const SkPaint& paint) {
  builder_->setAttributesFromPaint(paint, kDrawVerticesFlags);
  builder_->drawSkVertices(sk_ref_sp(vertices), mode);
}

void DisplayListCanvasRecorder::onDrawImage2(const SkImage* image,
                                             SkScalar dx,
                                             SkScalar dy,
                                             const SkSamplingOptions& sampling,
                                             const SkPaint* paint) {
  if (paint != nullptr) {
    builder_->setAttributesFromPaint(*paint, kDrawImageWithPaintFlags);
  }
  builder_->drawImage(DlImage::Make(image), SkPoint::Make(dx, dy),
                      ToDl(sampling), paint != nullptr);
}
void DisplayListCanvasRecorder::onDrawImageRect2(
    const SkImage* image,
    const SkRect& src,
    const SkRect& dst,
    const SkSamplingOptions& sampling,
    const SkPaint* paint,
    SrcRectConstraint constraint) {
  if (paint != nullptr) {
    builder_->setAttributesFromPaint(*paint, kDrawImageRectWithPaintFlags);
  }
  builder_->drawImageRect(DlImage::Make(image), src, dst, ToDl(sampling),
                          paint != nullptr, constraint);
}
void DisplayListCanvasRecorder::onDrawImageLattice2(const SkImage* image,
                                                    const Lattice& lattice,
                                                    const SkRect& dst,
                                                    SkFilterMode filter,
                                                    const SkPaint* paint) {
  if (paint != nullptr) {
    // SkCanvas will always construct a paint,
    // though it is a default paint most of the time
    SkPaint default_paint;
    if (*paint == default_paint) {
      paint = nullptr;
    } else {
      builder_->setAttributesFromPaint(*paint, kDrawImageLatticeWithPaintFlags);
    }
  }
  builder_->drawImageLattice(DlImage::Make(image), lattice, dst, ToDl(filter),
                             paint != nullptr);
}
void DisplayListCanvasRecorder::onDrawAtlas2(const SkImage* image,
                                             const SkRSXform xform[],
                                             const SkRect src[],
                                             const SkColor colors[],
                                             int count,
                                             SkBlendMode mode,
                                             const SkSamplingOptions& sampling,
                                             const SkRect* cull,
                                             const SkPaint* paint) {
  if (paint != nullptr) {
    builder_->setAttributesFromPaint(*paint, kDrawAtlasWithPaintFlags);
  }
  const DlColor* dl_colors = reinterpret_cast<const DlColor*>(colors);
  builder_->drawAtlas(DlImage::Make(image), xform, src, dl_colors, count,
                      ToDl(mode), ToDl(sampling), cull, paint != nullptr);
}

void DisplayListCanvasRecorder::onDrawTextBlob(const SkTextBlob* blob,
                                               SkScalar x,
                                               SkScalar y,
                                               const SkPaint& paint) {
  builder_->setAttributesFromPaint(paint, kDrawTextBlobFlags);
  builder_->drawTextBlob(sk_ref_sp(blob), x, y);
}

void DisplayListCanvasRecorder::onDrawPicture(const SkPicture* picture,
                                              const SkMatrix* matrix,
                                              const SkPaint* paint) {
  if (paint != nullptr) {
    builder_->setAttributesFromPaint(*paint, kDrawPictureWithPaintFlags);
  }
  builder_->drawPicture(sk_ref_sp(picture), matrix, paint != nullptr);
}

void DisplayListCanvasRecorder::onDrawShadowRec(const SkPath& path,
                                                const SkDrawShadowRec& rec) {
  // Skia does not expose the SkDrawShadowRec structure in a public
  // header file so we cannot record this operation.
  // See: https://bugs.chromium.org/p/skia/issues/detail?id=12125
  FML_DLOG(ERROR) << "Unimplemented DisplayListCanvasRecorder::"
                  << __FUNCTION__;
}

void DisplayListCanvasRecorder::onDrawBehind(const SkPaint&) {
  FML_DLOG(ERROR) << "Unimplemented DisplayListCanvasRecorder::"
                  << __FUNCTION__;
}

void DisplayListCanvasRecorder::onDrawRegion(const SkRegion& region,
                                             const SkPaint& paint) {
  FML_DLOG(ERROR) << "Unimplemented DisplayListCanvasRecorder::"
                  << __FUNCTION__;
}

void DisplayListCanvasRecorder::onDrawPatch(const SkPoint cubics[12],
                                            const SkColor colors[4],
                                            const SkPoint texCoords[4],
                                            SkBlendMode mode,
                                            const SkPaint& paint) {
  FML_DLOG(ERROR) << "Unimplemented DisplayListCanvasRecorder::"
                  << __FUNCTION__;
}

void DisplayListCanvasRecorder::onDrawEdgeAAQuad(const SkRect& rect,
                                                 const SkPoint clip[4],
                                                 SkCanvas::QuadAAFlags aaFlags,
                                                 const SkColor4f& color,
                                                 SkBlendMode mode) {
  FML_DLOG(ERROR) << "Unimplemented DisplayListCanvasRecorder::"
                  << __FUNCTION__;
}

void DisplayListCanvasRecorder::onDrawAnnotation(const SkRect& rect,
                                                 const char key[],
                                                 SkData* value) {
  FML_DLOG(ERROR) << "Unimplemented DisplayListCanvasRecorder::"
                  << __FUNCTION__;
}

void DisplayListCanvasRecorder::onDrawDrawable(SkDrawable* drawable,
                                               const SkMatrix* matrix) {
  FML_DLOG(ERROR) << "Unimplemented DisplayListCanvasRecorder::"
                  << __FUNCTION__;
}

}  // namespace flutter

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_DISPLAY_LIST_CANVAS_H_
#define FLUTTER_FLOW_DISPLAY_LIST_CANVAS_H_

#include "flutter/flow/display_list.h"
#include "flutter/flow/display_list_utils.h"
#include "flutter/fml/logging.h"

#include "third_party/skia/include/core/SkCanvasVirtualEnforcer.h"
#include "third_party/skia/include/utils/SkNoDrawCanvas.h"

// Classes to interact between SkCanvas and DisplayList, including:
// DisplayListCanvasDispatcher:
//     Can be fed to the dispatch() method of a DisplayList to feed
//     the resulting rendering operations to an SkCanvas instance.
// DisplayListCanvasRecorder
//     An adapter that implements an SkCanvas interface which can
//     then be handed to code that outputs to an SkCanvas to capture
//     the output into a Flutter DisplayList.

namespace flutter {

// Receives all methods on Dispatcher and sends them to an SkCanvas
class DisplayListCanvasDispatcher : public virtual Dispatcher,
                                    public SkPaintDispatchHelper {
 public:
  DisplayListCanvasDispatcher(SkCanvas* canvas) : canvas_(canvas) {}

  void save() override;
  void restore() override;
  void saveLayer(const SkRect* bounds, bool restore_with_paint) override;

  void translate(SkScalar tx, SkScalar ty) override;
  void scale(SkScalar sx, SkScalar sy) override;
  void rotate(SkScalar degrees) override;
  void skew(SkScalar sx, SkScalar sy) override;
  // clang-format off
  // 2x3 2D affine subset of a 4x4 transform in row major order
  void transform2DAffine(SkScalar mxx, SkScalar mxy, SkScalar mxt,
                         SkScalar myx, SkScalar myy, SkScalar myt) override;
  // full 4x4 transform in row major order
  void transformFullPerspective(
      SkScalar mxx, SkScalar mxy, SkScalar mxz, SkScalar mxt,
      SkScalar myx, SkScalar myy, SkScalar myz, SkScalar myt,
      SkScalar mzx, SkScalar mzy, SkScalar mzz, SkScalar mzt,
      SkScalar mwx, SkScalar mwy, SkScalar mwz, SkScalar mwt) override;
  // clang-format on

  void clipRect(const SkRect& rect, SkClipOp clip_op, bool is_aa) override;
  void clipRRect(const SkRRect& rrect, SkClipOp clip_op, bool is_aa) override;
  void clipPath(const SkPath& path, SkClipOp clip_op, bool is_aa) override;

  void drawPaint() override;
  void drawColor(SkColor color, SkBlendMode mode) override;
  void drawLine(const SkPoint& p0, const SkPoint& p1) override;
  void drawRect(const SkRect& rect) override;
  void drawOval(const SkRect& bounds) override;
  void drawCircle(const SkPoint& center, SkScalar radius) override;
  void drawRRect(const SkRRect& rrect) override;
  void drawDRRect(const SkRRect& outer, const SkRRect& inner) override;
  void drawPath(const SkPath& path) override;
  void drawArc(const SkRect& bounds,
               SkScalar start,
               SkScalar sweep,
               bool useCenter) override;
  void drawPoints(SkCanvas::PointMode mode,
                  uint32_t count,
                  const SkPoint pts[]) override;
  void drawVertices(const sk_sp<SkVertices> vertices,
                    SkBlendMode mode) override;
  void drawImage(const sk_sp<SkImage> image,
                 const SkPoint point,
                 const SkSamplingOptions& sampling,
                 bool render_with_attributes) override;
  void drawImageRect(const sk_sp<SkImage> image,
                     const SkRect& src,
                     const SkRect& dst,
                     const SkSamplingOptions& sampling,
                     bool render_with_attributes,
                     SkCanvas::SrcRectConstraint constraint) override;
  void drawImageNine(const sk_sp<SkImage> image,
                     const SkIRect& center,
                     const SkRect& dst,
                     SkFilterMode filter,
                     bool render_with_attributes) override;
  void drawImageLattice(const sk_sp<SkImage> image,
                        const SkCanvas::Lattice& lattice,
                        const SkRect& dst,
                        SkFilterMode filter,
                        bool render_with_attributes) override;
  void drawAtlas(const sk_sp<SkImage> atlas,
                 const SkRSXform xform[],
                 const SkRect tex[],
                 const SkColor colors[],
                 int count,
                 SkBlendMode mode,
                 const SkSamplingOptions& sampling,
                 const SkRect* cullRect,
                 bool render_with_attributes) override;
  void drawPicture(const sk_sp<SkPicture> picture,
                   const SkMatrix* matrix,
                   bool render_with_attributes) override;
  void drawDisplayList(const sk_sp<DisplayList> display_list) override;
  void drawTextBlob(const sk_sp<SkTextBlob> blob,
                    SkScalar x,
                    SkScalar y) override;
  void drawShadow(const SkPath& path,
                  const SkColor color,
                  const SkScalar elevation,
                  bool transparent_occluder,
                  SkScalar dpr) override;

 private:
  SkCanvas* canvas_;
};

// Receives all methods on SkCanvas and sends them to a DisplayListBuilder
class DisplayListCanvasRecorder
    : public SkCanvasVirtualEnforcer<SkNoDrawCanvas>,
      public SkRefCnt,
      DisplayListOpFlags {
 public:
  DisplayListCanvasRecorder(const SkRect& bounds);

  const sk_sp<DisplayListBuilder> builder() { return builder_; }

  sk_sp<DisplayList> Build();

  void didConcat44(const SkM44&) override;
  void didSetM44(const SkM44&) override { FML_DCHECK(false); }
  void didTranslate(SkScalar, SkScalar) override;
  void didScale(SkScalar, SkScalar) override;

  void onClipRect(const SkRect& rect,
                  SkClipOp op,
                  ClipEdgeStyle edgeStyle) override;
  void onClipRRect(const SkRRect& rrect,
                   SkClipOp op,
                   ClipEdgeStyle edgeStyle) override;
  void onClipPath(const SkPath& path,
                  SkClipOp op,
                  ClipEdgeStyle edgeStyle) override;

  void willSave() override;
  SaveLayerStrategy getSaveLayerStrategy(const SaveLayerRec&) override;
  void didRestore() override;

  void onDrawPaint(const SkPaint& paint) override;
  void onDrawBehind(const SkPaint&) override { FML_DCHECK(false); }
  void onDrawRect(const SkRect& rect, const SkPaint& paint) override;
  void onDrawRRect(const SkRRect& rrect, const SkPaint& paint) override;
  void onDrawDRRect(const SkRRect& outer,
                    const SkRRect& inner,
                    const SkPaint& paint) override;
  void onDrawOval(const SkRect& rect, const SkPaint& paint) override;
  void onDrawArc(const SkRect& rect,
                 SkScalar startAngle,
                 SkScalar sweepAngle,
                 bool useCenter,
                 const SkPaint& paint) override;
  void onDrawPath(const SkPath& path, const SkPaint& paint) override;
  void onDrawRegion(const SkRegion& region, const SkPaint& paint) override {
    FML_DCHECK(false);
  }

  void onDrawTextBlob(const SkTextBlob* blob,
                      SkScalar x,
                      SkScalar y,
                      const SkPaint& paint) override;

  void onDrawPatch(const SkPoint cubics[12],
                   const SkColor colors[4],
                   const SkPoint texCoords[4],
                   SkBlendMode mode,
                   const SkPaint& paint) override {
    FML_DCHECK(false);
  }
  void onDrawPoints(SkCanvas::PointMode mode,
                    size_t count,
                    const SkPoint pts[],
                    const SkPaint& paint) override;
  void onDrawVerticesObject(const SkVertices* vertices,
                            SkBlendMode mode,
                            const SkPaint& paint) override;

  void onDrawImage2(const SkImage*,
                    SkScalar dx,
                    SkScalar dy,
                    const SkSamplingOptions&,
                    const SkPaint*) override;
  void onDrawImageRect2(const SkImage*,
                        const SkRect& src,
                        const SkRect& dst,
                        const SkSamplingOptions&,
                        const SkPaint*,
                        SrcRectConstraint) override;
  void onDrawImageLattice2(const SkImage*,
                           const Lattice&,
                           const SkRect& dst,
                           SkFilterMode,
                           const SkPaint*) override;
  void onDrawAtlas2(const SkImage*,
                    const SkRSXform[],
                    const SkRect src[],
                    const SkColor[],
                    int count,
                    SkBlendMode,
                    const SkSamplingOptions&,
                    const SkRect* cull,
                    const SkPaint*) override;

  void onDrawEdgeAAQuad(const SkRect& rect,
                        const SkPoint clip[4],
                        SkCanvas::QuadAAFlags aaFlags,
                        const SkColor4f& color,
                        SkBlendMode mode) override {
    FML_DCHECK(0);
  }

  void onDrawAnnotation(const SkRect& rect,
                        const char key[],
                        SkData* value) override {
    FML_DCHECK(false);
  }
  void onDrawShadowRec(const SkPath&, const SkDrawShadowRec&) override;

  void onDrawDrawable(SkDrawable* drawable, const SkMatrix* matrix) override {
    FML_DCHECK(false);
  }
  void onDrawPicture(const SkPicture* picture,
                     const SkMatrix* matrix,
                     const SkPaint* paint) override;

 private:
  sk_sp<DisplayListBuilder> builder_;
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_DISPLAY_LIST_CANVAS_H_

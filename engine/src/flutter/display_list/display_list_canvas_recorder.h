// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DISPLAY_LIST_CANVAS_RECORDER_H_
#define FLUTTER_DISPLAY_LIST_DISPLAY_LIST_CANVAS_RECORDER_H_

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/display_list_builder.h"
#include "flutter/display_list/display_list_flags.h"
#include "flutter/fml/macros.h"
#include "third_party/skia/include/core/SkCanvasVirtualEnforcer.h"
#include "third_party/skia/include/utils/SkNoDrawCanvas.h"

namespace flutter {

//------------------------------------------------------------------------------
/// An adapter that implements an SkCanvas interface which can then be handed to
/// code that outputs to an SkCanvas to capture the output into a Flutter
/// DisplayList.
///
/// Receives all methods on SkCanvas and sends them to a DisplayListBuilder
///
class DisplayListCanvasRecorder
    : public SkCanvasVirtualEnforcer<SkNoDrawCanvas>,
      public SkRefCnt,
      DisplayListOpFlags {
 public:
  explicit DisplayListCanvasRecorder(const SkRect& bounds);

  const sk_sp<DisplayListBuilder> builder() { return builder_; }

  sk_sp<DisplayList> Build();

  void didConcat44(const SkM44&) override;
  void didSetM44(const SkM44&) override;
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
  void onDrawBehind(const SkPaint&) override;
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
  void onDrawRegion(const SkRegion& region, const SkPaint& paint) override;

  void onDrawTextBlob(const SkTextBlob* blob,
                      SkScalar x,
                      SkScalar y,
                      const SkPaint& paint) override;

  void onDrawPatch(const SkPoint cubics[12],
                   const SkColor colors[4],
                   const SkPoint texCoords[4],
                   SkBlendMode mode,
                   const SkPaint& paint) override;
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
                        SkBlendMode mode) override;

  void onDrawAnnotation(const SkRect& rect,
                        const char key[],
                        SkData* value) override;
  void onDrawShadowRec(const SkPath&, const SkDrawShadowRec&) override;

  void onDrawDrawable(SkDrawable* drawable, const SkMatrix* matrix) override;
  void onDrawPicture(const SkPicture* picture,
                     const SkMatrix* matrix,
                     const SkPaint* paint) override;

 private:
  sk_sp<DisplayListBuilder> builder_;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DISPLAY_LIST_CANVAS_RECORDER_H_

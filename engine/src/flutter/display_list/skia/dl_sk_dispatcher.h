// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DISPLAY_LIST_CANVAS_DISPATCHER_H_
#define FLUTTER_DISPLAY_LIST_DISPLAY_LIST_CANVAS_DISPATCHER_H_

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/dl_op_receiver.h"
#include "flutter/display_list/skia/dl_sk_utils.h"
#include "flutter/fml/macros.h"

namespace flutter {

//------------------------------------------------------------------------------
/// Can be fed to the dispatch() method of a DisplayList to feed the resulting
/// rendering operations to an SkCanvas instance.
///
/// Receives all methods on Dispatcher and sends them to an SkCanvas
///
class DlSkCanvasDispatcher : public virtual DlOpReceiver,
                             public SkPaintDispatchHelper {
 public:
  explicit DlSkCanvasDispatcher(SkCanvas* canvas, SkScalar opacity = SK_Scalar1)
      : SkPaintDispatchHelper(opacity),
        canvas_(canvas),
        original_transform_(canvas->getLocalToDevice()) {}

  const SkPaint* safe_paint(bool use_attributes);

  void save() override;
  void restore() override;
  void saveLayer(const SkRect* bounds,
                 const SaveLayerOptions options,
                 const DlImageFilter* backdrop) override;

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
  void transformReset() override;

  void clipRect(const SkRect& rect, ClipOp clip_op, bool is_aa) override;
  void clipRRect(const SkRRect& rrect, ClipOp clip_op, bool is_aa) override;
  void clipPath(const SkPath& path, ClipOp clip_op, bool is_aa) override;

  void drawPaint() override;
  void drawColor(DlColor color, DlBlendMode mode) override;
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
  void drawPoints(PointMode mode, uint32_t count, const SkPoint pts[]) override;
  void drawVertices(const DlVertices* vertices, DlBlendMode mode) override;
  void drawImage(const sk_sp<DlImage> image,
                 const SkPoint point,
                 DlImageSampling sampling,
                 bool render_with_attributes) override;
  void drawImageRect(const sk_sp<DlImage> image,
                     const SkRect& src,
                     const SkRect& dst,
                     DlImageSampling sampling,
                     bool render_with_attributes,
                     bool enforce_src_edges) override;
  void drawImageNine(const sk_sp<DlImage> image,
                     const SkIRect& center,
                     const SkRect& dst,
                     DlFilterMode filter,
                     bool render_with_attributes) override;
  void drawAtlas(const sk_sp<DlImage> atlas,
                 const SkRSXform xform[],
                 const SkRect tex[],
                 const DlColor colors[],
                 int count,
                 DlBlendMode mode,
                 DlImageSampling sampling,
                 const SkRect* cullRect,
                 bool render_with_attributes) override;
  void drawDisplayList(const sk_sp<DisplayList> display_list,
                       SkScalar opacity) override;
  void drawTextBlob(const sk_sp<SkTextBlob> blob,
                    SkScalar x,
                    SkScalar y) override;
  void drawShadow(const SkPath& path,
                  const DlColor color,
                  const SkScalar elevation,
                  bool transparent_occluder,
                  SkScalar dpr) override;

  static void DrawShadow(SkCanvas* canvas,
                         const SkPath& path,
                         DlColor color,
                         float elevation,
                         bool transparentOccluder,
                         SkScalar dpr);

 private:
  SkCanvas* canvas_;
  const SkM44 original_transform_;
  SkPaint temp_paint_;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DISPLAY_LIST_CANVAS_DISPATCHER_H_

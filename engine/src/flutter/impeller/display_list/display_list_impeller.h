// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/display_list/display_list.h"
#include "flutter/fml/macros.h"
#include "impeller/aiks/canvas.h"
#include "impeller/aiks/paint.h"

namespace impeller {

class DisplayListImpeller final : public flutter::Dispatcher {
 public:
  DisplayListImpeller();

  ~DisplayListImpeller();

  // |flutter::Dispatcher|
  void setAntiAlias(bool aa) override;

  // |flutter::Dispatcher|
  void setDither(bool dither) override;

  // |flutter::Dispatcher|
  void setStyle(SkPaint::Style style) override;

  // |flutter::Dispatcher|
  void setColor(SkColor color) override;

  // |flutter::Dispatcher|
  void setStrokeWidth(SkScalar width) override;

  // |flutter::Dispatcher|
  void setStrokeMiter(SkScalar limit) override;

  // |flutter::Dispatcher|
  void setStrokeCap(SkPaint::Cap cap) override;

  // |flutter::Dispatcher|
  void setStrokeJoin(SkPaint::Join join) override;

  // |flutter::Dispatcher|
  void setShader(sk_sp<SkShader> shader) override;

  // |flutter::Dispatcher|
  void setColorFilter(sk_sp<SkColorFilter> filter) override;

  // |flutter::Dispatcher|
  void setInvertColors(bool invert) override;

  // |flutter::Dispatcher|
  void setBlendMode(SkBlendMode mode) override;

  // |flutter::Dispatcher|
  void setBlender(sk_sp<SkBlender> blender) override;

  // |flutter::Dispatcher|
  void setPathEffect(sk_sp<SkPathEffect> effect) override;

  // |flutter::Dispatcher|
  void setMaskFilter(sk_sp<SkMaskFilter> filter) override;

  // |flutter::Dispatcher|
  void setMaskBlurFilter(SkBlurStyle style, SkScalar sigma) override;

  // |flutter::Dispatcher|
  void setImageFilter(sk_sp<SkImageFilter> filter) override;

  // |flutter::Dispatcher|
  void save() override;

  // |flutter::Dispatcher|
  void saveLayer(const SkRect* bounds, bool restore_with_paint) override;

  // |flutter::Dispatcher|
  void restore() override;

  // |flutter::Dispatcher|
  void translate(SkScalar tx, SkScalar ty) override;

  // |flutter::Dispatcher|
  void scale(SkScalar sx, SkScalar sy) override;

  // |flutter::Dispatcher|
  void rotate(SkScalar degrees) override;

  // |flutter::Dispatcher|
  void skew(SkScalar sx, SkScalar sy) override;

  // |flutter::Dispatcher|
  void transform2DAffine(SkScalar mxx,
                         SkScalar mxy,
                         SkScalar mxt,
                         SkScalar myx,
                         SkScalar myy,
                         SkScalar myt) override;

  // |flutter::Dispatcher|
  void transformFullPerspective(SkScalar mxx,
                                SkScalar mxy,
                                SkScalar mxz,
                                SkScalar mxt,
                                SkScalar myx,
                                SkScalar myy,
                                SkScalar myz,
                                SkScalar myt,
                                SkScalar mzx,
                                SkScalar mzy,
                                SkScalar mzz,
                                SkScalar mzt,
                                SkScalar mwx,
                                SkScalar mwy,
                                SkScalar mwz,
                                SkScalar mwt) override;

  // |flutter::Dispatcher|
  void clipRect(const SkRect& rect, SkClipOp clip_op, bool is_aa) override;

  // |flutter::Dispatcher|
  void clipRRect(const SkRRect& rrect, SkClipOp clip_op, bool is_aa) override;

  // |flutter::Dispatcher|
  void clipPath(const SkPath& path, SkClipOp clip_op, bool is_aa) override;

  // |flutter::Dispatcher|
  void drawColor(SkColor color, SkBlendMode mode) override;

  // |flutter::Dispatcher|
  void drawPaint() override;

  // |flutter::Dispatcher|
  void drawLine(const SkPoint& p0, const SkPoint& p1) override;

  // |flutter::Dispatcher|
  void drawRect(const SkRect& rect) override;

  // |flutter::Dispatcher|
  void drawOval(const SkRect& bounds) override;

  // |flutter::Dispatcher|
  void drawCircle(const SkPoint& center, SkScalar radius) override;

  // |flutter::Dispatcher|
  void drawRRect(const SkRRect& rrect) override;

  // |flutter::Dispatcher|
  void drawDRRect(const SkRRect& outer, const SkRRect& inner) override;

  // |flutter::Dispatcher|
  void drawPath(const SkPath& path) override;

  // |flutter::Dispatcher|
  void drawArc(const SkRect& oval_bounds,
               SkScalar start_degrees,
               SkScalar sweep_degrees,
               bool use_center) override;

  // |flutter::Dispatcher|
  void drawPoints(SkCanvas::PointMode mode,
                  uint32_t count,
                  const SkPoint points[]) override;

  // |flutter::Dispatcher|
  void drawVertices(const sk_sp<SkVertices> vertices,
                    SkBlendMode mode) override;

  // |flutter::Dispatcher|
  void drawImage(const sk_sp<SkImage> image,
                 const SkPoint point,
                 const SkSamplingOptions& sampling,
                 bool render_with_attributes) override;

  // |flutter::Dispatcher|
  void drawImageRect(const sk_sp<SkImage> image,
                     const SkRect& src,
                     const SkRect& dst,
                     const SkSamplingOptions& sampling,
                     bool render_with_attributes,
                     SkCanvas::SrcRectConstraint constraint) override;

  // |flutter::Dispatcher|
  void drawImageNine(const sk_sp<SkImage> image,
                     const SkIRect& center,
                     const SkRect& dst,
                     SkFilterMode filter,
                     bool render_with_attributes) override;

  // |flutter::Dispatcher|
  void drawImageLattice(const sk_sp<SkImage> image,
                        const SkCanvas::Lattice& lattice,
                        const SkRect& dst,
                        SkFilterMode filter,
                        bool render_with_attributes) override;

  // |flutter::Dispatcher|
  void drawAtlas(const sk_sp<SkImage> atlas,
                 const SkRSXform xform[],
                 const SkRect tex[],
                 const SkColor colors[],
                 int count,
                 SkBlendMode mode,
                 const SkSamplingOptions& sampling,
                 const SkRect* cull_rect,
                 bool render_with_attributes) override;

  // |flutter::Dispatcher|
  void drawPicture(const sk_sp<SkPicture> picture,
                   const SkMatrix* matrix,
                   bool render_with_attributes) override;

  // |flutter::Dispatcher|
  void drawDisplayList(const sk_sp<flutter::DisplayList> display_list) override;

  // |flutter::Dispatcher|
  void drawTextBlob(const sk_sp<SkTextBlob> blob,
                    SkScalar x,
                    SkScalar y) override;

  // |flutter::Dispatcher|
  void drawShadow(const SkPath& path,
                  const SkColor color,
                  const SkScalar elevation,
                  bool transparent_occluder,
                  SkScalar dpr) override;

 private:
  Paint paint_;
  Canvas canvas_;

  FML_DISALLOW_COPY_AND_ASSIGN(DisplayListImpeller);
};

}  // namespace impeller

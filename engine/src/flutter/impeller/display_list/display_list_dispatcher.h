// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "display_list/display_list_path_effect.h"
#include "flutter/display_list/display_list.h"
#include "flutter/display_list/display_list_blend_mode.h"
#include "flutter/display_list/display_list_dispatcher.h"
#include "flutter/fml/macros.h"
#include "impeller/aiks/canvas.h"
#include "impeller/aiks/paint.h"

namespace impeller {

class DisplayListDispatcher final : public flutter::Dispatcher {
 public:
  DisplayListDispatcher();

  ~DisplayListDispatcher();

  Picture EndRecordingAsPicture();

  // |flutter::Dispatcher|
  void setAntiAlias(bool aa) override;

  // |flutter::Dispatcher|
  void setDither(bool dither) override;

  // |flutter::Dispatcher|
  void setStyle(flutter::DlDrawStyle style) override;

  // |flutter::Dispatcher|
  void setColor(flutter::DlColor color) override;

  // |flutter::Dispatcher|
  void setStrokeWidth(SkScalar width) override;

  // |flutter::Dispatcher|
  void setStrokeMiter(SkScalar limit) override;

  // |flutter::Dispatcher|
  void setStrokeCap(flutter::DlStrokeCap cap) override;

  // |flutter::Dispatcher|
  void setStrokeJoin(flutter::DlStrokeJoin join) override;

  // |flutter::Dispatcher|
  void setColorSource(const flutter::DlColorSource* source) override;

  // |flutter::Dispatcher|
  void setColorFilter(const flutter::DlColorFilter* filter) override;

  // |flutter::Dispatcher|
  void setInvertColors(bool invert) override;

  // |flutter::Dispatcher|
  void setBlendMode(flutter::DlBlendMode mode) override;

  // |flutter::Dispatcher|
  void setBlender(sk_sp<SkBlender> blender) override;

  // |flutter::Dispatcher|
  void setPathEffect(const flutter::DlPathEffect* effect) override;

  // |flutter::Dispatcher|
  void setMaskFilter(const flutter::DlMaskFilter* filter) override;

  // |flutter::Dispatcher|
  void setImageFilter(const flutter::DlImageFilter* filter) override;

  // |flutter::Dispatcher|
  void save() override;

  // |flutter::Dispatcher|
  void saveLayer(const SkRect* bounds,
                 const flutter::SaveLayerOptions options,
                 const flutter::DlImageFilter* backdrop) override;

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
  void transformReset() override;

  // |flutter::Dispatcher|
  void clipRect(const SkRect& rect, SkClipOp clip_op, bool is_aa) override;

  // |flutter::Dispatcher|
  void clipRRect(const SkRRect& rrect, SkClipOp clip_op, bool is_aa) override;

  // |flutter::Dispatcher|
  void clipPath(const SkPath& path, SkClipOp clip_op, bool is_aa) override;

  // |flutter::Dispatcher|
  void drawColor(flutter::DlColor color, flutter::DlBlendMode mode) override;

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
  void drawSkVertices(const sk_sp<SkVertices> vertices,
                      SkBlendMode mode) override;

  // |flutter::Dispatcher|
  void drawVertices(const flutter::DlVertices* vertices,
                    flutter::DlBlendMode dl_mode) override;

  // |flutter::Dispatcher|
  void drawImage(const sk_sp<flutter::DlImage> image,
                 const SkPoint point,
                 flutter::DlImageSampling sampling,
                 bool render_with_attributes) override;

  // |flutter::Dispatcher|
  void drawImageRect(const sk_sp<flutter::DlImage> image,
                     const SkRect& src,
                     const SkRect& dst,
                     flutter::DlImageSampling sampling,
                     bool render_with_attributes,
                     SkCanvas::SrcRectConstraint constraint) override;

  // |flutter::Dispatcher|
  void drawImageNine(const sk_sp<flutter::DlImage> image,
                     const SkIRect& center,
                     const SkRect& dst,
                     flutter::DlFilterMode filter,
                     bool render_with_attributes) override;

  // |flutter::Dispatcher|
  void drawImageLattice(const sk_sp<flutter::DlImage> image,
                        const SkCanvas::Lattice& lattice,
                        const SkRect& dst,
                        flutter::DlFilterMode filter,
                        bool render_with_attributes) override;

  // |flutter::Dispatcher|
  void drawAtlas(const sk_sp<flutter::DlImage> atlas,
                 const SkRSXform xform[],
                 const SkRect tex[],
                 const flutter::DlColor colors[],
                 int count,
                 flutter::DlBlendMode mode,
                 flutter::DlImageSampling sampling,
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
                  const flutter::DlColor color,
                  const SkScalar elevation,
                  bool transparent_occluder,
                  SkScalar dpr) override;

 private:
  Paint paint_;
  Canvas canvas_;

  FML_DISALLOW_COPY_AND_ASSIGN(DisplayListDispatcher);
};

}  // namespace impeller

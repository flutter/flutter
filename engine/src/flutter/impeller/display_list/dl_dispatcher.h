// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/display_list/dl_op_receiver.h"
#include "flutter/fml/macros.h"
#include "impeller/aiks/canvas_type.h"
#include "impeller/aiks/paint.h"

namespace impeller {

class DlDispatcher final : public flutter::DlOpReceiver {
 public:
  DlDispatcher();

  explicit DlDispatcher(Rect cull_rect);

  explicit DlDispatcher(IRect cull_rect);

  ~DlDispatcher();

  Picture EndRecordingAsPicture();

  // |flutter::DlOpReceiver|
  void setAntiAlias(bool aa) override;

  // |flutter::DlOpReceiver|
  void setDither(bool dither) override;

  // |flutter::DlOpReceiver|
  void setDrawStyle(flutter::DlDrawStyle style) override;

  // |flutter::DlOpReceiver|
  void setColor(flutter::DlColor color) override;

  // |flutter::DlOpReceiver|
  void setStrokeWidth(SkScalar width) override;

  // |flutter::DlOpReceiver|
  void setStrokeMiter(SkScalar limit) override;

  // |flutter::DlOpReceiver|
  void setStrokeCap(flutter::DlStrokeCap cap) override;

  // |flutter::DlOpReceiver|
  void setStrokeJoin(flutter::DlStrokeJoin join) override;

  // |flutter::DlOpReceiver|
  void setColorSource(const flutter::DlColorSource* source) override;

  // |flutter::DlOpReceiver|
  void setColorFilter(const flutter::DlColorFilter* filter) override;

  // |flutter::DlOpReceiver|
  void setInvertColors(bool invert) override;

  // |flutter::DlOpReceiver|
  void setBlendMode(flutter::DlBlendMode mode) override;

  // |flutter::DlOpReceiver|
  void setPathEffect(const flutter::DlPathEffect* effect) override;

  // |flutter::DlOpReceiver|
  void setMaskFilter(const flutter::DlMaskFilter* filter) override;

  // |flutter::DlOpReceiver|
  void setImageFilter(const flutter::DlImageFilter* filter) override;

  // |flutter::DlOpReceiver|
  void save() override;

  // |flutter::DlOpReceiver|
  void saveLayer(const SkRect* bounds,
                 const flutter::SaveLayerOptions options,
                 const flutter::DlImageFilter* backdrop) override;

  // |flutter::DlOpReceiver|
  void restore() override;

  // |flutter::DlOpReceiver|
  void translate(SkScalar tx, SkScalar ty) override;

  // |flutter::DlOpReceiver|
  void scale(SkScalar sx, SkScalar sy) override;

  // |flutter::DlOpReceiver|
  void rotate(SkScalar degrees) override;

  // |flutter::DlOpReceiver|
  void skew(SkScalar sx, SkScalar sy) override;

  // |flutter::DlOpReceiver|
  void transform2DAffine(SkScalar mxx,
                         SkScalar mxy,
                         SkScalar mxt,
                         SkScalar myx,
                         SkScalar myy,
                         SkScalar myt) override;

  // |flutter::DlOpReceiver|
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

  // |flutter::DlOpReceiver|
  void transformReset() override;

  // |flutter::DlOpReceiver|
  void clipRect(const SkRect& rect, ClipOp clip_op, bool is_aa) override;

  // |flutter::DlOpReceiver|
  void clipRRect(const SkRRect& rrect, ClipOp clip_op, bool is_aa) override;

  // |flutter::DlOpReceiver|
  void clipPath(const SkPath& path, ClipOp clip_op, bool is_aa) override;

  // |flutter::DlOpReceiver|
  void drawColor(flutter::DlColor color, flutter::DlBlendMode mode) override;

  // |flutter::DlOpReceiver|
  void drawPaint() override;

  // |flutter::DlOpReceiver|
  void drawLine(const SkPoint& p0, const SkPoint& p1) override;

  // |flutter::DlOpReceiver|
  void drawRect(const SkRect& rect) override;

  // |flutter::DlOpReceiver|
  void drawOval(const SkRect& bounds) override;

  // |flutter::DlOpReceiver|
  void drawCircle(const SkPoint& center, SkScalar radius) override;

  // |flutter::DlOpReceiver|
  void drawRRect(const SkRRect& rrect) override;

  // |flutter::DlOpReceiver|
  void drawDRRect(const SkRRect& outer, const SkRRect& inner) override;

  // |flutter::DlOpReceiver|
  void drawPath(const SkPath& path) override;

  // |flutter::DlOpReceiver|
  void drawArc(const SkRect& oval_bounds,
               SkScalar start_degrees,
               SkScalar sweep_degrees,
               bool use_center) override;

  // |flutter::DlOpReceiver|
  void drawPoints(PointMode mode,
                  uint32_t count,
                  const SkPoint points[]) override;

  // |flutter::DlOpReceiver|
  void drawVertices(const flutter::DlVertices* vertices,
                    flutter::DlBlendMode dl_mode) override;

  // |flutter::DlOpReceiver|
  void drawImage(const sk_sp<flutter::DlImage> image,
                 const SkPoint point,
                 flutter::DlImageSampling sampling,
                 bool render_with_attributes) override;

  // |flutter::DlOpReceiver|
  void drawImageRect(const sk_sp<flutter::DlImage> image,
                     const SkRect& src,
                     const SkRect& dst,
                     flutter::DlImageSampling sampling,
                     bool render_with_attributes,
                     SrcRectConstraint constraint) override;

  // |flutter::DlOpReceiver|
  void drawImageNine(const sk_sp<flutter::DlImage> image,
                     const SkIRect& center,
                     const SkRect& dst,
                     flutter::DlFilterMode filter,
                     bool render_with_attributes) override;

  // |flutter::DlOpReceiver|
  void drawAtlas(const sk_sp<flutter::DlImage> atlas,
                 const SkRSXform xform[],
                 const SkRect tex[],
                 const flutter::DlColor colors[],
                 int count,
                 flutter::DlBlendMode mode,
                 flutter::DlImageSampling sampling,
                 const SkRect* cull_rect,
                 bool render_with_attributes) override;

  // |flutter::DlOpReceiver|
  void drawDisplayList(const sk_sp<flutter::DisplayList> display_list,
                       SkScalar opacity) override;

  // |flutter::DlOpReceiver|
  void drawTextBlob(const sk_sp<SkTextBlob> blob,
                    SkScalar x,
                    SkScalar y) override;

  // |flutter::DlOpReceiver|
  void drawTextFrame(const std::shared_ptr<impeller::TextFrame>& text_frame,
                     SkScalar x,
                     SkScalar y) override;

  // |flutter::DlOpReceiver|
  void drawShadow(const SkPath& path,
                  const flutter::DlColor color,
                  const SkScalar elevation,
                  bool transparent_occluder,
                  SkScalar dpr) override;

 private:
  Paint paint_;
  CanvasType canvas_;
  Matrix initial_matrix_;

  DlDispatcher(const DlDispatcher&) = delete;

  DlDispatcher& operator=(const DlDispatcher&) = delete;
};

}  // namespace impeller

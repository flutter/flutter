// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_UTILS_DL_RECEIVER_UTILS_H_
#define FLUTTER_DISPLAY_LIST_UTILS_DL_RECEIVER_UTILS_H_

#include "flutter/display_list/dl_op_receiver.h"
#include "flutter/fml/logging.h"

// This file contains various utility classes to ease implementing
// a Flutter DisplayList DlOpReceiver, including:
//
// IgnoreAttributeDispatchHelper:
// IgnoreClipDispatchHelper:
// IgnoreTransformDispatchHelper
//     Empty overrides of all of the associated methods of DlOpReceiver
//     for receivers that only track some of the rendering operations

namespace flutter {

// A utility class that will ignore all DlOpReceiver methods relating
// to the setting of attributes.
class IgnoreAttributeDispatchHelper : public virtual DlOpReceiver {
 public:
  void setAntiAlias(bool aa) override {}
  void setDither(bool dither) override {}
  void setInvertColors(bool invert) override {}
  void setStrokeCap(DlStrokeCap cap) override {}
  void setStrokeJoin(DlStrokeJoin join) override {}
  void setDrawStyle(DlDrawStyle style) override {}
  void setStrokeWidth(float width) override {}
  void setStrokeMiter(float limit) override {}
  void setColor(DlColor color) override {}
  void setBlendMode(DlBlendMode mode) override {}
  void setColorSource(const DlColorSource* source) override {}
  void setImageFilter(const DlImageFilter* filter) override {}
  void setColorFilter(const DlColorFilter* filter) override {}
  void setPathEffect(const DlPathEffect* effect) override {}
  void setMaskFilter(const DlMaskFilter* filter) override {}
};

// A utility class that will ignore all DlOpReceiver methods relating
// to setting a clip.
class IgnoreClipDispatchHelper : public virtual DlOpReceiver {
  void clipRect(const SkRect& rect,
                DlCanvas::ClipOp clip_op,
                bool is_aa) override {}
  void clipRRect(const SkRRect& rrect,
                 DlCanvas::ClipOp clip_op,
                 bool is_aa) override {}
  void clipPath(const SkPath& path,
                DlCanvas::ClipOp clip_op,
                bool is_aa) override {}
};

// A utility class that will ignore all DlOpReceiver methods relating
// to modifying the transform.
class IgnoreTransformDispatchHelper : public virtual DlOpReceiver {
 public:
  void translate(SkScalar tx, SkScalar ty) override {}
  void scale(SkScalar sx, SkScalar sy) override {}
  void rotate(SkScalar degrees) override {}
  void skew(SkScalar sx, SkScalar sy) override {}
  // clang-format off
  // 2x3 2D affine subset of a 4x4 transform in row major order
  void transform2DAffine(SkScalar mxx, SkScalar mxy, SkScalar mxt,
                         SkScalar myx, SkScalar myy, SkScalar myt) override {}
  // full 4x4 transform in row major order
  void transformFullPerspective(
      SkScalar mxx, SkScalar mxy, SkScalar mxz, SkScalar mxt,
      SkScalar myx, SkScalar myy, SkScalar myz, SkScalar myt,
      SkScalar mzx, SkScalar mzy, SkScalar mzz, SkScalar mzt,
      SkScalar mwx, SkScalar mwy, SkScalar mwz, SkScalar mwt) override {}
  // clang-format on
  void transformReset() override {}
};

class IgnoreDrawDispatchHelper : public virtual DlOpReceiver {
 public:
  void save() override {}
  void saveLayer(const SkRect* bounds,
                 const SaveLayerOptions options,
                 const DlImageFilter* backdrop) override {}
  void restore() override {}
  void drawColor(DlColor color, DlBlendMode mode) override {}
  void drawPaint() override {}
  void drawLine(const SkPoint& p0, const SkPoint& p1) override {}
  void drawRect(const SkRect& rect) override {}
  void drawOval(const SkRect& bounds) override {}
  void drawCircle(const SkPoint& center, SkScalar radius) override {}
  void drawRRect(const SkRRect& rrect) override {}
  void drawDRRect(const SkRRect& outer, const SkRRect& inner) override {}
  void drawPath(const SkPath& path) override {}
  void drawArc(const SkRect& oval_bounds,
               SkScalar start_degrees,
               SkScalar sweep_degrees,
               bool use_center) override {}
  void drawPoints(DlCanvas::PointMode mode,
                  uint32_t count,
                  const SkPoint points[]) override {}
  void drawVertices(const DlVertices* vertices, DlBlendMode mode) override {}
  void drawImage(const sk_sp<DlImage> image,
                 const SkPoint point,
                 DlImageSampling sampling,
                 bool render_with_attributes) override {}
  void drawImageRect(const sk_sp<DlImage> image,
                     const SkRect& src,
                     const SkRect& dst,
                     DlImageSampling sampling,
                     bool render_with_attributes,
                     SrcRectConstraint constraint) override {}
  void drawImageNine(const sk_sp<DlImage> image,
                     const SkIRect& center,
                     const SkRect& dst,
                     DlFilterMode filter,
                     bool render_with_attributes) override {}
  void drawAtlas(const sk_sp<DlImage> atlas,
                 const SkRSXform xform[],
                 const SkRect tex[],
                 const DlColor colors[],
                 int count,
                 DlBlendMode mode,
                 DlImageSampling sampling,
                 const SkRect* cull_rect,
                 bool render_with_attributes) override {}
  void drawDisplayList(const sk_sp<DisplayList> display_list,
                       SkScalar opacity) override {}
  void drawTextBlob(const sk_sp<SkTextBlob> blob,
                    SkScalar x,
                    SkScalar y) override {}
  void drawShadow(const SkPath& path,
                  const DlColor color,
                  const SkScalar elevation,
                  bool transparent_occluder,
                  SkScalar dpr) override {}
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_UTILS_DL_RECEIVER_UTILS_H_

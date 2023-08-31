// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DL_OP_SPY_H_
#define FLUTTER_DISPLAY_LIST_DL_OP_SPY_H_

#include "flutter/display_list/dl_op_receiver.h"
#include "flutter/display_list/utils/dl_receiver_utils.h"

namespace flutter {

//------------------------------------------------------------------------------
/// Receives to drawing commands of a DisplayListBuilder.
///
/// This is used to determine whether any non-transparent pixels will be drawn
/// on the canvas.
/// All the drawImage operations are considered drawing non-transparent pixels.
///
/// To use this class, dispatch the operations from DisplayList to a concrete
/// DlOpSpy object, and check the result of `did_draw` method.
///
/// ```
///    DlOpSpy dl_op_spy;
///    display_list.Dispatch(dl_op_spy);
///    bool did_draw = dl_op_spy.did_draw()
/// ```
///
class DlOpSpy final : public virtual DlOpReceiver,
                      private IgnoreAttributeDispatchHelper,
                      private IgnoreClipDispatchHelper,
                      private IgnoreTransformDispatchHelper {
 public:
  //----------------------------------------------------------------------------
  /// @brief      Returns true if any non transparent content has been drawn.
  bool did_draw();

 private:
  void setColor(DlColor color) override;
  void setColorSource(const DlColorSource* source) override;
  void save() override;
  void saveLayer(const SkRect* bounds,
                 const SaveLayerOptions options,
                 const DlImageFilter* backdrop) override;
  void restore() override;
  void drawColor(DlColor color, DlBlendMode mode) override;
  void drawPaint() override;
  void drawLine(const SkPoint& p0, const SkPoint& p1) override;
  void drawRect(const SkRect& rect) override;
  void drawOval(const SkRect& bounds) override;
  void drawCircle(const SkPoint& center, SkScalar radius) override;
  void drawRRect(const SkRRect& rrect) override;
  void drawDRRect(const SkRRect& outer, const SkRRect& inner) override;
  void drawPath(const SkPath& path) override;
  void drawArc(const SkRect& oval_bounds,
               SkScalar start_degrees,
               SkScalar sweep_degrees,
               bool use_center) override;
  void drawPoints(PointMode mode,
                  uint32_t count,
                  const SkPoint points[]) override;
  void drawVertices(const DlVertices* vertices, DlBlendMode mode) override;
  void drawImage(const sk_sp<DlImage> image,
                 const SkPoint point,
                 DlImageSampling sampling,
                 bool render_with_attributes) override;
  void drawImageRect(
      const sk_sp<DlImage> image,
      const SkRect& src,
      const SkRect& dst,
      DlImageSampling sampling,
      bool render_with_attributes,
      SrcRectConstraint constraint = SrcRectConstraint::kFast) override;
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
                 const SkRect* cull_rect,
                 bool render_with_attributes) override;
  void drawDisplayList(const sk_sp<DisplayList> display_list,
                       SkScalar opacity = SK_Scalar1) override;
  void drawTextBlob(const sk_sp<SkTextBlob> blob,
                    SkScalar x,
                    SkScalar y) override;
  void drawShadow(const SkPath& path,
                  const DlColor color,
                  const SkScalar elevation,
                  bool transparent_occluder,
                  SkScalar dpr) override;

  // Indicates if the attributes are set to values that will modify the
  // destination. For now, the test only checks if there is a non-transparent
  // color set.
  bool will_draw_ = true;

  bool did_draw_ = false;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DL_OP_SPY_H_

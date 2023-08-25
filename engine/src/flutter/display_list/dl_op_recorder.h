// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DL_OP_RECORDER_H_
#define FLUTTER_DISPLAY_LIST_DL_OP_RECORDER_H_

#include "flutter/display_list/dl_canvas_to_receiver.h"
#include "flutter/display_list/dl_op_receiver.h"
#include "flutter/display_list/utils/dl_bounds_accumulator.h"
#include "flutter/display_list/utils/dl_matrix_clip_tracker.h"

namespace flutter {

class DisplayList;

//------------------------------------------------------------------------------
/// @brief      An implementation of DlOpReceiver that records the calls into
///             a buffer, typically driven from a DisplayListBuilder.
///
class DlOpRecorder : public DlCanvasReceiver {
 private:
  using ClipOp = DlCanvas::ClipOp;

 public:
  static constexpr SkRect kMaxCullRect =
      SkRect::MakeLTRB(-1E9F, -1E9F, 1E9F, 1E9F);

  DlOpRecorder(const SkRect& cull_rect = kMaxCullRect, bool keep_rtree = false);

  ~DlOpRecorder() = default;

  // | DlCanvasReceiver|
  SkRect base_device_cull_rect() const override {
    return tracker_->base_device_cull_rect();
  }
  SkRect device_cull_rect() const override {
    return tracker_->device_cull_rect();
  }
  SkRect local_cull_rect() const override {
    return tracker_->local_cull_rect();
  }
  bool is_cull_rect_empty() const override {
    return tracker_->is_cull_rect_empty();
  }
  bool content_culled(const SkRect& content_bounds) const override {
    return tracker_->content_culled(content_bounds);
  }

  // | DlCanvasReceiver|
  SkM44 matrix_4x4() const override { return tracker_->matrix_4x4(); }
  SkMatrix matrix_3x3() const override { return tracker_->matrix_3x3(); }

  // | DlCanvasReceiver|
  void resetCullRect(const SkRect* cull_rect = nullptr) override;
  void intersectCullRect(const SkRect& cull_rect) override;

  // | DlCanvasReceiver|
  bool wants_granular_bounds() const override {
    return accumulator_->type() == BoundsAccumulator::Type::kRTree;
  }

  // |DlOpReceiver| all set methods
  void setAntiAlias(bool aa) override;
  void setDither(bool dither) override;
  void setDrawStyle(DlDrawStyle style) override;
  void setColor(DlColor color) override;
  void setStrokeWidth(float width) override;
  void setStrokeMiter(float limit) override;
  void setStrokeCap(DlStrokeCap cap) override;
  void setStrokeJoin(DlStrokeJoin join) override;
  void setColorSource(const DlColorSource* source) override;
  void setColorFilter(const DlColorFilter* filter) override;
  void setInvertColors(bool invert) override;
  void setBlendMode(DlBlendMode mode) override;
  void setPathEffect(const DlPathEffect* effect) override;
  void setMaskFilter(const DlMaskFilter* filter) override;
  void setImageFilter(const DlImageFilter* filter) override;

  // |DlOpReceiver|
  void save() override;
  // |DlOpReceiver|
  void saveLayer(const SkRect* bounds,
                 const SaveLayerOptions options,
                 const DlImageFilter* backdrop = nullptr) override;

  // |DlOpReceiver|
  void restore() override;
  // |DlCanvasReceiver|
  void restoreLayer(const DlImageFilter*,
                    bool layer_content_was_unbounded,
                    bool layer_could_distribute_opacity) override;

  // |DlOpReceiver| all transform methods
  void translate(SkScalar tx, SkScalar ty) override;
  void scale(SkScalar sx, SkScalar sy) override;
  void rotate(SkScalar degrees) override;
  void skew(SkScalar sx, SkScalar sy) override;

  // clang-format off
  // |DlOpReceiver|
  void transform2DAffine(SkScalar mxx, SkScalar mxy, SkScalar mxt,
                         SkScalar myx, SkScalar myy, SkScalar myt) override;
  // |DlOpReceiver|
  void transformFullPerspective(
      SkScalar mxx, SkScalar mxy, SkScalar mxz, SkScalar mxt,
      SkScalar myx, SkScalar myy, SkScalar myz, SkScalar myt,
      SkScalar mzx, SkScalar mzy, SkScalar mzz, SkScalar mzt,
      SkScalar mwx, SkScalar mwy, SkScalar mwz, SkScalar mwt) override;
  // clang-format on

  // |DlOpReceiver|
  void transformReset() override;

  // |DlOpReceiver| all clip methods
  void clipRect(const SkRect& rect, ClipOp clip_op, bool is_aa) override;
  void clipRRect(const SkRRect& rrect, ClipOp clip_op, bool is_aa) override;
  void clipPath(const SkPath& path, ClipOp clip_op, bool is_aa) override;

  // |DlOpReceiver| all render methods
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
  void drawImage(const sk_sp<DlImage>& image,
                 const SkPoint point,
                 DlImageSampling sampling,
                 bool render_with_attributes) override;
  void drawImageRect(
      const sk_sp<DlImage>& image,
      const SkRect& src,
      const SkRect& dst,
      DlImageSampling sampling,
      bool render_with_attributes,
      SrcRectConstraint constraint = SrcRectConstraint::kFast) override;
  void drawImageNine(const sk_sp<DlImage>& image,
                     const SkIRect& center,
                     const SkRect& dst,
                     DlFilterMode filter,
                     bool render_with_attributes) override;
  void drawAtlas(const sk_sp<DlImage>& atlas,
                 const SkRSXform xform[],
                 const SkRect tex[],
                 const DlColor colors[],
                 int count,
                 DlBlendMode mode,
                 DlImageSampling sampling,
                 const SkRect* cull_rect,
                 bool render_with_attributes) override;
  void drawDisplayList(const sk_sp<DisplayList>& display_list,
                       SkScalar opacity = SK_Scalar1) override;
  void drawTextBlob(const sk_sp<SkTextBlob>& blob,
                    SkScalar x,
                    SkScalar y) override;
  void drawShadow(const SkPath& path,
                  const DlColor color,
                  const SkScalar elevation,
                  bool transparent_occluder,
                  SkScalar dpr) override;

  bool accumulateLocalBoundsForNextOp(const SkRect& r) override;
  bool accumulateUnboundedForNextOp() override;

  bool is_nop() override { return tracker_->is_cull_rect_empty(); }

  sk_sp<DisplayList> Build(bool can_distribute_opacity = false,
                           bool affects_transparent_layer = true);

 private:
  std::shared_ptr<DisplayListMatrixClipTracker> tracker_;
  std::shared_ptr<BoundsAccumulator> accumulator_;
  DisplayList::DlStorage storage_;

  struct SaveInfo {
    size_t offset;
    bool deferred;
    bool is_layer;
  };
  std::vector<SaveInfo> save_infos_;
  void ResolveDeferredSave();

  int render_op_count_ = 0;
  int op_index_ = 0;

  // bytes and ops from |drawPicture| and |drawDisplayList|
  size_t nested_bytes_ = 0;
  int nested_op_count_ = 0;

  bool is_ui_thread_safe_ = true;

  template <typename T, typename... Args>
  void* Push(size_t extra, int op_inc, Args&&... args);
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DL_OP_RECORDER_H_

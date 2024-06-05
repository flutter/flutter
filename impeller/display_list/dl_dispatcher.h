// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_DISPLAY_LIST_DL_DISPATCHER_H_
#define FLUTTER_IMPELLER_DISPLAY_LIST_DL_DISPATCHER_H_

#include "display_list/utils/dl_receiver_utils.h"
#include "flutter/display_list/dl_op_receiver.h"
#include "fml/logging.h"
#include "impeller/aiks/canvas.h"
#include "impeller/aiks/experimental_canvas.h"
#include "impeller/aiks/paint.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/geometry/color.h"

namespace impeller {

class DlDispatcherBase : public flutter::DlOpReceiver {
 public:
  Picture EndRecordingAsPicture();

  // |flutter::DlOpReceiver|
  bool PrefersImpellerPaths() const override { return true; }

  // |flutter::DlOpReceiver|
  void setAntiAlias(bool aa) override;

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
  void save(uint32_t total_content_depth) override;

  // |flutter::DlOpReceiver|
  void saveLayer(const SkRect& bounds,
                 const flutter::SaveLayerOptions& options,
                 uint32_t total_content_depth,
                 flutter::DlBlendMode max_content_mode,
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
  void clipPath(const CacheablePath& cache,
                ClipOp clip_op,
                bool is_aa) override;

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
  void drawPath(const CacheablePath& cache) override;

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

  // |flutter::DlOpReceiver|
  void drawShadow(const CacheablePath& cache,
                  const flutter::DlColor color,
                  const SkScalar elevation,
                  bool transparent_occluder,
                  SkScalar dpr) override;

  virtual Canvas& GetCanvas() = 0;

 private:
  Paint paint_;
  Matrix initial_matrix_;

  static const Path& GetOrCachePath(const CacheablePath& cache);

  static void SimplifyOrDrawPath(Canvas& canvas,
                                 const CacheablePath& cache,
                                 const Paint& paint);
};

class DlDispatcher : public DlDispatcherBase {
 public:
  DlDispatcher();

  explicit DlDispatcher(IRect cull_rect);

  explicit DlDispatcher(Rect cull_rect);

  ~DlDispatcher() = default;

  // |flutter::DlOpReceiver|
  void save() override {
    // This dispatcher is used from test cases that might not supply
    // a content_depth parameter. Since this dispatcher doesn't use
    // the value, we just pass through a 0.
    DlDispatcherBase::save(0u);
  }
  using DlDispatcherBase::save;

  // |flutter::DlOpReceiver|
  void saveLayer(const SkRect& bounds,
                 const flutter::SaveLayerOptions options,
                 const flutter::DlImageFilter* backdrop) override {
    // This dispatcher is used from test cases that might not supply
    // a content_depth parameter. Since this dispatcher doesn't use
    // the value, we just pass through a 0.
    DlDispatcherBase::saveLayer(bounds, options, 0u,
                                flutter::DlBlendMode::kLastMode, backdrop);
  }
  using DlDispatcherBase::saveLayer;

 private:
  Canvas canvas_;

  Canvas& GetCanvas() override;
};

class ExperimentalDlDispatcher : public DlDispatcherBase {
 public:
  ExperimentalDlDispatcher(ContentContext& renderer,
                           RenderTarget& render_target,
                           bool has_root_backdrop_filter,
                           flutter::DlBlendMode max_root_blend_mode,
                           IRect cull_rect);

  ~ExperimentalDlDispatcher() = default;

  // |flutter::DlOpReceiver|
  void save() override {
    // This dispatcher should never be used with the save() variant
    // that does not include the content_depth parameter.
    FML_UNREACHABLE();
  }
  using DlDispatcherBase::save;

  // |flutter::DlOpReceiver|
  void saveLayer(const SkRect& bounds,
                 const flutter::SaveLayerOptions options,
                 const flutter::DlImageFilter* backdrop) override {
    // This dispatcher should never be used with the saveLayer() variant
    // that does not include the content_depth parameter.
    FML_UNREACHABLE();
  }
  using DlDispatcherBase::saveLayer;

  void FinishRecording() { canvas_.EndReplay(); }

 private:
  ExperimentalCanvas canvas_;

  Canvas& GetCanvas() override;
};

/// Performs a first pass over the display list to collect all text frames.
class TextFrameDispatcher : public flutter::IgnoreAttributeDispatchHelper,
                            public flutter::IgnoreClipDispatchHelper,
                            public flutter::IgnoreDrawDispatchHelper {
 public:
  TextFrameDispatcher(const ContentContext& renderer,
                      const Matrix& initial_matrix);
  void save() override;

  void saveLayer(const SkRect& bounds,
                 const flutter::SaveLayerOptions options,
                 const flutter::DlImageFilter* backdrop) override;

  void restore() override;

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

  void transformReset() override;

  void drawTextFrame(const std::shared_ptr<impeller::TextFrame>& text_frame,
                     SkScalar x,
                     SkScalar y) override;

  void drawDisplayList(const sk_sp<flutter::DisplayList> display_list,
                       SkScalar opacity) override;

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

 private:
  const ContentContext& renderer_;
  Matrix matrix_;
  std::vector<Matrix> stack_;
  Paint paint_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_DISPLAY_LIST_DL_DISPATCHER_H_

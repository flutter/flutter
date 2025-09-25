// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DL_CANVAS_H_
#define FLUTTER_DISPLAY_LIST_DL_CANVAS_H_

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/dl_blend_mode.h"
#include "flutter/display_list/dl_paint.h"
#include "flutter/display_list/dl_text.h"
#include "flutter/display_list/dl_types.h"
#include "flutter/display_list/dl_vertices.h"
#include "flutter/display_list/geometry/dl_geometry_types.h"
#include "flutter/display_list/geometry/dl_path.h"
#include "flutter/display_list/image/dl_image.h"

namespace flutter {

//------------------------------------------------------------------------------
/// @brief    Developer-facing API for rendering anything *within* the engine.
///
/// |DlCanvas| should be used to render anything in the framework classes (i.e.
/// `lib/ui`), flow and flow layers, embedders, shell, and elsewhere.
///
/// The only state carried by implementations of this interface are the clip
/// and transform which are saved and restored by the |save|, |saveLayer|, and
/// |restore| calls.
///
/// @note      The interface resembles closely the familiar |SkCanvas| interface
///            used throughout the engine.
class DlCanvas {
 public:
  virtual ~DlCanvas() = default;

  virtual DlISize GetBaseLayerDimensions() const = 0;
  virtual SkImageInfo GetImageInfo() const = 0;

  virtual void Save() = 0;
  virtual void SaveLayer(const std::optional<DlRect>& bounds,
                         const DlPaint* paint = nullptr,
                         const DlImageFilter* backdrop = nullptr,
                         std::optional<int64_t> backdrop_id = std::nullopt) = 0;
  virtual void Restore() = 0;
  virtual int GetSaveCount() const = 0;
  virtual void RestoreToCount(int restore_count) = 0;

  virtual void Translate(DlScalar tx, DlScalar ty) = 0;
  virtual void Scale(DlScalar sx, DlScalar sy) = 0;
  virtual void Rotate(DlScalar degrees) = 0;
  virtual void Skew(DlScalar sx, DlScalar sy) = 0;

  // clang-format off

  // 2x3 2D affine subset of a 4x4 transform in row major order
  virtual void Transform2DAffine(DlScalar mxx, DlScalar mxy, DlScalar mxt,
                                 DlScalar myx, DlScalar myy, DlScalar myt) = 0;
  // full 4x4 transform in row major order
  virtual void TransformFullPerspective(
      DlScalar mxx, DlScalar mxy, DlScalar mxz, DlScalar mxt,
      DlScalar myx, DlScalar myy, DlScalar myz, DlScalar myt,
      DlScalar mzx, DlScalar mzy, DlScalar mzz, DlScalar mzt,
      DlScalar mwx, DlScalar mwy, DlScalar mwz, DlScalar mwt) = 0;
  // clang-format on
  virtual void TransformReset() = 0;
  virtual void Transform(const DlMatrix& matrix) = 0;
  virtual void SetTransform(const DlMatrix& matrix) = 0;

  virtual DlMatrix GetMatrix() const = 0;

  virtual void ClipRect(const DlRect& rect,
                        DlClipOp clip_op = DlClipOp::kIntersect,
                        bool is_aa = false) = 0;
  virtual void ClipOval(const DlRect& bounds,
                        DlClipOp clip_op = DlClipOp::kIntersect,
                        bool is_aa = false) = 0;
  virtual void ClipRoundRect(const DlRoundRect& rrect,
                             DlClipOp clip_op = DlClipOp::kIntersect,
                             bool is_aa = false) = 0;
  virtual void ClipRoundSuperellipse(const DlRoundSuperellipse& rse,
                                     DlClipOp clip_op = DlClipOp::kIntersect,
                                     bool is_aa = false) = 0;
  virtual void ClipPath(const DlPath& path,
                        DlClipOp clip_op = DlClipOp::kIntersect,
                        bool is_aa = false) = 0;

  /// Conservative estimate of the bounds of all outstanding clip operations
  /// measured in the coordinate space within which this DisplayList will
  /// be rendered.
  virtual DlRect GetDestinationClipCoverage() const = 0;
  /// Conservative estimate of the bounds of all outstanding clip operations
  /// transformed into the local coordinate space in which currently
  /// recorded rendering operations are interpreted.
  virtual DlRect GetLocalClipCoverage() const = 0;

  /// Return true iff the supplied bounds are easily shown to be outside
  /// of the current clip bounds. This method may conservatively return
  /// false if it cannot make the determination.
  virtual bool QuickReject(const DlRect& bounds) const = 0;

  virtual void DrawPaint(const DlPaint& paint) = 0;
  virtual void DrawColor(DlColor color,
                         DlBlendMode mode = DlBlendMode::kSrcOver) = 0;
  void Clear(DlColor color) { DrawColor(color, DlBlendMode::kSrc); }
  virtual void DrawLine(const DlPoint& p0,
                        const DlPoint& p1,
                        const DlPaint& paint) = 0;
  virtual void DrawDashedLine(const DlPoint& p0,
                              const DlPoint& p1,
                              DlScalar on_length,
                              DlScalar off_length,
                              const DlPaint& paint) = 0;
  virtual void DrawRect(const DlRect& rect, const DlPaint& paint) = 0;
  virtual void DrawOval(const DlRect& bounds, const DlPaint& paint) = 0;
  virtual void DrawCircle(const DlPoint& center,
                          DlScalar radius,
                          const DlPaint& paint) = 0;
  virtual void DrawRoundRect(const DlRoundRect& rrect,
                             const DlPaint& paint) = 0;
  virtual void DrawDiffRoundRect(const DlRoundRect& outer,
                                 const DlRoundRect& inner,
                                 const DlPaint& paint) = 0;
  virtual void DrawRoundSuperellipse(const DlRoundSuperellipse& rse,
                                     const DlPaint& paint) = 0;
  virtual void DrawPath(const DlPath& path, const DlPaint& paint) = 0;
  virtual void DrawArc(const DlRect& bounds,
                       DlScalar start,
                       DlScalar sweep,
                       bool useCenter,
                       const DlPaint& paint) = 0;
  virtual void DrawPoints(DlPointMode mode,
                          uint32_t count,
                          const DlPoint pts[],
                          const DlPaint& paint) = 0;
  virtual void DrawVertices(const std::shared_ptr<DlVertices>& vertices,
                            DlBlendMode mode,
                            const DlPaint& paint) = 0;
  virtual void DrawImage(const sk_sp<DlImage>& image,
                         const DlPoint& point,
                         DlImageSampling sampling,
                         const DlPaint* paint = nullptr) = 0;
  virtual void DrawImageRect(
      const sk_sp<DlImage>& image,
      const DlRect& src,
      const DlRect& dst,
      DlImageSampling sampling,
      const DlPaint* paint = nullptr,
      DlSrcRectConstraint constraint = DlSrcRectConstraint::kFast) = 0;
  virtual void DrawImageRect(
      const sk_sp<DlImage>& image,
      const DlIRect& src,
      const DlRect& dst,
      DlImageSampling sampling,
      const DlPaint* paint = nullptr,
      DlSrcRectConstraint constraint = DlSrcRectConstraint::kFast) {
    auto float_src = DlRect::MakeLTRB(src.GetLeft(), src.GetTop(),
                                      src.GetRight(), src.GetBottom());
    DrawImageRect(image, float_src, dst, sampling, paint, constraint);
  }
  void DrawImageRect(
      const sk_sp<DlImage>& image,
      const DlRect& dst,
      DlImageSampling sampling,
      const DlPaint* paint = nullptr,
      DlSrcRectConstraint constraint = DlSrcRectConstraint::kFast) {
    DrawImageRect(image, image->GetBounds(), dst, sampling, paint, constraint);
  }
  virtual void DrawImageNine(const sk_sp<DlImage>& image,
                             const DlIRect& center,
                             const DlRect& dst,
                             DlFilterMode filter,
                             const DlPaint* paint = nullptr) = 0;
  virtual void DrawAtlas(const sk_sp<DlImage>& atlas,
                         const DlRSTransform xform[],
                         const DlRect tex[],
                         const DlColor colors[],
                         int count,
                         DlBlendMode mode,
                         DlImageSampling sampling,
                         const DlRect* cullRect,
                         const DlPaint* paint = nullptr) = 0;
  virtual void DrawDisplayList(const sk_sp<DisplayList> display_list,
                               DlScalar opacity = SK_Scalar1) = 0;

  virtual void DrawText(const std::shared_ptr<DlText>& text,
                        DlScalar x,
                        DlScalar y,
                        const DlPaint& paint) = 0;

  /// @brief  Draws the shadow of the given |path| rendered in the provided
  ///         |color| (which is only consulted for its opacity) as would be
  ///         produced by a directional light source uniformly shining in
  ///         the device space direction {0, -1, 1} against a backdrop
  ///         which is |elevation * dpr| device coordinates below the |path|
  ///         in the Z direction.
  ///
  /// Normally the renderer might consider omitting the rendering of any
  /// of the shadow pixels that fall under the |path| itself, as an
  /// optimization, unless the |transparent_occluder| flag is specified
  /// which would indicate that the optimization isn't appropriate.
  ///
  /// Note that the |elevation| and |dpr| are unique in the API for being
  /// considered in pure device coordinates while the |path| is interpreted
  /// relative to the current local-to-device transform.
  ///
  /// @see |ComputeShadowBounds|
  virtual void DrawShadow(const DlPath& path,
                          const DlColor color,
                          const DlScalar elevation,
                          bool transparent_occluder,
                          DlScalar dpr) = 0;

  virtual void Flush() = 0;

  static constexpr DlScalar kShadowLightHeight = 600;
  static constexpr DlScalar kShadowLightRadius = 800;

  /// @brief  Compute the local coverage for a |DrawShadow| operation using
  ///         the given parameters (excluding the color and the transparent
  ///         occluder parameters which do not affect the bounds).
  ///
  /// Since the elevation is expressed in device coordinates relative to the
  /// provided |dpr| value, the |ctm| of the final rendering coordinate
  /// system that will be applied to the path must be provided so the two
  /// sets of coordinates (path and light source) can be correlated.
  ///
  /// @see |DrawShadow|
  static DlRect ComputeShadowBounds(const DlPath& path,
                                    float elevation,
                                    DlScalar dpr,
                                    const DlMatrix& ctm);
};

class DlAutoCanvasRestore {
 public:
  DlAutoCanvasRestore(DlCanvas* canvas, bool do_save) : canvas_(canvas) {
    if (canvas) {
      canvas_ = canvas;
      restore_count_ = canvas->GetSaveCount();
      if (do_save) {
        canvas_->Save();
      }
    } else {
      canvas_ = nullptr;
      restore_count_ = 0;
    }
  }

  ~DlAutoCanvasRestore() { Restore(); }

  void Restore() {
    if (canvas_) {
      canvas_->RestoreToCount(restore_count_);
      canvas_ = nullptr;
    }
  }

 private:
  DlCanvas* canvas_;
  int restore_count_;

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(DlAutoCanvasRestore);
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DL_CANVAS_H_

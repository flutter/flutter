// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TESTING_MOCK_CANVAS_H_
#define FLUTTER_TESTING_MOCK_CANVAS_H_

#include <ostream>
#include <variant>
#include <vector>

#include "flutter/display_list/dl_canvas.h"
#include "flutter/display_list/utils/dl_matrix_clip_tracker.h"
#include "gtest/gtest.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkCanvasVirtualEnforcer.h"
#include "third_party/skia/include/core/SkClipOp.h"
#include "third_party/skia/include/core/SkData.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkImageFilter.h"
#include "third_party/skia/include/core/SkM44.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkRRect.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/utils/SkNWayCanvas.h"

namespace flutter {
namespace testing {

static constexpr SkRect kEmptyRect = SkRect::MakeEmpty();

// Mock |SkCanvas|, useful for writing tests that use Skia but do not interact
// with the GPU.
//
// The |MockCanvas| stores a list of |DrawCall| that the test can later verify
// against the expected list of primitives to be drawn.
class MockCanvas final : public DlCanvas {
 public:
  enum ClipEdgeStyle {
    kHardClipEdgeStyle,
    kSoftClipEdgeStyle,
  };

  struct SaveData {
    int save_to_layer;
  };

  struct SaveLayerData {
    SkRect save_bounds;
    DlPaint restore_paint;
    std::shared_ptr<DlImageFilter> backdrop_filter;
    int save_to_layer;
  };

  struct RestoreData {
    int restore_to_layer;
  };

  struct ConcatMatrixData {
    SkM44 matrix;
  };

  struct SetMatrixData {
    SkM44 matrix;
  };

  struct DrawRectData {
    SkRect rect;
    DlPaint paint;
  };

  struct DrawPathData {
    SkPath path;
    DlPaint paint;
  };

  struct DrawTextData {
    sk_sp<SkData> serialized_text;
    DlPaint paint;
    SkPoint offset;
  };

  struct DrawImageDataNoPaint {
    sk_sp<DlImage> image;
    DlScalar x;
    DlScalar y;
    DlImageSampling options;
  };

  struct DrawImageData {
    sk_sp<DlImage> image;
    DlScalar x;
    DlScalar y;
    DlImageSampling options;
    DlPaint paint;
  };

  struct DrawDisplayListData {
    sk_sp<DisplayList> display_list;
    DlScalar opacity;
  };

  struct DrawShadowData {
    SkPath path;
    DlColor color;
    DlScalar elevation;
    bool transparent_occluder;
    DlScalar dpr;
  };

  struct ClipRectData {
    SkRect rect;
    ClipOp clip_op;
    ClipEdgeStyle style;
  };

  struct ClipOvalData {
    SkRect bounds;
    ClipOp clip_op;
    ClipEdgeStyle style;
  };

  struct ClipRRectData {
    SkRRect rrect;
    ClipOp clip_op;
    ClipEdgeStyle style;
  };

  struct ClipPathData {
    SkPath path;
    ClipOp clip_op;
    ClipEdgeStyle style;
  };

  struct DrawPaintData {
    DlPaint paint;
  };

  // Discriminated union of all the different |DrawCall| types.  It is roughly
  // equivalent to the different methods in |SkCanvas|' public API.
  using DrawCallData = std::variant<SaveData,
                                    SaveLayerData,
                                    RestoreData,
                                    ConcatMatrixData,
                                    SetMatrixData,
                                    DrawRectData,
                                    DrawPathData,
                                    DrawTextData,
                                    DrawImageDataNoPaint,
                                    DrawImageData,
                                    DrawDisplayListData,
                                    DrawShadowData,
                                    ClipRectData,
                                    ClipOvalData,
                                    ClipRRectData,
                                    ClipPathData,
                                    DrawPaintData>;

  // A single call made against this canvas.
  struct DrawCall {
    int layer;
    DrawCallData data;
  };

  MockCanvas();
  MockCanvas(int width, int height);
  ~MockCanvas();

  const std::vector<DrawCall>& draw_calls() const { return draw_calls_; }
  void reset_draw_calls() { draw_calls_.clear(); }

  DlISize GetBaseLayerDimensions() const override;
  SkImageInfo GetImageInfo() const override;

  void Save() override;
  void SaveLayer(std::optional<const DlRect>& bounds,
                 const DlPaint* paint = nullptr,
                 const DlImageFilter* backdrop = nullptr) override;
  void Restore() override;
  int GetSaveCount() const { return current_layer_; }
  void RestoreToCount(int restore_count) {
    while (current_layer_ > restore_count) {
      Restore();
    }
  }

  // clang-format off

  // 2x3 2D affine subset of a 4x4 transform in row major order
  void Transform2DAffine(DlScalar mxx, DlScalar mxy, DlScalar mxt,
                         DlScalar myx, DlScalar myy, DlScalar myt) override;
  // full 4x4 transform in row major order
  void TransformFullPerspective(
      DlScalar mxx, DlScalar mxy, DlScalar mxz, DlScalar mxt,
      DlScalar myx, DlScalar myy, DlScalar myz, DlScalar myt,
      DlScalar mzx, DlScalar mzy, DlScalar mzz, DlScalar mzt,
      DlScalar mwx, DlScalar mwy, DlScalar mwz, DlScalar mwt) override;
  // clang-format on

  void Translate(DlScalar tx, DlScalar ty) override;
  void Scale(DlScalar sx, DlScalar sy) override;
  void Rotate(DlScalar degrees) override;
  void Skew(DlScalar sx, DlScalar sy) override;
  void TransformReset() override;
  void Transform(const DlMatrix& matrix) override;
  void SetTransform(const DlMatrix& matrix) override;

  DlMatrix GetMatrix() const override;

  void ClipRect(const DlRect& rect, ClipOp clip_op, bool is_aa) override;
  void ClipOval(const DlRect& bounds, ClipOp clip_op, bool is_aa) override;
  void ClipRRect(const SkRRect& rrect, ClipOp clip_op, bool is_aa) override;
  void ClipPath(const DlPath& path, ClipOp clip_op, bool is_aa) override;

  DlRect GetDestinationClipCoverage() const override;
  DlRect GetLocalClipCoverage() const override;
  bool QuickReject(const DlRect& bounds) const override;

  void DrawPaint(const DlPaint& paint) override;
  void DrawColor(DlColor color, DlBlendMode mode) override;
  void DrawLine(const DlPoint& p0,
                const DlPoint& p1,
                const DlPaint& paint) override;
  void DrawDashedLine(const DlPoint& p0,
                      const DlPoint& p1,
                      DlScalar on_length,
                      DlScalar off_length,
                      const DlPaint& paint) override;
  void DrawRect(const DlRect& rect, const DlPaint& paint) override;
  void DrawOval(const DlRect& bounds, const DlPaint& paint) override;
  void DrawCircle(const DlPoint& center,
                  DlScalar radius,
                  const DlPaint& paint) override;
  void DrawRRect(const SkRRect& rrect, const DlPaint& paint) override;
  void DrawDRRect(const SkRRect& outer,
                  const SkRRect& inner,
                  const DlPaint& paint) override;
  void DrawPath(const DlPath& path, const DlPaint& paint) override;
  void DrawArc(const DlRect& bounds,
               DlScalar start,
               DlScalar sweep,
               bool useCenter,
               const DlPaint& paint) override;
  void DrawPoints(PointMode mode,
                  uint32_t count,
                  const DlPoint pts[],
                  const DlPaint& paint) override;
  void DrawVertices(const std::shared_ptr<DlVertices>& vertices,
                    DlBlendMode mode,
                    const DlPaint& paint) override;

  void DrawImage(const sk_sp<DlImage>& image,
                 const DlPoint& point,
                 DlImageSampling sampling,
                 const DlPaint* paint = nullptr) override;
  void DrawImageRect(
      const sk_sp<DlImage>& image,
      const DlRect& src,
      const DlRect& dst,
      DlImageSampling sampling,
      const DlPaint* paint = nullptr,
      SrcRectConstraint constraint = SrcRectConstraint::kFast) override;
  void DrawImageNine(const sk_sp<DlImage>& image,
                     const DlIRect& center,
                     const DlRect& dst,
                     DlFilterMode filter,
                     const DlPaint* paint = nullptr) override;
  void DrawAtlas(const sk_sp<DlImage>& atlas,
                 const SkRSXform xform[],
                 const DlRect tex[],
                 const DlColor colors[],
                 int count,
                 DlBlendMode mode,
                 DlImageSampling sampling,
                 const DlRect* cullRect,
                 const DlPaint* paint = nullptr) override;

  void DrawDisplayList(const sk_sp<DisplayList> display_list,
                       DlScalar opacity) override;
  void DrawTextBlob(const sk_sp<SkTextBlob>& blob,
                    DlScalar x,
                    DlScalar y,
                    const DlPaint& paint) override;
  void DrawTextFrame(const std::shared_ptr<impeller::TextFrame>& text_frame,
                     DlScalar x,
                     DlScalar y,
                     const DlPaint& paint) override;
  void DrawShadow(const DlPath& path,
                  const DlColor color,
                  const DlScalar elevation,
                  bool transparent_occluder,
                  DlScalar dpr) override;

  void Flush() override;

  ENABLE_DL_CANVAS_BACKWARDS_COMPATIBILITY

 private:
  DlISize base_layer_size_;
  std::vector<DisplayListMatrixClipState> state_stack_;
  std::vector<DrawCall> draw_calls_;
  int current_layer_;
};

extern bool operator==(const MockCanvas::SaveData& a,
                       const MockCanvas::SaveData& b);
extern std::ostream& operator<<(std::ostream& os,
                                const MockCanvas::SaveData& data);
extern bool operator==(const MockCanvas::SaveLayerData& a,
                       const MockCanvas::SaveLayerData& b);
extern std::ostream& operator<<(std::ostream& os,
                                const MockCanvas::SaveLayerData& data);
extern bool operator==(const MockCanvas::RestoreData& a,
                       const MockCanvas::RestoreData& b);
extern std::ostream& operator<<(std::ostream& os,
                                const MockCanvas::RestoreData& data);
extern bool operator==(const MockCanvas::ConcatMatrixData& a,
                       const MockCanvas::ConcatMatrixData& b);
extern std::ostream& operator<<(std::ostream& os,
                                const MockCanvas::ConcatMatrixData& data);
extern bool operator==(const MockCanvas::SetMatrixData& a,
                       const MockCanvas::SetMatrixData& b);
extern std::ostream& operator<<(std::ostream& os,
                                const MockCanvas::SetMatrixData& data);
extern bool operator==(const MockCanvas::DrawRectData& a,
                       const MockCanvas::DrawRectData& b);
extern std::ostream& operator<<(std::ostream& os,
                                const MockCanvas::DrawRectData& data);
extern bool operator==(const MockCanvas::DrawPathData& a,
                       const MockCanvas::DrawPathData& b);
extern std::ostream& operator<<(std::ostream& os,
                                const MockCanvas::DrawPathData& data);
extern bool operator==(const MockCanvas::DrawTextData& a,
                       const MockCanvas::DrawTextData& b);
extern std::ostream& operator<<(std::ostream& os,
                                const MockCanvas::DrawTextData& data);
extern bool operator==(const MockCanvas::DrawImageData& a,
                       const MockCanvas::DrawImageData& b);
extern std::ostream& operator<<(std::ostream& os,
                                const MockCanvas::DrawImageData& data);
extern bool operator==(const MockCanvas::DrawImageDataNoPaint& a,
                       const MockCanvas::DrawImageDataNoPaint& b);
extern std::ostream& operator<<(std::ostream& os,
                                const MockCanvas::DrawImageDataNoPaint& data);
extern bool operator==(const MockCanvas::DrawDisplayListData& a,
                       const MockCanvas::DrawDisplayListData& b);
extern std::ostream& operator<<(std::ostream& os,
                                const MockCanvas::DrawDisplayListData& data);
extern bool operator==(const MockCanvas::DrawShadowData& a,
                       const MockCanvas::DrawShadowData& b);
extern std::ostream& operator<<(std::ostream& os,
                                const MockCanvas::DrawShadowData& data);
extern bool operator==(const MockCanvas::ClipRectData& a,
                       const MockCanvas::ClipRectData& b);
extern std::ostream& operator<<(std::ostream& os,
                                const MockCanvas::ClipRectData& data);
extern bool operator==(const MockCanvas::ClipRRectData& a,
                       const MockCanvas::ClipRRectData& b);
extern std::ostream& operator<<(std::ostream& os,
                                const MockCanvas::ClipRRectData& data);
extern bool operator==(const MockCanvas::ClipPathData& a,
                       const MockCanvas::ClipPathData& b);
extern std::ostream& operator<<(std::ostream& os,
                                const MockCanvas::ClipPathData& data);
extern std::ostream& operator<<(std::ostream& os,
                                const MockCanvas::DrawCallData& data);
extern bool operator==(const MockCanvas::DrawCall& a,
                       const MockCanvas::DrawCall& b);
extern std::ostream& operator<<(std::ostream& os,
                                const MockCanvas::DrawCall& draw);
extern bool operator==(const MockCanvas::DrawPaintData& a,
                       const MockCanvas::DrawPaintData& b);
extern std::ostream& operator<<(std::ostream& os,
                                const MockCanvas::DrawPaintData& data);
}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_TESTING_MOCK_CANVAS_H_

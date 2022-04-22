// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TESTING_MOCK_CANVAS_H_
#define TESTING_MOCK_CANVAS_H_

#include <ostream>
#include <variant>
#include <vector>

#include "flutter/testing/assertions_skia.h"
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
class MockCanvas : public SkCanvasVirtualEnforcer<SkCanvas> {
 public:
  using SkCanvas::kHard_ClipEdgeStyle;
  using SkCanvas::kSoft_ClipEdgeStyle;

  struct SaveData {
    int save_to_layer;
  };

  struct SaveLayerData {
    SkRect save_bounds;
    SkPaint restore_paint;
    sk_sp<SkImageFilter> backdrop_filter;
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
    SkPaint paint;
  };

  struct DrawPathData {
    SkPath path;
    SkPaint paint;
  };

  struct DrawTextData {
    sk_sp<SkData> serialized_text;
    SkPaint paint;
    SkPoint offset;
  };

  struct DrawImageDataNoPaint {
    sk_sp<SkImage> image;
    SkScalar x;
    SkScalar y;
    SkSamplingOptions options;
  };

  struct DrawImageData {
    sk_sp<SkImage> image;
    SkScalar x;
    SkScalar y;
    SkSamplingOptions options;
    SkPaint paint;
  };

  struct DrawPictureData {
    sk_sp<SkData> serialized_picture;
    SkPaint paint;
    SkMatrix matrix;
  };

  struct DrawShadowData {
    SkPath path;
  };

  struct ClipRectData {
    SkRect rect;
    SkClipOp clip_op;
    ClipEdgeStyle style;
  };

  struct ClipRRectData {
    SkRRect rrect;
    SkClipOp clip_op;
    ClipEdgeStyle style;
  };

  struct ClipPathData {
    SkPath path;
    SkClipOp clip_op;
    ClipEdgeStyle style;
  };

  struct DrawPaint {
    SkPaint paint;
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
                                    DrawPictureData,
                                    DrawShadowData,
                                    ClipRectData,
                                    ClipRRectData,
                                    ClipPathData,
                                    DrawPaint>;

  // A single call made against this canvas.
  struct DrawCall {
    int layer;
    DrawCallData data;
  };

  MockCanvas();
  ~MockCanvas() override;

  SkNWayCanvas* internal_canvas() { return &internal_canvas_; }

  const std::vector<DrawCall>& draw_calls() const { return draw_calls_; }

 protected:
  // Save/restore/set operations that we track.
  void willSave() override;
  SaveLayerStrategy getSaveLayerStrategy(const SaveLayerRec& rec) override;
  void willRestore() override;
  void didRestore() override {}
  void didConcat44(const SkM44&) override;
  void didSetM44(const SkM44&) override;
  void didScale(SkScalar x, SkScalar y) override;
  void didTranslate(SkScalar x, SkScalar y) override;

  // Draw and clip operations that we track.
  void onDrawRect(const SkRect& rect, const SkPaint& paint) override;
  void onDrawPath(const SkPath& path, const SkPaint& paint) override;
  void onDrawTextBlob(const SkTextBlob* text,
                      SkScalar x,
                      SkScalar y,
                      const SkPaint& paint) override;
  void onDrawShadowRec(const SkPath& path, const SkDrawShadowRec& rec) override;
  void onDrawPicture(const SkPicture* picture,
                     const SkMatrix* matrix,
                     const SkPaint* paint) override;
  void onClipRect(const SkRect& rect,
                  SkClipOp op,
                  ClipEdgeStyle style) override;
  void onClipRRect(const SkRRect& rrect,
                   SkClipOp op,
                   ClipEdgeStyle style) override;
  void onClipPath(const SkPath& path,
                  SkClipOp op,
                  ClipEdgeStyle style) override;

  // Operations that we don't track.
  bool onDoSaveBehind(const SkRect*) override;
  void onDrawAnnotation(const SkRect&, const char[], SkData*) override;
  void onDrawDRRect(const SkRRect&, const SkRRect&, const SkPaint&) override;
  void onDrawDrawable(SkDrawable*, const SkMatrix*) override;
  void onDrawPatch(const SkPoint[12],
                   const SkColor[4],
                   const SkPoint[4],
                   SkBlendMode,
                   const SkPaint&) override;
  void onDrawPaint(const SkPaint&) override;
  void onDrawBehind(const SkPaint&) override;
  void onDrawPoints(PointMode,
                    size_t,
                    const SkPoint[],
                    const SkPaint&) override;
  void onDrawRegion(const SkRegion&, const SkPaint&) override;
  void onDrawOval(const SkRect&, const SkPaint&) override;
  void onDrawArc(const SkRect&,
                 SkScalar,
                 SkScalar,
                 bool,
                 const SkPaint&) override;
  void onDrawRRect(const SkRRect&, const SkPaint&) override;
  void onDrawImage2(const SkImage* image,
                    SkScalar x,
                    SkScalar y,
                    const SkSamplingOptions&,
                    const SkPaint* paint) override;
  void onDrawImageRect2(const SkImage*,
                        const SkRect&,
                        const SkRect&,
                        const SkSamplingOptions&,
                        const SkPaint*,
                        SrcRectConstraint) override;
  void onDrawImageLattice2(const SkImage*,
                           const Lattice&,
                           const SkRect&,
                           SkFilterMode,
                           const SkPaint*) override;
  void onDrawVerticesObject(const SkVertices*,
                            SkBlendMode,
                            const SkPaint&) override;
  void onDrawAtlas2(const SkImage*,
                    const SkRSXform[],
                    const SkRect[],
                    const SkColor[],
                    int,
                    SkBlendMode,
                    const SkSamplingOptions&,
                    const SkRect*,
                    const SkPaint*) override;
  void onDrawEdgeAAQuad(const SkRect&,
                        const SkPoint[4],
                        QuadAAFlags,
                        const SkColor4f&,
                        SkBlendMode) override;
  void onClipRegion(const SkRegion&, SkClipOp) override;

 private:
  SkNWayCanvas internal_canvas_;

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
extern bool operator==(const MockCanvas::DrawPictureData& a,
                       const MockCanvas::DrawPictureData& b);
extern std::ostream& operator<<(std::ostream& os,
                                const MockCanvas::DrawPictureData& data);
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
extern bool operator==(const MockCanvas::DrawPaint& a,
                       const MockCanvas::DrawPaint& b);
extern std::ostream& operator<<(std::ostream& os,
                                const MockCanvas::DrawPaint& data);
}  // namespace testing
}  // namespace flutter

#endif  // TESTING_MOCK_CANVAS_H_

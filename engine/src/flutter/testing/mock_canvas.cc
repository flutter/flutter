// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/mock_canvas.h"

#include "flutter/fml/logging.h"
#include "flutter/testing/display_list_testing.h"
#include "third_party/skia/include/core/SkImageInfo.h"
#include "third_party/skia/include/core/SkSerialProcs.h"
#include "third_party/skia/include/core/SkSize.h"
#include "third_party/skia/include/core/SkTextBlob.h"

namespace flutter {
namespace testing {

constexpr SkISize kSize = SkISize::Make(64, 64);

MockCanvas::MockCanvas() : MockCanvas(kSize.fWidth, kSize.fHeight) {}

MockCanvas::MockCanvas(int width, int height)
    : base_layer_size_(width, height), current_layer_(0) {
  state_stack_.emplace_back(DlRect::MakeXYWH(0, 0, width, height), DlMatrix());
}

MockCanvas::~MockCanvas() {
  EXPECT_EQ(current_layer_, 0);
}

DlISize MockCanvas::GetBaseLayerDimensions() const {
  return base_layer_size_;
}

SkImageInfo MockCanvas::GetImageInfo() const {
  return SkImageInfo::MakeUnknown(base_layer_size_.width,
                                  base_layer_size_.height);
}

void MockCanvas::Save() {
  draw_calls_.emplace_back(
      DrawCall{current_layer_, SaveData{current_layer_ + 1}});
  state_stack_.emplace_back(state_stack_.back());
  current_layer_++;  // Must go here; func params order of eval is undefined
}

void MockCanvas::SaveLayer(std::optional<const DlRect>& bounds,
                           const DlPaint* paint,
                           const DlImageFilter* backdrop) {
  draw_calls_.emplace_back(DrawCall{
      current_layer_,
      SaveLayerData{bounds.has_value() ? ToSkRect(bounds.value()) : SkRect(),
                    paint ? *paint : DlPaint(),
                    backdrop ? backdrop->shared() : nullptr,
                    current_layer_ + 1}});
  state_stack_.emplace_back(state_stack_.back());
  current_layer_++;  // Must go here; func params order of eval is undefined
}

void MockCanvas::Restore() {
  FML_DCHECK(current_layer_ > 0);

  draw_calls_.emplace_back(
      DrawCall{current_layer_, RestoreData{current_layer_ - 1}});
  state_stack_.pop_back();
  current_layer_--;  // Must go here; func params order of eval is undefined
}

// clang-format off

// 2x3 2D affine subset of a 4x4 transform in row major order
void MockCanvas::Transform2DAffine(SkScalar mxx, SkScalar mxy, SkScalar mxt,
                                   SkScalar myx, SkScalar myy, SkScalar myt) {
  Transform(DlMatrix::MakeRow(mxx, mxy, 0, mxt,
                              myx, myy, 0, myt,
                              0, 0, 1, 0,
                              0, 0, 0, 1));
}

// full 4x4 transform in row major order
void MockCanvas::TransformFullPerspective(
    SkScalar mxx, SkScalar mxy, SkScalar mxz, SkScalar mxt,
    SkScalar myx, SkScalar myy, SkScalar myz, SkScalar myt,
    SkScalar mzx, SkScalar mzy, SkScalar mzz, SkScalar mzt,
    SkScalar mwx, SkScalar mwy, SkScalar mwz, SkScalar mwt) {
  Transform(DlMatrix::MakeRow(mxx, mxy, mxz, mxt,
                              myx, myy, myz, myt,
                              mzx, mzy, mzz, mzt,
                              mwx, mwy, mwz, mwt));
}

// clang-format on

void MockCanvas::Transform(const DlMatrix& matrix) {
  draw_calls_.emplace_back(
      DrawCall{current_layer_, ConcatMatrixData{ToSkM44(matrix)}});
  state_stack_.back().transform(matrix);
}

void MockCanvas::SetTransform(const DlMatrix& matrix) {
  draw_calls_.emplace_back(
      DrawCall{current_layer_, SetMatrixData{ToSkM44(matrix)}});
  state_stack_.back().setTransform(matrix);
}

void MockCanvas::TransformReset() {
  draw_calls_.emplace_back(DrawCall{current_layer_, SetMatrixData{SkM44()}});
  state_stack_.back().setIdentity();
}

void MockCanvas::Translate(SkScalar x, SkScalar y) {
  this->Transform(DlMatrix::MakeTranslation({x, y, 0}));
}

void MockCanvas::Scale(SkScalar x, SkScalar y) {
  this->Transform(DlMatrix::MakeScale({x, y, 1}));
}

void MockCanvas::Rotate(SkScalar degrees) {
  this->Transform(DlMatrix::MakeRotationZ(DlDegrees(degrees)));
}

void MockCanvas::Skew(SkScalar sx, SkScalar sy) {
  this->Transform(DlMatrix::MakeSkew(sx, sy));
}

DlMatrix MockCanvas::GetMatrix() const {
  return state_stack_.back().matrix();
}

void MockCanvas::DrawTextBlob(const sk_sp<SkTextBlob>& text,
                              SkScalar x,
                              SkScalar y,
                              const DlPaint& paint) {
  // This duplicates existing logic in SkCanvas::onDrawPicture
  // that should probably be split out so it doesn't need to be here as well.
  // SkRect storage;
  // if (paint.canComputeFastBounds()) {
  //   storage = text->bounds().makeOffset(x, y);
  //   SkRect tmp;
  //   if (this->quickReject(paint.computeFastBounds(storage, &tmp))) {
  //     return;
  //   }
  // }

  draw_calls_.emplace_back(DrawCall{
      current_layer_, DrawTextData{text ? text->serialize(SkSerialProcs{})
                                        : SkData::MakeUninitialized(0),
                                   paint, SkPoint::Make(x, y)}});
}

void MockCanvas::DrawTextFrame(
    const std::shared_ptr<impeller::TextFrame>& text_frame,
    SkScalar x,
    SkScalar y,
    const DlPaint& paint) {
  FML_DCHECK(false);
}

void MockCanvas::DrawRect(const DlRect& rect, const DlPaint& paint) {
  draw_calls_.emplace_back(
      DrawCall{current_layer_, DrawRectData{ToSkRect(rect), paint}});
}

void MockCanvas::DrawPath(const DlPath& path, const DlPaint& paint) {
  draw_calls_.emplace_back(
      DrawCall{current_layer_, DrawPathData{path.GetSkPath(), paint}});
}

void MockCanvas::DrawShadow(const DlPath& path,
                            const DlColor color,
                            const SkScalar elevation,
                            bool transparent_occluder,
                            SkScalar dpr) {
  draw_calls_.emplace_back(DrawCall{
      current_layer_, DrawShadowData{path.GetSkPath(), color, elevation,
                                     transparent_occluder, dpr}});
}

void MockCanvas::DrawImage(const sk_sp<DlImage>& image,
                           const DlPoint& point,
                           const DlImageSampling options,
                           const DlPaint* paint) {
  if (paint) {
    draw_calls_.emplace_back(
        DrawCall{current_layer_,
                 DrawImageData{image, point.x, point.y, options, *paint}});
  } else {
    draw_calls_.emplace_back(
        DrawCall{current_layer_,
                 DrawImageDataNoPaint{image, point.x, point.y, options}});
  }
}

void MockCanvas::DrawDisplayList(const sk_sp<DisplayList> display_list,
                                 SkScalar opacity) {
  draw_calls_.emplace_back(
      DrawCall{current_layer_, DrawDisplayListData{display_list, opacity}});
}

void MockCanvas::ClipRect(const DlRect& rect, ClipOp op, bool is_aa) {
  ClipEdgeStyle style = is_aa ? kSoftClipEdgeStyle : kHardClipEdgeStyle;
  draw_calls_.emplace_back(
      DrawCall{current_layer_, ClipRectData{ToSkRect(rect), op, style}});
  state_stack_.back().clipRect(rect, op, is_aa);
}

void MockCanvas::ClipOval(const DlRect& bounds, ClipOp op, bool is_aa) {
  ClipEdgeStyle style = is_aa ? kSoftClipEdgeStyle : kHardClipEdgeStyle;
  draw_calls_.emplace_back(
      DrawCall{current_layer_, ClipOvalData{ToSkRect(bounds), op, style}});
  state_stack_.back().clipOval(bounds, op, is_aa);
}

void MockCanvas::ClipRRect(const SkRRect& rrect, ClipOp op, bool is_aa) {
  ClipEdgeStyle style = is_aa ? kSoftClipEdgeStyle : kHardClipEdgeStyle;
  draw_calls_.emplace_back(
      DrawCall{current_layer_, ClipRRectData{rrect, op, style}});
  state_stack_.back().clipRRect(rrect, op, is_aa);
}

void MockCanvas::ClipPath(const DlPath& path, ClipOp op, bool is_aa) {
  ClipEdgeStyle style = is_aa ? kSoftClipEdgeStyle : kHardClipEdgeStyle;
  draw_calls_.emplace_back(
      DrawCall{current_layer_, ClipPathData{path.GetSkPath(), op, style}});
  state_stack_.back().clipPath(path, op, is_aa);
}

DlRect MockCanvas::GetDestinationClipCoverage() const {
  return state_stack_.back().GetDeviceCullCoverage();
}

DlRect MockCanvas::GetLocalClipCoverage() const {
  return state_stack_.back().GetLocalCullCoverage();
}

bool MockCanvas::QuickReject(const DlRect& bounds) const {
  return state_stack_.back().content_culled(bounds);
}

void MockCanvas::DrawDRRect(const SkRRect&, const SkRRect&, const DlPaint&) {
  FML_DCHECK(false);
}

void MockCanvas::DrawPaint(const DlPaint& paint) {
  draw_calls_.emplace_back(DrawCall{current_layer_, DrawPaintData{paint}});
}

void MockCanvas::DrawColor(DlColor color, DlBlendMode mode) {
  DrawPaint(DlPaint(color).setBlendMode(mode));
}

void MockCanvas::DrawLine(const DlPoint& p0,
                          const DlPoint& p1,
                          const DlPaint& paint) {
  FML_DCHECK(false);
}

void MockCanvas::DrawDashedLine(const DlPoint& p0,
                                const DlPoint& p1,
                                DlScalar on_length,
                                DlScalar off_length,
                                const DlPaint& paint) {
  FML_DCHECK(false);
}

void MockCanvas::DrawPoints(PointMode,
                            uint32_t,
                            const DlPoint[],
                            const DlPaint&) {
  FML_DCHECK(false);
}

void MockCanvas::DrawOval(const DlRect&, const DlPaint&) {
  FML_DCHECK(false);
}

void MockCanvas::DrawCircle(const DlPoint& center,
                            SkScalar radius,
                            const DlPaint& paint) {
  FML_DCHECK(false);
}

void MockCanvas::DrawArc(const DlRect&,
                         SkScalar,
                         SkScalar,
                         bool,
                         const DlPaint&) {
  FML_DCHECK(false);
}

void MockCanvas::DrawRRect(const SkRRect&, const DlPaint&) {
  FML_DCHECK(false);
}

void MockCanvas::DrawImageRect(const sk_sp<DlImage>&,
                               const DlRect&,
                               const DlRect&,
                               const DlImageSampling,
                               const DlPaint*,
                               SrcRectConstraint constraint) {
  FML_DCHECK(false);
}

void MockCanvas::DrawImageNine(const sk_sp<DlImage>& image,
                               const DlIRect& center,
                               const DlRect& dst,
                               DlFilterMode filter,
                               const DlPaint* paint) {
  FML_DCHECK(false);
}

void MockCanvas::DrawVertices(const std::shared_ptr<DlVertices>&,
                              DlBlendMode,
                              const DlPaint&) {
  FML_DCHECK(false);
}

void MockCanvas::DrawAtlas(const sk_sp<DlImage>&,
                           const SkRSXform[],
                           const DlRect[],
                           const DlColor[],
                           int,
                           DlBlendMode,
                           const DlImageSampling,
                           const DlRect*,
                           const DlPaint*) {
  FML_DCHECK(false);
}

void MockCanvas::Flush() {
  FML_DCHECK(false);
}

// --------------------------------------------------------
// A few ostream operators duplicated from assertions_skia.cc
// In the short term, there are issues trying to include that file
// here because it appears in a skia-targeted testing source set
// and in the long term, DlCanvas, and therefore this file will
// eventually be cleaned of these SkObject dependencies and these
// ostream operators will be converted to their DL equivalents.
static std::ostream& operator<<(std::ostream& os, const SkPoint& r) {
  return os << "XY: " << r.fX << ", " << r.fY;
}

static std::ostream& operator<<(std::ostream& os, const SkRect& r) {
  return os << "LTRB: " << r.fLeft << ", " << r.fTop << ", " << r.fRight << ", "
            << r.fBottom;
}

static std::ostream& operator<<(std::ostream& os, const SkRRect& r) {
  return os << "LTRB: " << r.rect().fLeft << ", " << r.rect().fTop << ", "
            << r.rect().fRight << ", " << r.rect().fBottom;
}

static std::ostream& operator<<(std::ostream& os, const SkPath& r) {
  return os << "Valid: " << r.isValid()
            << ", FillType: " << static_cast<int>(r.getFillType())
            << ", Bounds: " << r.getBounds();
}
// --------------------------------------------------------

static std::ostream& operator<<(std::ostream& os, const SkM44& m) {
  os << m.rc(0, 0) << ", " << m.rc(0, 1) << ", " << m.rc(0, 2) << ", "
     << m.rc(0, 3) << std::endl;
  os << m.rc(1, 0) << ", " << m.rc(1, 1) << ", " << m.rc(1, 2) << ", "
     << m.rc(1, 3) << std::endl;
  os << m.rc(2, 0) << ", " << m.rc(2, 1) << ", " << m.rc(2, 2) << ", "
     << m.rc(2, 3) << std::endl;
  os << m.rc(3, 0) << ", " << m.rc(3, 1) << ", " << m.rc(3, 2) << ", "
     << m.rc(3, 3);
  return os;
}

bool operator==(const MockCanvas::SaveData& a, const MockCanvas::SaveData& b) {
  return a.save_to_layer == b.save_to_layer;
}

std::ostream& operator<<(std::ostream& os, const MockCanvas::SaveData& data) {
  return os << data.save_to_layer;
}

bool operator==(const MockCanvas::SaveLayerData& a,
                const MockCanvas::SaveLayerData& b) {
  return a.save_bounds == b.save_bounds && a.restore_paint == b.restore_paint &&
         Equals(a.backdrop_filter, b.backdrop_filter) &&
         a.save_to_layer == b.save_to_layer;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::SaveLayerData& data) {
  return os << data.save_bounds << " " << data.restore_paint << " "
            << data.backdrop_filter << " " << data.save_to_layer;
}

bool operator==(const MockCanvas::RestoreData& a,
                const MockCanvas::RestoreData& b) {
  return a.restore_to_layer == b.restore_to_layer;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::RestoreData& data) {
  return os << data.restore_to_layer;
}

bool operator==(const MockCanvas::ConcatMatrixData& a,
                const MockCanvas::ConcatMatrixData& b) {
  return a.matrix == b.matrix;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::ConcatMatrixData& data) {
  return os << data.matrix;
}

bool operator==(const MockCanvas::SetMatrixData& a,
                const MockCanvas::SetMatrixData& b) {
  return a.matrix == b.matrix;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::SetMatrixData& data) {
  return os << data.matrix;
}

bool operator==(const MockCanvas::DrawRectData& a,
                const MockCanvas::DrawRectData& b) {
  return a.rect == b.rect && a.paint == b.paint;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::DrawRectData& data) {
  return os << data.rect << " " << data.paint;
}

bool operator==(const MockCanvas::DrawPathData& a,
                const MockCanvas::DrawPathData& b) {
  return a.path == b.path && a.paint == b.paint;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::DrawPathData& data) {
  return os << data.path << " " << data.paint;
}

bool operator==(const MockCanvas::DrawTextData& a,
                const MockCanvas::DrawTextData& b) {
  return a.serialized_text->equals(b.serialized_text.get()) &&
         a.paint == b.paint && a.offset == b.offset;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::DrawTextData& data) {
  return os << data.serialized_text << " " << data.paint << " " << data.offset;
}

bool operator==(const MockCanvas::DrawImageData& a,
                const MockCanvas::DrawImageData& b) {
  return a.image == b.image && a.x == b.x && a.y == b.y &&
         a.options == b.options && a.paint == b.paint;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::DrawImageData& data) {
  return os << data.image << " " << data.x << " " << data.y << " "
            << data.options << " " << data.paint;
}

bool operator==(const MockCanvas::DrawImageDataNoPaint& a,
                const MockCanvas::DrawImageDataNoPaint& b) {
  return a.image == b.image && a.x == b.x && a.y == b.y &&
         a.options == b.options;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::DrawImageDataNoPaint& data) {
  return os << data.image << " " << data.x << " " << data.y << " "
            << data.options;
}

bool operator==(const MockCanvas::DrawDisplayListData& a,
                const MockCanvas::DrawDisplayListData& b) {
  return a.display_list->Equals(b.display_list) && a.opacity == b.opacity;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::DrawDisplayListData& data) {
  auto dl = data.display_list;
  return os << "[" << dl->unique_id() << " " << dl->op_count() << " "
            << dl->bytes() << "] " << data.opacity;
}

bool operator==(const MockCanvas::DrawShadowData& a,
                const MockCanvas::DrawShadowData& b) {
  return a.path == b.path && a.color == b.color && a.elevation == b.elevation &&
         a.transparent_occluder == b.transparent_occluder && a.dpr == b.dpr;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::DrawShadowData& data) {
  return os << data.path << " " << data.color << " " << data.elevation << " "
            << data.transparent_occluder << " " << data.dpr;
}

bool operator==(const MockCanvas::ClipRectData& a,
                const MockCanvas::ClipRectData& b) {
  return a.rect == b.rect && a.clip_op == b.clip_op && a.style == b.style;
}

static std::ostream& operator<<(std::ostream& os,
                                const MockCanvas::ClipEdgeStyle& style) {
  return os << (style == MockCanvas::kSoftClipEdgeStyle ? "kSoftEdges"
                                                        : "kHardEdges");
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::ClipRectData& data) {
  return os << data.rect << " " << data.clip_op << " " << data.style;
}

bool operator==(const MockCanvas::ClipOvalData& a,
                const MockCanvas::ClipOvalData& b) {
  return a.bounds == b.bounds && a.clip_op == b.clip_op && a.style == b.style;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::ClipOvalData& data) {
  return os << data.bounds << " " << data.clip_op << " " << data.style;
}

bool operator==(const MockCanvas::ClipRRectData& a,
                const MockCanvas::ClipRRectData& b) {
  return a.rrect == b.rrect && a.clip_op == b.clip_op && a.style == b.style;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::ClipRRectData& data) {
  return os << data.rrect << " " << data.clip_op << " " << data.style;
}

bool operator==(const MockCanvas::ClipPathData& a,
                const MockCanvas::ClipPathData& b) {
  return a.path == b.path && a.clip_op == b.clip_op && a.style == b.style;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::ClipPathData& data) {
  return os << data.path << " " << data.clip_op << " " << data.style;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::DrawCallData& data) {
  std::visit([&os](auto& d) { os << d; }, data);
  return os;
}

bool operator==(const MockCanvas::DrawCall& a, const MockCanvas::DrawCall& b) {
  return a.layer == b.layer && a.data == b.data;
}

std::ostream& operator<<(std::ostream& os, const MockCanvas::DrawCall& draw) {
  return os << "[Layer: " << draw.layer << ", Data: " << draw.data << "]";
}

bool operator==(const MockCanvas::DrawPaintData& a,
                const MockCanvas::DrawPaintData& b) {
  return a.paint == b.paint;
}

std::ostream& operator<<(std::ostream& os,
                         const MockCanvas::DrawPaintData& data) {
  return os << data.paint;
}

}  // namespace testing
}  // namespace flutter

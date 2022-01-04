// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/display_list/display_list_dispatcher.h"

#include "impeller/geometry/path_builder.h"

namespace impeller {

#define UNIMPLEMENTED \
  FML_LOG(ERROR) << "Unimplemented detail in " << __FUNCTION__;

DisplayListDispatcher::DisplayListDispatcher() = default;

DisplayListDispatcher::~DisplayListDispatcher() = default;

// |flutter::Dispatcher|
void DisplayListDispatcher::setAntiAlias(bool aa) {
  // Nothing to do because AA is implicit.
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setDither(bool dither) {}

static Paint::Style ToStyle(SkPaint::Style style) {
  switch (style) {
    case SkPaint::kFill_Style:
      return Paint::Style::kFill;
    case SkPaint::kStroke_Style:
      return Paint::Style::kStroke;
    case SkPaint::kStrokeAndFill_Style:
      UNIMPLEMENTED;
      break;
  }
  return Paint::Style::kFill;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setStyle(SkPaint::Style style) {
  paint_.style = ToStyle(style);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setColor(SkColor color) {
  paint_.color = {
      SkColorGetR(color) / 255.0f,  // red
      SkColorGetG(color) / 255.0f,  // green
      SkColorGetB(color) / 255.0f,  // blue
      SkColorGetA(color) / 255.0f   // alpha
  };
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setStrokeWidth(SkScalar width) {
  paint_.stroke_width = width;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setStrokeMiter(SkScalar limit) {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setStrokeCap(SkPaint::Cap cap) {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setStrokeJoin(SkPaint::Join join) {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setShader(sk_sp<SkShader> shader) {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setColorFilter(sk_sp<SkColorFilter> filter) {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setInvertColors(bool invert) {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setBlendMode(SkBlendMode mode) {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setBlender(sk_sp<SkBlender> blender) {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setPathEffect(sk_sp<SkPathEffect> effect) {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setMaskFilter(sk_sp<SkMaskFilter> filter) {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setMaskBlurFilter(SkBlurStyle style,
                                              SkScalar sigma) {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setImageFilter(sk_sp<SkImageFilter> filter) {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::save() {
  canvas_.Save();
}

static std::optional<Rect> ToRect(const SkRect* rect) {
  if (rect == nullptr) {
    return std::nullopt;
  }
  return Rect::MakeLTRB(rect->fLeft, rect->fTop, rect->fRight, rect->fBottom);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::saveLayer(const SkRect* bounds,
                                      bool restore_with_paint) {
  canvas_.SaveLayer(restore_with_paint ? paint_ : Paint{}, ToRect(bounds));
}

// |flutter::Dispatcher|
void DisplayListDispatcher::restore() {
  canvas_.Restore();
}

// |flutter::Dispatcher|
void DisplayListDispatcher::translate(SkScalar tx, SkScalar ty) {
  canvas_.Translate({tx, ty, 0.0});
}

// |flutter::Dispatcher|
void DisplayListDispatcher::scale(SkScalar sx, SkScalar sy) {
  canvas_.Scale({sx, sy, 1.0});
}

// |flutter::Dispatcher|
void DisplayListDispatcher::rotate(SkScalar degrees) {
  canvas_.Rotate(Degrees{degrees});
}

// |flutter::Dispatcher|
void DisplayListDispatcher::skew(SkScalar sx, SkScalar sy) {
  canvas_.Skew(sx, sy);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::transform2DAffine(SkScalar mxx,
                                              SkScalar mxy,
                                              SkScalar mxt,
                                              SkScalar myx,
                                              SkScalar myy,
                                              SkScalar myt) {
  // clang-format off
  transformFullPerspective(
    mxx, mxy,  0, mxt,
    myx, myy,  0, myt,
    0  ,   0,  1,   0,
    0  ,   0,  0,   1
  );
  // clang-format on
}

// |flutter::Dispatcher|
void DisplayListDispatcher::transformFullPerspective(SkScalar mxx,
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
                                                     SkScalar mwt) {
  // The order of arguments is row-major but Impeller matrices are column-major.
  // clang-format off
  auto xformation = Matrix{
    mxx, myx, mzx, mwx,
    mxy, myy, mzy, mwy,
    mxz, myz, mzz, mwz,
    mxt, myt, mzt, mwt
  };
  // clang-format on
  canvas_.Transform(xformation);
}

static Rect ToRect(const SkRect& rect) {
  return Rect::MakeLTRB(rect.fLeft, rect.fTop, rect.fRight, rect.fBottom);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::clipRect(const SkRect& rect,
                                     SkClipOp clip_op,
                                     bool is_aa) {
  auto path = PathBuilder{}.AddRect(ToRect(rect)).TakePath();
  canvas_.ClipPath(std::move(path));
}

static Point ToPoint(const SkVector& vector) {
  return {vector.fX, vector.fY};
}

static PathBuilder::RoundingRadii ToRoundingRadii(const SkRRect& rrect) {
  using Corner = SkRRect::Corner;
  PathBuilder::RoundingRadii radii;
  radii.bottom_left = ToPoint(rrect.radii(Corner::kLowerLeft_Corner));
  radii.bottom_right = ToPoint(rrect.radii(Corner::kLowerRight_Corner));
  radii.top_left = ToPoint(rrect.radii(Corner::kUpperLeft_Corner));
  radii.top_right = ToPoint(rrect.radii(Corner::kUpperRight_Corner));
  return radii;
}

static Path ToPath(const SkPath& path) {
  auto iterator = SkPath::Iter(path, false);

  struct PathData {
    union {
      SkPoint points[4];
    };
  };

  PathBuilder builder;
  PathData data;
  auto verb = SkPath::Verb::kDone_Verb;
  do {
    verb = iterator.next(data.points);
    switch (verb) {
      case SkPath::kMove_Verb:
        builder.MoveTo(ToPoint(data.points[0]));
        break;
      case SkPath::kLine_Verb:
        builder.AddLine(ToPoint(data.points[0]), ToPoint(data.points[1]));
        break;
      case SkPath::kQuad_Verb:
        builder.AddQuadraticCurve(ToPoint(data.points[0]),  // p1
                                  ToPoint(data.points[1]),  // cp
                                  ToPoint(data.points[2])   // p2
        );
        break;
      case SkPath::kConic_Verb: {
        constexpr auto kPow2 = 1;  // Only works for sweeps up to 90 degrees.
        constexpr auto kQuadCount = 1 + (2 * (1 << kPow2));
        SkPoint points[kQuadCount];
        const auto curve_count =
            SkPath::ConvertConicToQuads(data.points[0],          //
                                        data.points[1],          //
                                        data.points[2],          //
                                        iterator.conicWeight(),  //
                                        points,                  //
                                        kPow2                    //
            );

        for (int curve_index = 0, point_index = 0;  //
             curve_index < curve_count;             //
             curve_index++, point_index += 2        //
        ) {
          builder.AddQuadraticCurve(ToPoint(points[point_index + 0]),  // p1
                                    ToPoint(points[point_index + 1]),  // cp
                                    ToPoint(points[point_index + 2])   // p2
          );
        }
      } break;
      case SkPath::kCubic_Verb:
        builder.AddCubicCurve(ToPoint(data.points[0]),  // p1
                              ToPoint(data.points[1]),  // cp1
                              ToPoint(data.points[2]),  // cp2
                              ToPoint(data.points[3])   // p2
        );
        break;
      case SkPath::kClose_Verb:
        builder.Close();
        break;
      case SkPath::kDone_Verb:
        break;
    }
  } while (verb != SkPath::Verb::kDone_Verb);
  // TODO: Convert fill types.
  return builder.TakePath();
}

static Path ToPath(const SkRRect& rrect) {
  return PathBuilder{}
      .AddRoundedRect(ToRect(rrect.getBounds()), ToRoundingRadii(rrect))
      .TakePath();
}

// |flutter::Dispatcher|
void DisplayListDispatcher::clipRRect(const SkRRect& rrect,
                                      SkClipOp clip_op,
                                      bool is_aa) {
  canvas_.ClipPath(ToPath(rrect));
}

// |flutter::Dispatcher|
void DisplayListDispatcher::clipPath(const SkPath& path,
                                     SkClipOp clip_op,
                                     bool is_aa) {
  canvas_.ClipPath(ToPath(path));
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawColor(SkColor color, SkBlendMode mode) {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawPaint() {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawLine(const SkPoint& p0, const SkPoint& p1) {
  auto path = PathBuilder{}.AddLine(ToPoint(p0), ToPoint(p1)).TakePath();
  canvas_.DrawPath(std::move(path), paint_);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawRect(const SkRect& rect) {
  auto path = PathBuilder{}.AddRect(ToRect(rect)).TakePath();
  canvas_.DrawPath(std::move(path), paint_);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawOval(const SkRect& bounds) {
  auto path = PathBuilder{}.AddOval(ToRect(bounds)).TakePath();
  canvas_.DrawPath(std::move(path), paint_);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawCircle(const SkPoint& center, SkScalar radius) {
  auto path = PathBuilder{}.AddCircle(ToPoint(center), radius).TakePath();
  canvas_.DrawPath(std::move(path), paint_);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawRRect(const SkRRect& rrect) {
  canvas_.DrawPath(ToPath(rrect), paint_);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawDRRect(const SkRRect& outer,
                                       const SkRRect& inner) {
  PathBuilder builder;
  builder.AddPath(ToPath(outer));
  builder.AddPath(ToPath(inner));
  canvas_.DrawPath(builder.TakePath(FillType::kOdd), paint_);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawPath(const SkPath& path) {
  canvas_.DrawPath(ToPath(path), paint_);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawArc(const SkRect& oval_bounds,
                                    SkScalar start_degrees,
                                    SkScalar sweep_degrees,
                                    bool use_center) {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawPoints(SkCanvas::PointMode mode,
                                       uint32_t count,
                                       const SkPoint points[]) {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawVertices(const sk_sp<SkVertices> vertices,
                                         SkBlendMode mode) {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawImage(const sk_sp<SkImage> image,
                                      const SkPoint point,
                                      const SkSamplingOptions& sampling,
                                      bool render_with_attributes) {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawImageRect(
    const sk_sp<SkImage> image,
    const SkRect& src,
    const SkRect& dst,
    const SkSamplingOptions& sampling,
    bool render_with_attributes,
    SkCanvas::SrcRectConstraint constraint) {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawImageNine(const sk_sp<SkImage> image,
                                          const SkIRect& center,
                                          const SkRect& dst,
                                          SkFilterMode filter,
                                          bool render_with_attributes) {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawImageLattice(const sk_sp<SkImage> image,
                                             const SkCanvas::Lattice& lattice,
                                             const SkRect& dst,
                                             SkFilterMode filter,
                                             bool render_with_attributes) {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawAtlas(const sk_sp<SkImage> atlas,
                                      const SkRSXform xform[],
                                      const SkRect tex[],
                                      const SkColor colors[],
                                      int count,
                                      SkBlendMode mode,
                                      const SkSamplingOptions& sampling,
                                      const SkRect* cull_rect,
                                      bool render_with_attributes) {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawPicture(const sk_sp<SkPicture> picture,
                                        const SkMatrix* matrix,
                                        bool render_with_attributes) {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawDisplayList(
    const sk_sp<flutter::DisplayList> display_list) {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawTextBlob(const sk_sp<SkTextBlob> blob,
                                         SkScalar x,
                                         SkScalar y) {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawShadow(const SkPath& path,
                                       const SkColor color,
                                       const SkScalar elevation,
                                       bool transparent_occluder,
                                       SkScalar dpr) {
  UNIMPLEMENTED;
}

Picture DisplayListDispatcher::EndRecordingAsPicture() {
  return canvas_.EndRecordingAsPicture();
}

}  // namespace impeller

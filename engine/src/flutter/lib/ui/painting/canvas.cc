// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/canvas.h"

#include <math.h>

#include "flutter/lib/ui/painting/image.h"
#include "flutter/lib/ui/painting/matrix.h"
#include "lib/tonic/dart_args.h"
#include "lib/tonic/dart_binding_macros.h"
#include "lib/tonic/converter/dart_converter.h"
#include "lib/tonic/dart_library_natives.h"
#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace blink {

static void Canvas_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&Canvas::Create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, Canvas);

#define FOR_EACH_BINDING(V)         \
  V(Canvas, save)                   \
  V(Canvas, saveLayerWithoutBounds) \
  V(Canvas, saveLayer)              \
  V(Canvas, restore)                \
  V(Canvas, getSaveCount)           \
  V(Canvas, translate)              \
  V(Canvas, scale)                  \
  V(Canvas, rotate)                 \
  V(Canvas, skew)                   \
  V(Canvas, transform)              \
  V(Canvas, setMatrix)              \
  V(Canvas, clipRect)               \
  V(Canvas, clipRRect)              \
  V(Canvas, clipPath)               \
  V(Canvas, drawColor)              \
  V(Canvas, drawLine)               \
  V(Canvas, drawPaint)              \
  V(Canvas, drawRect)               \
  V(Canvas, drawRRect)              \
  V(Canvas, drawDRRect)             \
  V(Canvas, drawOval)               \
  V(Canvas, drawCircle)             \
  V(Canvas, drawArc)                \
  V(Canvas, drawPath)               \
  V(Canvas, drawImage)              \
  V(Canvas, drawImageRect)          \
  V(Canvas, drawImageNine)          \
  V(Canvas, drawPicture)            \
  V(Canvas, drawPoints)             \
  V(Canvas, drawVertices)           \
  V(Canvas, drawAtlas)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void Canvas::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({{"Canvas_constructor", Canvas_constructor, 6, true},
                     FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

ftl::RefPtr<Canvas> Canvas::Create(PictureRecorder* recorder,
                                   double left,
                                   double top,
                                   double right,
                                   double bottom) {
  FTL_DCHECK(recorder);
  FTL_DCHECK(!recorder->isRecording());
  ftl::RefPtr<Canvas> canvas = ftl::MakeRefCounted<Canvas>(
      recorder->BeginRecording(SkRect::MakeLTRB(left, top, right, bottom)));
  recorder->set_canvas(canvas);
  return canvas;
}

Canvas::Canvas(SkCanvas* canvas) : canvas_(canvas) {}

Canvas::~Canvas() {}

void Canvas::save() {
  if (!canvas_)
    return;
  canvas_->save();
}

void Canvas::saveLayerWithoutBounds(const Paint& paint,
                                    const PaintData& paint_data) {
  if (!canvas_)
    return;
  canvas_->saveLayer(nullptr, paint.paint());
}

void Canvas::saveLayer(double left,
                       double top,
                       double right,
                       double bottom,
                       const Paint& paint,
                       const PaintData& paint_data) {
  if (!canvas_)
    return;
  SkRect bounds = SkRect::MakeLTRB(left, top, right, bottom);
  canvas_->saveLayer(&bounds, paint.paint());
}

void Canvas::restore() {
  if (!canvas_)
    return;
  canvas_->restore();
}

int Canvas::getSaveCount() {
  if (!canvas_)
    return 0;
  return canvas_->getSaveCount();
}

void Canvas::translate(double dx, double dy) {
  if (!canvas_)
    return;
  canvas_->translate(dx, dy);
}

void Canvas::scale(double sx, double sy) {
  if (!canvas_)
    return;
  canvas_->scale(sx, sy);
}

void Canvas::rotate(double radians) {
  if (!canvas_)
    return;
  canvas_->rotate(radians * 180.0 / M_PI);
}

void Canvas::skew(double sx, double sy) {
  if (!canvas_)
    return;
  canvas_->skew(sx, sy);
}

void Canvas::transform(const tonic::Float64List& matrix4) {
  if (!canvas_)
    return;
  canvas_->concat(ToSkMatrix(matrix4));
}

void Canvas::setMatrix(const tonic::Float64List& matrix4) {
  if (!canvas_)
    return;
  canvas_->setMatrix(ToSkMatrix(matrix4));
}

void Canvas::clipRect(double left, double top, double right, double bottom) {
  if (!canvas_)
    return;
  canvas_->clipRect(SkRect::MakeLTRB(left, top, right, bottom));
}

void Canvas::clipRRect(const RRect& rrect) {
  if (!canvas_)
    return;
  canvas_->clipRRect(rrect.sk_rrect, SkRegion::kIntersect_Op);
}

void Canvas::clipPath(const CanvasPath* path) {
  if (!canvas_)
    return;
  canvas_->clipPath(path->path(), SkRegion::kIntersect_Op);
}

void Canvas::drawColor(SkColor color, SkXfermode::Mode transfer_mode) {
  if (!canvas_)
    return;
  canvas_->drawColor(color, transfer_mode);
}

void Canvas::drawLine(double x1,
                      double y1,
                      double x2,
                      double y2,
                      const Paint& paint,
                      const PaintData& paint_data) {
  if (!canvas_)
    return;
  canvas_->drawLine(x1, y1, x2, y2, *paint.paint());
}

void Canvas::drawPaint(const Paint& paint, const PaintData& paint_data) {
  if (!canvas_)
    return;
  canvas_->drawPaint(*paint.paint());
}

void Canvas::drawRect(double left,
                      double top,
                      double right,
                      double bottom,
                      const Paint& paint,
                      const PaintData& paint_data) {
  if (!canvas_)
    return;
  canvas_->drawRect(SkRect::MakeLTRB(left, top, right, bottom), *paint.paint());
}

void Canvas::drawRRect(const RRect& rrect,
                       const Paint& paint,
                       const PaintData& paint_data) {
  if (!canvas_)
    return;
  canvas_->drawRRect(rrect.sk_rrect, *paint.paint());
}

void Canvas::drawDRRect(const RRect& outer,
                        const RRect& inner,
                        const Paint& paint,
                        const PaintData& paint_data) {
  if (!canvas_)
    return;
  canvas_->drawDRRect(outer.sk_rrect, inner.sk_rrect, *paint.paint());
}

void Canvas::drawOval(double left,
                      double top,
                      double right,
                      double bottom,
                      const Paint& paint,
                      const PaintData& paint_data) {
  if (!canvas_)
    return;
  canvas_->drawOval(SkRect::MakeLTRB(left, top, right, bottom), *paint.paint());
}

void Canvas::drawCircle(double x,
                        double y,
                        double radius,
                        const Paint& paint,
                        const PaintData& paint_data) {
  if (!canvas_)
    return;
  canvas_->drawCircle(x, y, radius, *paint.paint());
}

void Canvas::drawArc(double left,
             double top,
             double right,
             double bottom,
             double startAngle,
             double sweepAngle,
             bool useCenter,
             const Paint& paint,
             const PaintData& paint_data) {
  if (!canvas_)
    return;
  canvas_->drawArc(SkRect::MakeLTRB(left, top, right, bottom),
                   startAngle * 180.0 / M_PI,
                   sweepAngle* 180.0 / M_PI,
                   useCenter,
                   *paint.paint());
}

void Canvas::drawPath(const CanvasPath* path,
                      const Paint& paint,
                      const PaintData& paint_data) {
  if (!canvas_)
    return;
  FTL_DCHECK(path);
  canvas_->drawPath(path->path(), *paint.paint());
}

void Canvas::drawImage(const CanvasImage* image,
                       double x,
                       double y,
                       const Paint& paint,
                       const PaintData& paint_data) {
  if (!canvas_)
    return;
  FTL_DCHECK(image);
  canvas_->drawImage(image->image(), x, y, paint.paint());
}

void Canvas::drawImageRect(const CanvasImage* image,
                           double src_left,
                           double src_top,
                           double src_right,
                           double src_bottom,
                           double dst_left,
                           double dst_top,
                           double dst_right,
                           double dst_bottom,
                           const Paint& paint,
                           const PaintData& paint_data) {
  if (!canvas_)
    return;
  FTL_DCHECK(image);
  SkRect src = SkRect::MakeLTRB(src_left, src_top, src_right, src_bottom);
  SkRect dst = SkRect::MakeLTRB(dst_left, dst_top, dst_right, dst_bottom);
  canvas_->drawImageRect(image->image(), src, dst, paint.paint(),
                         SkCanvas::kFast_SrcRectConstraint);
}

void Canvas::drawImageNine(const CanvasImage* image,
                           double center_left,
                           double center_top,
                           double center_right,
                           double center_bottom,
                           double dst_left,
                           double dst_top,
                           double dst_right,
                           double dst_bottom,
                           const Paint& paint,
                           const PaintData& paint_data) {
  if (!canvas_)
    return;
  FTL_DCHECK(image);
  SkRect center =
      SkRect::MakeLTRB(center_left, center_top, center_right, center_bottom);
  SkIRect icenter;
  center.round(&icenter);
  SkRect dst = SkRect::MakeLTRB(dst_left, dst_top, dst_right, dst_bottom);
  canvas_->drawImageNine(image->image(), icenter, dst, paint.paint());
}

void Canvas::drawPicture(Picture* picture) {
  if (!canvas_)
    return;
  FTL_DCHECK(picture);
  canvas_->drawPicture(picture->picture().get());
}

void Canvas::drawPoints(const Paint& paint,
                        const PaintData& paint_data,
                        SkCanvas::PointMode point_mode,
                        const tonic::Float32List& points) {
  if (!canvas_)
    return;

  static_assert(sizeof(SkPoint) == sizeof(float) * 2,
                "SkPoint doesn't use floats.");

  canvas_->drawPoints(point_mode,
                      points.num_elements() / 2,  // SkPoints have two floats.
                      reinterpret_cast<const SkPoint*>(points.data()),
                      *paint.paint());
}

void Canvas::drawVertices(const Paint& paint,
                          const PaintData& paint_data,
                          SkCanvas::VertexMode vertex_mode,
                          const tonic::Float32List& vertices,
                          const tonic::Float32List& texture_coordinates,
                          const tonic::Int32List& colors,
                          SkXfermode::Mode transfer_mode,
                          const tonic::Int32List& indices) {
  if (!canvas_)
    return;

  sk_sp<SkXfermode> transfer_mode_ptr = SkXfermode::Make(transfer_mode);

  std::vector<uint16_t> indices16;
  indices16.reserve(indices.num_elements());
  for (int i = 0; i < indices.num_elements(); ++i)
    indices16.push_back(indices.data()[i]);

  static_assert(sizeof(SkPoint) == sizeof(float) * 2,
                "SkPoint doesn't use floats.");
  static_assert(sizeof(SkColor) == sizeof(int32_t),
                "SkColor doesn't use int32_t.");

  canvas_->drawVertices(
      vertex_mode,
      vertices.num_elements() / 2,  // SkPoints have two floats.
      reinterpret_cast<const SkPoint*>(vertices.data()),
      reinterpret_cast<const SkPoint*>(texture_coordinates.data()),
      reinterpret_cast<const SkColor*>(colors.data()), transfer_mode_ptr.get(),
      indices16.empty() ? nullptr : indices16.data(), indices16.size(),
      *paint.paint());
}

void Canvas::drawAtlas(const Paint& paint,
                       const PaintData& paint_data,
                       CanvasImage* atlas,
                       const tonic::Float32List& transforms,
                       const tonic::Float32List& rects,
                       const tonic::Int32List& colors,
                       SkXfermode::Mode transfer_mode,
                       const tonic::Float32List& cull_rect) {
  if (!canvas_)
    return;

  sk_sp<SkImage> skImage = atlas->image();

  static_assert(sizeof(SkRSXform) == sizeof(float) * 4,
                "SkRSXform doesn't use floats.");
  static_assert(sizeof(SkRect) == sizeof(float) * 4,
                "SkRect doesn't use floats.");

  canvas_->drawAtlas(
      skImage.get(), reinterpret_cast<const SkRSXform*>(transforms.data()),
      reinterpret_cast<const SkRect*>(rects.data()),
      reinterpret_cast<const SkColor*>(colors.data()),
      rects.num_elements() / 4,  // SkRect have four floats.
      transfer_mode, reinterpret_cast<const SkRect*>(cull_rect.data()),
      paint.paint());
}

void Canvas::Clear() {
  canvas_ = nullptr;
}

bool Canvas::IsRecording() const {
  return !!canvas_;
}

}  // namespace blink

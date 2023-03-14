// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/canvas.h"

#include <cmath>

#include "flutter/display_list/display_list_builder.h"
#include "flutter/lib/ui/painting/image.h"
#include "flutter/lib/ui/painting/image_filter.h"
#include "flutter/lib/ui/painting/paint.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/lib/ui/window/platform_configuration.h"
#include "flutter/lib/ui/window/window.h"

using tonic::ToDart;

namespace flutter {

IMPLEMENT_WRAPPERTYPEINFO(ui, Canvas);

void Canvas::Create(Dart_Handle wrapper,
                    PictureRecorder* recorder,
                    double left,
                    double top,
                    double right,
                    double bottom) {
  UIDartState::ThrowIfUIOperationsProhibited();

  if (!recorder) {
    Dart_ThrowException(
        ToDart("Canvas constructor called with non-genuine PictureRecorder."));
    return;
  }

  fml::RefPtr<Canvas> canvas = fml::MakeRefCounted<Canvas>(
      recorder->BeginRecording(SkRect::MakeLTRB(left, top, right, bottom)));
  recorder->set_canvas(canvas);
  canvas->AssociateWithDartWrapper(wrapper);
}

Canvas::Canvas(sk_sp<DisplayListBuilder> builder)
    : display_list_builder_(std::move(builder)) {}

Canvas::~Canvas() {}

void Canvas::save() {
  if (display_list_builder_) {
    builder()->Save();
  }
}

void Canvas::saveLayerWithoutBounds(Dart_Handle paint_objects,
                                    Dart_Handle paint_data) {
  Paint paint(paint_objects, paint_data);

  FML_DCHECK(paint.isNotNull());
  if (display_list_builder_) {
    DlPaint dl_paint;
    const DlPaint* save_paint = paint.paint(dl_paint, kSaveLayerWithPaintFlags);
    FML_DCHECK(save_paint);
    TRACE_EVENT0("flutter", "ui.Canvas::saveLayer (Recorded)");
    builder()->SaveLayer(nullptr, save_paint);
  }
}

void Canvas::saveLayer(double left,
                       double top,
                       double right,
                       double bottom,
                       Dart_Handle paint_objects,
                       Dart_Handle paint_data) {
  Paint paint(paint_objects, paint_data);

  FML_DCHECK(paint.isNotNull());
  SkRect bounds = SkRect::MakeLTRB(left, top, right, bottom);
  if (display_list_builder_) {
    DlPaint dl_paint;
    const DlPaint* save_paint = paint.paint(dl_paint, kSaveLayerWithPaintFlags);
    FML_DCHECK(save_paint);
    TRACE_EVENT0("flutter", "ui.Canvas::saveLayer (Recorded)");
    builder()->SaveLayer(&bounds, save_paint);
  }
}

void Canvas::restore() {
  if (display_list_builder_) {
    builder()->Restore();
  }
}

int Canvas::getSaveCount() {
  if (display_list_builder_) {
    return builder()->GetSaveCount();
  } else {
    return 0;
  }
}

void Canvas::restoreToCount(int count) {
  if (display_list_builder_ && count < getSaveCount()) {
    builder()->RestoreToCount(count);
  }
}

void Canvas::translate(double dx, double dy) {
  if (display_list_builder_) {
    builder()->Translate(dx, dy);
  }
}

void Canvas::scale(double sx, double sy) {
  if (display_list_builder_) {
    builder()->Scale(sx, sy);
  }
}

void Canvas::rotate(double radians) {
  if (display_list_builder_) {
    builder()->Rotate(radians * 180.0 / M_PI);
  }
}

void Canvas::skew(double sx, double sy) {
  if (display_list_builder_) {
    builder()->Skew(sx, sy);
  }
}

void Canvas::transform(const tonic::Float64List& matrix4) {
  // The Float array stored by Dart Matrix4 is in column-major order
  // Both DisplayList and SkM44 constructor take row-major matrix order
  if (display_list_builder_) {
    // clang-format off
    builder()->TransformFullPerspective(
        matrix4[ 0], matrix4[ 4], matrix4[ 8], matrix4[12],
        matrix4[ 1], matrix4[ 5], matrix4[ 9], matrix4[13],
        matrix4[ 2], matrix4[ 6], matrix4[10], matrix4[14],
        matrix4[ 3], matrix4[ 7], matrix4[11], matrix4[15]);
    // clang-format on
  }
}

void Canvas::getTransform(Dart_Handle matrix4_handle) {
  if (display_list_builder_) {
    SkM44 sk_m44 = builder()->GetTransformFullPerspective();
    SkScalar m44_values[16];
    // The Float array stored by Dart Matrix4 is in column-major order
    sk_m44.getColMajor(m44_values);
    auto matrix4 = tonic::Float64List(matrix4_handle);
    for (int i = 0; i < 16; i++) {
      matrix4[i] = m44_values[i];
    }
  }
}

void Canvas::clipRect(double left,
                      double top,
                      double right,
                      double bottom,
                      DlCanvas::ClipOp clipOp,
                      bool doAntiAlias) {
  if (display_list_builder_) {
    builder()->ClipRect(SkRect::MakeLTRB(left, top, right, bottom), clipOp,
                        doAntiAlias);
  }
}

void Canvas::clipRRect(const RRect& rrect, bool doAntiAlias) {
  if (display_list_builder_) {
    builder()->ClipRRect(rrect.sk_rrect, DlCanvas::ClipOp::kIntersect,
                         doAntiAlias);
  }
}

void Canvas::clipPath(const CanvasPath* path, bool doAntiAlias) {
  if (!path) {
    Dart_ThrowException(
        ToDart("Canvas.clipPath called with non-genuine Path."));
    return;
  }
  if (display_list_builder_) {
    builder()->ClipPath(path->path(), DlCanvas::ClipOp::kIntersect,
                        doAntiAlias);
  }
}

void Canvas::getDestinationClipBounds(Dart_Handle rect_handle) {
  if (display_list_builder_) {
    auto rect = tonic::Float64List(rect_handle);
    SkRect bounds = builder()->GetDestinationClipBounds();
    rect[0] = bounds.fLeft;
    rect[1] = bounds.fTop;
    rect[2] = bounds.fRight;
    rect[3] = bounds.fBottom;
  }
}

void Canvas::getLocalClipBounds(Dart_Handle rect_handle) {
  if (display_list_builder_) {
    auto rect = tonic::Float64List(rect_handle);
    SkRect bounds = builder()->GetLocalClipBounds();
    rect[0] = bounds.fLeft;
    rect[1] = bounds.fTop;
    rect[2] = bounds.fRight;
    rect[3] = bounds.fBottom;
  }
}

void Canvas::drawColor(SkColor color, DlBlendMode blend_mode) {
  if (display_list_builder_) {
    builder()->DrawColor(color, blend_mode);
  }
}

void Canvas::drawLine(double x1,
                      double y1,
                      double x2,
                      double y2,
                      Dart_Handle paint_objects,
                      Dart_Handle paint_data) {
  Paint paint(paint_objects, paint_data);

  FML_DCHECK(paint.isNotNull());
  if (display_list_builder_) {
    DlPaint dl_paint;
    paint.paint(dl_paint, kDrawLineFlags);
    builder()->DrawLine(SkPoint::Make(x1, y1), SkPoint::Make(x2, y2), dl_paint);
  }
}

void Canvas::drawPaint(Dart_Handle paint_objects, Dart_Handle paint_data) {
  Paint paint(paint_objects, paint_data);

  FML_DCHECK(paint.isNotNull());
  if (display_list_builder_) {
    DlPaint dl_paint;
    paint.paint(dl_paint, kDrawPaintFlags);
    std::shared_ptr<const DlImageFilter> filter = dl_paint.getImageFilter();
    if (filter && !filter->asColorFilter()) {
      // drawPaint does an implicit saveLayer if an SkImageFilter is
      // present that cannot be replaced by an SkColorFilter.
      TRACE_EVENT0("flutter", "ui.Canvas::saveLayer (Recorded)");
    }
    builder()->DrawPaint(dl_paint);
  }
}

void Canvas::drawRect(double left,
                      double top,
                      double right,
                      double bottom,
                      Dart_Handle paint_objects,
                      Dart_Handle paint_data) {
  Paint paint(paint_objects, paint_data);

  FML_DCHECK(paint.isNotNull());
  if (display_list_builder_) {
    DlPaint dl_paint;
    paint.paint(dl_paint, kDrawRectFlags);
    builder()->DrawRect(SkRect::MakeLTRB(left, top, right, bottom), dl_paint);
  }
}

void Canvas::drawRRect(const RRect& rrect,
                       Dart_Handle paint_objects,
                       Dart_Handle paint_data) {
  Paint paint(paint_objects, paint_data);

  FML_DCHECK(paint.isNotNull());
  if (display_list_builder_) {
    DlPaint dl_paint;
    paint.paint(dl_paint, kDrawRRectFlags);
    builder()->DrawRRect(rrect.sk_rrect, dl_paint);
  }
}

void Canvas::drawDRRect(const RRect& outer,
                        const RRect& inner,
                        Dart_Handle paint_objects,
                        Dart_Handle paint_data) {
  Paint paint(paint_objects, paint_data);

  FML_DCHECK(paint.isNotNull());
  if (display_list_builder_) {
    DlPaint dl_paint;
    paint.paint(dl_paint, kDrawDRRectFlags);
    builder()->DrawDRRect(outer.sk_rrect, inner.sk_rrect, dl_paint);
  }
}

void Canvas::drawOval(double left,
                      double top,
                      double right,
                      double bottom,
                      Dart_Handle paint_objects,
                      Dart_Handle paint_data) {
  Paint paint(paint_objects, paint_data);

  FML_DCHECK(paint.isNotNull());
  if (display_list_builder_) {
    DlPaint dl_paint;
    paint.paint(dl_paint, kDrawOvalFlags);
    builder()->DrawOval(SkRect::MakeLTRB(left, top, right, bottom), dl_paint);
  }
}

void Canvas::drawCircle(double x,
                        double y,
                        double radius,
                        Dart_Handle paint_objects,
                        Dart_Handle paint_data) {
  Paint paint(paint_objects, paint_data);

  FML_DCHECK(paint.isNotNull());
  if (display_list_builder_) {
    DlPaint dl_paint;
    paint.paint(dl_paint, kDrawCircleFlags);
    builder()->DrawCircle(SkPoint::Make(x, y), radius, dl_paint);
  }
}

void Canvas::drawArc(double left,
                     double top,
                     double right,
                     double bottom,
                     double startAngle,
                     double sweepAngle,
                     bool useCenter,
                     Dart_Handle paint_objects,
                     Dart_Handle paint_data) {
  Paint paint(paint_objects, paint_data);

  FML_DCHECK(paint.isNotNull());
  if (display_list_builder_) {
    DlPaint dl_paint;
    paint.paint(dl_paint, useCenter  //
                              ? kDrawArcWithCenterFlags
                              : kDrawArcNoCenterFlags);
    builder()->DrawArc(SkRect::MakeLTRB(left, top, right, bottom),
                       startAngle * 180.0 / M_PI, sweepAngle * 180.0 / M_PI,
                       useCenter, dl_paint);
  }
}

void Canvas::drawPath(const CanvasPath* path,
                      Dart_Handle paint_objects,
                      Dart_Handle paint_data) {
  Paint paint(paint_objects, paint_data);

  FML_DCHECK(paint.isNotNull());
  if (!path) {
    Dart_ThrowException(
        ToDart("Canvas.drawPath called with non-genuine Path."));
    return;
  }
  if (display_list_builder_) {
    DlPaint dl_paint;
    paint.paint(dl_paint, kDrawPathFlags);
    builder()->DrawPath(path->path(), dl_paint);
  }
}

Dart_Handle Canvas::drawImage(const CanvasImage* image,
                              double x,
                              double y,
                              Dart_Handle paint_objects,
                              Dart_Handle paint_data,
                              int filterQualityIndex) {
  Paint paint(paint_objects, paint_data);

  FML_DCHECK(paint.isNotNull());
  if (!image) {
    return ToDart("Canvas.drawImage called with non-genuine Image.");
  }

  auto dl_image = image->image();
  if (!dl_image) {
    return Dart_Null();
  }
  auto error = dl_image->get_error();
  if (error) {
    return ToDart(error.value());
  }

  auto sampling = ImageFilter::SamplingFromIndex(filterQualityIndex);
  if (display_list_builder_) {
    DlPaint dl_paint;
    const DlPaint* opt_paint = paint.paint(dl_paint, kDrawImageWithPaintFlags);
    builder()->DrawImage(dl_image, SkPoint::Make(x, y), sampling, opt_paint);
  }
  return Dart_Null();
}

Dart_Handle Canvas::drawImageRect(const CanvasImage* image,
                                  double src_left,
                                  double src_top,
                                  double src_right,
                                  double src_bottom,
                                  double dst_left,
                                  double dst_top,
                                  double dst_right,
                                  double dst_bottom,
                                  Dart_Handle paint_objects,
                                  Dart_Handle paint_data,
                                  int filterQualityIndex) {
  Paint paint(paint_objects, paint_data);

  FML_DCHECK(paint.isNotNull());
  if (!image) {
    return ToDart("Canvas.drawImageRect called with non-genuine Image.");
  }

  auto dl_image = image->image();
  if (!dl_image) {
    return Dart_Null();
  }
  auto error = dl_image->get_error();
  if (error) {
    return ToDart(error.value());
  }

  SkRect src = SkRect::MakeLTRB(src_left, src_top, src_right, src_bottom);
  SkRect dst = SkRect::MakeLTRB(dst_left, dst_top, dst_right, dst_bottom);
  auto sampling = ImageFilter::SamplingFromIndex(filterQualityIndex);
  if (display_list_builder_) {
    DlPaint dl_paint;
    const DlPaint* opt_paint =
        paint.paint(dl_paint, kDrawImageRectWithPaintFlags);
    builder()->DrawImageRect(dl_image, src, dst, sampling, opt_paint,
                             DlCanvas::SrcRectConstraint::kFast);
  }
  return Dart_Null();
}

Dart_Handle Canvas::drawImageNine(const CanvasImage* image,
                                  double center_left,
                                  double center_top,
                                  double center_right,
                                  double center_bottom,
                                  double dst_left,
                                  double dst_top,
                                  double dst_right,
                                  double dst_bottom,
                                  Dart_Handle paint_objects,
                                  Dart_Handle paint_data,
                                  int bitmapSamplingIndex) {
  Paint paint(paint_objects, paint_data);

  FML_DCHECK(paint.isNotNull());
  if (!image) {
    return ToDart("Canvas.drawImageNine called with non-genuine Image.");
  }
  auto dl_image = image->image();
  if (!dl_image) {
    return Dart_Null();
  }
  auto error = dl_image->get_error();
  if (error) {
    return ToDart(error.value());
  }

  SkRect center =
      SkRect::MakeLTRB(center_left, center_top, center_right, center_bottom);
  SkIRect icenter;
  center.round(&icenter);
  SkRect dst = SkRect::MakeLTRB(dst_left, dst_top, dst_right, dst_bottom);
  auto filter = ImageFilter::FilterModeFromIndex(bitmapSamplingIndex);
  if (display_list_builder_) {
    DlPaint dl_paint;
    const DlPaint* opt_paint =
        paint.paint(dl_paint, kDrawImageNineWithPaintFlags);
    builder()->DrawImageNine(dl_image, icenter, dst, filter, opt_paint);
  }
  return Dart_Null();
}

void Canvas::drawPicture(Picture* picture) {
  if (!picture) {
    Dart_ThrowException(
        ToDart("Canvas.drawPicture called with non-genuine Picture."));
    return;
  }
  if (picture->display_list()) {
    if (display_list_builder_) {
      builder()->DrawDisplayList(picture->display_list());
    }
  } else {
    FML_DCHECK(false);
  }
}

void Canvas::drawPoints(Dart_Handle paint_objects,
                        Dart_Handle paint_data,
                        DlCanvas::PointMode point_mode,
                        const tonic::Float32List& points) {
  Paint paint(paint_objects, paint_data);

  static_assert(sizeof(SkPoint) == sizeof(float) * 2,
                "SkPoint doesn't use floats.");

  FML_DCHECK(paint.isNotNull());
  if (display_list_builder_) {
    DlPaint dl_paint;
    switch (point_mode) {
      case DlCanvas::PointMode::kPoints:
        paint.paint(dl_paint, kDrawPointsAsPointsFlags);
        break;
      case DlCanvas::PointMode::kLines:
        paint.paint(dl_paint, kDrawPointsAsLinesFlags);
        break;
      case DlCanvas::PointMode::kPolygon:
        paint.paint(dl_paint, kDrawPointsAsPolygonFlags);
        break;
    }
    builder()->DrawPoints(point_mode,
                          points.num_elements() / 2,  // SkPoints have 2 floats
                          reinterpret_cast<const SkPoint*>(points.data()),
                          dl_paint);
  }
}

void Canvas::drawVertices(const Vertices* vertices,
                          DlBlendMode blend_mode,
                          Dart_Handle paint_objects,
                          Dart_Handle paint_data) {
  Paint paint(paint_objects, paint_data);

  if (!vertices) {
    Dart_ThrowException(
        ToDart("Canvas.drawVertices called with non-genuine Vertices."));
    return;
  }
  FML_DCHECK(paint.isNotNull());
  if (display_list_builder_) {
    DlPaint dl_paint;
    paint.paint(dl_paint, kDrawVerticesFlags);
    builder()->DrawVertices(vertices->vertices(), blend_mode, dl_paint);
  }
}

Dart_Handle Canvas::drawAtlas(Dart_Handle paint_objects,
                              Dart_Handle paint_data,
                              int filterQualityIndex,
                              CanvasImage* atlas,
                              Dart_Handle transforms_handle,
                              Dart_Handle rects_handle,
                              Dart_Handle colors_handle,
                              DlBlendMode blend_mode,
                              Dart_Handle cull_rect_handle) {
  Paint paint(paint_objects, paint_data);

  if (!atlas) {
    return ToDart(
        "Canvas.drawAtlas or Canvas.drawRawAtlas called with "
        "non-genuine Image.");
  }

  auto dl_image = atlas->image();
  auto error = dl_image->get_error();
  if (error) {
    return ToDart(error.value());
  }

  static_assert(sizeof(SkRSXform) == sizeof(float) * 4,
                "SkRSXform doesn't use floats.");
  static_assert(sizeof(SkRect) == sizeof(float) * 4,
                "SkRect doesn't use floats.");

  auto sampling = ImageFilter::SamplingFromIndex(filterQualityIndex);

  FML_DCHECK(paint.isNotNull());
  if (display_list_builder_) {
    tonic::Float32List transforms(transforms_handle);
    tonic::Float32List rects(rects_handle);
    tonic::Int32List colors(colors_handle);
    tonic::Float32List cull_rect(cull_rect_handle);

    DlPaint dl_paint;
    const DlPaint* opt_paint = paint.paint(dl_paint, kDrawAtlasWithPaintFlags);
    builder()->DrawAtlas(
        dl_image, reinterpret_cast<const SkRSXform*>(transforms.data()),
        reinterpret_cast<const SkRect*>(rects.data()),
        reinterpret_cast<const DlColor*>(colors.data()),
        rects.num_elements() / 4,  // SkRect have four floats.
        blend_mode, sampling, reinterpret_cast<const SkRect*>(cull_rect.data()),
        opt_paint);
  }
  return Dart_Null();
}

void Canvas::drawShadow(const CanvasPath* path,
                        SkColor color,
                        double elevation,
                        bool transparentOccluder) {
  if (!path) {
    Dart_ThrowException(
        ToDart("Canvas.drawShader called with non-genuine Path."));
    return;
  }
  SkScalar dpr = UIDartState::Current()
                     ->platform_configuration()
                     ->get_window(0)
                     ->viewport_metrics()
                     .device_pixel_ratio;
  if (display_list_builder_) {
    // The DrawShadow mechanism results in non-public operations to be
    // performed on the canvas involving an SkDrawShadowRec. Since we
    // cannot include the header that defines that structure, we cannot
    // record an operation that it injects into an SkCanvas. To prevent
    // that situation we bypass the canvas interface and inject the
    // shadow parameters directly into the underlying DisplayList.
    // See: https://bugs.chromium.org/p/skia/issues/detail?id=12125
    builder()->DrawShadow(path->path(), color, elevation, transparentOccluder,
                          dpr);
  }
}

void Canvas::Invalidate() {
  display_list_builder_ = nullptr;
  if (dart_wrapper()) {
    ClearDartWrapper();
  }
}

}  // namespace flutter

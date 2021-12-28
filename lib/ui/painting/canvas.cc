// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/canvas.h"
#include "flutter/lib/ui/painting/image_filter.h"

#include <cmath>

#include "flutter/display_list/display_list_builder.h"
#include "flutter/display_list/display_list_canvas_dispatcher.h"
#include "flutter/flow/layers/physical_shape_layer.h"
#include "flutter/lib/ui/painting/image.h"
#include "flutter/lib/ui/painting/matrix.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/lib/ui/window/platform_configuration.h"
#include "flutter/lib/ui/window/window.h"
#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkRSXform.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"

using tonic::ToDart;

namespace flutter {

static void Canvas_constructor(Dart_NativeArguments args) {
  UIDartState::ThrowIfUIOperationsProhibited();
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
  V(Canvas, drawAtlas)              \
  V(Canvas, drawShadow)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void Canvas::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({{"Canvas_constructor", Canvas_constructor, 6, true},
                     FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

fml::RefPtr<Canvas> Canvas::Create(PictureRecorder* recorder,
                                   double left,
                                   double top,
                                   double right,
                                   double bottom) {
  if (!recorder) {
    Dart_ThrowException(
        ToDart("Canvas constructor called with non-genuine PictureRecorder."));
    return nullptr;
  }

  // This call will implicitly initialize the |canvas_| field with an SkCanvas
  // whether or not we are using display_list. Now that all of the code here
  // in canvas.cc will direct calls to the DisplayListBuilder we could almost
  // stop initializing that field for the display list case. Unfortunately,
  // the text code in paragraph.cc still needs to present its output to an
  // SkCanvas* which means without significant work to the internals of the
  // paragraph code, we are going to continue to need the canvas adapter and
  // field and getter.
  fml::RefPtr<Canvas> canvas = fml::MakeRefCounted<Canvas>(
      recorder->BeginRecording(SkRect::MakeLTRB(left, top, right, bottom)));
  recorder->set_canvas(canvas);
  canvas->display_list_recorder_ = recorder->display_list_recorder();
  return canvas;
}

Canvas::Canvas(SkCanvas* canvas) : canvas_(canvas) {}

Canvas::~Canvas() {}

void Canvas::save() {
  if (display_list_recorder_) {
    builder()->save();
  } else if (canvas_) {
    canvas_->save();
  }
}

void Canvas::saveLayerWithoutBounds(const Paint& paint,
                                    const PaintData& paint_data) {
  FML_DCHECK(paint.isNotNull());
  if (display_list_recorder_) {
    bool restore_with_paint =
        paint.sync_to(builder(), kSaveLayerWithPaintFlags);
    FML_DCHECK(restore_with_paint);
    TRACE_EVENT0("flutter", "ui.Canvas::saveLayer (Recorded)");
    builder()->saveLayer(nullptr, restore_with_paint);
  } else if (canvas_) {
    SkPaint sk_paint;
    TRACE_EVENT0("flutter", "ui.Canvas::saveLayer (Recorded)");
    canvas_->saveLayer(nullptr, paint.paint(sk_paint));
  }
}

void Canvas::saveLayer(double left,
                       double top,
                       double right,
                       double bottom,
                       const Paint& paint,
                       const PaintData& paint_data) {
  FML_DCHECK(paint.isNotNull());
  SkRect bounds = SkRect::MakeLTRB(left, top, right, bottom);
  if (display_list_recorder_) {
    bool restore_with_paint =
        paint.sync_to(builder(), kSaveLayerWithPaintFlags);
    FML_DCHECK(restore_with_paint);
    TRACE_EVENT0("flutter", "ui.Canvas::saveLayer (Recorded)");
    builder()->saveLayer(&bounds, restore_with_paint);
  } else if (canvas_) {
    SkPaint sk_paint;
    TRACE_EVENT0("flutter", "ui.Canvas::saveLayer (Recorded)");
    canvas_->saveLayer(&bounds, paint.paint(sk_paint));
  }
}

void Canvas::restore() {
  if (display_list_recorder_) {
    builder()->restore();
  } else if (canvas_) {
    canvas_->restore();
  }
}

int Canvas::getSaveCount() {
  if (display_list_recorder_) {
    return builder()->getSaveCount();
  } else if (canvas_) {
    return canvas_->getSaveCount();
  } else {
    return 0;
  }
}

void Canvas::translate(double dx, double dy) {
  if (display_list_recorder_) {
    builder()->translate(dx, dy);
  } else if (canvas_) {
    canvas_->translate(dx, dy);
  }
}

void Canvas::scale(double sx, double sy) {
  if (display_list_recorder_) {
    builder()->scale(sx, sy);
  } else if (canvas_) {
    canvas_->scale(sx, sy);
  }
}

void Canvas::rotate(double radians) {
  if (display_list_recorder_) {
    builder()->rotate(radians * 180.0 / M_PI);
  } else if (canvas_) {
    canvas_->rotate(radians * 180.0 / M_PI);
  }
}

void Canvas::skew(double sx, double sy) {
  if (display_list_recorder_) {
    builder()->skew(sx, sy);
  } else if (canvas_) {
    canvas_->skew(sx, sy);
  }
}

void Canvas::transform(const tonic::Float64List& matrix4) {
  // The Float array stored by Dart Matrix4 is in column-major order
  // Both DisplayList and SkM44 constructor take row-major matrix order
  if (display_list_recorder_) {
    // clang-format off
    builder()->transformFullPerspective(
        matrix4[ 0], matrix4[ 4], matrix4[ 8], matrix4[12],
        matrix4[ 1], matrix4[ 5], matrix4[ 9], matrix4[13],
        matrix4[ 2], matrix4[ 6], matrix4[10], matrix4[14],
        matrix4[ 3], matrix4[ 7], matrix4[11], matrix4[15]);
    // clang-format on
  } else if (canvas_) {
    canvas_->concat(SkM44(matrix4[0], matrix4[4], matrix4[8], matrix4[12],
                          matrix4[1], matrix4[5], matrix4[9], matrix4[13],
                          matrix4[2], matrix4[6], matrix4[10], matrix4[14],
                          matrix4[3], matrix4[7], matrix4[11], matrix4[15]));
  }
}

void Canvas::clipRect(double left,
                      double top,
                      double right,
                      double bottom,
                      SkClipOp clipOp,
                      bool doAntiAlias) {
  if (display_list_recorder_) {
    builder()->clipRect(SkRect::MakeLTRB(left, top, right, bottom), clipOp,
                        doAntiAlias);
  } else if (canvas_) {
    canvas_->clipRect(SkRect::MakeLTRB(left, top, right, bottom), clipOp,
                      doAntiAlias);
  }
}

void Canvas::clipRRect(const RRect& rrect, bool doAntiAlias) {
  if (display_list_recorder_) {
    builder()->clipRRect(rrect.sk_rrect, SkClipOp::kIntersect, doAntiAlias);
  } else if (canvas_) {
    canvas_->clipRRect(rrect.sk_rrect, doAntiAlias);
  }
}

void Canvas::clipPath(const CanvasPath* path, bool doAntiAlias) {
  if (!path) {
    Dart_ThrowException(
        ToDart("Canvas.clipPath called with non-genuine Path."));
    return;
  }
  if (display_list_recorder_) {
    builder()->clipPath(path->path(), SkClipOp::kIntersect, doAntiAlias);
  } else if (canvas_) {
    canvas_->clipPath(path->path(), doAntiAlias);
  }
}

void Canvas::drawColor(SkColor color, SkBlendMode blend_mode) {
  if (display_list_recorder_) {
    builder()->drawColor(color, blend_mode);
  } else if (canvas_) {
    canvas_->drawColor(color, blend_mode);
  }
}

void Canvas::drawLine(double x1,
                      double y1,
                      double x2,
                      double y2,
                      const Paint& paint,
                      const PaintData& paint_data) {
  FML_DCHECK(paint.isNotNull());
  if (display_list_recorder_) {
    paint.sync_to(builder(), kDrawLineFlags);
    builder()->drawLine(SkPoint::Make(x1, y1), SkPoint::Make(x2, y2));
  } else if (canvas_) {
    SkPaint sk_paint;
    canvas_->drawLine(x1, y1, x2, y2, *paint.paint(sk_paint));
  }
}

void Canvas::drawPaint(const Paint& paint, const PaintData& paint_data) {
  FML_DCHECK(paint.isNotNull());
  if (display_list_recorder_) {
    paint.sync_to(builder(), kDrawPaintFlags);
    sk_sp<SkImageFilter> filter = builder()->getImageFilter();
    if (filter && !filter->asColorFilter(nullptr)) {
      // drawPaint does an implicit saveLayer if an SkImageFilter is
      // present that cannot be replaced by an SkColorFilter.
      TRACE_EVENT0("flutter", "ui.Canvas::saveLayer (Recorded)");
    }
    builder()->drawPaint();
  } else if (canvas_) {
    SkPaint sk_paint;
    paint.paint(sk_paint);
    SkImageFilter* filter = sk_paint.getImageFilter();
    if (filter && !filter->asColorFilter(nullptr)) {
      // drawPaint does an implicit saveLayer if an SkImageFilter is
      // present that cannot be replaced by an SkColorFilter.
      TRACE_EVENT0("flutter", "ui.Canvas::saveLayer (Recorded)");
    }
    canvas_->drawPaint(sk_paint);
  }
}

void Canvas::drawRect(double left,
                      double top,
                      double right,
                      double bottom,
                      const Paint& paint,
                      const PaintData& paint_data) {
  FML_DCHECK(paint.isNotNull());
  if (display_list_recorder_) {
    paint.sync_to(builder(), kDrawRectFlags);
    builder()->drawRect(SkRect::MakeLTRB(left, top, right, bottom));
  } else if (canvas_) {
    SkPaint sk_paint;
    canvas_->drawRect(SkRect::MakeLTRB(left, top, right, bottom),
                      *paint.paint(sk_paint));
  }
}

void Canvas::drawRRect(const RRect& rrect,
                       const Paint& paint,
                       const PaintData& paint_data) {
  FML_DCHECK(paint.isNotNull());
  if (display_list_recorder_) {
    paint.sync_to(builder(), kDrawRRectFlags);
    builder()->drawRRect(rrect.sk_rrect);
  } else if (canvas_) {
    SkPaint sk_paint;
    canvas_->drawRRect(rrect.sk_rrect, *paint.paint(sk_paint));
  }
}

void Canvas::drawDRRect(const RRect& outer,
                        const RRect& inner,
                        const Paint& paint,
                        const PaintData& paint_data) {
  FML_DCHECK(paint.isNotNull());
  if (display_list_recorder_) {
    paint.sync_to(builder(), kDrawDRRectFlags);
    builder()->drawDRRect(outer.sk_rrect, inner.sk_rrect);
  } else if (canvas_) {
    SkPaint sk_paint;
    canvas_->drawDRRect(outer.sk_rrect, inner.sk_rrect, *paint.paint(sk_paint));
  }
}

void Canvas::drawOval(double left,
                      double top,
                      double right,
                      double bottom,
                      const Paint& paint,
                      const PaintData& paint_data) {
  FML_DCHECK(paint.isNotNull());
  if (display_list_recorder_) {
    paint.sync_to(builder(), kDrawOvalFlags);
    builder()->drawOval(SkRect::MakeLTRB(left, top, right, bottom));
  } else if (canvas_) {
    SkPaint sk_paint;
    canvas_->drawOval(SkRect::MakeLTRB(left, top, right, bottom),
                      *paint.paint(sk_paint));
  }
}

void Canvas::drawCircle(double x,
                        double y,
                        double radius,
                        const Paint& paint,
                        const PaintData& paint_data) {
  FML_DCHECK(paint.isNotNull());
  if (display_list_recorder_) {
    paint.sync_to(builder(), kDrawCircleFlags);
    builder()->drawCircle(SkPoint::Make(x, y), radius);
  } else if (canvas_) {
    SkPaint sk_paint;
    canvas_->drawCircle(x, y, radius, *paint.paint(sk_paint));
  }
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
  FML_DCHECK(paint.isNotNull());
  if (display_list_recorder_) {
    paint.sync_to(builder(),
                  useCenter  //
                      ? kDrawArcWithCenterFlags
                      : kDrawArcNoCenterFlags);
    builder()->drawArc(SkRect::MakeLTRB(left, top, right, bottom),
                       startAngle * 180.0 / M_PI, sweepAngle * 180.0 / M_PI,
                       useCenter);
  } else if (canvas_) {
    SkPaint sk_paint;
    canvas_->drawArc(SkRect::MakeLTRB(left, top, right, bottom),
                     startAngle * 180.0 / M_PI, sweepAngle * 180.0 / M_PI,
                     useCenter, *paint.paint(sk_paint));
  }
}

void Canvas::drawPath(const CanvasPath* path,
                      const Paint& paint,
                      const PaintData& paint_data) {
  FML_DCHECK(paint.isNotNull());
  if (!path) {
    Dart_ThrowException(
        ToDart("Canvas.drawPath called with non-genuine Path."));
    return;
  }
  if (display_list_recorder_) {
    paint.sync_to(builder(), kDrawPathFlags);
    builder()->drawPath(path->path());
  } else if (canvas_) {
    SkPaint sk_paint;
    canvas_->drawPath(path->path(), *paint.paint(sk_paint));
  }
}

void Canvas::drawImage(const CanvasImage* image,
                       double x,
                       double y,
                       const Paint& paint,
                       const PaintData& paint_data,
                       int filterQualityIndex) {
  FML_DCHECK(paint.isNotNull());
  if (!image) {
    Dart_ThrowException(
        ToDart("Canvas.drawImage called with non-genuine Image."));
    return;
  }
  auto sampling = ImageFilter::SamplingFromIndex(filterQualityIndex);
  if (display_list_recorder_) {
    bool with_attributes = paint.sync_to(builder(), kDrawImageWithPaintFlags);
    builder()->drawImage(image->image(), SkPoint::Make(x, y), sampling,
                         with_attributes);
  } else if (canvas_) {
    SkPaint sk_paint;
    canvas_->drawImage(image->image(), x, y, sampling, paint.paint(sk_paint));
  }
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
                           const PaintData& paint_data,
                           int filterQualityIndex) {
  FML_DCHECK(paint.isNotNull());
  if (!image) {
    Dart_ThrowException(
        ToDart("Canvas.drawImageRect called with non-genuine Image."));
    return;
  }
  SkRect src = SkRect::MakeLTRB(src_left, src_top, src_right, src_bottom);
  SkRect dst = SkRect::MakeLTRB(dst_left, dst_top, dst_right, dst_bottom);
  auto sampling = ImageFilter::SamplingFromIndex(filterQualityIndex);
  if (display_list_recorder_) {
    bool with_attributes =
        paint.sync_to(builder(), kDrawImageRectWithPaintFlags);
    builder()->drawImageRect(image->image(), src, dst, sampling,
                             with_attributes,
                             SkCanvas::kFast_SrcRectConstraint);
  } else if (canvas_) {
    SkPaint sk_paint;
    canvas_->drawImageRect(image->image(), src, dst, sampling,
                           paint.paint(sk_paint),
                           SkCanvas::kFast_SrcRectConstraint);
  }
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
                           const PaintData& paint_data,
                           int bitmapSamplingIndex) {
  FML_DCHECK(paint.isNotNull());
  if (!image) {
    Dart_ThrowException(
        ToDart("Canvas.drawImageNine called with non-genuine Image."));
    return;
  }
  SkRect center =
      SkRect::MakeLTRB(center_left, center_top, center_right, center_bottom);
  SkIRect icenter;
  center.round(&icenter);
  SkRect dst = SkRect::MakeLTRB(dst_left, dst_top, dst_right, dst_bottom);
  auto filter = ImageFilter::FilterModeFromIndex(bitmapSamplingIndex);
  if (display_list_recorder_) {
    bool with_attributes =
        paint.sync_to(builder(), kDrawImageNineWithPaintFlags);
    builder()->drawImageNine(image->image(), icenter, dst, filter,
                             with_attributes);
  } else if (canvas_) {
    SkPaint sk_paint;
    canvas_->drawImageNine(image->image().get(), icenter, dst, filter,
                           paint.paint(sk_paint));
  }
}

void Canvas::drawPicture(Picture* picture) {
  if (!picture) {
    Dart_ThrowException(
        ToDart("Canvas.drawPicture called with non-genuine Picture."));
    return;
  }
  if (picture->picture()) {
    if (display_list_recorder_) {
      builder()->drawPicture(picture->picture(), nullptr, false);
    } else if (canvas_) {
      canvas_->drawPicture(picture->picture().get());
    }
  } else if (picture->display_list()) {
    if (display_list_recorder_) {
      builder()->drawDisplayList(picture->display_list());
    } else if (canvas_) {
      picture->display_list()->RenderTo(canvas_);
    }
  } else {
    FML_DCHECK(false);
  }
}

void Canvas::drawPoints(const Paint& paint,
                        const PaintData& paint_data,
                        SkCanvas::PointMode point_mode,
                        const tonic::Float32List& points) {
  static_assert(sizeof(SkPoint) == sizeof(float) * 2,
                "SkPoint doesn't use floats.");

  FML_DCHECK(paint.isNotNull());
  if (display_list_recorder_) {
    switch (point_mode) {
      case SkCanvas::kPoints_PointMode:
        paint.sync_to(builder(), kDrawPointsAsPointsFlags);
        break;
      case SkCanvas::kLines_PointMode:
        paint.sync_to(builder(), kDrawPointsAsLinesFlags);
        break;
      case SkCanvas::kPolygon_PointMode:
        paint.sync_to(builder(), kDrawPointsAsPolygonFlags);
        break;
    }
    builder()->drawPoints(point_mode,
                          points.num_elements() / 2,  // SkPoints have 2 floats
                          reinterpret_cast<const SkPoint*>(points.data()));
  } else if (canvas_) {
    SkPaint sk_paint;
    canvas_->drawPoints(point_mode,
                        points.num_elements() / 2,  // SkPoints have 2 floats
                        reinterpret_cast<const SkPoint*>(points.data()),
                        *paint.paint(sk_paint));
  }
}

void Canvas::drawVertices(const Vertices* vertices,
                          SkBlendMode blend_mode,
                          const Paint& paint,
                          const PaintData& paint_data) {
  if (!vertices) {
    Dart_ThrowException(
        ToDart("Canvas.drawVertices called with non-genuine Vertices."));
    return;
  }
  FML_DCHECK(paint.isNotNull());
  if (display_list_recorder_) {
    paint.sync_to(builder(), kDrawVerticesFlags);
    builder()->drawVertices(vertices->vertices(), blend_mode);
  } else if (canvas_) {
    SkPaint sk_paint;
    canvas_->drawVertices(vertices->vertices(), blend_mode,
                          *paint.paint(sk_paint));
  }
}

void Canvas::drawAtlas(const Paint& paint,
                       const PaintData& paint_data,
                       int filterQualityIndex,
                       CanvasImage* atlas,
                       const tonic::Float32List& transforms,
                       const tonic::Float32List& rects,
                       const tonic::Int32List& colors,
                       SkBlendMode blend_mode,
                       const tonic::Float32List& cull_rect) {
  if (!atlas) {
    Dart_ThrowException(
        ToDart("Canvas.drawAtlas or Canvas.drawRawAtlas called with "
               "non-genuine Image."));
    return;
  }

  sk_sp<SkImage> skImage = atlas->image();

  static_assert(sizeof(SkRSXform) == sizeof(float) * 4,
                "SkRSXform doesn't use floats.");
  static_assert(sizeof(SkRect) == sizeof(float) * 4,
                "SkRect doesn't use floats.");

  auto sampling = ImageFilter::SamplingFromIndex(filterQualityIndex);

  FML_DCHECK(paint.isNotNull());
  if (display_list_recorder_) {
    bool with_attributes = paint.sync_to(builder(), kDrawAtlasWithPaintFlags);
    builder()->drawAtlas(
        skImage, reinterpret_cast<const SkRSXform*>(transforms.data()),
        reinterpret_cast<const SkRect*>(rects.data()),
        reinterpret_cast<const SkColor*>(colors.data()),
        rects.num_elements() / 4,  // SkRect have four floats.
        blend_mode, sampling, reinterpret_cast<const SkRect*>(cull_rect.data()),
        with_attributes);
  } else if (canvas_) {
    SkPaint sk_paint;
    canvas_->drawAtlas(
        skImage.get(), reinterpret_cast<const SkRSXform*>(transforms.data()),
        reinterpret_cast<const SkRect*>(rects.data()),
        reinterpret_cast<const SkColor*>(colors.data()),
        rects.num_elements() / 4,  // SkRect have four floats.
        blend_mode, sampling, reinterpret_cast<const SkRect*>(cull_rect.data()),
        paint.paint(sk_paint));
  }
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
  if (display_list_recorder_) {
    // The DrawShadow mechanism results in non-public operations to be
    // performed on the canvas involving an SkDrawShadowRec. Since we
    // cannot include the header that defines that structure, we cannot
    // record an operation that it injects into an SkCanvas. To prevent
    // that situation we bypass the canvas interface and inject the
    // shadow parameters directly into the underlying DisplayList.
    // See: https://bugs.chromium.org/p/skia/issues/detail?id=12125
    builder()->drawShadow(path->path(), color, elevation, transparentOccluder,
                          dpr);
  } else if (canvas_) {
    DisplayListCanvasDispatcher::DrawShadow(
        canvas_, path->path(), color, elevation, transparentOccluder, dpr);
  }
}

void Canvas::Invalidate() {
  canvas_ = nullptr;
  display_list_recorder_ = nullptr;
  if (dart_wrapper()) {
    ClearDartWrapper();
  }
}

}  // namespace flutter

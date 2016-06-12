// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "math.h"

#include "sky/engine/core/painting/Canvas.h"

#include "flutter/tonic/dart_args.h"
#include "flutter/tonic/dart_binding_macros.h"
#include "flutter/tonic/dart_converter.h"
#include "flutter/tonic/dart_library_natives.h"
#include "sky/engine/core/painting/CanvasImage.h"
#include "sky/engine/core/painting/Matrix.h"
#include "sky/engine/core/text/Paragraph.h"
#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace blink {

static void Canvas_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&Canvas::create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, Canvas);

#define FOR_EACH_BINDING(V) \
  V(Canvas, save) \
  V(Canvas, saveLayerWithoutBounds) \
  V(Canvas, saveLayer) \
  V(Canvas, restore) \
  V(Canvas, getSaveCount) \
  V(Canvas, translate) \
  V(Canvas, scale) \
  V(Canvas, rotate) \
  V(Canvas, skew) \
  V(Canvas, transform) \
  V(Canvas, setMatrix) \
  V(Canvas, clipRect) \
  V(Canvas, clipRRect) \
  V(Canvas, clipPath) \
  V(Canvas, drawColor) \
  V(Canvas, drawLine) \
  V(Canvas, drawPaint) \
  V(Canvas, drawRect) \
  V(Canvas, drawRRect) \
  V(Canvas, drawDRRect) \
  V(Canvas, drawOval) \
  V(Canvas, drawCircle) \
  V(Canvas, drawPath) \
  V(Canvas, drawImage) \
  V(Canvas, drawImageRect) \
  V(Canvas, drawImageNine) \
  V(Canvas, drawPicture) \
  V(Canvas, drawParagraph) \
  V(Canvas, drawVertices) \
  V(Canvas, drawAtlas)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void Canvas::RegisterNatives(DartLibraryNatives* natives) {
  natives->Register({
    { "Canvas_constructor", Canvas_constructor, 6, true },
FOR_EACH_BINDING(DART_REGISTER_NATIVE)
  });
}

scoped_refptr<Canvas> Canvas::create(PictureRecorder* recorder,
                                     double left,
                                     double top,
                                     double right,
                                     double bottom) {
    DCHECK(recorder);
    DCHECK(!recorder->isRecording());
    scoped_refptr<Canvas> canvas = new Canvas(recorder->beginRecording(
        SkRect::MakeLTRB(left, top, right, bottom)));
    recorder->set_canvas(canvas.get());
    return canvas;
}

Canvas::Canvas(SkCanvas* skCanvas)
    : m_canvas(skCanvas)
{
}

Canvas::~Canvas()
{
}

void Canvas::save()
{
    if (!m_canvas)
        return;
    m_canvas->save();
}

void Canvas::saveLayerWithoutBounds(const Paint& paint) {
    if (!m_canvas)
        return;
    m_canvas->saveLayer(nullptr, paint.paint());
}

void Canvas::saveLayer(double left,
                       double top,
                       double right,
                       double bottom,
                       const Paint& paint)
{
    if (!m_canvas)
        return;
    SkRect bounds = SkRect::MakeLTRB(left, top, right, bottom);
    m_canvas->saveLayer(&bounds, paint.paint());
}

void Canvas::restore()
{
    if (!m_canvas)
        return;
    m_canvas->restore();
}

int Canvas::getSaveCount()
{
    if (!m_canvas)
        return 0;
    return m_canvas->getSaveCount();
}

void Canvas::translate(double dx, double dy)
{
    if (!m_canvas)
        return;
    m_canvas->translate(dx, dy);
}

void Canvas::scale(double sx, double sy)
{
    if (!m_canvas)
        return;
    m_canvas->scale(sx, sy);
}

void Canvas::rotate(double radians)
{
    if (!m_canvas)
        return;
    m_canvas->rotate(radians * 180.0/M_PI);
}

void Canvas::skew(double sx, double sy)
{
    if (!m_canvas)
        return;
    m_canvas->skew(sx, sy);
}

void Canvas::transform(const Float64List& matrix4)
{
    if (!m_canvas)
        return;
    m_canvas->concat(toSkMatrix(matrix4));
}

void Canvas::setMatrix(const Float64List& matrix4)
{
    if (!m_canvas)
        return;
    m_canvas->setMatrix(toSkMatrix(matrix4));
}

void Canvas::clipRect(double left,
                      double top,
                      double right,
                      double bottom)
{
    if (!m_canvas)
        return;
    m_canvas->clipRect(SkRect::MakeLTRB(left, top, right, bottom));
}

void Canvas::clipRRect(const RRect& rrect)
{
    if (!m_canvas)
        return;
    m_canvas->clipRRect(rrect.sk_rrect, SkRegion::kIntersect_Op);
}

void Canvas::clipPath(const CanvasPath* path)
{
    if (!m_canvas)
        return;
    m_canvas->clipPath(path->path(), SkRegion::kIntersect_Op);
}

void Canvas::drawColor(int color, int transferMode)
{
    if (!m_canvas)
        return;
    m_canvas->drawColor(static_cast<SkColor>(color),
                        static_cast<SkXfermode::Mode>(transferMode));
}

void Canvas::drawLine(double x1, double y1, double x2, double y2, const Paint& paint)
{
    if (!m_canvas)
        return;
    m_canvas->drawLine(x1, y1, x2, y2, paint.sk_paint);
}

void Canvas::drawPaint(const Paint& paint)
{
    if (!m_canvas)
        return;
    m_canvas->drawPaint(paint.sk_paint);
}

void Canvas::drawRect(double left,
                      double top,
                      double right,
                      double bottom,
                      const Paint& paint)
{
    if (!m_canvas)
        return;
    m_canvas->drawRect(SkRect::MakeLTRB(left, top, right, bottom), paint.sk_paint);
}

void Canvas::drawRRect(const RRect& rrect, const Paint& paint)
{
    if (!m_canvas)
        return;
    m_canvas->drawRRect(rrect.sk_rrect, paint.sk_paint);
}

void Canvas::drawDRRect(const RRect& outer, const RRect& inner, const Paint& paint)
{
    if (!m_canvas)
        return;
    m_canvas->drawDRRect(outer.sk_rrect, inner.sk_rrect, paint.sk_paint);
}

void Canvas::drawOval(double left,
                      double top,
                      double right,
                      double bottom,
                      const Paint& paint)
{
    if (!m_canvas)
        return;
    m_canvas->drawOval(SkRect::MakeLTRB(left, top, right, bottom), paint.sk_paint);
}

void Canvas::drawCircle(double x, double y, double radius, const Paint& paint)
{
    if (!m_canvas)
        return;
    m_canvas->drawCircle(x, y, radius, paint.sk_paint);
}

void Canvas::drawPath(const CanvasPath* path, const Paint& paint)
{
    if (!m_canvas)
        return;
    DCHECK(path);
    m_canvas->drawPath(path->path(), paint.sk_paint);
}

void Canvas::drawImage(const CanvasImage* image, double x, double y, const Paint& paint) {
    if (!m_canvas)
        return;
    DCHECK(image);
    m_canvas->drawImage(image->image(), x, y, paint.paint());
}

void Canvas::drawImageRect(const CanvasImage* image,
                           double srcLeft,
                           double srcTop,
                           double srcRight,
                           double srcBottom,
                           double dstLeft,
                           double dstTop,
                           double dstRight,
                           double dstBottom,
                           const Paint& paint) {
    if (!m_canvas)
        return;
    DCHECK(image);
    m_canvas->drawImageRect(image->image(),
                            SkRect::MakeLTRB(srcLeft, srcTop, srcRight, srcBottom),
                            SkRect::MakeLTRB(dstLeft, dstTop, dstRight, dstBottom),
                            paint.paint(),
                            SkCanvas::kFast_SrcRectConstraint);
}

void Canvas::drawImageNine(const CanvasImage* image,
                           double centerLeft,
                           double centerTop,
                           double centerRight,
                           double centerBottom,
                           double dstLeft,
                           double dstTop,
                           double dstRight,
                           double dstBottom,
                           const Paint& paint) {
    if (!m_canvas)
        return;
    DCHECK(image);
    SkRect center = SkRect::MakeLTRB(centerLeft, centerTop, centerRight, centerBottom);
    SkIRect icenter;
    center.round(&icenter);
    m_canvas->drawImageNine(image->image(),
                            icenter,
                            SkRect::MakeLTRB(dstLeft, dstTop, dstRight, dstBottom),
                            paint.paint());
}

void Canvas::drawPicture(Picture* picture)
{
    if (!m_canvas)
        return;
    DCHECK(picture);
    m_canvas->drawPicture(picture->toSkia().get());
}

void Canvas::drawParagraph(Paragraph* paragraph, double x, double y) {
    if (!m_canvas)
        return;
    DCHECK(paragraph);
    paragraph->paint(this, x, y);
}

void Canvas::drawVertices(
    SkCanvas::VertexMode vertexMode,
    const Float32List& vertices,
    const Float32List& textureCoordinates,
    const Int32List& colors,
    int transferMode,
    const Int32List& indices,
    const Paint& paint) {
  if (!m_canvas)
    return;

  sk_sp<SkXfermode> transferModePtr = SkXfermode::Make(
    static_cast<SkXfermode::Mode>(transferMode));

  std::vector<uint16_t> indices16;
  indices16.reserve(indices.num_elements());
  for (int i = 0; i < indices.num_elements(); ++i)
    indices16.push_back(indices.data()[i]);

  static_assert(sizeof(SkPoint) == sizeof(float) * 2, "SkPoint doesn't use floats.");
  static_assert(sizeof(SkColor) == sizeof(int32_t), "SkColor doesn't use int32_t.");

  m_canvas->drawVertices(
    vertexMode,
    vertices.num_elements(),
    reinterpret_cast<const SkPoint*>(vertices.data()),
    reinterpret_cast<const SkPoint*>(textureCoordinates.data()),
    reinterpret_cast<const SkColor*>(colors.data()),
    transferModePtr.get(),
    indices16.empty() ? nullptr : indices16.data(),
    indices16.size(),
    *paint.paint()
  );
}

void Canvas::drawAtlas(
    CanvasImage* atlas,
    const Float32List& transforms,
    const Float32List& rects,
    const Int32List& colors,
    int transferMode,
    const Float32List& cullRect,
    const Paint& paint) {
  if (!m_canvas)
    return;

  sk_sp<SkImage> skImage = atlas->image();

  static_assert(sizeof(SkRSXform) == sizeof(float) * 4, "SkRSXform doesn't use floats.");
  static_assert(sizeof(SkRect) == sizeof(float) * 4, "SkRect doesn't use floats.");

  m_canvas->drawAtlas(
    skImage.get(),
    reinterpret_cast<const SkRSXform*>(transforms.data()),
    reinterpret_cast<const SkRect*>(rects.data()),
    reinterpret_cast<const SkColor*>(colors.data()),
    rects.num_elements(),
    static_cast<SkXfermode::Mode>(transferMode),
    reinterpret_cast<const SkRect*>(cullRect.data()),
    paint.paint()
  );
}

} // namespace blink

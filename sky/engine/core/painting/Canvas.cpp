// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "math.h"

#include "sky/engine/core/painting/Canvas.h"

#include "sky/engine/core/painting/CanvasImage.h"
#include "sky/engine/core/painting/Matrix.h"
#include "sky/engine/platform/geometry/IntRect.h"
#include "sky/engine/tonic/dart_args.h"
#include "sky/engine/tonic/dart_binding_macros.h"
#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/tonic/dart_library_natives.h"
#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace blink {

static void Canvas_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&Canvas::create, args);
}

static void Canvas_concat(Dart_NativeArguments args) {
  DartArgIterator it(args);
  Float64List matrix4 = it.GetNext<Float64List>();
  if (it.had_exception())
    return;
  ExceptionState es;
  GetReceiver<Canvas>(args)->concat(matrix4, es);
  if (es.had_exception())
    Dart_ThrowException(es.GetDartException(args, true));
}

static void Canvas_setMatrix(Dart_NativeArguments args) {
  DartArgIterator it(args);
  Float64List matrix4 = it.GetNext<Float64List>();
  if (it.had_exception())
    return;
  ExceptionState es;
  GetReceiver<Canvas>(args)->setMatrix(matrix4, es);
  if (es.had_exception())
    Dart_ThrowException(es.GetDartException(args, true));
}

IMPLEMENT_WRAPPERTYPEINFO(Canvas);

#define FOR_EACH_BINDING(V) \
  V(Canvas, save) \
  V(Canvas, saveLayer) \
  V(Canvas, restore) \
  V(Canvas, getSaveCount) \
  V(Canvas, translate) \
  V(Canvas, scale) \
  V(Canvas, rotate) \
  V(Canvas, skew) \
  V(Canvas, getTotalMatrix) \
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
  V(Canvas, drawVertices) \
  V(Canvas, drawAtlas)

  // These are custom because of ExceptionState:
  // V(Canvas, concat)
  // V(Canvas, setMatrix)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void Canvas::RegisterNatives(DartLibraryNatives* natives) {
  natives->Register({
    { "Canvas_constructor", Canvas_constructor, 3, true },
    { "Canvas_concat", Canvas_concat, 2, true },
    { "Canvas_setMatrix", Canvas_setMatrix, 2, true },
FOR_EACH_BINDING(DART_REGISTER_NATIVE)
  });
}

PassRefPtr<Canvas> Canvas::create(PictureRecorder* recorder,
                                  Rect& bounds) {
    ASSERT(recorder);
    ASSERT(!recorder->isRecording());
    PassRefPtr<Canvas> canvas = adoptRef(new Canvas(recorder->beginRecording(bounds)));
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

void Canvas::saveLayer(const Rect& bounds, const Paint& paint)
{
    if (!m_canvas)
        return;
    m_canvas->saveLayer(!bounds.is_null ? &bounds.sk_rect : nullptr,
                        paint.paint());
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

void Canvas::translate(float dx, float dy)
{
    if (!m_canvas)
        return;
    m_canvas->translate(dx, dy);
}

void Canvas::scale(float sx, float sy)
{
    if (!m_canvas)
        return;
    m_canvas->scale(sx, sy);
}

void Canvas::rotate(float radians)
{
    if (!m_canvas)
        return;
    m_canvas->rotate(radians * 180.0/M_PI);
}

void Canvas::skew(float sx, float sy)
{
    if (!m_canvas)
        return;
    m_canvas->skew(sx, sy);
}

void Canvas::concat(const Float64List& matrix4, ExceptionState& es)
{
    if (!m_canvas)
        return es.ThrowTypeError("No canvas");

    SkMatrix sk_matrix = toSkMatrix(matrix4, es);
    if (es.had_exception())
        return;
    m_canvas->concat(sk_matrix);
}

void Canvas::setMatrix(const Float64List& matrix4, ExceptionState& es)
{
    if (!m_canvas)
        return es.ThrowTypeError("No canvas");

    SkMatrix sk_matrix = toSkMatrix(matrix4, es);
    if (es.had_exception())
        return;
    m_canvas->setMatrix(sk_matrix);
}

Float64List Canvas::getTotalMatrix()
{
    // Maybe we should throw an exception instead of returning an empty matrix?
    SkMatrix sk_matrix;
    if (m_canvas)
        sk_matrix = m_canvas->getTotalMatrix();
    return toMatrix4(sk_matrix);
}

void Canvas::clipRect(const Rect& rect)
{
    if (!m_canvas)
        return;
    m_canvas->clipRect(rect.sk_rect);
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

void Canvas::drawColor(CanvasColor color, TransferMode transferMode)
{
    if (!m_canvas)
        return;
    m_canvas->drawColor(color, transferMode);
}

void Canvas::drawLine(const Point& p1, const Point& p2, const Paint& paint)
{
    if (!m_canvas)
        return;
    m_canvas->drawLine(p1.sk_point.x(), p1.sk_point.y(), p2.sk_point.x(), p2.sk_point.y(), paint.sk_paint);
}

void Canvas::drawPaint(const Paint& paint)
{
    if (!m_canvas)
        return;
    m_canvas->drawPaint(paint.sk_paint);
}

void Canvas::drawRect(const Rect& rect, const Paint& paint)
{
    if (!m_canvas)
        return;
    m_canvas->drawRect(rect.sk_rect, paint.sk_paint);
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

void Canvas::drawOval(const Rect& rect, const Paint& paint)
{
    if (!m_canvas)
        return;
    m_canvas->drawOval(rect.sk_rect, paint.sk_paint);
}

void Canvas::drawCircle(const Point& c, float radius, const Paint& paint)
{
    if (!m_canvas)
        return;
    m_canvas->drawCircle(c.sk_point.x(), c.sk_point.y(), radius, paint.sk_paint);
}

void Canvas::drawPath(const CanvasPath* path, const Paint& paint)
{
    if (!m_canvas)
        return;
    ASSERT(path);
    m_canvas->drawPath(path->path(), paint.sk_paint);
}

void Canvas::drawImage(const CanvasImage* image, const Point& p, const Paint& paint) {
    if (!m_canvas)
        return;
    ASSERT(image);
    m_canvas->drawImage(image->image(), p.sk_point.x(), p.sk_point.y(), paint.paint());
}

void Canvas::drawImageRect(const CanvasImage* image, Rect& src, Rect& dst, const Paint& paint) {
    if (!m_canvas)
        return;
    ASSERT(image);
    m_canvas->drawImageRect(image->image(), src.sk_rect, dst.sk_rect, paint.paint());
}

void Canvas::drawImageNine(const CanvasImage* image, Rect& center, Rect& dst, const Paint& paint) {
    if (!m_canvas)
        return;
    ASSERT(image);
    SkIRect icenter;
    center.sk_rect.round(&icenter);
    m_canvas->drawImageNine(image->image(), icenter, dst.sk_rect, paint.paint());
}

void Canvas::drawPicture(Picture* picture)
{
    if (!m_canvas)
        return;
    ASSERT(picture);
    m_canvas->drawPicture(picture->toSkia());
}

void Canvas::drawVertices(SkCanvas::VertexMode vertexMode,
        const Vector<Point>& vertices,
        const Vector<Point>& textureCoordinates,
        const Vector<SkColor>& colors,
        TransferMode transferMode,
        const Vector<int>& indices,
        const Paint& paint)
{
  if (!m_canvas)
    return;

  Vector<SkPoint> skVertices;
  skVertices.reserveInitialCapacity(vertices.size());
  for (const Point& point : vertices)
    skVertices.append(point.sk_point);

  Vector<SkPoint> skTextureCoordinates;
  skVertices.reserveInitialCapacity(textureCoordinates.size());
  for (const Point& point : textureCoordinates)
    skTextureCoordinates.append(point.sk_point);

  Vector<uint16_t> skIndices;
  skIndices.reserveInitialCapacity(indices.size());
  for (uint16_t i : indices)
    skIndices.append(i);

  RefPtr<SkXfermode> transferModePtr = adoptRef(SkXfermode::Create(transferMode));

  m_canvas->drawVertices(
    vertexMode,
    skVertices.size(),
    skVertices.data(),
    skTextureCoordinates.isEmpty() ? nullptr : skTextureCoordinates.data(),
    colors.isEmpty() ? nullptr : colors.data(),
    transferModePtr.get(),
    skIndices.isEmpty() ? nullptr : skIndices.data(),
    skIndices.size(),
    *paint.paint()
  );
}

void Canvas::drawAtlas(CanvasImage* atlas,
    const Vector<RSTransform>& transforms, const Vector<Rect>& rects,
    const Vector<SkColor>& colors, TransferMode mode,
    const Rect& cullRect, const Paint& paint)
{
  if (!m_canvas)
    return;

  RefPtr<SkImage> skImage = atlas->image();

  Vector<SkRSXform> skXForms;
  skXForms.reserveInitialCapacity(transforms.size());
  for (const RSTransform& transform : transforms)
    skXForms.append(transform.sk_xform);

  Vector<SkRect> skRects;
  skRects.reserveInitialCapacity(rects.size());
  for (const Rect& rect : rects)
    skRects.append(rect.sk_rect);

  m_canvas->drawAtlas(
      skImage.get(),
      skXForms.data(),
      skRects.data(),
      colors.isEmpty() ? nullptr : colors.data(),
      skXForms.size(),
      mode,
      cullRect.is_null ? nullptr : &cullRect.sk_rect,
      paint.paint()
  );
}

} // namespace blink

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "math.h"

#include "sky/engine/core/painting/Canvas.h"

#include "sky/engine/core/painting/CanvasImage.h"
#include "sky/engine/core/painting/Matrix.h"
#include "sky/engine/core/text/Paragraph.h"
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

PassRefPtr<Canvas> Canvas::create(PictureRecorder* recorder,
                                  double left,
                                  double top,
                                  double right,
                                  double bottom) {
    ASSERT(recorder);
    ASSERT(!recorder->isRecording());
    PassRefPtr<Canvas> canvas = adoptRef(new Canvas(recorder->beginRecording(
        SkRect::MakeLTRB(left, top, right, bottom))));
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

Float64List Canvas::getTotalMatrix()
{
    // Maybe we should throw an exception instead of returning an empty matrix?
    SkMatrix sk_matrix;
    if (m_canvas)
        sk_matrix = m_canvas->getTotalMatrix();
    return toMatrix4(sk_matrix);
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
    ASSERT(path);
    m_canvas->drawPath(path->path(), paint.sk_paint);
}

void Canvas::drawImage(const CanvasImage* image, double x, double y, const Paint& paint) {
    if (!m_canvas)
        return;
    ASSERT(image);
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
    ASSERT(image);
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
    ASSERT(image);
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
    ASSERT(picture);
    m_canvas->drawPicture(picture->toSkia().get());
}

void Canvas::drawParagraph(Paragraph* paragraph, double x, double y) {
    if (!m_canvas)
        return;
    ASSERT(paragraph);
    paragraph->paint(this, x, y);
}

void Canvas::drawVertices(SkCanvas::VertexMode vertexMode,
        const std::vector<Point>& vertices,
        const std::vector<Point>& textureCoordinates,
        const std::vector<CanvasColor>& colors,
        TransferMode transferMode,
        const std::vector<int>& indices,
        const Paint& paint)
{
  if (!m_canvas)
    return;

  std::vector<SkPoint> skVertices;
  skVertices.reserve(vertices.size());
  for (const Point& point : vertices)
    skVertices.push_back(point.sk_point);

  std::vector<SkPoint> skTextureCoordinates;
  skVertices.reserve(textureCoordinates.size());
  for (const Point& point : textureCoordinates)
    skTextureCoordinates.push_back(point.sk_point);

  std::vector<SkColor> skColors;
  skColors.reserve(colors.size());
  for (const CanvasColor& color : colors)
    skColors.push_back(color);

  std::vector<uint16_t> skIndices;
  skIndices.reserve(indices.size());
  for (uint16_t i : indices)
    skIndices.push_back(i);

  sk_sp<SkXfermode> transferModePtr = SkXfermode::Make(transferMode);

  m_canvas->drawVertices(
    vertexMode,
    skVertices.size(),
    skVertices.data(),
    skTextureCoordinates.empty() ? nullptr : skTextureCoordinates.data(),
    skColors.empty() ? nullptr : skColors.data(),
    transferModePtr.get(),
    skIndices.empty() ? nullptr : skIndices.data(),
    skIndices.size(),
    *paint.paint()
  );
}

void Canvas::drawAtlas(CanvasImage* atlas,
    const std::vector<RSTransform>& transforms, const std::vector<Rect>& rects,
    const std::vector<CanvasColor>& colors, TransferMode mode,
    const Rect& cullRect, const Paint& paint)
{
  if (!m_canvas)
    return;

  sk_sp<SkImage> skImage = atlas->image();

  std::vector<SkRSXform> skXForms;
  skXForms.reserve(transforms.size());
  for (const RSTransform& transform : transforms)
    skXForms.push_back(transform.sk_xform);

  std::vector<SkRect> skRects;
  skRects.reserve(rects.size());
  for (const Rect& rect : rects)
    skRects.push_back(rect.sk_rect);

  std::vector<SkColor> skColors;
  skColors.reserve(colors.size());
  for (const CanvasColor& color : colors)
    skColors.push_back(color);

  m_canvas->drawAtlas(
      skImage.get(),
      skXForms.data(),
      skRects.data(),
      skColors.empty() ? nullptr : skColors.data(),
      skXForms.size(),
      mode,
      cullRect.is_null ? nullptr : &cullRect.sk_rect,
      paint.paint()
  );
}

} // namespace blink

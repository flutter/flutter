// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_CANVAS_H_
#define SKY_ENGINE_CORE_PAINTING_CANVAS_H_

#include "base/memory/ref_counted.h"
#include "flutter/tonic/dart_wrappable.h"
#include "flutter/tonic/float32_list.h"
#include "flutter/tonic/float64_list.h"
#include "flutter/tonic/int32_list.h"
#include "sky/engine/core/painting/CanvasPath.h"
#include "sky/engine/core/painting/Paint.h"
#include "sky/engine/core/painting/Picture.h"
#include "sky/engine/core/painting/PictureRecorder.h"
#include "sky/engine/core/painting/RRect.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace blink {
class CanvasImage;
class DartLibraryNatives;
class Paragraph;

template <>
struct DartConverter<SkCanvas::PointMode> : public DartConverterInteger<SkCanvas::PointMode> {};

template <>
struct DartConverter<SkCanvas::VertexMode> : public DartConverterInteger<SkCanvas::VertexMode> {};

class Canvas : public base::RefCountedThreadSafe<Canvas>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static scoped_refptr<Canvas> create(PictureRecorder* recorder,
                                        double left,
                                        double top,
                                        double right,
                                        double bottom);

    ~Canvas() override;

    void save();
    void saveLayerWithoutBounds(const Paint& paint);
    void saveLayer(double left,
                   double top,
                   double right,
                   double bottom,
                   const Paint& paint);
    void restore();
    int getSaveCount();

    void translate(double dx, double dy);
    void scale(double sx, double sy);
    void rotate(double radians);
    void skew(double sx, double sy);
    void transform(const Float64List& matrix4);
    void setMatrix(const Float64List& matrix4);

    void clipRect(double left,
                  double top,
                  double right,
                  double bottom);
    void clipRRect(const RRect& rrect);
    void clipPath(const CanvasPath* path);

    void drawColor(int color, int transferMode);
    void drawLine(double x1, double y1, double x2, double y2, const Paint& paint);
    void drawPaint(const Paint& paint);
    void drawRect(double left,
                  double top,
                  double right,
                  double bottom,
                  const Paint& paint);
    void drawRRect(const RRect& rrect, const Paint& paint);
    void drawDRRect(const RRect& outer, const RRect& inner, const Paint& paint);
    void drawOval(double left,
                  double top,
                  double right,
                  double bottom,
                  const Paint& paint);
    void drawCircle(double x, double y, double radius, const Paint& paint);
    void drawPath(const CanvasPath* path, const Paint& paint);
    void drawImage(const CanvasImage* image, double x, double y, const Paint& paint);
    void drawImageRect(const CanvasImage* image,
                       double srcLeft,
                       double srcTop,
                       double srcRight,
                       double srcBottom,
                       double dstLeft,
                       double dstTop,
                       double dstRight,
                       double dstBottom,
                       const Paint& paint);
    void drawImageNine(const CanvasImage* image,
                       double centerLeft,
                       double centerTop,
                       double centerRight,
                       double centerBottom,
                       double dstLeft,
                       double dstTop,
                       double dstRight,
                       double dstBottom,
                       const Paint& paint);
    void drawPicture(Picture* picture);
    void drawParagraph(Paragraph* paragraph, double x, double y);

    void drawPoints(SkCanvas::PointMode pointMode,
                    const Float32List& points,
                    const Paint& paint);

    void drawVertices(SkCanvas::VertexMode vertexMode,
                      const Float32List& vertices,
                      const Float32List& textureCoordinates,
                      const Int32List& colors,
                      int transferMode,
                      const Int32List& indices,
                      const Paint& paint);

    void drawAtlas(CanvasImage* atlas,
                   const Float32List& transforms,
                   const Float32List& rects,
                   const Int32List& colors,
                   int transferMode,
                   const Float32List& cullRect,
                   const Paint& paint);

    SkCanvas* skCanvas() { return m_canvas; }
    void clearSkCanvas() { m_canvas = nullptr; }
    bool isRecording() const { return !!m_canvas; }

  static void RegisterNatives(DartLibraryNatives* natives);

protected:
    explicit Canvas(SkCanvas* skCanvas);

private:
    // The SkCanvas is supplied by a call to SkPictureRecorder::beginRecording,
    // which does not transfer ownership.  For this reason, we hold a raw
    // pointer and manually set the SkCanvas to null in clearSkCanvas.
    SkCanvas* m_canvas;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_CANVAS_H_

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_CANVAS_H_
#define SKY_ENGINE_CORE_PAINTING_CANVAS_H_

#include "base/memory/ref_counted.h"
#include "flutter/lib/ui/painting/paint.h"
#include "flutter/lib/ui/painting/path.h"
#include "flutter/lib/ui/painting/picture.h"
#include "flutter/lib/ui/painting/rrect.h"
#include "flutter/tonic/dart_wrappable.h"
#include "flutter/tonic/float32_list.h"
#include "flutter/tonic/float64_list.h"
#include "flutter/tonic/int32_list.h"
#include "sky/engine/core/painting/PictureRecorder.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace blink {
class CanvasImage;
class DartLibraryNatives;
class Paragraph;

template <>
struct DartConverter<SkCanvas::PointMode>
    : public DartConverterInteger<SkCanvas::PointMode> {};

template <>
struct DartConverter<SkCanvas::VertexMode>
    : public DartConverterInteger<SkCanvas::VertexMode> {};

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
    void saveLayerWithoutBounds(const Paint& paint,
                                const PaintData& paint_data);
    void saveLayer(double left,
                   double top,
                   double right,
                   double bottom,
                   const Paint& paint,
                   const PaintData& paint_data);
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

    void drawColor(SkColor color, SkXfermode::Mode transferMode);
    void drawLine(double x1,
                  double y1,
                  double x2,
                  double y2,
                  const Paint& paint,
                  const PaintData& paint_data);
    void drawPaint(const Paint& paint,
                   const PaintData& paint_data);
    void drawRect(double left,
                  double top,
                  double right,
                  double bottom,
                  const Paint& paint,
                  const PaintData& paint_data);
    void drawRRect(const RRect& rrect,
                   const Paint& paint,
                   const PaintData& paint_data);
    void drawDRRect(const RRect& outer,
                    const RRect& inner,
                    const Paint& paint,
                    const PaintData& paint_data);
    void drawOval(double left,
                  double top,
                  double right,
                  double bottom,
                  const Paint& paint,
                  const PaintData& paint_data);
    void drawCircle(double x,
                    double y,
                    double radius,
                    const Paint& paint,
                    const PaintData& paint_data);
    void drawPath(const CanvasPath* path,
                  const Paint& paint,
                  const PaintData& paint_data);
    void drawImage(const CanvasImage* image,
                   double x,
                   double y,
                   const Paint& paint,
                   const PaintData& paint_data);
    void drawImageRect(const CanvasImage* image,
                       double srcLeft,
                       double srcTop,
                       double srcRight,
                       double srcBottom,
                       double dstLeft,
                       double dstTop,
                       double dstRight,
                       double dstBottom,
                       const Paint& paint,
                       const PaintData& paint_data);
    void drawImageNine(const CanvasImage* image,
                       double centerLeft,
                       double centerTop,
                       double centerRight,
                       double centerBottom,
                       double dstLeft,
                       double dstTop,
                       double dstRight,
                       double dstBottom,
                       const Paint& paint,
                       const PaintData& paint_data);
    void drawPicture(Picture* picture);
    void drawParagraph(Paragraph* paragraph, double x, double y);

    // The paint argument is first for the following functions because Paint
    // unwraps a number of C++ objects. Once we create a view unto a
    // Float32List, we cannot re-enter the VM to unwrap objects. That means we
    // either need to process the paint argument first.

    void drawPoints(const Paint& paint,
                    const PaintData& paint_data,
                    SkCanvas::PointMode pointMode,
                    const Float32List& points);

    void drawVertices(const Paint& paint,
                      const PaintData& paint_data,
                      SkCanvas::VertexMode vertexMode,
                      const Float32List& vertices,
                      const Float32List& textureCoordinates,
                      const Int32List& colors,
                      SkXfermode::Mode transferMode,
                      const Int32List& indices);

    void drawAtlas(const Paint& paint,
                   const PaintData& paint_data,
                   CanvasImage* atlas,
                   const Float32List& transforms,
                   const Float32List& rects,
                   const Int32List& colors,
                   SkXfermode::Mode transferMode,
                   const Float32List& cullRect);

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

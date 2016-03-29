// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_CANVAS_H_
#define SKY_ENGINE_CORE_PAINTING_CANVAS_H_

#include "sky/engine/bindings/exception_state.h"
#include "sky/engine/core/painting/CanvasPath.h"
#include "sky/engine/core/painting/Offset.h"
#include "sky/engine/core/painting/Paint.h"
#include "sky/engine/core/painting/Picture.h"
#include "sky/engine/core/painting/PictureRecorder.h"
#include "sky/engine/core/painting/Point.h"
#include "sky/engine/core/painting/RRect.h"
#include "sky/engine/core/painting/Rect.h"
#include "sky/engine/core/painting/RSTransform.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/tonic/float64_list.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/ThreadSafeRefCounted.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace blink {
class CanvasImage;
class DartLibraryNatives;
class Paragraph;

template <>
struct DartConverter<SkCanvas::VertexMode> : public DartConverterInteger<SkCanvas::VertexMode> {};

class Canvas : public ThreadSafeRefCounted<Canvas>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<Canvas> create(PictureRecorder* recorder, Rect& bounds);

    ~Canvas() override;

    void save();
    void saveLayer(const Rect& bounds, const Paint& paint);
    void restore();
    int getSaveCount();

    void translate(float dx, float dy);
    void scale(float sx, float sy);
    void rotate(float radians);
    void skew(float sx, float sy);
    void transform(const Float64List& matrix4);
    void setMatrix(const Float64List& matrix4);

    Float64List getTotalMatrix();

    void clipRect(const Rect& rect);
    void clipRRect(const RRect& rrect);
    void clipPath(const CanvasPath* path);

    void drawColor(CanvasColor color, TransferMode transferMode);
    void drawLine(const Point& p1, const Point& p2, const Paint& paint);
    void drawPaint(const Paint& paint);
    void drawRect(const Rect& rect, const Paint& paint);
    void drawRRect(const RRect& rrect, const Paint& paint);
    void drawDRRect(const RRect& outer, const RRect& inner, const Paint& paint);
    void drawOval(const Rect& rect, const Paint& paint);
    void drawCircle(const Point& c, float radius, const Paint& paint);
    void drawPath(const CanvasPath* path, const Paint& paint);
    void drawImage(const CanvasImage* image, const Point& p, const Paint& paint);
    void drawImageRect(const CanvasImage* image, Rect& src, Rect& dst, const Paint& paint);
    void drawImageNine(const CanvasImage* image, Rect& center, Rect& dst, const Paint& paint);
    void drawPicture(Picture* picture);
    void drawParagraph(Paragraph* paragraph, const Offset& offset);

    void drawVertices(SkCanvas::VertexMode vertexMode,
        const std::vector<Point>& vertices,
        const std::vector<Point>& textureCoordinates,
        const std::vector<CanvasColor>& colors,
        TransferMode transferMode,
        const std::vector<int>& indices,
        const Paint& paint);

    void drawAtlas(CanvasImage* atlas,
        const std::vector<RSTransform>& transforms,
        const std::vector<Rect>& rects,
        const std::vector<CanvasColor>& colors,
        TransferMode mode,
        const Rect& cullRect, const Paint& paint);

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

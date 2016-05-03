// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_PATH_H_
#define SKY_ENGINE_CORE_PAINTING_PATH_H_

#include "math.h"

#include "sky/engine/core/painting/Offset.h"
#include "sky/engine/core/painting/Point.h"
#include "sky/engine/core/painting/RRect.h"
#include "sky/engine/core/painting/Rect.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/ThreadSafeRefCounted.h"
#include "third_party/skia/include/core/SkPath.h"

// Note: There's a very similar class in ../../platform/graphics/Path.h
// We should probably rationalise these two.
// (The existence of that class is why this is CanvasPath and not just Path.)

// The Dart side of this is in ../dart/painting.dart

namespace blink {
class DartLibraryNatives;

class CanvasPath : public ThreadSafeRefCounted<CanvasPath>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    ~CanvasPath() override;
    static PassRefPtr<CanvasPath> create()
    {
        return adoptRef(new CanvasPath);
    }

    void moveTo(float x, float y) { m_path.moveTo(x, y); }
    void relativeMoveTo(float x, float y) { m_path.rMoveTo(x, y); }
    void lineTo(float x, float y) { m_path.lineTo(x, y); }
    void relativeLineTo(float x, float y) { m_path.rLineTo(x, y); }
    void quadraticBezierTo(float x1, float y1, float x2, float y2) { m_path.quadTo(x1, y1, x2, y2); }
    void relativeQuadraticBezierTo(float x1, float y1, float x2, float y2) { m_path.rQuadTo(x1, y1, x2, y2); }
    void cubicTo(float x1, float y1, float x2, float y2, float x3, float y3) { m_path.cubicTo(x1, y1, x2, y2, x3, y3); }
    void relativeCubicTo(float x1, float y1, float x2, float y2, float x3, float y3) { m_path.rCubicTo(x1, y1, x2, y2, x3, y3); }
    void conicTo(float x1, float y1, float x2, float y2, float w) { m_path.conicTo(x1, y1, x2, y2, w); }
    void relativeConicTo(float x1, float y1, float x2, float y2, float w) { m_path.rConicTo(x1, y1, x2, y2, w); }
    void arcTo(const Rect& rect, float startAngle, float sweepAngle, bool forceMoveTo) {
        m_path.arcTo(rect.sk_rect, startAngle*180.0/M_PI, sweepAngle*180.0/M_PI, forceMoveTo);
    }
    void addRect(const Rect& rect) { m_path.addRect(rect.sk_rect); }
    void addOval(const Rect& oval) { m_path.addOval(oval.sk_rect); }
    void addArc(const Rect& rect, float startAngle, float sweepAngle) {
        m_path.addArc(rect.sk_rect, startAngle*180.0/M_PI, sweepAngle*180.0/M_PI);
    }
    void addRRect(const RRect& rrect) { m_path.addRRect(rrect.sk_rrect); }

    void close()
    {
        m_path.close();
    }

    void reset()
    {
        m_path.reset();
    }

    bool contains(const Point& point) { return m_path.contains(point.sk_point.x(), point.sk_point.y()); }

    const SkPath& path() const { return m_path; }

    PassRefPtr<CanvasPath> shift(const Offset& offset);

    static void RegisterNatives(DartLibraryNatives* natives);

private:
    CanvasPath();

    SkPath m_path;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_PATH_H_

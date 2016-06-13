// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_PATH_H_
#define SKY_ENGINE_CORE_PAINTING_PATH_H_

#include "math.h"

#include "base/memory/ref_counted.h"
#include "flutter/tonic/dart_wrappable.h"
#include "flutter/tonic/float32_list.h"
#include "flutter/tonic/float64_list.h"
#include "sky/engine/core/painting/RRect.h"
#include "third_party/skia/include/core/SkPath.h"

// Note: There's a very similar class in ../../platform/graphics/Path.h
// We should probably rationalise these two.
// (The existence of that class is why this is CanvasPath and not just Path.)

// The Dart side of this is in ../dart/painting.dart

namespace blink {
class DartLibraryNatives;

class CanvasPath : public base::RefCountedThreadSafe<CanvasPath>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    ~CanvasPath() override;
    static scoped_refptr<CanvasPath> create() { return new CanvasPath(); }

    int getFillType() { return m_path.getFillType(); }
    void setFillType(int fill_type) { m_path.setFillType(static_cast<SkPath::FillType>(fill_type)); }

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
    void arcTo(float left, float top, float right, float bottom, float startAngle, float sweepAngle, bool forceMoveTo) {
        m_path.arcTo(SkRect::MakeLTRB(left, top, right, bottom), startAngle*180.0/M_PI, sweepAngle*180.0/M_PI, forceMoveTo);
    }
    void addRect(float left, float top, float right, float bottom) { m_path.addRect(SkRect::MakeLTRB(left, top, right, bottom)); }
    void addOval(float left, float top, float right, float bottom) { m_path.addOval(SkRect::MakeLTRB(left, top, right, bottom)); }
    void addArc(float left, float top, float right, float bottom, float startAngle, float sweepAngle) {
        m_path.addArc(SkRect::MakeLTRB(left, top, right, bottom), startAngle*180.0/M_PI, sweepAngle*180.0/M_PI);
    }
    void addPolygon(const Float32List& points, bool close) {
        m_path.addPoly(reinterpret_cast<const SkPoint*>(points.data()), points.num_elements() / 2, close);
    }
    void addRRect(const RRect& rrect) { m_path.addRRect(rrect.sk_rrect); }
    void addPath(CanvasPath* path, double dx, double dy) {
      if (path)
        m_path.addPath(path->path(), dx, dy, SkPath::kAppend_AddPathMode);
    }
    void extendWithPath(CanvasPath* path, double dx, double dy) {
      if (path)
        m_path.addPath(path->path(), dx, dy, SkPath::kExtend_AddPathMode);
    }
    void close() { m_path.close(); }
    void reset() { m_path.reset(); }
    bool contains(double x, double y) { return m_path.contains(x, y); }
    scoped_refptr<CanvasPath> shift(double dx, double dy);
    scoped_refptr<CanvasPath> transform(const Float64List& matrix4);

    const SkPath& path() const { return m_path; }

    static void RegisterNatives(DartLibraryNatives* natives);

private:
    CanvasPath();

    SkPath m_path;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_PATH_H_

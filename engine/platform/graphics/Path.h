/*
 * Copyright (C) 2003, 2006, 2009 Apple Inc. All rights reserved.
 *               2006 Rob Buis <buis@kde.org>
 * Copyright (C) 2007-2008 Torch Mobile, Inc.
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef Path_h
#define Path_h

#include "platform/PlatformExport.h"
#include "platform/geometry/RoundedRect.h"
#include "platform/graphics/GraphicsTypes.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkPathMeasure.h"
#include "wtf/FastAllocBase.h"
#include "wtf/Forward.h"

class SkPath;

namespace blink {

class AffineTransform;
class FloatPoint;
class FloatRect;
class FloatSize;
class StrokeData;

enum PathElementType {
    PathElementMoveToPoint, // The points member will contain 1 value.
    PathElementAddLineToPoint, // The points member will contain 1 value.
    PathElementAddQuadCurveToPoint, // The points member will contain 2 values.
    PathElementAddCurveToPoint, // The points member will contain 3 values.
    PathElementCloseSubpath // The points member will contain no values.
};

// The points in the structure are the same as those that would be used with the
// add... method. For example, a line returns the endpoint, while a cubic returns
// two tangent points and the endpoint.
struct PathElement {
    PathElementType type;
    FloatPoint* points;
};

typedef void (*PathApplierFunction)(void* info, const PathElement*);

class PLATFORM_EXPORT Path {
    WTF_MAKE_FAST_ALLOCATED;
public:
    Path();
    ~Path();

    Path(const Path&);
    Path& operator=(const Path&);
    bool operator==(const Path&) const;

    bool contains(const FloatPoint&, WindRule = RULE_NONZERO) const;
    bool strokeContains(const FloatPoint&, const StrokeData&) const;
    FloatRect boundingRect() const;
    FloatRect strokeBoundingRect(const StrokeData&) const;

    float length() const;
    FloatPoint pointAtLength(float length, bool& ok) const;
    float normalAngleAtLength(float length, bool& ok) const;
    bool pointAndNormalAtLength(float length, FloatPoint&, float&) const;

    // Helper for computing a sequence of positions and normals (normal angles) on a path.
    // The best possible access pattern will be one where the |length| value is
    // strictly increasing.
    // For other access patterns, performance will vary depending on curvature
    // and number of segments, but should never be worse than that of the
    // state-less method on Path.
    class PLATFORM_EXPORT PositionCalculator {
        WTF_MAKE_NONCOPYABLE(PositionCalculator);
    public:
        explicit PositionCalculator(const Path&);

        bool pointAndNormalAtLength(float length, FloatPoint&, float&);

    private:
        SkPath m_path;
        SkPathMeasure m_pathMeasure;
        SkScalar m_accumulatedLength;
    };

    void clear();
    bool isEmpty() const;
    // Gets the current point of the current path, which is conceptually the final point reached by the path so far.
    // Note the Path can be empty (isEmpty() == true) and still have a current point.
    bool hasCurrentPoint() const;
    FloatPoint currentPoint() const;

    WindRule windRule() const;
    void setWindRule(const WindRule);

    void moveTo(const FloatPoint&);
    void addLineTo(const FloatPoint&);
    void addQuadCurveTo(const FloatPoint& controlPoint, const FloatPoint& endPoint);
    void addBezierCurveTo(const FloatPoint& controlPoint1, const FloatPoint& controlPoint2, const FloatPoint& endPoint);
    void addArcTo(const FloatPoint&, const FloatPoint&, float radius);
    void closeSubpath();

    void addArc(const FloatPoint&, float radius, float startAngle, float endAngle, bool anticlockwise);
    void addRect(const FloatRect&);
    void addEllipse(const FloatPoint&, float radiusX, float radiusY, float rotation, float startAngle, float endAngle, bool anticlockwise);
    void addEllipse(const FloatRect&);

    void addRoundedRect(const FloatRect&, const FloatSize& roundingRadii);
    void addRoundedRect(const FloatRect&, const FloatSize& topLeftRadius, const FloatSize& topRightRadius, const FloatSize& bottomLeftRadius, const FloatSize& bottomRightRadius);
    void addRoundedRect(const RoundedRect&);

    void addPath(const Path&, const AffineTransform&);

    void translate(const FloatSize&);

    const SkPath& skPath() const { return m_path; }

    void apply(void* info, PathApplierFunction) const;
    void transform(const AffineTransform&);

    void addPathForRoundedRect(const FloatRect&, const FloatSize& topLeftRadius, const FloatSize& topRightRadius, const FloatSize& bottomLeftRadius, const FloatSize& bottomRightRadius);
    void addBeziersForRoundedRect(const FloatRect&, const FloatSize& topLeftRadius, const FloatSize& topRightRadius, const FloatSize& bottomLeftRadius, const FloatSize& bottomRightRadius);

    bool subtractPath(const Path&);
    bool intersectPath(const Path&);

    // Updates the path to the union (inclusive-or) of itself with the given argument.
    bool unionPath(const Path& other);

private:
    void addEllipse(const FloatPoint&, float radiusX, float radiusY, float startAngle, float endAngle, bool anticlockwise);

    SkPath m_path;
};

#if ENABLE(ASSERT)
PLATFORM_EXPORT bool ellipseIsRenderable(float startAngle, float endAngle);
#endif

} // namespace blink

#endif

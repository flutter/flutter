/*
 * Copyright (C) 2003, 2006 Apple Computer, Inc.  All rights reserved.
 *                     2006 Rob Buis <buis@kde.org>
 * Copyright (C) 2007 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2013 Google Inc. All rights reserved.
 * Copyright (C) 2013 Intel Corporation. All rights reserved.
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

#include "config.h"
#include "platform/graphics/Path.h"

#include <math.h>
#include "platform/geometry/FloatPoint.h"
#include "platform/geometry/FloatRect.h"
#include "platform/graphics/GraphicsContext.h"
#include "platform/graphics/skia/SkiaUtils.h"
#include "platform/transforms/AffineTransform.h"
#include "third_party/skia/include/pathops/SkPathOps.h"
#include "wtf/MathExtras.h"

namespace blink {

Path::Path()
    : m_path()
{
}

Path::Path(const Path& other)
{
    m_path = SkPath(other.m_path);
}

Path::~Path()
{
}

Path& Path::operator=(const Path& other)
{
    m_path = SkPath(other.m_path);
    return *this;
}

bool Path::operator==(const Path& other) const
{
    return m_path == other.m_path;
}

bool Path::contains(const FloatPoint& point, WindRule rule) const
{
    return SkPathContainsPoint(m_path, point, static_cast<SkPath::FillType>(rule));
}

bool Path::strokeContains(const FloatPoint& point, const StrokeData& strokeData) const
{
    SkPaint paint;
    strokeData.setupPaint(&paint);
    SkPath strokePath;
    paint.getFillPath(m_path, &strokePath);

    return SkPathContainsPoint(strokePath, point, SkPath::kWinding_FillType);
}

FloatRect Path::boundingRect() const
{
    return m_path.getBounds();
}

FloatRect Path::strokeBoundingRect(const StrokeData& strokeData) const
{
    SkPaint paint;
    strokeData.setupPaint(&paint);
    SkPath boundingPath;
    paint.getFillPath(m_path, &boundingPath);

    return boundingPath.getBounds();
}

static FloatPoint* convertPathPoints(FloatPoint dst[], const SkPoint src[], int count)
{
    for (int i = 0; i < count; i++) {
        dst[i].setX(SkScalarToFloat(src[i].fX));
        dst[i].setY(SkScalarToFloat(src[i].fY));
    }
    return dst;
}

void Path::apply(void* info, PathApplierFunction function) const
{
    SkPath::RawIter iter(m_path);
    SkPoint pts[4];
    PathElement pathElement;
    FloatPoint pathPoints[3];

    for (;;) {
        switch (iter.next(pts)) {
        case SkPath::kMove_Verb:
            pathElement.type = PathElementMoveToPoint;
            pathElement.points = convertPathPoints(pathPoints, &pts[0], 1);
            break;
        case SkPath::kLine_Verb:
            pathElement.type = PathElementAddLineToPoint;
            pathElement.points = convertPathPoints(pathPoints, &pts[1], 1);
            break;
        case SkPath::kQuad_Verb:
            pathElement.type = PathElementAddQuadCurveToPoint;
            pathElement.points = convertPathPoints(pathPoints, &pts[1], 2);
            break;
        case SkPath::kCubic_Verb:
            pathElement.type = PathElementAddCurveToPoint;
            pathElement.points = convertPathPoints(pathPoints, &pts[1], 3);
            break;
        case SkPath::kClose_Verb:
            pathElement.type = PathElementCloseSubpath;
            pathElement.points = convertPathPoints(pathPoints, 0, 0);
            break;
        case SkPath::kDone_Verb:
            return;
        default: // place-holder for kConic_Verb, when that lands from skia
            break;
        }
        function(info, &pathElement);
    }
}

void Path::transform(const AffineTransform& xform)
{
    m_path.transform(affineTransformToSkMatrix(xform));
}

float Path::length() const
{
    SkScalar length = 0;
    SkPathMeasure measure(m_path, false);

    do {
        length += measure.getLength();
    } while (measure.nextContour());

    return SkScalarToFloat(length);
}

FloatPoint Path::pointAtLength(float length, bool& ok) const
{
    FloatPoint point;
    float normal;
    ok = pointAndNormalAtLength(length, point, normal);
    return point;
}

float Path::normalAngleAtLength(float length, bool& ok) const
{
    FloatPoint point;
    float normal;
    ok = pointAndNormalAtLength(length, point, normal);
    return normal;
}

static bool calculatePointAndNormalOnPath(SkPathMeasure& measure, SkScalar length, FloatPoint& point, float& normalAngle, SkScalar* accumulatedLength = 0)
{
    do {
        SkScalar contourLength = measure.getLength();
        if (length <= contourLength) {
            SkVector tangent;
            SkPoint position;

            if (measure.getPosTan(length, &position, &tangent)) {
                normalAngle = rad2deg(SkScalarToFloat(SkScalarATan2(tangent.fY, tangent.fX)));
                point = FloatPoint(SkScalarToFloat(position.fX), SkScalarToFloat(position.fY));
                return true;
            }
        }
        length -= contourLength;
        if (accumulatedLength)
            *accumulatedLength += contourLength;
    } while (measure.nextContour());
    return false;
}

bool Path::pointAndNormalAtLength(float length, FloatPoint& point, float& normal) const
{
    SkPathMeasure measure(m_path, false);

    if (calculatePointAndNormalOnPath(measure, WebCoreFloatToSkScalar(length), point, normal))
        return true;

    normal = 0;
    point = FloatPoint(0, 0);
    return false;
}

Path::PositionCalculator::PositionCalculator(const Path& path)
    : m_path(path.skPath())
    , m_pathMeasure(path.skPath(), false)
    , m_accumulatedLength(0)
{
}

bool Path::PositionCalculator::pointAndNormalAtLength(float length, FloatPoint& point, float& normalAngle)
{
    SkScalar skLength = WebCoreFloatToSkScalar(length);
    if (skLength >= 0) {
        if (skLength < m_accumulatedLength) {
            // Reset path measurer to rewind (and restart from 0).
            m_pathMeasure.setPath(&m_path, false);
            m_accumulatedLength = 0;
        } else {
            skLength -= m_accumulatedLength;
        }

        if (calculatePointAndNormalOnPath(m_pathMeasure, skLength, point, normalAngle, &m_accumulatedLength))
            return true;
    }

    normalAngle = 0;
    point = FloatPoint(0, 0);
    return false;
}

void Path::clear()
{
    m_path.reset();
}

bool Path::isEmpty() const
{
    return m_path.isEmpty();
}

bool Path::hasCurrentPoint() const
{
    return m_path.getPoints(0, 0);
}

FloatPoint Path::currentPoint() const
{
    if (m_path.countPoints() > 0) {
        SkPoint skResult;
        m_path.getLastPt(&skResult);
        FloatPoint result;
        result.setX(SkScalarToFloat(skResult.fX));
        result.setY(SkScalarToFloat(skResult.fY));
        return result;
    }

    // FIXME: Why does this return quietNaN? Other ports return 0,0.
    float quietNaN = std::numeric_limits<float>::quiet_NaN();
    return FloatPoint(quietNaN, quietNaN);
}

WindRule Path::windRule() const
{
    return m_path.getFillType() == SkPath::kEvenOdd_FillType
        ? RULE_EVENODD
        : RULE_NONZERO;
}

void Path::setWindRule(const WindRule rule)
{
    m_path.setFillType(WebCoreWindRuleToSkFillType(rule));
}

void Path::moveTo(const FloatPoint& point)
{
    m_path.moveTo(point.data());
}

void Path::addLineTo(const FloatPoint& point)
{
    m_path.lineTo(point.data());
}

void Path::addQuadCurveTo(const FloatPoint& cp, const FloatPoint& ep)
{
    m_path.quadTo(cp.data(), ep.data());
}

void Path::addBezierCurveTo(const FloatPoint& p1, const FloatPoint& p2, const FloatPoint& ep)
{
    m_path.cubicTo(p1.data(), p2.data(), ep.data());
}

void Path::addArcTo(const FloatPoint& p1, const FloatPoint& p2, float radius)
{
    m_path.arcTo(p1.data(), p2.data(), WebCoreFloatToSkScalar(radius));
}

void Path::closeSubpath()
{
    m_path.close();
}

void Path::addEllipse(const FloatPoint& p, float radiusX, float radiusY, float startAngle, float endAngle, bool anticlockwise)
{
    ASSERT(ellipseIsRenderable(startAngle, endAngle));
    ASSERT(startAngle >= 0 && startAngle < twoPiFloat);
    ASSERT((anticlockwise && (startAngle - endAngle) >= 0) || (!anticlockwise && (endAngle - startAngle) >= 0));

    SkScalar cx = WebCoreFloatToSkScalar(p.x());
    SkScalar cy = WebCoreFloatToSkScalar(p.y());
    SkScalar radiusXScalar = WebCoreFloatToSkScalar(radiusX);
    SkScalar radiusYScalar = WebCoreFloatToSkScalar(radiusY);

    SkRect oval;
    oval.set(cx - radiusXScalar, cy - radiusYScalar, cx + radiusXScalar, cy + radiusYScalar);

    float sweep = endAngle - startAngle;
    SkScalar startDegrees = WebCoreFloatToSkScalar(startAngle * 180 / piFloat);
    SkScalar sweepDegrees = WebCoreFloatToSkScalar(sweep * 180 / piFloat);
    SkScalar s360 = SkIntToScalar(360);

    // We can't use SkPath::addOval(), because addOval() makes new sub-path. addOval() calls moveTo() and close() internally.

    // Use s180, not s360, because SkPath::arcTo(oval, angle, s360, false) draws nothing.
    SkScalar s180 = SkIntToScalar(180);
    if (SkScalarNearlyEqual(sweepDegrees, s360)) {
        // SkPath::arcTo can't handle the sweepAngle that is equal to or greater than 2Pi.
        m_path.arcTo(oval, startDegrees, s180, false);
        m_path.arcTo(oval, startDegrees + s180, s180, false);
        return;
    }
    if (SkScalarNearlyEqual(sweepDegrees, -s360)) {
        m_path.arcTo(oval, startDegrees, -s180, false);
        m_path.arcTo(oval, startDegrees - s180, -s180, false);
        return;
    }

    m_path.arcTo(oval, startDegrees, sweepDegrees, false);
}

void Path::addArc(const FloatPoint& p, float radius, float startAngle, float endAngle, bool anticlockwise)
{
    addEllipse(p, radius, radius, startAngle, endAngle, anticlockwise);
}

void Path::addRect(const FloatRect& rect)
{
    m_path.addRect(rect);
}

void Path::addEllipse(const FloatPoint& p, float radiusX, float radiusY, float rotation, float startAngle, float endAngle, bool anticlockwise)
{
    ASSERT(ellipseIsRenderable(startAngle, endAngle));
    ASSERT(startAngle >= 0 && startAngle < twoPiFloat);
    ASSERT((anticlockwise && (startAngle - endAngle) >= 0) || (!anticlockwise && (endAngle - startAngle) >= 0));

    if (!rotation) {
        addEllipse(FloatPoint(p.x(), p.y()), radiusX, radiusY, startAngle, endAngle, anticlockwise);
        return;
    }

    // Add an arc after the relevant transform.
    AffineTransform ellipseTransform = AffineTransform::translation(p.x(), p.y()).rotateRadians(rotation);
    ASSERT(ellipseTransform.isInvertible());
    AffineTransform inverseEllipseTransform = ellipseTransform.inverse();
    transform(inverseEllipseTransform);
    addEllipse(FloatPoint::zero(), radiusX, radiusY, startAngle, endAngle, anticlockwise);
    transform(ellipseTransform);
}

void Path::addEllipse(const FloatRect& rect)
{
    m_path.addOval(rect);
}

void Path::addRoundedRect(const RoundedRect& r)
{
    addRoundedRect(r.rect(), r.radii().topLeft(), r.radii().topRight(), r.radii().bottomLeft(), r.radii().bottomRight());
}

void Path::addRoundedRect(const FloatRect& rect, const FloatSize& roundingRadii)
{
    if (rect.isEmpty())
        return;

    FloatSize radius(roundingRadii);
    FloatSize halfSize(rect.width() / 2, rect.height() / 2);

    // Apply the SVG corner radius constraints, per the rect section of the SVG shapes spec: if
    // one of rx,ry is negative, then the other corner radius value is used. If both values are
    // negative then rx = ry = 0. If rx is greater than half of the width of the rectangle
    // then set rx to half of the width; ry is handled similarly.

    if (radius.width() < 0)
        radius.setWidth((radius.height() < 0) ? 0 : radius.height());

    if (radius.height() < 0)
        radius.setHeight(radius.width());

    if (radius.width() > halfSize.width())
        radius.setWidth(halfSize.width());

    if (radius.height() > halfSize.height())
        radius.setHeight(halfSize.height());

    addPathForRoundedRect(rect, radius, radius, radius, radius);
}

void Path::addRoundedRect(const FloatRect& rect, const FloatSize& topLeftRadius, const FloatSize& topRightRadius, const FloatSize& bottomLeftRadius, const FloatSize& bottomRightRadius)
{
    if (rect.isEmpty())
        return;

    if (rect.width() < topLeftRadius.width() + topRightRadius.width()
            || rect.width() < bottomLeftRadius.width() + bottomRightRadius.width()
            || rect.height() < topLeftRadius.height() + bottomLeftRadius.height()
            || rect.height() < topRightRadius.height() + bottomRightRadius.height()) {
        // If all the radii cannot be accommodated, return a rect.
        addRect(rect);
        return;
    }

    addPathForRoundedRect(rect, topLeftRadius, topRightRadius, bottomLeftRadius, bottomRightRadius);
}

void Path::addPathForRoundedRect(const FloatRect& rect, const FloatSize& topLeftRadius, const FloatSize& topRightRadius, const FloatSize& bottomLeftRadius, const FloatSize& bottomRightRadius)
{
    addBeziersForRoundedRect(rect, topLeftRadius, topRightRadius, bottomLeftRadius, bottomRightRadius);
}

// Approximation of control point positions on a bezier to simulate a quarter of a circle.
// This is 1-kappa, where kappa = 4 * (sqrt(2) - 1) / 3
static const float gCircleControlPoint = 0.447715f;

void Path::addBeziersForRoundedRect(const FloatRect& rect, const FloatSize& topLeftRadius, const FloatSize& topRightRadius, const FloatSize& bottomLeftRadius, const FloatSize& bottomRightRadius)
{
    moveTo(FloatPoint(rect.x() + topLeftRadius.width(), rect.y()));

    addLineTo(FloatPoint(rect.maxX() - topRightRadius.width(), rect.y()));
    if (topRightRadius.width() > 0 || topRightRadius.height() > 0)
        addBezierCurveTo(FloatPoint(rect.maxX() - topRightRadius.width() * gCircleControlPoint, rect.y()),
            FloatPoint(rect.maxX(), rect.y() + topRightRadius.height() * gCircleControlPoint),
            FloatPoint(rect.maxX(), rect.y() + topRightRadius.height()));
    addLineTo(FloatPoint(rect.maxX(), rect.maxY() - bottomRightRadius.height()));
    if (bottomRightRadius.width() > 0 || bottomRightRadius.height() > 0)
        addBezierCurveTo(FloatPoint(rect.maxX(), rect.maxY() - bottomRightRadius.height() * gCircleControlPoint),
            FloatPoint(rect.maxX() - bottomRightRadius.width() * gCircleControlPoint, rect.maxY()),
            FloatPoint(rect.maxX() - bottomRightRadius.width(), rect.maxY()));
    addLineTo(FloatPoint(rect.x() + bottomLeftRadius.width(), rect.maxY()));
    if (bottomLeftRadius.width() > 0 || bottomLeftRadius.height() > 0)
        addBezierCurveTo(FloatPoint(rect.x() + bottomLeftRadius.width() * gCircleControlPoint, rect.maxY()),
            FloatPoint(rect.x(), rect.maxY() - bottomLeftRadius.height() * gCircleControlPoint),
            FloatPoint(rect.x(), rect.maxY() - bottomLeftRadius.height()));
    addLineTo(FloatPoint(rect.x(), rect.y() + topLeftRadius.height()));
    if (topLeftRadius.width() > 0 || topLeftRadius.height() > 0)
        addBezierCurveTo(FloatPoint(rect.x(), rect.y() + topLeftRadius.height() * gCircleControlPoint),
            FloatPoint(rect.x() + topLeftRadius.width() * gCircleControlPoint, rect.y()),
            FloatPoint(rect.x() + topLeftRadius.width(), rect.y()));

    closeSubpath();
}

void Path::addPath(const Path& src, const AffineTransform& transform)
{
    m_path.addPath(src.skPath(), affineTransformToSkMatrix(transform));
}

void Path::translate(const FloatSize& size)
{
    m_path.offset(WebCoreFloatToSkScalar(size.width()), WebCoreFloatToSkScalar(size.height()));
}

bool Path::subtractPath(const Path& other)
{
    return Op(m_path, other.m_path, kDifference_PathOp, &m_path);
}

bool Path::intersectPath(const Path& other)
{
    return Op(m_path, other.m_path, kIntersect_PathOp, &m_path);
}

bool Path::unionPath(const Path& other)
{
    return Op(m_path, other.m_path, kUnion_PathOp, &m_path);
}

#if ENABLE(ASSERT)
bool ellipseIsRenderable(float startAngle, float endAngle)
{
    return (std::abs(endAngle - startAngle) < twoPiFloat)
        || WebCoreFloatNearlyEqual(std::abs(endAngle - startAngle), twoPiFloat);
}
#endif

} // namespace blink

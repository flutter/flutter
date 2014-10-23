/*
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2008, 2010 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2007 Alp Toker <alp@atoker.com>
 * Copyright (C) 2008 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2008 Dirk Schulze <krit@webkit.org>
 * Copyright (C) 2010 Torch Mobile (Beijing) Co. Ltd. All rights reserved.
 * Copyright (C) 2012, 2013 Intel Corporation. All rights reserved.
 * Copyright (C) 2012, 2013 Adobe Systems Incorporated. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include "config.h"
#include "core/html/canvas/CanvasPathMethods.h"

#include "bindings/core/v8/ExceptionState.h"
#include "core/dom/ExceptionCode.h"
#include "platform/geometry/FloatRect.h"
#include "platform/transforms/AffineTransform.h"
#include "wtf/MathExtras.h"

namespace blink {

void CanvasPathMethods::closePath()
{
    if (m_path.isEmpty())
        return;

    FloatRect boundRect = m_path.boundingRect();
    if (boundRect.width() || boundRect.height())
        m_path.closeSubpath();
}

void CanvasPathMethods::moveTo(float x, float y)
{
    if (!std::isfinite(x) || !std::isfinite(y))
        return;
    if (!isTransformInvertible())
        return;
    m_path.moveTo(FloatPoint(x, y));
}

void CanvasPathMethods::lineTo(float x, float y)
{
    if (!std::isfinite(x) || !std::isfinite(y))
        return;
    if (!isTransformInvertible())
        return;

    FloatPoint p1 = FloatPoint(x, y);
    if (!m_path.hasCurrentPoint())
        m_path.moveTo(p1);
    else if (p1 != m_path.currentPoint())
        m_path.addLineTo(p1);
}

void CanvasPathMethods::quadraticCurveTo(float cpx, float cpy, float x, float y)
{
    if (!std::isfinite(cpx) || !std::isfinite(cpy) || !std::isfinite(x) || !std::isfinite(y))
        return;
    if (!isTransformInvertible())
        return;
    if (!m_path.hasCurrentPoint())
        m_path.moveTo(FloatPoint(cpx, cpy));

    FloatPoint p1 = FloatPoint(x, y);
    FloatPoint cp = FloatPoint(cpx, cpy);
    if (p1 != m_path.currentPoint() || p1 != cp)
        m_path.addQuadCurveTo(cp, p1);
}

void CanvasPathMethods::bezierCurveTo(float cp1x, float cp1y, float cp2x, float cp2y, float x, float y)
{
    if (!std::isfinite(cp1x) || !std::isfinite(cp1y) || !std::isfinite(cp2x) || !std::isfinite(cp2y) || !std::isfinite(x) || !std::isfinite(y))
        return;
    if (!isTransformInvertible())
        return;
    if (!m_path.hasCurrentPoint())
        m_path.moveTo(FloatPoint(cp1x, cp1y));

    FloatPoint p1 = FloatPoint(x, y);
    FloatPoint cp1 = FloatPoint(cp1x, cp1y);
    FloatPoint cp2 = FloatPoint(cp2x, cp2y);
    if (p1 != m_path.currentPoint() || p1 != cp1 ||  p1 != cp2)
        m_path.addBezierCurveTo(cp1, cp2, p1);
}

void CanvasPathMethods::arcTo(float x1, float y1, float x2, float y2, float r, ExceptionState& exceptionState)
{
    if (!std::isfinite(x1) || !std::isfinite(y1) || !std::isfinite(x2) || !std::isfinite(y2) || !std::isfinite(r))
        return;

    if (r < 0) {
        exceptionState.throwDOMException(IndexSizeError, "The radius provided (" + String::number(r) + ") is negative.");
        return;
    }

    if (!isTransformInvertible())
        return;

    FloatPoint p1 = FloatPoint(x1, y1);
    FloatPoint p2 = FloatPoint(x2, y2);

    if (!m_path.hasCurrentPoint())
        m_path.moveTo(p1);
    else if (p1 == m_path.currentPoint() || p1 == p2 || !r)
        lineTo(x1, y1);
    else
        m_path.addArcTo(p1, p2, r);
}

namespace {

float adjustEndAngle(float startAngle, float endAngle, bool anticlockwise)
{
    float newEndAngle = endAngle;
    /* http://www.whatwg.org/specs/web-apps/current-work/multipage/the-canvas-element.html#dom-context-2d-arc
     * If the anticlockwise argument is false and endAngle-startAngle is equal to or greater than 2pi, or,
     * if the anticlockwise argument is true and startAngle-endAngle is equal to or greater than 2pi,
     * then the arc is the whole circumference of this ellipse, and the point at startAngle along this circle's circumference,
     * measured in radians clockwise from the ellipse's semi-major axis, acts as both the start point and the end point.
     */
    if (!anticlockwise && endAngle - startAngle >= twoPiFloat)
        newEndAngle = startAngle + twoPiFloat;
    else if (anticlockwise && startAngle - endAngle >= twoPiFloat)
        newEndAngle = startAngle - twoPiFloat;

    /*
     * Otherwise, the arc is the path along the circumference of this ellipse from the start point to the end point,
     * going anti-clockwise if the anticlockwise argument is true, and clockwise otherwise.
     * Since the points are on the ellipse, as opposed to being simply angles from zero,
     * the arc can never cover an angle greater than 2pi radians.
     */
    /* NOTE: When startAngle = 0, endAngle = 2Pi and anticlockwise = true, the spec does not indicate clearly.
     * We draw the entire circle, because some web sites use arc(x, y, r, 0, 2*Math.PI, true) to draw circle.
     * We preserve backward-compatibility.
     */
    else if (!anticlockwise && startAngle > endAngle)
        newEndAngle = startAngle + (twoPiFloat - fmodf(startAngle - endAngle, twoPiFloat));
    else if (anticlockwise && startAngle < endAngle)
        newEndAngle = startAngle - (twoPiFloat - fmodf(endAngle - startAngle, twoPiFloat));

    ASSERT(ellipseIsRenderable(startAngle, newEndAngle));
    return newEndAngle;
}

inline void lineToFloatPoint(CanvasPathMethods* path, const FloatPoint& p)
{
    path->lineTo(p.x(), p.y());
}

inline FloatPoint getPointOnEllipse(float radiusX, float radiusY, float theta)
{
    return FloatPoint(radiusX * cosf(theta), radiusY * sinf(theta));
}

void canonicalizeAngle(float* startAngle, float* endAngle)
{
    // Make 0 <= startAngle < 2*PI
    float newStartAngle = *startAngle;
    if (newStartAngle < 0)
        newStartAngle = twoPiFloat + fmodf(newStartAngle, -twoPiFloat);
    else
        newStartAngle = fmodf(newStartAngle, twoPiFloat);

    float delta = newStartAngle - *startAngle;
    *startAngle = newStartAngle;
    *endAngle = *endAngle + delta;
    ASSERT(newStartAngle >= 0 && newStartAngle < twoPiFloat);
}

/*
 * degenerateEllipse() handles a degenerated ellipse using several lines.
 *
 * Let's see a following example: line to ellipse to line.
 *        _--^\
 *       (     )
 * -----(      )
 *            )
 *           /--------
 *
 * If radiusX becomes zero, the ellipse of the example is degenerated.
 *         _
 *        // P
 *       //
 * -----//
 *      /
 *     /--------
 *
 * To draw the above example, need to get P that is a local maximum point.
 * Angles for P are 0.5Pi and 1.5Pi in the ellipse coordinates.
 *
 * If radiusY becomes zero, the result is as follows.
 * -----__
 *        --_
 *          ----------
 *            ``P
 * Angles for P are 0 and Pi in the ellipse coordinates.
 *
 * To handle both cases, degenerateEllipse() lines to start angle, local maximum points(every 0.5Pi), and end angle.
 * NOTE: Before ellipse() calls this function, adjustEndAngle() is called, so endAngle - startAngle must be equal to or less than 2Pi.
 */
void degenerateEllipse(CanvasPathMethods* path, float x, float y, float radiusX, float radiusY, float rotation, float startAngle, float endAngle, bool anticlockwise)
{
    ASSERT(ellipseIsRenderable(startAngle, endAngle));
    ASSERT(startAngle >= 0 && startAngle < twoPiFloat);
    ASSERT((anticlockwise && (startAngle - endAngle) >= 0) || (!anticlockwise && (endAngle - startAngle) >= 0));

    FloatPoint center(x, y);
    AffineTransform rotationMatrix;
    rotationMatrix.rotateRadians(rotation);
    // First, if the object's path has any subpaths, then the method must add a straight line from the last point in the subpath to the start point of the arc.
    lineToFloatPoint(path, center + rotationMatrix.mapPoint(getPointOnEllipse(radiusX, radiusY, startAngle)));
    if ((!radiusX && !radiusY) || startAngle == endAngle)
        return;

    if (!anticlockwise) {
        // startAngle - fmodf(startAngle, piOverTwoFloat) + piOverTwoFloat is the one of (0, 0.5Pi, Pi, 1.5Pi, 2Pi)
        // that is the closest to startAngle on the clockwise direction.
        for (float angle = startAngle - fmodf(startAngle, piOverTwoFloat) + piOverTwoFloat; angle < endAngle; angle += piOverTwoFloat)
            lineToFloatPoint(path, center + rotationMatrix.mapPoint(getPointOnEllipse(radiusX, radiusY, angle)));
    } else {
        for (float angle = startAngle - fmodf(startAngle, piOverTwoFloat); angle > endAngle; angle -= piOverTwoFloat)
            lineToFloatPoint(path, center + rotationMatrix.mapPoint(getPointOnEllipse(radiusX, radiusY, angle)));
    }

    lineToFloatPoint(path, center + rotationMatrix.mapPoint(getPointOnEllipse(radiusX, radiusY, endAngle)));
}

} // namespace

void CanvasPathMethods::arc(float x, float y, float radius, float startAngle, float endAngle, bool anticlockwise, ExceptionState& exceptionState)
{
    if (!std::isfinite(x) || !std::isfinite(y) || !std::isfinite(radius) || !std::isfinite(startAngle) || !std::isfinite(endAngle))
        return;

    if (radius < 0) {
        exceptionState.throwDOMException(IndexSizeError, "The radius provided (" + String::number(radius) + ") is negative.");
        return;
    }

    if (!isTransformInvertible())
        return;

    if (!radius || startAngle == endAngle) {
        // The arc is empty but we still need to draw the connecting line.
        lineTo(x + radius * cosf(startAngle), y + radius * sinf(startAngle));
        return;
    }

    canonicalizeAngle(&startAngle, &endAngle);
    float adjustedEndAngle = adjustEndAngle(startAngle, endAngle, anticlockwise);
    m_path.addArc(FloatPoint(x, y), radius, startAngle, adjustedEndAngle, anticlockwise);
}

void CanvasPathMethods::ellipse(float x, float y, float radiusX, float radiusY, float rotation, float startAngle, float endAngle, bool anticlockwise, ExceptionState& exceptionState)
{
    if (!std::isfinite(x) || !std::isfinite(y) || !std::isfinite(radiusX) || !std::isfinite(radiusY) || !std::isfinite(rotation) || !std::isfinite(startAngle) || !std::isfinite(endAngle))
        return;

    if (radiusX < 0) {
        exceptionState.throwDOMException(IndexSizeError, "The major-axis radius provided (" + String::number(radiusX) + ") is negative.");
        return;
    }
    if (radiusY < 0) {
        exceptionState.throwDOMException(IndexSizeError, "The minor-axis radius provided (" + String::number(radiusY) + ") is negative.");
        return;
    }

    if (!isTransformInvertible())
        return;

    canonicalizeAngle(&startAngle, &endAngle);
    float adjustedEndAngle = adjustEndAngle(startAngle, endAngle, anticlockwise);
    if (!radiusX || !radiusY || startAngle == adjustedEndAngle) {
        // The ellipse is empty but we still need to draw the connecting line to start point.
        degenerateEllipse(this, x, y, radiusX, radiusY, rotation, startAngle, adjustedEndAngle, anticlockwise);
        return;
    }

    m_path.addEllipse(FloatPoint(x, y), radiusX, radiusY, rotation, startAngle, adjustedEndAngle, anticlockwise);
}

void CanvasPathMethods::rect(float x, float y, float width, float height)
{
    if (!isTransformInvertible())
        return;

    if (!std::isfinite(x) || !std::isfinite(y) || !std::isfinite(width) || !std::isfinite(height))
        return;

    if (!width && !height) {
        m_path.moveTo(FloatPoint(x, y));
        return;
    }

    m_path.addRect(FloatRect(x, y, width, height));
}
}

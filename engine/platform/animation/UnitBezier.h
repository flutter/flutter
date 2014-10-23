/*
 * Copyright (C) 2008 Apple Inc. All Rights Reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef UnitBezier_h
#define UnitBezier_h

#include "platform/PlatformExport.h"
#include "wtf/Assertions.h"
#include <math.h>

namespace blink {

struct UnitBezier {
    UnitBezier(double p1x, double p1y, double p2x, double p2y)
    {
        // Calculate the polynomial coefficients, implicit first and last control points are (0,0) and (1,1).
        cx = 3.0 * p1x;
        bx = 3.0 * (p2x - p1x) - cx;
        ax = 1.0 - cx -bx;

        cy = 3.0 * p1y;
        by = 3.0 * (p2y - p1y) - cy;
        ay = 1.0 - cy - by;

        // End-point gradients are used to calculate timing function results
        // outside the range [0, 1].
        //
        // There are three possibilities for the gradient at each end:
        // (1) the closest control point is not horizontally coincident with regard to
        //     (0, 0) or (1, 1). In this case the line between the end point and
        //     the control point is tangent to the bezier at the end point.
        // (2) the closest control point is coincident with the end point. In
        //     this case the line between the end point and the far control
        //     point is tangent to the bezier at the end point.
        // (3) the closest control point is horizontally coincident with the end
        //     point, but vertically distinct. In this case the gradient at the
        //     end point is Infinite. However, this causes issues when
        //     interpolating. As a result, we break down to a simple case of
        //     0 gradient under these conditions.

        if (p1x > 0)
            m_startGradient = p1y / p1x;
        else if (!p1y && p2x > 0)
            m_startGradient = p2y / p2x;
        else
            m_startGradient = 0;

        if (p2x < 1)
            m_endGradient = (p2y - 1) / (p2x - 1);
        else if (p2x == 1 && p1x < 1)
            m_endGradient = (p1y - 1) / (p1x - 1);
        else
            m_endGradient = 0;
    }

    double sampleCurveX(double t)
    {
        // `ax t^3 + bx t^2 + cx t' expanded using Horner's rule.
        return ((ax * t + bx) * t + cx) * t;
    }

    double sampleCurveY(double t)
    {
        return ((ay * t + by) * t + cy) * t;
    }

    double sampleCurveDerivativeX(double t)
    {
        return (3.0 * ax * t + 2.0 * bx) * t + cx;
    }

    // Given an x value, find a parametric value it came from.
    double solveCurveX(double x, double epsilon)
    {
        ASSERT(x >= 0.0);
        ASSERT(x <= 1.0);

        double t0;
        double t1;
        double t2;
        double x2;
        double d2;
        int i;

        // First try a few iterations of Newton's method -- normally very fast.
        for (t2 = x, i = 0; i < 8; i++) {
            x2 = sampleCurveX(t2) - x;
            if (fabs (x2) < epsilon)
                return t2;
            d2 = sampleCurveDerivativeX(t2);
            if (fabs(d2) < 1e-6)
                break;
            t2 = t2 - x2 / d2;
        }

        // Fall back to the bisection method for reliability.
        t0 = 0.0;
        t1 = 1.0;
        t2 = x;

        while (t0 < t1) {
            x2 = sampleCurveX(t2);
            if (fabs(x2 - x) < epsilon)
                return t2;
            if (x > x2)
                t0 = t2;
            else
                t1 = t2;
            t2 = (t1 - t0) * .5 + t0;
        }

        // Failure.
        return t2;
    }

    // Evaluates y at the given x. The epsilon parameter provides a hint as to the required
    // accuracy and is not guaranteed.
    double solve(double x, double epsilon)
    {
        if (x < 0.0)
            return 0.0 + m_startGradient * x;
        if (x > 1.0)
            return 1.0 + m_endGradient * (x - 1.0);
        return sampleCurveY(solveCurveX(x, epsilon));
    }

private:
    double ax;
    double bx;
    double cx;

    double ay;
    double by;
    double cy;

    double m_startGradient;
    double m_endGradient;
};

} // namespace blink

#endif // UnitBezier_h

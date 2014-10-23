/*
 * Copyright (C) 2005, 2006 Apple Computer, Inc.  All rights reserved.
 *               2010 Dirk Schulze <krit@webkit.org>
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

#ifndef AffineTransform_h
#define AffineTransform_h

#include "platform/transforms/TransformationMatrix.h"

#include <string.h> // for memcpy
#include "wtf/FastAllocBase.h"

namespace blink {

class FloatPoint;
class FloatQuad;
class FloatRect;
class IntPoint;
class IntRect;
class TransformationMatrix;

class PLATFORM_EXPORT AffineTransform {
    WTF_MAKE_FAST_ALLOCATED;
public:
    typedef double Transform[6];

    AffineTransform();
    AffineTransform(double a, double b, double c, double d, double e, double f);

    void setMatrix(double a, double b, double c, double d, double e, double f);

    void map(double x, double y, double& x2, double& y2) const;

    // Rounds the mapped point to the nearest integer value.
    IntPoint mapPoint(const IntPoint&) const;

    FloatPoint mapPoint(const FloatPoint&) const;

    IntSize mapSize(const IntSize&) const;

    FloatSize mapSize(const FloatSize&) const;

    // Rounds the resulting mapped rectangle out. This is helpful for bounding
    // box computations but may not be what is wanted in other contexts.
    IntRect mapRect(const IntRect&) const;

    FloatRect mapRect(const FloatRect&) const;
    FloatQuad mapQuad(const FloatQuad&) const;

    bool isIdentity() const;

    double a() const { return m_transform[0]; }
    void setA(double a) { m_transform[0] = a; }
    double b() const { return m_transform[1]; }
    void setB(double b) { m_transform[1] = b; }
    double c() const { return m_transform[2]; }
    void setC(double c) { m_transform[2] = c; }
    double d() const { return m_transform[3]; }
    void setD(double d) { m_transform[3] = d; }
    double e() const { return m_transform[4]; }
    void setE(double e) { m_transform[4] = e; }
    double f() const { return m_transform[5]; }
    void setF(double f) { m_transform[5] = f; }

    void makeIdentity();

    AffineTransform& multiply(const AffineTransform& other);
    AffineTransform& scale(double);
    AffineTransform& scale(double sx, double sy);
    AffineTransform& scaleNonUniform(double sx, double sy);
    AffineTransform& rotate(double a);
    AffineTransform& rotateRadians(double a);
    AffineTransform& rotateFromVector(double x, double y);
    AffineTransform& translate(double tx, double ty);
    AffineTransform& shear(double sx, double sy);
    AffineTransform& flipX();
    AffineTransform& flipY();
    AffineTransform& skew(double angleX, double angleY);
    AffineTransform& skewX(double angle);
    AffineTransform& skewY(double angle);

    double xScale() const;
    double yScale() const;

    double det() const;
    bool isInvertible() const;
    AffineTransform inverse() const;

    TransformationMatrix toTransformationMatrix() const;

    bool isIdentityOrTranslation() const
    {
        return m_transform[0] == 1 && m_transform[1] == 0 && m_transform[2] == 0 && m_transform[3] == 1;
    }

    bool isIdentityOrTranslationOrFlipped() const
    {
        return m_transform[0] == 1 && m_transform[1] == 0 && m_transform[2] == 0 && (m_transform[3] == 1 || m_transform[3] == -1);
    }

    bool preservesAxisAlignment() const
    {
        return (m_transform[1] == 0 && m_transform[2] == 0) || (m_transform[0] == 0 && m_transform[3] == 0);
    }

    bool operator== (const AffineTransform& m2) const
    {
        return (m_transform[0] == m2.m_transform[0]
             && m_transform[1] == m2.m_transform[1]
             && m_transform[2] == m2.m_transform[2]
             && m_transform[3] == m2.m_transform[3]
             && m_transform[4] == m2.m_transform[4]
             && m_transform[5] == m2.m_transform[5]);
    }

    bool operator!=(const AffineTransform& other) const { return !(*this == other); }

    // *this = *this * t (i.e., a multRight)
    AffineTransform& operator*=(const AffineTransform& t)
    {
        return multiply(t);
    }

    // result = *this * t (i.e., a multRight)
    AffineTransform operator*(const AffineTransform& t) const
    {
        AffineTransform result = *this;
        result *= t;
        return result;
    }

    static AffineTransform translation(double x, double y)
    {
        return AffineTransform(1, 0, 0, 1, x, y);
    }

    // decompose the matrix into its component parts
    typedef struct {
        double scaleX, scaleY;
        double angle;
        double remainderA, remainderB, remainderC, remainderD;
        double translateX, translateY;
    } DecomposedType;

    bool decompose(DecomposedType&) const;
    void recompose(const DecomposedType&);

private:
    void setMatrix(const Transform m)
    {
        if (m && m != m_transform)
            memcpy(m_transform, m, sizeof(Transform));
    }

    Transform m_transform;
};

PLATFORM_EXPORT AffineTransform makeMapBetweenRects(const FloatRect& source, const FloatRect& dest);

}

#endif

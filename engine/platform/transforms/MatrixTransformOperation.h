/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Graham Dennis (graham.dennis@gmail.com)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

#ifndef MatrixTransformOperation_h
#define MatrixTransformOperation_h

#include "platform/transforms/TransformOperation.h"
#include "platform/transforms/TransformationMatrix.h"

namespace blink {

class PLATFORM_EXPORT MatrixTransformOperation : public TransformOperation {
public:
    static PassRefPtr<MatrixTransformOperation> create(double a, double b, double c, double d, double e, double f)
    {
        return adoptRef(new MatrixTransformOperation(a, b, c, d, e, f));
    }

    static PassRefPtr<MatrixTransformOperation> create(const TransformationMatrix& t)
    {
        return adoptRef(new MatrixTransformOperation(t));
    }

    TransformationMatrix matrix() const { return TransformationMatrix(m_a, m_b, m_c, m_d, m_e, m_f); }

    virtual bool canBlendWith(const TransformOperation& other) const
    {
        return false;
    }

private:
    virtual bool isIdentity() const OVERRIDE { return m_a == 1 && !m_b && !m_c && m_d == 1 && !m_e && !m_f; }

    virtual OperationType type() const OVERRIDE { return Matrix; }

    virtual bool operator==(const TransformOperation& o) const OVERRIDE
    {
        if (!isSameType(o))
            return false;

        const MatrixTransformOperation* m = static_cast<const MatrixTransformOperation*>(&o);
        return m_a == m->m_a && m_b == m->m_b && m_c == m->m_c && m_d == m->m_d && m_e == m->m_e && m_f == m->m_f;
    }

    virtual void apply(TransformationMatrix& transform, const FloatSize&) const OVERRIDE
    {
        TransformationMatrix matrix(m_a, m_b, m_c, m_d, m_e, m_f);
        transform.multiply(matrix);
    }

    virtual PassRefPtr<TransformOperation> blend(const TransformOperation* from, double progress, bool blendToIdentity = false) OVERRIDE;

    MatrixTransformOperation(double a, double b, double c, double d, double e, double f)
        : m_a(a)
        , m_b(b)
        , m_c(c)
        , m_d(d)
        , m_e(e)
        , m_f(f)
    {
    }

    MatrixTransformOperation(const TransformationMatrix& t)
        : m_a(t.a())
        , m_b(t.b())
        , m_c(t.c())
        , m_d(t.d())
        , m_e(t.e())
        , m_f(t.f())
    {
    }

    double m_a;
    double m_b;
    double m_c;
    double m_d;
    double m_e;
    double m_f;
};

} // namespace blink

#endif // MatrixTransformOperation_h

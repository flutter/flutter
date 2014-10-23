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

#ifndef RotateTransformOperation_h
#define RotateTransformOperation_h

#include "platform/transforms/TransformOperation.h"

namespace blink {

class PLATFORM_EXPORT RotateTransformOperation : public TransformOperation {
public:
    static PassRefPtr<RotateTransformOperation> create(double angle, OperationType type)
    {
        return adoptRef(new RotateTransformOperation(0, 0, 1, angle, type));
    }

    static PassRefPtr<RotateTransformOperation> create(double x, double y, double z, double angle, OperationType type)
    {
        return adoptRef(new RotateTransformOperation(x, y, z, angle, type));
    }

    double x() const { return m_x; }
    double y() const { return m_y; }
    double z() const { return m_z; }
    double angle() const { return m_angle; }

    FloatPoint3D axis() const;
    static bool shareSameAxis(const RotateTransformOperation* fromRotation, const RotateTransformOperation* toRotation, FloatPoint3D* axis, double* fromAngle, double* toAngle);

    virtual bool canBlendWith(const TransformOperation& other) const;
    virtual OperationType type() const OVERRIDE { return m_type; }

private:
    virtual bool isIdentity() const OVERRIDE { return !m_angle; }

    virtual bool operator==(const TransformOperation& o) const OVERRIDE
    {
        if (!isSameType(o))
            return false;
        const RotateTransformOperation* r = static_cast<const RotateTransformOperation*>(&o);
        return m_x == r->m_x && m_y == r->m_y && m_z == r->m_z && m_angle == r->m_angle;
    }

    virtual void apply(TransformationMatrix& transform, const FloatSize& /*borderBoxSize*/) const OVERRIDE
    {
        transform.rotate3d(m_x, m_y, m_z, m_angle);
    }

    virtual PassRefPtr<TransformOperation> blend(const TransformOperation* from, double progress, bool blendToIdentity = false) OVERRIDE;

    RotateTransformOperation(double x, double y, double z, double angle, OperationType type)
        : m_x(x)
        , m_y(y)
        , m_z(z)
        , m_angle(angle)
        , m_type(type)
    {
        ASSERT(type == RotateX || type == RotateY || type == RotateZ || type == Rotate3D);
    }

    double m_x;
    double m_y;
    double m_z;
    double m_angle;
    OperationType m_type;
};

} // namespace blink

#endif // RotateTransformOperation_h

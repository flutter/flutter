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

#ifndef SkewTransformOperation_h
#define SkewTransformOperation_h

#include "platform/transforms/TransformOperation.h"

namespace blink {

class PLATFORM_EXPORT SkewTransformOperation : public TransformOperation {
public:
    static PassRefPtr<SkewTransformOperation> create(double angleX, double angleY, OperationType type)
    {
        return adoptRef(new SkewTransformOperation(angleX, angleY, type));
    }

    double angleX() const { return m_angleX; }
    double angleY() const { return m_angleY; }

    virtual bool canBlendWith(const TransformOperation& other) const;
private:
    virtual bool isIdentity() const OVERRIDE { return !m_angleX && !m_angleY; }
    virtual OperationType type() const OVERRIDE { return m_type; }

    virtual bool operator==(const TransformOperation& o) const OVERRIDE
    {
        if (!isSameType(o))
            return false;
        const SkewTransformOperation* s = static_cast<const SkewTransformOperation*>(&o);
        return m_angleX == s->m_angleX && m_angleY == s->m_angleY;
    }

    virtual void apply(TransformationMatrix& transform, const FloatSize&) const OVERRIDE
    {
        transform.skew(m_angleX, m_angleY);
    }

    virtual PassRefPtr<TransformOperation> blend(const TransformOperation* from, double progress, bool blendToIdentity = false) OVERRIDE;

    SkewTransformOperation(double angleX, double angleY, OperationType type)
        : m_angleX(angleX)
        , m_angleY(angleY)
        , m_type(type)
    {
    }

    double m_angleX;
    double m_angleY;
    OperationType m_type;
};

} // namespace blink

#endif // SkewTransformOperation_h

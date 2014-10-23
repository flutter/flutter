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

#ifndef TransformOperation_h
#define TransformOperation_h

#include "platform/geometry/FloatSize.h"
#include "platform/transforms/TransformationMatrix.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"

namespace blink {

// CSS Transforms (may become part of CSS3)

class PLATFORM_EXPORT TransformOperation : public RefCounted<TransformOperation> {
public:
    enum OperationType {
        ScaleX, ScaleY, Scale,
        TranslateX, TranslateY, Translate,
        Rotate,
        RotateZ = Rotate,
        SkewX, SkewY, Skew,
        Matrix,
        ScaleZ, Scale3D,
        TranslateZ, Translate3D,
        RotateX, RotateY, Rotate3D,
        Matrix3D,
        Perspective,
        Interpolated,
        Identity, None
    };

    virtual ~TransformOperation() { }

    virtual bool operator==(const TransformOperation&) const = 0;
    bool operator!=(const TransformOperation& o) const { return !(*this == o); }

    virtual bool isIdentity() const = 0;

    virtual void apply(TransformationMatrix&, const FloatSize& borderBoxSize) const = 0;

    virtual PassRefPtr<TransformOperation> blend(const TransformOperation* from, double progress, bool blendToIdentity = false) = 0;

    virtual OperationType type() const = 0;
    bool isSameType(const TransformOperation& other) const { return other.type() == type(); }
    virtual bool canBlendWith(const TransformOperation& other) const = 0;

    bool is3DOperation() const
    {
        OperationType opType = type();
        return opType == ScaleZ
            || opType == Scale3D
            || opType == TranslateZ
            || opType == Translate3D
            || opType == RotateX
            || opType == RotateY
            || opType == Rotate3D
            || opType == Matrix3D
            || opType == Perspective
            || opType == Interpolated;
    }

    virtual bool dependsOnBoxSize() const { return false; }
};

} // namespace blink

#endif // TransformOperation_h

/*
 * Copyright (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.
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

#include "config.h"
#include "platform/transforms/TranslateTransformOperation.h"

namespace blink {

PassRefPtr<TransformOperation> TranslateTransformOperation::blend(const TransformOperation* from, double progress, bool blendToIdentity)
{
    if (from && !from->canBlendWith(*this))
        return this;

    const Length zeroLength(0, Fixed);
    if (blendToIdentity)
        return TranslateTransformOperation::create(zeroLength.blend(m_x, progress, ValueRangeAll), zeroLength.blend(m_y, progress, ValueRangeAll), blink::blend(0., m_z, progress), m_type);

    const TranslateTransformOperation* fromOp = static_cast<const TranslateTransformOperation*>(from);
    Length fromX = fromOp ? fromOp->m_x : zeroLength;
    Length fromY = fromOp ? fromOp->m_y : zeroLength;
    double fromZ = fromOp ? fromOp->m_z : 0;
    return TranslateTransformOperation::create(m_x.blend(fromX, progress, ValueRangeAll), m_y.blend(fromY, progress, ValueRangeAll), blink::blend(fromZ, m_z, progress), m_type);
}

bool TranslateTransformOperation::canBlendWith(const TransformOperation& other) const
{
    return other.type() == Translate
        || other.type() == TranslateX
        || other.type() == TranslateY
        || other.type() == TranslateZ
        || other.type() == Translate3D;
}

} // namespace blink

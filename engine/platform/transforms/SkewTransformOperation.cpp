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
#include "platform/transforms/SkewTransformOperation.h"

#include "platform/animation/AnimationUtilities.h"

namespace blink {

PassRefPtr<TransformOperation> SkewTransformOperation::blend(const TransformOperation* from, double progress, bool blendToIdentity)
{
    if (from && !from->canBlendWith(*this))
        return this;

    if (blendToIdentity)
        return SkewTransformOperation::create(blink::blend(m_angleX, 0.0, progress), blink::blend(m_angleY, 0.0, progress), m_type);

    const SkewTransformOperation* fromOp = static_cast<const SkewTransformOperation*>(from);
    double fromAngleX = fromOp ? fromOp->m_angleX : 0;
    double fromAngleY = fromOp ? fromOp->m_angleY : 0;
    return SkewTransformOperation::create(blink::blend(fromAngleX, m_angleX, progress), blink::blend(fromAngleY, m_angleY, progress), m_type);
}

bool SkewTransformOperation::canBlendWith(const TransformOperation& other) const
{
    return other.type() == Skew
        || other.type() == SkewX
        || other.type() == SkewY;
}

} // namespace blink

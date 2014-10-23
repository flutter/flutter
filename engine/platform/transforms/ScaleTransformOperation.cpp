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
#include "platform/transforms/ScaleTransformOperation.h"

#include "platform/animation/AnimationUtilities.h"

namespace blink {

PassRefPtr<TransformOperation> ScaleTransformOperation::blend(const TransformOperation* from, double progress, bool blendToIdentity)
{
    if (from && !from->canBlendWith(*this))
        return this;

    if (blendToIdentity)
        return ScaleTransformOperation::create(blink::blend(m_x, 1.0, progress),
                                               blink::blend(m_y, 1.0, progress),
                                               blink::blend(m_z, 1.0, progress), m_type);

    const ScaleTransformOperation* fromOp = static_cast<const ScaleTransformOperation*>(from);
    double fromX = fromOp ? fromOp->m_x : 1.0;
    double fromY = fromOp ? fromOp->m_y : 1.0;
    double fromZ = fromOp ? fromOp->m_z : 1.0;
    return ScaleTransformOperation::create(blink::blend(fromX, m_x, progress),
                                           blink::blend(fromY, m_y, progress),
                                           blink::blend(fromZ, m_z, progress), m_type);
}


bool ScaleTransformOperation::canBlendWith(const TransformOperation& other) const
{
    return other.type() == ScaleX
        || other.type() == ScaleY
        || other.type() == ScaleZ
        || other.type() == Scale3D
        || other.type() == Scale;
}

} // namespace blink

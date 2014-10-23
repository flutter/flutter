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
#include "platform/transforms/MatrixTransformOperation.h"

#include <algorithm>

namespace blink {

PassRefPtr<TransformOperation> MatrixTransformOperation::blend(const TransformOperation* from, double progress, bool blendToIdentity)
{
    if (from && !from->isSameType(*this))
        return this;

    // convert the TransformOperations into matrices
    FloatSize size;
    TransformationMatrix fromT;
    TransformationMatrix toT(m_a, m_b, m_c, m_d, m_e, m_f);
    if (from) {
        const MatrixTransformOperation* m = static_cast<const MatrixTransformOperation*>(from);
        fromT.setMatrix(m->m_a, m->m_b, m->m_c, m->m_d, m->m_e, m->m_f);
    }

    if (blendToIdentity)
        std::swap(fromT, toT);

    toT.blend(fromT, progress);
    return MatrixTransformOperation::create(toT.a(), toT.b(), toT.c(), toT.d(), toT.e(), toT.f());
}

} // namespace blink

/*
 * Copyright (C) 2009 Apple Inc. All rights reserved.
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
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/transforms/PerspectiveTransformOperation.h"

#include "platform/animation/AnimationUtilities.h"
#include "wtf/MathExtras.h"

namespace blink {

PassRefPtr<TransformOperation> PerspectiveTransformOperation::blend(const TransformOperation* from, double progress, bool blendToIdentity)
{
    if (from && !from->isSameType(*this))
        return this;

    if (blendToIdentity) {
        double p = blink::blend(m_p, 1., progress); // FIXME: this seems wrong. https://bugs.webkit.org/show_bug.cgi?id=52700
        return PerspectiveTransformOperation::create(clampToPositiveInteger(p));
    }

    const PerspectiveTransformOperation* fromOp = static_cast<const PerspectiveTransformOperation*>(from);

    TransformationMatrix fromT;
    TransformationMatrix toT;
    fromT.applyPerspective(fromOp ? fromOp->m_p : 0);
    toT.applyPerspective(m_p);
    toT.blend(fromT, progress);
    TransformationMatrix::DecomposedType decomp;
    toT.decompose(decomp);

    if (decomp.perspectiveZ) {
        double val = -1.0 / decomp.perspectiveZ;
        return PerspectiveTransformOperation::create(clampToPositiveInteger(val));
    }
    return PerspectiveTransformOperation::create(0);
}

} // namespace blink

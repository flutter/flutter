/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/transforms/InterpolatedTransformOperation.h"

#include "platform/transforms/IdentityTransformOperation.h"

namespace blink {

bool InterpolatedTransformOperation::operator==(const TransformOperation& o) const
{
    if (!isSameType(o))
        return false;
    const InterpolatedTransformOperation* t = static_cast<const InterpolatedTransformOperation*>(&o);
    return progress == t->progress && from == t->from && to == t->to;
}

void InterpolatedTransformOperation::apply(TransformationMatrix& transform, const FloatSize& borderBoxSize) const
{
    TransformationMatrix fromTransform;
    TransformationMatrix toTransform;
    from.apply(borderBoxSize, fromTransform);
    to.apply(borderBoxSize, toTransform);

    toTransform.blend(fromTransform, progress);
    transform.multiply(toTransform);
}

PassRefPtr<TransformOperation> InterpolatedTransformOperation::blend(const TransformOperation* from, double progress, bool blendToIdentity)
{
    if (from && !from->isSameType(*this))
        return this;

    TransformOperations thisOperations;
    thisOperations.operations().append(this);
    TransformOperations fromOperations;
    if (blendToIdentity)
        fromOperations.operations().append(IdentityTransformOperation::create());
    else
        fromOperations.operations().append(const_cast<TransformOperation*>(from));
    return InterpolatedTransformOperation::create(thisOperations, fromOperations, progress);
}

} // namespace blink


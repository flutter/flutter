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
#include "core/animation/animatable/AnimatableClipPathOperation.h"

namespace blink {

bool AnimatableClipPathOperation::usesDefaultInterpolationWith(const AnimatableValue* value) const
{
    const AnimatableClipPathOperation* toOperation = toAnimatableClipPathOperation(value);

    if (m_operation->type() != ClipPathOperation::SHAPE || toOperation->m_operation->type() != ClipPathOperation::SHAPE)
        return true;

    const BasicShape* fromShape = toShapeClipPathOperation(clipPathOperation())->basicShape();
    const BasicShape* toShape = toShapeClipPathOperation(toOperation->clipPathOperation())->basicShape();

    return !fromShape->canBlend(toShape);
}

PassRefPtrWillBeRawPtr<AnimatableValue> AnimatableClipPathOperation::interpolateTo(const AnimatableValue* value, double fraction) const
{
    if (usesDefaultInterpolationWith(value))
        return defaultInterpolateTo(this, value, fraction);

    const AnimatableClipPathOperation* toOperation = toAnimatableClipPathOperation(value);
    const BasicShape* fromShape = toShapeClipPathOperation(clipPathOperation())->basicShape();
    const BasicShape* toShape = toShapeClipPathOperation(toOperation->clipPathOperation())->basicShape();

    return AnimatableClipPathOperation::create(ShapeClipPathOperation::create(toShape->blend(fromShape, fraction)).get());
}

bool AnimatableClipPathOperation::equalTo(const AnimatableValue* value) const
{
    const ClipPathOperation* operation = toAnimatableClipPathOperation(value)->m_operation.get();
    return m_operation == operation || (m_operation && operation && *m_operation == *operation);
}

}

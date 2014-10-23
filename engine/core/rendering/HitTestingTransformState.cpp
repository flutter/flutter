/*
 * Copyright (C) 2011 Apple Inc.  All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
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
#include "core/rendering/HitTestingTransformState.h"

#include "platform/geometry/LayoutRect.h"
#include "wtf/PassOwnPtr.h"

namespace blink {

void HitTestingTransformState::translate(int x, int y, TransformAccumulation accumulate)
{
    m_accumulatedTransform.translate(x, y);
    if (accumulate == FlattenTransform)
        flattenWithTransform(m_accumulatedTransform);

    m_accumulatingTransform = accumulate == AccumulateTransform;
}

void HitTestingTransformState::applyTransform(const TransformationMatrix& transformFromContainer, TransformAccumulation accumulate)
{
    m_accumulatedTransform.multiply(transformFromContainer);
    if (accumulate == FlattenTransform)
        flattenWithTransform(m_accumulatedTransform);

    m_accumulatingTransform = accumulate == AccumulateTransform;
}

void HitTestingTransformState::flatten()
{
    flattenWithTransform(m_accumulatedTransform);
}

void HitTestingTransformState::flattenWithTransform(const TransformationMatrix& t)
{
    TransformationMatrix inverseTransform = t.inverse();
    m_lastPlanarPoint = inverseTransform.projectPoint(m_lastPlanarPoint);
    m_lastPlanarQuad = inverseTransform.projectQuad(m_lastPlanarQuad);
    m_lastPlanarArea = inverseTransform.projectQuad(m_lastPlanarArea);

    m_accumulatedTransform.makeIdentity();
    m_accumulatingTransform = false;
}

FloatPoint HitTestingTransformState::mappedPoint() const
{
    return m_accumulatedTransform.inverse().projectPoint(m_lastPlanarPoint);
}

FloatQuad HitTestingTransformState::mappedQuad() const
{
    return m_accumulatedTransform.inverse().projectQuad(m_lastPlanarQuad);
}

FloatQuad HitTestingTransformState::mappedArea() const
{
    return m_accumulatedTransform.inverse().projectQuad(m_lastPlanarArea);
}

LayoutRect HitTestingTransformState::boundsOfMappedArea() const
{
    return m_accumulatedTransform.inverse().clampedBoundsOfProjectedQuad(m_lastPlanarArea);
}

} // namespace blink

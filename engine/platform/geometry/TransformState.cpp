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
#include "platform/geometry/TransformState.h"

#include "wtf/PassOwnPtr.h"

namespace blink {

TransformState& TransformState::operator=(const TransformState& other)
{
    m_accumulatedOffset = other.m_accumulatedOffset;
    m_mapPoint = other.m_mapPoint;
    m_mapQuad = other.m_mapQuad;
    if (m_mapPoint)
        m_lastPlanarPoint = other.m_lastPlanarPoint;
    if (m_mapQuad)
        m_lastPlanarQuad = other.m_lastPlanarQuad;
    m_accumulatingTransform = other.m_accumulatingTransform;
    m_direction = other.m_direction;

    m_accumulatedTransform.clear();

    if (other.m_accumulatedTransform)
        m_accumulatedTransform = adoptPtr(new TransformationMatrix(*other.m_accumulatedTransform));

    return *this;
}

void TransformState::translateTransform(const LayoutSize& offset)
{
    if (m_direction == ApplyTransformDirection)
        m_accumulatedTransform->translateRight(offset.width().toDouble(), offset.height().toDouble());
    else
        m_accumulatedTransform->translate(offset.width().toDouble(), offset.height().toDouble());
}

void TransformState::translateMappedCoordinates(const LayoutSize& offset)
{
    LayoutSize adjustedOffset = (m_direction == ApplyTransformDirection) ? offset : -offset;
    if (m_mapPoint)
        m_lastPlanarPoint.move(adjustedOffset);
    if (m_mapQuad)
        m_lastPlanarQuad.move(adjustedOffset);
}

void TransformState::move(const LayoutSize& offset, TransformAccumulation accumulate)
{
    if (accumulate == FlattenTransform || !m_accumulatedTransform) {
        m_accumulatedOffset += offset;
    } else {
        applyAccumulatedOffset();
        if (m_accumulatingTransform && m_accumulatedTransform) {
            // If we're accumulating into an existing transform, apply the translation.
            translateTransform(offset);

            // Then flatten if necessary.
            if (accumulate == FlattenTransform)
                flatten();
        } else {
            // Just move the point and/or quad.
            translateMappedCoordinates(offset);
        }
    }
    m_accumulatingTransform = accumulate == AccumulateTransform;
}

void TransformState::applyAccumulatedOffset()
{
    LayoutSize offset = m_accumulatedOffset;
    m_accumulatedOffset = LayoutSize();
    if (!offset.isZero()) {
        if (m_accumulatedTransform) {
            translateTransform(offset);
            flatten();
        } else {
            translateMappedCoordinates(offset);
        }
    }
}

// FIXME: We transform AffineTransform to TransformationMatrix. This is rather inefficient.
void TransformState::applyTransform(const AffineTransform& transformFromContainer, TransformAccumulation accumulate, bool* wasClamped)
{
    applyTransform(transformFromContainer.toTransformationMatrix(), accumulate, wasClamped);
}

void TransformState::applyTransform(const TransformationMatrix& transformFromContainer, TransformAccumulation accumulate, bool* wasClamped)
{
    if (wasClamped)
        *wasClamped = false;

    if (transformFromContainer.isIntegerTranslation()) {
        move(LayoutSize(transformFromContainer.e(), transformFromContainer.f()), accumulate);
        return;
    }

    applyAccumulatedOffset();

    // If we have an accumulated transform from last time, multiply in this transform
    if (m_accumulatedTransform) {
        if (m_direction == ApplyTransformDirection)
            m_accumulatedTransform = adoptPtr(new TransformationMatrix(transformFromContainer * *m_accumulatedTransform));
        else
            m_accumulatedTransform->multiply(transformFromContainer);
    } else if (accumulate == AccumulateTransform) {
        // Make one if we started to accumulate
        m_accumulatedTransform = adoptPtr(new TransformationMatrix(transformFromContainer));
    }

    if (accumulate == FlattenTransform) {
        const TransformationMatrix* finalTransform = m_accumulatedTransform ? m_accumulatedTransform.get() : &transformFromContainer;
        flattenWithTransform(*finalTransform, wasClamped);
    }
    m_accumulatingTransform = accumulate == AccumulateTransform;
}

void TransformState::flatten(bool* wasClamped)
{
    if (wasClamped)
        *wasClamped = false;

    applyAccumulatedOffset();

    if (!m_accumulatedTransform) {
        m_accumulatingTransform = false;
        return;
    }

    flattenWithTransform(*m_accumulatedTransform, wasClamped);
}

FloatPoint TransformState::mappedPoint(bool* wasClamped) const
{
    if (wasClamped)
        *wasClamped = false;

    FloatPoint point = m_lastPlanarPoint;
    point.move((m_direction == ApplyTransformDirection) ? m_accumulatedOffset : -m_accumulatedOffset);
    if (!m_accumulatedTransform)
        return point;

    if (m_direction == ApplyTransformDirection)
        return m_accumulatedTransform->mapPoint(point);

    return m_accumulatedTransform->inverse().projectPoint(point, wasClamped);
}

FloatQuad TransformState::mappedQuad(bool* wasClamped) const
{
    if (wasClamped)
        *wasClamped = false;

    FloatQuad quad = m_lastPlanarQuad;
    quad.move((m_direction == ApplyTransformDirection) ? m_accumulatedOffset : -m_accumulatedOffset);
    if (!m_accumulatedTransform)
        return quad;

    if (m_direction == ApplyTransformDirection)
        return m_accumulatedTransform->mapQuad(quad);

    return m_accumulatedTransform->inverse().projectQuad(quad, wasClamped);
}

void TransformState::flattenWithTransform(const TransformationMatrix& t, bool* wasClamped)
{
    if (m_direction == ApplyTransformDirection) {
        if (m_mapPoint)
            m_lastPlanarPoint = t.mapPoint(m_lastPlanarPoint);
        if (m_mapQuad)
            m_lastPlanarQuad = t.mapQuad(m_lastPlanarQuad);
    } else {
        TransformationMatrix inverseTransform = t.inverse();
        if (m_mapPoint)
            m_lastPlanarPoint = inverseTransform.projectPoint(m_lastPlanarPoint);
        if (m_mapQuad)
            m_lastPlanarQuad = inverseTransform.projectQuad(m_lastPlanarQuad, wasClamped);
    }

    // We could throw away m_accumulatedTransform if we wanted to here, but that
    // would cause thrash when traversing hierarchies with alternating
    // preserve-3d and flat elements.
    if (m_accumulatedTransform)
        m_accumulatedTransform->makeIdentity();
    m_accumulatingTransform = false;
}

} // namespace blink

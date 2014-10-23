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

#ifndef TransformState_h
#define TransformState_h

#include "platform/geometry/FloatPoint.h"
#include "platform/geometry/FloatQuad.h"
#include "platform/geometry/IntSize.h"
#include "platform/geometry/LayoutSize.h"
#include "platform/transforms/AffineTransform.h"
#include "platform/transforms/TransformationMatrix.h"
#include "wtf/OwnPtr.h"

namespace blink {

class PLATFORM_EXPORT TransformState {
public:
    enum TransformDirection { ApplyTransformDirection, UnapplyInverseTransformDirection };
    enum TransformAccumulation { FlattenTransform, AccumulateTransform };

    TransformState(TransformDirection mappingDirection, const FloatPoint& p, const FloatQuad& quad)
        : m_lastPlanarPoint(p)
        , m_lastPlanarQuad(quad)
        , m_accumulatingTransform(false)
        , m_mapPoint(true)
        , m_mapQuad(true)
        , m_direction(mappingDirection)
    {
    }

    TransformState(TransformDirection mappingDirection, const FloatPoint& p)
        : m_lastPlanarPoint(p)
        , m_accumulatingTransform(false)
        , m_mapPoint(true)
        , m_mapQuad(false)
        , m_direction(mappingDirection)
    {
    }

    TransformState(TransformDirection mappingDirection, const FloatQuad& quad)
        : m_lastPlanarQuad(quad)
        , m_accumulatingTransform(false)
        , m_mapPoint(false)
        , m_mapQuad(true)
        , m_direction(mappingDirection)
    {
    }

    TransformState(const TransformState& other) { *this = other; }

    TransformState& operator=(const TransformState&);

    void setQuad(const FloatQuad& quad)
    {
        // FIXME: this assumes that the quad being added is in the coordinate system of the current state.
        // This breaks if we're simultaneously mapping a point. https://bugs.webkit.org/show_bug.cgi?id=106680
        ASSERT(!m_mapPoint);
        m_accumulatedOffset = LayoutSize();
        m_lastPlanarQuad = quad;
    }

    void move(LayoutUnit x, LayoutUnit y, TransformAccumulation accumulate = FlattenTransform)
    {
        move(LayoutSize(x, y), accumulate);
    }

    void move(const LayoutSize&, TransformAccumulation = FlattenTransform);
    void applyTransform(const AffineTransform& transformFromContainer, TransformAccumulation = FlattenTransform, bool* wasClamped = 0);
    void applyTransform(const TransformationMatrix& transformFromContainer, TransformAccumulation = FlattenTransform, bool* wasClamped = 0);
    void flatten(bool* wasClamped = 0);

    // Return the coords of the point or quad in the last flattened layer
    FloatPoint lastPlanarPoint() const { return m_lastPlanarPoint; }
    FloatQuad lastPlanarQuad() const { return m_lastPlanarQuad; }

    // Return the point or quad mapped through the current transform
    FloatPoint mappedPoint(bool* wasClamped = 0) const;
    FloatQuad mappedQuad(bool* wasClamped = 0) const;

private:
    void translateTransform(const LayoutSize&);
    void translateMappedCoordinates(const LayoutSize&);
    void flattenWithTransform(const TransformationMatrix&, bool* wasClamped);
    void applyAccumulatedOffset();

    FloatPoint m_lastPlanarPoint;
    FloatQuad m_lastPlanarQuad;

    // We only allocate the transform if we need to
    OwnPtr<TransformationMatrix> m_accumulatedTransform;
    LayoutSize m_accumulatedOffset;
    bool m_accumulatingTransform;
    bool m_mapPoint, m_mapQuad;
    TransformDirection m_direction;
};

} // namespace blink

#endif // TransformState_h

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

#ifndef HitTestingTransformState_h
#define HitTestingTransformState_h

#include "platform/geometry/FloatQuad.h"
#include "platform/geometry/FloatPoint.h"
#include "platform/geometry/IntSize.h"
#include "platform/transforms/AffineTransform.h"
#include "platform/transforms/TransformationMatrix.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"

namespace blink {

// FIXME: Now that TransformState lazily creates its TransformationMatrix it takes up less space.
// So there's really no need for a ref counted version. So This class should be removed and replaced
// with TransformState. There are some minor differences (like the way translate() works slightly
// differently than move()) so care has to be taken when this is done.
class HitTestingTransformState : public RefCounted<HitTestingTransformState> {
public:
    static PassRefPtr<HitTestingTransformState> create(const FloatPoint& p, const FloatQuad& quad, const FloatQuad& area)
    {
        return adoptRef(new HitTestingTransformState(p, quad, area));
    }

    static PassRefPtr<HitTestingTransformState> create(const HitTestingTransformState& other)
    {
        return adoptRef(new HitTestingTransformState(other));
    }

    enum TransformAccumulation { FlattenTransform, AccumulateTransform };
    void translate(int x, int y, TransformAccumulation);
    void applyTransform(const TransformationMatrix& transformFromContainer, TransformAccumulation);

    FloatPoint mappedPoint() const;
    FloatQuad mappedQuad() const;
    FloatQuad mappedArea() const;
    LayoutRect boundsOfMappedArea() const;
    void flatten();

    FloatPoint m_lastPlanarPoint;
    FloatQuad m_lastPlanarQuad;
    FloatQuad m_lastPlanarArea;
    TransformationMatrix m_accumulatedTransform;
    bool m_accumulatingTransform;

private:
    HitTestingTransformState(const FloatPoint& p, const FloatQuad& quad, const FloatQuad& area)
        : m_lastPlanarPoint(p)
        , m_lastPlanarQuad(quad)
        , m_lastPlanarArea(area)
        , m_accumulatingTransform(false)
    {
    }

    HitTestingTransformState(const HitTestingTransformState& other)
        : RefCounted<HitTestingTransformState>()
        , m_lastPlanarPoint(other.m_lastPlanarPoint)
        , m_lastPlanarQuad(other.m_lastPlanarQuad)
        , m_lastPlanarArea(other.m_lastPlanarArea)
        , m_accumulatedTransform(other.m_accumulatedTransform)
        , m_accumulatingTransform(other.m_accumulatingTransform)
    {
    }

    void flattenWithTransform(const TransformationMatrix&);
};

} // namespace blink

#endif // HitTestingTransformState_h

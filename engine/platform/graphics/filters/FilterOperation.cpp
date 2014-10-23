/*
 * Copyright (C) 2011 Apple Inc. All rights reserved.
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

#include "platform/graphics/filters/FilterOperation.h"

#include "platform/animation/AnimationUtilities.h"

namespace blink {

PassRefPtr<FilterOperation> FilterOperation::blend(const FilterOperation* from, const FilterOperation* to, double progress)
{
    ASSERT(from || to);
    if (to)
        return to->blend(from, progress);
    return from->blend(0, 1 - progress);
}

PassRefPtr<FilterOperation> BasicColorMatrixFilterOperation::blend(const FilterOperation* from, double progress) const
{
    double fromAmount;
    if (from) {
        ASSERT_WITH_SECURITY_IMPLICATION(from->isSameType(*this));
        fromAmount = toBasicColorMatrixFilterOperation(from)->amount();
    } else {
        switch (m_type) {
        case GRAYSCALE:
        case SEPIA:
        case HUE_ROTATE:
            fromAmount = 0;
            break;
        case SATURATE:
            fromAmount = 1;
            break;
        default:
            fromAmount = 0;
            ASSERT_NOT_REACHED();
        }
    }

    double result = blink::blend(fromAmount, m_amount, progress);
    switch (m_type) {
    case HUE_ROTATE:
        break;
    case GRAYSCALE:
    case SEPIA:
        result = clampTo<double>(result, 0, 1);
        break;
    case SATURATE:
        result = clampTo<double>(result, 0);
        break;
    default:
        ASSERT_NOT_REACHED();
    }
    return BasicColorMatrixFilterOperation::create(result, m_type);
}

PassRefPtr<FilterOperation> BasicComponentTransferFilterOperation::blend(const FilterOperation* from, double progress) const
{
    double fromAmount;
    if (from) {
        ASSERT_WITH_SECURITY_IMPLICATION(from->isSameType(*this));
        fromAmount = toBasicComponentTransferFilterOperation(from)->amount();
    } else {
        switch (m_type) {
        case OPACITY:
        case CONTRAST:
        case BRIGHTNESS:
            fromAmount = 1;
            break;
        case INVERT:
            fromAmount = 0;
            break;
        default:
            fromAmount = 0;
            ASSERT_NOT_REACHED();
        }
    }

    double result = blink::blend(fromAmount, m_amount, progress);
    switch (m_type) {
    case BRIGHTNESS:
    case CONTRAST:
        result = clampTo<double>(result, 0);
        break;
    case INVERT:
    case OPACITY:
        result = clampTo<double>(result, 0, 1);
        break;
    default:
        ASSERT_NOT_REACHED();
    }
    return BasicComponentTransferFilterOperation::create(result, m_type);
}

PassRefPtr<FilterOperation> BlurFilterOperation::blend(const FilterOperation* from, double progress) const
{
    LengthType lengthType = m_stdDeviation.type();
    if (!from)
        return BlurFilterOperation::create(m_stdDeviation.blend(Length(lengthType), progress, ValueRangeNonNegative));

    const BlurFilterOperation* fromOp = toBlurFilterOperation(from);
    return BlurFilterOperation::create(m_stdDeviation.blend(fromOp->m_stdDeviation, progress, ValueRangeNonNegative));
}

PassRefPtr<FilterOperation> DropShadowFilterOperation::blend(const FilterOperation* from, double progress) const
{
    if (!from) {
        return DropShadowFilterOperation::create(
            blink::blend(IntPoint(), m_location, progress),
            blink::blend(0, m_stdDeviation, progress),
            blink::blend(Color(Color::transparent), m_color, progress));
    }

    const DropShadowFilterOperation* fromOp = toDropShadowFilterOperation(from);
    return DropShadowFilterOperation::create(
        blink::blend(fromOp->location(), m_location, progress),
        blink::blend(fromOp->stdDeviation(), m_stdDeviation, progress),
        blink::blend(fromOp->color(), m_color, progress));
}

} // namespace blink


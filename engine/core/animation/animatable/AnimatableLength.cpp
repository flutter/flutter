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
#include "core/animation/animatable/AnimatableLength.h"

#include "platform/CalculationValue.h"
#include "platform/animation/AnimationUtilities.h"

namespace blink {

namespace {

double clampNumber(double value, ValueRange range)
{
    if (range == ValueRangeNonNegative)
        return std::max(value, 0.0);
    ASSERT(range == ValueRangeAll);
    return value;
}

} // namespace

AnimatableLength::AnimatableLength(const Length& length, float zoom)
{
    ASSERT(zoom);
    PixelsAndPercent pixelsAndPercent = length.pixelsAndPercent();
    m_pixels = pixelsAndPercent.pixels / zoom;
    m_percent = pixelsAndPercent.percent;
    m_hasPixels = length.type() != Percent;
    m_hasPercent = !length.isFixed();
}

Length AnimatableLength::length(float zoom, ValueRange range) const
{
    if (!m_hasPercent)
        return Length(clampNumber(m_pixels, range) * zoom, Fixed);
    if (!m_hasPixels)
        return Length(clampNumber(m_percent, range), Percent);
    return Length(CalculationValue::create(PixelsAndPercent(m_pixels * zoom, m_percent), range));
}

PassRefPtrWillBeRawPtr<AnimatableValue> AnimatableLength::interpolateTo(const AnimatableValue* value, double fraction) const
{
    const AnimatableLength* length = toAnimatableLength(value);
    return create(blend(m_pixels, length->m_pixels, fraction), blend(m_percent, length->m_percent, fraction),
        m_hasPixels || length->m_hasPixels, m_hasPercent || length->m_hasPercent);
}

bool AnimatableLength::equalTo(const AnimatableValue* value) const
{
    const AnimatableLength* length = toAnimatableLength(value);
    return m_pixels == length->m_pixels && m_percent == length->m_percent && m_hasPixels == length->m_hasPixels && m_hasPercent == length->m_hasPercent;
}

} // namespace blink

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

#ifndef AnimatableLength_h
#define AnimatableLength_h

#include "core/animation/animatable/AnimatableValue.h"
#include "platform/Length.h"

namespace blink {

class AnimatableLength final : public AnimatableValue {
public:
    static PassRefPtrWillBeRawPtr<AnimatableLength> create(const Length& length, float zoom)
    {
        return adoptRefWillBeNoop(new AnimatableLength(length, zoom));
    }
    Length length(float zoom, ValueRange) const;

protected:
    virtual PassRefPtrWillBeRawPtr<AnimatableValue> interpolateTo(const AnimatableValue*, double fraction) const override;

private:
    static PassRefPtrWillBeRawPtr<AnimatableLength> create(double pixels, double percent, bool hasPixels, bool hasPercent)
    {
        return adoptRefWillBeNoop(new AnimatableLength(pixels, percent, hasPixels, hasPercent));
    }
    AnimatableLength(const Length&, float zoom);
    AnimatableLength(double pixels, double percent, bool hasPixels, bool hasPercent)
        : m_pixels(pixels)
        , m_percent(percent)
        , m_hasPixels(hasPixels)
        , m_hasPercent(hasPercent)
    {
        ASSERT(m_hasPixels || m_hasPercent);
    }
    virtual AnimatableType type() const override { return TypeLength; }
    virtual bool equalTo(const AnimatableValue*) const override;

    virtual void trace(Visitor* visitor) override { AnimatableValue::trace(visitor); }

    double m_pixels;
    double m_percent;
    bool m_hasPixels;
    bool m_hasPercent;
};

DEFINE_ANIMATABLE_VALUE_TYPE_CASTS(AnimatableLength, isLength());

} // namespace blink

#endif // AnimatableLength_h
